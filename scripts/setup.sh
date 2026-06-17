#!/usr/bin/env bash
# adhd-hermes — Post-deploy setup script
# Run this after first boot to install dev tools and configure the environment.
# This script is idempotent — safe to run multiple times.
#
# Usage:
#   bash setup.sh                  # Install everything
#   bash setup.sh --check          # Check what's installed/missing
#   bash setup.sh --tools          # Install only dev tools
#   bash setup.sh --skills         # Install only skills to ~/.hermes/skills/

set -euo pipefail

HERMES_HOME="${HERMES_HOME:-/opt/data}"
LOCAL_BIN="${HOME}/.local/bin"
DEVTOOLS_DIR="${HOME}/.venvs/dev-tools"
SKILLS_SRC="$(cd "$(dirname "$0")" && pwd)/skills"
SKILLS_DST="${HERMES_HOME}/skills/software-development"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✅${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠️${NC}  $1"; }
fail() { echo -e "  ${RED}❌${NC}  $1"; }

CHECK_ONLY=false
TOOLS_ONLY=false
SKILLS_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --check)   CHECK_ONLY=true ;;
        --tools)   TOOLS_ONLY=true ;;
        --skills)  SKILLS_ONLY=true ;;
    esac
done

echo "═══════════════════════════════════════════════════"
echo "  adhd-hermes — Post-Deploy Setup"
echo "═══════════════════════════════════════════════════"
echo ""

# ---------------------------------------------------------------------------
# Step 1: System prerequisites
# ---------------------------------------------------------------------------
echo "▶ System prerequisites..."

# Check if running in the Hermes container
if [ -f /opt/hermes/.venv/bin/hermes ]; then
    ok "Hermes container detected"
else
    warn "Not running inside Hermes container — some steps may not apply"
fi

# Check for uv (Python package manager)
if command -v uv &>/dev/null; then
    ok "uv available: $(uv --version 2>&1 | head -1)"
else
    fail "uv not found — install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

# ---------------------------------------------------------------------------
# Step 2: Create directories
# ---------------------------------------------------------------------------
echo ""
echo "▶ Creating directories..."

mkdir -p "$LOCAL_BIN"
mkdir -p "$DEVTOOLS_DIR"
mkdir -p "$(dirname "$SKILLS_DST")"
ok "Directories created"

# ---------------------------------------------------------------------------
# Step 3: Install Python dev tools
# ---------------------------------------------------------------------------
if [ "$SKILLS_ONLY" = false ]; then
    echo ""
    echo "▶ Installing Python dev tools..."

    # Create venv if needed
    if [ ! -f "$DEVTOOLS_DIR/bin/pip" ]; then
        uv venv --python /opt/hermes/.venv/bin/python3 --seed "$DEVTOOLS_DIR" 2>&1 | tail -3
        ok "Dev tools venv created"
    else
        ok "Dev tools venv exists"
    fi

    # Install tools
    TOOLS=(bandit mypy pip-audit vulture interrogate pydocstyle cyclonedx-bom)
    for tool in "${TOOLS[@]}"; do
        if [ -f "$DEVTOOLS_DIR/bin/$tool" ]; then
            ok "$tool already installed"
        else
            if "$DEVTOOLS_DIR/bin/pip" install "$tool" 2>&1 | tail -3; then
                ok "$tool installed"
            else
                fail "$tool installation failed"
            fi
        fi
    done
fi

# ---------------------------------------------------------------------------
# Step 4: Install system tools (static binaries)
# ---------------------------------------------------------------------------
if [ "$SKILLS_ONLY" = false ]; then
    echo ""
    echo "▶ Installing system tools (static binaries)..."

    # jq
    if command -v jq &>/dev/null; then
        ok "jq: $(jq --version)"
    else
        if curl -sL https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64 -o "$LOCAL_BIN/jq" 2>/dev/null; then
            chmod 755 "$LOCAL_BIN/jq"
            ok "jq installed"
        else
            fail "jq download failed"
        fi
    fi

    # shellcheck
    if command -v shellcheck &>/dev/null; then
        ok "shellcheck: $(shellcheck --version 2>&1 | head -1)"
    else
        TMPDIR=$(mktemp -d)
        if curl -sL https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz -o "$TMPDIR/sc.tar.xz" 2>/dev/null; then
            tar -xf "$TMPDIR/sc.tar.xz" -C "$TMPDIR"
            cp "$TMPDIR/shellcheck-v0.10.0/shellcheck" "$LOCAL_BIN/shellcheck"
            chmod 755 "$LOCAL_BIN/shellcheck"
            rm -rf "$TMPDIR"
            ok "shellcheck installed"
        else
            fail "shellcheck download failed"
        fi
    fi

    # bats
    if command -v bats &>/dev/null; then
        ok "bats: $(bats --version)"
    else
        TMPDIR=$(mktemp -d)
        if curl -sL https://github.com/bats-core/bats-core/archive/refs/tags/v1.11.0.tar.gz -o "$TMPDIR/bats.tar.gz" 2>/dev/null; then
            tar -xf "$TMPDIR/bats.tar.gz" -C "$TMPDIR"
            cp "$TMPDIR/bats-core-1.11.0/bin/bats" "$LOCAL_BIN/bats"
            chmod 755 "$LOCAL_BIN/bats"
            rm -rf "$TMPDIR"
            ok "bats installed"
        else
            fail "bats download failed"
        fi
    fi
fi

