# frontend

Tide MCP - Local Tides App

## Version: 1.2.4

### Recent Changes
- Manual location entry now works when hitting return/enter in the location field. Users can now enter any location and immediately fetch tide data by pressing enter.
- Improved location selector TextField with `onSubmitted` handler for better UX.

### Features
- Dynamic app bar title: `Local Tides [LOCATION_NAME] - v[VERSION]`.
- Select or enter any location (not just from the database).
- Geocoding via Nominatim OpenStreetMap API for manual entries.
- Tide/fishing data fetched for any location, including new ones.
- Version is loaded from the assets VERSION file.

### Getting Started

This is a Flutter application for viewing local tide and fishing data. For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/).
