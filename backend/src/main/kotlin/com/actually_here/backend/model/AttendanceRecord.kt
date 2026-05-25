package com.actually_here.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

@Entity
@Table(name = "attendance_records")
data class AttendanceRecord(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    val session: AttendanceSession,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    val user: User,

    @Column(nullable = false)
    val distance: Double,

    @Column(nullable = false)
    val timestamp: LocalDateTime = LocalDateTime.now()
)
