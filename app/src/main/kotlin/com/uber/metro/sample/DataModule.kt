package com.uber.metro.sample

import dev.zacsweers.metro.ContributesTo
import dev.zacsweers.metro.Inject
import dev.zacsweers.metro.Provides

/**
 * Example of @ContributesTo with dependency injection This shows how providers can depend on other
 * provided dependencies.
 */
@ContributesTo(AppScope::class)
interface DataModule {

  @Provides
  fun provideUserRepository(networkClient: NetworkClient, logger: Logger): UserRepository {
    return UserRepositoryImpl(networkClient, logger)
  }
}

class UserRepositoryImpl
@Inject
constructor(private val networkClient: NetworkClient, private val logger: Logger) : UserRepository {
  override fun getUser(id: String): User {
    logger.log("Fetching user with id: $id")
    val response = networkClient.get("/users/$id")
    logger.log("Received response: $response")
    return User(id = id, name = "User $id")
  }
}
