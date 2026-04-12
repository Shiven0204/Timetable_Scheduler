# timetable_sceduler

Minimal Flutter app for timetable scheduling admin flow.

## Current Features

- Simple route-based navigation (no backend, no Firebase)
- Login -> Dashboard -> Timetable Configuration flow
- Admin setup screens:
  - Add Department
  - Add Program
  - Add Faculty
  - Add Subject
  - Add Room
- Form data is printed in console using local inputs only

## Navigation Flow

```text
Login
  -> Dashboard
      -> My Timetable (Timetable Configuration)
          -> Department
          -> Program
          -> Faculty
          -> Subject
          -> Room
```

## Main Routes

- `/login`
- `/dashboard`
- `/timetable_config`
- `/add_department`
- `/add_program`
- `/add_faculty`
- `/add_subject`
- `/add_room`

## Project Structure (Current)

```text
lib/
  main.dart
  routes/
    app_routes.dart
  screens/
    auth/
      login_screen.dart
    admin/
      dashboard_screen.dart
      timetable_config_screen.dart
      add_department_screen.dart
      add_program_screen.dart
      add_faculty_screen.dart
      add_subject_screen.dart
      add_room_screen.dart
  widgets/
    custom_textfield.dart
```

## Run

```bash
flutter pub get
flutter run
```
