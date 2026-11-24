# Insure-Plus — Hybrid Firebase + Supabase

Member 04 — Motor Claims Developer

## Backend design

- **Firebase Authentication:** user identity and Firebase UID.
- **Supabase PostgreSQL:** shared `public.claims` table for claim data.
- **Supabase Storage:** the project's existing private `claim-documents` bucket for accident photos and supporting documents. No separate Motor Claims bucket is required.
- **Authorization:** Firebase ID tokens are passed to Supabase through the Supabase Flutter client's `accessToken` callback. Supabase must trust the Firebase project as a Third-Party Auth provider. Row Level Security checks the Firebase issuer, audience and claim owner's UID.
- Firebase ID tokens without a custom `role` claim use the Supabase `anon` role. The migration grants only the necessary operations to `anon` and `authenticated`, protected by restrictive Firebase issuer/audience checks plus UID-based ownership policies.
- No Firebase Firestore or Firebase Storage service is used by the migrated Motor Claims feature.

## Current setup status

- This repository's previous setup notes record that the first migration created `public.claims`, the follow-up migration was run against the existing private `claim-documents` bucket, and an extra empty `motor-claim-documents` bucket was removed. Preserve the original object(s) in `claim-documents`.
- A read-only request to the live Supabase REST endpoint for `public.claims` returned HTTP 200. No demo claim records were inserted; the app shows the intended empty state when a user has no claims.
- The Storage bucket administration endpoint could not independently verify the private bucket using the publishable key. The Flutter code uses only the existing private `claim-documents` bucket; no bucket was created by this session.
- Firebase Third-Party Auth and Firebase Anonymous sign-in were recorded as configured in the previous setup notes, but their Firebase/Supabase dashboard settings were not independently re-checked in this session.
- The updated Dart UI passes all 11 Flutter tests. `flutter analyze --no-pub --no-fatal-infos` reports no errors; info-only Flutter deprecation/style notices remain.
- A fresh debug APK was built with `--target-platform android-x64 --dart-define-from-file=supabase_config.json`, installed, and launched successfully on the Android 17 x86_64 emulator. The InsureCare home screen and Motor Claim submission form were inspected; no runtime crash or layout overflow appeared in the final log/screenshot checks.
- Local build compatibility note: this device's cached `jni 1.2.1` Android Gradle script needed its `ndkVersion` set to the installed `28.2.13676358`. That edit is in the local Pub cache only and is not committed in this repository. A clean development machine should verify its NDK/Gradle setup when building.

## 1. Configure Supabase

1. In **Authentication → Third-Party Auth**, add or verify the **Firebase** provider with Firebase project ID `insure-plus`.
2. Expected issuer: `https://securetoken.google.com/insure-plus`; audience: `insure-plus`.
3. The first SQL migration creates the `public.claims` table and configures RLS.
4. In **SQL Editor → New Query**, run `supabase/migrations/202611240002_reuse_existing_claim_documents_bucket.sql`.
5. Confirm there is only one relevant Motor Claims storage bucket: `claim-documents`. The bucket remains private; the migration applies a 10 MB limit and allowed MIME types.
6. Never use a secret/service-role key in the Flutter app.

## 2. Configure the Flutter app

Copy `supabase_config.json.example` to `supabase_config.json`, then fill in the project URL and Publishable key.

Run PowerShell from the project folder:

```powershell
flutter pub get
flutter run --dart-define-from-file=supabase_config.json
```

The config file is ignored by Git. Never commit credentials.

To build a debug APK with the same configuration:

```powershell
flutter build apk --debug --dart-define-from-file=supabase_config.json
```

## 3. Firebase requirements

- Firebase project ID must remain `insure-plus` because it is registered as the Supabase third-party JWT issuer.
- The current app uses anonymous Firebase sign-in until a full sign-in screen is added. In Firebase Console → Authentication → Sign-in method, enable **Anonymous** sign-in before testing.
- The app uses the real Firebase Authentication service. Local Firebase Auth emulator tokens are not used with Supabase.
- Keep `android/app/google-services.json` and the generated `lib/firebase_options.dart` for the existing Firebase project.

## 4. Data and file security

- Users can read their own claims only.
- New claims must be submitted with the `Submitted` status.
- Owners can edit claim details, but cannot change claim ownership, ID, type, creation time, status, or approved amount.
- A trusted backend may issue a Firebase custom `admin: true` claim for authorized staff. Do not create admin claims from the Flutter app.
- Only claim owners can read, upload, or delete files within their Firebase UID folder in the existing `claim-documents` bucket.
- The bucket is private; the Flutter app creates one-hour signed URLs when a file is opened.
- Maximum file size is 10 MB and MIME types are restricted by the follow-up migration.

## 5. Shared claim schema

The required common fields are preserved: `claimId`, `userId`, `policyId`, `claimType`, `claimAmount`, `description`, `status`, `documents`, and `createdAt`.

Allowed statuses only: `Submitted`, `UnderReview`, `MoreInfoRequired`, `Approved`, `Rejected`.

Each document keeps: `documentId`, `documentType`, `fileName`, `fileUrl` (private Supabase object path), and `uploadedAt`.

## 6. Important current limitation

The Flutter client deliberately cannot approve or reject claims itself. Claim status/approved amount changes require a trusted administrator token and trusted backend workflow; client-side status edits are blocked by database protection policies.
