# Timetable Scheduler - Project Context

## 1. Document purpose

This document describes the current state of the `timetable_scheduler` Flutter application. It records the project structure, application flow, Firebase integration, Firestore data model, role-based access, timetable generation engine, UI responsibilities, audit findings, completed optimizations, known risks, and recommended future work.

This document is intended to help a developer understand the project before making further changes. It is not a feature specification and does not change the existing timetable rules or Firestore schema.

---

## 2. Project overview

The project is a Flutter application for managing and generating academic timetables.

### Technology stack

- Flutter
- Dart SDK `^3.9.2`
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Flutter Lints
- Android, iOS, macOS, Windows, Linux, and Web project folders

### Application roles

The application supports three roles:

- `admin`
- `faculty`
- `student`

### Main capabilities

Administrators can:

1. Configure basic timetable information.
2. Configure working days, periods, breaks, and timetable sessions.
3. Add departments.
4. Add programs.
5. Add faculty members.
6. Add rooms.
7. Add subjects.
8. Map subjects to faculty and rooms.
9. Configure theory and lab frequencies.
10. Generate timetable drafts.
11. View saved timetables.
12. Publish timetable drafts.

Faculty members can view their published schedules.

Students can view published timetables for their selected programs.

---

## 3. Repository structure

```text
timetable_scheduler/
├── android/                         Android application and Gradle configuration
├── ios/                             iOS application configuration
├── macos/                           macOS application configuration
├── linux/                           Linux application configuration
├── windows/                         Windows application configuration
├── web/                             Web application configuration
├── lib/
│   ├── firebase_options.dart        Generated Firebase platform options
│   ├── main.dart                    Application entry point and route setup
│   ├── models/                      Domain and persistence models
│   ├── providers/                   Provider directory; currently minimal or unused
│   ├── routes/                      Route constants
│   ├── screens/                     Feature and role-specific screens
│   ├── services/                    Authentication, database, and timetable services
│   ├── utils/                       Shared utility functions
│   └── widgets/                     Reusable widgets and guards
├── test/
│   └── widget_test.dart             Login screen widget test
├── docs/
│   └── FIREBASE_TEST_USERS.md       Firebase test-user documentation
├── firebase.json                    Firebase project configuration
├── pubspec.yaml                     Dependencies and Flutter configuration
├── pubspec.lock                     Locked dependency versions
└── analysis_options.yaml             Dart analyzer and lint configuration
```

Generated build output is present under `build/`. It should not be treated as application source code.

---

## 4. Application startup flow

The startup sequence is implemented in [lib/main.dart](lib/main.dart).

```text
main()
 ├── WidgetsFlutterBinding.ensureInitialized()
 ├── Firebase.initializeApp(...)
 └── runApp(const MyApp())
```

`MyApp` creates the root `MaterialApp`, sets the initial `AuthGate`, and registers named routes.

The default startup widget is:

```text
AuthGate
```

The application uses Firebase Auth state changes to decide whether to show the login page or a role-specific home screen.

---

## 5. Authentication and authorization

### Authentication flow

Authentication is implemented by:

- [lib/screens/auth/login_screen.dart](lib/screens/auth/login_screen.dart)
- [lib/services/auth_service.dart](lib/services/auth_service.dart)
- [lib/widgets/auth_gate.dart](lib/widgets/auth_gate.dart)

The flow is:

```text
FirebaseAuth.authStateChanges()
        ↓
AuthGate receives User?
        ↓
AuthService.fetchUserProfile(user)
        ↓
Read users/{uid} from Firestore
        ↓
Normalize and validate role
        ↓
Open role-specific screen
```

The Firestore user document ID is expected to be the Firebase Authentication UID:

```text
users/{uid}
```

The user profile contains a role such as `admin`, `faculty`, or `student`.

### AuthGate

[lib/widgets/auth_gate.dart](lib/widgets/auth_gate.dart) listens to Firebase Auth state changes. It:

