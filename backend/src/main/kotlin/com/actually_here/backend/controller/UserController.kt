package com.actually_here.backend.controller

import com.actually_here.backend.model.User
import com.actually_here.backend.repository.UserRepository
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/api/users")
class UserController(private val repository: UserRepository) {

    // Rota para testar se a API está viva
    @GetMapping("/ping")
    fun ping(): String = "Backend Kotlin respondendo com sucesso!"

    // Rota para listar todos os usuários do banco (retorna JSON)
    @GetMapping
    fun listarTodos(): List<User> = repository.findAll()
}