package com.cawfee.ui.recipes

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Star
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
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.RecipeEntity
import com.cawfee.data.settings
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.MilkKind
import com.cawfee.ui.components.MachineSettingsEditor
import com.cawfee.ui.components.SectionCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RecipesScreen(viewModel: RecipesViewModel = hiltViewModel()) {
    val recipes by viewModel.recipes.collectAsStateWithLifecycle()
    val beans by viewModel.beans.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<RecipeEntity?>(null) }
    var showEditor by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Recipes") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { editing = null; showEditor = true }) {
                Icon(Icons.Filled.Add, contentDescription = "New recipe")
            }
        },
    ) { padding ->
        if (recipes.isEmpty()) {
            Column(Modifier.fillMaxSize().padding(padding).padding(24.dp)) {
                Text("No recipes yet — save one here or from Fix My Coffee.")
            }
        } else {
            LazyColumn(
                Modifier.fillMaxSize().padding(padding).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(recipes, key = { it.id }) { r ->
                    Card(onClick = { editing = r; showEditor = true }, modifier = Modifier.fillMaxWidth()) {
                        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                                if (r.isFavourite) {
                                    Icon(Icons.Filled.Star, null, tint = Color(0xFFF5B301))
                                }
                                Text(r.name, fontWeight = FontWeight.SemiBold)
                                if (r.isLastGood) {
                                    Text(
                                        "  LAST GOOD",
                                        color = MaterialTheme.colorScheme.primary,
                                        style = MaterialTheme.typography.labelSmall,
                                    )
                                }
                            }
                            Text(
                                "${DrinkType.valueOf(r.drink).displayName} • Grinder ${r.grinder} · Strength ${r.strength} · ${r.volumeML}ml",
                                style = MaterialTheme.typography.bodySmall,
                            )
                        }
                    }
                }
            }
        }
    }

    if (showEditor) {
        RecipeEditorDialog(
            existing = editing,
            beans = beans,
            onDismiss = { showEditor = false },
            canDelete = editing != null,
            onDelete = { editing?.let { viewModel.delete(it) }; showEditor = false },
            onSave = { name, drink, milk, beanSlug, settings, notes, fav, lastGood ->
                viewModel.save(editing, name, drink, milk, beanSlug, settings, notes, fav, lastGood)
                showEditor = false
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
private fun RecipeEditorDialog(
    existing: RecipeEntity?,
    beans: List<BeanEntity>,
    onDismiss: () -> Unit,
    canDelete: Boolean,
    onDelete: () -> Unit,
    onSave: (
        name: String, drink: DrinkType, milk: MilkKind, beanSlug: String?,
        settings: MachineSettings, notes: String, favourite: Boolean, lastGood: Boolean,
    ) -> Unit,
) {
    var name by rememberSaveable { mutableStateOf(existing?.name ?: "Untitled Recipe") }
    var drink by remember { mutableStateOf(existing?.let { DrinkType.valueOf(it.drink) } ?: DrinkType.CAPPUCCINO) }
    var milk by remember { mutableStateOf(existing?.let { MilkKind.valueOf(it.milkKind) } ?: MilkKind.DEVONDALE_FULL_CREAM_UHT) }
    var beanSlug by rememberSaveable { mutableStateOf(existing?.beanSlug) }
    var settings by remember { mutableStateOf(existing?.settings ?: MachineSettings.defaultCappuccino) }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    var favourite by rememberSaveable { mutableStateOf(existing?.isFavourite ?: false) }
    var lastGood by rememberSaveable { mutableStateOf(existing?.isLastGood ?: false) }
    var beanMenu by remember { mutableStateOf(false) }

    Dialog(onDismissRequest = onDismiss) {
        Card {
            Column(
                Modifier.padding(20.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(if (existing == null) "New Recipe" else "Edit Recipe", style = MaterialTheme.typography.titleLarge)
                OutlinedTextField(name, { name = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth())

                Text("Drink", fontWeight = FontWeight.Medium)
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    DrinkType.entries.forEach { d ->
                        FilterChip(selected = drink == d, onClick = { drink = d }, label = { Text(d.displayName) })
                    }
                }

                Text("Milk", fontWeight = FontWeight.Medium)
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    MilkKind.entries.forEach { m ->
                        FilterChip(selected = milk == m, onClick = { milk = m }, label = { Text(m.displayName) })
                    }
                }

                Box {
                    OutlinedButton(onClick = { beanMenu = true }, modifier = Modifier.fillMaxWidth()) {
                        Text(beans.firstOrNull { it.slug == beanSlug }?.let { "${it.roaster} — ${it.name}" } ?: "Bean: None")
                    }
                    DropdownMenu(expanded = beanMenu, onDismissRequest = { beanMenu = false }) {
                        DropdownMenuItem(text = { Text("None") }, onClick = { beanSlug = null; beanMenu = false })
                        beans.forEach { b ->
                            DropdownMenuItem(
                                text = { Text("${b.roaster} — ${b.name}") },
                                onClick = { beanSlug = b.slug; beanMenu = false },
                            )
                        }
                    }
                }

                SectionCard("Settings") {
                    MachineSettingsEditor(settings, { settings = it }, showsMilk = drink.isMilkBased)
                }

                OutlinedTextField(notes, { notes = it }, label = { Text("Notes") }, modifier = Modifier.fillMaxWidth())

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Favourite"); Switch(checked = favourite, onCheckedChange = { favourite = it })
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Last good"); Switch(checked = lastGood, onCheckedChange = { lastGood = it })
                }

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    if (canDelete) TextButton(onClick = onDelete) { Text("Delete") }
                    Box(Modifier.weight(1f))
                    TextButton(onClick = onDismiss) { Text("Cancel") }
                    TextButton(
                        enabled = name.isNotBlank(),
                        onClick = { onSave(name, drink, milk, beanSlug, settings, notes, favourite, lastGood) },
                    ) { Text(if (existing == null) "Create" else "Save") }
                }
            }
        }
    }
}
