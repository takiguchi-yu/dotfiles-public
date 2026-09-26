#!/usr/bin/env python3
"""Promote Claude Code's own ai-title to the session name.

Hooked on UserPromptSubmit and SessionStart. Claude Code already generates a
Haiku topic title on the first turn and records it in the transcript as
{"type":"ai-title","aiTitle":...}; this hook copies it into the session name,
which is what /rename sets. It emits a title only while the session has none,
so a manual /rename is never overwritten.
"""

import json
import sys

EVENTS = ("UserPromptSubmit", "SessionStart")


def latest_ai_title(path):
    """Return the last non-empty aiTitle in the transcript, or None."""
    found = None
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                if '"ai-title"' not in line:
                    continue
                try:
                    record = json.loads(line)
                except ValueError:
                    continue
                if record.get("type") != "ai-title":
                    continue
                title = (record.get("aiTitle") or "").strip()
                if title:
                    found = title
    except OSError:
        return None
    return found


def main():
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return

    event = payload.get("hook_event_name")
    if event not in EVENTS:
        return

    # Already named - by /rename, or by an earlier run of this hook. Leave it.
    if (payload.get("session_title") or "").strip():
        return

    transcript = payload.get("transcript_path")
    if not transcript:
        return

    title = latest_ai_title(transcript)
    if not title:
        return

    json.dump(
        {"hookSpecificOutput": {"hookEventName": event, "sessionTitle": title}},
        sys.stdout,
        ensure_ascii=False,
    )


if __name__ == "__main__":
    main()
