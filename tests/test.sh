#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$SCRIPT_DIR/../charts/openclaw"
SNAPSHOT_DIR="$SCRIPT_DIR/snapshots"
UPDATE=false

for arg in "$@"; do
  case "$arg" in
    --update | -u) UPDATE=true ;;
  esac
done

# Ensure chart dependencies are available
helm dependency build "$CHART_DIR" --skip-refresh 2>/dev/null \
  || helm dependency update "$CHART_DIR"

# Read versions from Chart.yaml for normalization (so snapshots don't break on bumps)
CHART_VERSION=$(grep '^version:' "$CHART_DIR/Chart.yaml" | awk '{print $2}')
APP_VERSION=$(grep '^appVersion:' "$CHART_DIR/Chart.yaml" | awk '{print $2}' | tr -d '"')

FAIL=false

run_scenario() {
  local name="$1"
  shift
  local snapshot="$SNAPSHOT_DIR/$name.yaml"

  echo "==> scenario: $name"

  local raw
  raw=$(helm template openclaw "$CHART_DIR" "$@")

  # Validate and sort: yq exits non-zero on invalid YAML; collect all docs into an array,
  # sort by kind then name, and emit each document — yq re-serializes consistently.
  local output
  if ! output=$(echo "$raw" | yq eval-all '[.] | sort_by(.kind, .metadata.name) | .[]'); then
    echo "    FAIL: output is not valid YAML"
    FAIL=true
    return
  fi
  echo "    OK:   YAML valid"

  # Replace chart/app versions with fixed placeholders so snapshots survive version bumps.
  # Dots are escaped so they are treated as literals in the sed regex.
  local chart_ver_re="${CHART_VERSION//./\\.}"
  local app_ver_re="${APP_VERSION//./\\.}"
  output=$(printf '%s\n' "$output" | sed "s/${chart_ver_re}/CHART_VERSION/g; s/${app_ver_re}/APP_VERSION/g")

  if $UPDATE; then
    mkdir -p "$SNAPSHOT_DIR"
    printf '%s\n' "$output" > "$snapshot"
    echo "    snapshot updated: $snapshot"
  elif [[ ! -f "$snapshot" ]]; then
    echo "    FAIL: no snapshot found — run with --update to create it"
    FAIL=true
  else
    if diff --unified=3 "$snapshot" <(printf '%s\n' "$output"); then
      echo "    OK:   Output matches snapshot"
    else
      echo "    FAIL: Output differs from snapshot — run with --update to accept changes"
      FAIL=true
    fi
  fi
}

run_scenario "default"

run_scenario "homebrew-with-packages" \
  --set 'app-template.homebrew.enabled=true' \
  --set 'app-template.homebrew.packages={gh,gogcli}'

echo ""
if $FAIL; then
  echo "FAILED: one or more scenarios did not match their snapshots."
  exit 1
else
  echo "All scenarios passed."
fi