- Shows `LoginScreen` when no user is signed in.
- Shows a loading indicator while the profile is loading.
- Shows an admin dashboard for administrators.
- Shows the faculty schedule for faculty members.
- Shows the student timetable for students.
- Shows a missing-profile screen for invalid or missing profiles.
- Cancels its authentication stream subscription in `dispose()`.

### Route protection

[lib/widgets/role_protected.dart](lib/widgets/role_protected.dart) loads the current user profile and checks whether the role is included in the route's allowed role set.

Current route authorization:

| Route | Allowed roles |
|---|---|
| Dashboard | Admin, faculty, student |
| Overview | Admin |
| Basic information | Admin |
| Timetable configuration | Admin |
| Add subject | Admin |
| Add mapping | Admin |
| Institute data | Admin |
| Lecture configuration | Admin |
| My timetables | Admin |
| View timetable | Admin, student |
| Faculty schedule | Admin, faculty |
| Calendar | All roles by current route setup |

Important security note: `RoleProtected` only controls the client UI. It is not a substitute for Firestore security rules. Firestore rules must independently enforce read and write permissions.

---

## 6. Route map

Route constants are defined in [lib/routes/app_routes.dart](lib/routes/app_routes.dart).

The registered routes are defined in [lib/main.dart](lib/main.dart):

```text
/login
/dashboard
/overview
/basic-information
/timetable-config
/add_subject
/add-mapping
/view-timetable
/faculty-schedule
/institute-data
/lecture-configuration
/my-timetables
/calendar
```

The application preserves named navigation through `Navigator.pushNamed`.

---

## 7. Screen responsibilities

### Authentication screens

#### Login screen

File: [lib/screens/auth/login_screen.dart](lib/screens/auth/login_screen.dart)

Responsibilities:

- Email and password form.
- Client-side validation.
- Firebase email/password sign-in.
- User profile loading after authentication.
- Error message conversion using [lib/utils/auth_error_messages.dart](lib/utils/auth_error_messages.dart).
- Signing out users who do not have a valid Firestore role profile.

Text controllers are disposed correctly.

### Admin screens

Admin screens are under [lib/screens/admin/](lib/screens/admin/).

#### Dashboard

File: [lib/screens/admin/dashboard_screen.dart](lib/screens/admin/dashboard_screen.dart)

Provides the primary administrative navigation surface and dashboard information.

#### Overview

File: [lib/screens/admin/overview_screen.dart](lib/screens/admin/overview_screen.dart)

Provides navigation to administrative workflows and starts full timetable generation.

Generation behavior:

1. Sets a loading state.
2. Calls `generateFullTimetableFromPreparedData()`.
3. Increments the draft counter in `timetable_stats/counters`.
4. Shows success or error feedback.

#### Basic information

Files:

- [lib/screens/admin/basic_information_screen.dart](lib/screens/admin/basic_information_screen.dart)
- [lib/screens/admin/basic_information_entries.dart](lib/screens/admin/basic_information_entries.dart)
- [lib/screens/admin/timetable_details_form.dart](lib/screens/admin/timetable_details_form.dart)
- [lib/screens/admin/bell_schedule_form.dart](lib/screens/admin/bell_schedule_form.dart)

Responsibilities:

- Timetable name.
- Academic session.
- Working days.
- Periods.
- Breaks.
- Uniform or custom schedule configuration.
- Validation before saving.

#### Institute data

Files:

- [lib/screens/admin/institute_data_screen.dart](lib/screens/admin/institute_data_screen.dart)
- [lib/screens/admin/institute_data_entries.dart](lib/screens/admin/institute_data_entries.dart)
- [lib/widgets/institute_data/institute_entry_sheet.dart](lib/widgets/institute_data/institute_entry_sheet.dart)
- [lib/widgets/institute_form_card.dart](lib/widgets/institute_form_card.dart)

