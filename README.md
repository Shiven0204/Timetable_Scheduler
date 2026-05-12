# Timetable Scheduler

Flutter application for **institute timetable management**: master data (departments, programs, faculty, subjects, rooms), **subject–faculty–room mappings** per program, configurable weekly grid, **automated timetable generation**, and **Firestore-backed** views for students, faculty, and calendar.

---

## 1. Project overview

Administrators configure the institute, map each subject to a faculty member and **specific room** (lab vs classroom), then generate a weekly timetable that respects **daily theory limits**, **two-period contiguous labs**, **faculty availability**, and **room conflicts**. Generated slots are stored in Firestore and shown across dashboard, student, faculty, and calendar screens.

---

## 2. Features

- Firebase Authentication and Firestore
- Admin dashboard (quick actions: My Timetables, Calendar)
- Overview hub: data setup, lecture configuration, generate timetable, navigation to views
- CRUD-style flows: departments, programs, faculty, subjects, rooms, **mappings (with room)**
- Timetable configuration (`working_days`, `periods_per_day`, etc.)
- **Timetable engine**: lab scheduling → theory scheduling → **persist** flat `timetable` documents
- **Student timetable** (by program), **faculty schedule** (by faculty), **calendar grid** (by program)
- Shared UI helpers: name resolution, `TimetableGrid` widget

---

## 3. Architecture

| Layer | Responsibility |
|--------|----------------|
| **Screens** | Material UI, forms, navigation (`lib/screens/`) |
| **Routes** | Named routes in `lib/routes/app_routes.dart`, registered in `main.dart` |
| **Services** | `DatabaseService` (writes), `TimetableService` (read config, prepare data, schedule, save), `TimetableNameResolver` / helpers for UI |
| **Widgets** | Reusable timetable table (`lib/widgets/timetable_grid.dart`) |
| **Firebase** | `firebase_options.dart`, Firestore collections listed below |

---

## 4. Tech stack

- **Flutter** (Material 3–friendly UI)
- **Firebase Core + Cloud Firestore**
- **Dart** analyzer–clean codebase target for touched modules

---

## 5. Firebase collections (typical)

| Collection | Purpose |
|------------|---------|
| `Department` | Departments (`dept_name`) |
| `Programs` | Programs (`program_name`, `branch_name`, `department_id`) |
| `Faculty` | Faculty (`faculty_name`, `department_id`, …) |
| `Subjects` | Subjects (`subject_name`, `program_id`, `credits`, `is_lab`) |
| `Rooms` | Rooms (`room_name`, `room_type`: **Lab** / **Classroom**, `capacity`) |
| `Mappings` | Per program: `subject_id`, `faculty_id`, **`room_id`**, `program_id`, optional `department_id`, `created_at` |
| `config` / `timetable` doc | `working_days` / `working_days_per_week`, `periods` / `periods_per_day`, … |
| `timetable` | Generated slots: `program_id`, `day` (0-based), `period`, `subject_id`, `faculty_id`, `room_id`, `type` (`lab` / `theory`), `created_at` |

Collection name casing may vary (`Programs` vs `programs`); `TimetableService` tries common variants when reading.

---

## 6. Timetable generation flow

1. **`prepareTimetableData()`** — Loads programs, **mappings filtered by `program_id`**, subjects per program, rooms, config. Builds per program:
   - `facultyMap[subjectId]`
   - **`roomMap[subjectId]`** (from mapping; validated: lab subject → lab room, theory → non-lab room)
2. **`createEmptyTimetableGrid()`** — For each program, empty lists per weekday × periods.
3. **`scheduleLabs()`** — For each **lab** subject with valid mapping: place **exactly one** contiguous **2-period** block using **mapped `room_id`**, respecting faculty/room occupancy.
4. **`scheduleTheorySubjects()`** — For each **theory** subject (deduped by `subject_id`): for each **credit**, place one period on a day where that subject **has not yet appeared that day**, using **mapped classroom `room_id`**, respecting conflicts.
5. **`persistNestedTimetableToFirestore()`** — Flattens nested grid to `timetable` documents (replaces previous batch).

Entry points: **Overview → Generate Timetable**, or **Timetable Configuration → Generate Full Timetable** (same pipeline; optional `persistToFirestore` flag in code).

---

## 7. Scheduling constraints (important)

| Rule | Description |
|------|-------------|
| **Theory once per day** | Same `subject_id` at most **one** slot per weekday per program (grid scan + explicit tracker). |
| **Theory credits** | `credits` = number of **weekly** theory periods to place (spread across different days when possible). |
| **Lab block** | Each lab subject: **one** placement of **two adjacent periods** in the week; both periods share the same subject/faculty/room. |
| **Rooms from mapping** | **No random room pick** in the main pipeline: lab uses mapping’s **lab** room; theory uses mapping’s **classroom** (non-lab) room. |
| **Faculty conflicts** | Same faculty cannot be double-booked in the same day/period (global across programs when building from one grid pass per program — faculty schedule still reflects stored rows). |
| **Room conflicts** | Same room cannot be used twice in the same day/period. |
| **Mapping scope** | Mappings are **per `program_id`** so subjects in different programs do not share the wrong faculty/room row. |

If a subject has **no mapping**, **missing `room_id`**, or **room type mismatch**, it is **skipped** with a `dev.log` message (generation continues for others).

---

## 8. Navigation flow

```text
Login → Dashboard
  → My Timetables → + New Timetable → Overview
  → View Calendar

Overview
  → Institute Data (department, program, faculty, subject, room, mapping)
  → Lecture Configuration
  → View Timetable / Faculty Schedule
  → Generate Timetable
```

Timetable Configuration screen: save config, prepare data, optional stepwise lab/full generation (full generation persists by default).

---

## 9. Screens overview

| Area | Screen |
|------|--------|
| Auth | `LoginScreen` |
| Admin | `DashboardScreen`, `OverviewScreen`, `MyTimetablesScreen`, `InstituteDataScreen`, `LectureConfigurationScreen`, `TimetableConfigScreen` |
| Forms | Add department/program/faculty/subject/**room**/**mapping** |
| Views | `ViewTimetableScreen`, `FacultyScheduleScreen`, `CalendarScreen` |

---

## 10. Current implementation status

- Firebase wiring and **named routes** (including `/my-timetables`, `/calendar`)
- **Mappings include `room_id`** and optional `department_id`
- **Add Mapping** UI: Department → Program → Subject → Faculty → Room (room list filtered by subject `is_lab`)
- **Timetable engine** uses mapping rooms and stricter theory/lab rules as above
- **UI** resolves IDs to names via batched Firestore reads; `TimetableGrid` supports program vs faculty layout and lab tint

---

## 11. Future enhancements

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

Ensure `firebase_options.dart` matches your Firebase project and Firestore security rules allow admin clients to read/write the collections above.
