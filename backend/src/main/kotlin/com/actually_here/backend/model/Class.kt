package com.actually_here.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "classroom")
data class Class(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,
    
    @Column(nullable = false)
    val name: String, // Ex: "Sistemas Distribuídos - 2026.1"
    
    @Column(nullable = false)
    val subjectCode: String, // Código da Disciplina
    
    // Relação: Muitos alunos/turmas para um professor
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "professor_id", nullable = false)
    val professor: User
)