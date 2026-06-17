---
name: security-framework
description: "NIST/CIS/OWASP/CWE security controls mapped to code-level checks per language. Supply chain threat model and incident reference. Pre-commit hook templates and audit log format."
version: 1.0.0
author: Hermes Agent (OWL)
license: MIT
metadata:
  hermes:
    tags: [security, nist, cis, owasp, cwe, supply-chain, compliance, audit]
    related_skills: [coding-audit, requesting-code-review]
---

# Security Framework Reference

Maps industry-standard security controls to concrete code-level checks. Used by `coding-audit` and `requesting-code-review` to enforce security standards.

## Frameworks Covered

| Framework | Scope | Version |
|-----------|-------|---------|
| NIST 800-53 | US federal information security controls | Rev 5 |
| CIS Benchmarks | Secure configuration benchmarks | v8+ |
| OWASP Top 10 | Web application security risks | 2021 + 2025 update |
| CWE Top 25 | Common Weakness Enumeration | 2024 |
| GDPR / CCPA | Data protection regulations | Current |
| Supply Chain Security | npm/pip/cargo supply chain attacks | 2022-2026 |

## How to Use

1. Load this skill when performing security review or audit
2. Reference the specific framework mapping for the target language
3. Use `references/nist-800-53-mapping.md` for control-to-code mapping
4. Use `references/owasp-top-10-mapping.md` for web app security patterns
5. Use `references/cwe-top-25-mapping.md` for language-specific weakness patterns
6. Use `references/supply-chain-incidents.md` for real-world attack examples
7. Use `references/cis-benchmarks.md` for runtime hardening

## Control Severity

| Level | Meaning | Action |
|-------|---------|--------|
| 🔴 CRITICAL | Must fix — blocks commit | Exploitable vulnerability |
| 🟡 HIGH | Should fix — requires override | Significant risk |
| 🟠 MEDIUM | Recommended fix | Moderate risk |
| 🔵 LOW | Nice to have | Minor risk |

## Quick Reference: What to Check By Language

### Python
- SQL injection: parameterized queries only
- Command injection: no `os.system()`, no `subprocess.shell=True`
- Path traversal: validate all file paths
- Deserialization: no `pickle.loads()` on untrusted data
- SSRF: validate URLs before requests
- Hardcoded secrets: use env vars or secret managers
- Logging: never log PII, tokens, or passwords

### Rust
- Memory safety: Rust enforces this, but unsafe blocks need review
- Integer overflow: use `checked_add`, `saturating_add` for untrusted input
- Path traversal: `std::fs::canonicalize` + validation
- Command injection: `std::process::Command` with arg array (not shell)
- Deserialization: validate input before `serde` deserialization
- Secrets: use `secrecy` crate for zero-on-drop

### Bash / Shell
- Unquoted variables: always quote `"$VAR"`
- Word splitting: use arrays for command arguments
- `eval` / `exec` with user input: NEVER
- `curl | sh`: NEVER download and execute
- File permissions: least privilege (600 for secrets, 755 for scripts)
- `set -euo pipefail`: always use in scripts

### JavaScript / TypeScript
- XSS: no `innerHTML` with user input, use `textContent`
- Prototype pollution: no `__proto__` access, use `Object.create(null)`
- Command injection: no `child_process.exec()` with user input
- SSRF: validate URLs, block internal IPs
- Prototype chain: freeze `Object.prototype`
- eval / Function(): never with user input
- npm scripts: review all postinstall scripts

## Pre-commit Hook Template

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.5.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/PyCQA/bandit
    rev: '1.7.9'
    hooks:
      - id: bandit
        args: [-ll, -ii]

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: detect-private-key
      - id: check-added-large-files
      - id: no-commit-to-branch
        args: [--branch, main]

  - repo: local
    hooks:
      - id: cve-check
        name: CVE Vulnerability Check
        entry: python3 scripts/cve-check.sh
        language: python
        additional_dependencies: []

      - id: typosquat-check
        name: Typosquat Detection
        entry: python3 scripts/typosquat-check.sh
        language: python

      - id: postinstall-scan
        name: Postinstall Script Scan
        entry: python3 scripts/postinstall-scan.sh
        language: python
```

## Audit Log Format

Every audit produces a tamper-evident log entry:

```json
{
  "timestamp": "2026-06-16T10:30:00Z",
  "commit": "abc123def456",
  "author": "hermes-agent",
  "frameworks": ["nist-800-53", "owasp-top-10", "cwe-top-25"],
  "language": "python",
  "files_audited": 12,
  "findings": {
    "critical": 0,
    "high": 1,
    "medium": 3,
    "low": 2
  },
  "verdict": "WARN",
  "hash": "sha256:abcdef1234567890",
  "previous_hash": "sha256:0987654321abcdef"
}
```

The `hash` field is a SHA-256 of the entire entry (excluding the hash itself). The `previous_hash` chains entries for tamper evidence.

## Integration

- **coding-audit:** Uses framework mappings to determine severity of findings
- **requesting-code-review:** Independent reviewer references framework controls
- **context7-integration:** Fetches security advisories for detected versions
