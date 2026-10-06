#!/usr/bin/env bash
# =============================================================================
# zscaler-doctor.sh — Diagnose & repair TLS/SSL breakage behind Zscaler on macOS
#
# Usage:
#   ./zscaler-doctor.sh                # full diagnostic (default: check)
#   ./zscaler-doctor.sh check          # env vars + bundle audit + tool tests
#   ./zscaler-doctor.sh regen --confirm
#                                      # regenerate ~/zscaler-ca-bundle.pem
#                                      #   (macOS system roots + keychain Zscaler CAs)
#   ./zscaler-doctor.sh fix-env        # print the export block for ~/.zshrc
#   ./zscaler-doctor.sh fix-env --write --confirm
#   ./zscaler-doctor.sh fix-python --confirm
#                                      #   (installs sitecustomize.py in user site-packages)
#   ./zscaler-doctor.sh all --confirm  # run every repair, then check
#
# Environment overrides:
#   BUNDLE=/path/to/bundle.pem         # default: ~/zscaler-ca-bundle.pem
#   PROBE_HOSTS="a:443 b:443"          # hosts used only for TLS diagnostics
#   RC_FILE=/path/to/shell/rc          # default: ~/.zshrc
# =============================================================================

set -uo pipefail
umask 077

BUNDLE="${BUNDLE:-${HOME}/zscaler-ca-bundle.pem}"
PROBE_HOSTS="${PROBE_HOSTS:-api.github.com:443 pypi.org:443 registry.npmjs.org:443 google.com:443}"
RC_FILE="${RC_FILE:-${HOME}/.zshrc}"
MARKER="# >>> zscaler-doctor >>>"
MARKER_END="# <<< zscaler-doctor <<<"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/zscaler-doctor.XXXXXX") || {
  echo "Unable to create a private temporary directory" >&2
  exit 1
}
readonly WORK_DIR
cleanup() {
  local status=$?
  trap - EXIT
  rm -rf -- "$WORK_DIR"
  exit "$status"
}
trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

if [ "$(uname -s)" != "Darwin" ]; then
  echo "zscaler-doctor supports macOS only" >&2
  exit 1
fi
if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is required" >&2
  exit 1
fi

PASS=0
FAIL=0
WARN=0
ok() {
  echo "  [OK]   $*"
  PASS=$((PASS + 1))
}
ko() {
  echo "  [FAIL] $*"
  FAIL=$((FAIL + 1))
}
wa() {
  echo "  [WARN] $*"
  WARN=$((WARN + 1))
}
info() { echo "  [....] $*"; }
hdr() {
  echo ""
  echo "== $* =="
}

