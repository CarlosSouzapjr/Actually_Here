package com.actually_here.backend.repository

import com.actually_here.backend.model.UserClass
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface UserClassRepository : JpaRepository<UserClass, Long>