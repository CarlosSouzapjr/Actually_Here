package com.actually_here.backend.controller

import com.actually_here.backend.model.Class
import com.actually_here.backend.repository.ClassRepository
import com.actually_here.backend.repository.UserRepository
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import org.springframework.web.server.ResponseStatusException

@RestController
@RequestMapping("/api/turmas")
class ClassController(
    private val classRepository: ClassRepository,
    private val userRepository: UserRepository
) {

    // Criar nova turma (O usuário que cria já entra como administrador)
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(@RequestBody request: ClassRequest): Class {
        // Busca quem está tentando criar a turma
        val professor = userRepository.findById(request.professorId)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Professor não encontrado") }
        
        val newClass = Class(
            name = request.name,
            subjectCode = request.subjectCode,
            professor = professor
        )

        return classRepository.save(newClass)
    }

    @GetMapping("/Professor/{id}")
    fun listByProfessorId(@PathVariable id: Long): List<Class> { // ou Turma
        return classRepository.findByProfessorId(id)
    }

}

// Classe auxiliar para receber os dados do Flutter/Frontend
data class ClassRequest(
    val name: String,
    val subjectCode: String,
    val professorId: Long
)