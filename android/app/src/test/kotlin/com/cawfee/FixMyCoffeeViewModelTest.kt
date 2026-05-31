package com.cawfee

import com.cawfee.data.CoffeeRepository
import com.cawfee.data.PreferencesRepository
import com.cawfee.data.local.BeanEntity
import com.cawfee.data.local.HistoryEntity
import com.cawfee.domain.model.AdjustmentParameter
import com.cawfee.domain.model.Cause
import com.cawfee.domain.model.MachineSettings
import com.cawfee.domain.model.Symptom
import com.cawfee.ui.fix.FixMyCoffeeViewModel
import com.cawfee.ui.shots.ShotTimerViewModel
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/** JVM unit tests for the Android ViewModels that contain no Android framework calls. */
@OptIn(ExperimentalCoroutinesApi::class)
class FixMyCoffeeViewModelTest {

    private val dispatcher = StandardTestDispatcher()
    private lateinit var repo: CoffeeRepository
    private lateinit var prefs: PreferencesRepository

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
        repo = mockk(relaxed = true)
        prefs = mockk(relaxed = true)
        every { repo.beans } returns MutableStateFlow(emptyList<BeanEntity>())
        every { repo.history } returns flowOf(emptyList<HistoryEntity>())
        every { prefs.prefs } returns flowOf(PreferencesRepository.UserPrefs())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    private fun viewModel() = FixMyCoffeeViewModel(repo, prefs)

    @Test
    fun `evaluating too bitter at fine grind recommends coarser grind`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceUntilIdle()
        vm.setSettings(MachineSettings(grinder = 6))
        vm.toggle(Symptom.TOO_BITTER)
        vm.evaluate(novice = true)
        advanceUntilIdle()

        val rec = vm.state.value.recommendation
        assertTrue(rec != null)
        assertEquals(Cause.OVER_EXTRACTION, rec!!.topCause)
        assertEquals(AdjustmentParameter.GRINDER, rec.primary?.parameter)
        assertEquals(5, rec.primary?.toInt)
    }

    @Test
    fun `clearing symptoms removes the recommendation`() = runTest(dispatcher) {
        val vm = viewModel()
        advanceUntilIdle()
        vm.toggle(Symptom.TOO_SOUR)
        vm.evaluate(novice = true)
        advanceUntilIdle()
        assertTrue(vm.state.value.recommendation != null)
        vm.clearSymptoms()
        assertNull(vm.state.value.recommendation)
        assertTrue(vm.state.value.selectedSymptoms.isEmpty())
    }

    @Test
    fun `shot timer formats milliseconds as tenths of a second`() {
        assertEquals("27.4", ShotTimerViewModel.format(27_400))
        assertEquals("0.0", ShotTimerViewModel.format(0))
    }
}
