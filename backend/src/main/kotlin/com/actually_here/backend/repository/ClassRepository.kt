package com.actually_here.backend.repository

import com.actually_here.backend.model.Class // Ou o nome exato da sua entidade de Turma
import com.actually_here.backend.model.TipoMembro
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository

@Repository
interface ClassRepository : JpaRepository<Class, Long> {
    
    // Ajustamos para ler a entidade UserClass e buscar a propriedade classroom/user/role
    @Query("SELECT uc.classroom FROM UserClass uc WHERE uc.user.id = :userId AND uc.role = :role")
    fun findByUserIdAndRole(@Param("userId") userId: Long, @Param("role") role: TipoMembro): List<Class>

    @Query("SELECT uc.classroom FROM UserClass uc WHERE uc.user.id = :userId")
    fun findByUserId(@Param("userId") userId: Long): List<Class>
}