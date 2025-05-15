load("@//rules/testing:commons.bzl", "KOTEST_DEPS")
load("@//rules/testing:junit5.bzl", "kt_junit5_test")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")

kt_jvm_library(
    name = "BspProjectMapperTestLib",
    srcs = ["BspProjectMapperTest.kt"],
    deps = [
        "//server/server/src/main/kotlin/org/jetbrains/bsp/bazel/server/sync",
        "@maven//:org_junit_jupiter_junit_jupiter",
        "@maven//:org_junit_platform_junit_platform_console",
    ] + KOTEST_DEPS,
)

# there is no 'flaky' attr for kt_jvm_test so the workaround
# is kt_jvm_library + java_test (which has flaky attr)
java_test(
    name = "BspProjectMapperTest",
    args = [
        "--select-package=org.jetbrains.bsp.bazel.server.sync",
    ],
    flaky = True,
    main_class = "org.junit.platform.console.ConsoleLauncher",
    use_testrunner = False,
    runtime_deps = [
        ":BspProjectMapperTestLib",
    ],
)

kt_junit5_test(
    name = "DependencyMapperTest",
    size = "small",
    src = "DependencyMapperTest.kt",
    deps = [
        "//server/server/src/main/kotlin/org/jetbrains/bsp/bazel/server/sync",
    ],
)

kt_junit5_test(
    name = "TargetTagsResolverTest",
    size = "small",
    src = "TargetTagsResolverTest.kt",
    deps = [
        "//server/server/src/main/kotlin/org/jetbrains/bsp/bazel/server/sync",
        "//server/server/src/main/kotlin/org/jetbrains/bsp/bazel/server/sync/proto:bsp_target_info_java_proto",
    ],
)
