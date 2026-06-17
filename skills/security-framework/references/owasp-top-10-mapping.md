# OWASP Top 10 (2021 + 2025 Update) — Language-Specific Detection Patterns

## A01:2021 — Broken Access Control

### Python (Flask/Django/FastAPI)
```python
# FAIL: Direct object reference without ownership check
@app.route("/api/users/<int:user_id>/documents")
def get_documents(user_id):
    docs = Document.query.filter_by(user_id=user_id).all()  # No auth check!
    return jsonify(docs)

# PASS: Ownership verified
@app.route("/api/users/<int:user_id>/documents")
@login_required
def get_documents(user_id):
    if current_user.id != user_id and not current_user.is_admin:
        abort(403)
    docs = Document.query.filter_by(user_id=user_id).all()
    return jsonify(docs)
```

### JavaScript/TypeScript (Express)
```javascript
// FAIL: No ownership verification
app.get('/api/users/:userId/documents', async (req, res) => {
  const docs = await Document.findAll({ where: { userId: req.params.userId } });
  res.json(docs);
});

// PASS: Ownership verified
app.get('/api/users/:userId/documents', auth, async (req, res) => {
  if (req.user.id !== parseInt(req.params.userId) && !req.user.isAdmin) {
    return res.status(403).json({ error: 'Forbidden' });
  }
  const docs = await Document.findAll({ where: { userId: req.params.userId } });
  res.json(docs);
});
```

### Rust (Actix/Axum)
```rust
// FAIL: No ownership check
async fn get_documents(path: web::Path<i32>, data: web::Data<AppState>) -> impl Responder {
    let user_id = path.into_inner();
    let docs = Document::find_by_user_id(&data.db, user_id).await;
    web::Json(docs)
}

// PASS: Ownership verified
async fn get_documents(
    path: web::Path<i32>,
    auth: AuthExtractor,
    data: web::Data<AppState>,
) -> impl Responder {
    let user_id = path.into_inner();
    if auth.user_id != user_id && !auth.is_admin {
        return HttpResponse::Forbidden().finish();
    }
    let docs = Document::find_by_user_id(&data.db, user_id).await;
    HttpResponse::Ok().json(docs)
}
```

## A02:2021 — Cryptographic Failures

### All Languages
```python
# FAIL: Weak hashing
import hashlib
hashlib.md5(password.encode()).hexdigest()

# FAIL: Hardcoded encryption key
KEY = b"my-secret-key-1234567890123456"

# FAIL: No TLS verification
import requests
requests.get("https://api.example.com", verify=False)

# PASS: Strong hashing + env-based key
import bcrypt
import os
key = os.environ["ENCRYPTION_KEY"].encode()
bcrypt.hashpw(password.encode(), bcrypt.gensalt())
```

## A03:2021 — Injection

### Python
```python
# FAIL: SQL injection
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")

# FAIL: Command injection
os.system(f"ping {hostname}")

# FAIL: Path traversal
with open(f"/uploads/{filename}") as f:
    content = f.read()

# PASS: Parameterized queries + input validation
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
subprocess.run(["ping", "-c", "1", hostname], check=True)
safe_path = os.path.realpath(os.path.join("/uploads", filename))
if not safe_path.startswith("/uploads/"):
    raise ValueError("Invalid path")
```

### JavaScript
```javascript
// FAIL: NoSQL injection
const user = await User.findOne({ username: req.body.username });

// FAIL: Command injection
const { exec } = require('child_process');
exec(`ping ${req.query.host}`);

// PASS: Input sanitization
const user = await User.findOne({ username: String(req.body.username) });
const { execFile } = require('child_process');
execFile('ping', ['-c', '1', req.query.host]);
```

## A04:2021 — Insecure Design

### Patterns to Flag
- No rate limiting on auth endpoints
- No input validation on API parameters
- Missing CSRF protection on state-changing endpoints
- No request size limits (DoS vector)
- Business logic bypass (e.g., negative prices)

## A05:2021 — Security Misconfiguration

