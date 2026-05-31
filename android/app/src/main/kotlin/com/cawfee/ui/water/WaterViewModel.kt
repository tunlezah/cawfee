package com.cawfee.ui.water

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.local.WaterProfileEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class WaterViewModel @Inject constructor(
    private val repo: CoffeeRepository,
) : ViewModel() {

    val profiles: StateFlow<List<WaterProfileEntity>> =
        repo.waterProfiles.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun save(
        existing: WaterProfileEntity?,
        name: String,
        detail: String,
        calcium: Double,
        magnesium: Double,
        bicarbonate: Double,
        totalHardness: Double,
    ) = viewModelScope.launch {
        repo.upsertWater(
            WaterProfileEntity(
                id = existing?.id ?: UUID.randomUUID().toString(),
                name = name,
                detail = detail,
                calcium = calcium,
                magnesium = magnesium,
                bicarbonate = bicarbonate,
                totalHardness = totalHardness,
                isDefault = existing?.isDefault ?: false,
                isSeeded = existing?.isSeeded ?: false,
                sortOrder = existing?.sortOrder ?: 100,
            )
        )
    }

    fun makeDefault(profile: WaterProfileEntity) = viewModelScope.launch { repo.makeWaterDefault(profile) }
    fun delete(profile: WaterProfileEntity) = viewModelScope.launch { repo.deleteWater(profile) }
}
