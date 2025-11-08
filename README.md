# Task Manager App

A **production-minded, offline-first task management app** built with **Flutter**, **Riverpod**, and **sqflite**.  
Supports lists, tasks, tags, due dates, priority, status, filtering, sorting, and global search — all **fully persistent** and **responsive**.

---

## Features

### Core (All Implemented)

- **Lists**: Create, rename, delete (swipe + confirm), view
- **Tasks**: Title, description, due date, priority, status, tags
- **Task Editor**: Form validation (title required, future due date)
- **Global Search**: Search by title **and** tags
- **Offline Persistence**: `sqflite` with schema versioning + migration
- **State Management**: Riverpod (AsyncNotifier → Repository → DAO)
- **UI States**: Loading, empty, error (with retry)
- **Responsive**: Works on phones and tablets
- **Accessibility**: Semantics, large tap targets
- **5+ Tests**: Repository, state, widget, golden, validation

### Nice-to-Haves (Included)

- Tag chips with **color**
- **"Due Soon"** section (next 48h)
- **Light/Dark theme** is added according to system current **themee**
- **Completion animation** (strikethrough + fade)

---

## How to Run

```bash
# 1. Get dependencies
flutter pub get

# 2. Run the app
flutter run

# 3. Run tests
flutter test
```
