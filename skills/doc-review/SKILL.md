---
name: doc-review
description: "Enforce documentation standards — docstrings, API docs, README completeness, CHANGELOG. Part of the coding audit pipeline."
version: 1.0.0
author: Hermes Agent (OWL)
license: MIT
metadata:
  hermes:
    tags: [documentation, docstrings, api-docs, readme, changelog, quality]
    related_skills: [coding-audit, test-driven-development]
---

# Documentation Review

Enforces documentation standards as part of the coding audit pipeline. Checks docstring completeness, API documentation, README structure, and CHANGELOG currency.

**Core principle:** If it's not documented, it doesn't exist. Undocumented code is unmaintainable code.

## When to Use

- As part of `coding-audit` Step 11 (documentation dimension)
- Before every commit that adds/modifies public APIs
- When user says "document this", "add docs", "write docs"
- Weekly cron: full documentation audit

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| 🔴 FAIL | Missing critical documentation | Must fix before merge |
| 🟡 WARN | Incomplete or inconsistent docs | Requires override |
| 🔵 INFO | Style or enhancement suggestion | No action required |

## The Pipeline

### Step 1: Docstring Coverage

Scan all public functions/methods/classes for docstrings.

```bash
# Python
pip install interrogate
interrogate src/ -v --fail-under=100

# Check specific patterns
grep -rn "def " src/ --include="*.py" | while read line; do
  file=$(echo "$line" | cut -d: -f1)
  lineno=$(echo "$line" | cut -d: -f2)
  # Check if next non-empty line is a docstring
  sed -n "${lineno},${lineno}p;${lineno}a" "$file" | head -5 | grep -q '"""' || echo "MISSING: $file:$lineno"
done

# Rust
# Check for /// doc comments on public items
grep -rn "pub fn\|pub struct\|pub enum\|pub trait" src/ | while read line; do
  file=$(echo "$line" | cut -d: -f1)
  lineno=$(echo "$line" | cut -d: -f2)
  prevline=$((lineno - 1))
  sed -n "${prevline}p" "$file" | grep -q "///" || echo "MISSING: $file:$lineno"
done

# JavaScript/TypeScript
# Check for JSDoc on exported functions
grep -rn "export" src/ --include="*.ts" --include="*.js" | while read line; do
  file=$(echo "$line" | cut -d: -f1)
  lineno=$(echo "$line" | cut -d: -f2)
  # Look for /** ... */ above the export
  start=$((lineno - 5))
  sed -n "${start},${lineno}p" "$file" | grep -q "/\*\*" || echo "MISSING: $file:$lineno"
done
```

**Outcome:** Public function without docstring → FAIL. Private function without docstring → INFO.

### Step 2: Docstring Format Validation

Verify docstrings match the project's declared style.

```bash
# Python — Google style
# Expected format:
def function_name(param1: str, param2: int) -> bool:
    """Short description.

    Args:
        param1: Description.
        param2: Description.

    Returns:
        Description.

    Raises:
        ValueError: When param2 is negative.
    """
    pass

# Check with pydocstyle
pip install pydocstyle
pydocstyle src/ --convention=google

# Python — Sphinx style
pydocstyle src/ --convention=numpy
```

**Supported styles per language:**

