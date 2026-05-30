package com.cawfee.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.cawfee.domain.model.MachineRanges
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.TemperatureLevel

/**
 * Editor for a [MachineSettings] value. Compose analogue of MachineSettingsEditor.swift —
 * grinder / strength / volume / (milk) sliders plus a temperature segmented control. Every
 * change re-clamps via the MachineSettings factory.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MachineSettingsEditor(
    settings: MachineSettings,
    onChange: (MachineSettings) -> Unit,
    modifier: Modifier = Modifier,
    showsMilk: Boolean = true,
) {
    Column(modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        IntSlider(
            label = "Grinder", value = settings.grinder, range = MachineRanges.grinderRange,
            suffix = "/ 7",
        ) { onChange(settings.with(grinder = it)) }

        IntSlider(
            label = "Strength", value = settings.strength, range = MachineRanges.strengthRange,
            suffix = "/ 10",
        ) { onChange(settings.with(strength = it)) }

        IntSlider(
            label = "Volume", value = settings.volumeML, range = MachineRanges.volumeRange,
            step = 5, suffix = "ml",
        ) { onChange(settings.with(volumeML = it)) }

        if (showsMilk) {
            IntSlider(
                label = "Milk", value = settings.milkSeconds, range = MachineRanges.milkDurationRange,
                suffix = "s",
            ) { onChange(settings.with(milkSeconds = it)) }
        }

        Text("Temperature", fontWeight = FontWeight.Medium)
        SingleChoiceSegmentedButtonRow(Modifier.fillMaxWidth()) {
            TemperatureLevel.entries.forEachIndexed { i, level ->
                SegmentedButton(
                    selected = settings.temperature == level,
                    onClick = { onChange(settings.with(temperature = level)) },
                    shape = SegmentedButtonDefaults.itemShape(i, TemperatureLevel.entries.size),
                ) { Text(level.displayName) }
            }
        }
    }
}

@Composable
private fun IntSlider(
    label: String,
    value: Int,
    range: IntRange,
    step: Int = 1,
    suffix: String = "",
    onChange: (Int) -> Unit,
) {
    Column {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(label, fontWeight = FontWeight.Medium)
            Text("$value $suffix".trim())
        }
        val steps = ((range.last - range.first) / step) - 1
        Slider(
            value = value.toFloat(),
            onValueChange = { onChange(Math.round(it)) },
            valueRange = range.first.toFloat()..range.last.toFloat(),
            steps = if (steps > 0) steps else 0,
        )
    }
}
