#!/bin/bash
# Setup script for demo Vercel project

set -e

echo "🎯 Setting up WSZLLP Demo Project on Vercel..."

# Check if vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Install with: npm i -g vercel"
    exit 1
fi

echo ""
echo "Step 1: Create new Vercel project"
echo "You will be prompted to:"
echo "  - Link to existing project? → No"
echo "  - Project name? → wszllp-demo"
echo "  - Directory? → ./ (press enter)"
echo "  - Override settings? → No (press enter)"
echo ""
read -p "Press enter to continue..."

# Create new project (this will prompt for project name)
vercel

echo ""
echo "Step 2: Setting up environment variables..."
echo ""

# Set environment variables for demo project
echo "Setting VITE_ENVIRONMENT..."
vercel env add VITE_ENVIRONMENT production < <(echo "demo")

echo ""
echo "⚠️  You'll need to manually add these environment variables:"
echo ""
echo "Required variables (get from your demo Supabase project):"
echo "  1. VITE_SUPABASE_URL"
echo "  2. VITE_SUPABASE_ANON_KEY"
echo "  3. SUPABASE_SERVICE_ROLE_KEY"
echo "  4. VITE_EFILE_USERNAME"
echo "  5. VITE_EFILE_PASSWORD"
echo "  6. VITE_EFILE_CLIENT_TOKEN"
echo ""
echo "Run these commands:"
echo "  vercel env add VITE_SUPABASE_URL production"
echo "  vercel env add VITE_SUPABASE_ANON_KEY production"
echo "  vercel env add SUPABASE_SERVICE_ROLE_KEY production"
echo "  vercel env add VITE_EFILE_USERNAME production"
echo "  vercel env add VITE_EFILE_PASSWORD production"
echo "  vercel env add VITE_EFILE_CLIENT_TOKEN production"
echo ""
echo "Step 3: Deploy to Vercel"
echo "  vercel --prod"
echo ""
echo "✅ Setup guide complete!"
