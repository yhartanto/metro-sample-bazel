#!/bin/bash
#
# Setup script to create kotlin-compiler-override with custom jvm-abi-gen
#
# This script extracts Kotlin 2.2.22-UBER from ~/Downloads/kotlin-2.2.22-UBER.zip
# which contains the custom jvm-abi-gen.jar that preserves Metro metadata.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
KOTLIN_VERSION="2.2.22-UBER"
UBER_ZIP="$HOME/Downloads/kotlin-2.2.22-UBER.zip"
EXPECTED_JVM_ABI_SHA256="27fd2cde53377dec9505a580bd0583b8fcecfab18927143decc3fa8303fb57a5"

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OVERRIDE_DIR="${PROJECT_ROOT}/kotlin-compiler-override"

echo -e "${GREEN}=== Kotlin 2.2.22-UBER Compiler Setup ===${NC}\n"

# Step 1: Check if UBER zip exists
echo -e "${YELLOW}[1/3] Checking for Kotlin 2.2.22-UBER zip...${NC}"
if [ ! -f "${UBER_ZIP}" ]; then
    echo -e "${RED}ERROR: Kotlin 2.2.22-UBER zip not found at ${UBER_ZIP}${NC}"
    echo "Please ensure the file exists at: ${UBER_ZIP}"
    exit 1
fi
echo "✓ Found UBER zip: ${UBER_ZIP}"

# Step 2: Extract compiler
echo -e "\n${YELLOW}[2/3] Extracting Kotlin 2.2.22-UBER compiler...${NC}"
rm -rf "${OVERRIDE_DIR}" "${PROJECT_ROOT}/kotlin-compiler-temp"
unzip -q "${UBER_ZIP}" -d "${PROJECT_ROOT}/kotlin-compiler-temp"
mv "${PROJECT_ROOT}/kotlin-compiler-temp/dist/kotlinc" "${OVERRIDE_DIR}"
rm -rf "${PROJECT_ROOT}/kotlin-compiler-temp"
echo "✓ Extracted to ${OVERRIDE_DIR}"

# Step 3: Create Bazel files
echo -e "\n${YELLOW}[3/3] Creating Bazel build files...${NC}"

# Create BUILD.bazel
cat > "${OVERRIDE_DIR}/BUILD.bazel" <<'EOF'
package(default_visibility = ["//visibility:public"])

# Kotlin compiler 2.2.22-UBER with custom jvm-abi-gen
# Extracted from ~/Downloads/kotlin-2.2.22-UBER.zip

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
cat > "${OVERRIDE_DIR}/WORKSPACE" <<'EOF'
workspace(name = "com_github_jetbrains_kotlin_git")
EOF

echo "✓ Bazel files created"

# Verification
echo -e "\n${GREEN}=== Setup Complete! ===${NC}\n"
echo "Verification:"
ACTUAL_JVM_ABI_SHA=$(shasum -a 256 "${OVERRIDE_DIR}/lib/jvm-abi-gen.jar" | cut -d' ' -f1)
JVM_ABI_SIZE=$(ls -lh "${OVERRIDE_DIR}/lib/jvm-abi-gen.jar" | awk '{print $5}')
KOTLIN_VERSION_ACTUAL=$(unzip -p "${OVERRIDE_DIR}/lib/kotlin-compiler.jar" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d' ' -f2 | tr -d '\r')
JVM_ABI_VERSION=$(unzip -p "${OVERRIDE_DIR}/lib/jvm-abi-gen.jar" META-INF/MANIFEST.MF | grep Implementation-Version | cut -d' ' -f2 | tr -d '\r')

echo "  Kotlin compiler version: ${KOTLIN_VERSION_ACTUAL}"
echo "  jvm-abi-gen version: ${JVM_ABI_VERSION}"
echo "  jvm-abi-gen SHA256: ${ACTUAL_JVM_ABI_SHA}"
echo "  jvm-abi-gen size: ${JVM_ABI_SIZE}"

if [ "${ACTUAL_JVM_ABI_SHA}" = "${EXPECTED_JVM_ABI_SHA256}" ]; then
    echo -e "\n${GREEN}✓ Kotlin 2.2.22-UBER compiler correctly installed!${NC}"
else
    echo -e "\n${YELLOW}Note: jvm-abi-gen checksum differs from expected${NC}"
    echo "  Expected: ${EXPECTED_JVM_ABI_SHA256}"
    echo "  Actual:   ${ACTUAL_JVM_ABI_SHA}"
    echo "  This is OK if you're using an updated UBER build."
fi

echo -e "\nYou can now run: ${GREEN}bazel test //...${NC}"
