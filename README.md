# Tide MCP

A cross-platform app for tides, moon phases, and fishing/hunting predictions. Now supports learning any town/location selected by users.

**Version:** 1.3.2

Built with:
- **Backend:** FastAPI (Python) + SQLite (locations.db)
- **Frontend:** Flutter (Dart)

---

## MCP Servers and Tools Used

This project is managed and automated using the Model Context Protocol (MCP) with the following servers and tools:

### MCP Servers

1. **filesystem MCP server**
   - Handles all file operations within allowed directories (read, write, edit, list, move, search, etc.).
2. **github MCP server**
   - Integrates with GitHub for repository, branch, file, issue, and pull request management.
3. **brave-search MCP server**
   - Enables web and local business search via the Brave Search API.
4. **sequential-thinking MCP server**
   - Used for advanced, multi-step problem-solving and planning via chain-of-thought reasoning.

### Tools in Use

#### Filesystem Tools
- Create, read, write, edit, and move files and directories
- List directory contents and search for files
- Get file/directory metadata

#### GitHub Tools
- Create/update/read files and directories in repositories
- Manage branches, issues, pull requests, and comments
- Search code, repositories, issues, and users

#### Brave Search Tools
- Web search for general queries
- Local business search

#### Sequential Thinking Tools
- Advanced problem decomposition and reasoning

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
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Run the app:**
   ```bash
   flutter run
   ```

---

## Changelog

- **1.3.2**: Maintenance: Added `.venv/` and `backend/.venv/` to `.gitignore` to ensure Python virtual environment files and folders are not tracked by git.
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
