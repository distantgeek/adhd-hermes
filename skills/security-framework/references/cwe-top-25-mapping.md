# CWE Top 25 (2024) — Language-Specific Detection Patterns

## CWE-787: Out-of-bounds Write

### Rust
```rust
// FAIL: No bounds check
let mut buf = [0u8; 10];
buf[offset] = data;  // offset could be > 9

// PASS: Bounds check
if offset < buf.len() {
    buf[offset] = data;
} else {
    return Err("offset out of bounds");
}

// PASS: Use safe API
buf.get_mut(offset).ok_or("offset out of bounds")?;
```

### C
```c
// FAIL: No bounds check
char buf[10];
buf[offset] = 'x';  // Buffer overflow

// PASS: Bounds check
if (offset < sizeof(buf)) {
    buf[offset] = 'x';
}
```

## CWE-79: Cross-site Scripting (XSS)

### JavaScript
```javascript
// FAIL: Raw HTML insertion
element.innerHTML = userInput;

// PASS: Safe text insertion
element.textContent = userInput;

// PASS: If HTML is needed, sanitize first
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

### Python (Jinja2)
```python
# FAIL: Autoescape disabled
env = Environment(autoescape=False)
template = env.from_string(user_template)

# PASS: Autoescape enabled (default)
env = Environment(autoescape=True)

# PASS: Explicit escaping
from markupsafe import escape
safe_output = escape(user_input)
```

## CWE-89: SQL Injection

### Python
```python
# FAIL: String formatting
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
cursor.execute("SELECT * FROM users WHERE id = " + user_id)

# FAIL: .format()
cursor.execute("SELECT * FROM users WHERE id = {}".format(user_id))

# PASS: Parameterized
cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
```

### JavaScript
```javascript
// FAIL: String concatenation
db.query("SELECT * FROM users WHERE id = " + userId);

// PASS: Parameterized
db.query("SELECT * FROM users WHERE id = ?", [userId]);

// PASS: ORM
const user = await User.findByPk(userId);
```

### Rust
```rust
// FAIL: String formatting
let query = format!("SELECT * FROM users WHERE id = {}", user_id);
sqlx::query(&query).fetch_all(&pool).await?;

// PASS: Parameterized
sqlx::query("SELECT * FROM users WHERE id = $1")
    .bind(user_id)
    .fetch_all(&pool)
    .await?;
```

## CWE-20: Improper Input Validation

### All Languages
```python
# FAIL: No validation
def process_order(quantity, price):
    return quantity * price  # quantity could be negative, price could be NaN

# PASS: Validate all inputs
def process_order(quantity: int, price: float) -> float:
    if not isinstance(quantity, int) or quantity <= 0:
        raise ValueError("quantity must be positive integer")
    if not isinstance(price, (int, float)) or price < 0:
        raise ValueError("price must be non-negative")
    if quantity > 10000:
        raise ValueError("quantity exceeds maximum")
    return quantity * price
```

## CWE-125: Out-of-bounds Read

### Python
```python
# FAIL: No bounds check
value = my_list[index]  # index could be out of range

# PASS: Bounds check
if 0 <= index < len(my_list):
    value = my_list[index]

# PASS: Try/except
try:
    value = my_list[index]
except IndexError:
    value = default
```

## CWE-22: Path Traversal

### Python
```python
# FAIL: No path validation
with open(f"/uploads/{filename}") as f:
    content = f.read()

# PASS: Path validation
import os
base = "/uploads"
full_path = os.path.realpath(os.path.join(base, filename))
if not full_path.startswith(os.path.realpath(base) + os.sep):
    raise ValueError("Path traversal detected")
with open(full_path) as f:
    content = f.read()
```

### JavaScript
```javascript
// FAIL: No path validation
const content = fs.readFileSync(`/uploads/${req.query.file}`);

// PASS: Path validation
const path = require('path');
const base = '/uploads';
const fullPath = path.resolve(base, req.query.file);
if (!fullPath.startsWith(path.resolve(base) + path.sep)) {
    throw new Error('Path traversal detected');
}
const content = fs.readFileSync(fullPath);
```

## CWE-416: Use After Free

### C/C++
```c
// FAIL: Use after free
char* ptr = malloc(10);
free(ptr);
ptr[0] = 'x';  // UAF

// PASS: Null after free
free(ptr);
ptr = NULL;
```

### Rust (unsafe)
```rust
// FAIL: Use after free in unsafe block
unsafe {
    let ptr = Box::into_raw(Box::new(42));
    drop(Box::from_raw(ptr));
    println!("{}", *ptr);  // UAF
}

// PASS: Don't use unsafe, or ensure lifetime safety
```

## CWE-190: Integer Overflow

### Rust
```rust
// FAIL: Can overflow in release mode
let result = a + b;

// PASS: Checked arithmetic
let result = a.checked_add(b).ok_or("overflow")?;

// PASS: Saturating arithmetic
let result = a.saturating_add(b);
```

### C
```c
// FAIL: Can overflow
int result = a + b;

