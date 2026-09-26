# EcoTrack — Complete Project Development Tracker

**Project:** EcoTrack: Neighbourhood Waste & Recycling Coordination System
**Repository:** Flutter client + Node.js/Express REST API + MongoDB
**Last reviewed:** 24 September 2026
**Purpose:** Shareable project handover and living project memory. Update it in the same change set as every functional, API, dependency, data-model, setup, or platform change.

## Product summary

EcoTrack coordinates community waste collection and recycling. It links residents and restaurant owners who request collection, recycling managers who plan and assign work, drivers who complete routes, and community members who join environmental activities.

| Area | Current scope |
| --- | --- |
| Collection requests | Create, track, status-update, and cancel requests containing waste, quantity, address/map point, preferred time, notes, and optional image. |
| Operations | Manager request review, driver assignment, route creation and stop management/optimisation; driver dashboard, schedule, fixed-route and pickup flows. |
| Recycling management | Manager dashboard, waste, inventory, and assignment UI surfaces. Verify a matching backend workflow before presenting UI-only screens as complete. |
| Community | Posts/comments/likes, cleanup events, illegal-dumping reports, announcements, engagement and leaderboard data. |

## Roles

Exact role values are `neighbour`, `restaurant_owner`, `driver`, and `recycling_manager`. Keep them identical in Flutter, JWT middleware, and MongoDB.

| Role | Primary experience |
| --- | --- |
| Neighbour | Community hub, collection requests/tracking, illegal-dumping reports, feed, cleanup events, engagement, profile/location. |
| Restaurant owner | Restaurant dashboard and shared request/profile flows. |
| Driver | Dashboard metrics, availability, today's schedule, assigned fixed routes, pickup actions and profile. |
| Recycling manager | Dashboard, requests, available drivers, driver assignment, route planning/stop control/maps, waste/inventory UI. |

## Architecture

```text
Flutter (Android / iOS / Web / Windows / macOS / Linux)
  screens -> Provider state -> feature service -> ApiService
  -> JSON REST request + JWT bearer token
  -> Express route -> controller -> Mongoose model -> MongoDB

Email authentication: authController -> OTP generator -> Nodemailer/Gmail
```

| Layer | Technology |
| --- | --- |
| Client | Flutter/Dart, Material 3, Provider, `http`, `flutter_secure_storage` |
| Maps/location | `flutter_map`/OpenStreetMap, `latlong2`, `geolocator`, `url_launcher` |
| Server | Node.js, CommonJS, Express 5, Mongoose, MongoDB |
| Security | JWT, bcryptjs, email OTPs, bearer-token middleware |
| Email | Nodemailer/Gmail configured through environment variables |

## Repository map

```text
EcoTrack--Neighborhood-Waste-and-Recycling-Coordination-System-/
├── PROJECT_development_details_track.md  # living handover
├── ReadMe.md                             # public overview
├── backend_nodejs/
│   ├── server.js                         # Express startup/API mounts
│   └── src/{models,controllers,routes,middleware,services,utils,scripts}/
└── frontend_flutter/
    ├── lib/{config,models,providers,services,screens,shared}/
    └── android,ios,web,windows,macos,linux
```

Do not edit generated content such as `node_modules`, `.dart_tool`, `build`, or generated platform plugin registrants.

## Backend

### API groups

Base URL: `http://<host>:5000/api` by default.

| Base path | Responsibility |
| --- | --- |
| `/auth` | Registration, verification/resend OTP, login, current user, and password reset. |
| `/profile` | Authenticated profile read/update. |
| `/collection-requests` | Create request, list own/all, get one, update status, cancel. |
| `/manager` | Dashboard statistics, request list/detail, available drivers, driver assignment, and `GET /drivers/:driverId/location` for manager-only location polling. |
| `/manager/routes` | Route CRUD, stops, driver changes, schedule, suggested/optimised route sequencing. |
| `/driver` | `GET /dashboard` returns driver data, today's assigned pickup tasks, active routes, completion/cancellation counts, total collected weight, category-weight totals and progress. Also supports assigned routes, today's schedule, availability, pickup status, `POST /location` live-location updates, and `PATCH /routes/:routeId/stops/:stopId/status` driver-owned stop updates. |
| `/community/posts` | Posts, comments, likes, deletion. |
| `/community/events` | Cleanup-event list/detail/create, join and status updates. |
| `/community/announcements` | Announcement read/create/delete. |
| `/community/reports` | Illegal-dumping/community reports, votes, details and status. |
| `/community/engagement` | Current engagement, leaderboard, aggregate statistics. |

`GET /` is a health response; unmatched routes return JSON 404. Feature APIs should use `protect`; role-owned work should also use `authorizeRoles(...)`.

### Data models

| Model | Key responsibilities/data |
| --- | --- |
| `User` | Identity, role, verified/available state, profile/home location text/coordinates, separate `liveLocation` (`lat`, `lng`, `updatedAt`), credential and OTP fields. |
| `CollectionRequest` | Requester, waste type(s), quantity, description/image, address/coordinates, schedule, assignment, lifecycle/history, suggested route. |
| `Route` | Name/zone, date or operating days, area point, driver, ordered stops, active status, weekly waste-category schedule. |
| `DriverAssignment` | Request-to-driver link, assigner, status, time and notes. |
| `pickup` | Driver pickup task record and status. |
| `CommunityPost` | Author, content/image/tags, likes and comments. |
| `CleanupEvent` | Event/map details, participants, lifecycle and waste totals. |
| `CommunityReport`, `Announcement`, `UserPoints` | Community report workflow, announcements and gamification data. |

