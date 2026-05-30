package com.cawfee.ui.recipes

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.RecipeEntity
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.MilkKind
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class RecipesViewModel @Inject constructor(
    private val repo: CoffeeRepository,
) : ViewModel() {

    val recipes: StateFlow<List<RecipeEntity>> =
        repo.recipes.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val beans: StateFlow<List<BeanEntity>> =
        repo.beans.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun save(
        existing: RecipeEntity?,
        name: String,
        drink: DrinkType,
        milkKind: MilkKind,
        beanSlug: String?,
        settings: MachineSettings,
        notes: String,
        isFavourite: Boolean,
        isLastGood: Boolean,
    ) = viewModelScope.launch {
        val entity = RecipeEntity(
            id = existing?.id ?: UUID.randomUUID().toString(),
            name = name,
            drink = drink.name,
            milkKind = milkKind.name,
            grinder = settings.grinder,
            strength = settings.strength,
            volumeML = settings.volumeML,
            milkSeconds = settings.milkSeconds,
            temperature = settings.temperature.name,
            isFavourite = isFavourite,
            isLastGood = isLastGood,
            createdAtMillis = existing?.createdAtMillis ?: System.currentTimeMillis(),
            notes = notes,
            beanSlug = beanSlug,
        )
        repo.setRecipeLastGood(entity, isLastGood)
    }

    fun delete(recipe: RecipeEntity) = viewModelScope.launch { repo.deleteRecipe(recipe) }
}
