# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Kotlin + Bazel + Metro DI framework** sample project that demonstrates using ABI jars with Metro dependency injection. The project successfully uses ABI jars through Kotlin 2.2.22-UBER which includes a custom-built `jvm-abi-gen` that preserves Metro compiler metadata.

### Key Technologies
- **Build System**: Bazel (using bzlmod)
- **Language**: Kotlin 2.2.22-UBER
- **DI Framework**: Metro 0.11.2 (compile-time dependency injection)
- **Build Rules**: rules_kotlin 2.3.10
- **Critical Component**: Custom jvm-abi-gen 2.2.22-UBER (preserves Metro metadata)

## Architecture

### Module Structure
The project follows a layered architecture with these modules:

- **scope/**: Defines `AppScope` annotation used throughout the project for dependency scoping
- **network/**: Contains `NetworkModule` with `@ContributesTo(AppScope::class)` - demonstrates basic Metro provider contribution
- **app/**: Main application module containing:
  - `AppGraph` - Main `@DependencyGraph` that Metro merges all contributions into
  - Additional modules (`DataModule`, `LoggingModule`) demonstrating Metro's contribution pattern
  - Tests that verify Metro DI works with ABI jars

### Metro DI Pattern
Metro uses compile-time code generation to merge dependency graphs:

1. Modules annotate interfaces with `@ContributesTo(Scope::class)`
2. Provider methods use `@Provides` annotation
3. Metro compiler plugin discovers these at compile time via metadata markers in ABI jars
4. Interfaces are merged into the main `@DependencyGraph` at compile time

**Critical**: Stock `jvm-abi-gen` strips the Metro compiler marker (`"dev.zacsweers.metro.compiler"`) from Kotlin metadata in ABI jars, breaking Metro's discovery. This project uses a custom version that preserves this marker.

## Build Commands

### First-Time Setup
```bash
# Extract Kotlin 2.2.22-UBER from ~/Downloads/kotlin-2.2.22-UBER.zip (run once)
./scripts/setup-kotlin-compiler.sh
```

This must be run before building. It extracts the UBER compiler to `kotlin-compiler-override/` directory (git-ignored).

### Basic Build
```bash
# Build all modules
bazel build //...

# Build specific modules
bazel build //network:src_main //scope:src_main //app:src_main
```

### Testing
```bash
# Run all tests
bazel test //...

# Run specific test
bazel test //app:test_main
```

### Clean Build
```bash
bazel clean
bazel build //...
```

### ABI Jar Analysis
```bash
# Build and analyze ABI jars (decompiles and compares ABI vs full jars)
./scripts/analyze-abi-jars.sh
```

## Critical Configuration

### Custom jvm-abi-gen Setup

The project uses a **local Kotlin 2.2.22-UBER compiler** which includes a custom `jvm-abi-gen.jar` that preserves Metro metadata. This is configured in `.bazelrc`:

```
build --override_repository=rules_kotlin~~rules_kotlin_extensions~com_github_jetbrains_kotlin_git=%workspace%/kotlin-compiler-override
```

**Initial Setup** (run once):
```bash
# Extract Kotlin 2.2.22-UBER from ~/Downloads/kotlin-2.2.22-UBER.zip
./scripts/setup-kotlin-compiler.sh
```

**Prerequisites**:
- Kotlin 2.2.22-UBER zip file must exist at `~/Downloads/kotlin-2.2.22-UBER.zip`

This script:
1. Extracts Kotlin 2.2.22-UBER to `kotlin-compiler-override/`
2. Creates necessary Bazel BUILD files
3. Verifies the jvm-abi-gen.jar

**Verification**:
```bash
# Check version (must be 2.2.22-UBER, 2.8M size)
shasum -a 256 kotlin-compiler-override/lib/jvm-abi-gen.jar
# Expected: 27fd2cde53377dec9505a580bd0583b8fcecfab18927143decc3fa8303fb57a5

ls -lh kotlin-compiler-override/lib/jvm-abi-gen.jar
# Expected: 2.8M (not 951K stock version)
```

### ABI Jars Configuration

ABI jars are enabled in two places:
1. `MODULE.bazel` - `kt.toolchain(experimental_use_abi_jars = True)`
2. `BUILD.bazel` - `define_kt_toolchain(experimental_use_abi_jars = True)`

### Metro Compiler Plugin

Defined in root `BUILD.bazel`:
- Plugin ID: `dev.zacsweers.metro`
- Applied to modules via `plugins = ["//:metro"]` in BUILD files
- Debug reports written to `/tmp/metro-sample-bazel`

## Build Files Structure

All Kotlin libraries use `kt_jvm_library` from `@rules_kotlin//kotlin:jvm.bzl`:
- Source pattern: `glob(["src/main/kotlin/**/*.kt"])`
- Modules using Metro must include `plugins = ["//:metro"]`
- Tests use `kt_jvm_test` with `test_class` specifying the main test class

## Dependencies

Maven dependencies managed in `MODULE.bazel`:
- Metro runtime and compiler
- Testing: JUnit 4.13.2, Google Truth 1.1.3

## Troubleshooting

If Metro fails to discover contributions:
1. Verify custom jvm-abi-gen is in place (see verification commands above)
2. Check ABI jars contain Metro metadata: `./scripts/analyze-abi-jars.sh`
3. Review Metro debug reports in `/tmp/metro-sample-bazel`
4. Clean build: `bazel clean && bazel build //...`
