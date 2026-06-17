#!/usr/bin/env python3
"""
Lockfile Diff Analyzer — Detects suspicious changes in package-lock.json.

Usage:
  python3 lockfile-diff.sh <lockfile-path>

Flags:
  - New packages not in original lockfile
  - Integrity hash changes
  - Registry URL changes
  - Version downgrades

Output: JSON with findings.
"""
import json
import sys
import re
import subprocess


def get_current_packages(lockfile):
    """Extract current packages from lockfile."""
    try:
        with open(lockfile) as f:
            data = json.load(f)
        packages = {}
        for key, val in data.get("packages", {}).items():
            if not key:
                continue
            name = key.replace("node_modules/", "")
            packages[name] = {
                "version": val.get("version", ""),
                "resolved": val.get("resolved", ""),
                "integrity": val.get("integrity", ""),
                "link": val.get("link", False),
            }
        return packages
    except Exception as e:
        return {}


def get_git_original(lockfile):
    """Get the original (HEAD) version of the lockfile."""
    try:
        result = subprocess.run(
            ["git", "show", f"HEAD:{lockfile}"],
            capture_output=True, text=True, timeout=10
        )
        if result.returncode != 0:
            return {}
        data = json.loads(result.stdout)
        packages = {}
        for key, val in data.get("packages", {}).items():
            if not key:
                continue
            name = key.replace("node_modules/", "")
            packages[name] = {
                "version": val.get("version", ""),
                "resolved": val.get("resolved", ""),
                "integrity": val.get("integrity", ""),
                "link": val.get("link", False),
            }
        return packages
    except Exception:
        return {}


def analyze_diff(current, original):
    """Compare current vs original packages."""
    findings = []

    for name, cur in current.items():
        if name not in original:
            # New package
            if not cur.get("link", False):  # Skip local link: packages
                findings.append({
                    "package": name,
                    "type": "NEW_PACKAGE",
                    "severity": "WARN",
                    "detail": f"New dependency: {name}@{cur['version']}",
                    "version": cur["version"],
                    "resolved": cur.get("resolved", ""),
                })
        else:
            orig = original[name]

            # Version change
            if cur["version"] != orig["version"]:
                # Check if it's a downgrade
                finding = {
                    "package": name,
                    "type": "VERSION_CHANGE",
                    "severity": "WARN",
                    "detail": f"{name}: {orig['version']} → {cur['version']}",
                    "old_version": orig["version"],
                    "new_version": cur["version"],
                }
                findings.append(finding)

            # Integrity hash change (same version, different hash = suspicious)
            if (cur["integrity"] and orig["integrity"] and
                    cur["integrity"] != orig["integrity"]):
                findings.append({
                    "package": name,
                    "type": "INTEGRITY_CHANGE",
                    "severity": "FAIL",
                    "detail": f"Integrity hash changed for {name}@{cur['version']}",
                    "old_hash": orig["integrity"][:16] + "...",
                    "new_hash": cur["integrity"][:16] + "...",
                })

            # Registry URL change
            if (cur.get("resolved") and orig.get("resolved") and
                    cur["resolved"] != orig["resolved"]):
                findings.append({
                    "package": name,
                    "type": "REGISTRY_CHANGE",
                    "severity": "FAIL",
                    "detail": f"Registry URL changed for {name}",
                    "old_url": orig["resolved"][:80],
                    "new_url": cur["resolved"][:80],
                })

    # Check for removed packages (less suspicious, but worth noting)
    for name in original:
        if name not in current:
            findings.append({
                "package": name,
                "type": "REMOVED_PACKAGE",
                "severity": "INFO",
                "detail": f"Removed: {name}@{original[name]['version']}",
            })

    return findings


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <lockfile-path>")
        sys.exit(1)

    lockfile = sys.argv[1]
    current = get_current_packages(lockfile)
    original = get_git_original(lockfile)

    if not current:
        print(json.dumps({"error": f"Could not parse {lockfile}"}))
        sys.exit(1)

    if not original:
        # No git history — just report current state
        print(json.dumps({
            "packages": len(current),
            "findings": 0,
            "verdict": "SKIP",
            "reason": "No git history to compare against",
        }))
        return

    findings = analyze_diff(current, original)

    fails = [f for f in findings if f["severity"] == "FAIL"]
    warns = [f for f in findings if f["severity"] == "WARN"]

    verdict = "PASS"
    if fails:
        verdict = "FAIL"
    elif warns:
        verdict = "WARN"

    output = {
        "packages": len(current),
        "changes": len(findings),
        "fails": len(fails),
        "warns": len(warns),
        "verdict": verdict,
        "findings": findings,
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
