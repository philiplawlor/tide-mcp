## 1.2.8 - 2025-04-22
- Enhancement: When a user enters only "City, State" as a manual location, the app now automatically looks up the ZIP code using geocoding and appends it to the location display and backend request if found.
- UI: The app bar and all relevant UI now display the location as "City, State ZIP" when the ZIP is available.
- Bugfix: Ensured that ZIP is always sent to the backend for both today and week tide data requests when available.

---

