---
name: coding-audit
description: "Automated code audit pipeline — lint, security, privacy, CVE, supply chain, dead-code, secrets, SBOM. Enforces language-specific standards for Python, Rust, Bash, JS/TS."
version: 1.0.0
author: Hermes Agent (OWL)
license: MIT
metadata:
  hermes:
    tags: [audit, security, quality, lint, cve, supply-chain, privacy, sbom]
    related_skills: [requesting-code-review, security-framework, test-driven-development]
---

# Coding Audit Pipeline

Automated audit that runs before every commit. Covers 10 dimensions: lint, security, privacy, CVE, supply chain, dependency audit, dead code, secrets, SBOM, and documentation.

**Core principle:** FAIL blocks commit. WARN requires explicit `# audit-ignore` comment with justification. No exceptions.

## When to Use

- Before every `git commit` (integrate with `requesting-code-review`)
- On every `git diff` of lockfiles (supply chain check)
- On every new dependency install
- Weekly cron: full project audit
- User says "audit this", "check this code", "is this secure"

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| 🔴 FAIL | Blocks commit | Must fix before merge |
| 🟡 WARN | Requires override | `# audit-ignore: <reason>` in code or explicit user approval |
| 🔵 INFO | FYI only | No action required |

## The Pipeline

### Step 1: Detect Language(s)

```bash
# Check for language indicators
ls *.py 2>/dev/null && echo "python"
ls Cargo.toml 2>/dev/null && echo "rust"
ls package.json 2>/dev/null && echo "javascript"
ls *.sh 2>/dev/null && echo "bash"
ls go.mod 2>/dev/null && echo "go"
```

Multi-language projects: run all applicable pipelines.

### Step 2: Lint

Run the language-appropriate linter. See `references/language-configs.md` for exact commands.

```bash
# Python
ruff check --select ALL src/ tests/

# Rust
cargo fmt --check && cargo clippy -- -D warnings

# Bash
shellcheck --severity=warning *.sh

# JavaScript/TypeScript
npx eslint --max-warnings=0 src/
npx tsc --noEmit --strict
```

**Outcome:** Unused imports, style violations, type errors → FAIL if new issues introduced.

### Step 3: Security Scan

```bash
# Python
bandit -r src/ -ll -ii

# JavaScript
npx semgrep --config=auto src/

# Rust (beyond clippy)
cargo audit

# Go
gosec ./...
```

**Outcome:** Security anti-patterns → FAIL.

### Step 4: Privacy / PII Detection

Scan added/modified lines for PII patterns:

```bash
# Email addresses
git diff | grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

# Phone numbers
git diff | grep -E "(\+?1[-.\s]?)?\(?[0-9]{3}\)?[-.\s]?[0-9]{3}[-.\s]?[0-9]{4}"

# SSN patterns
git diff | grep -E "[0-9]{3}-[0-9]{2}-[0-9]{4}"

# Credit card patterns
git diff | grep -E "[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}[-\s]?[0-9]{4}"

# API keys / tokens in code (not env files)
git diff -- "*.py" "*.js "*.ts" "*.rs" | grep -iE "(api_key|secret|password|token|passwd)\s*=\s*['\"][^'\"]{8,}['\"]"
```

**Outcome:** Hardcoded PII or secrets → FAIL.

### Step 5: CVE / Vulnerability Check

Query OSV.dev for all dependencies. See `references/cve-check.sh` for the query script.

```bash
# For each dependency in lockfile, query OSV
# Python (from requirements.txt or Pipfile.lock)
pip freeze | while read pkg; do
  name=$(echo "$pkg" | cut -d= -f1)
  version=$(echo "$pkg" | cut -d= -f3)
  curl -s -X POST https://api.osv.dev/v1/query \
    -H "Content-Type: application/json" \
    -d "{\"package\":{\"name\":\"$name\",\"ecosystem\":\"PyPI\"},\"version\":\"$version\"}" \
    | jq '.vulns | length'
done

# Node.js (from package-lock.json)
# Extract packages and query OSV
cat package-lock.json | jq -r '.packages | to_entries[] | "\(.key) \(.value.version)"' | \
  while read pkg; do
    name=$(echo "$pkg" | sed 's/ /|/' | cut -d'|' -f1 | sed 's/^node_modules\///')
    version=$(echo "$pkg" | sed 's/ /|/' | cut -d'|' -f2)
    [ -z "$version" ] && continue
    curl -s -X POST https://api.osv.dev/v1/query \
      -H "Content-Type: application/json" \
      -d "{\"package\":{\"name\":\"$name\",\"ecosystem\":\"npm\"},\"version\":\"$version\"}" \
      | jq '.vulns | length'
  done
```

**Outcome:** Known CVE in any dependency → FAIL (critical/high), WARN (medium), INFO (low).

### Step 6: Supply Chain Scan

Three checks:

#### 6a: Typosquat Detection
See `references/typosquat-check.sh`. Computes Levenshtein distance against top-1000 packages.

