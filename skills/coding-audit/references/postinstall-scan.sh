#!/usr/bin/env python3
"""
Postinstall Script Scanner — Detects suspicious behavior in npm postinstall scripts.

Usage:
  python3 postinstall-scan.sh <package.json-path>

Scans for:
  - Network calls (curl, wget, http.request, fetch)
  - Filesystem writes outside node_modules
  - eval/exec with dynamic content
  - Base64-encoded payloads
  - Obfuscated code patterns

Output: JSON with findings.
"""
import json
import sys
import re
import os


SUSPICIOUS_PATTERNS = {
    "network_call": {
        "pattern": r"(curl\s|wget\s|http\.request|fetch\(|https?\.\w+\()",
        "severity": "FAIL",
        "reason": "Network call in install script — potential data exfiltration",
    },
    "filesystem_write": {
        "pattern": r"(writeFileSync|writeFile|createWriteStream|fs\.write)",
        "severity": "WARN",
        "reason": "Filesystem write in install script",
    },
    "eval_exec": {
        "pattern": r"(eval\(|exec\(|execSync\(|child_process)",
        "severity": "WARN",
        "reason": "Dynamic code execution in install script",
    },
    "base64": {
        "pattern": r"(atob\(|btoa\(|base64|Buffer\.from\(['\"].*['\"],\s*['\"]base64['\"]\))",
        "severity": "FAIL",
        "reason": "Base64 encoding — potential obfuscated payload",
    },
    "env_access": {
        "pattern": r"(process\.env\[['\"](TOKEN|SECRET|KEY|PASSWORD|API)['\"]\]|process\.env\.(TOKEN|SECRET|KEY|PASSWORD|API))",
        "severity": "FAIL",
        "reason": "Accessing sensitive env vars in install script",
    },
    "download_execute": {
        "pattern": r"(curl.*\|.*sh|wget.*\|.*sh|curl.*\|.*bash|wget.*\|.*bash|curl.*exec|wget.*exec)",
        "severity": "FAIL",
        "reason": "Download and execute pattern — classic supply chain attack",
    },
    "obfuscation": {
        "pattern": r"(\\[\s*'\\x[0-9a-f]{2}'(\s*,\s*'\\x[0-9a-f]{2}')+\s*\]|String\.fromCharCode\(|unescape\()",
        "severity": "FAIL",
        "reason": "Obfuscated code — potential malware payload",
    },
}


def scan_script(script_content, script_name="unknown"):
    """Scan a script for suspicious patterns."""
    findings = []
    for check_name, check in SUSPICIOUS_PATTERNS.items():
        matches = re.finditer(check["pattern"], script_content, re.IGNORECASE)
        for match in matches:
            # Get context (3 lines around match)
            lines = script_content.split("\n")
            line_num = script_content[: match.start()].count("\n") + 1
            context_start = max(0, line_num - 2)
            context_end = min(len(lines), line_num + 1)
            context = "\n".join(lines[context_start:context_end])

            findings.append({
                "check": check_name,
                "severity": check["severity"],
                "reason": check["reason"],
                "script": script_name,
                "line": line_num,
                "match": match.group()[:80],
                "context": context,
            })
    return findings


def scan_package_json(path):
    """Scan a package.json for suspicious scripts."""
    findings = []
    try:
        with open(path) as f:
            pkg = json.load(f)

        scripts = pkg.get("scripts", {})
        script_keys = ["preinstall", "postinstall", "prepare", "prepublish", "prepublishOnly"]

        for key in script_keys:
            script = scripts.get(key, "")
            if script:
                hits = scan_script(script, f"{path}:{key}")
                findings.extend(hits)
    except Exception as e:
        findings.append({
            "check": "PARSE_ERROR",
            "severity": "WARN",
            "reason": str(e),
            "script": path,
            "line": 0,
            "match": "",
            "context": "",
        })
    return findings


def scan_node_modules(package_json_dir):
    """Scan all package.json files in node_modules for postinstall scripts."""
    findings = []
    node_modules = os.path.join(os.path.dirname(package_json_dir), "node_modules")
    if not os.path.isdir(node_modules):
        return findings

    for root, dirs, files in os.walk(node_modules):
        if "package.json" in files:
            pkg_path = os.path.join(root, "package.json")
            hits = scan_package_json(pkg_path)
            if hits:
                findings.extend(hits)
        # Don't recurse too deep
        if root.count(os.sep) > 6:
            dirs.clear()

    return findings


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <package.json-path>")
        sys.exit(1)

    target = sys.argv[1]

    if os.path.basename(target) == "package.json":
        findings = scan_package_json(target)
        # Also scan node_modules if present
        if os.path.isdir(os.path.join(os.path.dirname(target), "node_modules")):
            findings.extend(scan_node_modules(target))
    elif os.path.isdir(target):
        # Scan all package.json files in directory
        for root, dirs, files in os.walk(target):
            if "package.json" in files:
                findings.extend(scan_package_json(os.path.join(root, "package.json")))
            if root.count(os.sep) > 4:
                dirs.clear()
    else:
        print(json.dumps({"error": f"Unknown target: {target}"}))
        sys.exit(1)

    fails = [f for f in findings if f["severity"] == "FAIL"]
    warns = [f for f in findings if f["severity"] == "WARN"]

    verdict = "PASS"
    if fails:
        verdict = "FAIL"
    elif warns:
        verdict = "WARN"

    output = {
        "findings": len(findings),
        "fails": len(fails),
        "warns": len(warns),
        "verdict": verdict,
        "details": findings,
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
