#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Metro Sample Bazel - ABI Jar Analysis ===${NC}\n"

# Step 0: Create build folder
echo -e "${YELLOW}Step 0: Creating build folder${NC}"
BUILD_DIR="$(pwd)/build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/abi"
mkdir -p "$BUILD_DIR/full"
echo "Build directory: $BUILD_DIR"

# Step 1: Clean and build
echo -e "\n${YELLOW}Step 1: Running bazel clean && bazel build${NC}"
bazel clean
# Build only network and scope modules (app fails due to Metro ABI issue)
bazel build //network:src_main //scope:src_main 2>&1 | tee "$BUILD_DIR/build.log" || {
    echo -e "${RED}Build failed, but continuing with jar analysis...${NC}"
}

# Step 2: Find ABI and full jars
echo -e "\n${YELLOW}Step 2: Finding ABI and full jars${NC}"
ABI_JARS=$(find -L bazel-bin -name "*.abi.jar" -type f 2>/dev/null || true)
FULL_JARS=$(find -L bazel-bin -name "*-kt.jar" -type f ! -name "*.abi.jar" 2>/dev/null || true)

echo "Found ABI jars:"
echo "$ABI_JARS"
echo ""
echo "Found full jars:"
echo "$FULL_JARS"

# Step 3: Download CFR decompiler if not present
CFR_JAR="/tmp/cfr.jar"
if [ ! -f "$CFR_JAR" ]; then
    echo -e "\n${YELLOW}Step 3: Downloading CFR decompiler${NC}"
    curl -L -o "$CFR_JAR" https://github.com/leibnitz27/cfr/releases/download/0.152/cfr-0.152.jar
else
    echo -e "\n${YELLOW}Step 3: Using existing CFR decompiler${NC}"
fi

# Step 4: Decompile all classes from ABI jars
echo -e "\n${YELLOW}Step 4: Decompiling ABI jars${NC}"
for abi_jar in $ABI_JARS; do
    module_name=$(echo "$abi_jar" | sed 's|bazel-bin/||' | sed 's|/.*||')
    echo "  Decompiling $abi_jar -> build/abi/$module_name/"
    mkdir -p "$BUILD_DIR/abi/$module_name"
    java -jar "$CFR_JAR" "$abi_jar" --outputdir "$BUILD_DIR/abi/$module_name" --silent
done

# Step 5: Decompile all classes from full jars
echo -e "\n${YELLOW}Step 5: Decompiling full jars${NC}"
for full_jar in $FULL_JARS; do
    module_name=$(echo "$full_jar" | sed 's|bazel-bin/||' | sed 's|/.*||')
    echo "  Decompiling $full_jar -> build/full/$module_name/"
    mkdir -p "$BUILD_DIR/full/$module_name"
    java -jar "$CFR_JAR" "$full_jar" --outputdir "$BUILD_DIR/full/$module_name" --silent
done

# Step 6: Generate summary report
echo -e "\n${YELLOW}Step 6: Generating summary report${NC}"
REPORT_FILE="$BUILD_DIR/analysis-report.txt"
cat > "$REPORT_FILE" << 'EOF'
=== ABI Jar Analysis Report ===

Generated: $(date)

EOF

echo "ABI Jars Found:" >> "$REPORT_FILE"
echo "$ABI_JARS" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Full Jars Found:" >> "$REPORT_FILE"
echo "$FULL_JARS" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo "Decompiled Sources:" >> "$REPORT_FILE"
echo "- ABI jars: $BUILD_DIR/abi/" >> "$REPORT_FILE"
echo "- Full jars: $BUILD_DIR/full/" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Compare file counts
echo "File Comparison:" >> "$REPORT_FILE"
for module in $(ls "$BUILD_DIR/abi/" 2>/dev/null || true); do
    abi_count=$(find "$BUILD_DIR/abi/$module" -name "*.java" 2>/dev/null | wc -l)
    full_count=$(find "$BUILD_DIR/full/$module" -name "*.java" 2>/dev/null | wc -l)
    echo "  $module: ABI=$abi_count files, Full=$full_count files" >> "$REPORT_FILE"
done

echo -e "\n${GREEN}=== Analysis Complete ===${NC}"
echo "Results available in: $BUILD_DIR"
echo "Report: $REPORT_FILE"
echo ""
cat "$REPORT_FILE"
