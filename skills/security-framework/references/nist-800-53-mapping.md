# NIST 800-53 Rev 5 — Code-Level Control Mapping

Relevant controls mapped to concrete code checks.

## Access Control (AC)

| Control | Title | Code Check |
|---------|-------|------------|
| AC-2 | Account Management | No hardcoded credentials; all auth via env vars or secret managers |
| AC-3 | Access Enforcement | RBAC/ABAC implemented; no direct object references |
| AC-6 | Least Privilege | File permissions 600 for secrets; services run as non-root |
| AC-7 | Unsuccessful Logins | Rate limiting on auth endpoints; account lockout |
| AC-17 | Remote Access | TLS 1.2+ for all connections; no plaintext protocols |

## Audit and Accountability (AU)

| Control | Title | Code Check |
|---------|-------|------------|
| AU-2 | Event Logging | All auth events, data access, config changes logged |
| AU-3 | Content of Audit Records | Log: timestamp, user, action, resource, outcome |
| AU-6 | Audit Record Review | Automated log analysis for anomalies |
| AU-12 | Audit Record Generation | Structured logging (JSON); no PII in logs |

## Configuration Management (CM)

| Control | Title | Code Check |
|---------|-------|------------|
| CM-2 | Baseline Configuration | Infrastructure as Code; version-controlled config |
| CM-3 | Configuration Change Control | All config changes via PR with review |
| CM-6 | Configuration Settings | No default passwords; secure defaults enforced |
| CM-7 | Least Functionality | Unused dependencies removed; minimal attack surface |

## Identification and Authentication (IA)

| Control | Title | Code Check |
|---------|-------|------------|
| IA-2 | User Identification | Unique user IDs; no shared accounts |
| IA-5 | Authenticator Management | Password hashing (bcrypt/argon2); MFA support |
| IA-6 | Authenticator Feedback | No username enumeration; generic error messages |

## System and Communications Protection (SC)

| Control | Title | Code Check |
|---------|-------|------------|
| SC-7 | Boundary Protection | Network segmentation; firewall rules |
| SC-8 | Transmission Confidentiality | TLS for all data in transit |
| SC-12 | Cryptographic Key Management | Keys rotated; stored in HSM or secret manager |
| SC-28 | Protection of Information at Rest | Encryption at rest for sensitive data |

## System and Information Integrity (SI)

| Control | Title | Code Check |
|---------|-------|------------|
| SI-2 | Flaw Remediation | Dependency updates within SLA; CVE monitoring |
| SI-3 | Malicious Code Protection | Input validation; output encoding; CSP headers |
| SI-4 | System Monitoring | Anomaly detection; alerting on security events |
| SI-7 | Software, Firmware, and Information Integrity | Checksums on dependencies; signed commits |

## Privacy Controls (PT)

| Control | Title | Code Check |
|---------|-------|------------|
| PT-2 | Authority to Process | Data processing agreements in place |
| PT-3 | Purpose Specification | Data used only for stated purpose |
| PT-4 | Data Minimization | Collect only necessary data |
| PT-5 | Data Retention | Automatic data deletion after retention period |
| PT-6 | Data Quality | Input validation; data sanitization |

## Mapping to Audit Severity

| NIST Impact Level | Audit Severity |
|-------------------|----------------|
| HIGH (AC, IA, SC) | CRITICAL — blocks commit |
| MODERATE (AU, CM, SI) | HIGH — requires override |
| LOW (PT) | MEDIUM — recommended fix |