This area manages institute-level data such as departments, programs, faculty, rooms, subjects, and mappings.

#### Timetable configuration

File: [lib/screens/admin/timetable_config_screen.dart](lib/screens/admin/timetable_config_screen.dart)

This screen exposes configuration and diagnostic-style operations:

- Save working days and periods.
- Prepare timetable data.
- Create an empty timetable grid.
- Schedule labs from prepared data.
- Generate the full timetable.

The active end-to-end generation operation is also available from the Overview screen.

#### Lecture configuration

File: [lib/screens/admin/lecture_configuration_screen.dart](lib/screens/admin/lecture_configuration_screen.dart)

Used for configuring lecture-related timetable information.

#### Saved timetables

File: [lib/screens/admin/my_timetables_screen.dart](lib/screens/admin/my_timetables_screen.dart)

Reads timetable configuration documents and displays saved timetable entries.

### Faculty screen

File: [lib/screens/faculty/faculty_schedule_screen.dart](lib/screens/faculty/faculty_schedule_screen.dart)

Responsibilities:

- Load timetable configuration.
- Load published timetable rows filtered by faculty ID.
- Resolve subject, program, and room names.
- Build a faculty-specific weekly grid.
- Display loading, empty, and error states.

### Student screen

File: [lib/screens/student/view_timetable_screen.dart](lib/screens/student/view_timetable_screen.dart)

Responsibilities:

- Load timetable headers and breaks.
- Load programs.
- Select a program.
- Query published timetable rows for the selected program.
- Resolve subject, faculty, and room names.
- Build the student timetable grid.

### Calendar screen

File: [lib/screens/calendar/calendar_screen.dart](lib/screens/calendar/calendar_screen.dart)

The calendar screen provides a program-based weekly view. Its loading and grid logic is similar to the student timetable screen, although it uses a different timetable status behavior and presentation context.

---

## 8. Models

Models are under [lib/models/](lib/models/).

### AcademicSession

File: [lib/models/academic_session.dart](lib/models/academic_session.dart)

Represents academic session details, including session name and optional dates.

### AppUserProfile

File: [lib/models/app_user_profile.dart](lib/models/app_user_profile.dart)

Represents:

- Firebase UID.
- User profile fields.
- Normalized role.
- Known role constants.

### BasicInformation

File: [lib/models/basic_information.dart](lib/models/basic_information.dart)

Represents timetable configuration such as:

- Timetable name.
- Academic session.
- Working days.
- Schedule mode.
- Schedule type.
- Periods.
- Breaks.
- Day-specific schedules.

### ScheduleSlot

File: [lib/models/schedule_slot.dart](lib/models/schedule_slot.dart)

Represents a period or break with:

- Name.
- Start time.
- End time.
- Validation helpers.
- Formatting helpers.

---

## 9. Service layer

### AuthService

File: [lib/services/auth_service.dart](lib/services/auth_service.dart)

Responsibilities:

- Read the current user.
- Sign out.
- Load `users/{uid}`.
- Convert Firestore data to `AppUserProfile`.
- Validate known roles.
- Return structured profile-load results.

It uses explicit Firebase exception handling and logs failures through `dart:developer`.

### DatabaseService

File: [lib/services/database_service.dart](lib/services/database_service.dart)

Responsibilities:

- Save departments.
- Save programs.
- Save faculty.
- Save subjects.
- Save mappings.
- Save rooms.

It performs basic input validation before Firestore writes and rethrows errors after logging them.

Some data writes intentionally include both canonical and legacy field names. For example, programs can contain both:

```text
name
program_name
short_name
branch_name
```

This appears to preserve compatibility with existing data and screens.

### BasicInformationService

File: [lib/services/basic_information_service.dart](lib/services/basic_information_service.dart)

The basic-information document is stored at:

```text
timetable_config/basic_information
```

The service also synchronizes engine configuration to:

```text
config/timetable
```

Synchronized fields include:

