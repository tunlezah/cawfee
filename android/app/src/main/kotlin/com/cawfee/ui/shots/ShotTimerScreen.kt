package com.cawfee.ui.shots

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.domain.model.DrinkType

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun ShotTimerScreen(viewModel: ShotTimerViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val shotCount by viewModel.shotCount.collectAsStateWithLifecycle()

    var drink by remember { mutableStateOf(DrinkType.CAPPUCCINO) }
    var dose by remember { mutableFloatStateOf(18f) }
    var yield0 by remember { mutableFloatStateOf(36f) }
    var rating by remember { mutableIntStateOf(0) }

    Scaffold(topBar = { TopAppBar(title = { Text("Shot Timer") }) }) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).padding(24.dp).verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Text(
                ShotTimerViewModel.format(state.elapsedMs),
                style = MaterialTheme.typography.displayLarge,
                fontWeight = FontWeight.SemiBold,
            )
            state.preInfusionMs?.let { Text("Pre-infusion at ${ShotTimerViewModel.format(it)}s") }
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = { viewModel.startOrStop() }) { Text(if (state.isRunning) "Stop" else "Start") }
                OutlinedButton(onClick = { viewModel.markPreInfusion() }, enabled = state.isRunning) { Text("Pre-infusion") }
                OutlinedButton(onClick = { viewModel.reset() }) { Text("Reset") }
            }

            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                DrinkType.entries.forEach { d ->
                    FilterChip(selected = drink == d, onClick = { drink = d }, label = { Text(d.displayName) })
                }
            }

            Text("Dose: %.1f g".format(dose))
            Slider(value = dose, onValueChange = { dose = it }, valueRange = 5f..30f)
            Text("Yield: %.0f g  (1:%.1f)".format(yield0, if (dose > 0) yield0 / dose else 0f))
            Slider(value = yield0, onValueChange = { yield0 = it }, valueRange = 10f..140f)

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

            FilledTonalButton(onClick = {
                viewModel.saveShot(drink, dose.toDouble(), yield0.toDouble(), rating, "")
                rating = 0
            }) { Text("Save shot") }

            Text("$shotCount shots logged", style = MaterialTheme.typography.bodySmall)
        }
    }
}