# ---------------------------------------------------------------------------
# 1. Environment variables
# ---------------------------------------------------------------------------
check_env() {
  hdr "Environment variables"
  local vars="SSL_CERT_FILE REQUESTS_CA_BUNDLE CURL_CA_BUNDLE GIT_SSL_CAINFO PIP_CERT NODE_EXTRA_CA_CERTS AWS_CA_BUNDLE DENO_CERT"
  for v in $vars; do
    local val="${!v:-}"
    if [ -z "$val" ]; then
      case "$v" in
      NODE_EXTRA_CA_CERTS) ko "$v unset — Node.js IGNORES SSL_CERT_FILE, this one is required" ;;
      AWS_CA_BUNDLE | DENO_CERT) wa "$v unset (only needed if you use aws-cli / deno)" ;;
      *) ko "$v unset" ;;
      esac
    elif [ ! -r "$val" ]; then
      ko "$v=$val — file missing or unreadable"
    else
      ok "$v=$val"
    fi
  done
  [ -n "${UV_NATIVE_TLS:-}" ] && ok "UV_NATIVE_TLS=${UV_NATIVE_TLS} (uv uses macOS trust store)" || info "UV_NATIVE_TLS unset (uv uses rustls + SSL_CERT_FILE — stricter than Python)"

  # Divergence check: all CA vars should point at the SAME file. A mix of
  # bundles means tools disagree on trust and failures look random per tool.
  local distinct
  distinct=$(for v in SSL_CERT_FILE REQUESTS_CA_BUNDLE CURL_CA_BUNDLE GIT_SSL_CAINFO PIP_CERT NODE_EXTRA_CA_CERTS; do
    [ -n "${!v:-}" ] && echo "${!v}"
  done | sort -u)
  if [ "$(echo "$distinct" | grep -c .)" -gt 1 ]; then
    ko "CA env vars point at DIFFERENT files — tools use different trust stores:"
    echo "$distinct" | sed 's/^/           /'
    echo "         >>> Unify with '$0 fix-env --write --confirm' AFTER checking which file is good (see per-file audits below)."
    echo "         >>> Look in ~/.zshrc ~/.zprofile ~/.zshenv ~/.bashrc for duplicate export blocks."
  fi

  # Vars that silently disable verification — flag them
  for v in GIT_SSL_NO_VERIFY NODE_TLS_REJECT_UNAUTHORIZED PYTHONHTTPSVERIFY CURL_INSECURE; do
    [ -n "${!v:-}" ] && wa "$v=${!v} is set — verification disabled/altered, remove it once fixed"
  done

  # Proxy vars: some tools honor them, others don't — a set proxy var explains
  # per-tool differences (uv/rustls honors HTTP(S)_PROXY, curl too, node needs config)
  local any_proxy=0 proxy_value
  for v in HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy NO_PROXY no_proxy; do
    if [ -n "${!v:-}" ]; then
      proxy_value=$(printf '%s' "${!v}" | sed -E 's#(://)[^/@[:space:]]+@#\1***@#')
      info "proxy: $v=$proxy_value"
      any_proxy=1
    fi
  done
  [ "$any_proxy" -eq 0 ] && info "no proxy env vars set (transparent interception only)"

  # npm / git config can override env
  if command -v npm >/dev/null 2>&1; then
    local npm_cafile
    npm_cafile=$(npm config get cafile 2>/dev/null)
    [ "$npm_cafile" != "null" ] && [ -n "$npm_cafile" ] && info "npm cafile=$npm_cafile" || info "npm cafile not set (uses NODE_EXTRA_CA_CERTS)"
    local npm_strict
    npm_strict=$(npm config get strict-ssl 2>/dev/null)
    [ "$npm_strict" = "false" ] && wa "npm strict-ssl=false — verification disabled"
  fi
  if command -v git >/dev/null 2>&1; then
    local git_ca
    git_ca=$(git config --global http.sslCAInfo 2>/dev/null || true)
    [ -n "$git_ca" ] && info "git http.sslCAInfo=$git_ca (overrides GIT_SSL_CAINFO if different)"
    local git_verify
    git_verify=$(git config --global http.sslVerify 2>/dev/null || true)
    [ "$git_verify" = "false" ] && wa "git http.sslVerify=false — verification disabled"
  fi
}

