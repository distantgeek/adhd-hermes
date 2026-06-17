# Language Configuration Reference

Exact tool commands, flags, and thresholds per language.

## Python

### Lint
```bash
ruff check --select ALL src/ tests/
```
Config: `pyproject.toml` or `setup.cfg`
```toml
[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["ALL"]
ignore = ["D203", "D213"]  # docstring style conflicts
```

### Type Check
```bash
mypy --strict src/
```

### Security
```bash
bandit -r src/ -ll -ii
npx semgrep --config=auto src/
```

### Privacy / PII
```bash
# Custom patterns — run as part of coding-audit
grep -rn "email\|phone\|ssn\|credit_card\|api_key\|password\|secret" src/ \
  --include="*.py" | grep -v "test_" | grep -v "# audit-ignore"
```

### Test
```bash
pytest tests/ -v --cov=src --cov-fail-under=100 --tb=short
```

### Dead Code
```bash
vulture src/ --min-confidence 80
```

### Dependency Audit
```bash
pip-audit --strict
```

### SBOM
```bash
pip install cyclonedx-bom
cyclonedx-py requirements.txt > sbom.json
```

### Docstring Coverage
```bash
pip install interrogate
interrogate src/ -v --fail-under=100
```

---

## Rust

### Format
```bash
cargo fmt --check
```

### Lint
```bash
cargo clippy -- -D warnings
```

### Security
```bash
cargo audit
cargo deny check
```

### Test
```bash
cargo test
cargo nextest run  # if cargo-nextest installed
```

### Dead Code
```bash
cargo udeps  # requires cargo-udeps
```

### SBOM
```bash
cargo cyclonedx  # requires cargo-cyclonedx
```

### Documentation
```bash
cargo doc --no-deps
# Check for missing doc comments:
grep -rn "//!" src/ | wc -l  # doc comments count
```

---

## Bash / Shell

### Lint
```bash
shellcheck --severity=warning *.sh
```

### Security Rules (custom)
```bash
# No eval
grep -rn "eval " --include="*.sh"
# No unquoted variables
grep -rn '\$[A-Z_]' --include="*.sh" | grep -v '"'
# No curl | sh
grep -rn "curl.*|.*sh\|wget.*|.*sh" --include="*.sh"
```

### Test
```bash
bats test/  # requires bats-core
```

### Portability
```bash
shcheck script.sh  # if targeting POSIX sh
```

---

## JavaScript / TypeScript

### Lint
```bash
npx eslint --max-warnings=0 src/
npx prettier --check "src/**/*.{js,ts,jsx,tsx}"
```

### Type Check
```bash
npx tsc --noEmit --strict
```

### Security
```bash
npx semgrep --config=auto src/
npm audit --audit-level=high
```

### Privacy
```bash
npx eslint --plugin=no-leak src/
```

### Test
```bash
npx vitest --coverage
# or
npx jest --coverage
```

### Dead Code
```bash
npx ts-prune  # TypeScript
npx knip      # Both JS and TS
```

### Dependency Audit
```bash
npm audit --audit-level=high
npx license-checker --production --failOn "GPL-3.0;AGPL-3.0"
```

### SBOM
```bash
npx @cyclonedx/cyclonedx-npm > sbom.json
```

---

## Go

### Format
```bash
gofmt -l .
```

### Lint
```bash
golangci-lint run ./...
```

### Security
```bash
gosec ./...
```

### Test
```bash
go test ./... -cover
```

### Dependency Audit
```bash
govulncheck ./...
```

---

## Severity Mapping

| Tool Output | Audit Severity |
|-------------|---------------|
| ruff error (new) | FAIL |
| ruff warning | WARN |
| bandit HIGH | FAIL |
| bandit MEDIUM | WARN |
| mypy error | FAIL |
| shellcheck error | FAIL |
| shellcheck warning | WARN |
| eslint error | FAIL |
| eslint warning | WARN |
| CVE CRITICAL/HIGH | FAIL |
| CVE MEDIUM | WARN |
| CVE LOW | INFO |
| Hardcoded secret | FAIL |
| PII in code | FAIL |
| New package (lockfile) | WARN |
| Integrity hash change | FAIL |
| Registry URL change | FAIL |
| Dead code | WARN |
| Missing docstring | WARN |
| Missing test | FAIL |
