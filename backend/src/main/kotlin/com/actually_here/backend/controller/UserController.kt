package com.actually_here.backend.controller

import com.actually_here.backend.model.User
import com.actually_here.backend.repository.UserRepository
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/users")
class UserController(private val repository: UserRepository) {

    // Rota para cadastrar um novo usuário (Professor ou Aluno)
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun create(@RequestBody request: UserRequest): User {
        val newUser = User(
            name = request.name,
            email = request.email,
            authId = request.authId
        )
        // O Spring Data JPA salva no PostgreSQL automaticamente!
        return repository.save(newUser)
    }

    // Rota para listar todos os usuários do banco (retorna JSON)
    @GetMapping
    fun listarAll(): List<User> = repository.findAll()

    // Classe auxiliar (DTO) para receber os dados limpos do Flutter
    data class UserRequest(
        val name: String,
        val email: String,
        val authId: String? = null
    )
}