package com.actually_here.backend.model

import jakarta.persistence.*

@Entity
@Table(name = "classroom")
data class Class(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,
    
    @Column(nullable = false)
    val name: String,
    
    @Column(nullable = false)
    val subjectCode: String,
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "professor_id", nullable = false)
    val professor: User,

    // Lista de Alunos regulares
    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "class_students", // Cria outra tabela intermediária no banco
        joinColumns = [JoinColumn(name = "class_id")],
        inverseJoinColumns = [JoinColumn(name = "user_id")]
    )
    val students: MutableSet<User> = mutableSetOf()
)