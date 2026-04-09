#!/usr/bin/env python3

import json
import os
import sys
import tempfile
from pathlib import Path
import shutil


def _unique_paths(paths):
    seen = set()
    unique = []
    for path in paths:
        if not path:
            continue
        resolved = str(path)
        if resolved in seen:
            continue
        seen.add(resolved)
        unique.append(path)
    return unique


def _candidate_homes(original_home):
    candidates = []

    runtime_override = os.environ.get("MEMPALACE_HOME")
    if runtime_override:
        candidates.append(Path(runtime_override).expanduser())

    if original_home:
        candidates.append(original_home)
        candidates.append(original_home / ".ai-tools" / "mempalace-home")

        xdg_state_home = os.environ.get("XDG_STATE_HOME")
        if xdg_state_home:
            candidates.append(Path(xdg_state_home).expanduser() / "my-ai-tools" / "mempalace-home")
        else:
            candidates.append(original_home / ".local" / "state" / "my-ai-tools" / "mempalace-home")

        xdg_data_home = os.environ.get("XDG_DATA_HOME")
        if xdg_data_home:
            candidates.append(Path(xdg_data_home).expanduser() / "my-ai-tools" / "mempalace-home")
        else:
            candidates.append(original_home / ".local" / "share" / "my-ai-tools" / "mempalace-home")

    tmp_root = Path(os.environ.get("TMPDIR") or tempfile.gettempdir())
    user_name = os.environ.get("USER") or os.environ.get("USERNAME") or "user"
    candidates.append(tmp_root / f"mempalace-home-{user_name}")

    return _unique_paths(candidates)


def _is_writable_home(home_path):
    mempalace_dir = home_path / ".mempalace"
    try:
        mempalace_dir.mkdir(parents=True, exist_ok=True)
        probe_file = mempalace_dir / ".write-test"
        probe_file.write_text("ok", encoding="utf-8")
        probe_file.unlink()
        return True
    except OSError:
        return False


def _copy_if_missing(source_path, destination_path):
    if destination_path.exists() or not source_path.exists():
        return

    if source_path.is_dir():
        shutil.copytree(source_path, destination_path)
        return

    destination_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source_path, destination_path)


def _seed_runtime_home(runtime_home, original_home):
    runtime_mempalace_dir = runtime_home / ".mempalace"
    runtime_mempalace_dir.mkdir(parents=True, exist_ok=True)
    (runtime_mempalace_dir / "palace").mkdir(parents=True, exist_ok=True)

    if not original_home or runtime_home == original_home:
        return

    source_dir = original_home / ".mempalace"
    if not source_dir.exists():
        return

    for file_name in ("config.json", "wing_config.json", "identity.txt", "people_map.json"):
        _copy_if_missing(source_dir / file_name, runtime_mempalace_dir / file_name)

    for dir_name in ("agents", "palace"):
        _copy_if_missing(source_dir / dir_name, runtime_mempalace_dir / dir_name)


def _resolve_runtime_home():
    original_home_env = os.environ.get("HOME")
    original_home = Path(original_home_env).expanduser() if original_home_env else None

    for candidate in _candidate_homes(original_home):
        if not _is_writable_home(candidate):
            continue
        _seed_runtime_home(candidate, original_home)
        return candidate

    raise RuntimeError("No writable home directory found for mempalace MCP")


def _configure_runtime_environment():
    runtime_home = _resolve_runtime_home()
    runtime_mempalace_dir = runtime_home / ".mempalace"

    os.environ["HOME"] = str(runtime_home)
    os.environ.setdefault("MEMPALACE_HOME", str(runtime_home))
    os.environ["MEMPALACE_PALACE_PATH"] = str(runtime_mempalace_dir / "palace")


def _read_line_message():
    line = sys.stdin.readline()
    if not line:
        return None, None

    line = line.strip()
    if not line:
        return "line", None

    return "line", json.loads(line)


def _read_header_message(first_line):
    headers = [first_line]
    while True:
        header_line = sys.stdin.buffer.readline()
        if not header_line:
            return "header", None
        headers.append(header_line)
        if header_line in (b"\r\n", b"\n"):
            break

    content_length = None
    for header in headers:
        lower_header = header.decode("utf-8", errors="replace").lower()
        if lower_header.startswith("content-length:"):
            content_length = int(lower_header.split(":", 1)[1].strip())
            break

    if content_length is None:
        raise ValueError("Missing Content-Length header")

    body = sys.stdin.buffer.read(content_length)
    if not body:
        return "header", None

    return "header", json.loads(body.decode("utf-8"))


def _read_message():
    first_line = sys.stdin.buffer.readline()
    if not first_line:
        return None, None

    if first_line.startswith(b"Content-Length:"):
        return _read_header_message(first_line)

    text_line = first_line.decode("utf-8")
    if not text_line.strip():
        return "line", None

    return "line", json.loads(text_line)


def _write_message(mode, payload):
    encoded = json.dumps(payload).encode("utf-8")

    if mode == "header":
        sys.stdout.buffer.write(f"Content-Length: {len(encoded)}\r\n\r\n".encode("utf-8"))
        sys.stdout.buffer.write(encoded)
        sys.stdout.buffer.flush()
        return

    sys.stdout.write(encoded.decode("utf-8") + "\n")
    sys.stdout.flush()


def main():
    _configure_runtime_environment()

    from mempalace import mcp_server

    while True:
        try:
            mode, request = _read_message()
            if mode is None:
                break
            if request is None:
                continue

            response = mcp_server.handle_request(request)
            if response is not None:
                _write_message(mode, response)
        except KeyboardInterrupt:
            break
        except Exception as exc:
            print(f"mempalace launcher error: {exc}", file=sys.stderr)
            break


if __name__ == "__main__":
    main()
