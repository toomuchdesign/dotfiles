#!/usr/bin/env python3
"""PreToolUse gate: block a too-1-by-1 picker that has no item card above it.

too-1-by-1 asks each item through AskUserQuestion with header `<n>/<total>`.
The card (`### <n>/<total> · …`) must be visible text earlier in the same turn;
otherwise the user only sees the picker. The turn starts after the previous
AskUserQuestion call or the last user prompt.

Contract: reads the PreToolUse JSON on stdin. Exit 0 allows; exit 2 blocks and
feeds stderr back to the agent. Fails open when the transcript can't be read.
"""
import json
import re
import sys

HEADER = re.compile(r"^(\d+)/(\d+)$")


def blocks(entry):
    content = entry.get("message", {}).get("content")
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    return content if isinstance(content, list) else []


def card_in_turn(lines, card, current_id):
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except ValueError:
            continue
        kind = entry.get("type")
        if kind == "user":
            if any(b.get("type") == "text" for b in blocks(entry)):
                return False
        elif kind == "assistant":
            for b in blocks(entry):
                if b.get("type") == "text" and card in b.get("text", ""):
                    return True
                if b.get("type") == "tool_use" and b.get("name") == "AskUserQuestion" and b.get("id") != current_id:
                    return False
    return False


def main():
    data = json.load(sys.stdin)
    questions = data.get("tool_input", {}).get("questions") or []
    match = HEADER.match(questions[0].get("header", "")) if questions else None
    if not match:
        return 0
    try:
        with open(data["transcript_path"]) as f:
            lines = f.readlines()
    except (KeyError, OSError):
        return 0
    card = f"### {match[1]}/{match[2]}"
    if card_in_turn(lines, card, data.get("tool_use_id")):
        return 0
    print(
        f"Item {match[1]}/{match[2]} has no card: the user sees only the picker. "
        "Don't call AskUserQuestion again for this item. End your reply with the "
        f"full card (`{card} · …`, Where, In plain words, Options, Why ★) as "
        "plain text, finishing with the **Your call** line.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
