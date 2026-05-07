#!/bin/sh
# OpenSauce installer — public POSIX install path.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --version 0.1.0
#   curl -fsSL .../install.sh | sh -s -- --scope system   # requires sudo
#
# The .deb path uses dpkg directly when available (Debian/Ubuntu); falls back
# to per-user tarball install everywhere else.
set -eu

VERSION="${SAUCE_VERSION:-0.1.0}"
SCOPE="${SAUCE_SCOPE:-user}"
PROFILE="${SAUCE_PROFILE:-client}"
GITHUB_REPO="${SAUCE_REPO:-Diatonic-AI/opensauce}"

# ─── parse args ──────────────────────────────────────────────────────
while [ $# -gt 0 ]; do
  case "$1" in
    --version)   VERSION="$2";  shift 2 ;;
    --version=*) VERSION="${1#*=}"; shift ;;
    --scope)     SCOPE="$2";    shift 2 ;;
    --scope=*)   SCOPE="${1#*=}"; shift ;;
    --profile)   PROFILE="$2";  shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    -h|--help)
      cat <<EOF
OpenSauce installer
  --version <v>          default: $VERSION
  --scope user|system    default: user (system requires sudo)
  --profile <p>          default: client (passed to 'sauce init')

Env overrides:  SAUCE_VERSION  SAUCE_SCOPE  SAUCE_PROFILE  SAUCE_REPO
EOF
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

# ─── platform + scope sanity ─────────────────────────────────────────
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) ARCH=x86_64 ;; aarch64|arm64) ARCH=aarch64 ;; *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; esac
case "$OS" in linux|darwin) ;; *) echo "unsupported os: $OS (Windows: use install.ps1 or download .msi from releases)" >&2; exit 1 ;; esac

if [ "$SCOPE" = "system" ] && [ "$(id -u)" -ne 0 ]; then
  echo "error: --scope=system requires root (sudo sh -s -- --scope system)" >&2
  exit 1
fi

# ─── prefer the .deb path on Debian/Ubuntu ───────────────────────────
DEB_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/sauce-framework_${VERSION}-1_amd64.deb"
if [ "$OS" = "linux" ] && [ "$ARCH" = "x86_64" ] && command -v dpkg >/dev/null 2>&1 && [ "$SCOPE" = "system" ]; then
  TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
  echo "→ downloading .deb: $DEB_URL"
  curl -fsSL "$DEB_URL" -o "$TMP/sauce.deb"
  echo "→ dpkg -i (will run postinst — provisioning users + system dirs)"
  dpkg -i "$TMP/sauce.deb"
  echo "✅ sauce-framework $VERSION installed (system scope, .deb path)"
  exit 0
fi

# ─── per-user tarball / binary path (Linux + macOS, no sudo) ─────────
VENDOR=SauceTech
APP=sauce
LIBDIR="$HOME/.local/lib/$VENDOR/$APP"
BINDIR="$HOME/.local/bin"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# Tarball naming: sauce-<v>-<os>-<arch>.tar.gz under the same release.
TARBALL_URL="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/sauce-${VERSION}-${OS}-${ARCH}.tar.gz"
echo "→ downloading $TARBALL_URL"
if ! curl -fsSL "$TARBALL_URL" -o "$TMP/sauce.tar.gz" 2>/dev/null; then
  # Fallback: extract from the .deb when no per-OS tarball is published yet.
  echo "→ tarball not found; falling back to .deb extraction"
  curl -fsSL "$DEB_URL" -o "$TMP/sauce.deb"
  ar x "$TMP/sauce.deb" --output="$TMP" data.tar.* 2>/dev/null
  ( cd "$TMP" && tar xf data.tar.* )
  # binaries land at $TMP/usr/bin/
  cp "$TMP/usr/bin/"sauce* "$TMP/" 2>/dev/null || true
  if [ -d "$TMP/usr/share/sauce/scripts" ]; then
    mkdir -p "$TMP/scripts" && cp "$TMP/usr/share/sauce/scripts/"* "$TMP/scripts/"
  fi
else
  tar -xzf "$TMP/sauce.tar.gz" -C "$TMP"
fi

echo "→ installing to $LIBDIR (24 binaries + scripts)"
mkdir -p "$LIBDIR" "$LIBDIR/scripts" "$BINDIR"
SAUCE_BINS='
  sauce sauce-mcp sauce-registry
  sauce-pipeline sauce-tok
  sauce-classify sauce-ontology sauce-extract
  sauce-cart-fs-inventory sauce-cart-deps-roles sauce-cart-ts-types
  sauce-cart-sql-schema sauce-cart-routes-map sauce-cart-api-surface
  sauce-cart-configs-canon sauce-cart-docs-canon sauce-cart-patterns
  sauce-cart-standards sauce-cart-lexicon sauce-cart-taxonomy
  sauce-cart-ontology sauce-cart-topology sauce-cart-epistemology
  sauce-cart-db-rel-graph
'
n=0
for bin in $SAUCE_BINS; do
  if [ -f "$TMP/$bin" ]; then
    install -m 0755 "$TMP/$bin" "$LIBDIR/$bin"
    ln -sf "$LIBDIR/$bin" "$BINDIR/$bin"
    n=$((n + 1))
  fi
done
echo "   installed $n binaries"

if [ -f "$TMP/scripts/sauce-pipeline.sh" ]; then
  install -m 0755 "$TMP/scripts/sauce-pipeline.sh" "$LIBDIR/scripts/sauce-pipeline.sh"
fi

# ─── PATH guidance ───────────────────────────────────────────────────
case ":$PATH:" in
  *":$BINDIR:"*) ;;
  *) echo; echo "→ NOTE: $BINDIR is not on your PATH. Add this to your shell rc:"; echo "    export PATH=\"$BINDIR:\$PATH\"" ;;
esac

# ─── touchless user provisioning ─────────────────────────────────────
if [ -x "$BINDIR/sauce" ]; then
  echo "→ sauce init --scope user --profile $PROFILE"
  "$BINDIR/sauce" init --scope user --profile "$PROFILE" --quiet 2>/dev/null || true
  echo
  "$BINDIR/sauce" --version 2>/dev/null || true
fi

echo "✅ sauce-framework $VERSION installed (scope=$SCOPE, profile=$PROFILE)"
