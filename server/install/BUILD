load("@rules_jvm_external//:kt_defs.bzl", "kt_jvm_export")
load("@rules_kotlin//kotlin:jvm.bzl", "kt_jvm_binary", "kt_jvm_library")
load("//:versions.bzl", "BAZEL_BSP_ARTIFACT_VERSION")
load("//rules/publishing:publish_sonatype.bzl", "publish_sonatype")

kt_jvm_library(
    name = "install-lib",
    visibility = ["//visibility:public"],
    exports = [
        "//server/install/src/main/kotlin/org/jetbrains/bsp/bazel/install",
    ],
)

kt_jvm_binary(
    name = "install",
    main_class = "org.jetbrains.bsp.bazel.install.Install",
    resources = ["//server/log4j_config"],
    visibility = ["//visibility:public"],
    runtime_deps = [
        "//server/commons",
        "//server/install:install-lib",
        "//server/server/src/main/kotlin/org/jetbrains/bsp/bazel/server",
        # Needed because the installer injects its own classpath as the one to be used by the installed server
        "@server_maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
        "@server_maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core_jvm",
    ],
)

kt_jvm_export(
    name = "install_export",
    maven_coordinates = "com.virtuslab:bazel-bsp:{}".format(BAZEL_BSP_ARTIFACT_VERSION),
    pom_template = "//server/server/src/main/resources:pom.xml",
    tags = [
        "manual",
        "no-javadocs",
    ],
    visibility = ["//visibility:public"],
    runtime_deps = [
        "//server/commons",
        "//server/install:install-lib",
        "//server/server/src/main/kotlin/org/jetbrains/bsp/bazel/server",
        # Needed for protobuf runtime version consitency, otherwise NoClassDefFoundError is raised
        "@maven//:original_com_google_protobuf_protobuf_java_4_29_3",
        # Needed because the installer injects its own classpath as the one to be used by the installed server
        "@server_maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core",
        "@server_maven//:org_jetbrains_kotlinx_kotlinx_coroutines_core_jvm",
    ],
)

publish_sonatype(
    name = "publish",
    coord = "com.virtuslab:bazel-bsp:{}".format(BAZEL_BSP_ARTIFACT_VERSION),
    jar = ":install_export-maven-artifact",
    pom = ":install_export-pom",
    source = ":install_export-maven-source",
)
