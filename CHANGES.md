## 1.3.0 - feature branch: centered-tide-chart (not yet merged to main)
### Added
- Tide chart now displays a 12-hour window centered on "Now" (current time).
- X-axis labels are hourly, showing hours before and after "Now" (e.g., -6, -5, ..., 0/Now, ..., +5, +6).
- The tide curve is interpolated at 30-minute increments to fit the graph window.
- "Now" is always visually centered in the graph window.
- Vertical lines for solar/lunar events and "Now" remain accurately positioned.

## 1.2.9 - 2025-04-22
- Fix: Added assets/VERSION to pubspec.yaml and moved VERSION file to assets directory so app version is loaded and displayed dynamically in the app bar and MaterialApp title.
- Chore: Updated README and project structure to ensure asset versioning is robust and future-proof.

---

## 1.2.8 - 2025-04-22
- Enhancement: When a user enters only "City, State" as a manual location, the app now automatically looks up the ZIP code using geocoding and appends it to the location display and backend request if found.
- UI: The app bar and all relevant UI now display the location as "City, State ZIP" when the ZIP is available.
- Bugfix: Ensured that ZIP is always sent to the backend for both today and week tide data requests when available.
- Bugfix: The "week at a glance" feature now appears immediately after a location is selected, without needing to refresh. This was fixed by ensuring fetchAll() is called after location selection, not just for today data.

---

