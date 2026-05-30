package com.cawfee.ui.onboarding

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.AustralianStylePreset

/**
 * First-launch dial-in coach. Ported from OnboardingView.swift: captures the machine
 * name and default drink (Cappuccino), explains the workflow, then flips
 * `hasCompletedOnboarding`. Fully local.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun OnboardingScreen(viewModel: OnboardingViewModel = hiltViewModel(), onFinish: () -> Unit) {
    var step by remember { mutableIntStateOf(0) }
    var machineName by remember { mutableStateOf("") }
    var drink by remember { mutableStateOf(DrinkType.CAPPUCCINO) }
    val lastStep = 3

    Scaffold { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            LinearProgressIndicator(progress = { step.toFloat() / lastStep }, modifier = Modifier.fillMaxWidth())

            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                when (step) {
                    0 -> {
                        Text("Welcome to Cawfee", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                        Text(
                            "A fully offline espresso companion built for Canberra. Let's set you up in a few taps — " +
                                "your bean library is already loaded with local roasters and supermarket beans.",
                        )
                    }
                    1 -> {
                        Text("Your machine", style = MaterialTheme.typography.titleLarge)
                        Text("Optional — name your espresso machine so settings feel like yours.")
                        OutlinedTextField(machineName, { machineName = it }, label = { Text("e.g. Jura E8") }, modifier = Modifier.fillMaxWidth())
                    }
                    2 -> {
                        Text("Your usual order", style = MaterialTheme.typography.titleLarge)
                        Text("We'll default new recipes and the shot timer to this drink.")
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            DrinkType.entries.forEach { d ->
                                FilterChip(selected = drink == d, onClick = { drink = d }, label = { Text(d.displayName) })
                            }
                        }
                        AustralianStylePreset.all.firstOrNull { it.drink == drink }?.let { preset ->
                            Text("${preset.name}: aim for a 1:%.1f ratio. ${preset.blurb}".format(preset.ratio),
                                style = MaterialTheme.typography.bodySmall)
                        }
                    }
                    else -> {
                        Text("You're set", style = MaterialTheme.typography.titleLarge)
                        Text("How to dial in:", fontWeight = FontWeight.SemiBold)
                        Text("1. Pick a bean in Beans and add its roast date for freshness tracking.")
                        Text("2. Pull a shot with the Shot Timer — aim for the ratio in Ratio Converter.")
                        Text("3. Taste it. If it's off, use Fix My Coffee to get a single adjustment.")
                        Text("4. Log how it tasted in the Tasting Log and repeat.")
                        Text("Everything stays on this device — no account, no internet.", style = MaterialTheme.typography.bodySmall)
                    }
                }
            }

            Row(Modifier.fillMaxWidth()) {
                if (step > 0) OutlinedButton(onClick = { step -= 1 }) { Text("Back") }
                Spacer(Modifier.weight(1f))
                if (step < lastStep) {
                    Button(onClick = { step += 1 }) { Text("Continue") }
                } else {
                    Button(onClick = {
                        viewModel.finish(machineName, drink)
                        onFinish()
                    }) { Text("Start brewing") }
                }
            }
        }
    }
}
