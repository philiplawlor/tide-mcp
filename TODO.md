# TODO for Location Selection & Proximity Features

## Next Steps

- [x] Switch backend from towns.json to a local SQLite DB that learns new locations as users select them. (v1.2.0)
- [x] Migrate legacy towns from towns.json to the locations database. (v1.2.0)
- [x] Update frontend to POST to /locations/add when a new location is selected, so the backend learns new towns. (v1.2.0)
- [x] Allow users to fetch tide/fishing data for any selected town/zip, not just Stamford by default. (v1.2.0)
- [x] Automatically reload tide/fishing data when a new location is selected in the UI. (v1.2.0)
- [ ] Improve UI/UX of the location selector (e.g., make it more prominent, add map view, etc.)
- [ ] Handle geolocation permissions and errors gracefully in the frontend.
- [ ] Optionally, cache recent location selections for quick access.
- [ ] Add tests for new backend endpoints (`/locations/search`, `/locations/add`, and `/locations/nearby`).
- [ ] Document the new endpoints and frontend features in the project README (ongoing).
