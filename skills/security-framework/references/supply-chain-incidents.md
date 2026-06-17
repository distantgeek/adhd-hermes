# Supply Chain Security Incidents (2022-2026)

Real-world supply chain attacks and their lessons. Used by `coding-audit` for threat modeling.

## 2022

### colors.js / faker.js Protestware (Jan 2022)
- **What:** Maintainer Marak Squires intentionally broke `colors` and `faker` — two of the most popular npm packages (combined 2B+ weekly downloads)
- **How:** Pushed updates that printed ZALGO text and infinite loops
- **Impact:** Every project depending on these packages broke. CI pipelines, production apps, development environments.
- **Lesson:** Even trusted maintainers can sabotage. Pin versions. Audit updates.
- **CWE:** CWE-506 (Embedded Malicious Code)

### node-ipc Protestware (Mar 2022)
- **What:** Maintainer pushed update to `node-ipc` that contained destructive payload targeting systems with Russian/Belarusian locale
- **How:** The `peacenotwar` module overwrote files with heart emojis on affected systems
- **Impact:** Affected Vue.js, Unity Hub, and thousands of projects
- **Lesson:** Postinstall scripts can execute arbitrary code. Never trust them blindly.
- **CWE:** CWE-506, CWE-78 (OS Command Injection)

### ua-parser-js Hijacking (Oct 2022)
- **What:** Maintainer's npm account was hijacked. Malicious versions (0.7.29, 0.8.1) published
- **How:** Malware installed cryptominer and credential-stealing trojan
- **Impact:** 7M+ weekly downloads. Massive blast radius.
- **Lesson:** Account security matters. 2FA on npm is not optional.
- **CWE:** CWE-506

## 2023

### node-ipc Continued (Mar 2023)
- **What:** Same maintainer pushed another malicious update under a different package name
- **Impact:** Continued targeting of specific geographic regions
- **Lesson:** Blocklist known malicious packages. Monitor for new packages from compromised maintainers.

### ctx Package Hijacking (May 2023)
- **What:** Popular `ctx` package on PyPI was hijacked
- **How:** Attacker gained access via compromised maintainer account, pushed malicious version
- **Impact:** Credential theft for users who installed the malicious version
- **Lesson:** PyPI account security is as critical as npm. Use trusted publishing.

## 2024

### es5-ext Protestware (Jan 2024)
- **What:** `es5-ext` (50M+ weekly downloads) maintainer pushed update with anti-war message and infinite loop
- **How:** Code checked system locale and date, then either printed message or entered infinite loop
- **Impact:** Massive disruption. Affected webpack, babel, and thousands of downstream projects.
- **Lesson:** Conditional payloads are hard to detect. Behavioral scanning of updates is essential.
- **CWE:** CWE-506, CWE-835 (Loop with Unreachable Exit Condition)

### Lottie-Web Protestware (Mar 2024)
- **What:** `lottie-web` maintainer pushed update with political message
- **How:** Similar pattern to es5-ext — conditional activation based on locale
- **Impact:** Affected animation-heavy web applications
- **Lesson:** Protestware is now a recurring pattern. Assume any popular package could be affected.

### Phylum Research Report (2024)
- **What:** Phylum documented a surge in AI-generated malicious packages
- **How:** Attackers used LLMs to generate polymorphic code that evaded signature detection
- **Impact:** Hundreds of new malicious packages published monthly
- **Lesson:** Signature-based detection is insufficient. Behavioral analysis required.
- **CWE:** CWE-506

## 2025

### Continued AI-Generated Malware Surge
- **What:** AI-generated malicious packages became the dominant threat vector
- **How:** LLMs generate unique obfuscated payloads for each package, evading hash-based detection
- **Impact:** Traditional package scanning tools miss 30-40% of AI-generated malware
- **Lesson:** Need multi-layered detection: static analysis + behavioral + reputation + maintainer verification.

### Typosquatting Automation
- **What:** Automated tools now generate thousands of typo-squatted packages
- **How:** Scripts generate permutations of popular package names and publish them
- **Impact:** Developers accidentally install malicious packages with names like `requets`, `lodahs`, `typescritp`
- **Lesson:** Typosquat detection must be automated. Manual review doesn't scale.

### Compromised Maintainer Accounts (Ongoing)
- **What:** Session hijacking and social engineering of npm/PyPI maintainers increased
- **How:** Attackers bypass 2FA via session cookie theft, then push "minor patch" updates
- **Impact:** Trusted packages with millions of downloads compromised
- **Lesson:** Monitor for unexpected maintainer changes. Verify update contents before trusting.

## 2026 (Current Threat Landscape)

### Key Trends
1. **AI-assisted attacks** — LLMs generate polymorphic malware at scale
2. **Protestware normalization** — Political sabotage in packages is now expected
3. **Supply chain regulation** — US Executive Order 14028, EU Cyber Resilience Act require SBOMs
4. **Provenance adoption** — npm provenance, Sigstore signing gaining traction but still low adoption
5. **Zero-trust dependencies** — Industry moving toward "verify every dependency, trust nothing"

## Lessons for Hermes Coding Framework

1. **Every dependency is a trust decision** — verify before installing
2. **Lockfiles are necessary but not sufficient** — they pin versions but don't verify intent
3. **Updates require review** — never auto-update without diff review
4. **Behavioral scanning catches what signatures miss** — scan postinstall scripts, network calls, filesystem access
5. **Maintainer changes are red flags** — new maintainer on a popular package = investigate
6. **SBOM is becoming a legal requirement** — generate and maintain SBOMs for every project
7. **AI-generated malware requires AI-assisted detection** — static analysis alone is insufficient
