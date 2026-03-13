# Custom repository rule to patch jvm-abi-gen.jar with dev version
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_jar")

def _kotlin_compiler_with_custom_abi_gen_impl(repository_ctx):
    """Downloads Kotlin compiler and replaces jvm-abi-gen.jar with custom version."""

    # Download the standard Kotlin compiler
    repository_ctx.download_and_extract(
        url = repository_ctx.attr.compiler_urls,
        sha256 = repository_ctx.attr.compiler_sha256,
        stripPrefix = "kotlinc",
    )

    # Download the custom jvm-abi-gen.jar
    repository_ctx.download(
        url = repository_ctx.attr.abi_gen_url,
        sha256 = repository_ctx.attr.abi_gen_sha256,
        output = "lib/jvm-abi-gen.jar",
    )

    # Create BUILD file
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

kotlin_compiler_with_custom_abi_gen = repository_rule(
    implementation = _kotlin_compiler_with_custom_abi_gen_impl,
    attrs = {
        "compiler_urls": attr.string_list(
            mandatory = True,
            doc = "URLs for the Kotlin compiler zip",
        ),
        "compiler_sha256": attr.string(
            mandatory = True,
            doc = "SHA256 of the Kotlin compiler zip",
        ),
        "abi_gen_url": attr.string(
            mandatory = True,
            doc = "URL for the custom jvm-abi-gen.jar",
        ),
        "abi_gen_sha256": attr.string(
            mandatory = False,
            doc = "SHA256 of the custom jvm-abi-gen.jar",
        ),
    },
)