- `working_days`
- `working_days_per_week`
- `periods`
- `periods_per_day`
- `timetable_name`
- `updated_at`

Validation includes:

- Timetable name validation.
- Academic session completeness.
- Academic session date order.
- Working-day selection.
- Custom cycle-week bounds.
- Period and break names.
- Period and break time validity.
- At least one period per active day.

### TimetableFirestoreHelpers

File: [lib/services/timetable_firestore_helpers.dart](lib/services/timetable_firestore_helpers.dart)

Converts flat Firestore rows into display grids. It handles invalid day or period values safely and prevents out-of-range grid writes.

### TimetableNameResolver

File: [lib/services/timetable_name_resolver.dart](lib/services/timetable_name_resolver.dart)

Resolves IDs into display names by reading the corresponding Firestore collections. The result is used by student, calendar, and faculty timetable screens.

### TimetableService

File: [lib/services/timetable_service.dart](lib/services/timetable_service.dart)

This is the central business-logic service.

It has two generations of timetable code:

1. The active prepared-data generation engine.
2. A legacy generator that is no longer used by the active UI.

---

## 10. Firestore data model

The application currently uses the following collections.

### `users`

Document ID:

```text
Firebase Auth UID
```

Expected role field:

```text
role: admin | faculty | student
```

### `Department`

Representative fields:

```text
dept_name
created_at
```

### `Programs`

Representative fields:

```text
name
short_name
program_name
branch_name
department_id
student_count
created_at
```

### `Faculty`

Representative fields:

```text
full_name
short_name
faculty_name
max_lectures_per_day
availability
email
role
phone
designation
department_id
created_at
```

### `Subjects`

Representative fields:

```text
name
short_name
subject_name
credits
is_lab
program_id
created_at
```

### `Mappings`

Representative fields:

```text
faculty_id
subject_id
program_id
theory_frequency
lab_frequency
theory_room_id
lab_room_id
room_id
department_id
created_at
```

`room_id` is retained as a compatibility field for theory room mapping.

### `Rooms`

Representative fields:

```text
name
room_name
room_type
capacity
building_name
created_at
```

Room types are normalized through [lib/utils/room_type_utils.dart](lib/utils/room_type_utils.dart).

### `config/timetable`

Representative fields:

```text
working_days
working_days_per_week
periods
periods_per_day
duration_per_period
max_lectures_per_day
timetable_name
updated_at
```

### `timetable_config`

Used for:

- Basic information.
- Saved timetable metadata.
- Draft/published status.

Saved timetable metadata includes:

```text
document_type
timetable_name
session_name
status
created_at
updated_at
published_on
```

### `timetable`

The generated timetable is stored as flat documents.

Representative fields:

```text
timetable_id
program_id
day
period
subject_id
faculty_id
room_id
type
status
created_at
published_on
```

`type` is normally `theory` or `lab`.

### `timetable_stats/counters`

Used by the Overview screen for draft counters.

---

## 11. Timetable generation flow

The active generation entry point is:

```text
TimetableService.generateFullTimetableFromPreparedData()
```

The complete flow is:

```text
Load BasicInformation
        ↓
Validate timetable name and session name
        ↓
prepareTimetableData()
        ↓
Create empty grid using prepared data
        ↓
scheduleLabs()
        ↓
scheduleTheorySubjects()
        ↓
persistNestedTimetableToFirestore()
        ↓
_saveTimetable()
```

### Preparing timetable data

`prepareTimetableData()` loads:

- Programs.
- Mappings.
- Rooms.
- Configuration.
- Subjects.

It then builds per-program maps:

```text
facultyMap
theoryRoomMap
labRoomMap
theoryFrequencyMap
labFrequencyMap
```

It validates:

- Faculty mapping presence.
- Theory room presence.
- Theory room type.
- Lab room presence.
- Lab room type.
- Non-negative frequencies.

Subjects without valid mappings are skipped and logged.

