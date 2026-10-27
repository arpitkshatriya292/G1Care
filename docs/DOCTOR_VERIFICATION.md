# Doctor Verification Architecture

## Role & Status Enforcement
Doctor access to patient records is strictly restricted to approved medical professionals.

### Doctor Verification States:
1. **PENDING**: Initial state upon registration. Scanning patient QR codes and accessing medical profiles is disabled.
2. **APPROVED**: Granted after medical registration number verification. Enables QR scanner and medical profile retrieval.
3. **REJECTED**: Registration details invalid or unverified. Access disabled.
4. **SUSPENDED**: License revoked or under compliance review. Access disabled.

## Hackathon Prototype Approval Simulator
For quick prototype testing in Android Studio without requiring a live admin web dashboard:
- Every Doctor user card / verification banner features a **Simulate Admin** button.
- Clicking **Simulate Admin** immediately toggles the doctor's `verificationStatus` between `PENDING` and `APPROVED`.
- The UI dynamically updates and unlocks/locks QR scanning capability accordingly.
