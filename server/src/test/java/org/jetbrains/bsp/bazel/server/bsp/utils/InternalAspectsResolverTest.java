package org.jetbrains.bsp.bazel.server.bsp.utils;

import static org.junit.Assert.assertEquals;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collection;
import org.jetbrains.bsp.bazel.bazelrunner.data.BazelData;
import org.jetbrains.bsp.bazel.bazelrunner.data.SemanticVersion;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;

@RunWith(value = Parameterized.class)
public class InternalAspectsResolverTest {

  private Path workspaceRoot;
  private Path bspRoot;
  private String aspectName;
  private String expectedAspectLabel;

  public InternalAspectsResolverTest(
      String workspaceRoot, String bspRoot, String aspectName, String expectedAspectLabel) {
    this.workspaceRoot = Paths.get(workspaceRoot);
    this.bspRoot = Paths.get(bspRoot);
    this.aspectName = aspectName;
    this.expectedAspectLabel = expectedAspectLabel;
  }

  @Test
  public void shouldResolveLabels() {
    String actual = new InternalAspectsResolver(createBazelData()).resolveLabel(aspectName);
    assertEquals(expectedAspectLabel, actual);
  }

  private BazelData createBazelData() {
    return new BazelData() {
      @Override
      public String getExecRoot() {
        return null;
      }

      @Override
      public String getWorkspaceRoot() {
        return workspaceRoot.toString();
      }

      @Override
      public String getBinRoot() {
        return null;
      }

      @Override
      public SemanticVersion getVersion() {
        return null;
      }

      @Override
      public Path getBspProjectRoot() {
        return bspRoot;
      }
    };
  }

  @Parameters
  public static Collection<Object> data() {
    return Arrays.asList(
        (Object[])
            new Object[][] {
              {
                "/Users/user/workspace/test-project",
                "/Users/user/workspace/test-project",
                "get_classpath",
                "@//.bazelbsp:aspects.bzl%get_classpath"
              },
              {
                "/Users/user/workspace/test-project",
                "/Users/user/workspace/test-project/bsp-projects/test-project-bsp",
                "get_classpath",
                "@//bsp-projects/test-project-bsp/.bazelbsp:aspects.bzl%get_classpath"
              },
            });
  }
}