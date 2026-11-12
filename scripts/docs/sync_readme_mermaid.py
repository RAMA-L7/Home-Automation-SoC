#!/usr/bin/env python3
"""
Home-Automation-SoC — inject the Mermaid block diagram into README.md.

The diagram lives in docs/architecture/BLOCK_DIAGRAM.md (a markdown file with
a ```mermaid fence). This script copies that fenced block into README.md
between the markers, so the README and the standalone diagram can never drift.

    python scripts/docs/sync_readme_mermaid.py

Validate the diagram renders with:
    node scripts/docs/check_mermaid.mjs
"""

import os
import re
import sys

BEGIN = "<!-- BEGIN MERMAID BLOCK DIAGRAM -->"
END = "<!-- END MERMAID BLOCK DIAGRAM -->"

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE = os.path.join(ROOT, "docs", "architecture", "BLOCK_DIAGRAM.md")
README = os.path.join(ROOT, "README.md")


def extract_mermaid(text):
    """Return the contents of the first ```mermaid fenced block."""
    match = re.search(r"^```mermaid\s*$(.*?)^```\s*$", text, re.MULTILINE | re.DOTALL)
    if not match:
        raise SystemExit(f"no ```mermaid block found in {SOURCE}")
    return match.group(1).rstrip("\n")


def main():
    if not os.path.isfile(SOURCE):
        raise SystemExit(f"missing {SOURCE}")
    if not os.path.isfile(README):
        raise SystemExit(f"missing {README}")

    with open(SOURCE, "r", encoding="utf-8") as fh:
        mermaid = extract_mermaid(fh.read())

    with open(README, "r", encoding="utf-8") as fh:
        readme = fh.read()

    if BEGIN not in readme or END not in readme:
        raise SystemExit("README.md is missing the mermaid-diagram markers")

    # Replace only the fenced mermaid block inside the markers.  The marker
    # region is shared with hand-written prose, and an earlier version of this
    # script rewrote the region from the markers inward, deleting that prose.
    region = re.compile(re.escape(BEGIN) + r"(?P<body>.*?)" + re.escape(END), re.DOTALL)
    fence = re.compile(r"```mermaid\n.*?\n```", re.DOTALL)
    fresh = "```mermaid\n" + mermaid + "\n```"

    def replace_region(match):
        body = match.group("body")
        if fence.search(body):
            return BEGIN + fence.sub(fresh, body, count=1) + END
        return (
            f"{BEGIN}\n"
            "<!-- Source of truth: docs/architecture/BLOCK_DIAGRAM.md -->\n"
            "<!-- Regenerate with: python scripts/docs/sync_readme_mermaid.py -->\n"
            "\n" + fresh + "\n" + END
        )

    if region.search(readme):
        readme = region.sub(replace_region, readme)
    else:
        heading = "## \U0001f3d7\ufe0f System Block Diagram (Mermaid)"
        index = readme.find(heading)
        if index < 0:
            raise SystemExit("README.md: no Mermaid heading found")
        insert_at = readme.find("\n", index) + 1
        block = (
            f"{BEGIN}\n"
            "<!-- Source of truth: docs/architecture/BLOCK_DIAGRAM.md -->\n"
            "<!-- Regenerate with: python scripts/docs/sync_readme_mermaid.py -->\n"
            "\n" + fresh + "\n" + END
        )
        readme = readme[:insert_at] + "\n" + block + "\n" + readme[insert_at:]

    with open(README, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(readme)
    print(f"[updated] {README}")
    print(f"[source]  {SOURCE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
