package com.actually_here.backend.model

import jakarta.persistence.*

// Os papéis possíveis dentro de uma turma
enum class TipoMembro {
    PROFESSOR, STUDENT
}

@Entity
@Table(name = "user_class")
data class UserClass(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id", nullable = false)
    val classroom: Class,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    val role: TipoMembro
)