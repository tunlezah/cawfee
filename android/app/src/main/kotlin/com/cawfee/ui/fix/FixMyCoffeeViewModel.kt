package com.cawfee.ui.fix

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.PreferencesRepository
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.HistoryEntity
import com.cawfee.data.snapshot
import com.cawfee.domain.model.Adjustment
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.Milk
import com.cawfee.domain.model.MilkKind
import com.cawfee.domain.model.Recommendation
import com.cawfee.domain.model.Symptom
import com.cawfee.domain.rules.RulesEngine
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

data class FixUiState(
    val drink: DrinkType = DrinkType.CAPPUCCINO,
    val milkKind: MilkKind = MilkKind.DEVONDALE_FULL_CREAM_UHT,
    val settings: MachineSettings = MachineSettings.defaultCappuccino,
    val selectedSymptoms: Set<Symptom> = emptySet(),
    val selectedBeanSlug: String? = null,
    val recommendation: Recommendation? = null,
    val didApply: Boolean = false,
)

/**
 * ViewModel for Fix My Coffee / Expert mode. Ported from FixMyCoffeeViewModel.swift:
 * loads defaults from preferences, feeds the selected bean + recent history into the
 * rules engine, and persists every applied adjustment to history.
 */
@HiltViewModel
class FixMyCoffeeViewModel @Inject constructor(
    private val repo: CoffeeRepository,
    private val preferences: PreferencesRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(FixUiState())
    val state: StateFlow<FixUiState> = _state.asStateFlow()

    val beans: StateFlow<List<BeanEntity>> =
        repo.beans.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    init {
        // Mirror loadDefaults(from:) — seed the drink/settings from the user default.
        viewModelScope.launch {
            val prefs = preferences.prefs.first()
            _state.update {
                it.copy(drink = prefs.defaultDrink, settings = MachineSettings.defaults(prefs.defaultDrink))
            }
        }
    }

    fun setDrink(drink: DrinkType) = _state.update {
        it.copy(drink = drink, settings = MachineSettings.defaults(drink), recommendation = null, didApply = false)
    }

    fun setMilkKind(kind: MilkKind) = _state.update { it.copy(milkKind = kind) }

    fun setSettings(settings: MachineSettings) = _state.update { it.copy(settings = settings) }

    fun setBean(slug: String?) = _state.update { it.copy(selectedBeanSlug = slug) }

    fun toggle(symptom: Symptom) = _state.update { s ->
        val next = if (symptom in s.selectedSymptoms) s.selectedSymptoms - symptom else s.selectedSymptoms + symptom
        s.copy(selectedSymptoms = next)
    }

    fun clearSymptoms() = _state.update { it.copy(selectedSymptoms = emptySet(), recommendation = null, didApply = false) }

    fun evaluate(novice: Boolean) = viewModelScope.launch {
        val s = _state.value
        val bean = beans.value.firstOrNull { it.slug == s.selectedBeanSlug }?.snapshot()
        val recentHistory = repo.history.first().map { it.snapshot() }
        val rec = RulesEngine.evaluate(
            symptoms = s.selectedSymptoms.toList(),
            current = s.settings,
            milk = Milk.canonical(s.milkKind),
            drink = s.drink,
            bean = bean,
            recentHistory = recentHistory,
            novice = novice,
        )
        _state.update { it.copy(recommendation = rec, didApply = false) }
    }

    /** Apply the primary (and secondary) adjustment, then persist a history entry. */
    fun applyAndLog() = viewModelScope.launch {
        val s = _state.value
        val rec = s.recommendation ?: return@launch
        val primary: Adjustment = rec.primary ?: return@launch
        val before = s.settings
        var after = primary.apply(before)
        rec.secondary?.let { after = it.apply(after) }

        val beanName = beans.value.firstOrNull { it.slug == s.selectedBeanSlug }?.name
        repo.upsertHistory(
            HistoryEntity(
                id = UUID.randomUUID().toString(),
                dateMillis = System.currentTimeMillis(),
                drink = s.drink.name,
                beanName = beanName,
                symptoms = s.selectedSymptoms.map { it.name },
                beforeGrinder = before.grinder,
                beforeStrength = before.strength,
                beforeVolumeML = before.volumeML,
                beforeMilkSeconds = before.milkSeconds,
                beforeTemperature = before.temperature.name,
                afterGrinder = after.grinder,
                afterStrength = after.strength,
                afterVolumeML = after.volumeML,
                afterMilkSeconds = after.milkSeconds,
                afterTemperature = after.temperature.name,
                primaryParameter = primary.parameter.name,
                outcome = com.cawfee.domain.model.AdjustmentOutcome.UNKNOWN.name,
                rationale = rec.rationale,
                confidence = rec.confidence,
            )
        )
        _state.update { it.copy(settings = after, didApply = true) }
    }
}
