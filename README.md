# Metro + Bazel + Kotlin ABI Jars ✅ WORKING

## Solution: Custom jvm-abi-gen 2.2.255-SNAPSHOT

This project successfully uses **ABI jars with Metro DI framework** by using a custom-built `jvm-abi-gen` that preserves Metro compiler metadata.

### Setup

**Versions:**
- Kotlin compiler: **2.2.21**
- jvm-abi-gen: **2.2.255-SNAPSHOT** (custom build)
- rules_kotlin: **2.3.10**
- Metro: **0.11.2**

**Configuration:**

1. **Custom jvm-abi-gen location**: `/tmp/kotlin-compiler-patched/kotlinc/`
   - Kotlin compiler 2.2.21 with custom `lib/jvm-abi-gen.jar`
   - Source: `libs/jvm-abi-gen/jvm-abi-gen-2.2.255-SNAPSHOT.jar`

2. **Override mechanism**: `.bazelrc` contains:
   ```
   build --override_repository=rules_kotlin~~rules_kotlin_extensions~com_github_jetbrains_kotlin_git=/tmp/kotlin-compiler-patched/kotlinc
   ```

3. **Verification**:
   ```bash
   # Verify the jvm-abi-gen.jar version
   shasum -a 256 /tmp/kotlin-compiler-patched/kotlinc/lib/jvm-abi-gen.jar
   # Should output: ede34ff07dcaf1d149446c6f7652ac40ef80331bb34636aa1785422beb929bbe

   # Verify it's 2.8M (not 951K stock version)
   ls -lh /tmp/kotlin-compiler-patched/kotlinc/lib/jvm-abi-gen.jar
   # Should show: 2.8M
   ```

### Building

```bash
# Clean build
bazel clean

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
