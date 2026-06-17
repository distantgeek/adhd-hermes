# Python Audit Reference

## Tool Chain

| Tool | Install | Command |
|------|---------|---------|
| ruff | `pip install ruff` | `ruff check --select ALL src/` |
| mypy | `pip install mypy` | `mypy --strict src/` |
| bandit | `pip install bandit` | `bandit -r src/ -ll` |
| semgrep | `pip install semgrep` | `semgrep --config=auto --error src/` |
| pip-audit | `pip install pip-audit` | `pip-audit --strict` |
| vulture | `pip install vulture` | `vulture src/ --min-confidence 80` |
| interrogate | `pip install interrogate` | `interrogate src/ --fail-under 100` |

## ruff Configuration (pyproject.toml)

```toml
[tool.ruff]
target-version = "py311"
line-length = 100

[tool.ruff.lint]
select = [
    "E", "W", "F", "I", "N", "UP", "B", "C4", "SIM",
    "S", "A", "T20", "RET", "RUF",
]
ignore = ["S101"]

[tool.ruff.lint.per-file-ignores]
"tests/*" = ["S101", "S106"]
```

## Common Python Security Pitfalls

```python
# BAD: SQL injection
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
# GOOD: parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

# BAD: shell injection
os.system(f"ls {user_input}")
# GOOD: safe subprocess
subprocess.run(["ls", user_input], check=True)

# BAD: unsafe deserialization
data = pickle.loads(untrusted_input)
# GOOD: use json
data = json.loads(untrusted_input)

# BAD: hardcoded secret
API_KEY = "sk-abc123..."
# GOOD: environment variable
API_KEY = os.environ["API_KEY"]

# BAD: yaml unsafe
config = yaml.load(raw)
# GOOD: safe loader
config = yaml.safe_load(raw)
```

## Testing Requirements

- 100% code coverage gate: `pytest --cov --cov-fail-under=100`
- All public functions must have docstrings (Google style)
- All functions must have type hints
- No `# type: ignore` without explanation comment
