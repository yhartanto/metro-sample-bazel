package com.uber.metro.sample

import dev.zacsweers.metro.ContributesTo
import dev.zacsweers.metro.Provides

/**
 * Example of Another @ContributesTo module This demonstrates how multiple modules can contribute to
 * the same scope independently.
 */
@ContributesTo(AppScope::class)
interface LoggingModule {

  @Provides
  fun provideLogger(): Logger {
    return object : Logger {
      override fun log(message: String) {
        println("[LOG] $message")
      }
    }
  }
}