// PASS: Check before operation
if (a > INT_MAX - b) {
    // handle overflow
}
int result = a + b;
```

## CWE-502: Deserialization of Untrusted Data

### Python
```python
# FAIL: Pickle on untrusted data
import pickle
data = pickle.loads(user_input)

# PASS: Use safe serialization
import json
data = json.loads(user_input)
```

### JavaScript
```javascript
// FAIL: eval on untrusted data
const data = eval(userInput);

// PASS: JSON.parse
const data = JSON.parse(userInput);
```

### Rust
```rust
// FAIL: Deserializing untrusted data without validation
let config: Config = serde_json::from_str(untrusted_input)?;

// PASS: Validate after deserialization
let config: Config = serde_json::from_str(untrusted_input)?;
config.validate()?;
```

## CWE-78: OS Command Injection

### Python
```python
# FAIL: Shell injection
os.system(f"ping {hostname}")
subprocess.run(f"ping {hostname}", shell=True)

# PASS: No shell
subprocess.run(["ping", "-c", "1", hostname], check=True)
```

### Bash
```bash
# FAIL: Unquoted variable in command
ping $hostname  # hostname could contain malicious commands

# PASS: Quoted variable
ping "$hostname"

# PASS: Even better — validate first
if [[ "$hostname" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    ping -c 1 "$hostname"
fi
```

## CWE-918: Server-Side Request Forgery

### Python
```python
# FAIL: No URL validation
response = requests.get(user_url)

# PASS: Validate URL
from urllib.parse import urlparse
import ipaddress

def safe_request(url):
    parsed = urlparse(url)
    if parsed.scheme not in ('https',):
        raise ValueError("Only HTTPS allowed")
    # Block private IPs
    import socket
    ip = socket.gethostbyname(parsed.hostname)
    if ipaddress.ip_address(ip).is_private:
        raise ValueError("Private IP blocked")
    return requests.get(url, timeout=5)
```

## CWE-434: Unrestricted File Upload

### Python
```python
# FAIL: No file type validation
filename = request.files['file'].filename
request.files['file'].save(f"/uploads/{filename}")

# PASS: Validate type + randomize name
import magic
import uuid

file = request.files['file']
mime = magic.from_buffer(file.read(1024), mime=True)
file.seek(0)
ALLOWED_TYPES = {'image/png', 'image/jpeg', 'application/pdf'}
if mime not in ALLOWED_TYPES:
    raise ValueError(f"File type {mime} not allowed")
ext = mimetypes.guess_extension(mime)
safe_name = f"{uuid.uuid4()}{ext}"
file.save(f"/uploads/{safe_name}")
```

## CWE-306: Missing Authentication for Critical Function

### All Languages
```python
# FAIL: Admin endpoint without auth
@app.route("/admin/delete_user/<int:user_id>", methods=["DELETE"])
def delete_user(user_id):
    User.query.filter_by(id=user_id).delete()
    db.session.commit()

# PASS: Auth required
@app.route("/admin/delete_user/<int:user_id>", methods=["DELETE"])
@login_required
@admin_required
def delete_user(user_id):
    User.query.filter_by(id=user_id).delete()
    db.session.commit()
```

## CWE-798: Hard-coded Credentials

### All Languages
```python
# FAIL: Hardcoded credentials
API_KEY = "sk-1234567890abcdef"
DATABASE_URL = "postgres://user:password@host/db"

# PASS: Environment variables
API_KEY = os.environ["API_KEY"]
DATABASE_URL = os.environ["DATABASE_URL"]

# PASS: Secret manager
from aws_secretsmanager import get_secret
API_KEY = get_secret("prod/api-key")
```

## CWE-200: Exposure of Sensitive Information

### All Languages
```python
# FAIL: Sensitive data in logs
logger.info(f"User login: {username}, password: {password}")
logger.debug(f"API response: {response}")  # May contain tokens

# PASS: Sanitized logging
logger.info(f"User login: {username}")
logger.debug(f"API response status: {response.status_code}")

# FAIL: Error messages expose internals
return jsonify({"error": str(exception), "traceback": traceback.format_exc()})

# PASS: Generic error to user, detailed to logs
logger.error(f"Unhandled error: {exception}", exc_info=True)
return jsonify({"error": "Internal server error"}), 500
```

## CWE-276: Incorrect Default Permissions

### Bash
```bash
# FAIL: World-readable secrets
chmod 644 /etc/app/secrets.env

# PASS: Owner-only
chmod 600 /etc/app/secrets.env

# FAIL: World-writable directory
chmod 777 /var/app/uploads/

# PASS: Group-writable only
chmod 775 /var/app/uploads/
chown app:app /var/app/uploads/
```

## CWE-200: Insertion of Sensitive Information into Externally-Accessible File or Directory

### All Languages
```python
# FAIL: Logs in web-accessible directory
LOG_PATH = "/var/log/app/"  # If /var is served by nginx

# PASS: Logs outside web root
LOG_PATH = "/var/log/app/"  # Ensure NOT in /var/www/
```