### Empty grid

The grid has this conceptual shape:

```text
programId
 └── dayName
      └── List of periods
```

Empty periods contain `null`.

The current grid uses configured working days and periods per day.

### Lab scheduling

Labs are scheduled before theory sessions.

Important rules preserved by the active implementation:

- A lab uses two consecutive periods.
- A lab session uses its mapped lab room.
- A lab uses its mapped faculty member.
- The same subject is not scheduled for multiple labs on the same day.
- Faculty cannot be busy in another program at the same time.
- A room cannot be busy in another program at the same time.
- Lab frequency comes from `lab_frequency`.

The implementation uses:

```text
facultySchedule: faculty → day → occupied periods
roomSchedule: room → day → occupied periods
programLabLoad: day → lab count
```

The scheduling order attempts to distribute labs across days and reduce daily concentration.

### Theory scheduling

Theory scheduling runs after labs.

Important rules:

- Theory frequency comes from the configured mapping.
- A subject is not scheduled more than once per day.
- A theory lecture cannot overlap with a lab of the same subject on the same day.
- Faculty conflicts are prevented.
- Room conflicts are prevented.
- Theory rooms must be classroom-type rooms.

### Persistence

`persistNestedTimetableToFirestore()` converts the in-memory grid to flat rows.

`_saveTimetable()`:

1. Validates timetable and session names.
2. Reuses an existing timetable metadata document when the same name/session exists.
3. Creates a new metadata document otherwise.
4. Deletes existing rows for the timetable.
5. Writes new rows in Firestore batches.
6. Uses a batch size of 400.
7. Marks rows as `draft`.

### Publishing

`publishTimetable()`:

1. Finds draft rows for the timetable ID.
2. Updates rows to `published`.
3. Adds `published_on`.
4. Updates the corresponding `timetable_config` document.

---

## 12. Timetable business rules that must remain unchanged

Future cleanup must preserve these rules:

1. A lab session occupies two consecutive periods.
2. A subject may have zero theory lectures.
3. A lab-enabled subject may have both theory and lab sessions.
4. A subject may have at most one lab session per day.
5. Lab frequency is independently configurable.
6. Faculty members cannot teach multiple classes simultaneously.
7. Rooms cannot be assigned to multiple classes simultaneously.
8. Theory frequency follows the configured mapping frequency.
9. Working days, periods, and breaks follow Basic Information settings.

These are domain rules, not implementation details.

---

## 13. Display-grid flow

Published timetable rows are loaded by the display screens.

The common flow is:

```text
Load configuration
        ↓
Load programs or faculty timetable rows
        ↓
Collect subject/faculty/room/program IDs
        ↓
Resolve IDs into display names
        ↓
Build grid with TimetableFirestoreHelpers
        ↓
Render TimetableGrid
```

The grid helper handles:

- Invalid day values.
- Invalid period values.
- Break indexes.
- Empty cells.
- Display-name fallbacks when an ID cannot be resolved.

---

## 14. Reusable widgets

Reusable UI components are under [lib/widgets/](lib/widgets/).

Important widgets:

- `AuthGate`
- `RoleProtected`
- `TimetableGrid`
- `CustomTextField`
- `LogoutAppBarAction`
- `MissingProfileScreen`
- Basic information cards
- Schedule slot tiles
- Institute data form components

Most stateful screens dispose their `TextEditingController` instances correctly.

---

## 15. Utilities

### Auth error messages

File: [lib/utils/auth_error_messages.dart](lib/utils/auth_error_messages.dart)

Converts Firebase Auth exception codes into user-readable messages.

### Room type utilities

File: [lib/utils/room_type_utils.dart](lib/utils/room_type_utils.dart)

Normalizes room types and checks whether a room document represents:

- A classroom.
- A lab.

### Short name generator

File: [lib/utils/short_name_generator.dart](lib/utils/short_name_generator.dart)

