load("@bazel_skylib//:lib.bzl", "shell")

_CONTENT_PREFIX = """#!/usr/bin/env bash

set -euo pipefail

"""

def _multirun_impl(ctx):
    transitive_depsets = []
    content = [_CONTENT_PREFIX]
    args_for_commands = ctx.attr.args_for_commands
    env_for_commands = ctx.attr.env_for_commands

    if not args_for_commands:
        args_for_commands = [""] * len(ctx.attr.commands)
        print(args_for_commands)

    if not env_for_commands:
        env_for_commands = [""] * len(ctx.attr.commands)

    if len(ctx.attr.commands) != len(args_for_commands):
        fail("The length of the commands (len %s) and args_for_commands (len %s) attribute have to match." % (len(ctx.attr.commands), len(args_for_commands)))

    if len(ctx.attr.commands) != len(env_for_commands):
        fail("The length of the commands (len %s) and env_for_commands (len %s) attribute have to match." % (len(ctx.attr.commands), len(env_for_commands)))

    for command, attrs, envs  in zip(ctx.attr.commands, args_for_commands, env_for_commands):
        info = command[DefaultInfo]
        if info.files_to_run == None:
            fail("%s is not executable" % command.label, attr = "commands")
        exe = info.files_to_run.executable
        if exe == None:
            fail("%s does not have an executable file" % command.label, attr = "commands")

        default_runfiles = info.default_runfiles
        if default_runfiles != None:
            transitive_depsets.append(default_runfiles.files)
        full_command = "%s ./%s %s" % (envs, shell.quote(exe.short_path), attrs)
        content.append("echo Running %s\n./%s\n" % (shell.quote(str(command.label)), full_command))

    out_file = ctx.actions.declare_file(ctx.label.name + ".bash")
    ctx.actions.write(
        output = out_file,
        content = "".join(content),
        is_executable = True,
    )
    runfiles = ctx.runfiles(
        transitive_files = depset([], transitive = transitive_depsets),
    )
    return [DefaultInfo(
        files = depset([out_file]),
        runfiles = runfiles,
        executable = out_file,
    )]

_multirun = rule(
    implementation = _multirun_impl,
    attrs = {
        "commands": attr.label_list(
            allow_empty = True,  # this is explicitly allowed - generated invocations may need to run 0 targets
            mandatory = True,
            allow_files = True,
            doc = "Targets to run in specified order",
            cfg = "host",
        ),
        "args_for_commands": attr.string_list(
            default = [],
            doc = """This list has to match the commands list. Each entry is a string with all
                     arguments to be passed to the matching command, e.g. '--a=b --c=d'""",
        ),
        "env_for_commands": attr.string_list(
            default = [],
            doc = """This list has to match the commands list. Each entry is a string with all
                     env variables to be passed to the matching command, e.g. 'ENV1=a ENV2=b'""",
        ),
    },
    executable = True,
)

def multirun(**kwargs):
    tags = kwargs.get("tags", [])
    if "manual" not in tags:
        tags.append("manual")
        kwargs["tags"] = tags
    _multirun(
        **kwargs
    )
