package com.uber.metro.sample

/** Simple service interfaces to demonstrate Metro's @ContributesTo pattern. */
interface UserRepository {
  fun getUser(id: String): User
}

data class User(val id: String, val name: String)

interface Logger {
  fun log(message: String)
}
