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
    
)