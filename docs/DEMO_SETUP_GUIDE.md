# WSZLLP Demo/Sandbox Setup Guide

This guide walks you through setting up a completely separate demo environment for client demonstrations. The demo project uses its own Supabase database and Vercel deployment, ensuring complete isolation from your production environment.

## Overview

**Goal:** Create a separate Vercel project (`wszllp-demo`) with its own database and sample data for client demos.

**Benefits:**
- Complete isolation from production
- Safe environment for client exploration
- Pre-loaded with realistic sample data
- Independent credentials and configuration
- Can be reset/rebuilt anytime without affecting production

---

## Prerequisites

- Vercel CLI installed: `npm i -g vercel`
- Access to Supabase (for creating a new project)
- Your Tyler e-filing demo/staging credentials

---

## Step-by-Step Setup

### 1. Create Demo Supabase Project

1. Go to https://supabase.com/dashboard
2. Click **"New Project"**
3. Configure:
   - **Name:** `wszllp-demo` or `wszllp-sandbox`
   - **Database Password:** (choose a strong password)
   - **Region:** Choose closest to your users
4. Wait for project to be created (~2 minutes)
5. Once ready, go to **Settings → API**
6. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJhbG...`)
   - **service_role key** (starts with `eyJhbG...`) - keep this secret!

### 2. Run Database Migrations

You need to apply your database schema to the demo project:

```bash
# Install Supabase CLI if needed
npm install -g supabase

# Link to your demo project
supabase link --project-ref YOUR_DEMO_PROJECT_ID

# Run migrations
supabase db push
```

Alternatively, you can run the SQL migrations manually:
1. Go to Supabase SQL Editor
2. Run all migration files from `supabase/migrations/` in order

### 3. Configure Demo Environment

Update the `.env.demo` file with your demo Supabase credentials:

```bash
# Edit .env.demo
VITE_SUPABASE_URL=https://your-demo-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Tyler e-filing credentials (use staging/demo credentials)
VITE_EFILE_USERNAME=your-demo-username
VITE_EFILE_PASSWORD=your-demo-password
VITE_EFILE_CLIENT_TOKEN=RANSTAG
```

### 4. Seed Demo Data

Run the seeding script to populate the demo database with sample cases:

```bash
node scripts/seed-demo-data.js
```

This will create:
- **Demo user account:** `demo@wszllp.com` / `DemoPassword123!`
- **3 sample cases** (Filed, Hearing Scheduled, Judgment Entered)
- **3 sample contacts** (defendants and property managers)
- **1 sample hearing** scheduled in the future

**Important:** Save the demo credentials shown at the end of the script!

### 5. Create Vercel Demo Project

Run the automated setup script:

```bash
./scripts/setup-demo-project.sh
```

Or set up manually:

```bash
# Initialize new Vercel project
vercel

# When prompted:
# - Link to existing project? → No
# - Project name? → wszllp-demo
# - Directory? → ./ (press enter)
# - Override settings? → No

# Add environment variables
vercel env add VITE_ENVIRONMENT production
# Enter: demo

vercel env add VITE_SUPABASE_URL production
# Paste your demo Supabase URL

vercel env add VITE_SUPABASE_ANON_KEY production
# Paste your demo anon key

vercel env add SUPABASE_SERVICE_ROLE_KEY production
# Paste your demo service role key

vercel env add VITE_EFILE_USERNAME production
# Enter your demo e-filing username

vercel env add VITE_EFILE_PASSWORD production
# Enter your demo e-filing password

vercel env add VITE_EFILE_CLIENT_TOKEN production
# Enter: RANSTAG

vercel env add VITE_EFILE_BASE_URL production
# Enter: https://api.uslegalpro.com/v4

# Deploy to production
vercel --prod
```

### 6. Get Your Demo URL

After deployment completes, you'll see:

```
✅ Production: https://wszllp-demo.vercel.app
```

This is the URL you'll share with potential clients!

### 7. Optional: Add Custom Domain

For a more professional demo experience:

1. Go to Vercel Dashboard → Your Demo Project → Settings → Domains
2. Add a custom domain like:
   - `demo.wszllp.com`
   - `sandbox.yourcompany.com`
3. Update your DNS records as instructed
4. Wait for SSL certificate to provision (~10 minutes)

---

## Giving Clients Access

### Option A: Provide Demo Credentials

Share these credentials with your client:

```
Demo URL: https://wszllp-demo.vercel.app
Email: demo@wszllp.com
Password: DemoPassword123!
```

**Pros:**
- Simple, one set of credentials
- Quick access for client

**Cons:**
- Shared demo environment
- Multiple clients see same data

### Option B: Create Individual Client Accounts

For each client, create a dedicated demo account:

```bash
# Connect to demo Supabase
# Use SQL Editor or Supabase Auth UI to create users

