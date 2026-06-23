package com.actually_here.backend.config

import com.actually_here.backend.model.AttendanceRecord
import com.actually_here.backend.model.SessionStatus
import com.actually_here.backend.repository.AttendanceRecordRepository
import com.actually_here.backend.repository.AttendanceSessionRepository
import com.actually_here.backend.repository.UserRepository
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.integration.annotation.ServiceActivator
import org.springframework.integration.channel.DirectChannel
import org.springframework.integration.mqtt.core.DefaultMqttPahoClientFactory
import org.springframework.integration.mqtt.core.MqttPahoClientFactory
import org.springframework.integration.mqtt.inbound.MqttPahoMessageDrivenChannelAdapter
import org.springframework.integration.mqtt.support.DefaultPahoMessageConverter
import org.springframework.messaging.Message
import org.springframework.messaging.MessageChannel

@Configuration
class MqttConfig(
    private val attendanceRecordRepository: AttendanceRecordRepository,
    private val attendanceSessionRepository: AttendanceSessionRepository,
    private val userRepository: UserRepository,
    @Value("\${mqtt.broker-url:tcp://localhost:1883}")
    private val mqttBrokerUrl: String
) {

    @Bean
    fun objectMapper(): ObjectMapper = jacksonObjectMapper()

    @Bean
    fun mqttClientFactory(): MqttPahoClientFactory {
        val factory = DefaultMqttPahoClientFactory()
        val options = MqttConnectOptions()
        options.serverURIs = arrayOf(mqttBrokerUrl)
        options.isCleanSession = true
        factory.connectionOptions = options
        return factory
    }

    @Bean
    fun mqttInputChannel(): MessageChannel {
        return DirectChannel()
    }

    @Bean
    fun inbound(): MqttPahoMessageDrivenChannelAdapter {
        val clientId = "backend-subscriber-${java.util.UUID.randomUUID()}"
        
        val adapter = MqttPahoMessageDrivenChannelAdapter(
            clientId, 
            mqttClientFactory(), 
            "presenca/+/+"
        )
        adapter.setCompletionTimeout(5000)
        adapter.setConverter(DefaultPahoMessageConverter())
        adapter.setQos(1)
        adapter.setOutputChannel(mqttInputChannel()) 
        
        adapter.setAutoStartup(false)
        
        return adapter
    }

    // A mudança principal está aqui:
    // Removemos o @Bean e deixamos apenas o @ServiceActivator recebendo a Mensagem diretamente
    @ServiceActivator(inputChannel = "mqttInputChannel")
    fun processMqttMessage(message: Message<*>) {
        val payload = message.payload.toString()
        val topic = message.headers["mqtt_receivedTopic"]?.toString() ?: return
        
        try {
            val topicParts = topic.split("/")
            if (topicParts.size == 3) {
                val classId = topicParts[1].toLong()
                val userId = topicParts[2].toLong()
                
                val mapper = objectMapper()
                val data = mapper.readTree(payload)
                val distance = data.get("distancia").asDouble()

                val session = attendanceSessionRepository.findFirstByClassroomIdAndStatus(classId, SessionStatus.ACTIVE)
                
                if (session.isPresent) {
                    val user = userRepository.findById(userId)
                    if (user.isPresent) {
                        val record = AttendanceRecord(
                            session = session.get(),
                            user = user.get(),
                            distance = distance
                        )
                        attendanceRecordRepository.save(record)
                        println("Presenca registrada: Aluno ${user.get().name} na Turma ${classId} (Distancia: $distance m)")
                    }
                } else {
                    println("Aviso: Ping recebido para turma $classId, mas nao ha sessao ativa.")
                }
            }
        } catch (e: Exception) {
            println("Erro ao processar mensagem MQTT: ${e.message}")
        }
    }
}