package com.cawfee.ui.shots

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.local.ShotEntity
import com.cawfee.domain.model.DrinkType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ShotTimerState(
    val elapsedMs: Long = 0,
    val isRunning: Boolean = false,
    val preInfusionMs: Long? = null,
)

/** Espresso shot stopwatch with persistence. Ported from ShotTimerViewModel.swift +
 * ShotTimerView.swift (the save step). Saved shots drive the Maintenance shot counter. */
@HiltViewModel
class ShotTimerViewModel @Inject constructor(
    private val repo: CoffeeRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(ShotTimerState())
    val state: StateFlow<ShotTimerState> = _state.asStateFlow()

    val shotCount: StateFlow<Int> =
        repo.shotCount.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0)

    private var ticker: Job? = null
    private var startUptime: Long = 0
    private var accumulated: Long = 0

    fun startOrStop() {
        if (_state.value.isRunning) stop() else start()
    }

    private fun start() {
        startUptime = System.currentTimeMillis()
        _state.update { it.copy(isRunning = true) }
        ticker = viewModelScope.launch {
            while (true) {
                delay(50)
                val now = System.currentTimeMillis()
                _state.update { it.copy(elapsedMs = accumulated + (now - startUptime)) }
            }
        }
    }

    private fun stop() {
        ticker?.cancel()
        accumulated += System.currentTimeMillis() - startUptime
        _state.update { it.copy(isRunning = false, elapsedMs = accumulated) }
    }

    fun markPreInfusion() {
        _state.update { it.copy(preInfusionMs = it.elapsedMs) }
    }

    fun reset() {
        ticker?.cancel()
        accumulated = 0
        _state.value = ShotTimerState()
    }

    /** Persist the current timed shot, then reset the stopwatch. */
    fun saveShot(drink: DrinkType, doseGrams: Double, yieldGrams: Double, rating: Int, notes: String) {
        val s = _state.value
        viewModelScope.launch {
            repo.insertShot(
                ShotEntity(
                    dateMillis = System.currentTimeMillis(),
                    beanName = null,
                    drink = drink.name,
                    doseGrams = doseGrams,
                    yieldGrams = yieldGrams,
                    preInfusionSeconds = (s.preInfusionMs ?: 0L) / 1000.0,
                    totalSeconds = s.elapsedMs / 1000.0,
                    rating = rating,
                    notes = notes,
                )
            )
            reset()
        }
    }

    companion object {
        /** "27.4" style formatting. */
        fun format(ms: Long): String = "%.1f".format(ms / 1000.0)
    }
}
