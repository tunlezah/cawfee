package com.cawfee.ui.tasting

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.cawfee.data.CoffeeRepository
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.TastingNoteEntity
import com.cawfee.domain.model.DrinkType
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class TastingViewModel @Inject constructor(
    private val repo: CoffeeRepository,
) : ViewModel() {

    val notes: StateFlow<List<TastingNoteEntity>> =
        repo.tastingNotes.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val beans: StateFlow<List<BeanEntity>> =
        repo.beans.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    fun save(
        existing: TastingNoteEntity?,
        beanSlug: String?,
        beanName: String?,
        drink: DrinkType,
        descriptors: List<String>,
        body: Int,
        acidity: Int,
        sweetness: Int,
        bitterness: Int,
        rating: Int,
        freeText: String,
    ) = viewModelScope.launch {
        repo.upsertTastingNote(
            TastingNoteEntity(
                id = existing?.id ?: UUID.randomUUID().toString(),
                dateMillis = existing?.dateMillis ?: System.currentTimeMillis(),
                beanName = beanName,
                beanSlug = beanSlug,
                drink = drink.name,
                descriptors = descriptors.sorted(),
                body = body,
                acidity = acidity,
                sweetness = sweetness,
                bitterness = bitterness,
                rating = rating,
                freeText = freeText,
            )
        )
    }

    fun delete(note: TastingNoteEntity) = viewModelScope.launch { repo.deleteTastingNote(note) }
}
