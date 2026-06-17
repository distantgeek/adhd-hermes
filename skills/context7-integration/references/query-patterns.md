# Context7 Query Patterns

Pre-built query templates for common documentation needs.

## Python Libraries

### FastAPI
```
"Show me FastAPI@{version} security best practices for:
- Authentication (OAuth2, JWT)
- CORS configuration
- Request validation
- Rate limiting
- SQL injection prevention"
```

### Django
```
"Show me Django@{version} security checklist:
- SECURE_* settings
- CSRF protection
- XSS prevention
- SQL injection prevention
- Clickjacking protection
- SSL/TLS configuration"
```

### SQLAlchemy
```
"Show me SQLAlchemy@{version} security best practices:
- Parameterized queries
- Connection pooling security
- Transaction management
- Raw SQL safety"
```

### Requests/httpx
```
"Show me {library}@{version} security best practices:
- SSL verification
- Timeout configuration
- Redirect handling
- Header injection prevention"
```

## JavaScript/TypeScript Libraries

### Express
```
"Show me Express@{version} security best practices:
- Helmet configuration
- CORS setup
- Rate limiting
- Input validation
- Session security
- Error handling (no stack traces in production)"
```

### React
```
"Show me React@{version} security best practices:
- XSS prevention
- dangerouslySetInnerHTML usage
- CSRF token handling
- Dependency injection security
- State management security"
```

### Next.js
```
"Show me Next.js@{version} security best practices:
- API route security
- Middleware authentication
- Environment variable handling
- Image optimization security
- SSRF prevention in API routes"
```

## Rust Libraries

### Tokio
```
"Show me Tokio@{version} security considerations:
- Async runtime configuration
- Task spawning safety
- Resource limits
- TLS configuration"
```

### Axum/Actix
```
"Show me {library}@{version} security best practices:
- Middleware configuration
- Authentication patterns
- Request validation
- CORS handling
- Rate limiting"
```

### SQLx
```
"Show me SQLx@{version} security best practices:
- Parameterized queries
- Connection pool security
- Migration safety
- Type-safe queries"
```

## Bash/Shell

### General
```
"Show me bash security best practices:
- set -euo pipefail
- Variable quoting
- Path validation
- Temporary file handling
- Privilege dropping
- Input sanitization"
```

## Security Advisories

### CVE Lookup
```
"Show me all CVEs for {library}@{version}.
For each CVE provide:
- CVE ID
- Severity (CVSS score)
- Affected versions
- Description
- Remediation
- Whether an exploit exists"
```

### Supply Chain
```
"Show me supply chain security information for {library}:
- Maintainer identity and reputation
- Release process and signing
- Known supply chain incidents
- Dependency tree health
- Maintenance status"
```
