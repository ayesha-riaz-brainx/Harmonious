# Harmonious email templates (Supabase)

Paste these HTML files into **Supabase → Authentication → Email Templates**.

They match the Harmonious dark UI (cyan accent, card surface, “Your life, understood.”).

| Template in Supabase | File | Suggested subject |
|----------------------|------|-------------------|
| Confirm signup | `confirm-signup.html` | Verify your Harmonious email |
| Reset password | `reset-password.html` | Reset your Harmonious password |
| Magic Link | `magic-link.html` | Your Harmonious sign-in link |
| Change Email Address | `change-email.html` | Confirm your new Harmonious email |

## Confirm signup (important)

`confirm-signup.html` uses **`{{ .TokenHash }}` + `{{ .RedirectTo }}`**, not a bare `{{ .ConfirmationURL }}`.

Why: Gmail/Outlook security scanners open confirmation links automatically and burn the one-time token. Users then see **“Link expired or invalid”**. Our link opens the Harmonious page first; the user taps **Confirm my email**.

After pasting the template, also set:

**Authentication → URL Configuration**

- Site URL: `https://harmonious.onrender.com`
- Redirect URLs must include:
  - `https://harmonious.onrender.com/auth/email-confirmed`
  - `https://harmonious.onrender.com/auth/reset-password`

Deploy the latest backend so `/auth/email-confirmed` serves the click-to-confirm page, and ensure Render has `SUPABASE_URL` + `SUPABASE_ANON_KEY` (used by `/auth/client-config.json`).

## Steps

1. Open the `.html` file and copy **all** contents.
2. In Supabase, open the matching template.
3. Paste into the body editor (HTML mode if available).
4. Set the subject from the table above.
5. Save. Send a test signup from the app.

For reset / magic / change-email templates:
- **Reset password:** paste `reset-password.html` (uses `{{ .TokenHash }}` + `{{ .RedirectTo }}`)
- Redirect URL must also include: `https://harmonious.onrender.com/auth/reset-password`
- Magic / change-email: keep their template variables as written in those files.
