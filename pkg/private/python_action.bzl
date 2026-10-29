# Copyright 2026 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Actions that run the Python tools used to write archives."""

load("@rules_python//python:py_executable_info.bzl", "PyExecutableInfo")
load("@rules_python//python:py_runtime_info.bzl", "PyRuntimeInfo")

def run_writer(ctx, writer, arguments, tools = [], **kwargs):
    """Run a package writer with its configured interpreter and runfiles."""
    executable = writer[DefaultInfo].files_to_run
    env = {
        "LANG": "en_US.UTF-8",
        "LC_CTYPE": "UTF-8",
        "PYTHONIOENCODING": "UTF-8",
        "PYTHONUTF8": "1",
    }

    # rules_python 1.9+ exposes the entry point that sets up the binary's
    # imports. Older rules, platform interpreters, and Windows launchers
    # continue to run the py_binary itself.
    app = writer[PyExecutableInfo] if PyExecutableInfo in writer else None
    bootstrap = getattr(app, "stage2_bootstrap", None)
    runtime = writer[PyRuntimeInfo] if PyRuntimeInfo in writer else None
    if bootstrap and runtime and runtime.interpreter and executable.executable.extension != "exe":
        tools = [executable, bootstrap, runtime.files] + tools
        env["RUNFILES_DIR"] = executable.executable.path + ".runfiles"
        arguments = app.interpreter_args + [bootstrap.path] + arguments
        executable = getattr(runtime, "interpreter_files_to_run", None) or runtime.interpreter
    ctx.actions.run(executable = executable, arguments = arguments, tools = tools, env = env, **kwargs)
