# timetable_sceduler

A Flutter app for admin-driven timetable setup and generation (Firebase integrated).

## Current Features

- Firebase + Firestore integration for core data modules
- Route-based admin flow:
  - Login -> Dashboard -> Overview -> Timetable Configuration
- Admin setup screens:
  - Add Department
  - Add Program
  - Add Faculty
  - Add Subject
  - Add Room
- Add Mapping (subject -> faculty -> program)
- Timetable data preparation layer (`prepareTimetableData()`)
- Empty timetable grid creation (`createEmptyTimetableGrid()`)
- Lab-only scheduling (`scheduleLabs()`)
- Theory scheduling into remaining empty slots (`scheduleTheorySubjects()`)
- Full pipeline trigger (`generateFullTimetableFromPreparedData()`)

## Navigation Flow

```text
Login
  -> Dashboard
      -> My Timetable (Overview)
          -> Department / Program / Faculty / Subject / Room / Mapping
          -> Timetable Settings

Timetable Settings
  -> Save Configuration
  -> Prepare Data
  -> Create Timetable Grid
  -> Schedule Labs
  -> Generate Full Timetable
```

## Main Routes

- `/login`
- `/dashboard`
- `/overview`
- `/timetable-config`
- `/add_department`
- `/add_program`
- `/add_faculty`
- `/add_subject`
- `/add_room`
- `/add-mapping`

## Timetable Service (Current Scope)

`lib/services/timetable_service.dart` currently supports:

- `getAllPrograms()`
- `getSubjectsByProgram(programId)`
- `getMappings()`
- `getRooms()`
- `getConfig()`
- `prepareTimetableData()`
- `createEmptyTimetableGrid()`
- `scheduleLabs(timetable, timetableData)`
- `scheduleTheorySubjects(timetable, timetableData)`
- `generateFullTimetableFromPreparedData()`

Grid creation uses config values:

- `working_days_per_week` (fallback supported)
- `periods_per_day` (fallback supported)

Each program receives a day-period matrix initialized with `null` slots.

Current scheduling rules:

- Labs: 2 consecutive slots, once per week
- Theory: fills only empty slots
- Theory daily limit: same subject max 1 slot/day
- Faculty and room conflict checks applied
- Lab slots are not overwritten by theory

## Project Structure

```text
lib/
  main.dart
  firebase_options.dart
  routes/
    app_routes.dart
  services/
    database_service.dart
    timetable_service.dart
  screens/
    auth/
      login_screen.dart
    admin/
      dashboard_screen.dart
      overview_screen.dart
      timetable_config_screen.dart
      add_department_screen.dart
      add_program_screen.dart
      add_faculty_screen.dart
      add_subject_screen.dart
      add_room_screen.dart
      add_mapping_screen.dart
  widgets/
    custom_textfield.dart
```

## Run

```bash
flutter pub get
flutter run
```