# ---------------------------------------------------------------------------
# 2. Bundle audit — robust per-cert parse (CRLF-safe, ignores text between certs)
# ---------------------------------------------------------------------------
audit_one_bundle() {
  local file="$1"
  hdr "Bundle audit: $file"
  if [ ! -f "$file" ]; then
    ko "bundle not found — run: $0 regen --confirm"
    return 1
  fi
  local count
  count=$(grep -c "BEGIN CERTIFICATE" "$file" | head -1)
  info "$count certificate(s) in bundle"
  if [ "$count" -lt 3 ]; then
    wa "only $count cert(s) — if it lacks public roots, sites NOT intercepted by Zscaler will fail. 'regen' builds system-roots + Zscaler."
  fi

  local cert="" line subj text
  local noncritical=0 expired=0 unparseable=0 shown_exp=0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
    *"BEGIN CERTIFICATE"*) cert="${line}"$'\n' ;;
    *"END CERTIFICATE"*)
      [ -z "$cert" ] && continue
      cert="${cert}${line}"$'\n'
      text=$(printf "%s" "$cert" | openssl x509 -noout -text 2>/dev/null)
      if [ -z "$text" ]; then
        unparseable=$((unparseable + 1))
        cert=""
        continue
      fi
      subj=$(printf "%s" "$cert" | openssl x509 -noout -subject 2>/dev/null | sed 's/^subject=//')
      if ! printf "%s" "$cert" | openssl x509 -noout -checkend 0 >/dev/null 2>&1; then
        expired=$((expired + 1))
        [ "$shown_exp" -lt 5 ] && ko "EXPIRED: $subj" && shown_exp=$((shown_exp + 1))
      fi
      if echo "$text" | grep -q "CA:TRUE"; then
        if ! echo "$text" | grep "X509v3 Basic Constraints:" | grep -q "critical"; then
          wa "basicConstraints NOT critical (Python 3.13+ rejects this CA): $subj"
          noncritical=$((noncritical + 1))
        fi
      fi
      cert=""
      ;;
    *) [ -n "$cert" ] && cert="${cert}${line}"$'\n' ;;
    esac
  done <"$file"

  [ "$expired" -gt 5 ] && ko "...and $((expired - 5)) more expired certs"
  [ "$unparseable" -gt 0 ] && wa "$unparseable cert block(s) could not be parsed by openssl (corrupt PEM?)"
  [ "$expired" -eq 0 ] && ok "no expired certs"
  if [ "$noncritical" -gt 0 ]; then
    echo ""
    echo "  >>> $noncritical CA cert(s) without critical basicConstraints in this file."
    echo "  >>> Python 3.13+ (VERIFY_X509_STRICT) and uv (rustls) reject chains anchored on them."
    echo "  >>> curl/git/node still work. Fixes: $0 regen --confirm, then $0 fix-python --confirm if required."
  fi
  # subjects are base64-encoded in the certs — decode to search for Zscaler
  local has_zs
  has_zs=$(openssl crl2pkcs7 -nocrl -certfile "$file" 2>/dev/null | openssl pkcs7 -print_certs -noout 2>/dev/null | grep -ci zscaler | head -1)
  if [ "${has_zs:-0}" -gt 0 ]; then
    ok "Zscaler CA present ($has_zs entries)"
  else
    ko "no Zscaler CA found in this file"
  fi
}

check_bundle() {
  # Audit every distinct file referenced by CA env vars, plus $BUNDLE
  local files
  files=$({
    echo "$BUNDLE"
    for v in SSL_CERT_FILE REQUESTS_CA_BUNDLE CURL_CA_BUNDLE GIT_SSL_CAINFO PIP_CERT NODE_EXTRA_CA_CERTS; do
      [ -n "${!v:-}" ] && echo "${!v}"
    done
  } | sort -u)
  local f
  while IFS= read -r f; do
    [ -n "$f" ] && audit_one_bundle "$f"
  done <<<"$files"
}

# ---------------------------------------------------------------------------
# 3. Live interception check + chain verify
# ---------------------------------------------------------------------------
check_live() {
  hdr "Live TLS interception"
  local target chain verify_out
  for target in $PROBE_HOSTS; do
    if [[ ! "$target" =~ ^[A-Za-z0-9.-]+:[0-9]{1,5}$ ]]; then
      ko "invalid probe host '$target' — expected hostname:port"
      continue
    fi
    chain=$(openssl s_client -showcerts -connect "$target" -servername "${target%:*}" </dev/null 2>/dev/null)
    if ! printf '%s' "$chain" | grep -q "BEGIN CERTIFICATE"; then
      ko "no TLS handshake with $target — network/proxy problem, not a cert problem"
      continue
    fi
    if printf '%s' "$chain" | grep -qi "zscaler"; then
      ok "Zscaler interception active on $target"
    else
      wa "NOT intercepted: $target (Zscaler bypass) — issuer: $(printf '%s' "$chain" | grep 'issuer=' | head -1 | sed 's/.*issuer=//')"
      echo "         >>> bypassed hosts need PUBLIC roots in every bundle — a Zscaler-only file breaks them"
    fi
    if [ -f "$BUNDLE" ]; then
      verify_out=$(openssl s_client -connect "$target" -servername "${target%:*}" -CAfile "$BUNDLE" </dev/null 2>/dev/null | grep "Verify return code" || true)
      if printf '%s' "$verify_out" | grep -q ": 0 (ok)"; then
        ok "openssl verifies $target against bundle"
      else
        ko "openssl CANNOT verify $target against bundle — $verify_out — run: $0 regen --confirm"
      fi
    fi
  done
}

