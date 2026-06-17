#!/usr/bin/env python3
"""
Typosquat Detection Script — Checks dependency names against top packages.

Usage:
  python3 typosquat-check.sh <lockfile> [ecosystem]

Examples:
  python3 typosquat-check.sh package-lock.json npm
  python3 typosquat-check.sh requirements.txt pip

Output: JSON with suspected typosquats.
"""
import json
import sys
import re
import urllib.request

# Top packages by ecosystem (abbreviated — extend as needed)
TOP_PACKAGES = {
    "npm": [
        "lodash", "express", "react", "axios", "moment", "chalk", "commander",
        "webpack", "babel", "jest", "eslint", "prettier", "typescript", "ts-node",
        "nodemon", "dotenv", "cors", "helmet", "morgan", "multer", "bcrypt",
        "jsonwebtoken", "passport", "socket.io", "redis", "mongoose", "sequelize",
        "next", "vue", "angular", "svelte", "tailwindcss", "sass", "less",
        "webpack-dev-server", "vite", "rollup", "esbuild", "swc", "vitest",
        "testing-library", "cypress", "playwright", "puppeteer", "sharp",
        "winston", "pino", "joi", "yup", "zod", "class-validator",
        "typeorm", "prisma", "knex", "pg", "mysql2", "better-sqlite3",
        "aws-sdk", "@aws-sdk/client-s3", "firebase", "supabase",
        "react-dom", "react-router", "redux", "zustand", "recoil",
        "framer-motion", "three", "d3", "chart.js", "recharts",
        "uuid", "nanoid", "dayjs", "date-fns", "luxon",
        "lodash-es", "ramda", "immutable", "rxjs", "core-js",
        "semver", "rimraf", "mkdirp", "glob", "minimatch",
        "debug", "ms", "supports-color", "ansi-styles", "strip-ansi",
        "cross-env", "npm-run-all", "husky", "lint-staged",
        "ts-jest", "tsx", "tsup", "typedoc", "api-extractor",
    ],
    "PyPI": [
        "requests", "flask", "django", "fastapi", "pandas", "numpy", "scipy",
        "matplotlib", "seaborn", "scikit-learn", "tensorflow", "torch",
        "sqlalchemy", "alembic", "pydantic", "celery", "redis", "boto3",
        "botocore", "urllib3", "certifi", "charset-normalizer", "idna",
        "python-dateutil", "pytz", "pyyaml", "toml", "click", "typer",
        "rich", "httpx", "aiohttp", "asyncio", "trio", "anyio",
        "pytest", "coverage", "mypy", "ruff", "black", "isort",
        "cryptography", "pyjwt", "passlib", "bcrypt", "argon2-cffi",
        "pillow", "lxml", "beautifulsoup4", "scrapy", "selenium",
        "jinja2", "markupsafe", "itsdangerous", "werkzeug", "gunicorn",
        "uvicorn", "starlette", "httptools", "uvloop", "orjson",
        "psycopg2", "pymysql", "pymongo", "motor", "elasticsearch",
        "kafka-python", "pika", "grpcio", "protobuf",
        "sentry-sdk", "datadog", "newrelic", "prometheus-client",
        "structlog", "loguru", "python-json-logger",
        "factory-boy", "faker", "hypothesis", "responses", "mock",
    ],
}


def levenshtein(s1, s2):
    """Compute Levenshtein distance between two strings."""
    if len(s1) < len(s2):
        return levenshtein(s2, s1)
    if len(s2) == 0:
        return len(s1)

    prev_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        curr_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = prev_row[j + 1] + 1
            deletions = curr_row[j] + 1
            substitutions = prev_row[j] + (c1 != c2)
            curr_row.append(min(insertions, deletions, substitutions))
        prev_row = curr_row

    return prev_row[-1]


def check_name(name, top_list):
    """Check if name is a potential typosquat of any top package."""
    name_lower = name.lower().replace("_", "-")
    suspects = []

    for top in top_list:
        top_lower = top.lower().replace("_", "-")
        dist = levenshtein(name_lower, top_lower)

        # Distance of 1-2 from a popular package is suspicious
        if 1 <= dist <= 2 and len(name) > 3:
            suspects.append({
                "original": top,
                "distance": dist,
                "reason": f"Levenshtein distance {dist} from popular package '{top}'",
            })

    return suspects


def extract_deps(lockfile, ecosystem):
    """Extract dependency names from lockfile."""
    deps = set()
    try:
        if ecosystem == "npm":
            with open(lockfile) as f:
                data = json.load(f)
            for key in data.get("packages", {}):
                name = key.replace("node_modules/", "")
                if name:
                    deps.add(name)
        elif ecosystem == "PyPI":
            with open(lockfile) as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or line.startswith("-"):
                        continue
                    match = re.match(r"^([a-zA-Z0-9_-]+)[>=~]=", line)
                    if match:
                        deps.add(match.group(1))
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
    return deps


def main():
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <lockfile> <ecosystem>")
        sys.exit(1)

    lockfile = sys.argv[1]
    ecosystem = sys.argv[2]

    top_list = TOP_PACKAGES.get(ecosystem, [])
    if not top_list:
        print(json.dumps({"suspects": [], "verdict": "SKIP", "reason": f"No top packages for {ecosystem}"}))
        return

    deps = extract_deps(lockfile, ecosystem)
    suspects = []

    for dep in deps:
        hits = check_name(dep, top_list)
        for h in hits:
            suspects.append({
                "package": dep,
                "suspected_typosquat_of": h["original"],
                "distance": h["distance"],
                "reason": h["reason"],
            })

    verdict = "FAIL" if suspects else "PASS"
    output = {
        "dependencies_checked": len(deps),
        "suspects": len(suspects),
        "verdict": verdict,
        "findings": suspects,
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