### All Languages
```python
# FAIL: Debug mode in production
app.config["DEBUG"] = True

# FAIL: Default credentials
ADMIN_PASSWORD = "admin123"

# FAIL: Verbose error messages to users
@app.errorhandler(500)
def handle_500(e):
    return jsonify({"error": str(e), "traceback": traceback.format_exc()}), 500

# FAIL: CORS wildcard
CORS(app, origins="*")

# PASS: Secure defaults
app.config["DEBUG"] = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
CORS(app, origins=os.environ.get("ALLOWED_ORIGINS", "").split(","))
```

## A06:2021 — Vulnerable and Outdated Components

### Detection
- Run `npm audit`, `pip-audit`, `cargo audit` on every build
- Check OSV.dev for all transitive dependencies
- Flag dependencies with known CVEs
- Flag unmaintained dependencies (no updates in 12+ months)

## A07:2021 — Identification and Authentication Failures

### Patterns to Flag
```python
# FAIL: Plaintext password storage
user.password = request.json["password"]

# FAIL: Weak session management
session["user_id"] = user.id  # No expiration, no rotation

# FAIL: Username enumeration
if user_exists:
    return "User not found"
else:
    return "Wrong password"  # Different messages reveal user existence

# PASS: Constant-time comparison + generic errors
if not user or not bcrypt.checkpw(password, user.password_hash):
    return "Invalid credentials"  # Same message either way
```

## A08:2021 — Software and Data Integrity Failures

### Supply Chain
```bash
# FAIL: Download and execute
curl -s https://install.example.com | sh

# FAIL: No integrity verification
npm install some-package  # No lockfile, no hash check

# PASS: Verify checksums
curl -s https://example.com/file.tar.gz -o file.tar.gz
echo "expected_sha256  file.tar.gz" | sha256sum -c
tar xzf file.tar.gz
```

### CI/CD
```yaml
# FAIL: No signature verification
- run: npm install && npm run build

# PASS: Signed dependencies + reproducible builds
- run: npm ci --ignore-scripts  # Uses lockfile exactly
- run: npm audit --audit-level=high
```

## A09:2021 — Security Logging and Monitoring Failures

### All Languages
```python
# FAIL: No logging of security events
def login(username, password):
    user = authenticate(username, password)
    if user:
        return create_session(user)
    return None  # No log of failed attempt

# PASS: Log all security events
def login(username, password):
    user = authenticate(username, password)
    if user:
        logger.info("login_success", extra={"username": username, "ip": request.remote_addr})
        return create_session(user)
    logger.warning("login_failure", extra={"username": username, "ip": request.remote_addr})
    return None

# FAIL: Logging sensitive data
logger.info(f"User authenticated with password: {password}")

# PASS: Never log secrets
logger.info("User authenticated successfully")
```

## A10:2021 — Server-Side Request Forgery (SSRF)

### All Languages
```python
# FAIL: No URL validation
response = requests.get(user_provided_url)

# PASS: Validate and restrict URLs
from urllib.parse import urlparse
ALLOWED_SCHEMES = {"https"}
ALLOWED_HOSTS = {"api.example.com", "cdn.example.com"}

def safe_fetch(url):
    parsed = urlparse(url)
    if parsed.scheme not in ALLOWED_SCHEMES:
        raise ValueError("Invalid scheme")
    if parsed.hostname not in ALLOWED_HOSTS:
        raise ValueError("Host not allowed")
    # Block private IPs
    import ipaddress
    try:
        ip = ipaddress.ip_address(parsed.hostname)
        if ip.is_private or ip.is_loopback:
            raise ValueError("Private IP blocked")
    except ValueError:
        pass  # Not an IP, hostname is fine
    return requests.get(url, timeout=5)
```

## OWASP 2025 Additions

### A11:2025 — Unrestricted AI/LLM API Access
- Rate limiting on LLM API calls
- Input/output filtering for LLM prompts
- No PII in LLM prompts
- Cost controls on API usage

### A12:2025 — Software Composition Analysis
- SBOM generation required
- Automated dependency scanning
- License compliance checking
- Dependency update SLA enforced
