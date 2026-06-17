---
name: context7-integration
description: "Configure and use Context7 MCP for version-specific library documentation during code review, audit, and implementation. Reduces LLM hallucination and provides security advisory context."
version: 1.0.0
author: Hermes Agent (OWL)
license: MIT
metadata:
  hermes:
    tags: [context7, mcp, documentation, llm-context, security-advisories]
    related_skills: [coding-audit, security-framework, requesting-code-review]
---

# Context7 Integration

Uses Context7 MCP to provide version-specific library documentation to the LLM during code review, audit, and implementation. Reduces hallucination and provides security context.

## What Context7 Provides

- **Version-specific docs** — Real documentation for the exact library version in use
- **Custom sources** — Internal security guides, CVE lists, hardening docs
- **MCP integration** — Works natively with Hermes's MCP client

## Installation

```bash
# Add as MCP server
hermes mcp add context7 -- npx @context7/mcp-server

# Verify connection
hermes mcp test context7
```

## Configuration

### Version Pinning

Always pin to the version used in the project to avoid hallucination from newer APIs:

```
# In your query, specify the exact version:
"Show me the security considerations for express@4.18.2"
"Document the authentication flow in django@4.2"
```

### Custom Sources

Context7 can be configured to include custom documentation sources:

```json
{
  "context7": {
    "customSources": [
      {
        "name": "security-guides",
        "url": "https://internal-docs.example.com/security",
        "type": "markdown"
      },
      {
        "name": "cve-list",
        "url": "https://internal-docs.example.com/cves",
        "type": "markdown"
      }
    ]
  }
}
```

## Usage Patterns

### During Code Review

When reviewing code that uses a library, fetch the docs for that library:

```
Before reviewing auth code:
1. Query Context7 for "express@4.18.2 security best practices"
2. Query Context7 for "jsonwebtoken@9.0.0 API"
3. Use the returned docs to verify the code follows recommended patterns
```

### During Audit

When the coding-audit skill detects a dependency with a known CVE:

```
1. Query Context7 for the specific CVE advisory
2. Query Context7 for the library's security changelog
3. Use findings to determine severity and remediation
```

### During Implementation

When implementing a feature using a library:

```
1. Query Context7 for the library's API docs (pinned to project version)
2. Query Context7 for security best practices for that library
3. Implement using the documented patterns
```

## Integration Points

### With coding-audit

Add Context7 queries to the audit pipeline:

```
Step 5 (CVE Check): After OSV.dev query, use Context7 to fetch:
  - Library security advisories
  - Recommended secure configuration
  - Known attack vectors for the library

Step 6 (Supply Chain): Use Context7 to fetch:
  - Library maintainer security practices
  - Known supply chain incidents for the library
  - Recommended version pinning strategy
```

### With requesting-code-review

Provide the independent reviewer with Context7 context:

```
When dispatching reviewer subagent:
1. Query Context7 for all libraries used in the changed files
2. Include the docs in the reviewer's context
3. Reviewer checks code against documented security patterns
```

### With security-framework

Use Context7 to enrich framework mappings:

```
When security-framework identifies a control:
1. Query Context7 for language-specific implementation guidance
2. Include real examples from the library's official docs
3. Verify the code follows the documented secure pattern
```

## Query Templates

### Security Advisory Query
```
"Show me all security advisories for {library}@{version}. 
Include CVE IDs, severity, affected versions, and remediation."
```

### API Security Query
```
"Show me the security best practices for {library}@{version}.
Focus on: authentication, input validation, data protection, 
and common vulnerabilities."
```

### Configuration Hardening Query
```
"Show me the secure configuration options for {library}@{version}.
What are the default security settings? What should be changed 
for production use?"
```

### Supply Chain Query
```
"Show me the supply chain security information for {library}.
Who maintains it? What is the release process? 
Have there been any security incidents?"
```

## Fallback Behavior

If Context7 is unreachable:
1. Fall back to web search for library documentation
2. Fall back to local `references/` in security-framework
3. Log the fallback but continue the audit/review
4. Never block a commit solely because Context7 is unavailable

## Limitations

- **Network dependency:** Requires network access. Graceful fallback required.
- **Version accuracy:** Only as good as the version you specify. Always pin.
- **Coverage gaps:** Not all libraries are covered. Check before relying.
- **Staleness:** Docs may lag behind latest releases. Cross-reference with official docs.
- **Not a security tool:** Context7 provides docs, not vulnerability data. Use OSV.dev for CVEs.

## Reference Files

- `references/query-patterns.md` — Common Context7 query patterns per language
- `references/fallback-sources.md` — Alternative doc sources when Context7 is unavailable
