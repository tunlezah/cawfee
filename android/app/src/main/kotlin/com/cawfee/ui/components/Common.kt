package com.cawfee.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CleaningServices
import androidx.compose.material.icons.filled.Autorenew
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material.icons.filled.Air
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

/** A titled card panel, the Compose analogue of the macOS SectionPanel. */
@Composable
fun SectionCard(
    title: String,
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit,
) {
    Card(modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(title, fontWeight = FontWeight.SemiBold)
            content()
        }
    }
}

/** Read-only star row (filled up to [rating]/5). */
@Composable
fun StarRow(rating: Int, modifier: Modifier = Modifier) {
    Row(modifier) {
        for (i in 1..5) {
            Icon(
                imageVector = if (i <= rating) Icons.Filled.Star else Icons.Outlined.StarBorder,
                contentDescription = null,
                tint = if (i <= rating) Color(0xFFF5B301) else MaterialTheme.colorScheme.outline,
            )
        }
    }
}

/** Map a seed SF-Symbol-style icon key to a Material icon for maintenance tasks. */
fun maintenanceIcon(iconKey: String): ImageVector = when (iconKey) {
    "arrow.triangle.2.circlepath" -> Icons.Filled.Autorenew
    "bubbles.and.sparkles" -> Icons.Filled.CleaningServices
    "drop.triangle" -> Icons.Filled.WaterDrop
    "shower" -> Icons.Filled.WaterDrop
    "circle.dashed" -> Icons.Filled.Build
    "fan" -> Icons.Filled.Air
    else -> Icons.Filled.CleaningServices
}
