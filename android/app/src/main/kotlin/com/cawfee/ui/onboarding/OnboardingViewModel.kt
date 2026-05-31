package com.cawfee.ui.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.PreferencesRepository
import com.cawfee.domain.model.DrinkType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val preferences: PreferencesRepository,
) : ViewModel() {

    /** Persist the chosen machine name + default drink and mark onboarding complete. */
    fun finish(machineName: String, drink: DrinkType) = viewModelScope.launch {
        if (machineName.isNotBlank()) preferences.setMachineName(machineName)
        preferences.setDefaultDrink(drink)
        preferences.setOnboardingComplete(true)
    }
}
