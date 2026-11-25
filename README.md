# insure_plus

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase authentication

The app uses the existing Firebase configuration for Android and web. Enable
Email/Password sign-in in Firebase Authentication and apply the checked-in
Firestore rules to the corresponding Firebase project. Review any rules already
deployed for other modules before applying the combined ruleset.

New accounts are policyholders. Claim Management requires an Admin or
OperationsStaff Firebase Auth custom claim named role, assigned from a trusted
Admin SDK environment. Sign out and back in after assigning a role to pick up
the new token. The Firestore profile role field is retained for compatibility.