| Language | Styles | Tool |
|----------|--------|------|
| Python | Google, NumPy, Sphinx | pydocstyle |
| Rust | rustdoc (///) | Built-in |
| JavaScript | JSDoc | eslint-plugin-jsdoc |
| Go | godoc | Built-in |

**Outcome:** Wrong docstring format → WARN. Missing Args/Returns sections → WARN.

### Step 3: README Completeness

Verify README exists and has required sections.

```bash
# Check README exists
ls README.md || ls README.rst || ls README || echo "NO README"

# Check required sections
for section in "Installation" "Usage" "Contributing" "License"; do
  grep -q "^## $section\|^# $section\|$section" README.md || echo "MISSING SECTION: $section"
done
```

**Required sections:**

| Section | Required For | Severity if Missing |
|---------|-------------|-------------------|
| Description/Overview | All projects | FAIL |
| Installation | All projects | FAIL |
| Usage | Libraries, tools | FAIL |
| API Reference | Libraries | WARN |
| Configuration | Apps with config | WARN |
| Contributing | Open source | WARN |
| License | Open source | FAIL |
| Security Policy | Production services | WARN |
| Changelog | Versioned projects | WARN |

**Outcome:** Missing required section → FAIL. Missing recommended section → WARN.

### Step 4: CHANGELOG Currency

Check for CHANGELOG entry matching the current version.

```bash
# Check CHANGELOG exists
ls CHANGELOG.md || ls CHANGELOG || ls CHANGES.md || echo "NO CHANGELOG"

# Check for current version entry
VERSION=$(python3 -c "import tomllib; print(tomllib.load(open('pyproject.toml','rb'))['project']['version'])" 2>/dev/null || \
         grep version Cargo.toml | head -1 | cut -d'"' -f2 || \
         grep '"version"' package.json | head -1 | cut -d'"' -f2)

grep -q "## \[$VERSION\]\|^## $VERSION\|^# $VERSION" CHANGELOG.md || echo "NO CHANGELOG ENTRY FOR $VERSION"
```

**Format (Keep a Changelog):**
```markdown
## [1.2.3] - 2026-06-16

### Added
- New feature X

### Fixed
- Bug fix Y

### Security
- Patched CVE-2025-XXXX in dependency Z
```

**Outcome:** No CHANGELOG entry for current version → WARN. No CHANGELOG at all → WARN.

### Step 5: TODO/FIXME/HACK Audit

Scan for unresolved development markers.

```bash
# Find all TODO/FIXME/HACK/XXX markers
grep -rn "TODO\|FIXME\|HACK\|XXX\|TEMP\|TEMPORARY" src/ --include="*.py" --include="*.rs" --include="*.js" --include="*.ts"

# Flag those without issue references
grep -rn "TODO\|FIXME\|HACK" src/ | grep -v "TODO(" | grep -v "FIXME(" | grep -v "HACK(" | while read line; do
  echo "NO ISSUE REF: $line"
done
```

**Convention:** All TODO/FIXME must reference an issue: `TODO(#123): fix this`

**Outcome:** TODO/FIXME without issue reference → WARN. HACK/TEMP without issue reference → WARN.

### Step 6: API Documentation (for Libraries)

Check that public APIs have documentation.

```bash
# Python — check __all__ matches documented functions
python3 -c "
import ast, sys
with open('src/__init__.py') as f:
    tree = ast.parse(f.read())
for node in ast.walk(tree):
    if isinstance(node, ast.Assign):
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == '__all__':
                print('__all__ defined:', [elt.s for elt in node.value.elts if isinstance(elt, ast.Constant)])
"

# Rust — check that pub items have /// docs
# (covered in Step 1)

# JavaScript — check for TypeScript types on exports
grep -rn "export" src/ --include="*.ts" | grep -v ": " | while read line; do
  echo "MISSING TYPE: $line"
done
```

**Outcome:** Public API without documentation → FAIL.

### Step 7: Aggregate & Report

```
╔══════════════════════════════════════════╗
║        DOCUMENTATION REVIEW REPORT       ║
╠══════════════════════════════════════════╣
║ Language: Python                         ║
║ Public APIs: 45                          ║
║                                          ║
║ Docstring Coverage: 91% (41/45)          ║
║ README: ✅ Complete                      ║
║ CHANGELOG: ✅ Entry for v1.2.3           ║
║                                          ║
║ 🔴 FAIL: 1                               ║
║   - src/api/auth.py:login() — no docstring║
║                                          ║
║ 🟡 WARN: 2                               ║
║   - 3 TODO markers without issue refs    ║
║   - Missing "Security Policy" section    ║
║                                          ║
║ Verdict: ❌ FAIL — fix 1 docstring       ║
╚══════════════════════════════════════════╝
```

## Ignore Convention

```python
# doc-ignore: internal helper, not part of public API
def _internal_helper():
    pass
```

Rules:
- Only works for WARN-level findings
- FAIL-level findings (missing docstring on public API) cannot be ignored
- Must include justification

## Integration

- **coding-audit:** This skill is Step 11 of the audit pipeline
- **test-driven-development:** TDD tests serve as usage documentation
- **requesting-code-review:** Reviewer checks doc completeness
- **security-framework:** Security-sensitive functions require extra documentation (security considerations, threat model notes)

## Pitfalls

- **Auto-generated docs:** Tools like Sphinx `autodoc` can mask missing docstrings. Check source, not generated output.
- **Test docstrings:** Test function docstrings count as documentation but shouldn't replace API docstrings.
- **README drift:** README gets outdated fast. Check it against actual code, not just for existence.
- **Changelog automation:** Tools like `semantic-release` can auto-generate changelogs. That's fine, but verify accuracy.
