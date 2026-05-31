package com.cawfee.ui.tasting

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.toMutableStateList
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.TastingNoteEntity
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.SensoryWheel
import com.cawfee.ui.components.StarRow
import java.text.DateFormat
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun TastingScreen(viewModel: TastingViewModel = hiltViewModel()) {
    val notes by viewModel.notes.collectAsStateWithLifecycle()
    val beans by viewModel.beans.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<TastingNoteEntity?>(null) }
    var showEditor by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Tasting Log") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { editing = null; showEditor = true }) {
                Icon(Icons.Filled.Add, contentDescription = "New tasting note")
            }
        },
    ) { padding ->
        if (notes.isEmpty()) {
            Column(Modifier.fillMaxSize().padding(padding).padding(24.dp)) {
                Text("No tasting notes yet. Tap + to log how a cup tasted using the flavour wheel.")
            }
        } else {
            LazyColumn(
                Modifier.fillMaxSize().padding(padding).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(notes, key = { it.id }) { note ->
                    Card(onClick = { editing = note; showEditor = true }, modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(note.beanName ?: "Unknown bean", fontWeight = FontWeight.SemiBold)
                                if (note.rating > 0) StarRow(note.rating)
                            }
                            Text(
                                "${DrinkType.valueOf(note.drink).displayName} · ${
                                    DateFormat.getDateInstance(DateFormat.MEDIUM).format(Date(note.dateMillis))
                                }",
                                style = MaterialTheme.typography.bodySmall,
                            )
                            if (note.descriptors.isNotEmpty()) {
                                FlowRow(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                    note.descriptors.forEach { d ->
                                        Text(d, style = MaterialTheme.typography.labelSmall)
                                    }
                                }
                            }
                            if (note.freeText.isNotEmpty()) {
                                Text(note.freeText, style = MaterialTheme.typography.bodySmall)
                            }
                        }
                    }
                }
            }
        }
    }

    if (showEditor) {
        TastingEditorDialog(
            existing = editing,
            beans = beans,
            onDismiss = { showEditor = false },
            canDelete = editing != null,
            onDelete = { editing?.let { viewModel.delete(it) }; showEditor = false },
            onSave = { slug, beanName, drink, descriptors, body, acidity, sweetness, bitterness, rating, free ->
                viewModel.save(editing, slug, beanName, drink, descriptors, body, acidity, sweetness, bitterness, rating, free)
                showEditor = false
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
private fun TastingEditorDialog(
    existing: TastingNoteEntity?,
    beans: List<BeanEntity>,
    onDismiss: () -> Unit,
    canDelete: Boolean,
    onDelete: () -> Unit,
    onSave: (
        beanSlug: String?, beanName: String?, drink: DrinkType, descriptors: List<String>,
        body: Int, acidity: Int, sweetness: Int, bitterness: Int, rating: Int, freeText: String,
    ) -> Unit,
) {
    var beanSlug by rememberSaveable { mutableStateOf(existing?.beanSlug) }
    var drink by remember { mutableStateOf(existing?.let { DrinkType.valueOf(it.drink) } ?: DrinkType.CAPPUCCINO) }
    val descriptors = remember { (existing?.descriptors ?: emptyList()).toMutableStateList() }
    var body by rememberSaveable { mutableStateOf(existing?.body ?: 0) }
    var acidity by rememberSaveable { mutableStateOf(existing?.acidity ?: 0) }
    var sweetness by rememberSaveable { mutableStateOf(existing?.sweetness ?: 0) }
    var bitterness by rememberSaveable { mutableStateOf(existing?.bitterness ?: 0) }
    var rating by rememberSaveable { mutableStateOf(existing?.rating ?: 0) }
    var freeText by rememberSaveable { mutableStateOf(existing?.freeText ?: "") }
    var beanMenu by remember { mutableStateOf(false) }

    Dialog(onDismissRequest = onDismiss) {
        Card {
            Column(
                Modifier.padding(20.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(if (existing == null) "New Tasting Note" else "Edit Tasting Note", style = MaterialTheme.typography.titleLarge)

                Box {
                    OutlinedButton(onClick = { beanMenu = true }, modifier = Modifier.fillMaxWidth()) {
                        Text(beans.firstOrNull { it.slug == beanSlug }?.let { "${it.name} · ${it.roaster}" } ?: "Bean: None")
                    }
                    DropdownMenu(expanded = beanMenu, onDismissRequest = { beanMenu = false }) {
                        DropdownMenuItem(text = { Text("None") }, onClick = { beanSlug = null; beanMenu = false })
                        beans.forEach { b ->
                            DropdownMenuItem(
                                text = { Text("${b.name} · ${b.roaster}") },
                                onClick = { beanSlug = b.slug; beanMenu = false },
                            )
                        }
                    }
                }

                Text("Drink", fontWeight = FontWeight.Medium)
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    DrinkType.entries.forEach { d ->
                        FilterChip(selected = drink == d, onClick = { drink = d }, label = { Text(d.displayName) })
                    }
                }

                Text("Flavour wheel", fontWeight = FontWeight.Medium)
                SensoryWheel.categories.forEach { category ->
                    Text(category.name, style = MaterialTheme.typography.labelLarge)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        category.descriptors.forEach { d ->
                            val on = d in descriptors
                            FilterChip(
                                selected = on,
                                onClick = { if (on) descriptors.remove(d) else descriptors.add(d) },
                                label = { Text(d) },
                            )
                        }
                    }
                }

                Text("Intensity", fontWeight = FontWeight.Medium)
                DotRow("Body", body) { body = it }
                DotRow("Acidity", acidity) { acidity = it }
                DotRow("Sweetness", sweetness) { sweetness = it }
                DotRow("Bitterness", bitterness) { bitterness = it }

                Text("Overall", fontWeight = FontWeight.Medium)
                Row {
                    for (i in 1..5) {
                        Icon(
                            imageVector = if (i <= rating) Icons.Filled.Star else Icons.Outlined.StarBorder,
                            contentDescription = null,
                            tint = if (i <= rating) Color(0xFFF5B301) else MaterialTheme.colorScheme.outline,
                            modifier = Modifier.size(28.dp).clickable { rating = if (rating == i) 0 else i },
                        )
                    }
                }
                OutlinedTextField(freeText, { freeText = it }, label = { Text("Free notes") }, modifier = Modifier.fillMaxWidth())

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (canDelete) TextButton(onClick = onDelete) { Text("Delete") }
                    Box(Modifier.weight(1f))
                    TextButton(onClick = onDismiss) { Text("Cancel") }
                    TextButton(onClick = {
                        val name = beans.firstOrNull { it.slug == beanSlug }?.name
                        onSave(beanSlug, name, drink, descriptors.toList(), body, acidity, sweetness, bitterness, rating, freeText)
                    }) { Text(if (existing == null) "Save" else "Update") }
                }
            }
        }
    }
}

@Composable
private fun DotRow(label: String, value: Int, onChange: (Int) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(label, modifier = Modifier.size(width = 90.dp, height = 24.dp))
        for (i in 1..5) {
            Box(
                Modifier
                    .size(20.dp)
                    .clickable { onChange(if (value == i) 0 else i) },
            ) {
                Icon(
                    imageVector = if (i <= value) Icons.Filled.Star else Icons.Outlined.StarBorder,
                    contentDescription = null,
                    tint = if (i <= value) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline,
                )
            }
        }
    }
}
