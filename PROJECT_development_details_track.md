# EcoTrack - Project Architecture and AI Handoff

## Purpose and current scope

EcoTrack is a neighbourhood waste and recycling coordination system. It is a mobile/desktop/web client with a REST API backend. The intended user roles are:

- `neighbour` - household/community user.
- `restaurant_owner` - restaurant waste producer.
- `driver` - garbage collection driver.
- `recycling_manager` - recycling centre manager.

The project is **at the authentication foundation stage**. Registration, email OTP verification, login, password reset, token persistence, and role-based dashboard selection are implemented. The actual waste reporting, collection scheduling, recycling-management, and community-engagement modules are not implemented yet.

## Technology stack

| Layer | Technologies and techniques |
| --- | --- |
| Client | Flutter/Dart, Material 3 UI, `provider` (`ChangeNotifier`) for app/auth state, `http` for REST calls, `flutter_secure_storage` for token and cached user persistence. |
| Server | Node.js/CommonJS, Express 5 REST API, Mongoose/MongoDB persistence, JWT authentication, bcrypt password hashing, Nodemailer/Gmail email delivery, CORS, dotenv configuration. |
| Security/auth | Six-digit OTPs with a 10-minute expiration; bcrypt hash cost 12; seven-day JWTs; bearer-token middleware; user role validation. |
| Targets | Flutter Android, iOS, web, Windows, macOS, and Linux runner folders are present. Android uses Kotlin and Gradle; iOS/macOS use Swift/Xcode; Windows/Linux use CMake/C++. |

## Architecture and request flow

```text
Flutter screens
  -> AuthProvider (UI loading/error/user state)
  -> AuthService (authentication use cases)
  -> ApiService (JSON HTTP + optional Bearer token)
  -> Express /api/auth routes
  -> authController
  -> Mongoose User model / MongoDB

Registration or password reset additionally:
  authController -> generateOtp -> Nodemailer/Gmail -> user email
```

The client starts with a splash screen. It waits two seconds, reads the locally stored JWT, calls `GET /api/auth/me`, then navigates to the dashboard matching the returned user role. If this check fails, it opens login.

## Folder structure

```text
EcoTrack--Neighborhood-Waste-and-Recycling-Coordination-System-/
├── AI_PROJECT_HANDOFF.md              # This AI-ready project summary
├── ReadMe.md                          # Present but currently empty
├── backend_nodejs/
│   ├── .env                           # Local secrets/config; do not share or commit
│   ├── .gitignore
│   ├── package.json / package-lock.json
│   ├── server.js                      # Express entry point
│   ├── node_modules/                  # Installed packages; generated, not source
│   └── src/
│       ├── api/                       # Empty placeholder (.gitkeep)
│       ├── config/db.js
│       ├── controllers/authController.js
│       ├── middleware/authMiddleware.js
│       ├── models/User.js
│       ├── routes/authRoutes.js
│       ├── services/emailService.js
│       └── utils/generateOtp.js, generateToken.js
└── frontend_flutter/
    ├── pubspec.yaml / pubspec.lock    # Flutter package config and lockfile
    ├── analysis_options.yaml           # Flutter lint configuration
    ├── README.md                       # Default Flutter readme
    ├── test/widget_test.dart           # Default Flutter counter test; stale for this app
    ├── lib/                            # Hand-written Flutter application code
    │   ├── main.dart
    │   ├── config/                     # API URL and route constants
    │   ├── models/                     # Client data objects
    │   ├── providers/                  # Provider state classes
    │   ├── services/                   # HTTP, auth, encrypted storage
    │   ├── utils/                      # Validators and role constants
    │   ├── screens/                    # Auth, splash, and role dashboard UI
    │   ├── core/                       # Empty placeholder
    │   ├── shared/                     # Empty placeholder (.gitkeep)
    │   └── features/                   # Empty planned feature folders
    │       ├── collection_scheduling/
    │       ├── community engagement/   # Space in name: rename before using
    │       ├── recycling_management/
    │       └── waste_reporting/
    ├── android/, ios/, web/, windows/, macos/, linux/
    │                                  # Flutter platform runner/configuration files
    ├── .dart_tool/, build/             # Generated artifacts; do not edit or commit
    └── platform ephemeral folders      # Generated Flutter plugin files; do not edit
```

## Backend files and behaviour

