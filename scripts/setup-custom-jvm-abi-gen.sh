#!/bin/bash
#
# Setup script to override jvm-abi-gen.jar with a custom version
#
# Usage:
#   ./scripts/setup-custom-jvm-abi-gen.sh [JVM_ABI_GEN_VERSION]
#
# Example:
#   ./scripts/setup-custom-jvm-abi-gen.sh 2.4.0-dev-5318
#

set -e

# Configuration
KOTLIN_VERSION="2.3.10"
KOTLIN_SHA256="c8d546f9ff433b529fb0ad43feceb39831040cae2ca8d17e7df46364368c9a9e"
JVM_ABI_GEN_VERSION="${1:-2.4.0-dev-5318}"
JVM_ABI_GEN_SHA256="${2:-0709e38b5dfea8e7ec0e478ba2b57c21876f56e574fd8c0d02a215b030db1c7f}"

# Paths
PATCH_DIR="/tmp/kotlin-compiler-patched"
KOTLINC_DIR="${PATCH_DIR}/kotlinc"
JVM_ABI_GEN_JAR="${KOTLINC_DIR}/lib/jvm-abi-gen.jar"

echo "===================================="
echo "Setting up custom jvm-abi-gen.jar"
echo "===================================="
echo "Kotlin version: ${KOTLIN_VERSION}"
echo "jvm-abi-gen version: ${JVM_ABI_GEN_VERSION}"
echo "Target directory: ${KOTLINC_DIR}"
echo

# Step 1: Create directory
echo "[1/5] Creating directory..."
mkdir -p "${PATCH_DIR}"
cd /tmp

# Step 2: Download Kotlin compiler if not already present
if [ ! -f "kotlin-compiler-${KOTLIN_VERSION}.zip" ]; then
    echo "[2/5] Downloading Kotlin compiler ${KOTLIN_VERSION}..."
    curl -L -O "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip"

    echo "Verifying SHA256..."
    echo "${KOTLIN_SHA256}  kotlin-compiler-${KOTLIN_VERSION}.zip" | shasum -a 256 -c
else
    echo "[2/5] Using cached Kotlin compiler ${KOTLIN_VERSION}"
fi

# Step 3: Extract Kotlin compiler
echo "[3/5] Extracting Kotlin compiler..."
rm -rf "${KOTLINC_DIR}"
unzip -q "kotlin-compiler-${KOTLIN_VERSION}.zip" -d "${PATCH_DIR}"

# Step 4: Download custom jvm-abi-gen.jar
echo "[4/5] Downloading jvm-abi-gen ${JVM_ABI_GEN_VERSION}..."
curl -L -o "${JVM_ABI_GEN_JAR}" \
    "https://packages.jetbrains.team/maven/p/kt/bootstrap/org/jetbrains/kotlin/jvm-abi-gen/${JVM_ABI_GEN_VERSION}/jvm-abi-gen-${JVM_ABI_GEN_VERSION}.jar"

if [ -n "${JVM_ABI_GEN_SHA256}" ]; then
    echo "Verifying jvm-abi-gen SHA256..."
    echo "${JVM_ABI_GEN_SHA256}  ${JVM_ABI_GEN_JAR}" | shasum -a 256 -c
fi

# Step 5: Create BUILD.bazel and WORKSPACE files
echo "[5/5] Creating Bazel files..."
cat > "${KOTLINC_DIR}/BUILD.bazel" <<'EOF'
package(default_visibility = ["//visibility:public"])

# Kotlin home filegroup containing everything that is needed.
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

cat > "${KOTLINC_DIR}/WORKSPACE" <<'EOF'
workspace(name = "com_github_jetbrains_kotlin_git")
EOF

echo
echo "✅ Setup complete!"
echo
echo "Verification:"
echo "  SHA256: $(shasum -a 256 ${JVM_ABI_GEN_JAR} | cut -d' ' -f1)"
echo "  Size: $(ls -lh ${JVM_ABI_GEN_JAR} | awk '{print $5}')"
echo
echo "The .bazelrc file is configured to use this patched compiler."
echo "Run 'bazel clean && bazel build //...' to use the new jvm-abi-gen."
