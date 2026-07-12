ASTRIDE Mobile Auth Fix v3.12.4

Fixed:
- Passenger app now uses POST /v1/auth/otp/request
- Passenger app stores sessionId and verifies with POST /v1/auth/otp/verify
- Passenger, Driver and Partner use the production ASTRIDE domain
- Mobile numbers are normalized to 91XXXXXXXXXX for OTP
- Real API/network errors are shown instead of only "Something went wrong"
- API clients safely handle non-JSON and connection errors
- Signed Release workflow now has an "all" option to build Passenger, Driver and Partner together

Apply in Termux:
1. Copy this ZIP into ~/ASTRIDE_MASTER
2. Run:
   cd ~/ASTRIDE_MASTER
   unzip -o ASTRIDE_MOBILE_AUTH_FIXED_v3.12.4.zip
   git add .
   git commit -m "Fix production OTP auth for all mobile apps"
   git push

Then GitHub Actions:
- ASTRIDE Android Signed Release
- app: all
- environment: production
- version: 3.12.4
- build_number: higher than previous build
