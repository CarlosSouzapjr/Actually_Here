package com.actually_here.backend.repository

import com.actually_here.backend.model.AttendanceRecord
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface AttendanceRecordRepository : JpaRepository<AttendanceRecord, Long>
