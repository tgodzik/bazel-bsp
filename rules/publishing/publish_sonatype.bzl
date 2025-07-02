load("@aspect_bazel_lib//lib:expand_template.bzl", "expand_template_rule")
load("@aspect_bazel_lib//lib:run_binary.bzl", "run_binary")
load("@rules_pkg//pkg:mappings.bzl", "pkg_files")
load("@rules_pkg//pkg/private/zip:zip.bzl", "pkg_zip")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

def publish_sonatype(
        name,
        coord = None,
        jar = None,
        source = None,
        pom = None,
        doc = None):
    """Macro for generating a Sonatype's release bundle and running publish action with a
    new Sonatype release API: https://central.sonatype.org/publish/publish-portal-api/#uploading-a-deployment-bundle

    Invocation example:
    ```
    # export four env variables:
    # - SONATYPE_USERNAME: username for the sonatype account
    # - SONATYPE_PASSWORD: password for the sonatype account
    # - SONATYPE_SIGNING_KEY: private key used for signing the artifacts
    # - SONATYPE_SIGNING_KEY_PASSWORD: password for the private key
    bazel run publish_target \
       --action_env=SONATYPE_USERNAME \
       --action_env=SONATYPE_PASSWORD \
       --action_env=SONATYPE_SIGNING_KEY \
       --action_env=SONATYPE_SIGNING_KEY_PASSWORD
    ```

    Args:
      name: A unique name for this rule
      coord: Maven coordinates in the format of: organization:product:version
      jar: Jar file to be published
      source: Source jar file to be published
      pom: Pom file to be published
    """

    coordinates = _parse_coord(coord)

    [
        _calculate_hashes(
            name = "{}_{}".format(name, suffix),
            artifact = artifact,
        )
        for artifact, suffix in [(pom, "pom"), (jar, "jar"), (source, "source"), (doc, "doc")]
    ]

    [
        _sign(
            name = "{}_{}".format(name, suffix),
            artifact = artifact,
        )
        for artifact, suffix in [(pom, "pom"), (jar, "jar"), (source, "source"), (doc, "doc")]
    ]

    pkg_files(
        name = "{}_bundle_files".format(name),
        prefix = _get_prefix(coordinates),
        srcs = [
            pom,
            "{}_pom_md5".format(name),
            "{}_pom_sha1".format(name),
            "{}_pom_sha256".format(name),
            "{}_pom_sha512".format(name),
            "{}_pom_asc".format(name),
            jar,
            "{}_jar_md5".format(name),
            "{}_jar_sha1".format(name),
            "{}_jar_sha256".format(name),
            "{}_jar_sha512".format(name),
            "{}_jar_asc".format(name),
            doc,
            "{}_doc_md5".format(name),
            "{}_doc_sha1".format(name),
            "{}_doc_sha256".format(name),
            "{}_doc_sha512".format(name),
            "{}_doc_asc".format(name),
            source,
            "{}_source_md5".format(name),
            "{}_source_sha1".format(name),
            "{}_source_sha256".format(name),
            "{}_source_sha512".format(name),
            "{}_source_asc".format(name),
        ],
        renames = {
            pom: "{}-{}.pom".format(coordinates.artifact, coordinates.version),
            "{}_pom_asc".format(name): "{}-{}.pom.asc".format(coordinates.artifact, coordinates.version),
            "{}_pom_md5".format(name): "{}-{}.pom.md5".format(coordinates.artifact, coordinates.version),
            "{}_pom_sha1".format(name): "{}-{}.pom.sha1".format(coordinates.artifact, coordinates.version),
            "{}_pom_sha256".format(name): "{}-{}.pom.sha256".format(coordinates.artifact, coordinates.version),
            "{}_pom_sha512".format(name): "{}-{}.pom.sha512".format(coordinates.artifact, coordinates.version),
            jar: "{}-{}.jar".format(coordinates.artifact, coordinates.version),
            "{}_jar_asc".format(name): "{}-{}.jar.asc".format(coordinates.artifact, coordinates.version),
            "{}_jar_md5".format(name): "{}-{}.jar.md5".format(coordinates.artifact, coordinates.version),
            "{}_jar_sha1".format(name): "{}-{}.jar.sha1".format(coordinates.artifact, coordinates.version),
            "{}_jar_sha256".format(name): "{}-{}.jar.sha256".format(coordinates.artifact, coordinates.version),
            "{}_jar_sha512".format(name): "{}-{}.jar.sha512".format(coordinates.artifact, coordinates.version),
            doc: "{}-{}-javadoc.jar".format(coordinates.artifact, coordinates.version),
            "{}_doc_asc".format(name): "{}-{}-javadoc.jar.asc".format(coordinates.artifact, coordinates.version),
            "{}_doc_md5".format(name): "{}-{}-javadoc.jar.md5".format(coordinates.artifact, coordinates.version),
            "{}_doc_sha1".format(name): "{}-{}-javadoc.jar.sha1".format(coordinates.artifact, coordinates.version),
            "{}_doc_sha256".format(name): "{}-{}-javadoc.jar.sha256".format(coordinates.artifact, coordinates.version),
            "{}_doc_sha512".format(name): "{}-{}-javadoc.jar.sha512".format(coordinates.artifact, coordinates.version),
            source: "{}-{}-sources.jar".format(coordinates.artifact, coordinates.version),
            "{}_source_asc".format(name): "{}-{}-sources.jar.asc".format(coordinates.artifact, coordinates.version),
            "{}_source_md5".format(name): "{}-{}-sources.jar.md5".format(coordinates.artifact, coordinates.version),
            "{}_source_sha1".format(name): "{}-{}-sources.jar.sha1".format(coordinates.artifact, coordinates.version),
            "{}_source_sha256".format(name): "{}-{}-sources.jar.sha256".format(coordinates.artifact, coordinates.version),
            "{}_source_sha512".format(name): "{}-{}-sources.jar.sha512".format(coordinates.artifact, coordinates.version),
        },
        tags = ["manual"],
    )

    pkg_zip(
        name = "{}_bundle".format(name),
        srcs = [
            ":{}_bundle_files".format(name),
        ],
        tags = ["manual"],
    )

    data = [
        "@curl",
        "@echo",
        "@base64",
        ":{}_bundle".format(name),
    ]

    expand_template_rule(
        name = "{}.sh".format(name),
        data = data,
        out = "{}_upload.sh".format(name),
        is_executable = True,
        substitutions = {
            "{CURL}": "$(rootpath @curl)",
            "{ECHO}": "$(rootpath @echo)",
            "{BASE64}": "$(rootpath @base64)",
            "{BUNDLE}": "$(rootpath :{}_bundle)".format(name),
        },
        template = "//rules/publishing:upload.sh.tpl",
        tags = ["manual"],
    )

    sh_binary(
        name = name,
        data = data,
        srcs = [":{}.sh".format(name)],
        tags = ["manual"],
    )