| File | Responsibility |
| --- | --- |
| `backend_nodejs/server.js` | Loads environment variables, sets Cloudflare/Google DNS servers, enables CORS and JSON/form parsing, registers `/api/auth`, provides `GET /` health response, a JSON 404 handler, connects to MongoDB, then listens on `0.0.0.0:$PORT` (default 5000). |
| `src/config/db.js` | Connects Mongoose with `MONGO_URI`; exits the process if MongoDB cannot be reached. |
| `src/models/User.js` | Defines the only database entity: name, email, phone, hashed password, role, verification status, verification OTP/expiry, reset OTP/expiry, timestamps. |
| `src/routes/authRoutes.js` | Maps all public/protected auth HTTP endpoints to the controller. |
| `src/controllers/authController.js` | Implements input validation, registration, OTP handling, login, current-user lookup, and password reset business logic. |
| `src/middleware/authMiddleware.js` | `protect` validates `Authorization: Bearer <JWT>`, gets the verified user, and attaches it to `req.user`. `authorizeRoles(...roles)` is available but currently unused by any route. |
| `src/services/emailService.js` | Creates Gmail/Nodemailer transporter and sends HTML verification and password-reset OTP emails. |
| `src/utils/generateOtp.js` | Generates a six-digit numeric OTP. |
| `src/utils/generateToken.js` | Signs a JWT containing the user id and role; expiry is seven days. |
| `src/api/.gitkeep` and several other `.gitkeep` files | Keep otherwise empty planned directories in Git. They have no runtime behaviour. |

### Backend API contract

Base URL: `http://<server>:5000/api`

| Method + endpoint | Auth | Request body | Current result |
| --- | --- | --- | --- |
| `GET /` | No | — | Health JSON: API is running. |
| `POST /api/auth/register` | No | `name`, `email`, `password`, `role`, optional `phone` | Creates an unverified user, sends verification OTP, returns `requiresVerification: true`. |
| `POST /api/auth/verify-otp` | No | `email`, `otp` | Marks account verified and returns JWT plus user. |
| `POST /api/auth/resend-otp` | No | `email` | Sends a replacement verification OTP for an unverified user. |
| `POST /api/auth/login` | No | `email`, `password` | Requires verified account; returns JWT plus user. |
| `GET /api/auth/me` | Bearer JWT | — | Returns current user. |
| `POST /api/auth/forgot-password` | No | `email` | Emails a password-reset OTP to a verified user. |
| `POST /api/auth/verify-reset-otp` | No | `email`, `otp` | Checks reset OTP but does not issue a temporary reset token. |
| `POST /api/auth/reset-password` | No | `email`, `otp`, `newPassword` | Revalidates OTP, saves new bcrypt hash, and clears reset OTP. |

Valid backend roles are exactly `neighbour`, `restaurant_owner`, `driver`, and `recycling_manager`.

Required server environment variables (do **not** send their values to another AI): `MONGO_URI`, `JWT_SECRET`, `EMAIL_USER`, `EMAIL_PASS`; `PORT` is optional.

## Flutter files and behaviour

| File/group | Responsibility |
| --- | --- |
| `lib/main.dart` | App entry point. Registers one global `AuthProvider`, Material 3 green theme, and named routes for splash/login/register/forgot-password and four dashboards. |
| `lib/config/api_config.dart` | Builds API URLs. Web and desktop use `localhost:5000`; Android is hard-coded to `192.168.8.104:5000`. |
| `lib/config/app_routes.dart` | Route-name constants. Some constants are not registered in `main.dart`; see gaps below. |
| `lib/models/user_model.dart` | Client representation of a user. Accepts both `_id` and `id` from API JSON. Includes an optional `location` client field. |
| `lib/providers/auth_provider.dart` | Global auth loading/error/user state; delegates auth calls to `AuthService`; notifies listening widgets. |
| `lib/services/api_service.dart` | Reusable JSON `GET`/`POST` client. Adds stored bearer token for authenticated calls and turns API failures into exceptions. |
| `lib/services/auth_service.dart` | Thin client-side wrapper for register, OTP verification, login, reset-password flows, current-user fetch, logout and token check. On login, saves JWT and serialized user. |
| `lib/services/storage_service.dart` | Reads/writes/deletes the JWT and cached user in `flutter_secure_storage`. |
| `lib/utils/constants.dart` | One source of truth for role string constants/list. |
| `lib/utils/validators.dart` | Common required, email, password-length, and password-confirmation validators. |
| `lib/screens/splash/splash_screen.dart` | Restores authenticated session and pushes the appropriate role dashboard. |
| `lib/screens/auth/login_screen.dart` | Login form; uses `AuthProvider.login`, then routes by role. Links to registration and password reset. |
| `lib/screens/auth/register_screen.dart` | Registration form for name, email, phone, location, password, confirmation and role; then pushes OTP verification. |
| `lib/screens/auth/otp_verification_screen.dart` | Verifies registration OTP then returns to login. |
| `lib/screens/auth/forgot_password_screen.dart` | Requests password-reset OTP then opens reset-password screen. |
| `lib/screens/auth/reset_password_screen.dart` | Collects OTP and new password, calls reset API, then returns to login. |
| `lib/screens/auth/widgets/auth_text_field.dart` | Reusable styled form text field. |
| `lib/screens/auth/widgets/auth_button.dart` | Reusable full-width button with loading spinner/disabled state. |
| `lib/screens/auth/widgets/role_dropdown.dart` | Reusable validated dropdown displaying friendly role names. |
| `lib/screens/neighbour/neighbour_dashboard.dart` | Placeholder app bar and centre text only. |
| `lib/screens/restaurant/restaurant_dashboard.dart` | Placeholder app bar and centre text only. |
| `lib/screens/driver/driver_dashboard.dart` | Placeholder app bar and centre text only. |
| `lib/screens/recycling_manager/recycling_manager_dashboard.dart` | Placeholder dashboard plus a confirmation dialog that only deletes the saved token and navigates to `/login`. |

