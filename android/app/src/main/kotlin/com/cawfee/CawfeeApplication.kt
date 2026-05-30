package com.cawfee

import android.app.Application
import com.cawfee.data.CoffeeRepository
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import javax.inject.Inject

/** Application entry point; Hilt's dependency graph root. Seeds the catalogue on launch. */
@HiltAndroidApp
class CawfeeApplication : Application() {

    @Inject lateinit var repository: CoffeeRepository
    @Inject lateinit var appScope: CoroutineScope

    override fun onCreate() {
        super.onCreate()
        // First-launch seeding (beans, water profiles, maintenance tasks). Idempotent.
        appScope.launch { repository.seedIfNeeded() }
    }
}
