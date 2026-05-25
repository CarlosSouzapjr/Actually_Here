package com.actually_here.backend.model

import jakarta.persistence.*
import java.time.LocalDateTime

enum class SessionStatus {
    ACTIVE, FINISHED
}

@Entity
@Table(name = "attendance_sessions")
data class AttendanceSession(
    @Id 
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_id", nullable = false)
    val classroom: Class,

    @Column(nullable = false)
    val startTime: LocalDateTime = LocalDateTime.now(),

    var endTime: LocalDateTime? = null,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    var status: SessionStatus = SessionStatus.ACTIVE,

    @Column(nullable = false)
    val expectedIntervalMinutes: Int = 5
)
