const nodemailer = require('nodemailer');

function apiToken() {
  return (process.env.MAILTRAP_API_TOKEN || '').trim();
}

function smtpHost() {
  return (
    (process.env.SMTP_HOST || '').trim() ||
    (process.env.MAILTRAP_HOST || '').trim()
  );
}

function smtpUser() {
  return (
    (process.env.SMTP_USER || '').trim() ||
    (process.env.MAILTRAP_USER || '').trim()
  );
}

function smtpPass() {
  return (
    (process.env.SMTP_PASS || '').trim() ||
    (process.env.MAILTRAP_PASS || '').trim()
  );
}

function smtpConfigured() {
  const pass = smtpPass();
  return Boolean(
    smtpHost() &&
      smtpUser() &&
      pass &&
      !pass.includes('PASTE_'),
  );
}

function mailConfigured() {
  return Boolean(apiToken()) || smtpConfigured();
}

function parseFrom(fromRaw) {
  const raw =
    (fromRaw || '').trim() || 'Harmonious <hello@demomailtrap.com>';
  const match = raw.match(/^(.*)<([^>]+)>$/);
  if (match) {
    return {
      name: match[1].trim().replace(/^"|"$/g, '') || 'Harmonious',
      email: match[2].trim(),
    };
  }
  return { name: 'Harmonious', email: raw };
}

function createTransport() {
  const host = smtpHost() || 'sandbox.smtp.mailtrap.io';
  const port = Number(
    process.env.SMTP_PORT || process.env.MAILTRAP_PORT || 587,
  );
  const secure =
    String(process.env.SMTP_SECURE || '').toLowerCase() === 'true' ||
    port === 465;

  return nodemailer.createTransport({
    host,
    port,
    secure,
    auth: {
      user: smtpUser(),
      pass: smtpPass(),
    },
  });
}

function passwordResetHtml({ code, email }) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Reset your Harmonious password</title>
</head>
<body style="margin:0;padding:0;background:#0E0E12;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#F4F2F8;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#0E0E12;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width:520px;background:#17171D;border:1px solid #2A2A35;border-radius:20px;overflow:hidden;">
          <tr>
            <td style="padding:28px 28px 8px 28px;">
              <div style="font-size:13px;letter-spacing:0.12em;text-transform:uppercase;color:#A78BFA;font-weight:700;">Harmonious</div>
              <h1 style="margin:12px 0 0;font-size:24px;line-height:1.3;color:#FFFFFF;">Reset your password</h1>
              <p style="margin:14px 0 0;font-size:15px;line-height:1.6;color:#B7B3C5;">
                We received a request to reset the password for <strong style="color:#F4F2F8;">${email}</strong>.
                Use this one-time code in the app:
              </p>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding:18px 28px;">
              <div style="display:inline-block;padding:16px 28px;border-radius:14px;background:linear-gradient(135deg,#7C6AF0,#5B8DEF);font-size:32px;letter-spacing:0.28em;font-weight:800;color:#FFFFFF;">
                ${code}
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 28px 28px;">
              <p style="margin:0;font-size:14px;line-height:1.6;color:#B7B3C5;">
                This code expires in <strong style="color:#F4F2F8;">15 minutes</strong>.
                If you didn’t request a password reset, you can ignore this email.
              </p>
              <p style="margin:18px 0 0;font-size:12px;color:#7E7A8C;">
                Sent by Harmonious · Your life, understood.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
}

function passwordResetText({ code, email }) {
  return `Harmonious password reset

We received a request to reset the password for ${email}.

Your one-time code: ${code}

This code expires in 15 minutes.
If you didn’t request this, ignore this email.`;
}

async function sendViaApi({ to, code }) {
  const token = apiToken();
  const from = parseFrom(process.env.MAIL_FROM);
  const inboxId = (process.env.MAILTRAP_INBOX_ID || '').trim();
  const useSandbox =
    String(process.env.MAILTRAP_USE_SANDBOX || '').toLowerCase() === 'true' ||
    Boolean(inboxId);

  const url = useSandbox
    ? `https://sandbox.api.mailtrap.io/api/send/${inboxId}`
    : 'https://send.api.mailtrap.io/api/send';

  if (useSandbox && !inboxId) {
    const error = new Error(
      'MAILTRAP_INBOX_ID is required for sandbox API sending. Find it in Mailtrap → Email Testing → inbox URL.',
    );
    error.status = 503;
    error.code = 'MAIL_NOT_CONFIGURED';
    throw error;
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from,
      to: [{ email: to }],
      subject: 'Your Harmonious password reset code',
      text: passwordResetText({ code, email: to }),
      html: passwordResetHtml({ code, email: to }),
      category: 'Password Reset',
    }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message =
      body?.errors?.[0] ||
      body?.error ||
      body?.message ||
      `Mailtrap API failed (${response.status})`;
    const error = new Error(
      typeof message === 'string' ? message : JSON.stringify(message),
    );
    error.status = 502;
    throw error;
  }
}

async function sendViaSmtp({ to, code }) {
  const from =
    (process.env.MAIL_FROM || '').trim() ||
    'Harmonious <hello@harmonious.test>';
  const transporter = createTransport();
  await transporter.sendMail({
    from,
    to,
    subject: 'Your Harmonious password reset code',
    text: passwordResetText({ code, email: to }),
    html: passwordResetHtml({ code, email: to }),
  });
}

async function sendPasswordResetEmail({ to, code }) {
  if (!mailConfigured()) {
    const error = new Error(
      'Email is not configured. Set SMTP_HOST/SMTP_USER/SMTP_PASS (or Mailtrap) in backend/.env',
    );
    error.status = 503;
    error.code = 'MAIL_NOT_CONFIGURED';
    throw error;
  }

  // Prefer generic SMTP (Resend/SendGrid/etc.) when configured; else Mailtrap API.
  if (smtpConfigured() && !apiToken()) {
    await sendViaSmtp({ to, code });
    return;
  }

  if (apiToken()) {
    await sendViaApi({ to, code });
    return;
  }

  await sendViaSmtp({ to, code });
}

module.exports = {
  mailConfigured,
  sendPasswordResetEmail,
};
