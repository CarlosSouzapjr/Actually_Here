package com.actually_here.backend.config

import com.actually_here.backend.model.AttendanceRecord
import com.actually_here.backend.model.SessionStatus
import com.actually_here.backend.repository.AttendanceRecordRepository
import com.actually_here.backend.repository.AttendanceSessionRepository
import com.actually_here.backend.repository.UserRepository
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.integration.annotation.ServiceActivator
import org.springframework.integration.channel.DirectChannel
import org.springframework.integration.core.MessageProducer
import org.springframework.integration.mqtt.core.DefaultMqttPahoClientFactory
import org.springframework.integration.mqtt.core.MqttPahoClientFactory
import org.springframework.integration.mqtt.inbound.MqttPahoMessageDrivenChannelAdapter
import org.springframework.integration.mqtt.support.DefaultPahoMessageConverter
import org.springframework.messaging.MessageChannel
import org.springframework.messaging.MessageHandler

@Configuration
class MqttConfig(
    private val attendanceRecordRepository: AttendanceRecordRepository,
    private val attendanceSessionRepository: AttendanceSessionRepository,
    private val userRepository: UserRepository
) {

    @Bean
    fun objectMapper(): ObjectMapper = jacksonObjectMapper()

    @Bean
    fun mqttClientFactory(): MqttPahoClientFactory {
        val factory = DefaultMqttPahoClientFactory()
        val options = MqttConnectOptions()
        options.serverURIs = arrayOf("tcp://localhost:1883")
        options.isCleanSession = true
        factory.connectionOptions = options
        return factory
    }

    @Bean
    fun mqttInputChannel(): MessageChannel {
        return DirectChannel()
    }

    @Bean
    fun inbound(): MessageProducer {
        val adapter = MqttPahoMessageDrivenChannelAdapter(
            "backend-subscriber", 
            mqttClientFactory(), 
            "presenca/+/+"
        )
        adapter.setCompletionTimeout(5000)
        adapter.setConverter(DefaultPahoMessageConverter())
        adapter.setQos(1)
        adapter.setOutputChannel(mqttInputChannel())
        return adapter
    }

    @Bean
    @ServiceActivator(inputChannel = "mqttInputChannel")
    fun handler(objectMapper: ObjectMapper): MessageHandler {
        return MessageHandler { message ->
            val payload = message.payload.toString()
            val topic = message.headers["mqtt_receivedTopic"].toString()
            
            try {
                // Tópico esperado: presenca/{classId}/{userId}
                val topicParts = topic.split("/")
                if (topicParts.size == 3) {
                    val classId = topicParts[1].toLong()
                    val userId = topicParts[2].toLong()
                    
                    val data = objectMapper.readTree(payload)
                    val distance = data.get("distancia").asDouble()

                    // Busca a sessão ativa para esta turma
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
                            println("Presença registrada: Aluno ${user.get().name} na Turma ${classId} (Distância: $distance m)")
                        }
                    } else {
                        println("Aviso: Ping recebido para turma $classId, mas não há sessão ativa.")
                    }
                }
            } catch (e: Exception) {
                println("Erro ao processar mensagem MQTT: ${e.message}")
            }
        }
    }
}
