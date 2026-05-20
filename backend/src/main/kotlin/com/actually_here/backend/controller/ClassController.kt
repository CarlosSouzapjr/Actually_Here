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

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(@RequestBody request: ClassRequest): Class {
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
        
        return novaTurma
    }

    @GetMapping
    fun listarTodas(): List<Class> = classRepository.findAll()

    // Essa rota usará a nossa @Query personalizada!
    @GetMapping("/professor/{id}")
    fun listByProfessor(@PathVariable id: Long): List<Class> {
        return classRepository.findByUserIdAndRole(id, TipoMembro.PROFESSOR)
    }
}

data class ClassRequest(
    val name: String,
    val subjectCode: String,
    val professorId: Long 
)