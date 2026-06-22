package com.actually_here.backend.controller

import com.actually_here.backend.model.Class
import com.actually_here.backend.model.UserClass
import com.actually_here.backend.model.TipoMembro
import com.actually_here.backend.repository.ClassRepository
import com.actually_here.backend.repository.UserClassRepository
import com.actually_here.backend.repository.UserRepository
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import org.springframework.web.server.ResponseStatusException

@RestController
@RequestMapping("/api/classes")
class ClassController(
    private val classRepository: ClassRepository,
    private val userClassRepository: UserClassRepository,
    private val userRepository: UserRepository
) {

    private fun Class.toResponse(): ClassResponse {
        val professors = this.id?.let { userClassRepository.findByClassroomIdAndRole(it, TipoMembro.PROFESSOR) } ?: emptyList()
        val professor = professors.firstOrNull()?.user
        return ClassResponse(
            id = this.id,
            name = this.name,
            subjectCode = this.subjectCode,
            professor = professor?.name,
            professorId = professor?.id
        )
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(@RequestBody request: ClassRequest): ClassResponse {
        val userCreator = userRepository.findById(request.professorId)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Usuário não encontrado") }
        
        // Cria a turma e salva no banco
        val novaTurma = classRepository.save(
            Class(name = request.name, subjectCode = request.subjectCode)
        )
        
        // Cria o vínculo definindo que este usuário é o PROFESSOR da turma recém-criada
        val userClass = UserClass(
            classroom = novaTurma,
            user = userCreator,
            role = TipoMembro.PROFESSOR
        )
        userClassRepository.save(userClass)
        
        return novaTurma.toResponse()
    }

    @GetMapping
    fun listarTodas(): List<ClassResponse> = classRepository.findAll().map { it.toResponse() }

    @GetMapping("/user/{id}")
    fun listByUser(@PathVariable id: Long): List<ClassResponse> {
        return classRepository.findByUserId(id).map { it.toResponse() }
    }

    @PostMapping("/{classId}/enroll/{studentId}")
    @ResponseStatus(HttpStatus.CREATED)
    fun enrollStudent(@PathVariable classId: Long, @PathVariable studentId: Long): ClassResponse {
        val classroom = classRepository.findById(classId)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Turma não encontrada") }
            
        val student = userRepository.findById(studentId)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Aluno não encontrado") }

        // Verifica se já está matriculado
        val isEnrolled = userClassRepository.findAll().any { it.classroom.id == classId && it.user.id == studentId }
        if (isEnrolled) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Usuário já está matriculado nesta turma")
        }

        val userClass = UserClass(
            classroom = classroom,
            user = student,
            role = TipoMembro.STUDENT
        )
        userClassRepository.save(userClass)
        
        return classroom.toResponse()
    }
}

data class ClassRequest(
    val name: String,
    val subjectCode: String,
    val professorId: Long 
)

data class ClassResponse(
    val id: Long?,
    val name: String,
    val subjectCode: String,
    val professor: String?,
    val professorId: Long?
)