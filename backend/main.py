from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"status": "Tide MCP backend running"}

import datetime
import requests
from fastapi import Query
from fastapi import Request
from fastapi.responses import JSONResponse
import math
import json
import os

# Helper to get NOAA tides for Stamford, CT (Bridgeport station: 8467150)
NOAA_DEFAULT_STATION = "8467150"  # Bridgeport, CT (closest to Stamford)
NOAA_PRODUCT = "predictions"
NOAA_DATUM = "MLLW"
NOAA_UNITS = "english"
NOAA_TIMEZONE = "lst_ldt"
NOAA_API = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"

# Helper to get moon phase from a free API (e.g., farmsense.net)
MOON_API = "https://api.farmsense.net/v1/moonphases/"  # No API key needed

# Path to cached NOAA stations metadata
STATIONS_PATH = os.path.join(os.path.dirname(__file__), "stations.json")

# Haversine formula to compute distance between two lat/lon points
def haversine(lat1, lon1, lat2, lon2):
    R = 6371  # km
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# Load stations from local cache
def load_stations():
    with open(STATIONS_PATH, "r") as f:
        return json.load(f)

@app.get("/stations/nearby")
def stations_nearby(lat: float = Query(...), lon: float = Query(...), limit: int = 5):
    stations = load_stations()
    for s in stations:
        s["distance_km"] = haversine(lat, lon, float(s["lat"]), float(s["lon"]))
    stations.sort(key=lambda s: s["distance_km"])
    return {"stations": stations[:limit]}

@app.get("/tide/today")
def tide_today(date: str = Query(None, description="YYYY-MM-DD, default today")):
    if date is None:
        date = datetime.date.today().strftime("%Y-%m-%d")
    # NOAA API only supports 'today', 'latest', or 'recent' as date values (not YYYY-MM-DD)
    params = {
        "station": NOAA_DEFAULT_STATION,
        "product": NOAA_PRODUCT,
        "date": "today",
        "datum": NOAA_DATUM,
        "units": NOAA_UNITS,
        "time_zone": NOAA_TIMEZONE,
        "format": "json",
        "interval": "hilo"
    }
    resp = requests.get(NOAA_API, params=params)
    data = resp.json()
    highs = [t for t in data.get("predictions", []) if t["type"] == "H"]
    lows = [t for t in data.get("predictions", []) if t["type"] == "L"]
    # Get moon phase
    today_jd = int(datetime.datetime.strptime(date, "%Y-%m-%d").strftime("%j"))
    moon_resp = requests.get(MOON_API, params={"d": today_jd})
    moon_data = moon_resp.json()
    moon_phase = moon_data[0]["Phase"] if moon_data else "Unknown"
    return {"date": date, "highs": highs, "lows": lows, "moon_phase": moon_phase}

@app.get("/tide/week")
def tide_week():
    week = []
    today = datetime.date.today()
    for i in range(7):
        day = today + datetime.timedelta(days=i)
        date_str = day.strftime("%Y%m%d")
        params = {
            "station": NOAA_DEFAULT_STATION,
            "product": NOAA_PRODUCT,
            "date": date_str,
            "datum": NOAA_DATUM,
            "units": NOAA_UNITS,
            "time_zone": NOAA_TIMEZONE,
            "format": "json",
            "interval": "hilo"
        }
        resp = requests.get(NOAA_API, params=params)
        data = resp.json()
        predictions = data.get("predictions", [])
        highs = [t for t in predictions if t["type"] == "H"]
        lows = [t for t in predictions if t["type"] == "L"]
        try:
            jd = int(day.strftime("%j"))
            moon_resp = requests.get(MOON_API, params={"d": jd})
            moon_data = moon_resp.json()
            moon_phase = moon_data[0]["Phase"] if moon_data else "Unknown"
        except Exception:
            moon_phase = "Unknown"
        week.append({"date": day.strftime("%Y-%m-%d"), "highs": highs, "lows": lows, "moon_phase": moon_phase})
    return {"week": week}


@app.get("/predictions/week")
def predictions_week():
    # Placeholder for solunar/fishing/hunting predictions
    # Most free APIs require registration, so here we mock the data
    today = datetime.date.today()
    predictions = []
    for i in range(7):
        day = today + datetime.timedelta(days=i)
        predictions.append({
            "date": day.strftime("%Y-%m-%d"),
            "fishing": "Good" if i % 2 == 0 else "Fair",
            "hunting": "Average" if i % 3 == 0 else "Below Average"
        })
    return {"predictions": predictions}
