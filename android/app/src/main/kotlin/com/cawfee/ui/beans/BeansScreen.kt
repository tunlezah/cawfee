package com.cawfee.ui.beans

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.data.freshness
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.recommendedSettings
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.RoastLevel
import com.cawfee.ui.components.MachineSettingsEditor
import com.cawfee.ui.components.SectionCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BeansScreen(viewModel: BeansViewModel = hiltViewModel()) {
    val beans by viewModel.beans.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<BeanEntity?>(null) }
    var showEditor by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Beans") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { editing = null; showEditor = true }) {
                Icon(Icons.Filled.Add, contentDescription = "New bean")
            }
        },
    ) { padding ->
        if (beans.isEmpty()) {
            Column(
                Modifier.fillMaxSize().padding(padding).padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) { Text("No beans yet. Tap + to add your first roast.") }
        } else {
            val grouped = beans.groupBy { it.roaster }.toSortedMap()
            LazyColumn(
                Modifier.fillMaxSize().padding(padding).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                grouped.forEach { (roaster, list) ->
                    item(key = "h_$roaster") {
                        Text(roaster, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.titleSmall)
                    }
                    items(list, key = { it.slug }) { bean ->
                        Card(onClick = { editing = bean; showEditor = true }, modifier = Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                                Text(bean.name, fontWeight = FontWeight.SemiBold)
                                Text(
                                    buildString {
                                        append(RoastLevel.valueOf(bean.roastLevel).displayName)
                                        if (bean.milkFriendly) append(" • milk-friendly")
                                    },
                                    style = MaterialTheme.typography.bodySmall,
                                )
                                if (bean.roastDateMillis != null) {
                                    Text(bean.freshness().summary, style = MaterialTheme.typography.bodySmall)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if (showEditor) {
        BeanEditorDialog(
            existing = editing,
            onDismiss = { showEditor = false },
            onSave = { name, roaster, roast, milk, notesList, settings, notes, roastDays, openedDays, grind ->
                val roastMillis = roastDays?.let { System.currentTimeMillis() - it * 86_400_000L }
                val openedMillis = openedDays?.let { System.currentTimeMillis() - it * 86_400_000L }
                val e = editing
                if (e == null) {
                    viewModel.create(name, roaster, roast, milk, notesList, settings, notes, roastMillis, openedMillis, grind)
                } else {
                    viewModel.update(e, name, roaster, roast, milk, notesList, settings, notes, roastMillis, openedMillis, grind)
                }
                showEditor = false
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BeanEditorDialog(
    existing: BeanEntity?,
    onDismiss: () -> Unit,
    onSave: (
        name: String, roaster: String, roast: RoastLevel, milkFriendly: Boolean,
        flavourNotes: List<String>, settings: MachineSettings, notes: String,
        roastDaysAgo: Int?, openedDaysAgo: Int?, grind: Int?,
    ) -> Unit,
) {
    var name by rememberSaveable { mutableStateOf(existing?.name ?: "") }
    var roaster by rememberSaveable { mutableStateOf(existing?.roaster ?: "") }
    var roast by remember { mutableStateOf(existing?.let { RoastLevel.valueOf(it.roastLevel) } ?: RoastLevel.MEDIUM) }
    var milkFriendly by rememberSaveable { mutableStateOf(existing?.milkFriendly ?: true) }
    var notesText by rememberSaveable { mutableStateOf(existing?.flavourNotes?.joinToString(", ") ?: "") }
    var settings by remember { mutableStateOf(existing?.recommendedSettings ?: MachineSettings()) }
    var notes by rememberSaveable { mutableStateOf(existing?.notes ?: "") }
    val initialRoastDays = existing?.roastDateMillis?.let {
        ((System.currentTimeMillis() - it) / 86_400_000L).toInt().coerceAtLeast(0).toString()
    } ?: ""
    var roastDays by rememberSaveable { mutableStateOf(initialRoastDays) }
    var grindText by rememberSaveable { mutableStateOf(existing?.currentGrindSetting?.toString() ?: "") }

    Dialog(onDismissRequest = onDismiss) {
        Card {
            Column(
                Modifier.padding(20.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    if (existing == null) "New Bean" else "Edit Bean",
                    style = MaterialTheme.typography.titleLarge,
                )
                OutlinedTextField(name, { name = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(roaster, { roaster = it }, label = { Text("Roaster") }, modifier = Modifier.fillMaxWidth())

                Text("Roast", fontWeight = FontWeight.Medium)
                SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
                    RoastLevel.entries.forEachIndexed { i, level ->
                        SegmentedButton(
                            selected = roast == level,
                            onClick = { roast = level },
                            shape = SegmentedButtonDefaults.itemShape(i, RoastLevel.entries.size),
                        ) { Text(level.displayName.take(3)) }
                    }
                }

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Text("Milk-friendly")
                    Switch(checked = milkFriendly, onCheckedChange = { milkFriendly = it })
                }

                OutlinedTextField(
                    notesText, { notesText = it },
                    label = { Text("Flavour notes (comma-separated)") },
                    modifier = Modifier.fillMaxWidth(),
                )

                SectionCard("Recommended settings") {
                    MachineSettingsEditor(settings, { settings = it }, showsMilk = true)
                }

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    OutlinedTextField(
                        roastDays, { roastDays = it.filter(Char::isDigit) },
                        label = { Text("Days since roast") }, modifier = Modifier.weight(1f),
                    )
                    OutlinedTextField(
                        grindText, { grindText = it.filter(Char::isDigit) },
                        label = { Text("Dialled grind") }, modifier = Modifier.weight(1f),
                    )
                }

                OutlinedTextField(notes, { notes = it }, label = { Text("Notes") }, modifier = Modifier.fillMaxWidth())

                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = onDismiss) { Text("Cancel") }
                    TextButton(
                        enabled = name.isNotBlank() && roaster.isNotBlank(),
                        onClick = {
                            val flav = notesText.split(",").map { it.trim() }.filter { it.isNotEmpty() }
                            onSave(
                                name, roaster, roast, milkFriendly, flav, settings, notes,
                                roastDays.toIntOrNull(), null, grindText.toIntOrNull(),
                            )
                        },
                    ) { Text(if (existing == null) "Create" else "Save") }
                }
            }
        }
    }
}
