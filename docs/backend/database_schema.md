# Insure-Plus – Firestore Database Schema

## 1. Users Collection

**Collection name:** `users`

**Document ID:** Firebase Authentication UID

| Field       | Data Type | Description                    |
|-------------|-----------|--------------------------------|
| fullName    | String    | User's full name               |
| email       | String    | User's email address           |
| phoneNumber | String    | User's contact number          |
| role        | String    | User's system role             |
| createdAt   | Timestamp | Account creation date and time |

**Default role:** `Policyholder`

**Important rules:**
- New users receive the `Policyholder` role automatically.
- Users cannot assign or change their own role.
- Only authorized administrators can assign elevated roles.
- Passwords must not be stored in Firestore. Firebase Authentication manages passwords.

## 2. Claims Collection

**Collection name:** `claims`

**Document ID:** Unique Claim ID (e.g. `CLAIM001`)

| Field       | Data Type | Description                      |
|-------------|-----------|----------------------------------|
| claimId     | String    | Unique claim identifier          |
| userId      | String    | Firebase UID of the policyholder |
| policyId    | String    | Related insurance policy ID      |
| claimType   | String    | Medical or Motor                 |
| claimAmount | Number    | Requested claim amount           |
| description | String    | Claim description                |
| status      | String    | Current claim status             |
| documents   | Array     | Uploaded document metadata       |
| createdAt   | Timestamp | Claim submission date and time   |

**Allowed claim statuses:**
- `Submitted`
- `UnderReview`
- `MoreInfoRequired`
- `Approved`
- `Rejected`

### Document Metadata

Each item in the `documents` array should contain:

| Field       | Data Type | Description                |
|-------------|-----------|----------------------------|
| documentId  | String    | Unique document identifier |
| documentType| String    | Type of uploaded document  |
| fileName    | String    | Original file name         |
| storagePath | String    | Supabase Storage file path |
| uploadedAt  | Timestamp | Upload date and time       |

**Storage:** Supabase Storage (`claim-documents` bucket)

**Security:** The bucket is private. Files should not be exposed through unrestricted public URLs.