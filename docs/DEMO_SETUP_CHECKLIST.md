# Demo Environment Setup Checklist

Use this checklist when setting up your demo environment for the first time.

## Pre-Setup

- [ ] Have Vercel account access
- [ ] Have Supabase account access
- [ ] Have Tyler e-filing demo/staging credentials
- [ ] Vercel CLI installed: `npm i -g vercel`
- [ ] Supabase CLI installed: `npm i -g supabase`

## 1. Supabase Demo Project

- [ ] Created new Supabase project named `wszllp-demo`
- [ ] Noted down Project URL
- [ ] Noted down `anon` public key
- [ ] Noted down `service_role` secret key
- [ ] Stored credentials securely (password manager)

## 2. Environment Configuration

- [ ] Updated `.env.demo` with Supabase URL
- [ ] Updated `.env.demo` with anon key
- [ ] Updated `.env.demo` with service role key
- [ ] Updated `.env.demo` with Tyler e-filing credentials
- [ ] Verified all values are correct (no typos)

## 3. Database Setup

- [ ] Linked Supabase CLI to demo project: `supabase link`
- [ ] Applied all migrations: `supabase db push`
- [ ] Verified tables exist in Supabase Table Editor
- [ ] Checked RLS policies are active

## 4. Demo Data

- [ ] Ran seed script: `npm run demo:seed`
- [ ] Verified seed script completed successfully
- [ ] Noted demo user credentials from output
- [ ] Verified data appears in Supabase Table Editor:
  - [ ] Cases table has 3 entries
  - [ ] Contacts table has 3 entries
  - [ ] Hearings table has 1 entry

## 5. Vercel Project Setup

- [ ] Ran `npm run demo:setup` (or manual `vercel` command)
- [ ] Created new project (NOT linked to existing)
- [ ] Project name: `wszllp-demo`
- [ ] Added environment variable: `VITE_ENVIRONMENT` = `demo`
- [ ] Added environment variable: `VITE_SUPABASE_URL`
- [ ] Added environment variable: `VITE_SUPABASE_ANON_KEY`
- [ ] Added environment variable: `SUPABASE_SERVICE_ROLE_KEY`
- [ ] Added environment variable: `VITE_EFILE_USERNAME`
- [ ] Added environment variable: `VITE_EFILE_PASSWORD`
- [ ] Added environment variable: `VITE_EFILE_CLIENT_TOKEN`
- [ ] Added environment variable: `VITE_EFILE_BASE_URL`

## 6. Deploy

- [ ] Deployed to production: `vercel --prod`
- [ ] Deployment succeeded
- [ ] Noted deployment URL
- [ ] Verified URL is accessible in browser

## 7. Testing

- [ ] Visited demo URL
- [ ] Login page loads correctly
- [ ] Logged in with demo credentials
- [ ] Dashboard loads
- [ ] Sample cases are visible
- [ ] Sample contacts are visible
- [ ] Sample hearing is visible
- [ ] Tested creating a new case
- [ ] Tested uploading a document
- [ ] Tested scheduling a hearing
- [ ] All features work as expected

## 8. Documentation

- [ ] Documented demo URL
- [ ] Documented demo credentials
- [ ] Stored credentials in password manager
- [ ] Created internal notes about demo environment
- [ ] Added demo URL to client communication materials

## 9. Optional Enhancements

- [ ] Added custom domain (e.g., `demo.wszllp.com`)
- [ ] Updated DNS records
- [ ] Verified SSL certificate provisioned
- [ ] Added "DEMO MODE" banner to UI
- [ ] Set up analytics tracking
- [ ] Created multiple demo user accounts for different clients

## 10. Client Communication

- [ ] Prepared client demo instructions
- [ ] Tested demo flow from client perspective
- [ ] Prepared FAQ for common demo questions
- [ ] Ready to share demo URL with clients

---

## Ongoing Maintenance

### Monthly Tasks

- [ ] Check demo environment is still accessible
- [ ] Verify demo data hasn't been corrupted
- [ ] Remove old/expired client demo accounts
- [ ] Update demo environment with latest code
- [ ] Review analytics to see demo usage

### Before Each Client Demo

- [ ] Test demo login
- [ ] Verify sample data is intact
- [ ] Check for any bugs or issues
- [ ] Prepare demo walkthrough script
- [ ] Test on multiple devices/browsers

### After Each Client Demo

- [ ] Gather client feedback
- [ ] Note any issues encountered
- [ ] Update demo data if needed
- [ ] Reset demo environment if necessary

---

## Troubleshooting Reference

| Issue | Solution |
|-------|----------|
| Can't login | Verify user exists in Supabase Auth |
| No data showing | Re-run `npm run demo:seed` |
| 500 errors | Check Vercel logs with `vercel logs` |
| RLS blocking access | Verify migrations ran: `supabase db push` |
| Build fails | Check environment variables are set |
| Tyler e-filing errors | Verify using staging credentials, not production |

---

**Setup Date:** _________________

**Demo URL:** _________________

**Demo Credentials:** (stored in password manager)

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