## Current implementation status

Implemented:

- MongoDB connection and `User` persistence.
- Email/password account creation with role choice.
- Verification OTP issuance, resend, expiration validation and verification.
- bcrypt password hashing and JWT login/session authentication.
- Forgot-password OTP and reset-password flow.
- Secure client token storage and splash-session restoration.
- Basic Material 3 authentication UI and role-based navigation.

Not implemented:

- Domain models/routes/screens for waste reports, bins, pickups, schedules, driver routes, recycling inventory/processing, community posts, notifications, analytics, maps, file/image uploads, or admin functions.
- Any real dashboard UI; all four dashboards are placeholders.
- Tests for backend auth or application features; the Flutter widget test is the default template and does not describe EcoTrack.
- Backend logout, refresh-token/revocation, global error middleware, rate limiting, production CORS policy, OTP attempt limiting, or role-protected feature APIs.
- UI assets, custom fonts, design system, localization, responsiveness rules, or a populated product README.

## Important integration gaps and constraints

1. `RegisterScreen` sends `location`, and `UserModel` exposes it, but `User` has no `location` schema field. Mongoose therefore does not persist or return it. Add it to the model/controller if the new UI needs location.
2. Flutter defines/calls `POST /api/auth/logout`, but the backend has no such endpoint. `AuthService.logout()` catches the resulting 404 and clears local storage, so the client still logs out locally. Prefer local logout or add a real server endpoint/token revocation design.
3. The client does not expose the backend `POST /api/auth/resend-otp` endpoint.
4. `AppRoutes.otp` and `AppRoutes.resetPassword` exist, but those routes are not registered in `main.dart`; these screens are currently opened with `MaterialPageRoute` instead.
5. Android API address is a private LAN IP (`192.168.8.104`) while web/desktop use localhost. Make this environment-configurable before team/device use. For an Android emulator, `10.0.2.2` normally reaches the host machine; a physical phone needs the host LAN IP.
6. `authorizeRoles` exists but is unused. Any new role-owned APIs should use `protect` followed by `authorizeRoles(...)`.
7. There is an empty feature directory named `community engagement` with a space. Use a Dart-safe directory such as `community_engagement` for new imports/files.
8. The `.env` file exists locally and must remain private. Never hard-code its credentials in Flutter or commit it.

## Recommended implementation conventions for the next AI

- Keep Flutter presentation in `lib/features/<feature>/presentation`, domain objects/use cases in `domain`, and API/repository/data classes in `data`; use snake_case folder/file names.
- Reuse `ApiService` for authenticated requests and add methods to feature services/repositories instead of placing HTTP calls directly in widgets.
- Use Provider consistently for screen state (loading, data, errors); do not introduce a second state-management library without a team decision.
- Add backend Mongoose models, controllers, and routes per feature. Mount each route in `server.js` under `/api/<feature>` and protect it with JWT/role middleware.
- Keep request/response fields aligned between Flutter models and Mongoose schemas. Update this document/API table whenever a contract changes.
- Preserve the role strings exactly unless both backend and client are migrated together.
- Build the supplied external UI designs as Flutter widgets, but connect actions to the existing auth/session flow rather than replacing it.

## Safe prompt to give another AI

> You are extending the EcoTrack Flutter + Node/Express/MongoDB project. Read `AI_PROJECT_HANDOFF.md` first and preserve its existing authentication architecture. Implement only the requested feature/UI files. Use Flutter Material 3, Provider, `ApiService`, `AuthService`, and `StorageService` conventions already in the repository. The existing role dashboards are placeholders. Do not modify `.env`, expose credentials, regenerate platform folders, or edit generated `build`, `.dart_tool`, `node_modules`, or ephemeral files. Before adding UI that needs data, identify whether its backend model/API exists; if it does not, add a matching protected backend contract or clearly mark the UI as mock data. Respect the listed integration gaps, particularly the current missing `location` persistence and logout endpoint.

## Local development commands

```powershell
# Backend (requires a valid local .env and MongoDB)
cd backend_nodejs
npm install
npm run dev

# Flutter client
cd frontend_flutter
flutter pub get
flutter run
flutter analyze
```
