# Forgot Password OTP Function

This function powers the custom forgot-password flow for the Flutter app.

## What it does

- Accepts `request_otp` with an email
- Finds the matching Appwrite Auth user
- Generates a 6-digit OTP
- Stores a hashed OTP in the user's `prefs`
- Sends the OTP email using Appwrite Messaging
- Accepts `reset_password` with `email + otp + password`
- Verifies the OTP and updates the Appwrite Auth password

## Appwrite Console setup

Create a new Appwrite Function with:

- Function ID: `forgot-password-otp`
- Runtime: `Node.js`
- Root directory: `functions/forgot_password_otp`
- Entrypoint: `src/main.js`
- Build command: `npm install`
- Execute access: `Any`

## Required function scopes

Enable these scopes for the function:

- `users.read`
- `users.write`
- `messaging.write`

## Required variables

Add this runtime variable:

- `OTP_HASH_SECRET`
  - Use a long random secret in production.

## Messaging requirement

Your Appwrite project must have an email provider configured in Messaging so `createEmail()` can send the OTP through SMTP/email.

## Request payloads

Request OTP:

```json
{
  "action": "request_otp",
  "email": "user@example.com"
}
```

Reset password:

```json
{
  "action": "reset_password",
  "email": "user@example.com",
  "otp": "123456",
  "password": "new-password-123"
}
```