# ---------------------------------------------------------------------------
# 4. Per-tool tests
# ---------------------------------------------------------------------------
check_tools() {
  hdr "Tool tests"

  if command -v curl >/dev/null 2>&1; then
    if curl -sS --max-time 15 -o /dev/null https://api.github.com 2>"$WORK_DIR/curl.err"; then
      ok "curl https://api.github.com"
    else
      ko "curl: $(tail -1 "$WORK_DIR/curl.err")"
    fi
  fi

  if command -v git >/dev/null 2>&1; then
    if git ls-remote https://github.com/git/git.git HEAD >/dev/null 2>"$WORK_DIR/git.err"; then
      ok "git ls-remote github.com"
    else
      ko "git: $(tail -1 "$WORK_DIR/git.err")"
    fi
  fi

  local py=""
  for c in python3 python; do command -v "$c" >/dev/null 2>&1 && py=$c && break; done
  if [ -n "$py" ]; then
    local pyver
    pyver=$("$py" -c 'import sys;print("%d.%d"%sys.version_info[:2])')
    info "python: $py ($pyver)"
    if "$py" - <<'EOF' 2>"$WORK_DIR/python.err"; then
import os, ssl, urllib.request
ctx = ssl.create_default_context(cafile=os.environ.get("SSL_CERT_FILE"))
urllib.request.urlopen("https://api.github.com", context=ctx, timeout=15)
EOF
      ok "python urllib (default strict context)"
    else
      ko "python urllib default context: $(tail -1 "$WORK_DIR/python.err")"
      if "$py" - <<'EOF' 2>/dev/null; then
import os, ssl, urllib.request
ctx = ssl.create_default_context(cafile=os.environ.get("SSL_CERT_FILE"))
ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT
urllib.request.urlopen("https://api.github.com", context=ctx, timeout=15)
EOF
        echo "         ...but WORKS with VERIFY_X509_STRICT removed."
        echo "         >>> CONFIRMED: Python 3.13+ strict mode vs malformed Zscaler CA. Fix: $0 fix-python --confirm"
      else
        echo "         ...still fails without strict — bundle itself is bad. Run: $0 regen --confirm"
      fi
    fi
    if "$py" -c 'import requests' 2>/dev/null; then
      if "$py" -c 'import requests; requests.get("https://api.github.com", timeout=15)' 2>"$WORK_DIR/requests.err"; then
        ok "python requests (verify=REQUESTS_CA_BUNDLE)"
      else
        ko "python requests: $(tail -2 "$WORK_DIR/requests.err" | head -1)"
        if [ -n "${SSL_CERT_FILE:-}" ] && [ "${SSL_CERT_FILE:-}" != "${REQUESTS_CA_BUNDLE:-}" ]; then
          if "$py" -c 'import os, requests; requests.get("https://api.github.com", timeout=15, verify=os.environ["SSL_CERT_FILE"])' 2>/dev/null; then
            echo "         ...but WORKS with verify=\$SSL_CERT_FILE ($SSL_CERT_FILE)"
            echo "         >>> REQUESTS_CA_BUNDLE ($REQUESTS_CA_BUNDLE) is the bad file. Unify vars on the good one."
          else
            echo "         ...also fails with \$SSL_CERT_FILE — both bundles bad or strict-mode issue. Try: $0 fix-python --confirm"
          fi
        fi
      fi
    fi
  fi

  if command -v node >/dev/null 2>&1; then
    if node -e 'require("https").get("https://api.github.com",{headers:{"user-agent":"zsd"}},r=>{process.exit(0)}).on("error",e=>{console.error(e.message);process.exit(1)})' 2>"$WORK_DIR/node.err"; then
      ok "node https"
    else
      ko "node https: $(tail -1 "$WORK_DIR/node.err") — check NODE_EXTRA_CA_CERTS"
    fi
  fi

  if command -v npm >/dev/null 2>&1; then
    if npm ping --registry https://registry.npmjs.org >/dev/null 2>"$WORK_DIR/npm.err"; then
      ok "npm ping registry.npmjs.org"
    else
      ko "npm ping: $(grep -i 'error' "$WORK_DIR/npm.err" | head -1)"
    fi
  fi

  if command -v uv >/dev/null 2>&1; then
    local uvtmp
    uvtmp=$(mktemp -d "$WORK_DIR/uv.XXXXXX")
    if uv venv -q "$uvtmp/venv" 2>/dev/null &&
      VIRTUAL_ENV="$uvtmp/venv" uv pip install --dry-run --no-cache requests >/dev/null 2>"$WORK_DIR/uv.err"; then
      ok "uv (dry-run resolve from pypi)"
    else
      ko "uv failed — full error chain:"
      grep -E "error|Caused by|─▶" "$WORK_DIR/uv.err" | head -10 | sed 's/^/           /'
      if curl -sS --max-time 15 -o /dev/null https://pypi.org/simple/requests/ 2>/dev/null; then
        echo "         (curl reaches https://pypi.org/simple/requests/ fine — problem is uv/rustls specific)"
      else
        echo "         (curl ALSO fails on pypi.org — pypi is blocked/intercepted differently, not a uv problem)"
      fi
      if VIRTUAL_ENV="$uvtmp/venv" UV_NATIVE_TLS=1 uv pip install --dry-run --no-cache requests >/dev/null 2>"$WORK_DIR/uv-native.err"; then
        echo "         ...WORKS with UV_NATIVE_TLS=1 (macOS trust store)."
        echo "         >>> add 'export UV_NATIVE_TLS=1' — done by '$0 fix-env --write --confirm'"
      else
        echo "         UV_NATIVE_TLS=1 also fails:"
        grep -E "error|Caused by|─▶" "$WORK_DIR/uv-native.err" | head -6 | sed 's/^/           /'
      fi
    fi
    rm -rf -- "$uvtmp"
  fi
}

