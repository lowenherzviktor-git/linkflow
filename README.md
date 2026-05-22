# Linkflow

AI-powered LinkedIn operating system. Live at https://lf.l1advisory.com/.

## Stack

- Static HTML, no build step
- GitHub → Vercel auto-deploy from `main`
- Supabase (auth + Postgres + RLS) as the backend
- IBM Plex Sans, palette ported from `lss.l1advisory.com`

## Layout

```
index.html              public landing
login/index.html        sign in / sign up (toggle)
app/index.html          user dashboard (auth-gated)
admin/index.html        user list + admin toggle (admin-gated, RLS-enforced)
assets/styles.css       shared design tokens, scoped under .lf-page
assets/supabase-client.js  createClient + requireAuth/requireAdmin/signOut
supabase-schema.sql     one-paste schema + RLS policies for the Supabase SQL editor
vercel.json             cleanUrls + trailingSlash
```

## Edit / deploy flow

```bash
# edit any file
git add <files>
git commit -m "..."
git push
# Vercel auto-deploys main within ~30s
```

## Configuration

Two secrets live in `assets/supabase-client.js`:

- `LF_SUPABASE_URL` — Supabase project URL (Settings → API)
- `LF_SUPABASE_ANON_KEY` — public anon key (Settings → API, NOT the service role key)

Both are safe to embed in client JS. RLS is the security boundary.

## Supabase setup

1. Create project `linkflow`, region `eu-central-1`.
2. SQL editor → paste `supabase-schema.sql` → run.
3. Authentication → URL Configuration:
   - Site URL: `https://lf.l1advisory.com`
   - Redirect URLs: `https://lf.l1advisory.com/**`
4. Authentication → Email Templates: replace `localhost` links with `https://lf.l1advisory.com/...`.
5. Authentication → Providers: Email on; everything else off for MVP.
6. Sign up Viktor's account via the live login page (or Authentication → Users → Add user).
7. SQL editor: `update profiles set is_admin = true where email = 'lowenherzviktor@gmail.com';`
8. Settings → API: copy Project URL + anon key → paste into `assets/supabase-client.js`, commit, push.

## DNS

Cloudflare zone `l1advisory.com`:

- `lf` CNAME → Vercel-provided target
- **Gray cloud (DNS only).** Orange cloud breaks Vercel TLS.

## Verification

End-to-end smoke test:

1. `curl -I https://lf.l1advisory.com` → 200, valid cert.
2. Sign up with a throwaway email → redirected to `/app/` → three "Coming soon" cards visible.
3. Sign out, sign in as Viktor → `/admin/` loads, user list shows all accounts.
4. As the throwaway user, manually load `/admin/` → bounced to `/app/`. In devtools `lfSupabase.from('profiles').select('*')` returns only own row.
5. Toggle the throwaway's admin bit on/off → persists on reload.

## Out of scope (v1)

- Real LinkedIn API integration (deferred to v2, will use Supabase Edge Functions for OAuth)
- Module internals (ship as "Coming soon" placeholders)
- Billing, audit log, password-reset UI, n8n integration
