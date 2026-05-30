package com.cawfee.ui.maintenance

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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.data.local.MaintenanceTaskEntity
import com.cawfee.ui.components.maintenanceIcon
import java.text.DateFormat
import java.util.Date

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MaintenanceScreen(viewModel: MaintenanceViewModel = hiltViewModel()) {
    val tasks by viewModel.tasks.collectAsStateWithLifecycle()
    val shotCount by viewModel.shotCount.collectAsStateWithLifecycle()
    var showEditor by remember { mutableStateOf(false) }
    val dueCount = tasks.count { it.isDue(shotCount) }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Maintenance") }) },
        floatingActionButton = {
            FloatingActionButton(onClick = { showEditor = true }) {
                Icon(Icons.Filled.Add, contentDescription = "New task")
            }
        },
    ) { padding ->
        LazyColumn(
            Modifier.fillMaxSize().padding(padding).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Text("$shotCount shots logged")
                    if (dueCount == 0) {
                        AssistChip(onClick = {}, label = { Text("All up to date") },
                            leadingIcon = { Icon(Icons.Filled.CheckCircle, null) })
                    } else {
                        AssistChip(onClick = {}, label = { Text("$dueCount due") },
                            leadingIcon = { Icon(Icons.Filled.Warning, null) })
                    }
                }
            }
            items(tasks, key = { it.id }) { task ->
                TaskCard(
                    task = task,
                    shotCount = shotCount,
                    onDone = { viewModel.markDone(task, shotCount) },
                    onDelete = { viewModel.delete(task) },
                )
            }
        }
    }

    if (showEditor) {
        TaskEditorDialog(
            onDismiss = { showEditor = false },
            onSave = { name, detail, days, shots -> viewModel.add(name, detail, days, shots); showEditor = false },
        )
    }
}

@Composable
private fun TaskCard(
    task: MaintenanceTaskEntity,
    shotCount: Int,
    onDone: () -> Unit,
    onDelete: () -> Unit,
) {
    val due = task.isDue(shotCount)
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(maintenanceIcon(task.iconKey), contentDescription = null)
                Text(task.name, fontWeight = FontWeight.SemiBold)
                if (due) {
                    Box(Modifier.weight(1f))
                    Icon(Icons.Filled.Warning, contentDescription = "Due",
                        tint = MaterialTheme.colorScheme.error)
                }
            }
            if (task.detail.isNotEmpty()) Text(task.detail, style = MaterialTheme.typography.bodySmall)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                task.daysUntilDue()?.let {
                    Text(if (it <= 0) "Overdue (days)" else "in ${it}d", style = MaterialTheme.typography.labelMedium)
                }
                task.shotsUntilDue(shotCount)?.let {
                    Text(if (it <= 0) "Overdue (shots)" else "in $it shots", style = MaterialTheme.typography.labelMedium)
                }
            }
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    task.lastCompletedMillis?.let {
                        "Last done ${DateFormat.getDateInstance(DateFormat.MEDIUM).format(Date(it))}"
                    } ?: "Never done",
                    style = MaterialTheme.typography.labelSmall,
                )
                Box(Modifier.weight(1f))
                Button(onClick = onDone) { Text("Mark done") }
                if (!task.isSeeded) {
                    IconButton(onClick = onDelete) { Icon(Icons.Filled.Delete, contentDescription = "Delete") }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun TaskEditorDialog(
    onDismiss: () -> Unit,
    onSave: (name: String, detail: String, days: Int?, shots: Int?) -> Unit,
) {
    var name by rememberSaveable { mutableStateOf("") }
    var detail by rememberSaveable { mutableStateOf("") }
    var useDays by rememberSaveable { mutableStateOf(true) }
    var days by rememberSaveable { mutableStateOf("14") }
    var useShots by rememberSaveable { mutableStateOf(false) }
    var shots by rememberSaveable { mutableStateOf("100") }

    Dialog(onDismissRequest = onDismiss) {
        Card {
            Column(
                Modifier.padding(20.dp).verticalScroll(rememberScrollState()),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text("New Maintenance Task", style = MaterialTheme.typography.titleLarge)
                OutlinedTextField(name, { name = it }, label = { Text("Name") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(detail, { detail = it }, label = { Text("Notes") }, modifier = Modifier.fillMaxWidth())
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(checked = useDays, onCheckedChange = { useDays = it })
                    Text("Every N days")
                }
                if (useDays) {
                    OutlinedTextField(days, { days = it.filter(Char::isDigit) }, label = { Text("Days") }, modifier = Modifier.fillMaxWidth())
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(checked = useShots, onCheckedChange = { useShots = it })
                    Text("Every N shots")
                }
                if (useShots) {
                    OutlinedTextField(shots, { shots = it.filter(Char::isDigit) }, label = { Text("Shots") }, modifier = Modifier.fillMaxWidth())
                }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                    TextButton(onClick = onDismiss) { Text("Cancel") }
                    TextButton(
                        enabled = name.isNotBlank() && (useDays || useShots),
                        onClick = {
                            onSave(
                                name, detail,
                                if (useDays) days.toIntOrNull() else null,
                                if (useShots) shots.toIntOrNull() else null,
                            )
                        },
                    ) { Text("Create") }
                }
            }
        }
    }
}
