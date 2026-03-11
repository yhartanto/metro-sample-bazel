package com.uber.metro.sample

import com.google.common.truth.Truth.assertThat
import dev.zacsweers.metro.DependencyGraph
import dev.zacsweers.metro.createGraph
import org.junit.Test

/**
 * Test to verify that Metro's @ContributesTo pattern works correctly. This test validates that the
 * dependency graph is properly generated and all contributed modules are merged into the AppGraph.
 */
class AppGraphTest {

  @Test
  fun `test graph is created and dependencies are initialized`() {
    // Create the graph - Metro generates the implementation at compile time
    val graph = createGraph<TestGraph>()

    // Verify that the graph is not null
    assertThat(graph).isNotNull()
  }

  @Test
  fun `test NetworkClient is provided correctly`() {
    val graph = createGraph<TestGraph>()

    // Get the NetworkClient from the graph
    val networkClient = graph.networkClient

    // Assert that it's initialized correctly
    assertThat(networkClient).isNotNull()
    assertThat(networkClient).isInstanceOf(NetworkClient::class.java)

    // Verify it works
    val response = networkClient.get("https://example.com")
    assertThat(response).isEqualTo("Response from https://example.com")
  }

  @Test
  fun `test Logger is provided correctly`() {
    val graph = createGraph<TestGraph>()

    // Get the Logger from the graph
    val logger = graph.logger

    // Assert that it's initialized correctly
    assertThat(logger).isNotNull()
    assertThat(logger).isInstanceOf(Logger::class.java)

    // Verify it works (should not throw)
    logger.log("Test message")
  }

  @Test
  fun `test UserRepository is provided with dependencies injected`() {
    val graph = createGraph<TestGraph>()

    // Get the UserRepository from the graph
    val userRepository = graph.userRepository

    // Assert that it's initialized correctly
    assertThat(userRepository).isNotNull()
    assertThat(userRepository).isInstanceOf(UserRepository::class.java)

    // Verify it's the implementation class with dependencies
    assertThat(userRepository).isInstanceOf(UserRepositoryImpl::class.java)

    // Verify it works with injected dependencies
    val user = userRepository.getUser("123")
    assertThat(user).isNotNull()
    assertThat(user.id).isEqualTo("123")
    assertThat(user.name).isEqualTo("User 123")
  }

  @Test
  fun `test all contributed modules are merged into the graph`() {
    val graph = createGraph<TestGraph>()

    // Verify all dependencies from different @ContributesTo modules are available
    // This proves that Metro successfully merged:
    // - NetworkModule (provides NetworkClient)
    // - LoggingModule (provides Logger)
    // - DataModule (provides UserRepository)

    assertThat(graph.networkClient).isNotNull()
    assertThat(graph.logger).isNotNull()
    assertThat(graph.userRepository).isNotNull()
  }

  @Test
  fun `test dependency injection chain works correctly`() {
    val graph = createGraph<TestGraph>()

    // UserRepository depends on both NetworkClient and Logger
    // This test verifies the dependency chain is properly resolved
    val userRepository = graph.userRepository as UserRepositoryImpl

    // Verify the repository can use its injected dependencies
    val user = userRepository.getUser("456")

    // If this works without throwing, it means:
    // 1. Metro created the graph correctly
    // 2. All @ContributesTo modules were merged
    // 3. Dependencies were properly injected
    // 4. The dependency chain (NetworkClient + Logger -> UserRepository) works
    assertThat(user.id).isEqualTo("456")
    assertThat(user.name).isEqualTo("User 456")
  }

  @Test
  fun `test NetworkService uses ReplacementNetworkModule in tests`() {
    val graph = createGraph<TestGraph>()

    // Get the NetworkService from the graph
    val networkService = graph.networkService

    // Verify it's the test implementation (TestNetworkService)
    assertThat(networkService).isInstanceOf(TestNetworkService::class.java)

    // Verify it returns mock data, proving ReplacementNetworkModule replaced
    // ReplacableNetworkModule
    val data = networkService.fetchData()
    assertThat(data).isEqualTo("Mock data for testing")
  }

  /**
   * Main dependency graph for the application. Metro will merge all @ContributesTo(AppScope::class)
   * interfaces into this graph.
   */
  @DependencyGraph(scope = AppScope::class)
  interface TestGraph {
    // Access to services that will be contributed
    val userRepository: UserRepository
    val logger: Logger
    val networkClient: NetworkClient
    // Replacable Object - see ReplacementNetworkModule
    val networkService: NetworkService
  }
}
