package com.cawfee.ui.fix

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.cawfee.domain.model.DrinkType
import com.cawfee.domain.model.MilkKind
import com.cawfee.domain.model.Recommendation
import com.cawfee.domain.model.Symptom
import com.cawfee.ui.components.MachineSettingsEditor
import com.cawfee.ui.components.SectionCard

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
fun FixMyCoffeeScreen(expertMode: Boolean, viewModel: FixMyCoffeeViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val beans by viewModel.beans.collectAsStateWithLifecycle()
    var beanMenu by remember { mutableStateOf(false) }

    Scaffold(topBar = { TopAppBar(title = { Text(if (expertMode) "Expert Mode" else "Fix My Coffee") }) }) { padding ->
        Column(
            Modifier.fillMaxSize().padding(padding).padding(16.dp).verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            SectionCard("Drink") {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    DrinkType.entries.forEach { d ->
                        FilterChip(selected = state.drink == d, onClick = { viewModel.setDrink(d) }, label = { Text(d.displayName) })
                    }
                }
                if (state.drink.isMilkBased) {
                    Text("Milk", fontWeight = FontWeight.Medium)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        MilkKind.entries.forEach { m ->
                            FilterChip(selected = state.milkKind == m, onClick = { viewModel.setMilkKind(m) }, label = { Text(m.displayName) })
                        }
                    }
                }
                Box {
                    OutlinedButton(onClick = { beanMenu = true }) {
                        Text(beans.firstOrNull { it.slug == state.selectedBeanSlug }?.let { "${it.roaster} — ${it.name}" } ?: "Bean: None")
                    }
                    DropdownMenu(expanded = beanMenu, onDismissRequest = { beanMenu = false }) {
                        DropdownMenuItem(text = { Text("None") }, onClick = { viewModel.setBean(null); beanMenu = false })
                        beans.forEach { b ->
                            DropdownMenuItem(text = { Text("${b.roaster} — ${b.name}") }, onClick = { viewModel.setBean(b.slug); beanMenu = false })
                        }
                    }
                }
            }

            SectionCard("Current settings") {
                MachineSettingsEditor(state.settings, { viewModel.setSettings(it) }, showsMilk = state.drink.isMilkBased)
            }

            Text("What's wrong with the cup?", fontWeight = FontWeight.SemiBold)
            FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Symptom.entries.forEach { symptom ->
                    FilterChip(
                        selected = symptom in state.selectedSymptoms,
                        onClick = { viewModel.toggle(symptom) },
                        label = { Text(symptom.displayName) },
                    )
                }
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = { viewModel.evaluate(novice = !expertMode) },
                    enabled = state.selectedSymptoms.isNotEmpty(),
                ) { Text("Get recommendation") }
                OutlinedButton(onClick = { viewModel.clearSymptoms() }) { Text("Clear") }
            }

            state.recommendation?.let { rec ->
                RecommendationCard(rec, didApply = state.didApply, onApply = { viewModel.applyAndLog() }, expert = expertMode)
            }
        }
    }
}

@Composable
private fun RecommendationCard(rec: Recommendation, didApply: Boolean, onApply: () -> Unit, expert: Boolean) {
    Card(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            if (rec.suggestRevertToLastGood) {
                Text("Consider reverting", fontWeight = FontWeight.SemiBold)
                Text(rec.rationale)
                return@Column
            }
            rec.topCause?.let { Text(it.displayName, fontWeight = FontWeight.SemiBold) }
            LinearProgressIndicator(progress = { rec.confidence.toFloat() }, modifier = Modifier.fillMaxWidth())
            Text("${(rec.confidence * 100).toInt()}% confident")
            Text(rec.rationale)
            rec.primary?.let { p ->
                Text("Primary: ${p.summary}", fontWeight = FontWeight.Medium)
                Text(p.reason)
                Button(onClick = onApply, enabled = !didApply) { Text(if (didApply) "Applied & logged" else "Apply & log") }
            }
            rec.secondary?.let { s -> Text("Also: ${s.summary}") }

            if (expert) {
                Text("Rule contributions", fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(top = 8.dp))
                rec.contributions.forEach { c ->
                    Text("• ${c.cause.displayName} — ${(c.confidence * 100).toInt()}% (${c.ruleIDs.joinToString()})")
                }
            }
        }
    }
}
