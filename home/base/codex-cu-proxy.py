#!/usr/bin/env python3
"""MCP stdio proxy for Codex's cua_repl server.

opencode's MCP client (1.18.21) does not support MCP elicitation, but Codex
Computer Use asks for approval ("Allow Computer Use to use "<app>"?") through
`elicitation/create`. Registered directly, every approval-gated call fails with
"nodeRepl.createElicitation is unavailable...". This proxy sits between opencode
and cua_repl and answers those requests itself:

- CODEX_CU_PROXY_AUTO_APPROVE=1 approves everything silently.
- Otherwise the first use of an app pops a macOS dialog with
  Deny / Allow Once / Always Allow. "Always Allow" is remembered per app in
  ~/.local/state/codex-cu-proxy/approvals.json (all decisions are appended to
  approvals.log). Closing the dialog or the 300s timeout cancels the request.

The proxy also raises the `js` execution timeout when the caller omitted it, so
a pending approval dialog does not hit node_repl's 30s default.

Usage: codex-cu-proxy.py <real-server-command> [args...]
"""
import json
import os
import signal
import subprocess
import sys
import threading
import time

DIALOG_TIMEOUT_SEC = 300
JS_TIMEOUT_MS = 540_000
AUTO_APPROVE = os.environ.get("CODEX_CU_PROXY_AUTO_APPROVE", "0") == "1"

_STATE_HOME = os.environ.get("XDG_STATE_HOME") or os.path.join(
    os.path.expanduser("~"), ".local", "state"
)
STATE_DIR = os.path.join(_STATE_HOME, "codex-cu-proxy")
APPROVALS_FILE = os.path.join(STATE_DIR, "approvals.json")
LOG_FILE = os.path.join(STATE_DIR, "approvals.log")

_child = None
_child_stdin_lock = threading.Lock()
_shutdown_lock = threading.Lock()
_child_stopped = False
_approvals_lock = threading.Lock()


def _append_log(record):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        record = dict(record, time=time.strftime("%Y-%m-%dT%H:%M:%S%z"))
        with open(LOG_FILE, "a", encoding="utf-8") as fh:
            fh.write(json.dumps(record, ensure_ascii=False) + "\n")
    except OSError:
        pass


def _load_allowed():
    try:
        with open(APPROVALS_FILE, encoding="utf-8") as fh:
            return set(json.load(fh).get("always_allow_apps", []))
    except (OSError, ValueError):
        return set()


def _save_allowed(apps):
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        tmp = APPROVALS_FILE + ".tmp"
        with open(tmp, "w", encoding="utf-8") as fh:
            json.dump({"always_allow_apps": sorted(apps)}, fh, indent=2)
            fh.write("\n")
        os.replace(tmp, APPROVALS_FILE)
    except OSError:
        pass


def _apple_string(value):
    return '"%s"' % (
        value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ").replace("\r", " ")
    )


