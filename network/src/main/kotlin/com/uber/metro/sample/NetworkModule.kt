package com.uber.metro.sample

import dev.zacsweers.metro.ContributesTo
import dev.zacsweers.metro.Provides

/**
 * Example of Basic @ContributesTo usage This interface contributes network-related providers to the
 * AppScope. Metro will merge this interface into the AppGraph at compile time.
 */
@ContributesTo(AppScope::class)
interface NetworkModule {

  @Provides
  fun provideNetworkClient(): NetworkClient {
    return object : NetworkClient {
      override fun get(url: String): String {
        return "Response from $url"
      }
    }
  }
}

interface NetworkClient {
  fun get(url: String): String
}
