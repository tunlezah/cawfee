package com.cawfee.ui.water

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
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
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.data.local.WaterProfileEntity

private fun assessmentLabel(hardness: Double): String = when {
    hardness < 50 -> "Soft"
    hardness <= 175 -> "In range"
    else -> "Hard"
}

private fun brewingHint(hardness: Double): String = when {
    hardness < 50 ->
        "Soft water (low scale risk) but can taste flat / under-extracted. Grind finer or push the ratio, and consider a remineraliser for clarity."
    hardness <= 175 ->
        "Hardness is in the sweet spot for extraction. Keep an eye on alkalinity if shots taste dull."
    else ->
        "Hard water extracts strongly but scales the machine. Descale more often and watch for chalky/bitter cups."
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WaterScreen(viewModel: WaterViewModel = hiltViewModel()) {
    val profiles by viewModel.profiles.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<WaterProfileEntity?>(null) }
    var showEditor by remember { mutableStateOf(false) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Water") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { editing = null; showEditor = true }) {
                Icon(Icons.Filled.Add, contentDescription = "New water profile")
            }
        },
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                Text(
                    "Water chemistry shapes extraction and scale build-up. Canberra tap is soft and low " +
                        "in bicarbonate — kind to the machine, but it can taste flat, so don't be afraid to grind finer.",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            items(profiles, key = { it.id }) { p ->
                Card(Modifier.fillMaxWidth()) {
                    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(p.name, fontWeight = FontWeight.SemiBold)
                            if (p.isDefault) AssistChip(onClick = {}, label = { Text("Default") })
                        }
                        if (p.detail.isNotEmpty()) Text(p.detail, style = MaterialTheme.typography.bodySmall)
                        Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                            Mineral("Ca", p.calcium); Mineral("Mg", p.magnesium)
                            Mineral("HCO₃", p.bicarbonate); Mineral("Hardness", p.totalHardness)
                        }
                        Text(assessmentLabel(p.totalHardness), fontWeight = FontWeight.Medium)
                        Text(brewingHint(p.totalHardness), style = MaterialTheme.typography.bodySmall)
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            if (!p.isDefault) TextButton(onClick = { viewModel.makeDefault(p) }) { Text("Make default") }
                            TextButton(onClick = { editing = p; showEditor = true }) { Text("Edit") }
                            if (!p.isSeeded) TextButton(onClick = { viewModel.delete(p) }) { Text("Delete") }
                        }
                    }
                }
            }
        }
    }

    if (showEditor) {
        WaterEditorDialog(
            existing = editing,
            onDismiss = { showEditor = false },
            onSave = { name, detail, ca, mg, hco3, hard ->
                viewModel.save(editing, name, detail, ca, mg, hco3, hard); showEditor = false
            },
        )
    }
}

@Composable
private fun Mineral(label: String, value: Double) {
    Column {
        Text("%.0f".format(value), fontWeight = FontWeight.SemiBold)
        Text("$label mg/L", style = MaterialTheme.typography.labelSmall)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun WaterEditorDialog(
    existing: WaterProfileEntity?,
    onDismiss: () -> Unit,
    onSave: (name: String, detail: String, ca: Double, mg: Double, hco3: Double, hardness: Double) -> Unit,
) {
    var name by rememberSaveable { mutableStateOf(existing?.name ?: "") }
    var detail by rememberSaveable { mutableStateOf(existing?.detail ?: "") }
    var ca by rememberSaveable { mutableStateOf(existing?.calcium?.toInt()?.toString() ?: "0") }
    var mg by rememberSaveable { mutableStateOf(existing?.magnesium?.toInt()?.toString() ?: "0") }
    var hco3 by rememberSaveable { mutableStateOf(existing?.bicarbonate?.toInt()?.toString() ?: "0") }
    var hard by rememberSaveable { mutableStateOf(existing?.totalHardness?.toInt()?.toString() ?: "0") }

    Dialog(onDismissRequest = onDismiss) {
        Card {
            Column(
                Modifier.padding(20.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(if (existing == null) "New Water Profile" else "Edit Water Profile", style = MaterialTheme.typography.titleLarge)
                OutlinedTextField(name, { name = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(detail, { detail = it }, label = { Text("Notes") }, modifier = Modifier.fillMaxWidth())
                NumField("Calcium (mg/L)", ca) { ca = it }
                NumField("Magnesium (mg/L)", mg) { mg = it }
                NumField("Bicarbonate (mg/L)", hco3) { hco3 = it }
                NumField("Total hardness (mg/L)", hard) { hard = it }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = onDismiss) { Text("Cancel") }
                    TextButton(
                        enabled = name.isNotBlank(),
                        onClick = {
                            onSave(
                                name, detail,
                                ca.toDoubleOrNull() ?: 0.0, mg.toDoubleOrNull() ?: 0.0,
                                hco3.toDoubleOrNull() ?: 0.0, hard.toDoubleOrNull() ?: 0.0,
                            )
                        },
                    ) { Text(if (existing == null) "Create" else "Save") }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun NumField(label: String, value: String, onChange: (String) -> Unit) {
    OutlinedTextField(
        value, { onChange(it.filter { c -> c.isDigit() }) },
        label = { Text(label) }, modifier = Modifier.fillMaxWidth(),
    )
}
