#!/usr/bin/env bash
# InvoiceFlow build script — single source of truth for flutter build commands.
#
# Usage:
#   ./scripts/build.sh dev       flutter run with Razorpay TEST keys
#   ./scripts/build.sh prod      flutter build apk --release with LIVE keys
#
# RAZORPAY_KEY_ID is a public identifier — safe to embed at build time.
# RAZORPAY_KEY_SECRET must NEVER appear here. It lives in Firebase Secret Manager.
#
# Set these in your shell profile (~/.zshrc or ~/.bashrc), not in this file:
#   export RAZORPAY_TEST_KEY_ID=rzp_test_YOUR_KEY_ID
#   export RAZORPAY_LIVE_KEY_ID=rzp_live_YOUR_KEY_ID

set -euo pipefail

ENV=${1:-dev}

case "$ENV" in
  dev)
    KEY_ID="rzp_test_Sd6MF9ADYdg91Z"
    echo "→ Building DEV with Razorpay TEST key"
    flutter run \
      --dart-define=RAZORPAY_KEY_ID="$KEY_ID" \
      --dart-define=APP_ENV=dev
    ;;

  prod)
    KEY_ID="${RAZORPAY_LIVE_KEY_ID:?RAZORPAY_LIVE_KEY_ID env var is required for prod builds}"
    echo "→ Building PROD with Razorpay LIVE key"
    flutter build apk \
      --release \
      --dart-define=RAZORPAY_KEY_ID="$KEY_ID" \
      --dart-define=APP_ENV=prod
    ;;

  *)
    echo "Unknown environment: '$ENV'" >&2
    echo "Usage: $0 [dev|prod]" >&2
    exit 1
    ;;
esac
