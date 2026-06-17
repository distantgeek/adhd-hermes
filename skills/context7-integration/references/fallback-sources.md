# Fallback Documentation Sources

When Context7 is unavailable, use these alternative sources.

## Official Documentation

| Library | URL Pattern |
|---------|------------|
| Python stdlib | https://docs.python.org/3/library/ |
| FastAPI | https://fastapi.tiangolo.com/ |
| Django | https://docs.djangoproject.com/ |
| Flask | https://flask.palletsprojects.com/ |
| Express | https://expressjs.com/en/api.html |
| React | https://react.dev/reference/ |
| Rust stdlib | https://doc.rust-lang.org/std/ |
| Tokio | https://tokio.rs/tokio/ |
| MDN (JS) | https://developer.mozilla.org/ |

## Security Advisories

| Source | URL | Coverage |
|--------|-----|----------|
| OSV.dev | https://api.osv.dev/v1/query | All ecosystems |
| NVD | https://nvd.nist.gov/ | All ecosystems |
| GitHub Advisory | https://github.com/advisories | npm, pip, cargo, go |
| Snyk | https://snyk.io/vuln/ | npm, pip, cargo, go |
| pip-audit | https://pypi.org/project/pip-audit/ | Python only |
| cargo-audit | https://rustsec.org/ | Rust only |

## Local Fallback

If all external sources fail, use the `references/` directory in `security-framework`:
- `owasp-top-10-mapping.md` — Common vulnerability patterns
- `cwe-top-25-mapping.md` — Language-specific weakness patterns
- `supply-chain-incidents.md` — Real-world attack examples
- `cis-benchmarks.md` — Secure configuration guides

## Fallback Decision Tree

```
Context7 available?
├── YES → Query Context7 with version-pinned request
│   └── Result useful? → Use it
│   └── Result empty? → Fall through
└── NO → Try web fetch of official docs
    └── Available? → Use it
    └── Not available? → Use security-framework references
        └── Still insufficient? → Log as INFO, don't block
```

**Rule:** Never block a commit or review solely because documentation context is unavailable. Use what you have, log what you don't.