# ---------------------------------------------------------------------------
# regen: rebuild the bundle from local macOS trust stores only
# ---------------------------------------------------------------------------
cmd_regen() {
  hdr "Regenerating bundle: $BUNDLE"

  if [ "${1:-}" != "--confirm" ]; then
    ko "refusing to replace the CA bundle without: regen --confirm"
    return 1
  fi
  if ! command -v security >/dev/null 2>&1; then
    ko "macOS security command not found"
    return 1
  fi
  if [ -L "$BUNDLE" ]; then
    ko "refusing to replace symlink: $BUNDLE"
    return 1
  fi
  if [ -e "$BUNDLE" ] && [ ! -f "$BUNDLE" ]; then
    ko "refusing to replace non-regular file: $BUNDLE"
    return 1
  fi

  local bundle_dir tmp roots_count zscaler_count final_count backup staged
  case "$BUNDLE" in
  */*) bundle_dir=${BUNDLE%/*} ;;
  *) bundle_dir=. ;;
  esac
  if [ ! -d "$bundle_dir" ] || [ ! -w "$bundle_dir" ]; then
    ko "bundle directory is missing or not writable: $bundle_dir"
    return 1
  fi

  tmp=$(mktemp -d "$WORK_DIR/regen.XXXXXX") || return 1
  security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain >"$tmp/roots.pem" 2>/dev/null || true
  roots_count=$(grep -c 'BEGIN CERTIFICATE' "$tmp/roots.pem" 2>/dev/null || true)
  info "system roots: ${roots_count:-0} certs"
  if [ "${roots_count:-0}" -eq 0 ]; then
    ko "no macOS system roots found; refusing to replace the bundle"
    return 1
  fi

  : >"$tmp/keychain-zs.pem"
  for kc in "/Library/Keychains/System.keychain" "${HOME}/Library/Keychains/login.keychain-db"; do
    [ -r "$kc" ] || continue
    for name in zscaler Zscaler ZScaler; do
      security find-certificate -a -c "$name" -p "$kc" >>"$tmp/keychain-zs.pem" 2>/dev/null || true
    done
  done
  : >"$tmp/keychain-zs-ca.pem"
  local zs_cert="" zs_line zs_collecting=0
  while IFS= read -r zs_line || [ -n "$zs_line" ]; do
    case "$zs_line" in
    *"BEGIN CERTIFICATE"*)
      zs_cert="${zs_line}"$'\n'
      zs_collecting=1
      ;;
    *"END CERTIFICATE"*)
      [ "$zs_collecting" -eq 1 ] || continue
      zs_cert="${zs_cert}${zs_line}"$'\n'
      if printf '%s' "$zs_cert" | openssl x509 -noout -checkend 0 >/dev/null 2>&1 &&
        printf '%s' "$zs_cert" | openssl x509 -noout -text 2>/dev/null | grep -q 'CA:TRUE'; then
        printf '%s' "$zs_cert" >>"$tmp/keychain-zs-ca.pem"
      fi
      zs_cert=""
      zs_collecting=0
      ;;
    *) [ "$zs_collecting" -eq 1 ] && zs_cert="${zs_cert}${zs_line}"$'\n' ;;
    esac
  done <"$tmp/keychain-zs.pem"
  zscaler_count=$(grep -c 'BEGIN CERTIFICATE' "$tmp/keychain-zs-ca.pem" 2>/dev/null || true)
  info "valid keychain Zscaler CAs: ${zscaler_count:-0}"
  if [ "${zscaler_count:-0}" -eq 0 ]; then
    ko "no valid Zscaler CA found in macOS keychains; obtain the approved CA from IT"
    return 1
  fi

  cat "$tmp/roots.pem" "$tmp/keychain-zs-ca.pem" >"$tmp/all.pem"
  : >"$tmp/final.pem"
  local seen="" fp cert="" line collecting=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
    *"BEGIN CERTIFICATE"*)
      cert="${line}"$'\n'
      collecting=1
      ;;
    *"END CERTIFICATE"*)
      [ "$collecting" -eq 1 ] || continue
      cert="${cert}${line}"$'\n'
      fp=$(printf '%s' "$cert" | openssl x509 -noout -fingerprint -sha256 2>/dev/null || true)
      if [ -n "$fp" ] && ! printf '%s' "$seen" | grep -qF "$fp"; then
        seen="${seen}${fp}"$'\n'
        printf '%s' "$cert" >>"$tmp/final.pem"
      fi
      cert=""
      collecting=0
      ;;
    *) [ "$collecting" -eq 1 ] && cert="${cert}${line}"$'\n' ;;
    esac
  done <"$tmp/all.pem"

  final_count=$(grep -c 'BEGIN CERTIFICATE' "$tmp/final.pem" 2>/dev/null || true)
  if [ "${final_count:-0}" -lt "$roots_count" ]; then
    ko "generated bundle failed certificate validation; existing bundle unchanged"
    return 1
  fi
  if ! openssl crl2pkcs7 -nocrl -certfile "$tmp/final.pem" 2>/dev/null | openssl pkcs7 -print_certs -noout 2>/dev/null | grep -qi zscaler; then
    ko "generated bundle contains no Zscaler CA; existing bundle unchanged"
    return 1
  fi

  if [ -f "$BUNDLE" ]; then
    backup="${BUNDLE}.bak.$(date +%Y%m%d-%H%M%S)"
    cp -p "$BUNDLE" "$backup" || return 1
    chmod 600 "$backup" || return 1
    info "backup: $backup"
  fi
  staged=$(mktemp "${BUNDLE}.tmp.XXXXXX") || return 1
  install -m 600 "$tmp/final.pem" "$staged" || {
    rm -f -- "$staged"
    return 1
  }
  mv -f "$staged" "$BUNDLE" || {
    rm -f -- "$staged"
    return 1
  }
  ok "wrote $BUNDLE ($final_count unique certs, mode 600)"
  ok "Zscaler CA present in new bundle"
}

# ---------------------------------------------------------------------------
# fix-env: emit or install the canonical export block
# ---------------------------------------------------------------------------
cmd_fix_env() {
  local block bundle_q start_count end_count backup tmp mode staged
  bundle_q=$(printf '%q' "$BUNDLE")
  block=$(
    cat <<EOF
$MARKER
export SSL_CERT_FILE=$bundle_q
export REQUESTS_CA_BUNDLE=$bundle_q
export CURL_CA_BUNDLE=$bundle_q
export GIT_SSL_CAINFO=$bundle_q
export PIP_CERT=$bundle_q
export UV_NATIVE_TLS=1
export NODE_EXTRA_CA_CERTS=$bundle_q
export AWS_CA_BUNDLE=$bundle_q
export DENO_CERT=$bundle_q
$MARKER_END
EOF
  )
  if [ "${1:-}" != "--write" ]; then
    echo "$block"
    echo ""
    echo "  (use '$0 fix-env --write --confirm' to install into $RC_FILE)"
    return 0
  fi
  if [ "${2:-}" != "--confirm" ]; then
    ko "refusing to edit $RC_FILE without: fix-env --write --confirm"
    return 1
  fi
  if [ ! -r "$BUNDLE" ]; then
    ko "refusing to configure a missing or unreadable bundle: $BUNDLE"
    return 1
  fi
  if [ -L "$RC_FILE" ]; then
    ko "refusing to edit symlinked shell configuration: $RC_FILE"
    return 1
  fi
  if [ ! -e "$RC_FILE" ]; then
    : >"$RC_FILE" || return 1
    chmod 600 "$RC_FILE"
  fi
  if [ ! -f "$RC_FILE" ] || [ ! -w "$RC_FILE" ]; then
    ko "shell configuration is not a writable regular file: $RC_FILE"
    return 1
  fi

  start_count=$(grep -cF "$MARKER" "$RC_FILE" 2>/dev/null || true)
  end_count=$(grep -cF "$MARKER_END" "$RC_FILE" 2>/dev/null || true)
  if [ "$start_count" -ne "$end_count" ] || [ "$start_count" -gt 1 ]; then
    ko "managed markers are malformed or duplicated in $RC_FILE; refusing to edit"
    return 1
  fi

  backup="${RC_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  cp -p "$RC_FILE" "$backup" || return 1
  chmod 600 "$backup" || return 1
  tmp=$(mktemp "$WORK_DIR/rc.XXXXXX") || return 1
  awk -v start="$MARKER" -v end="$MARKER_END" '
        $0 == start { skip=1; next }
        $0 == end { skip=0; next }
        !skip { print }
    ' "$RC_FILE" >"$tmp" || return 1
  printf '\n%s\n' "$block" >>"$tmp"
  mode=$(/usr/bin/stat -f '%Lp' "$RC_FILE" 2>/dev/null || printf '600')
  staged=$(mktemp "${RC_FILE}.tmp.XXXXXX") || return 1
  install -m "$mode" "$tmp" "$staged" || {
    rm -f -- "$staged"
    return 1
  }
  mv -f "$staged" "$RC_FILE" || {
    rm -f -- "$staged"
    return 1
  }
  ok "written to $RC_FILE — backup: $backup"
  info "run: source $RC_FILE"
}

# ---------------------------------------------------------------------------
# fix-python: neutralize VERIFY_X509_STRICT for Python 3.13+ via sitecustomize
# ---------------------------------------------------------------------------
cmd_fix_python() {
  hdr "Fix Python 3.13+ VERIFY_X509_STRICT"
  if [ "${1:-}" != "--confirm" ]; then
    ko "refusing to change Python SSL behavior without: fix-python --confirm"
    return 1
  fi

  local py="" c site_dir target backup tmp staged first_line
  for c in python3 python; do command -v "$c" >/dev/null 2>&1 && py=$c && break; done
  [ -z "$py" ] && {
    ko "no python found"
    return 1
  }

  site_dir=$("$py" -m site --user-site 2>/dev/null)
  case "$site_dir" in
  "$HOME"/*) ;;
  *)
    ko "unsafe Python user-site path: $site_dir"
    return 1
    ;;
  esac
  mkdir -p -m 700 "$site_dir" || return 1
  target="$site_dir/sitecustomize.py"
  if [ -L "$target" ]; then
    ko "refusing to replace symlink: $target"
    return 1
  fi
  if [ -e "$target" ] && [ ! -f "$target" ]; then
    ko "refusing to replace non-regular file: $target"
    return 1
  fi
  if [ -f "$target" ]; then
    IFS= read -r first_line <"$target" || true
    if [ "$first_line" != "# Managed by zscaler-doctor." ]; then
      ko "existing sitecustomize.py is not managed by this tool; refusing to overwrite: $target"
      return 1
    fi
  fi
  if [ -f "$target" ]; then
    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    cp -p "$target" "$backup" || return 1
    chmod 600 "$backup" || return 1
    info "backup: $backup"
  fi

  tmp=$(mktemp "$WORK_DIR/sitecustomize.XXXXXX") || return 1
  cat >"$tmp" <<'PYEOF'
# Managed by zscaler-doctor.
# Certificate verification remains enabled; only VERIFY_X509_STRICT is removed.
import ssl

_orig_create_default_context = ssl.create_default_context

def _create_default_context(*args, **kwargs):
    ctx = _orig_create_default_context(*args, **kwargs)
    ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT
    return ctx

ssl.create_default_context = _create_default_context

try:
    _orig_stdlib = ssl._create_default_https_context
    def _stdlib_ctx(*args, **kwargs):
        ctx = _orig_stdlib(*args, **kwargs)
        ctx.verify_flags &= ~ssl.VERIFY_X509_STRICT
        return ctx
    ssl._create_default_https_context = _stdlib_ctx
except AttributeError:
    pass
PYEOF
  "$py" -c 'import pathlib, sys; compile(pathlib.Path(sys.argv[1]).read_text(), sys.argv[1], "exec")' "$tmp" || {
    ko "generated Python customization is invalid"
    return 1
  }
  staged=$(mktemp "${target}.tmp.XXXXXX") || return 1
  install -m 600 "$tmp" "$staged" || {
    rm -f -- "$staged"
    return 1
  }
  mv -f "$staged" "$target" || {
    rm -f -- "$staged"
    return 1
  }
  ok "installed $target (mode 600)"
  wa "Python strict X.509 validation is reduced for this user; certificate verification remains enabled"
  info "Prefer an IT-provided compliant Zscaler CA or Python truststore as the long-term fix"

  if "$py" -c 'import requests; requests.get("https://api.github.com", timeout=15)' 2>/dev/null; then
    ok "python requests now works"
  else
    wa "requests still failing (or not installed) — rerun '$0 check' for details"
  fi
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
usage() {
  echo "Usage: $0 [check|regen --confirm|fix-env|fix-env --write --confirm|fix-python --confirm|all --confirm]"
}

cmd="${1:-check}"
[ "$#" -gt 0 ] && shift
case "$cmd" in
check)
  [ "$#" -eq 0 ] || {
    usage
    exit 1
  }
  echo "zscaler-doctor — $(date '+%Y-%m-%d %H:%M:%S') — host: $(hostname)"
  echo "macOS $(sw_vers -productVersion 2>/dev/null), openssl: $(openssl version 2>/dev/null)"
  check_env
  check_bundle
  check_live
  check_tools
  hdr "Summary"
  echo "  PASS=$PASS FAIL=$FAIL WARN=$WARN"
  if [ "$FAIL" -gt 0 ]; then
    echo "  Next: use a confirmed repair only after reviewing the relevant failure."
    exit 1
  fi
  ;;
regen)
  [ "$#" -eq 1 ] && [ "$1" = "--confirm" ] || {
    usage
    exit 1
  }
  cmd_regen "$1"
  ;;
fix-env)
  if [ "$#" -eq 0 ]; then
    cmd_fix_env
  elif [ "$#" -eq 2 ] && [ "$1" = "--write" ] && [ "$2" = "--confirm" ]; then
    cmd_fix_env "$1" "$2"
  else
    usage
    exit 1
  fi
  ;;
fix-python)
  [ "$#" -eq 1 ] && [ "$1" = "--confirm" ] || {
    usage
    exit 1
  }
  cmd_fix_python "$1"
  ;;
all)
  [ "$#" -eq 1 ] && [ "$1" = "--confirm" ] || {
    usage
    exit 1
  }
  cmd_regen --confirm || exit 1
  cmd_fix_env --write --confirm || exit 1
  cmd_fix_python --confirm || exit 1
  export SSL_CERT_FILE="$BUNDLE" REQUESTS_CA_BUNDLE="$BUNDLE" CURL_CA_BUNDLE="$BUNDLE" \
    GIT_SSL_CAINFO="$BUNDLE" PIP_CERT="$BUNDLE" NODE_EXTRA_CA_CERTS="$BUNDLE" \
    AWS_CA_BUNDLE="$BUNDLE" DENO_CERT="$BUNDLE" UV_NATIVE_TLS=1
  check_env
  check_bundle
  check_live
  check_tools
  hdr "Summary"
  echo "  PASS=$PASS FAIL=$FAIL WARN=$WARN"
  echo "  Remember: source $RC_FILE (env exported only for this run)"
  [ "$FAIL" -eq 0 ]
  ;;
*)
  usage
  exit 1
  ;;
esac
