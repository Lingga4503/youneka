# Firebase AI + Premium Setup

Youneka now uses a server-enforced AI flow:

- Flutter app -> Firebase Auth
- Flutter app -> Callable Cloud Functions
- Cloud Functions -> Gemini API
- Firestore -> user plan, quota, and subscription state
- Google Play Billing -> premium activation

## Flutter dependencies already wired

- `firebase_core`
- `firebase_app_check`
- `firebase_auth`
- `cloud_firestore`
- `cloud_functions`
- `in_app_purchase`

## Firebase Console Checklist

### 1. Firebase Auth

- Enable `Google` sign-in provider.
- Add Android SHA fingerprints for your debug and release keys.
- Download the latest `google-services.json` again if Firebase adds OAuth clients.

### 2. Firestore

- Create a Firestore database in production mode.
- Deploy `firestore.rules` from this repo.

### 3. Cloud Functions

- Deploy the `functions/` folder.
- Required environment variables:

```bash
GEMINI_API_KEY=...
MENTOR_AI_MODEL=gemini-2.5-flash
GOOGLE_PLAY_PACKAGE_NAME=com.vigioapps.youneka
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON={...full service account json...}
```

Recommended example:

```bash
firebase functions:config:unset unused
firebase deploy --only functions,firestore:rules
```

If you prefer `.env` with the Functions framework, keep the same variable names.

### 4. App Check

- Android debug build: add the debug token shown in logcat to Firebase App Check.
- Android release build: register release SHA-256 and keep Play Integrity enabled.
- Keep App Check `Registered (Unenforced)` during active dev if needed.
- Enforce App Check after release signing and production testing are stable.

### 5. Google Play Billing

- Create one monthly subscription:
  - `youneka_ai_premium_monthly`
- Price:
  - `Rp33.000 / bulan`
- Link Play Console and service account access so Cloud Functions can verify purchases.

## Product Defaults

- Free plan: `10 chat / hari`
- Premium plan: `500 chat / bulan`
- Reset timezone: `Asia/Jakarta`

## Important runtime notes

- Premium is enforced server-side by callable Cloud Functions.
- Client Firestore reads are read-only; users cannot upgrade plan from the app directly.
- If Functions are not deployed yet, the app can still show account state, but production mentor chat will not be fully usable.
