# Tide MCP

A cross-platform app for Stamford, CT tides, moon phases, and fishing/hunting predictions.

Built with:
- **Backend:** FastAPI (Python)
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
   - The API will be available at `http://localhost:8000`

### Frontend Setup (Flutter)

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```
2. **Ensure Flutter is installed:**
   - [Flutter installation guide](https://docs.flutter.dev/get-started/install)
3. **Get dependencies:**
   ```bash
   flutter pub get
   ```
4. **Run the app:**
   ```bash
   flutter run
   ```
   - The app connects to the backend at `http://localhost:8000` by default.

---

## Features

### Backend (API)
- Tide times and heights for Stamford, CT (or selected NOAA stations)
- Moon phase for the current day and week
- Nearby tide station lookup by latitude/longitude
- Week-at-a-glance tide, moon, and fishing/hunting predictions (mocked)
- CORS enabled for local development

### Frontend (Flutter App)
- Location selection (town/zipcode or geolocation)
- Displays:
  - Today's tide chart, high/low times, and heights
  - Current moon phase
  - Week view: daily tides, moon phase, fishing/hunting predictions
- Selects nearest tide station and shows distance
- Responsive UI for mobile and web

---

## Development Notes
- Backend: Python 3.8+, FastAPI, uvicorn, requests, python-dotenv
- Frontend: Flutter 3+, uses `http`, `fl_chart`, `geolocator` packages
- For production, update backend CORS and API URLs as needed

---

## License
MIT
