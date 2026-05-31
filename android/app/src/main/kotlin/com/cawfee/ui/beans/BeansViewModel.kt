package com.cawfee.ui.beans

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.local.BeanEntity
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.RoastLevel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.Locale
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class BeansViewModel @Inject constructor(
    private val repo: CoffeeRepository,
) : ViewModel() {

    val beans: StateFlow<List<BeanEntity>> =
        repo.beans.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    /** Insert a brand-new bean (generates a slug). */
    fun create(
        name: String,
        roaster: String,
        roastLevel: RoastLevel,
        milkFriendly: Boolean,
        flavourNotes: List<String>,
        settings: MachineSettings,
        notes: String,
        roastDateMillis: Long?,
        openedDateMillis: Long?,
        currentGrindSetting: Int?,
    ) = viewModelScope.launch {
        val bean = BeanEntity(
            slug = makeSlug(roaster, name),
            name = name,
            roaster = roaster,
            roastLevel = roastLevel.name,
            milkFriendly = milkFriendly,
            flavourNotes = flavourNotes,
            notes = notes,
            recGrinder = settings.grinder,
            recStrength = settings.strength,
            recVolumeML = settings.volumeML,
            recMilkSeconds = settings.milkSeconds,
            recTemperature = settings.temperature.name,
            createdAtMillis = System.currentTimeMillis(),
            isSeeded = false,
            roastDateMillis = roastDateMillis,
            openedDateMillis = openedDateMillis,
            currentGrindSetting = currentGrindSetting,
        )
        repo.upsertBean(bean)
    }

    /** Persist edits to an existing bean (keeps slug / created / seeded flags). */
    fun update(
        existing: BeanEntity,
        name: String,
        roaster: String,
        roastLevel: RoastLevel,
        milkFriendly: Boolean,
        flavourNotes: List<String>,
        settings: MachineSettings,
        notes: String,
        roastDateMillis: Long?,
        openedDateMillis: Long?,
        currentGrindSetting: Int?,
    ) = viewModelScope.launch {
        repo.updateBean(
            existing.copy(
                name = name,
                roaster = roaster,
                roastLevel = roastLevel.name,
                milkFriendly = milkFriendly,
                flavourNotes = flavourNotes,
                notes = notes,
                recGrinder = settings.grinder,
                recStrength = settings.strength,
                recVolumeML = settings.volumeML,
                recMilkSeconds = settings.milkSeconds,
                recTemperature = settings.temperature.name,
                roastDateMillis = roastDateMillis,
                openedDateMillis = openedDateMillis,
                currentGrindSetting = currentGrindSetting,
            )
        )
    }

    private fun makeSlug(roaster: String, name: String): String {
        val base = "$roaster-$name".lowercase(Locale.ROOT)
            .replace(" ", "-").replace("/", "-")
            .filter { it.isLetterOrDigit() || it == '-' }
        return "$base-${UUID.randomUUID().toString().take(6).lowercase(Locale.ROOT)}"
    }
}