Collection-request statuses: `requested`, `accepted`, `scheduled`, `en_route`, `arrived`, `collected`, `cancelled`. Route-stop statuses: `pending`, `collected`, `skipped`.

### Backend rules

- Add model, controller, and route module for every new server feature; mount it in `server.js`.
- Validate IDs/inputs and derive the acting user from `req.user` rather than trusting client-supplied ownership IDs.
- Keep request/response fields aligned with Flutter models/services.
- Required `.env` values: `MONGO_URI`, `JWT_SECRET`, `EMAIL_USER`, `EMAIL_PASS`; `PORT` is optional. Never commit or share their values.

## Flutter

`main.dart` registers `AuthProvider`, `ManagerProvider`, and `DriverProvider`, Material 3 theming, and main named routes. Splash restores secure storage, validates the session with the API, and navigates by role.

| Layer | Convention |
| --- | --- |
| Screen | Widgets, navigation, dialog, interaction. |
| Provider | Observable data/loading/error state and service calls. |
| Service | API call/JSON-to-model mapping. |
| `ApiService` | JSON HTTP, JWT bearer header, shared error handling. |
| `StorageService` | Secure JWT and cached-user persistence. |
| `ApiConfig` | Endpoint constants and development host selection. |

Implemented screen groups include auth, profile/location picker, community hub/feed/events/reports/engagement, collection request flows, driver dashboard/schedule/pickup flows, and manager requests/routes/assignments/maps. Confirm backend support before declaring presentation-only inventory/waste screens complete.

### Driver route and map rules

Drivers receive a responsive dashboard from `GET /api/driver/dashboard`; it displays real daily counts, total collected waste, weights grouped by completed pickup `wasteType`, progress and today's tasks. Current collection requests use `estimatedQuantity` as the stored weight; legacy `Pickup` records use `weightKg`. Fixed routes come from `GET /api/driver/routes`. The Today's Route map uses OpenStreetMap, a blue marker for the driver's current GPS location, and route-stop markers coloured red (pending), green (collected), or grey (skipped). Opening this active route screen starts 15-second polling using `LocationService` and `POST /api/driver/location`; disposal stops the timer. Tapping a stop offers collected/skipped actions with optimistic UI state and backend confirmation via `PATCH /api/driver/routes/:routeId/stops/:stopId/status`. Managers can poll a driver's last saved location via `GET /api/manager/drivers/:driverId/location`.

### Platform notes

- Android includes internet, fine-location and coarse-location permissions.
- iOS has `NSLocationWhenInUseUsageDescription`; update it when location purpose changes.
- `ApiConfig` uses `10.0.2.2` for Android emulator and `localhost` for web/desktop. Physical devices require a reachable LAN/deployed API URL.

## Setup and validation

```powershell
# Backend
cd backend_nodejs
npm install
# create .env with required values
npm run dev

# Flutter
cd frontend_flutter
flutter pub get
flutter run
flutter analyze
```

```powershell
# Additional backend checks
cd backend_nodejs
node --check server.js
npm run seed:routes  # optional development seed
```

There is no meaningful automated backend test suite yet (`npm test` intentionally fails), and Flutter tests need feature coverage. Validate new work through API-contract, permission, empty/error-state and real-device map/location testing.

## Current priorities and risks

1. Add automated backend API tests and Flutter widget/integration tests for auth, request lifecycle, routes, and role permission.
2. Use environment-driven API URL and production HTTPS/CORS instead of local defaults.
3. Complete/reconcile inventory, waste and assignment UI with documented models and protected APIs.
4. Decide live-tracking implementation (polling/WebSocket), consent, retention, background execution and manager visibility.
5. Add production safeguards: request validation, rate/OTP limits, secure CORS, error middleware, logging and token-revocation/refresh policy.
6. Keep route stop order, request status, and driver assignments transactionally consistent.

## Change log

| Date | Change | Validation | Follow-up |
| --- | --- | --- | --- |
| 2026-09-24 | Replaced the obsolete authentication-only document with complete current architecture, feature, API, model, setup and handover guidance. | Repository routes, models, Flutter configuration and dependencies reviewed. | Update this row/table for every future change. |
| 2026-09-24 | Added polling-based live driver tracking and driver-owned route-stop status updates. | Backend syntax checks and Flutter formatting/analyzer run. | Decide production privacy/retention and manager map polling UI. |
| 2026-09-24 | Recreated the driver dashboard and corrected its dashboard API contract. | Backend route/controller and Flutter service/provider/dashboard reviewed and analysed. | Add automated API/widget tests with representative collection-request and legacy-pickup records. |

## Required update protocol

For every implementation change, update this document in the same commit/PR:

1. Add a dated **Change log** entry with the user-visible outcome and validation.
2. Update API groups for endpoint, authorization, request, or response changes.
3. Update data models for persisted fields, enums, indexes, or relationships.
4. Update Flutter details for a screen, navigation item, provider, service, dependency, or permission change.
5. Record migrations, environment variables, compatibility risks, and incomplete follow-ups.
6. Never document secrets, tokens, email credentials, real user data, or private host addresses.

### Handover prompt

> You are extending EcoTrack, a Flutter + Node/Express + MongoDB waste and recycling coordination system. Read `PROJECT_development_details_track.md` first. Preserve the role strings, Provider/service/API layering, authenticated backend patterns, and API/model alignment. Implement only the requested scope. Do not expose `.env` values, edit generated folders, or silently substitute mock data for missing APIs. Update this tracker and its change log in the same change set, then verify the changed code proportionately.
