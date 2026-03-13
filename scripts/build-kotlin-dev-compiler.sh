#!/bin/bash
#
# Build a complete Kotlin 2.4.0-dev compiler distribution from Maven artifacts
#

set -e

VERSION="2.4.0-dev-5318"
BASE_URL="https://packages.jetbrains.team/maven/p/kt/bootstrap/org/jetbrains/kotlin"
KOTLINC_DIR="/tmp/kotlin-compiler-patched/kotlinc"

echo "Building Kotlin ${VERSION} compiler distribution..."
echo

# Create directory structure
rm -rf "${KOTLINC_DIR}"
mkdir -p "${KOTLINC_DIR}/lib"
mkdir -p "${KOTLINC_DIR}/bin"

cd "${KOTLINC_DIR}/lib"

# List of required JARs (core libraries)
declare -a JARS=(
    "kotlin-stdlib"
    "kotlin-stdlib-jdk7"
    "kotlin-stdlib-jdk8"
    "kotlin-reflect"
    "kotlin-test"
    "kotlin-test-junit"
    "kotlin-compiler"
    "kotlin-scripting-common"
    "kotlin-scripting-jvm"
    "kotlin-scripting-compiler"
    "kotlin-scripting-compiler-impl"
    "kotlin-daemon-client"
    "jvm-abi-gen"
)

echo "Downloading JARs from Maven..."
for jar in "${JARS[@]}"; do
    echo "  - ${jar}.jar"
    curl -f -s -L -o "${jar}.jar" \
        "${BASE_URL}/${jar}/${VERSION}/${jar}-${VERSION}.jar" || {
        echo "    ⚠️  Failed to download ${jar}, skipping..."
    }
done

echo
echo "Downloading compiler plugins..."
cd "${KOTLINC_DIR}/lib"

# Compiler plugins
declare -a PLUGINS=(
    "allopen-compiler-plugin"
    "noarg-compiler-plugin"
    "sam-with-receiver-compiler-plugin"
    "kotlinx-serialization-compiler-plugin"
    "parcelize-compiler"
)

for plugin in "${PLUGINS[@]}"; do
    echo "  - ${plugin}.jar"
    curl -f -s -L -o "${plugin}.jar" \
        "${BASE_URL}/${plugin}/${VERSION}/${plugin}-${VERSION}.jar" || {
        echo "    ⚠️  Failed to download ${plugin}, skipping..."
    }
done

# Create minimal bin/kotlinc script
cat > "${KOTLINC_DIR}/bin/kotlinc" <<'EOF'
#!/bin/sh
KOTLIN_HOME="$(dirname "$0")/.."
java -cp "$KOTLIN_HOME/lib/kotlin-compiler.jar" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler "$@"
EOF
chmod +x "${KOTLINC_DIR}/bin/kotlinc"

# Create BUILD.bazel
cat > "${KOTLINC_DIR}/BUILD.bazel" <<'EOF'
package(default_visibility = ["//visibility:public"])

[
    filegroup(
        name = name.replace(".", "_"),
        srcs = glob(["" + name]),
    )
    for name in glob(["lib/**"])
]

filegroup(
    name = "home",
    srcs = glob(["**"]),
)
EOF

# Create WORKSPACE
cat > "${KOTLINC_DIR}/WORKSPACE" <<'EOF'
workspace(name = "com_github_jetbrains_kotlin_git")
EOF

echo
echo "✅ Kotlin ${VERSION} distribution built!"
echo "Location: ${KOTLINC_DIR}"
echo
echo "Downloaded JARs:"
ls -1 "${KOTLINC_DIR}/lib"/*.jar | wc -l | xargs echo "  Total:"
echo
echo "jvm-abi-gen.jar info:"
ls -lh "${KOTLINC_DIR}/lib/jvm-abi-gen.jar"
shasum -a 256 "${KOTLINC_DIR}/lib/jvm-abi-gen.jar"
