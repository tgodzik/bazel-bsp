package org.jetbrains.bazel.android

import org.jetbrains.bazel.base.BazelBspTestBaseScenario
import org.jetbrains.bazel.base.BazelBspTestScenarioStep
import org.jetbrains.bazel.install.Install
import org.jetbrains.bazel.install.cli.CliOptions
import org.jetbrains.bazel.install.cli.ProjectViewCliOptions
import org.jetbrains.bazel.label.Label
import org.jetbrains.bsp.protocol.ResourcesItem
import org.jetbrains.bsp.protocol.ResourcesParams
import org.jetbrains.bsp.protocol.ResourcesResult
import org.jetbrains.bsp.protocol.WorkspaceBuildTargetsResult
import java.net.URI
import kotlin.io.path.Path
import kotlin.io.path.exists
import kotlin.io.path.name
import kotlin.io.path.toPath
import kotlin.time.Duration.Companion.minutes

abstract class BazelBspAndroidProjectTestBase : BazelBspTestBaseScenario() {
  private val testClient = createTestkitClient()

  protected abstract val enabledRules: List<String>

  override fun installServer() {
    Install.runInstall(
      CliOptions(
        workspaceDir = Path(workspaceDir),
        projectViewCliOptions =
          ProjectViewCliOptions(
            bazelBinary = Path(bazelBinary),
            targets = listOf("//..."),
            enabledRules = enabledRules,
            buildFlags = listOf("--action_env=ANDROID_HOME=${AndroidSdkDownloader.androidSdkPath}"),
          ),
      ),
    )
  }

  override fun scenarioSteps(): List<BazelBspTestScenarioStep> =
    listOf(
      downloadAndroidSdk(),
      compareWorkspaceBuildTargets(),
      compareBuildTargetResources(),
      compareWorkspaceLibraries(),
    )

  private fun downloadAndroidSdk() =
    BazelBspTestScenarioStep("Download Android SDK") {
      AndroidSdkDownloader.downloadAndroidSdkIfNeeded()
    }

  private fun expectedBuildTargetResourcesResult(): ResourcesResult {
    val appResources =
      ResourcesItem(
        Label.parse("@@//src/main:app"),
        listOf("file://\$WORKSPACE/src/main/AndroidManifest.xml"),
      )

    val libResources =
      ResourcesItem(
        Label.parse("@@//src/main/java/com/example/myapplication:lib"),
        listOf(
          "file://\$WORKSPACE/src/main/java/com/example/myapplication/AndroidManifest.xml",
          "file://\$WORKSPACE/src/main/java/com/example/myapplication/res/",
        ),
      )

    val libTestResources =
      ResourcesItem(
        Label.parse("@@//src/test/java/com/example/myapplication:lib_test"),
        listOf("file://\$WORKSPACE/src/test/java/com/example/myapplication/AndroidManifest.xml"),
      )

    return ResourcesResult(listOf(appResources, libResources, libTestResources))
  }

  private fun compareWorkspaceBuildTargets(): BazelBspTestScenarioStep =
    BazelBspTestScenarioStep(
      "Compare workspace/buildTargets",
    ) {
      testClient.test(timeout = 5.minutes) { session ->
        val result = session.server.workspaceBuildTargets()
        testClient.assertJsonEquals<WorkspaceBuildTargetsResult>(expectedWorkspaceBuildTargetsResult(), result)
      }
    }

  private fun compareBuildTargetResources(): BazelBspTestScenarioStep =
    BazelBspTestScenarioStep(
      "Compare buildTarget/resources",
    ) {
      testClient.test(timeout = 1.minutes) { session ->
        val resourcesParams = ResourcesParams(expectedTargetIdentifiers())
        val result = session.server.buildTargetResources(resourcesParams)
        testClient.assertJsonEquals<ResourcesResult>(expectedBuildTargetResourcesResult(), result)
      }
    }

  private fun compareWorkspaceLibraries(): BazelBspTestScenarioStep =
    BazelBspTestScenarioStep(
      "Compare workspace/libraries",
    ) {
      testClient.test(timeout = 5.minutes) { session ->
        // Make sure Bazel unpacks all the dependent AARs
        session.server.workspaceBuildAndGetBuildTargets()
        val result = session.server.workspaceLibraries()
        val appCompatLibrary = result.libraries.first { "androidx_appcompat_appcompat" in it.id.toShortString() }

        val jars = appCompatLibrary.jars.toList().map { URI.create(it).toPath() }
        for (jar in jars) {
          require(jar.exists()) { "Jar $jar should exist" }
        }

        val expectedJarNames = setOf("classes_and_libs_merged.jar", "AndroidManifest.xml", "res", "R.txt")
        val jarNames = jars.map { it.name }.toSet()
        require(jarNames == expectedJarNames) { "$jarNames should be equal to $expectedJarNames" }
      }
    }
}
