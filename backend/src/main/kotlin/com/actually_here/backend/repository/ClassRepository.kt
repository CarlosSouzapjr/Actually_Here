package com.actually_here.backend.repository

import com.actually_here.backend.model.Class
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository

@Repository
interface ClassRepository : JpaRepository<Class, Long>{
    
    // Busca todas as turmas de um professor específico
    fun findByProfessorId(professorId: Long): List<Class>
}