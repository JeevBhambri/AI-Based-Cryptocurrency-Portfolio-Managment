#!/usr/bin/env bash
# One-command launcher for Apex Crypto Agent
set -e
cd "$(dirname "$0")"
if [ ! -d "server/node_modules" ] || [ ! -d "client/node_modules" ]; then
  echo "Installing dependencies (one-time)…"
  npm run install:all
fi
if [ ! -f "server/.env" ]; then
  echo "WARNING: server/.env not found. Copying from .env.example."
  cp server/.env.example server/.env
  echo "Edit server/.env to add your ANTHROPIC_API_KEY (or set DEMO_MODE=true)."
fi
echo ""
echo "Starting Apex on http://localhost:5173 ..."
npm run dev
