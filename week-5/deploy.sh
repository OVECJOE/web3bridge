#!/bin/bash

# =============================================================================
# deploy_all.sh
# Deploys all Foundry projects (forge init) in the current directory to
# Lisk Sepolia. Place your .env file in the same folder as this script.
# =============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LISK_SEPOLIA_RPC="https://rpc.sepolia-api.lisk.com"
CHAIN_ID=4202
LOG_FILE="$SCRIPT_DIR/deploy_$(date +%Y%m%d_%H%M%S).log"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()    { echo -e "$*" | tee -a "$LOG_FILE"; }
info()   { log "${CYAN}[INFO]${NC}  $*"; }
success(){ log "${GREEN}[OK]${NC}    $*"; }
warn()   { log "${YELLOW}[WARN]${NC}  $*"; }
error()  { log "${RED}[ERROR]${NC} $*"; }
header() { log "\n${BOLD}${CYAN}=== $* ===${NC}"; }

# ── Preflight checks ──────────────────────────────────────────────────────────
header "Preflight"

if ! command -v forge &>/dev/null; then
  error "forge not found. Install Foundry: https://getfoundry.sh"
  exit 1
fi
info "Foundry: $(forge --version)"

if [[ ! -f "$ENV_FILE" ]]; then
  error ".env not found at $ENV_FILE"
  exit 1
fi

# Load .env (skip comments and empty lines)
set -o allexport
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +o allexport

if [[ -z "${PRIVATE_KEY:-}" ]]; then
  error "PRIVATE_KEY is not set in .env"
  exit 1
fi

info "RPC : $LISK_SEPOLIA_RPC"
info "Log : $LOG_FILE"

# ── Discover Foundry projects ─────────────────────────────────────────────────
header "Discovering projects"

mapfile -t PROJECTS < <(
  find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r dir; do
    if [[ -f "$dir/foundry.toml" && -d "$dir/src" && -d "$dir/script" ]]; then
      echo "$dir"
    fi
  done | sort
)

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
  error "No Foundry projects found in $SCRIPT_DIR"
  error "Each sub-folder must contain foundry.toml, src/, and script/."
  exit 1
fi

info "Found ${#PROJECTS[@]} project(s):"
for p in "${PROJECTS[@]}"; do
  info "  → $(basename "$p")"
done

# ── Deploy loop ───────────────────────────────────────────────────────────────
PASS=0
FAIL=0
FAILED_PROJECTS=()

for PROJECT_DIR in "${PROJECTS[@]}"; do
  PROJECT_NAME="$(basename "$PROJECT_DIR")"
  header "Deploying: $PROJECT_NAME"

  # Find deploy script(s) inside project/script/
  mapfile -t DEPLOY_SCRIPTS < <(find "$PROJECT_DIR/script" -maxdepth 2 -name "*.s.sol" 2>/dev/null | sort)

  if [[ ${#DEPLOY_SCRIPTS[@]} -eq 0 ]]; then
    warn "No .s.sol deploy scripts found in $PROJECT_DIR/script — skipping."
    FAIL=$((FAIL + 1))
    FAILED_PROJECTS+=("$PROJECT_NAME (no deploy script)")
    continue
  fi

  # Install / update dependencies
  info "Installing dependencies..."
  (cd "$PROJECT_DIR" && forge install --no-git 2>&1 | tee -a "$LOG_FILE") || true

  # Build first to catch compilation errors early
  info "Building..."
  if ! (cd "$PROJECT_DIR" && forge build 2>&1 | tee -a "$LOG_FILE"); then
    error "$PROJECT_NAME failed to compile — skipping."
    FAIL=$((FAIL + 1))
    FAILED_PROJECTS+=("$PROJECT_NAME (build failed)")
    continue
  fi

  PROJECT_FAILED=false

  for SCRIPT_PATH in "${DEPLOY_SCRIPTS[@]}"; do
    SCRIPT_REL="${SCRIPT_PATH#"$PROJECT_DIR/"}"
    # Derive the contract name from filename (MyScript.s.sol → MyScript)
    SCRIPT_CONTRACT="$(basename "$SCRIPT_PATH" .s.sol)"

    info "Running script: $SCRIPT_REL ($SCRIPT_CONTRACT)"

    DEPLOY_CMD=(
      forge script "$SCRIPT_REL"
        --contracts "$SCRIPT_CONTRACT"
        --rpc-url "$LISK_SEPOLIA_RPC"
        --chain-id "$CHAIN_ID"
        --private-key "$PRIVATE_KEY"
        --broadcast
        --verify
        --verifier blockscout
        --verifier-url "https://sepolia-blockscout.lisk.com/api"
    )

    # Optional: pass extra flags via FORGE_EXTRA_FLAGS env var
    if [[ -n "${FORGE_EXTRA_FLAGS:-}" ]]; then
      # shellcheck disable=SC2206
      DEPLOY_CMD+=($FORGE_EXTRA_FLAGS)
    fi

    if (cd "$PROJECT_DIR" && "${DEPLOY_CMD[@]}" 2>&1 | tee -a "$LOG_FILE"); then
      success "$PROJECT_NAME / $SCRIPT_CONTRACT deployed successfully."
    else
      error "$PROJECT_NAME / $SCRIPT_CONTRACT deployment FAILED."
      PROJECT_FAILED=true
    fi
  done

  if $PROJECT_FAILED; then
    FAIL=$((FAIL + 1))
    FAILED_PROJECTS+=("$PROJECT_NAME (deployment failed)")
  else
    PASS=$((PASS + 1))
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
header "Summary"
success "Passed : $PASS"
if [[ $FAIL -gt 0 ]]; then
  error   "Failed : $FAIL"
  for fp in "${FAILED_PROJECTS[@]}"; do
    error "  ✗ $fp"
  done
else
  log     "Failed : 0"
fi
info "Full log saved to: $LOG_FILE"

[[ $FAIL -eq 0 ]]   # exit 1 if any project failed
