package com.uber.metro.sample

import dev.zacsweers.metro.DependencyGraph

/**
 * Main dependency graph for the application. Metro will merge all @ContributesTo(AppScope::class)
 * interfaces into this graph.
 *
 */
@DependencyGraph(scope = AppScope::class)
interface AppGraph {
  // Access to services that will be contributed
  val userRepository: UserRepository
  val logger: Logger
  val networkClient: NetworkClient
  // Replacable Object - see ReplacementNetworkModule
  val networkService: NetworkService
}
