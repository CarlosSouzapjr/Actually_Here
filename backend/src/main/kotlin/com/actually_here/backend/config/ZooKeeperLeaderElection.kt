package com.actually_here.backend.config

import org.apache.zookeeper.*
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.util.Collections
import java.util.concurrent.CountDownLatch
import jakarta.annotation.PostConstruct

@Service
class ZooKeeperLeaderElection : Watcher {

    private val logger = LoggerFactory.getLogger(ZooKeeperLeaderElection::class.java)
    private lateinit var zk: ZooKeeper
    private var currentZNodeName: String? = null
    
    private val ELECTION_NAMESPACE = "/election"
    
    @PostConstruct
    fun start() {
        connectToZookeeper()
        participateInElection()
    }

    private fun connectToZookeeper() {
        val connectedSignal = CountDownLatch(1)
        
        // Lemos a variável de ambiente do Docker. Se não existir, usamos localhost
        val zkHost = System.getenv("ZOOKEEPER_URL") ?: "localhost:2181"

        // Conecta ao ZK usando a variável dinâmica
        zk = ZooKeeper(zkHost, 3000) { event ->
            if (event.state == Watcher.Event.KeeperState.SyncConnected) {
                connectedSignal.countDown()
            }
        }
        
        connectedSignal.await() // Espera conectar
        logger.info("Conectado ao ZooKeeper no endereço: $zkHost")
        
        // Cria a pasta raiz se não existir
        if (zk.exists(ELECTION_NAMESPACE, false) == null) {
            try {
                zk.create(ELECTION_NAMESPACE, ByteArray(0), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.PERSISTENT)
            } catch (e: KeeperException.NodeExistsException) {
                // Outro nó já criou, tudo bem.
            }
        }
    }

    private fun participateInElection() {
        // 1. Cria seu próprio nó efêmero sequencial
        val nodePrefix = "$ELECTION_NAMESPACE/candidato_"
        val createdPath = zk.create(nodePrefix, ByteArray(0), ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL)
        
        currentZNodeName = createdPath.replace("$ELECTION_NAMESPACE/", "")
        logger.info("Entrei na eleição como: $currentZNodeName")

        checkLeadership()
    }

    private fun checkLeadership() {
        // 2. Pega todos os candidatos e ordena
        val children = zk.getChildren(ELECTION_NAMESPACE, false)
        Collections.sort(children)

        val myIndex = children.indexOf(currentZNodeName)

        if (myIndex == 0) {
            // 3. Sou o primeiro da fila! Sou o Líder!
            logger.info("*** EU SOU O LÍDER! Ligando consumidor MQTT... ***")
            // TODO: Aqui vocês ativam o serviço que lê as mensagens do Mosquitto
        } else {
            // 4. Não sou o líder. Vou vigiar o cara que está logo à minha frente na fila.
            val predecessorName = children[myIndex - 1]
            val predecessorPath = "$ELECTION_NAMESPACE/$predecessorName"
            
            logger.info("Não sou o líder. Ficarei vigiando a queda do nó: $predecessorName")
            
            // Coloca o Watcher (o true significa "avise esta classe quando mudar")
            val stat = zk.exists(predecessorPath, this)
            
            // Condição de corrida: se o cara caiu exatamente no milissegundo antes de eu botar o watcher
            if (stat == null) {
                checkLeadership() // Tenta de novo
            }
        }
    }

    // Este método é engatilhado pelo ZK automaticamente quando um nó que estamos vigiando é deletado (cai)
    override fun process(event: WatchedEvent) {
        if (event.type == Watcher.Event.EventType.NodeDeleted) {
            logger.info("O nó que eu estava vigiando caiu! Vou verificar se sou o novo líder...")
            checkLeadership()
        }
    }
}