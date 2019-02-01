load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def multirun_dependencies():
    _maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "eb5c57e4c12e68c0c20bc774bfbc60a568e800d025557bc4ea022c6479acc867",
        strip_prefix = "bazel-skylib-0.6.0",
        urls = ["https://github.com/bazelbuild/bazel-skylib/archive/0.6.0.tar.gz"],
    )

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)
