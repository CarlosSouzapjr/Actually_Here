package com.actually_here.backend.config

import jakarta.annotation.PostConstruct
import jakarta.annotation.PreDestroy
import org.apache.zookeeper.*
import org.slf4j.LoggerFactory
import org.springframework.integration.mqtt.inbound.MqttPahoMessageDrivenChannelAdapter
import org.springframework.stereotype.Service
import java.util.Collections
import java.util.concurrent.CountDownLatch

@Service
class ZooKeeperLeaderElection(
    private val mqttAdapter: MqttPahoMessageDrivenChannelAdapter
) : Watcher {

    private val logger = LoggerFactory.getLogger(ZooKeeperLeaderElection::class.java)
    private lateinit var zk: ZooKeeper
    private var currentZNodeName: String? = null
    
    private val ELECTION_NAMESPACE = "/election"
    
    @PostConstruct
    fun start() {
        connectToZookeeper()
        participateInElection()
    }

    // FECHA A CONEXÃO QUANDO O CONTAINER FOR DESLIGADO
    @PreDestroy
    fun stop() {
        try {
            logger.info("Encerrando conexao com o ZooKeeper...")
            zk.close()
        } catch (e: Exception) {
            logger.error("Erro ao fechar conexao do ZooKeeper", e)
        }
    }

    private fun connectToZookeeper() {
        val connectedSignal = CountDownLatch(1)
        val zkHost = System.getenv("ZOOKEEPER_URL") ?: "localhost:2181"

        zk = ZooKeeper(zkHost, 3000) { event ->
            when (event.state) {
                Watcher.Event.KeeperState.SyncConnected -> {
                    logger.info("Conexao com ZooKeeper estabelecida!")
                    connectedSignal.countDown()
                }
                Watcher.Event.KeeperState.Expired, Watcher.Event.KeeperState.Disconnected -> {
                    // Se a conexão com o ZK cair pesadamente, pausamos o MQTT por segurança
                    logger.warn("Conexao com ZooKeeper perdida/expirada! Pausando MQTT preventivamente.")
                    if (mqttAdapter.isRunning) mqttAdapter.stop()
                }
                else -> {} // Outros estados não importam aqui
            }
        }
        
        connectedSignal.await() // Espera a conexão firmar
        
        try {
            if (zk.exists(ELECTION_NAMESPACE, false) == null) {
                zk.create(ELECTION_NAMESPACE, ByteArray(0), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT)
            }
        } catch (e: KeeperException.NodeExistsException) {
            // Outro nó já criou, tudo bem.
        } catch (e: Exception) {
            logger.error("Erro ao criar namespace de eleicao", e)
        }
    }

    private fun participateInElection() {
        try {
            val nodePrefix = "$ELECTION_NAMESPACE/candidato_"
            val createdPath = zk.create(nodePrefix, ByteArray(0), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL)
            
            currentZNodeName = createdPath.replace("$ELECTION_NAMESPACE/", "")
            logger.info("Entrei na eleicao como: $currentZNodeName")

            checkLeadership()
        } catch (e: Exception) {
            logger.error("Erro ao participar da eleicao. Tentando novamente em breve...", e)
        }
    }

    private fun checkLeadership() {
        try {
            val children = zk.getChildren(ELECTION_NAMESPACE, false)
            Collections.sort(children)

            val myIndex = children.indexOf(currentZNodeName)

            if (myIndex == 0) {
                logger.info("*** EU SOU O LIDER! Ligando consumidor MQTT... ***")
                if (!mqttAdapter.isRunning) {
                    mqttAdapter.start()
                    logger.info("Consumidor MQTT Iniciado com sucesso!")
                }
            } else {
                if (mqttAdapter.isRunning) {
                    mqttAdapter.stop()
                    logger.info("Consumidor MQTT Pausado (nao sou mais o lider).")
                }
                
                val predecessorName = children[myIndex - 1]
                val predecessorPath = "$ELECTION_NAMESPACE/$predecessorName"
                
                logger.info("Nao sou o lider. Ficarei vigiando a queda do no: $predecessorName")
                
                // O bloco TRY lida com a rara chance de o predecessor ter caido no exato milissegundo 
                // entre o getChildren e o exists
                val stat = zk.exists(predecessorPath, this)
                if (stat == null) {
                    checkLeadership() 
                }
            }
        } catch (e: Exception) {
            logger.error("Erro ao checar a lideranca", e)
        }
    }

    override fun process(event: WatchedEvent) {
        if (event.type == Watcher.Event.EventType.NodeDeleted) {
            logger.info("O no que eu estava vigiando caiu! Vou verificar se sou o novo lider...")
            checkLeadership()
        }
    }
}