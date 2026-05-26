# Firebase test users setup

Credentials are **not** stored in the app. Create users in the Firebase Console and matching Firestore profiles.

## 1. Enable Email/Password

Firebase Console → **Authentication** → **Sign-in method** → **Email/Password** → **Enable**.

## 2. Create Authentication users

Authentication → **Users** → **Add user**:

| Role    | Email                 | Password     |
|---------|-----------------------|--------------|
| Admin   | `admin@timetable.com` | `Admin@123`  |
| Faculty | `faculty@timetable.com` | `Faculty@123` |
| Student | `student@timetable.com` | `Student@123` |

Copy each user’s **User UID** from the Authentication tab.

## 3. Create Firestore `users` documents

Collection: **`users`**  
Document ID: **must be the Auth UID** (not the email).

### Admin (`users/<ADMIN_UID>`)

```json
{
  "uid": "<ADMIN_UID>",
  "name": "Admin User",
  "email": "admin@timetable.com",
  "role": "admin"
}
```

### Faculty (`users/<FACULTY_UID>`)

```json
{
  "uid": "<FACULTY_UID>",
  "name": "Faculty User",
  "email": "faculty@timetable.com",
  "role": "faculty"
}
```

### Student (`users/<STUDENT_UID>`)

```json
{
  "uid": "<STUDENT_UID>",
  "name": "Student User",
  "email": "student@timetable.com",
  "role": "student"
}
```

## 4. Firestore security rules (development)

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Tighten rules for production.

## 5. Expected app behavior

| Role    | After login                          |
|---------|--------------------------------------|
| admin   | Admin **Dashboard**                  |
| faculty | **Faculty Schedule** (+ calendar)    |
| student | **View Timetable** (+ calendar)      |

If Auth succeeds but Firestore profile is missing, the app shows **Account setup required** with your UID and a **Sign out** button.

## 6. Debug logs

Run the app with `flutter run` and watch the console for:

- `LoginScreen` — login attempt, uid, profile status  
- `AuthService` — Firestore fetch  
- `AuthGate` — role-based navigation target  
