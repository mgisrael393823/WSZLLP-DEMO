# WSZLLP Demo Environment

**⚠️ THIS IS THE DEMO REPOSITORY - NOT FOR PRODUCTION USE**

This repository contains the demo/sandbox version of the WSZLLP legal case management system. It is completely isolated from the production environment.

## Purpose

This demo environment is designed for:
- Client demonstrations
- Feature previews
- Testing new functionality
- Sales presentations
- Training sessions

## Key Differences from Production

| Aspect | Demo | Production |
|--------|------|------------|
| **Supabase Project** | qpwlklygmjgjtweaahxr | (separate) |
| **Data** | Sample/fake data only | Real client data |
| **Tyler E-Filing** | Staging API (RANSTAG) | Production API |
| **Vercel Project** | wszllp-demo | wszllp |
| **Demo Banner** | Visible | Hidden |
| **User Isolation** | Less strict | Full RLS enforcement |

## Quick Start

### Prerequisites
- Node.js 18+
- Docker Desktop (for local Supabase)
- Vercel CLI: `npm i -g vercel`
- Supabase CLI: `npm i -g supabase`

### Local Development

```bash
# Install dependencies
npm install

# Start local development server
npm run dev

# App runs at http://localhost:5178
```

### Environment Variables

Copy `.env.demo` and configure with demo Supabase credentials:

```bash
VITE_SUPABASE_URL=https://qpwlklygmjgjtweaahxr.supabase.co
VITE_SUPABASE_ANON_KEY=<demo-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<demo-service-role-key>
VITE_ENVIRONMENT=demo
```

### Database Setup

```bash
# Link to demo Supabase project
supabase link --project-ref qpwlklygmjgjtweaahxr

# Apply migrations
supabase db push

# Seed demo data
npm run demo:seed
```

### Deployment

```bash
# Deploy to Vercel demo project
npm run demo:deploy
```

## Demo Credentials

**URL:** https://wszllp-demo.vercel.app (after deployment)

**Demo User:**
- Email: `demo@wszllp.com`
- Password: `DemoPassword123!`

## Migration Strategy

This demo uses a **baseline migration** approach:
- Single baseline file (`00000000000000_baseline.sql`) contains core schema
- Stepwise migrations archived in `supabase/migrations_archive/`
- New features added via ordered migrations (columns → views → backfills → RLS)

## Safety Guardrails

✅ **SAFE:**
- Resetting demo database
- Modifying demo Supabase project
- Testing with fake data
- Sharing demo URL with clients

❌ **NEVER:**
- Use production Supabase credentials
- Deploy to production Vercel project
- Share service role keys publicly
- Mix demo and production data

## Documentation

- [Demo Setup Guide](docs/DEMO_SETUP_GUIDE.md)
- [Demo Quick Start](DEMO_QUICKSTART.md)
- [Security Guidelines](SECURITY.md)

## Support

For issues with the demo environment, check:
1. Vercel deployment logs: `vercel logs`
2. Supabase logs in dashboard
3. Local browser console for client errors

---

**Repository:** wszllp-demo (demo only)
**Production Repo:** wszllp (DO NOT MODIFY)
**Last Updated:** 2025-01-18
