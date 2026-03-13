"""Custom module extension to override jvm-abi-gen.jar in Kotlin compiler."""

load("@bazel_tools//tools/build_defs/repo:utils.bzl", "get_auth", "patch")

def _kotlin_compiler_with_dev_abi_gen_impl(repository_ctx):
    """Downloads Kotlin compiler and replaces jvm-abi-gen.jar with dev version."""

    attr = repository_ctx.attr

    # Download the standard Kotlin compiler
    repository_ctx.download_and_extract(
        attr.compiler_urls,
        sha256 = attr.compiler_sha256,
        stripPrefix = "kotlinc",
        auth = get_auth(repository_ctx, attr.compiler_urls),
    )

    # Download the custom jvm-abi-gen.jar from JetBrains Maven
    repository_ctx.download(
        url = attr.abi_gen_url,
        sha256 = attr.abi_gen_sha256,
        output = "lib/jvm-abi-gen.jar",
    )

    # Create BUILD file (matching rules_kotlin template)
    repository_ctx.file(
        "BUILD.bazel",
        content = """
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
""",
        executable = False,
    )

    # Create capabilities.bzl (copy from rules_kotlin)
    repository_ctx.file(
        "capabilities.bzl",
        content = """
def _compiler_supports(version, minimum_version):
    \"\"\"Check if compiler version meets minimum requirement.\"\"\"
    v_parts = [int(p) for p in version.split(".")]
    min_parts = [int(p) for p in minimum_version.split(".")]

    for i in range(max(len(v_parts), len(min_parts))):
        v = v_parts[i] if i < len(v_parts) else 0
        m = min_parts[i] if i < len(min_parts) else 0
        if v > m:
            return True
        if v < m:
            return False
    return True

COMPILER_VERSION = "{version}"

supports_kt2 = _compiler_supports(COMPILER_VERSION, "2.0.0")
""".format(version = attr.compiler_version),
        executable = False,
    )

kotlin_compiler_with_dev_abi_gen = repository_rule(
    implementation = _kotlin_compiler_with_dev_abi_gen_impl,
    attrs = {
        "compiler_urls": attr.string_list(
            mandatory = True,
            doc = "URLs for the Kotlin compiler zip",
        ),
        "compiler_sha256": attr.string(
            mandatory = True,
            doc = "SHA256 of the Kotlin compiler zip",
        ),
        "compiler_version": attr.string(
            mandatory = True,
            doc = "Kotlin compiler version",
        ),
        "abi_gen_url": attr.string(
            mandatory = True,
            doc = "URL for the custom jvm-abi-gen.jar",
        ),
        "abi_gen_sha256": attr.string(
            mandatory = True,
            doc = "SHA256 of the custom jvm-abi-gen.jar",
        ),
    },
)