Generates short names from longer labels for forms and data-entry workflows.

---

## 16. Code quality audit results

### Strengths

- Clear high-level separation between screens, services, models, widgets, and utilities.
- Firebase initialization is centralized in `main.dart`.
- Authentication and profile loading are separated from UI.
- Controllers are generally disposed properly.
- Timetable persistence uses batched writes.
- Timetable reads use explicit program/faculty filters.
- Room type validation is centralized.
- Basic-information validation is centralized.
- Error messages are shown to users for most form operations.
- The active timetable engine uses shared conflict-tracking structures.
- The project now passes static analysis.

### Redundancy identified

#### Duplicate timetable display logic

The student and calendar screens contain similar logic for:

- Loading headers.
- Loading programs.
- Reading timetable rows.
- Collecting related IDs.
- Resolving names.
- Building grids.
- Handling loading and error states.

This is a future extraction opportunity, but it was not performed to avoid a broad UI refactor.

#### Duplicate timetable generation paths

`TimetableService` contains:

1. The active prepared-data engine.
2. A legacy `_Task`-based engine.

The legacy path is not used by current routes and has different behavior. It should eventually be removed or clearly isolated after confirming that no external caller depends on it.

#### Legacy collection and field aliases

Several services support both old and new collection names or field names. This is likely intentional compatibility behavior. Removing aliases could break existing Firestore data and should require a migration plan.

---

## 17. Performance observations

### Improvements already made

`prepareTimetableData()` previously loaded subjects separately for every program. It now loads the subject collection once and filters the in-memory list by `program_id`.

The full generation flow now creates its empty grid from already prepared configuration instead of re-reading programs and configuration through another service call.

### Remaining performance considerations

- Timetable display screens repeat similar configuration and program reads.
- Name resolution can require several Firestore reads depending on the number of unique IDs.
- Timetable generation is intentionally sequential because scheduling conflicts depend on prior assignments.
- `_saveTimetable()` deletes old rows before writing new rows. This preserves replacement behavior but is not atomic across all batches.
- Candidate collection fallback reads may make multiple reads when legacy collection names are present.

Concurrency should not be introduced into scheduling placement or replacement writes without preserving consistency.

---

## 18. Error handling observations

The project generally follows this pattern:

```text
try
 ├── perform Firebase or scheduling operation
 └── show success
catch
 └── log/show an error
finally
 └── clear loading state
```

Positive aspects:

- Most user-facing operations show error feedback.
- Services commonly log exceptions with stack traces.
- Many async UI paths check `mounted`.
- Firestore exceptions are handled explicitly in authentication.

Remaining concerns:

- Some timetable-generation failures are logged and the partially generated grid is returned.
- Completeness validation is not yet enforced before persistence.
- Several screens use generic error messages, which is safe for users but limits debugging detail.

---

## 19. Security observations

### Current client-side controls

- Firebase Authentication is used.
- User roles are loaded from Firestore.
- Routes use `RoleProtected` in most cases.
- Admin functionality is mostly guarded at the route level.

### Items requiring verification

The repository does not currently provide enough information to verify Firestore rules. The following must be enforced server-side:

- Only administrators can write institute data.
- Only administrators can generate, update, and publish timetables.
- Students can only read permitted published timetable data.
- Faculty members can only read permitted schedules.
- Users cannot change their own role through unauthorized writes.
- Draft timetable data is not exposed to unauthorized users.

The Calendar route currently allows access without a route-level `RoleProtected` wrapper. This should be reviewed against the intended product behavior and Firestore rules.

---

## 20. Testing and static analysis

### Current test coverage

There is one widget test:

- [test/widget_test.dart](test/widget_test.dart)

It verifies that the login screen renders.

### Commands executed

```text
flutter analyze
```

Result:

```text
No issues found
```

```text
flutter test
```

Result:

```text
All tests passed
```

### Missing test coverage

The following areas need dedicated tests:

