# Metro + Bazel + Kotlin ABI Jars ✅ WORKING

## Solution: Kotlin 2.2.22-UBER with Custom jvm-abi-gen

This project successfully uses **ABI jars with Metro DI framework** by using Kotlin 2.2.22-UBER which includes a custom-built `jvm-abi-gen` that preserves Metro compiler metadata.

### Setup

**Versions:**
- Kotlin compiler: **2.2.22-UBER**
- jvm-abi-gen: **2.2.22-UBER** (custom UBER build)
- rules_kotlin: **2.3.10**
- Metro: **0.11.2**

**Initial Setup** (run once):

```bash
# Extract Kotlin 2.2.22-UBER from ~/Downloads/kotlin-2.2.22-UBER.zip
./scripts/setup-kotlin-compiler.sh
```

This script creates `kotlin-compiler-override/` containing:
- Kotlin compiler 2.2.22-UBER (extracted from ~/Downloads/kotlin-2.2.22-UBER.zip)
- Custom `lib/jvm-abi-gen.jar` that preserves Metro metadata

**Configuration:**

The `.bazelrc` file contains:
```
build --override_repository=rules_kotlin~~rules_kotlin_extensions~com_github_jetbrains_kotlin_git=%workspace%/kotlin-compiler-override
```

This overrides the Kotlin compiler to use our local version with the custom jvm-abi-gen.

**Verification**:
```bash
# Verify the jvm-abi-gen.jar version
shasum -a 256 kotlin-compiler-override/lib/jvm-abi-gen.jar
# Should output: 27fd2cde53377dec9505a580bd0583b8fcecfab18927143decc3fa8303fb57a5

# Verify it's 2.8M (not 951K stock version)
ls -lh kotlin-compiler-override/lib/jvm-abi-gen.jar
# Should show: 2.8M
```

### Building

```bash
# First-time setup
./scripts/setup-kotlin-compiler.sh

# Build all modules
bazel build //...

# Build and analyze ABI jars
bazel build //network:src_main //scope:src_main
./scripts/analyze-abi-jars.sh
```

### Testing with Different jvm-abi-gen Versions

To test with a different version:

1. Download the desired jvm-abi-gen.jar version
2. Replace `/tmp/kotlin-compiler-patched/kotlinc/lib/jvm-abi-gen.jar`
3. Clean and rebuild: `bazel clean && bazel build //...`

### Available jvm-abi-gen Versions

- **Release**: Bundled with Kotlin compiler (e.g., 2.3.10-release-465)
- **Dev**: https://packages.jetbrains.team/maven/p/kt/bootstrap/org/jetbrains/kotlin/jvm-abi-gen/

To browse dev versions:
```bash
curl -L "https://packages.jetbrains.team/maven/p/kt/bootstrap/org/jetbrains/kotlin/jvm-abi-gen/" | grep "href"
```

## Test Results

✅ **All tests pass with ABI jars enabled!**

```bash
bazel test //app:test_main
# Output:
# //app:test_main                                                          PASSED in 0.5s
# Executed 1 out of 1 test: 1 test passes.
```

## How It Works

The custom `jvm-abi-gen-2.2.255-SNAPSHOT.jar` preserves the Metro compiler marker in ABI jars:

### Stock jvm-abi-gen (❌ Broken)
```java
@Metadata(d2={
  "Lcom/uber/metro/sample/NetworkModule;",
  "provideNetworkClient",
  "network-src_main"
  // ❌ Missing: "dev.zacsweers.metro.compiler"
})
```

### Custom jvm-abi-gen (✅ Working)
```java
@Metadata(d2={
  "Lcom/uber/metro/sample/NetworkModule;",
  "provideNetworkClient",
  "dev.zacsweers.metro.compiler",  // ✅ Preserved!
  "network-src_main"
})
```

This marker allows Metro to discover compiler-generated Factory classes at compile time.

## Directory Structure

```
/tmp/kotlin-compiler-patched/kotlinc/
├── BUILD.bazel         # Bazel build file
├── WORKSPACE           # Workspace marker
├── bin/                # Kotlin compiler binaries
└── lib/
    ├── jvm-abi-gen.jar # ← Replaced with dev version
    ├── kotlin-stdlib.jar
    └── ...             # Other Kotlin libs
```
