"""Module extension that provisions the rules_rust repository."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_patch = tag_class(
    doc = "Additional patches to apply to the pinned rules_rust archive.",
    attrs = {
        "patches": attr.label_list(
            doc = "Additional patch files to apply to rules_rust.",
        ),
        "strip": attr.int(
            doc = "Equivalent to adding `-pN` when applying `patches`.",
            default = 0,
        ),
    },
)

_BUILTIN_PATCHES = [
    # bootstrap_process_wrapper links libstdc++ dynamically with no rpath.
    # Nix dev shells strip LD_LIBRARY_PATH in the sandbox, causing link
    # failures. Static linking eliminates the runtime dependency.
    Label("//rs/experimental/patches:bootstrap-linkstatic.patch"),
]

def _rules_rust_impl(mctx):
    patches = list(_BUILTIN_PATCHES)
    strip_values = set([1])  # builtin patches use -p1

    for mod in mctx.modules:
        for tag in mod.tags.patch:
            patches.extend(tag.patches)
            strip_values.add(tag.strip)

    if len(strip_values) > 1:
        fail("Found conflicting strip values in rules_rust.patch tags")

    strip = list(strip_values)[0] if strip_values else 1

    http_archive(
        name = "rules_rust",
        integrity = "sha256-xT7zyL35CDK5b7iKdKL+WchslRZsnXDXuBMHiqVD0ps=",
        strip_prefix = "rules_rust-7ed8a24a37be47378b8a266ae3016148b9cb5c49",
        url = "https://github.com/hermeticbuild/rules_rust/archive/7ed8a24a37be47378b8a266ae3016148b9cb5c49.tar.gz",
        patches = patches,
        patch_strip = strip,
    )

    return mctx.extension_metadata(reproducible = True)

rules_rust = module_extension(
    implementation = _rules_rust_impl,
    tag_classes = {
        "patch": _patch,
    },
)
