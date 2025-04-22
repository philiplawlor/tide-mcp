# Tide MCP

A cross-platform app for tides, moon phases, and fishing/hunting predictions. Now supports learning any town/location selected by users.

**Version:** 1.2.7

Built with:
- **Backend:** FastAPI (Python) + SQLite (locations.db)
- **Frontend:** Flutter (Dart)

---

## Getting Started

### Backend Setup (FastAPI)

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```
2. **Create and activate a virtual environment:**
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   ```
3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
4. **Configure environment variables:**
   - Copy `.env.sample` to `.env` and add any required API keys or settings.
5. **Start the backend server:**
   ```bash
   uvicorn main:app --reload
   ```

### Frontend Setup (Flutter)

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```
2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```

## Testing

- The app now supports robust widget testing using a test-only parameter (`initialLoading`) in `TideHomePage` for modern, testable UI state injection.
- To run tests:
  ```bash
  flutter test
  ```

## Changelog Automation

- The changelog ([CHANGES.md](CHANGES.md)) is automatically generated from commit history using [`git-cliff`](https://github.com/orhun/git-cliff).
- To update the changelog, run:
  ```bash
  ./scripts/update_changelog.sh
  ```
  (Requires `git-cliff` to be installed. See [git-cliff releases](https://github.com/orhun/git-cliff/releases).)

## Versioning Automation

- The project version is stored in the `VERSION` file and in the README.
- To bump the version:
  - For a major release: `./scripts/bump_version.sh major`
  - For a new feature: `./scripts/bump_version.sh minor`
  - For a fix: `./scripts/bump_version.sh patch`
- This will update both the `VERSION` file and the version in the README.

## Features

- Location learning: Select any town/location and it will be stored for future lookups.
- Tide, moon, and prediction data are shown only after a location is selected.
- SQLite database for local location storage.
- Modern testability patterns for Flutter frontend.

---

## Changelog

- **1.2.6**: Refactor: Removed all references to towns.json and stations.json. The backend now uses a default station for manual/geocoded locations.
- **1.2.5**: Fixed: Tide data is now displayed after entering a manual location and pressing enter. The UI now shows tide data for both database and manual/geocoded locations.
- **1.2.4**: Fixed: Manual location entry now works when hitting return/enter in the location field. Users can now enter any location and immediately fetch tide data by pressing enter.
- **1.2.2**: Locations not in the database are now selectable and return estimated tides using the nearest NOAA station. Backend API returns an `estimated` flag and source station info for non-database locations.
- **1.2.1**: Added testable constructor to `TideHomePage` for robust widget testing. All tests now pass reliably. Updated docs for modern testability.
- **1.2.0**: Switched to SQLite for locations, improved UI/UX, added location learning.

---
