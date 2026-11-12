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

    # Remove every existing block first so the script is idempotent and a
    # duplicated or half-written block cannot survive.
    readme = re.sub(re.escape(BEGIN) + r".*?" + re.escape(END), "@@BLOCK@@", readme, flags=re.DOTALL)
    readme = readme.replace(BEGIN, "").replace(END, "")

    block = (
        f"{BEGIN}\n"
        "<!-- Source of truth: docs/architecture/BLOCK_DIAGRAM.md -->\n"
        "<!-- Regenerate with: python scripts/docs/sync_readme_mermaid.py -->\n"
        "\n"
        "```mermaid\n"
        f"{mermaid}\n"
        "```\n"
        f"{END}"
    )

    if "@@BLOCK@@" in readme:
        readme = readme.replace("@@BLOCK@@", block)
    else:
        heading = "## \U0001f3d7\ufe0f System Block Diagram (Mermaid)"
        index = readme.find(heading)
        if index < 0:
            raise SystemExit("README.md: no Mermaid heading found")
        insert_at = readme.find("\n", index) + 1
        readme = readme[:insert_at] + "\n" + block + "\n" + readme[insert_at:]

    readme = re.sub(r"\n{4,}", "\n\n\n", readme)

    with open(README, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(readme)
    print(f"[updated] {README}")
    print(f"[source]  {SOURCE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
