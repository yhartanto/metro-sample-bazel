package com.uber.metro.sample

import dev.zacsweers.metro.ContributesTo
import dev.zacsweers.metro.Provides

/**
 * Example of Original module that can be replaced. This module provides the "real" network
 * implementation. See ReplacementNetworkModule to see the replacement
 */
@ContributesTo(AppScope::class)
interface ReplacableNetworkModule {

  @Provides
  fun provideRealNetworkService(): NetworkService {
    return RealNetworkService()
  }
}

interface NetworkService {
  fun fetchData(): String
}

class RealNetworkService : NetworkService {
  override fun fetchData(): String = "Real data from network"
}
