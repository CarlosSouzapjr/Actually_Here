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

    // Criar nova turma
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(@RequestBody classRequest: ClassRequest): Class {
        val professor = userRepository.findById(classRequest.professorId)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "Professor não encontrado") }
        
        val newClass = Class(
            name = classRequest.name,
            subjectCode = classRequest.subjectCode,
            professor = professor
        )
        return classRepository.save(newClass)
    }

    // Listar todas as turmas cadastradas
    @GetMapping
    fun listAll(): List<Class> = classRepository.findAll()

    // Listar turmas de um professor específico
    @GetMapping("/professor/{id}")
    fun listByProfessor(@PathVariable id: Long): List<Class> = 
        classRepository.findByProfessorId(id)
}

// Classe auxiliar para receber os dados do Flutter/Frontend
data class ClassRequest(
    val name: String,
    val subjectCode: String,
    val professorId: Long
)