def _parse_coord(coord):
    splitted = coord.split(":")
    return struct(
        org = splitted[0],
        artifact = splitted[1],
        version = splitted[2],
    )

def _get_prefix(coord):
    return "/".join([
        coord.org.replace(".", "/"),
        coord.artifact.replace(".", "/"),
        coord.version,
    ])

def _sign(
        name,
        artifact):
    out = "{}.asc".format(name)
    name = "{}_asc".format(name)

    run_binary(
        name = name,
        tool = "//rules/publishing:pgp_signer",
        srcs = [artifact],
        outs = [out],
        env = {
            "MAVEN_SIGNING_TOSIGN": "$(location {})".format(artifact),
            "MAVEN_SIGNING_OUTPUT_PATH": "$(location {})".format(out),
        },
        use_default_shell_env = True,
        tags = [
            "manual",
        ],
    )

def _calculate_hashes(
        name,
        artifact,
        types = ["md5", "sha1", "sha256", "sha512"]):
    type_to_bin = {
        "md5": "@md5sum",
        "sha1": "@sha1sum",
        "sha256": "@sha256sum",
        "sha512": "@sha512sum",
    }

    [
        native.genrule(
            name = "{}_{}".format(name, tp),
            srcs = [
                artifact,
            ],
            outs = [
                out,
            ],
            cmd = "$(location {}) $(location {}) | awk '{{print $$1}}' > $@".format(type_to_bin[tp], artifact),
            tools = [
                type_to_bin[tp],
            ],
            tags = ["manual"],
        )
        for tp in types
        if tp in type_to_bin
        for out in ["{}.{}".format(name, tp)]
    ]
