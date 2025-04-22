# frontend

Tide MCP - Local Tides App

## Version: 1.2.8

### Recent Changes
- When a user enters only "City, State" as a manual location, the app now automatically looks up the ZIP code using geocoding and appends it to the location display and backend request if found.
- The app bar and all relevant UI now display the location as "City, State ZIP" when the ZIP is available.
- Ensured that ZIP is always sent to the backend for both today and week tide data requests when available.

### Features
- Dynamic app bar title: `Local Tides [LOCATION_NAME] - v[VERSION]`.
- Select or enter any location (not just from the database).
- Geocoding via Nominatim OpenStreetMap API for manual entries.
- Tide/fishing data fetched for any location, including new ones.
- Version is loaded from the assets VERSION file.

### Getting Started

This is a Flutter application for viewing local tide and fishing data. For help getting started with Flutter development, view the [online documentation](https://docs.flutter.dev/).