# ---------------------------------------------------------------------------
# Step 5: Install Rust toolchain
# ---------------------------------------------------------------------------
if [ "$SKILLS_ONLY" = false ]; then
    echo ""
    echo "▶ Installing Rust toolchain..."

    if [ -f "$HOME/.cargo/bin/rustc" ]; then
        ok "Rust: $(bash -c 'source ~/.cargo/env && rustc --version')"
    else
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path 2>&1 | tail -3; then
            ok "Rust toolchain installed"
        else
            fail "Rust toolchain installation failed"
        fi
    fi

    # Rust tools
    RUST_TOOLS=(cargo-audit cargo-deny)
    for tool in "${RUST_TOOLS[@]}"; do
        if bash -c "source ~/.cargo/env && $tool --version" &>/dev/null; then
            ok "$tool already installed"
        else
            if bash -c "source ~/.cargo/env && cargo install $tool --locked" 2>&1 | tail -3; then
                ok "$tool installed"
            else
                warn "$tool installation failed (optional)"
            fi
        fi
    done
fi

# ---------------------------------------------------------------------------
# Step 6: Install Go toolchain
# ---------------------------------------------------------------------------
if [ "$SKILLS_ONLY" = false ]; then
    echo ""
    echo "▶ Installing Go toolchain..."

    GO_BIN="$HOME/.local/go/bin"
    mkdir -p "$GO_BIN"

    if [ -f "$GO_BIN/go" ]; then
        ok "Go: $(bash -c 'export PATH=$PATH:$GO_BIN && go version')"
    else
        TMPDIR=$(mktemp -d)
        if curl -sL https://go.dev/dl/go1.24.4.linux-amd64.tar.gz -o "$TMPDIR/go.tar.gz" 2>/dev/null; then
            tar -C "$HOME/.local" -xzf "$TMPDIR/go.tar.gz"
            rm -rf "$TMPDIR"
            ok "Go installed"
        else
            fail "Go download failed"
        fi
    fi

    # Go tools
    GO_TOOLS=(golangci-lint gosec)
    for tool in "${GO_TOOLS[@]}"; do
        if [ -f "$LOCAL_BIN/$tool" ]; then
            ok "$tool already installed"
        else
            if bash -c "export PATH=$PATH:$GO_BIN && go install $tool@latest" 2>&1 | tail -3; then
                ok "$tool installed"
            else
                warn "$tool installation failed (optional)"
            fi
        fi
    done
fi

# ---------------------------------------------------------------------------
# Step 7: Install npm global tools
# ---------------------------------------------------------------------------
if [ "$SKILLS_ONLY" = false ]; then
    echo ""
    echo "▶ Installing npm global tools..."

    NPM_TOOLS=(typescript @cyclonedx/cyclonedx-npm)
    for pkg in "${NPM_TOOLS[@]}"; do
        if npm list -g "$pkg" 2>/dev/null | grep -q "$pkg"; then
            ok "$pkg already installed"
        else
            if npm install -g "$pkg" 2>&1 | tail -3; then
                ok "$pkg installed"
            else
                warn "$pkg installation failed (optional)"
            fi
        fi
    done
fi

# ---------------------------------------------------------------------------
# Step 8: Install skills
# ---------------------------------------------------------------------------
if [ "$TOOLS_ONLY" = false ]; then
    echo ""
    echo "▶ Installing skills..."

    if [ -L "$SKILLS_DST" ]; then
        rm "$SKILLS_DST"
    fi

    if [ -d "$SKILLS_DST" ]; then
        rm -rf "$SKILLS_DST"
    fi

    ln -sfn "$SKILLS_SRC" "$SKILLS_DST"
    ok "Skills symlinked: $SKILLS_SRC → $SKILLS_DST"

    # Verify
    for skill in coding-audit security-framework doc-review context7-integration; do
        if [ -f "$SKILLS_DST/$skill/SKILL.md" ]; then
            ok "  $skill"
        else
            fail "  $skill: SKILL.md missing"
        fi
    done
fi

# ---------------------------------------------------------------------------
# Step 9: Configure SSH for GitHub
# ---------------------------------------------------------------------------
if [ "$SKILLS_ONLY" = false ]; then
    echo ""
    echo "▶ Configuring SSH for GitHub..."

    SSH_DIR="${HERMES_HOME}/.ssh"
    mkdir -p "$SSH_DIR"

    if [ -f "$SSH_DIR/id_ed25519" ]; then
        ok "SSH key exists"
    else
        ssh-keygen -t ed25519 -C "hermes-agent" -f "$SSH_DIR/id_ed25519" -N ""
        ok "SSH key generated"
        echo ""
        echo "  ⚠️  Add this public key to GitHub:"
        echo "  https://github.com/settings/keys"
        echo ""
        cat "$SSH_DIR/id_ed25519.pub"
        echo ""
    fi

    # Create SSH config
    if [ ! -f "$SSH_DIR/config" ]; then
        cat > "$SSH_DIR/config" << 'EOF'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    StrictHostKeyChecking accept-new
EOF
        ok "SSH config created"
    else
        ok "SSH config exists"
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Setup complete!"
echo "═══════════════════════════════════════════════════"
echo ""
echo "  Tools:     $LOCAL_BIN/"
echo "  Skills:    $SKILLS_DST/"
echo "  Dev venv:  $DEVTOOLS_DIR/"
echo "  SSH keys:  ${HERMES_HOME}/.ssh/"
echo ""
echo "  Add ~/.local/bin to PATH if not already:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
echo ""
