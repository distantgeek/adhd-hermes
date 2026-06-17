# Security Scan Patterns (Grep-Based Fallback)

Use these when language-specific tools (bandit, cargo-audit, semgrep) are not installed.

## Shell Injection

```bash
# Python: os.system / subprocess.shell=True
grep -rn "os\.system\|subprocess.*shell=True" --include="*.py" src/

# Unquoted variables in shell scripts
grep -rn '\$[A-Za-z_]' --include="*.sh" scripts/ | grep -v '"'

# eval in any language
grep -rn "\beval\s*(" --include="*.py" --include="*.js" --include="*.sh" src/
```

## SQL Injection

```bash
# Python: f-string / .format() in SQL
grep -rn "execute(f\"\|execute(\"%\|\.format(.*SELECT\|\.format(.*INSERT\|\.format(.*UPDATE\|\.format(.*DELETE" --include="*.py" src/

# Python: string concatenation in SQL
grep -rn "execute.*\+.*SELECT\|execute.*\+.*INSERT\|execute.*\+.*WHERE" --include="*.py" src/

# JS: template literals in SQL
grep -rn "query\`\|sql\`\|SELECT.*\$\{" --include="*.js" --include="*.ts" src/
```

## Hardcoded Secrets

```bash
# Common secret names assigned to string literals
grep -rn "api_key\|api_secret\|access_token\|auth_token\|private_key\|secret_key\|client_secret" --include="*.py" --include="*.js" --include="*.ts" --include="*.rs" src/ | grep -v "os\.environ\|process\.env\|env\[\|getenv\|config\.\|settings\."

# High-entropy strings (32+ chars)
grep -rn "[A-Za-z0-9+/]\{32,\}" --include="*.py" --include="*.js" src/ | grep -v "test\|example\|placeholder\|TODO"

# .env files committed
git diff --cached --name-only | grep -E "^\.env$|\.env\.local|\.env\.production"
```

## PII Detection

```bash
# Email addresses in code
grep -rn "[a-zA-Z0-9._%+-]\+@[a-zA-Z0-9.-]\+\.[a-zA-Z]\{2,\}" --include="*.py" --include="*.js" src/

# SSN patterns (US)
grep -rn "[0-9]\{3\}-[0-9]\{2\}-[0-9]\{4\}" --include="*.py" src/

# Phone numbers (US)
grep -rn "[0-9]\{3\}-[0-9]\{3\}-[0-9]\{4\}" --include="*.py" src/
```

## Unsafe Deserialization

```bash
# Python pickle
grep -rn "pickle\.load\|pickle\.loads\|cPickle" --include="*.py" src/

# Python yaml without SafeLoader
grep -rn "yaml\.load\s*(" --include="*.py" src/ | grep -v "SafeLoader\|safe_load"

# JS: Function constructor / deserialization
grep -rn "new Function\|deserialize\|unserialize" --include="*.js" --include="*.ts" src/
```

## XSS (JavaScript)

```bash
# innerHTML assignment
grep -rn "innerHTML\s*=" --include="*.js" --include="*.ts" src/

# dangerouslySetInnerHTML (React)
grep -rn "dangerouslySetInnerHTML" --include="*.jsx" --include="*.tsx" src/

# document.write
grep -rn "document\.write" --include="*.js" src/
```

## Path Traversal

```bash
# User input in file paths without validation
grep -rn "open(.*\+.*request\|open(.*\+.*param\|readFile(.*\+.*req" --include="*.py" --include="*.js" src/
```