```bash
bash references/typosquat-check.sh <lockfile>
```

#### 6b: Postinstall Script Analysis
Scan any package with `postinstall`/`preinstall`/`prepare` scripts. Pass the **project root directory** (not a file path) — the script walks `node_modules/` to find all package.json files:

```bash
# Scan a project's node_modules
python3 references/postinstall-scan.sh /path/to/project/

# Or scan a single package.json
python3 references/postinstall-scan.sh /path/to/package.json
```

Flag if script contains: `curl`, `wget`, `http.request`, `eval`, `exec`, `base64`, filesystem writes outside `node_modules`.

**Outcome:** Suspicious postinstall → FAIL. Network calls in postinstall → FAIL.

#### 6c: Lockfile Diff Review
See `references/lockfile-diff.sh`.

```bash
# On every git diff of lockfile
git diff -- package-lock.json | python3 references/lockfile-diff.sh
```

Flag: new packages not in original lockfile, integrity hash changes, registry URL changes.

**Outcome:** Unexplained lockfile changes → WARN (requires explicit approval).

### Step 7: Dependency Audit

```bash
# Python
pip-audit --strict

# JavaScript
npm audit --audit-level=high

# Rust
cargo audit
cargo deny check

# Go
govulncheck ./...
```

**Outcome:** Known vulnerabilities → FAIL (critical/high), WARN (medium).

### Step 8: Dead Code Detection

```bash
# Python
vulture src/ --min-confidence 80

# JavaScript/TypeScript
npx ts-prune
npx knip

# Rust
cargo udeps
```

**Outcome:** Dead code → WARN (not blocking, but should be cleaned up).

### Step 9: Secrets / Entropy Scan

```bash
# High-entropy strings (potential secrets)
git diff | grep -E "[A-Za-z0-9+/]{40,}=*"

# Check for .env files accidentally committed
git diff --name-only | grep -E "\.env$|\.env\.local$|\.env\.production$"

# Check for private keys
git diff | grep -E "-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----"
```

**Outcome:** High-entropy strings in code → WARN. Private keys or .env files → FAIL.

### Step 10: SBOM Generation

```bash
# Python
pip install cyclonedx-bom
cyclonedx-py requirements.txt > sbom.json

# JavaScript
npx @cyclonedx/cyclonedx-npm > sbom.json

# Rust
cargo cyclonedx > sbom.json
```

**Outcome:** SBOM generated → INFO. Compare with previous SBOM to detect supply chain changes.

### Step 11: Aggregate & Report

Combine all findings:

```
╔══════════════════════════════════════════╗
║          CODING AUDIT REPORT             ║
╠══════════════════════════════════════════╣
║ Language: Python + JavaScript            ║
║ Files changed: 12                        ║
║                                          ║
║ 🔴 FAIL: 2                               ║
║   - Hardcoded API key in src/auth.py:42  ║
║   - CVE-2025-XXXX in lodash@4.17.20     ║
║                                          ║
║ 🟡 WARN: 3                               ║
║   - New dependency: express@5.0.0       ║
║   - 3 unused imports                    ║
║   - Lockfile integrity hash changed      ║
║                                          ║
║ 🔵 INFO: 1                               ║
║   - SBOM generated: sbom.json           ║
║                                          ║
║ Verdict: ❌ FAIL — fix 2 issues          ║
╚══════════════════════════════════════════╝
```

## Ignore Convention

To override a finding, add a comment on the relevant line:

```python
# audit-ignore: API key is a public read-only key for the GitHub API
# nosec: B105 — this is a public API key, not a secret
PUBLIC_GITHUB_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Rules:
- Must include justification
- Only works for WARN-level findings
- FAIL-level findings cannot be ignored (must fix)
- `# nosec` for Bandit, `# audit-ignore` for everything else

## Integration with Other Skills

- **requesting-code-review:** This skill IS the audit step in the pre-commit pipeline
- **security-framework:** Provides the NIST/CIS/OWASP reference tables for deeper review
- **test-driven-development:** Audit verifies TDD discipline was followed
- **context7-integration:** Fetch security advisories for detected library versions

## Pitfalls

- **OSV.dev rate limits:** Cache results locally. Don't query the same package twice in one run.
- **False positives in PII scan:** Test data with fake emails triggers PII detection. Use `# audit-ignore: test data`.
- **Lockfile noise:** Minor version bumps change many hashes. Only flag NEW packages and registry URL changes.
- **Postinstall false positives:** Some legitimate packages use postinstall (e.g., `husky` for git hooks). Maintain a whitelist.
- **Time overhead:** Full pipeline takes 2-5 min. Run lint + security first (fast), then CVE + supply chain in parallel.

## Reference Files

Load these when needed:
- `references/language-configs.md` — exact tool commands per language
- `references/cve-check.sh` — OSV.dev query script
- `references/typosquat-check.sh` — Levenshtein-based typosquat detection
- `references/postinstall-scan.sh` — Postinstall script behavioral scanner
- `references/lockfile-diff.sh` — Lockfile change analyzer
