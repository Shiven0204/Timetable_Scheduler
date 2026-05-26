# Timetable Scheduler

Flutter application for **institute timetable management**: master data (departments, programs, faculty, subjects, rooms), **subject–faculty–room mappings** per program, configurable weekly grid, **automated timetable generation**, and **Firestore-backed** views for students, faculty, and calendar.

---

## 1. Project overview

Administrators configure the institute, map each subject to a faculty member and **rooms** (classroom for theory, and when applicable a **separate lab room**), then generate a weekly timetable that respects **credit-based theory counts**, **one weekly 2-period lab block** for combined courses, **daily theory limits**, **faculty availability**, and **room conflicts**. Generated slots are stored in Firestore and shown across dashboard, student, faculty, and calendar screens.

---

## 2. Features

- **Firebase Authentication** (email / password): sign-in validation, loading state, mapped error messages; **session persistence** via `authStateChanges()`; **sign out** from the dashboard app bar
- **Firestore** for institute data and generated timetables
- Admin dashboard (quick actions: My Timetables, Calendar)
- **Basic Information** hub: timetable metadata, academic session, bell schedule, working days, periods & breaks (first config step before generation)
- Overview hub: data setup, lecture configuration, generate timetable, navigation to views
- CRUD-style flows: departments, programs, faculty, subjects, rooms, **mappings (theory room + optional lab room)**
- Timetable configuration (`working_days`, `periods_per_day`, etc.)
- **Timetable engine**: lab scheduling → theory scheduling → **persist** flat `timetable` documents
- **Student timetable** (by program), **faculty schedule** (by faculty), **calendar grid** (by program)
- Shared UI helpers: name resolution, `TimetableGrid` widget

---

## 3. Architecture

| Layer | Responsibility |
|--------|----------------|
| **Screens** | Material UI, forms, navigation (`lib/screens/`) |
| **Auth** | `AuthGate` (`lib/widgets/auth_gate.dart`) — root listens to `FirebaseAuth.instance.authStateChanges()`; signed-in users see `DashboardScreen`, others see `LoginScreen` |
| **Routes** | Named routes in `lib/routes/app_routes.dart`, registered in `main.dart` (app `home` is `AuthGate`, not `/login`) |
| **Services** | `DatabaseService` (writes), `BasicInformationService` (timetable-level config), `TimetableService` (read config, prepare data, schedule, save), `TimetableNameResolver` / helpers for UI |
| **Models** | `BasicInformation`, `ScheduleSlot`, `AcademicSession` (`lib/models/`) |
| **Utils** | `RoomTypeUtils` (`lib/utils/room_type_utils.dart`), `messageForFirebaseAuth` (`lib/utils/auth_error_messages.dart`) |
| **Widgets** | `TimetableGrid`, `AuthGate`, shared layout pieces (`lib/widgets/`) |
| **Firebase** | `firebase_options.dart`, **Authentication** (email/password), Firestore collections listed below |

---

## 4. Tech stack

- **Flutter** (Material 3–friendly UI)
- **Firebase Core + Cloud Firestore + Firebase Auth**
- **Dart** analyzer–clean codebase target for touched modules

---

## 5. Authentication

- **Sign-in**: `LoginScreen` → Firebase Auth → load `users/{uid}` → role-based home (see **`docs/FIREBASE_TEST_USERS.md`** for test accounts).
- **Roles**: `admin` → `DashboardScreen`; `faculty` → `FacultyScheduleScreen`; `student` → `ViewTimetableScreen`.
- **Session**: `AuthGate` listens to `authStateChanges()`, fetches profile, routes by role; missing profile shows setup screen with UID.
- **Sign-out**: `LogoutAppBarAction` / `AuthService.signOut()` — `AuthGate` returns to login (no back-stack bypass).
- **Test users** (create in Firebase Console, not in app code):

| Email | Password | Firestore `role` |
|-------|----------|------------------|
| `admin@timetable.com` | `Admin@123` | `admin` |
| `faculty@timetable.com` | `Faculty@123` | `faculty` |
| `student@timetable.com` | `Student@123` | `student` |

Document id for each: **Authentication User UID** in collection `users`.

Firestore **security rules** should allow authenticated users to read their own `users/{uid}` document (see `docs/FIREBASE_TEST_USERS.md`).

---

## 6. Firebase collections (typical)

