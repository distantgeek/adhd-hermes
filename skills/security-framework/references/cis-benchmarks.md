# CIS Benchmarks — Runtime Security Configuration

CIS (Center for Internet Security) benchmarks for secure configuration of runtimes.

## CIS Benchmark: Python Runtime

### 1. Install from Trusted Sources
- Use official PyPI or verified internal mirror
- Verify package signatures when available
- Pin all dependencies with exact versions

### 2. Virtual Environment Isolation
```bash
# Always use virtual environments
python -m venv .venv
source .venv/bin/activate

# Never install globally
# BAD: pip install package
# GOOD: pip install --user package (or better, use venv)
```

### 3. Dependency Management
```bash
# Use lock files
pip freeze > requirements.txt
pip install -r requirements.txt

# Or use modern tools
pip install pip-tools
pip-compile requirements.in  # Generates pinned requirements.txt
```

### 4. Secure Defaults
```python
# Disable debug mode in production
DEBUG = False

# Use secure cookie settings
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SAMESITE = 'Lax'

# Set secure headers
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = 'DENY'
```

### 5. Input Validation
```python
# Validate all external input
from pydantic import BaseModel, validator

class UserInput(BaseModel):
    name: str
    email: str

    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('name must not be empty')
        return v.strip()
```

## CIS Benchmark: Node.js Runtime

### 1. Install from Trusted Sources
```bash
# Use lockfile
npm ci  # Uses package-lock.json exactly

# Verify integrity
npm audit
```

### 2. Minimize Attack Surface
```bash
# Remove devDependencies in production
npm ci --omit=dev

# Use production node_env
NODE_ENV=production
```

### 3. Secure Defaults
```javascript
// Helmet for security headers
const helmet = require('helmet');
app.use(helmet());

// Rate limiting
const rateLimit = require('express-rate-limit');
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
}));

// CORS — restrict origins
const cors = require('cors');
app.use(cors({ origin: ['https://example.com'] }));
```

### 4. Process Management
```bash
# Run as non-root user
# In Dockerfile:
RUN adduser --disabled-password appuser
USER appuser

# Or in docker-compose:
user: "1001:1001"
```

### 5. Environment Variables
```javascript
// Never commit .env files
// Use secret managers in production
const secret = process.env.SECRET_KEY];  // From vault, not code

// Validate required env vars at startup
const required = ['DATABASE_URL', 'JWT_SECRET', 'API_KEY'];
for (const key of required) {
  if (!process.env[key]) {
    throw new Error(`Missing required environment variable: ${key}`);
  }
}
```

## CIS Benchmark: Nginx/Web Server

### 1. Hide Version
```nginx
server_tokens off;
```

### 2. Security Headers
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'" always;
```

### 3. TLS Configuration
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_prefer_server_ciphers off;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:10m;
```

## CIS Benchmark: Docker Container

### 1. Minimal Base Image
```dockerfile
# Use distroless or alpine
FROM python:3.11-slim AS runtime
# Or even better:
FROM gcr.io/distroless/python3.11
```

### 2. Non-Root User
```dockerfile
RUN adduser --disabled-password --gecos '' appuser
USER appuser
```

### 3. No Secrets in Image
```dockerfile
# BAD:
# COPY .env /app/.env

# GOOD:
# Use runtime secrets:
# docker run -e DB_PASSWORD_FILE=/run/secrets/db_password \
#   --mount type=secret,id=db_password ...
```

### 4. Read-Only Filesystem
```dockerfile
# In docker-compose:
read_only: true
tmpfs:
  - /tmp
  - /var/tmp
```

### 5. Resource Limits
```yaml
# docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
```

## CIS Benchmark: Database (PostgreSQL)

### 1. Connection Security
```sql
-- Require SSL
ALTER SYSTEM SET ssl = on;
-- In pg_hba.conf:
-- hostssl all all 0.0.0.0/0 scram-sha-256
```

### 2. Least Privilege
```sql
-- Create application-specific user with minimal permissions
CREATE USER app_user WITH PASSWORD 'strong_password';
GRANT CONNECT ON DATABASE app_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- No DROP, no ALTER, no CREATE
```

### 3. Audit Logging
```sql
-- Enable query logging for sensitive tables
ALTER SYSTEM SET log_statement = 'mod';
-- Or use pgaudit extension
CREATE EXTENSION pgaudit;
```

## Mapping to Audit Severity

| CIS Control | Audit Severity |
|-------------|----------------|
| Install from trusted sources | CRITICAL |
| Non-root execution | CRITICAL |
| Network encryption (TLS) | CRITICAL |
| Authentication required | CRITICAL |
| Debug mode disabled | HIGH |
| Security headers | HIGH |
| Rate limiting | HIGH |
| Input validation | HIGH |
| Dependency pinning | MEDIUM |
| Version hiding | LOW |
| Resource limits | LOW |
