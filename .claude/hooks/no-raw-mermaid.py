#!/usr/bin/env python3
"""Stop the turn when the response carries a raw ```mermaid block.

Hooked on Stop. The terminal does not render Mermaid, so a ```mermaid block
shows up as source text. DIAGRAM.md and the diagram skill say to convert it
with mmd2txt, but models skip that even with the skill in context, so this
hook enforces it: if any assistant text in the current turn has a mermaid
fence, it blocks once and asks for the mmd2txt version.

It reads last_assistant_message from the hook input, because the transcript
file may not hold the final message yet when Stop fires, and the transcript
for the earlier text of the same turn. Only text blocks are checked: Mermaid
written into files or sent with gh (GitHub bodies, where Mermaid is correct)
lives in tool_use and is ignored. A GitHub body pasted into the response is
still caught once; when the block fires again (stop_hook_active) the turn is
let through, so a deliberate quote ends with a one-line note instead of
looping. Any failure exits quietly so the hook never keeps Claude running.
"""

import json
import re
import sys

FENCE = re.compile(r"^[ \t]*(?:`{3,}|~{3,})[ \t]*mermaid\b", re.MULTILINE)

REASON = (
    "応答に ```mermaid のコードブロックがあります。ターミナルは Mermaid を図にしないので、"
    "元記述がそのまま表示されます。diagram スキルの手順どおり mmd2txt で罫線の図に変換し、"
    "その出力で図を載せ直してください。GitHub に書く本文を見せるために意図して Mermaid のまま"
    "載せたのなら、その旨を 1 行書いて終えてください。"
)


def is_user_prompt(record):
    """A prompt the user typed, as opposed to a tool result or injected meta."""
    if record.get("type") != "user" or record.get("isMeta"):
        return False
    content = (record.get("message") or {}).get("content")
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        kinds = {c.get("type") for c in content if isinstance(c, dict)}
        return "text" in kinds and "tool_result" not in kinds
    return False


def turn_texts(path):
    """Assistant text blocks written since the last user prompt."""
    texts = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                record = json.loads(line)
            except ValueError:
                continue
            if not isinstance(record, dict) or record.get("isSidechain"):
                continue
            if is_user_prompt(record):
                texts = []
            elif record.get("type") == "assistant":
                for c in (record.get("message") or {}).get("content") or []:
                    if isinstance(c, dict) and c.get("type") == "text":
                        texts.append(c.get("text") or "")
    return texts


def main():
    payload = json.load(sys.stdin)
    if not isinstance(payload, dict) or payload.get("stop_hook_active"):
        return
    texts = []
    last = payload.get("last_assistant_message")
    if isinstance(last, str):
        texts.append(last)
    path = payload.get("transcript_path")
    if isinstance(path, str) and path:
        try:
            texts += turn_texts(path)
        except (OSError, UnicodeDecodeError):
            pass
    if any(FENCE.search(t) for t in texts):
        print(json.dumps({"decision": "block", "reason": REASON}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception:  # noqa: BLE001 -- a broken hook must not block Stop
        pass