def _ask_dialog(message, title):
    script = (
        "set r to display dialog %s with title %s "
        'buttons {"Deny", "Allow Once", "Always Allow"} default button "Allow Once" '
        "with icon caution giving up after %d\n"
        'if gave up of r then return "GAVEUP"\n'
        "return button returned of r"
    ) % (_apple_string(message), _apple_string(title), DIALOG_TIMEOUT_SEC)
    try:
        proc = subprocess.run(
            ["osascript", "-e", script],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=DIALOG_TIMEOUT_SEC + 30,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        _append_log({"event": "dialog_error", "error": str(exc)})
        return "cancel"
    answer = (proc.stdout or "").strip()
    if answer == "Always Allow":
        return "always"
    if answer == "Allow Once":
        return "once"
    if answer == "Deny":
        return "deny"
    return "cancel"


def _approval_decision(message, app_id, app_name, tool_name):
    if AUTO_APPROVE:
        _append_log(
            {"decision": "accept", "source": "auto", "app": app_id, "app_name": app_name, "tool": tool_name}
        )
        return "once"
    with _approvals_lock:
        remembered = bool(app_id) and app_id in _load_allowed()
    if remembered:
        _append_log(
            {"decision": "accept", "source": "remembered", "app": app_id, "app_name": app_name, "tool": tool_name}
        )
        return "always"
    decision = _ask_dialog(message, "Codex Computer Use (opencode)")
    if decision == "always" and app_id:
        with _approvals_lock:
            allowed = _load_allowed()
            allowed.add(app_id)
            _save_allowed(allowed)
    _append_log(
        {"decision": decision, "source": "dialog", "app": app_id, "app_name": app_name, "tool": tool_name}
    )
    return decision


def _send_to_server(obj):
    data = json.dumps(obj, ensure_ascii=False).encode("utf-8") + b"\n"
    with _child_stdin_lock:
        _child.stdin.write(data)
        _child.stdin.flush()


def _handle_elicitation(msg):
    params = msg.get("params") or {}
    meta = params.get("_meta") or {}
    tool_params = meta.get("tool_params") or {}
    app_id = tool_params.get("app") or ""
    app_name = app_id
    for item in meta.get("tool_params_display") or []:
        if item.get("name") == "app" and item.get("value"):
            app_name = item["value"]
    decision = _approval_decision(
        params.get("message") or "", app_id, app_name, meta.get("tool_name") or ""
    )
    if decision == "always":
        result = {"action": "accept", "content": {}, "_meta": {"persist": "always"}}
    elif decision == "once":
        result = {"action": "accept", "content": {}, "_meta": {"persist": "session"}}
    elif decision == "deny":
        result = {"action": "decline"}
    else:
        result = {"action": "cancel"}
    _send_to_server({"jsonrpc": "2.0", "id": msg["id"], "result": result})


def _client_pump():
    for line in iter(sys.stdin.buffer.readline, b""):
        if not line.strip():
            continue
        out = line
        try:
            msg = json.loads(line.decode("utf-8"))
        except ValueError:
            msg = None
        if msg is not None and "id" in msg and msg.get("method") == "initialize":
            params = msg.setdefault("params", {})
            caps = params.setdefault("capabilities", {})
            caps["elicitation"] = {}
            out = (json.dumps(msg, ensure_ascii=False) + "\n").encode("utf-8")
        elif (
            msg is not None
            and msg.get("method") == "tools/call"
            and (msg.get("params") or {}).get("name") == "js"
        ):
            args = (msg.get("params") or {}).setdefault("arguments", {})
            if isinstance(args, dict) and "timeout_ms" not in args:
                args["timeout_ms"] = JS_TIMEOUT_MS
                out = (json.dumps(msg, ensure_ascii=False) + "\n").encode("utf-8")
        try:
            with _child_stdin_lock:
                _child.stdin.write(out)
                _child.stdin.flush()
        except (BrokenPipeError, ValueError):
            break
    _shutdown_child()


def _server_pump():
    for line in iter(_child.stdout.readline, b""):
        if not line.strip():
            continue
        msg = None
        try:
            msg = json.loads(line.decode("utf-8"))
        except ValueError:
            pass
        if msg is not None and "id" in msg and "method" in msg:
            if msg["method"] == "elicitation/create":
                try:
                    _handle_elicitation(msg)
                except Exception as exc:  # keep the pipe alive
                    _append_log({"event": "elicitation_error", "error": str(exc)})
                    _send_to_server({"jsonrpc": "2.0", "id": msg["id"], "result": {"action": "cancel"}})
            else:
                _send_to_server(
                    {"jsonrpc": "2.0", "id": msg["id"], "error": {"code": -32601, "message": "Method not found"}}
                )
            continue
        sys.stdout.buffer.write(line)
        sys.stdout.buffer.flush()


def _shutdown_child():
    global _child_stopped
    with _shutdown_lock:
        if _child_stopped:
            return
        _child_stopped = True
    try:
        _child.terminate()
    except Exception:
        pass
    try:
        _child.wait(timeout=5)
    except Exception:
        try:
            _child.kill()
        except Exception:
            pass


def main():
    global _child
    if len(sys.argv) < 2:
        sys.stderr.write("usage: codex-cu-proxy.py <command> [args...]\n")
        return 64
    _child = subprocess.Popen(sys.argv[1:], stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    def on_signal(_signum, _frame):
        _shutdown_child()
        os._exit(0)

    signal.signal(signal.SIGTERM, on_signal)
    signal.signal(signal.SIGINT, on_signal)

    client_thread = threading.Thread(target=_client_pump, daemon=True)
    server_thread = threading.Thread(target=_server_pump, daemon=True)
    client_thread.start()
    server_thread.start()
    server_thread.join()
    _shutdown_child()
    return 0


if __name__ == "__main__":
    sys.exit(main())
