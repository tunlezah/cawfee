package com.cawfee.ui.history

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.local.HistoryEntity
import com.cawfee.data.local.RecipeEntity
import com.cawfee.domain.model.AdjustmentOutcome
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HistoryViewModel @Inject constructor(
    private val repo: CoffeeRepository,
) : ViewModel() {

    val entries: StateFlow<List<HistoryEntity>> =
        repo.history.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val recipes: StateFlow<List<RecipeEntity>> =
        repo.recipes.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun setOutcome(entry: HistoryEntity, outcome: AdjustmentOutcome) = viewModelScope.launch {
        repo.upsertHistory(entry.copy(outcome = outcome.name))
    }

    fun delete(entry: HistoryEntity) = viewModelScope.launch { repo.deleteHistory(entry) }
}
