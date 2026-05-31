package com.cawfee

import androidx.compose.material3.Text
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithText
import com.cawfee.ui.components.SectionCard
import com.cawfee.ui.theme.CawfeeTheme
import org.junit.Rule
import org.junit.Test

/** Compose UI test exercising a real component end-to-end on device/emulator. */
class SectionCardUiTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun showsSectionTitleAndContent() {
        composeRule.setContent {
            CawfeeTheme(dynamicColor = false) {
                SectionCard(title = "Beans") {
                    Text("Your bean library")
                }
            }
        }
        composeRule.onNodeWithText("Beans").assertIsDisplayed()
        composeRule.onNodeWithText("Your bean library").assertIsDisplayed()
    }
}