- Lab sessions occupy exactly two consecutive periods.
- Lab frequency is fully respected.
- A subject does not receive two labs on the same day.
- Subjects with zero theory frequency are handled correctly.
- Lab-enabled subjects can receive both theory and lab sessions.
- Faculty conflicts are prevented.
- Room conflicts are prevented.
- Theory frequency is fully respected.
- Invalid room types are rejected.
- Missing mappings are handled safely.
- Timetable persistence writes the expected flat rows.
- Publishing updates only draft rows.
- Firestore error states are shown correctly.

---

## 21. Completed audit changes

The recent audit made only behavior-preserving changes:

### Production logging cleanup

Removed direct `print()` calls from timetable display screens. Existing developer logging through `dart:developer` remains where useful.

### Lifecycle safety

Added mounted checks before asynchronous state updates in:

- `AuthGate`
- Calendar header loading
- Student timetable header loading

### Firestore read reduction

Prepared timetable data now loads subjects once instead of once per program.

### Prepared-grid reuse

The active full-generation flow creates its empty grid directly from the prepared configuration, avoiding duplicate reads.

### Login testability

Firebase Auth service resolution was deferred until login submission, allowing the login rendering test to run without requiring a Firebase host platform plugin.

### Test correction

The widget test now renders `LoginScreen` inside `MaterialApp`, which supplies the required Flutter inherited widgets.

---

## 22. Known risks and unresolved issues

### High priority

#### Incomplete timetable may be persisted

If the engine cannot place every requested theory or lab session, the current flow can log the failure and continue. A final validation step should compare requested and placed frequencies before saving.

#### Legacy generator remains in the codebase

The old generator is not used by the active UI and does not represent the current scheduling rules accurately. Removing it without checking all references could be unsafe, so it remains for now.

### Medium priority

#### No verified Firestore rules in the repository

Client-side role protection cannot guarantee data security.

#### Duplicated display logic

Calendar, student, and faculty timetable views share patterns that could be consolidated.

#### Multi-step timetable replacement

Replacing a timetable involves deleting old rows and writing new rows in separate batches. A failure between those operations could leave an incomplete timetable.

### Low priority

#### Legacy aliases

Supporting multiple collection and field names increases complexity, but removing them could break existing data.

#### Limited automated coverage

The current test suite does not exercise the scheduling engine.

---

## 23. Recommended next steps

Recommended order:

1. Add unit tests around the active scheduling engine.
2. Add a final completeness validator before timetable persistence.
3. Verify Firestore security rules and role boundaries.
4. Confirm whether the Calendar route should be role-protected.
5. Review the Gradle wrapper version against the Android Gradle Plugin version.
6. Confirm there are no external callers of `generateTimetable()`.
7. Remove or isolate the legacy generator after confirmation.
8. Extract shared timetable-loading logic from calendar and student screens.
9. Improve atomicity or recovery behavior for timetable replacement.
10. Add integration tests for Firebase-backed workflows where practical.

---

## 24. Important maintenance rules

Future changes should:

- Preserve all timetable business rules.
- Avoid changing the Firestore schema without a migration plan.
- Preserve existing routes and role behavior.
- Avoid deleting apparently unused code until references are verified.
- Keep generated Firebase configuration files unchanged unless Firebase configuration is intentionally updated.
- Use batched Firestore operations for large timetable writes.
- Keep scheduling operations sequential where conflict consistency depends on ordering.
- Validate all configured frequencies before saving a timetable.
- Add tests before modifying the scheduling algorithm.

---

## 25. Current project status

The application has a functioning Flutter structure with Firebase Authentication, Firestore-backed institute data, role-aware navigation, timetable generation, timetable persistence, and timetable viewing.

The codebase currently passes:

- Static analysis.
- The existing widget test.

The most important next technical improvement is automated validation and testing of timetable completeness and conflict behavior. The most important security follow-up is verification of Firestore rules.
