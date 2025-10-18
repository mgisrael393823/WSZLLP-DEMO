# 🎯 Demo Environment - Quick Start

This is a **TL;DR** version for setting up your client demo environment. For full details, see [docs/DEMO_SETUP_GUIDE.md](docs/DEMO_SETUP_GUIDE.md).

## What You're Creating

A **completely separate** Vercel deployment with its own:
- Supabase database (isolated from production)
- Demo user credentials
- Sample case data
- Unique URL for client demos

## Quick Setup (10 minutes)

### 1. Create Demo Supabase Project

1. Go to https://supabase.com/dashboard → **New Project**
2. Name: `wszllp-demo`
3. Save the credentials (URL + keys)

### 2. Update `.env.demo`

```bash
# Edit .env.demo with your demo Supabase credentials
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbG...
SUPABASE_SERVICE_ROLE_KEY=eyJhbG...
```

### 3. Run Database Migrations

```bash
# Link to demo project
supabase link --project-ref YOUR_DEMO_PROJECT_ID

# Apply schema
supabase db push
```

### 4. Seed Demo Data

```bash
npm run demo:seed
```

This creates:
- Demo user: `demo@wszllp.com` / `DemoPassword123!`
- 3 sample cases
- Sample contacts and hearings

### 5. Deploy to Vercel

```bash
npm run demo:setup
```

Follow the prompts to create a new Vercel project and add environment variables.

Then deploy:

```bash
npm run demo:deploy
```

### 6. Share with Client

Your demo is now live at: `https://wszllp-demo.vercel.app`

**Client Credentials:**
- Email: `demo@wszllp.com`
- Password: `DemoPassword123!`

---

## Quick Commands

| Command | Purpose |
|---------|---------|
| `npm run demo:setup` | Initial Vercel project setup |
| `npm run demo:seed` | Populate with sample data |
| `npm run demo:deploy` | Deploy updates to demo |

---

## Next Steps

- ✅ Test the demo yourself first
- ✅ Verify sample data appears
- ✅ Share URL with client
- ✅ Consider adding custom domain (e.g., `demo.wszllp.com`)

---

## Troubleshooting

**Issue:** "Invalid credentials"
→ Check `.env.demo` has correct Supabase values

**Issue:** No data showing
→ Run `npm run demo:seed` again

**Issue:** Deployment fails
→ Check `vercel logs` and verify all env vars are set

---

## Support

Full guide: [docs/DEMO_SETUP_GUIDE.md](docs/DEMO_SETUP_GUIDE.md)