| Collection | Purpose |
|------------|---------|
| `Department` | Departments (`dept_name`) |
| `Programs` | Programs (`name`, `short_name`, optional `student_count`; legacy mirrors: `program_name`, `branch_name`) |
| `Faculty` | Faculty (`full_name`, `short_name`, `max_lectures_per_day`, `availability`, optional `email` / `role` / `phone` / `designation`; legacy mirror: `faculty_name`) |
| `Subjects` | Subjects (`subject_name`, `program_id`, `credits`, **`is_lab`**) — see §8 for meaning of `is_lab` |
| `Rooms` | Rooms (`name`, optional `building_name`, `capacity`, **`room_type`** canonical **`classroom`** / **`lab`**; legacy mirror: `room_name`) |
| `Mappings` | Per program: `subject_id`, `faculty_id`, **`theory_room_id`**, optional **`lab_room_id`** (required when subject `is_lab` is true), legacy **`room_id`** (mirrors `theory_room_id` on save), optional `department_id`, `created_at` |
| `timetable_config` / `basic_information` | Full bell-schedule payload: `timetable_name`, `description`, `academic_session`, `schedule_type`, `cycle_weeks`, `schedule_mode`, `working_days`, `periods`, `breaks`, `day_schedules` |
| `config` / `timetable` doc | Engine fields synced from Basic Information: `working_days_per_week`, `periods_per_day`, `timetable_name`, … |
| `timetable` | Generated slots: `program_id`, `day` (0-based), `period`, `subject_id`, `faculty_id`, `room_id`, `type` (`lab` / `theory`), `created_at` |

Collection name casing may vary (`Programs` vs `programs`); `TimetableService` tries common variants when reading.

### Basic Information module

Administrators open **Overview → Basic Information** as the **first configuration step** before institute data, mappings, or generation.

| Area | Details |
|------|---------|
| **Timetable info** | Required name; optional description |
| **Academic session** | Optional session name + start/end dates (all three required if any field is used) |
| **Schedule type** | `weekly`, `fortnightly`, or `custom` (with cycle week count) |
| **Schedule mode** | `uniform` (same periods all working days) or `custom_day` (per-day periods/breaks) |
| **Working days** | Multi-select chips (Sun–Sat); Weekdays / Clear helpers |
| **Periods & breaks** | Dynamic list with name + start/end time pickers; add/remove rows |

On **Save**, data is stored at `timetable_config/basic_information` and key engine fields are merged into `config/timetable` so existing `TimetableService.getConfig()` continues to work.

### Institute Data module updates

- **Dashboard cleanup**: Admin dashboard quick actions now keep only **My Timetables** and **View Calendar**.
- **Institute Data cleanup**: Subject entry is temporarily removed from Institute Data shortcuts; module still exists and is reachable from its route.
- **Faculty form**:
  - Required: `full_name`, `short_name`, `max_lectures_per_day`, `availability`
  - Optional (collapsed section): `email`, `role`, `phone`, `designation`, `department_id`
  - `short_name` auto-generates from full name and remains editable.
- **Program form**:
  - Required: `name`, `short_name`
  - Optional: `student_count`
  - `short_name` auto-generates and remains editable.
- **Room form**:
  - Required: `name`, `room_type`, `capacity`
  - Optional: `building_name`
  - `room_type` is persisted as lowercase canonical values (`classroom`, `lab`).
- **Compatibility**:
  - Write path keeps legacy mirrors (`program_name`, `branch_name`, `faculty_name`, `room_name`) so current timetable/mapping/read flows remain stable.

### Room type system (`classroom` vs `lab`)

- **Firestore** stores **`room_type`** as lowercase **`classroom`** or **`lab`** only (Add Room writes through `RoomTypeUtils`).
- **UI** labels remain **Classroom** / **Lab** for readability.
- **Add Mapping**: theory dropdown lists only **`classroom`** rooms; lab dropdown (when `is_lab` is true) lists only **`lab`** rooms.
- **Timetable engine**: theory periods always use the mapped **`theory_room_id`** (must resolve to a classroom); lab blocks use **`lab_room_id`** (must resolve to a lab). Legacy **`room_id`** on a mapping is treated as **`theory_room_id`** for backward compatibility.

---

## 7. Timetable generation flow

1. **`prepareTimetableData()`** — Loads programs, **mappings filtered by `program_id`**, subjects per program, rooms, config. Builds per program:
   - `facultyMap[subjectId]`
   - **`theoryRoomMap[subjectId]`** from `theory_room_id` (fallback: legacy `room_id`) — room document must have **`room_type == classroom`**
   - **`labRoomMap[subjectId]`** from `lab_room_id` — required when subject has `is_lab == true`; room document must have **`room_type == lab`**
2. **`createEmptyTimetableGrid()`** — For each program, empty lists per weekday × periods.
3. **`scheduleLabs()`** — For each subject with **`is_lab == true`**: place **one** contiguous **2-period** block using **`lab_room_id`**, respecting faculty/room occupancy.
4. **`scheduleTheorySubjects()`** — For **every** subject that has theory periods this week (including `is_lab == true` courses): place **`theoryPeriodsPerWeek`** slots using **`theory_room_id`**, at most **one theory slot per subject per day**, respecting conflicts. Theory period count:
   - `is_lab == false` → **all** `credits` are theory lectures.
   - `is_lab == true` → **`credits - 1`** theory lectures **plus** the single lab block above (e.g. 4 credits → 3 theory + 1 lab session).
