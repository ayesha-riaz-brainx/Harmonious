# Verification email setup (Gmail SMTP + Supabase)

Signup uses **Supabase Auth**, which sends mail through whatever SMTP you configure.
**Gmail works** — no Brevo required.

## 1. Create a Gmail App Password

Google blocks normal passwords for SMTP. Use an **App Password**:

1. Open [Google Account → Security](https://myaccount.google.com/security)
2. Turn on **2-Step Verification** (required)
3. Search for **App passwords** (or open [App passwords](https://myaccount.google.com/apppasswords))
4. Create one:
   - App: **Mail**
   - Device: **Other** → name it `Harmonious Supabase`
5. Copy the **16-character** password (spaces optional)

Use a dedicated Gmail if you can (e.g. `harmonious.app@gmail.com`), not your personal inbox long-term.

## 2. Paste into Supabase SMTP

Supabase → **Project Settings** → **Authentication** → **SMTP Settings**:

| Field | Value |
|-------|--------|
| Enable custom SMTP | **On** |
| Sender email | Your full Gmail address (same as username) |
| Sender name | `Harmonious` |
| Host | `smtp.gmail.com` |
| Port | `587` |
| Minimum interval | `60` (seconds) — avoids Gmail rate issues |
| Username | Your full Gmail address |
| Password | The **16-character App Password** (not your normal Gmail password) |

Save.

## 3. Confirm email + redirect URLs

**Authentication → Providers → Email**

- **Confirm email** = **ON**

**Authentication → URL Configuration**

Add redirect URLs:

- `https://harmonious.onrender.com/auth/email-confirmed`
- `https://harmonious.onrender.com/auth/reset-password`

Site URL can be: `https://harmonious.onrender.com`

## 4. Branded confirm template (required)

Paste `backend/email-templates/confirm-signup.html` into  
**Authentication → Email Templates → Confirm signup**.

That template uses `{{ .TokenHash }}` + `{{ .RedirectTo }}` (not a bare
`{{ .ConfirmationURL }}`) so email scanners cannot burn the one-time link.
On the Harmonious page, tap **Confirm my email**.

Deploy the latest backend to Render so `/auth/email-confirmed` is up to date,
and keep `SUPABASE_URL` + `SUPABASE_ANON_KEY` set on Render.

## 5. Test

1. Install the latest `releases/Harmonious.apk`
2. Sign up with a **new** email (or delete the old user under **Authentication → Users** first)
3. Check inbox **and spam** for mail from your Gmail address
4. Tap **Verify email address**

## Limits & tips

- Gmail free accounts: roughly **~100 emails/day** — fine for testing / early users
- If send fails: wrong password (must be App Password), 2FA off, or “Less secure apps” myths — ignore those; App Password is the correct path
- “Username and Password not accepted” → regenerate App Password and paste again (no spaces issues usually OK either way)
- For production at scale later, move to Resend / SendGrid / a real domain

## If mail still doesn’t arrive

1. Supabase → **Authentication → Users** — does the new user appear as **Waiting for verification**?
2. Gmail → **Sent** — did the message leave?
3. Recipient spam folder
4. Wait 1–2 minutes and tap **Resend** in the app (rate limits apply)
