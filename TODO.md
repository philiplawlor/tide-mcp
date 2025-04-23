# TODO for Location Selection & Proximity Features

## Next Steps

- [x] Switch backend from towns.json to a local SQLite DB that learns new locations as users select them. (v1.2.0)
- [x] Migrate legacy towns from towns.json to the locations database. (v1.2.0)
- [x] Update frontend to POST to /locations/add when a new location is selected, so the backend learns new towns. (v1.2.0)
- [x] Allow users to fetch tide/fishing data for any selected town/zip, not just Stamford by default. (v1.2.0)
- [x] Automatically reload tide/fishing data when a new location is selected in the UI. (v1.2.0)
- [x] Improve UI/UX of the location selector (added `onSubmitted` for return/enter support, better manual entry UX). (v1.2.4)
- [x] Bugfix: The "week at a glance" feature now appears immediately after a location is selected, without needing to refresh. (v1.2.8)
- [x] Fix: Added assets/VERSION to pubspec.yaml and moved VERSION file to assets directory so app version is loaded and displayed dynamically in the app bar and MaterialApp title. (v1.2.9)
- [ ] Handle geolocation permissions and errors gracefully in the frontend.
- [ ] Optionally, cache recent location selections for quick access.
- [ ] Add tests for new backend endpoints (`/locations/search`, `/locations/add`, and `/locations/nearby`).
- [ ] Document the new endpoints and frontend features in the project README (ongoing).
