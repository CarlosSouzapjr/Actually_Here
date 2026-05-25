package com.actually_here.backend.repository

import com.actually_here.backend.model.AttendanceSession
import com.actually_here.backend.model.SessionStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.Optional

@Repository
interface AttendanceSessionRepository : JpaRepository<AttendanceSession, Long> {
    fun findFirstByClassroomIdAndStatus(classId: Long, status: SessionStatus): Optional<AttendanceSession>
}
