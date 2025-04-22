## 1.2.6 - 2025-04-22
- Refactor: Removed all references to towns.json and stations.json. The backend now uses a default station for manual/geocoded locations.

## 1.2.5 - 2025-04-22
- Fixed: Tide data is now displayed after entering a manual location and pressing enter. The UI now shows tide data for both database and manual/geocoded locations.

## 1.2.4 - 2025-04-22
- Fixed: Manual location entry now works when hitting return/enter in the location field. Users can now enter any location and immediately fetch tide data by pressing enter.
- UI: Improved location selector TextField with `onSubmitted` handler.

## 1.2.3 - 2025-04-22
- Fixed a build-breaking bug by removing the undefined `_addLocationIfNotExists` call from `main.dart`.
- Cleaned up the `TideHomePage` class definition to ensure only one valid implementation exists.
# CHANGES.md

All significant changes to this project are documented here, grouped by version and date.

---

## [1.2.2] - 2025-04-22
### Added
- Locations not in the database are now selectable and will return estimated tide schedules using the nearest NOAA station.
- Backend API for `/tide/today` and `/tide/week` now accepts lat/lon and returns an `estimated` flag and `source_station` info for non-database locations.

### Changed
- Patch version bump to 1.2.2 for this backend/API fix.

---

## [1.2.1] - 2025-04-22
### Added
- Modern testability: Introduced `initialLoading` parameter to `TideHomePage` for robust widget testing and state injection.
- All widget tests now pass and reliably check for the correct UI prompt on startup.
- Updated documentation to highlight modern Flutter test patterns and usage.

### Changed
- Test files now use `MaterialApp` and pass `initialLoading: false` for testability.
- README updated with new testability instructions and version bump.

---

## [1.2.0] - 2025-04-21
### Added
- Switched backend location storage from JSON to SQLite database (`locations.db`).
- Migration script to import existing towns from `towns.json` into SQLite.
- Frontend now supports learning and storing new towns/locations selected by users.
- UI prompts user to select location before fetching tide data.
- Test files cleaned up for import style and linting.

### Changed
- Improved UX: App fetches and displays data only after a location is selected.
- Updated README and TODO to reflect new architecture and features.

---

## Older versions
- See project history and commit logs for details prior to 1.2.0.
