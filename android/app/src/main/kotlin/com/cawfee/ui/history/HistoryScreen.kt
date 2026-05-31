package com.cawfee.ui.history

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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.data.afterSettings
import com.cawfee.data.beforeSettings
import com.cawfee.data.local.HistoryEntity
import com.cawfee.data.symptomList
import com.cawfee.domain.model.AdjustmentOutcome
import com.cawfee.domain.model.AdjustmentParameter
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.MachineSettings
import java.text.DateFormat
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun HistoryScreen(viewModel: HistoryViewModel = hiltViewModel()) {
    val entries by viewModel.entries.collectAsStateWithLifecycle()
    val recipes by viewModel.recipes.collectAsStateWithLifecycle()
    val lastGood = recipes.firstOrNull { it.isLastGood }

    Scaffold(topBar = { TopAppBar(title = { Text("History") }) }) { padding ->
        if (entries.isEmpty()) {
            Column(Modifier.fillMaxSize().padding(padding).padding(24.dp)) {
                Text("No history yet. Adjustments you apply from Fix My Coffee will appear here.")
            }
        } else {
            LazyColumn(
                Modifier.fillMaxSize().padding(padding).padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                if (lastGood != null) {
                    item(key = "lastgood") {
                        Card(Modifier.fillMaxWidth()) {
                            Column(Modifier.padding(16.dp)) {
                                Text("Last good recipe", fontWeight = FontWeight.SemiBold)
                                Text(lastGood.name)
                                Text(
                                    "Grinder ${lastGood.grinder} · Strength ${lastGood.strength} · ${lastGood.volumeML}ml",
                                    style = MaterialTheme.typography.bodySmall,
                                )
                            }
                        }
                    }
                }
                items(entries, key = { it.id }) { entry ->
                    HistoryRow(
                        entry = entry,
                        onOutcome = { viewModel.setOutcome(entry, it) },
                        onDelete = { viewModel.delete(entry) },
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun HistoryRow(
    entry: HistoryEntity,
    onOutcome: (AdjustmentOutcome) -> Unit,
    onDelete: () -> Unit,
) {
    var menu by remember { mutableStateOf(false) }
    val param = AdjustmentParameter.valueOf(entry.primaryParameter)
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT).format(Date(entry.dateMillis)),
                    style = MaterialTheme.typography.bodySmall,
                )
                entry.beanName?.let { Text(" · $it", style = MaterialTheme.typography.bodySmall) }
                Box(Modifier.weight(1f))
                Box {
                    TextButton(onClick = { menu = true }) {
                        Text(AdjustmentOutcome.valueOf(entry.outcome).displayName)
                    }
                    DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                        AdjustmentOutcome.entries.forEach { o ->
                            DropdownMenuItem(text = { Text(o.displayName) }, onClick = { onOutcome(o); menu = false })
                        }
                    }
                }
                IconButton(onClick = onDelete) { Icon(Icons.Filled.Delete, contentDescription = "Delete") }
            }
            Text(
                "${DrinkType.valueOf(entry.drink).displayName} · ${paramName(param)}: " +
                    "${value(param, entry.beforeSettings)} → ${value(param, entry.afterSettings)}",
                fontWeight = FontWeight.Medium,
            )
            if (entry.symptomList.isNotEmpty()) {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    entry.symptomList.forEach { Text(it.displayName, style = MaterialTheme.typography.labelSmall) }
                }
            }
            if (entry.rationale.isNotEmpty()) {
                Text(entry.rationale, style = MaterialTheme.typography.bodySmall)
            }
        }
    }
}

private fun paramName(p: AdjustmentParameter): String = when (p) {
    AdjustmentParameter.GRINDER -> "Grinder"
    AdjustmentParameter.STRENGTH -> "Strength"
    AdjustmentParameter.VOLUME -> "Volume"
    AdjustmentParameter.MILK_DURATION -> "Milk"
    AdjustmentParameter.TEMPERATURE -> "Temp"
    AdjustmentParameter.BEANS -> "Bean"
}

private fun value(p: AdjustmentParameter, s: MachineSettings): String = when (p) {
    AdjustmentParameter.GRINDER -> "${s.grinder}"
    AdjustmentParameter.STRENGTH -> "${s.strength}"
    AdjustmentParameter.VOLUME -> "${s.volumeML}ml"
    AdjustmentParameter.MILK_DURATION -> "${s.milkSeconds}s"
    AdjustmentParameter.TEMPERATURE -> s.temperature.displayName
    AdjustmentParameter.BEANS -> "—"
}
