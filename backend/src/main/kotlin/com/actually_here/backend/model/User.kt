package com.actually_here.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "users")
data class User(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,
    
    @Column(nullable = false)
    val name: String,
    
    @Column(nullable = false, unique = true)
    val email: String,
    
    // Pode ser uma string temporária como "PROFESSOR" ou "ALUNO"
    @Column(nullable = false)
    val type: String, 
    
    // O ID que o Auth0 vai gerar para esse usuário no futuro
    @Column(name = "auth_id", unique = true)
    val authId: String? = null
)