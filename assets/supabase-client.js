/* ==========================================================================
   Linkflow — shared Supabase client + session helpers
   Loaded as a classic <script> on every page that needs auth.
   Expects window.supabase from the @supabase/supabase-js UMD CDN bundle.
   ========================================================================== */

// TODO: paste real values from Supabase project (Settings → API)
const LF_SUPABASE_URL = 'https://YOUR-PROJECT-REF.supabase.co';
const LF_SUPABASE_ANON_KEY = 'YOUR-PUBLIC-ANON-KEY';

const lfSupabase = window.supabase.createClient(LF_SUPABASE_URL, LF_SUPABASE_ANON_KEY);

async function lfGetSession() {
  const { data } = await lfSupabase.auth.getSession();
  return data.session || null;
}

async function lfGetProfile() {
  const session = await lfGetSession();
  if (!session) return null;
  const { data, error } = await lfSupabase
    .from('profiles')
    .select('id, email, created_at, is_admin')
    .eq('id', session.user.id)
    .single();
  if (error) return null;
  return data;
}

async function lfRequireAuth(redirectTo = '/login/') {
  const session = await lfGetSession();
  if (!session) {
    window.location.replace(redirectTo);
    return null;
  }
  return session;
}

async function lfRequireAdmin(redirectTo = '/app/') {
  const session = await lfRequireAuth();
  if (!session) return null;
  const profile = await lfGetProfile();
  if (!profile || !profile.is_admin) {
    window.location.replace(redirectTo);
    return null;
  }
  return profile;
}

async function lfSignOut(redirectTo = '/') {
  await lfSupabase.auth.signOut();
  window.location.replace(redirectTo);
}
