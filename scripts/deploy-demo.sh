#!/bin/bash
# Quick deploy script for demo environment
# Use this to deploy updates to your demo project

set -e

echo "🚀 Deploying to WSZLLP Demo Environment..."
echo ""

# Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Run this script from the project root."
    exit 1
fi

# Check if .env.demo exists
if [ ! -f ".env.demo" ]; then
    echo "❌ Error: .env.demo not found. Have you set up the demo environment?"
    echo "See docs/DEMO_SETUP_GUIDE.md for setup instructions."
    exit 1
fi

# Verify Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Install with: npm i -g vercel"
    exit 1
fi

echo "✅ Pre-flight checks passed"
echo ""

# Ask which project to deploy to
echo "Which demo project are you deploying to?"
read -p "Project name (default: wszllp-demo): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-wszllp-demo}

echo ""
echo "Deploying to: $PROJECT_NAME"
echo ""

# Deploy
echo "🔨 Building and deploying..."
vercel --prod --scope m-learsicos-projects

echo ""
echo "═══════════════════════════════════════════"
echo "✅ Demo deployment complete!"
echo "═══════════════════════════════════════════"
echo ""
echo "Your demo is now live. Check the URL above."
echo ""
echo "Next steps:"
echo "  1. Test the deployment"
echo "  2. Verify demo data is intact"
echo "  3. Share the URL with your client"
echo ""