5. **`persistNestedTimetableToFirestore()`** — Flattens nested grid to `timetable` documents (replaces previous batch).

Entry points: **Overview → Generate Timetable**, or **Timetable Configuration → Generate Full Timetable** (same pipeline; optional `persistToFirestore` flag in code).

---

## 8. Scheduling constraints (important)

### Subject flag `is_lab` (critical)

| `is_lab` | Meaning |
|----------|---------|
| **`false`** | **Theory-only** subject: all `credits` are weekly theory periods; mapping needs **`theory_room_id`** pointing to a room with **`room_type: classroom`** only. |
| **`true`** | **Theory + lab** subject: **not** “lab only”. It has **`credits - 1`** weekly **theory** periods **and** **one** weekly **lab** session (exactly **two contiguous periods**). Mapping needs **`theory_room_id`** (classroom) **and** **`lab_room_id`** (lab). |

### Other rules

| Rule | Description |
|------|-------------|
| **Theory once per day** | Same `subject_id` at most **one theory** slot per weekday per program (lab slots on the same day do **not** block theory that day). |
| **Theory credits** | See table above: theory-only uses all credits; theory+lab uses `credits - 1` for theory. |
| **Lab block** | For `is_lab == true`: **one** placement of **two adjacent periods** per week; uses **`lab_room_id`**. |
| **Rooms from mapping** | No random room pick: theory always uses **`theory_room_id`**; lab uses **`lab_room_id`**. |
| **Faculty conflicts** | Same faculty cannot be double-booked in the same day/period. |
| **Room conflicts** | Same room cannot be used twice in the same day/period. |
| **Mapping scope** | Mappings are **per `program_id`**. |

If a subject has **no mapping**, **missing required room ids**, or **wrong room types**, it is **skipped** with a `dev.log` message (generation continues for others).

**Legacy mappings** that only have `room_id` (no `theory_room_id`) still work for **theory room** resolution: `theory_room_id` falls back to `room_id`. Combined courses still need **`lab_room_id`** added in Firestore or via the updated Add Mapping screen.

---

## 9. Navigation flow

```text
Sign in (valid Firebase Auth user) → Dashboard
  → My Timetables → + New Timetable → Overview
  → View Calendar

Dashboard → Sign out → Login

Overview
  → Basic Information (timetable + bell schedule)
  → Institute Data (department, program, faculty, subject, room, mapping)
  → Lecture Configuration
  → View Timetable / Faculty Schedule
  → Generate Timetable
```

Timetable Configuration screen: save config, prepare data, optional stepwise lab/full generation (full generation persists by default).

---

## 10. Screens overview

| Area | Screen |
|------|--------|
| Auth | `LoginScreen` (email/password, validation, loading state); `AuthGate` (session routing at app root) |
| Admin | `DashboardScreen` (greeting from signed-in user, **logout** in app bar), `OverviewScreen`, `MyTimetablesScreen`, `InstituteDataScreen`, `LectureConfigurationScreen`, `TimetableConfigScreen` |
| Forms | **Basic Information**, add department/program/faculty/subject/**room**/**mapping** |
| Views | `ViewTimetableScreen`, `FacultyScheduleScreen`, `CalendarScreen` |

---

## 11. Current implementation status

- **Basic Information** screen with Firestore persistence and engine config sync
- **Firebase Auth** wired with **`AuthGate`** as `MaterialApp` `home`; email/password sign-in and dashboard **sign out**
- **Named routes** for admin and views (e.g. `/my-timetables`, `/calendar`); initial UI is **not** an anonymous dashboard
- **Mappings** store `theory_room_id` + optional `lab_room_id` (+ `room_id` mirror for legacy reads)
- **Room types**: `RoomTypeUtils` + Add Room persist **`classroom`** / **`lab`**; mapping dropdowns and the scheduler filter on those values only (legacy title-case strings that normalize to the same tokens still work).
- **Add Mapping** UI: Department → Program → Subject → Faculty → **Theory room** (rooms with `room_type == classroom`) → **Lab room** (only when subject `is_lab` is true; `room_type == lab` only)
- **Timetable engine** uses the credit split and dual rooms as in §7–8
- **UI** resolves IDs to names; `TimetableGrid` labels lab slots with **(LAB)** and tints lab rows

---

## 12. Future enhancements

- Soft constraints (preferred time slots, max consecutive lectures)
- Edit / drag timetable after generation
- Per-semester timetable versions and publish workflow
- Automated tests for scheduler invariants
- Optional legacy `generateTimetable()` path aligned with mapping-based rooms (if still needed)

---

## Run

```bash
flutter pub get
flutter run
```

Ensure `firebase_options.dart` matches your Firebase project. Enable **Email/Password** in the Firebase console, create at least one admin user for testing, and configure **Firestore security rules** (and optionally **App Check**) so only authenticated clients can access sensitive data.
