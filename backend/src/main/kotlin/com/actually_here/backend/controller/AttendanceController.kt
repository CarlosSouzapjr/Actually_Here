package com.actually_here.backend.controller

import com.actually_here.backend.model.AttendanceSession
import com.actually_here.backend.model.SessionStatus
import com.actually_here.backend.repository.AttendanceSessionRepository
import com.actually_here.backend.repository.ClassRepository
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import org.springframework.web.server.ResponseStatusException
import java.time.LocalDateTime

@RestController
@RequestMapping("/api/attendance")
class AttendanceController(
    private val attendanceSessionRepository: AttendanceSessionRepository,
    private val classRepository: ClassRepository
) {

    @PostMapping("/start/{classId}")
    @ResponseStatus(HttpStatus.CREATED)
    fun startSession(@PathVariable classId: Long): AttendanceSession {
        // Verifica se a turma existe
        val classroom = classRepository.findById(classId)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Turma não encontrada") }

        // Verifica se já existe uma sessão ativa para esta turma para evitar duplicidade
        val existingSession = attendanceSessionRepository.findFirstByClassroomIdAndStatus(classId, SessionStatus.ACTIVE)
        if (existingSession.isPresent) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Já existe uma sessão ativa para esta turma")
        }

        val session = AttendanceSession(classroom = classroom)
        return attendanceSessionRepository.save(session)
    }

    @PostMapping("/end/{sessionId}")
    fun endSession(@PathVariable sessionId: Long): AttendanceSession {
        val session = attendanceSessionRepository.findById(sessionId)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Sessão não encontrada") }

        if (session.status == SessionStatus.FINISHED) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Esta sessão já foi encerrada")
        }

        session.status = SessionStatus.FINISHED
        session.endTime = LocalDateTime.now()
        
        // Futuramente: disparar o cálculo de porcentagem de presença aqui
        
        return attendanceSessionRepository.save(session)
    }

    @GetMapping("/active/{classId}")
    fun getActiveSession(@PathVariable classId: Long): AttendanceSession {
        return attendanceSessionRepository.findFirstByClassroomIdAndStatus(classId, SessionStatus.ACTIVE)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Nenhuma sessão ativa encontrada") }
    }
}
