# Tide MCP

A cross-platform app for tides, moon phases, and fishing/hunting predictions. Now supports learning any town/location selected by users.

**Version:** 1.3.1

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

## Backend Endpoint Testing

Automated tests (pytest + httpx + pytest-asyncio) cover:
- `/locations/search`: Now uses `query` as the parameter (not `q`). Returns `{"locations": [...]}`. Tests cover valid queries, missing/empty query (returns empty list), and edge cases.
- `/locations/add`: Valid adds, missing/invalid fields, duplicate/edge cases.
- `/locations/nearby`: Valid lookups, invalid/malformed/edge-case input (returns 404 or 422 as appropriate).

To run backend tests:
```bash
cd backend
source .venv/bin/activate
pytest tests/
```

All backend tests pass as of v1.3.0. Test assertions are aligned with actual API response and status codes.

## Changelog Automation

- The changelog ([CHANGES.md](CHANGES.md)) is automatically generated from commit history using [`git-cliff`](https://github.com/orhun/git-cliff).
- To update the changelog, run:
  ```bash
  ./scripts/update_changelog.sh
  ```
  (Requires `git-cliff` to be installed. See [git-cliff releases](https://github.com/orhun/git-cliff/releases))

## Features

- Location learning: Select any town/location and it will be stored for future lookups.
- Tide, moon, and prediction data are shown only after a location is selected.
- SQLite database for local location storage.
- Modern testability patterns for Flutter frontend.

---

## Future Upgraded Release: Raspberry Pi Kiosk Frontend

A future release will add a second frontend—a lightweight UI (possibly in Flutter) for Raspberry Pi kiosk mode:
- Takes over the screen and displays local clock, weather, tide, fishing, and hunting data.
- Updates every 15-30 minutes throughout the day, every other hour from midnight to 6am local time.
- User-adjustable dark/light mode schedule.
- Keeps screen awake from 6am to midnight (user adjustable range).
- Always-on, glanceable display optimized for kiosk use.
- Integrates with backend for real-time data and robust error handling.
- Provides configuration UI for schedule and display options.

---

## Changelog

- **1.3.1**: (upcoming) Planned Raspberry Pi kiosk frontend: lightweight UI for always-on display, configurable schedule, and real-time updates for clock, weather, tide, fishing, and hunting data.
- **1.3.0**: Backend: `/locations/search` now uses `query` as the parameter and returns `{"locations": [...]}`. Automated backend tests updated to match new response structure and status codes; all backend tests now pass. Also covers `/locations/add`, `/locations/nearby` (valid, invalid, edge-case inputs; pytest + httpx + pytest-asyncio).
- **1.2.9**: Fix: Added assets/VERSION to pubspec.yaml and moved VERSION file to assets directory so app version is loaded and displayed dynamically in the app bar and MaterialApp title.
- **1.2.8**: Bugfix: The "week at a glance" feature now appears immediately after a location is selected, without needing to refresh. This was fixed by ensuring fetchAll() is called after location selection, not just for today data.
- **1.2.7**: Refactor: Removed all references to towns.json and stations.json. The backend now uses a default station for manual/geocoded locations.
- **1.2.6**: Fixed: Tide data is now displayed after entering a manual location and pressing enter. The UI now shows tide data for both database and manual/geocoded locations.
- **1.2.4**: Fixed: Manual location entry now works when hitting return/enter in the location field. Users can now enter any location and immediately fetch tide data by pressing enter.
- **1.2.2**: Locations not in the database are now selectable and return estimated tides using the nearest NOAA station. Backend API returns an `estimated` flag and source station info for non-database locations.
- **1.2.1**: Added testable constructor to `TideHomePage` for robust widget testing. All tests now pass reliably. Updated docs for modern testability.
- **1.2.0**: Switched to SQLite for locations, improved UI/UX, added location learning.

---
