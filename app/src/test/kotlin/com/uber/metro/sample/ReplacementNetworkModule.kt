package com.uber.metro.sample

import dev.zacsweers.metro.ContributesTo
import dev.zacsweers.metro.Provides

/**
 * Example of Replacement module using 'replaces' This demonstrates how @ContributesTo can replace
 * another contribution. When this module is included, it replaces ReplacableNetworkModule in the
 * AppScope.
 *
 * Note: To use this replacement, uncomment the @ContributesTo annotation. By default it's commented
 * out so both modules don't conflict.
 */
@ContributesTo(scope = AppScope::class, replaces = [ReplacableNetworkModule::class])
interface ReplacementNetworkModule {

  @Provides
  fun provideTestNetworkService(): NetworkService {
    return TestNetworkService()
  }
}

class TestNetworkService : NetworkService {
  override fun fetchData(): String = "Mock data for testing"
}
