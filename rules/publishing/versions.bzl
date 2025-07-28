def _versions(rctx):
    git_describe_result = rctx.execute(
        ["git", "describe", "--tags", "--exact-match", "HEAD"],
        working_directory = str(rctx.workspace_root)
    )
    rctx.file("git_tag_version.txt", git_describe_result.stdout.strip("\n"))
    input_file = rctx.path("git_tag_version.txt")
    result = rctx.execute([
        "sed", "-nE",
        's/^v?([0-9]+\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9]+)?)$/\\1/p',
        str(input_file),
    ])

    rctx.file(
        "versions.bzl",
        content = "BAZEL_BSP_ARTIFACT_VERSION=\"{}\"".format(
            result.stdout if result.stdout != "" else rctx.attr.default_bsp_artifact_version
        )
    )
    rctx.file(
        "BUILD.bazel",
        #content = "exports_files([\"versions.bzl\"])",
    )

versions = repository_rule(
    implementation = _versions,
    attrs = {
        "default_bsp_artifact_version": attr.string()
    },
)
