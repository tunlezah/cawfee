package com.cawfee.ui.maintenance

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.local.MaintenanceTaskEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class MaintenanceViewModel @Inject constructor(
    private val repo: CoffeeRepository,
) : ViewModel() {

    val tasks: StateFlow<List<MaintenanceTaskEntity>> =
        repo.maintenanceTasks.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val shotCount: StateFlow<Int> =
        repo.shotCount.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    fun markDone(task: MaintenanceTaskEntity, currentShotCount: Int) = viewModelScope.launch {
        repo.upsertTask(
            task.copy(
                lastCompletedMillis = System.currentTimeMillis(),
                lastCompletedShotCount = currentShotCount,
            )
        )
    }

    fun add(name: String, detail: String, intervalDays: Int?, intervalShots: Int?) = viewModelScope.launch {
        repo.upsertTask(
            MaintenanceTaskEntity(
                id = UUID.randomUUID().toString(),
                name = name,
                detail = detail,
                iconKey = "wrench",
                intervalDays = intervalDays,
                intervalShots = intervalShots,
                lastCompletedMillis = null,
                lastCompletedShotCount = 0,
                isSeeded = false,
                sortOrder = 100,
            )
        )
    }

    fun delete(task: MaintenanceTaskEntity) = viewModelScope.launch { repo.deleteTask(task) }
}

/** Due-ness helpers ported from MaintenanceTask.swift. */
private const val MS_PER_DAY = 86_400_000L

fun MaintenanceTaskEntity.daysUntilDue(now: Long = System.currentTimeMillis()): Int? {
    val days = intervalDays ?: return null
    val last = lastCompletedMillis ?: return 0
    val elapsed = ((now - last) / MS_PER_DAY).toInt()
    return days - elapsed
}

fun MaintenanceTaskEntity.shotsUntilDue(currentShotCount: Int): Int? {
    val shots = intervalShots ?: return null
    return shots - (currentShotCount - lastCompletedShotCount)
}

fun MaintenanceTaskEntity.isDue(currentShotCount: Int, now: Long = System.currentTimeMillis()): Boolean {
    daysUntilDue(now)?.let { if (it <= 0) return true }
    shotsUntilDue(currentShotCount)?.let { if (it <= 0) return true }
    return false
}