# Example for client "Acme Law Firm"
Email: demo+acme@wszllp.com
Password: AcmeDemo2025!
```

Then seed data specific to that client account.

**Pros:**
- Personalized demo experience
- Client-specific sample data
- Better security (each client has own credentials)

**Cons:**
- More setup per client
- Need to manage multiple accounts

### Option C: Self-Service Demo (Coming Soon)

Create a public demo page where clients can:
1. Click "Try Demo"
2. Auto-create temporary account
3. Access pre-loaded sample data
4. Account auto-expires after 24 hours

---

## Maintaining the Demo Environment

### Resetting Demo Data

To reset the demo database to default sample data:

```bash
# Clear all data
supabase db reset --linked

# Re-run migrations
supabase db push

# Re-seed demo data
node scripts/seed-demo-data.js
```

### Updating Demo After Code Changes

When you update features in your main codebase:

```bash
# Make sure changes are committed
git add .
git commit -m "feat: new feature"

# Deploy to demo
vercel --prod
```

The demo project will automatically rebuild with your latest code.

### Monitoring Demo Usage

Check Vercel analytics to see:
- Number of visitors
- Page views
- Performance metrics

Go to: Vercel Dashboard → wszllp-demo → Analytics

---

## Security Considerations

### Demo Environment Security

- ✅ **Separate database:** Demo uses its own Supabase project
- ✅ **RLS policies active:** Same security policies as production
- ✅ **Isolated credentials:** Demo credentials don't access production
- ✅ **Test e-filing only:** Uses staging Tyler API, not live court filings

### What to Share

**Safe to share:**
- Demo URL
- Demo user credentials (`demo@wszllp.com`)
- Screenshots of demo environment

**NEVER share:**
- Production URL or credentials
- Service role keys
- Tyler production credentials
- Database connection strings

### Best Practices

1. **Use demo-specific credentials** for Tyler e-filing (staging API)
2. **Regular data resets** - clear old client demo accounts monthly
3. **Monitor access logs** - check who's accessing the demo
4. **Watermark/banner** - consider adding "DEMO MODE" banner to UI
5. **Auto-expire accounts** - set up temporary demo accounts that expire

---

## Troubleshooting

### "Invalid Supabase credentials"

Check that `.env.demo` has correct values from your demo Supabase project.

### Deployment fails

```bash
# Check build logs
vercel logs

# Common fixes:
# 1. Verify all env vars are set
vercel env ls

# 2. Test build locally
npm run build
```

### Demo data not appearing

```bash
# Verify data was seeded
# Check Supabase Table Editor for demo project

# Re-run seeding script
node scripts/seed-demo-data.js
```

### RLS Policies blocking access

Ensure migrations were run on demo database:

```bash
supabase db push --linked
```

---

## Next Steps

After setup:

1. ✅ Test the demo yourself - login with demo credentials
2. ✅ Verify sample data appears correctly
3. ✅ Test key features (case creation, document upload, etc.)
4. ✅ Share demo URL with first client
5. ✅ Gather feedback and iterate

---

## Quick Reference

| Item | Value |
|------|-------|
| **Demo URL** | `https://wszllp-demo.vercel.app` |
| **Demo Email** | `demo@wszllp.com` |
| **Demo Password** | `DemoPassword123!` |
| **Environment File** | `.env.demo` |
| **Seed Script** | `node scripts/seed-demo-data.js` |
| **Deploy Command** | `vercel --prod` |
| **Reset Database** | `supabase db reset --linked` |

---

## Support

If you need help with demo setup:
- Check Vercel deployment logs: `vercel logs`
- Check Supabase logs: Project Dashboard → Logs
- Review this guide's troubleshooting section

---

**Document Version:** 1.0
**Last Updated:** 2025-01-18
**Maintained By:** WSZLLP Development Team
