import os
import sqlite3
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import datetime
import requests
import math
import json

# Paths
DB_PATH = os.path.join(os.path.dirname(__file__), "locations.db")
STATIONS_PATH = os.path.join(os.path.dirname(__file__), "stations.json")

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS locations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        town TEXT,
        state TEXT,
        zip TEXT,
        lat REAL,
        lon REAL,
        stationId TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        last_used TEXT DEFAULT CURRENT_TIMESTAMP
    )''')
    conn.commit()
    conn.close()

init_db()

@app.get("/")
def root():
    return {"status": "Tide MCP backend running"}

NOAA_DEFAULT_STATION = "8467150"  # Bridgeport, CT (closest to Stamford)
NOAA_PRODUCT = "predictions"
NOAA_DATUM = "MLLW"
NOAA_UNITS = "english"
NOAA_TIMEZONE = "lst_ldt"
NOAA_API = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
MOON_API = "https://api.farmsense.net/v1/moonphases/"

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

def load_stations():
    with open(STATIONS_PATH, "r") as f:
        return json.load(f)

# --- LOCATION DB UTILITIES ---
def get_locations(query=None, limit=5):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    if query:
        q = f"%{query.lower()}%"
        c.execute("SELECT * FROM locations WHERE LOWER(town) LIKE ? OR LOWER(state) LIKE ? OR zip LIKE ? ORDER BY last_used DESC LIMIT ?", (q, q, q, limit))
    else:
        c.execute("SELECT * FROM locations ORDER BY last_used DESC LIMIT ?", (limit,))
    rows = c.fetchall()
    conn.close()
    return [dict(zip([col[0] for col in c.description], row)) for row in rows]

def add_or_update_location(town, state, zip_code, lat, lon, stationId):
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    # Check if already exists
    c.execute("SELECT id FROM locations WHERE town=? AND state=?", (town, state))
    row = c.fetchone()
    if row:
        c.execute("UPDATE locations SET last_used=CURRENT_TIMESTAMP WHERE id=?", (row[0],))
    else:
        c.execute("INSERT INTO locations (town, state, zip, lat, lon, stationId) VALUES (?, ?, ?, ?, ?, ?)", (town, state, zip_code, lat, lon, stationId))
    conn.commit()
    conn.close()

@app.get("/locations/search")
def locations_search(q: str = Query(...), limit: int = 5):
    results = get_locations(q, limit)
    return {"locations": results}

@app.post("/locations/add")
def add_location(town: str, state: str, zip_code: str, lat: float, lon: float, stationId: str):
    add_or_update_location(town, state, zip_code, lat, lon, stationId)
    return {"status": "added"}

@app.get("/stations/nearby")
def stations_nearby(lat: float = Query(...), lon: float = Query(...), limit: int = 5):
    stations = load_stations()
    for s in stations:
        s["distance_km"] = haversine(lat, lon, float(s["lat"]), float(s["lon"]))
    stations.sort(key=lambda s: s["distance_km"])
    return {"stations": stations[:limit]}

@app.get("/tide/today")
def tide_today(
    date: str = Query(None),
    station: str = Query(None),
    lat: float = Query(None),
    lon: float = Query(None),
    town: str = Query(None),
    state: str = Query(None)
):
    if date is None:
        date = datetime.date.today().strftime("%Y-%m-%d")
    estimated = False
    used_station = station
    # If no station provided, but lat/lon provided, find nearest station
    if not station and lat is not None and lon is not None:
        stations = load_stations()
        for s in stations:
            s["distance_km"] = haversine(lat, lon, float(s["lat"]), float(s["lon"]))
        stations.sort(key=lambda s: s["distance_km"])
        nearest = stations[0]
        used_station = nearest["id"]
        estimated = True
        source_station = nearest
    else:
        source_station = None
    params = {
        "station": used_station or NOAA_DEFAULT_STATION,
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
    today_jd = int(datetime.datetime.strptime(date, "%Y-%m-%d").strftime("%j"))
    moon_resp = requests.get(MOON_API, params={"d": today_jd})
    moon_data = moon_resp.json()
    moon_phase = moon_data[0]["Phase"] if moon_data else "Unknown"
    response = {"date": date, "highs": highs, "lows": lows, "moon_phase": moon_phase}
    if estimated:
        response["estimated"] = True
        response["source_station"] = source_station
    return response

@app.get("/tide/week")
def tide_week(
    station: str = Query(None),
    lat: float = Query(None),
    lon: float = Query(None),
    town: str = Query(None),
    state: str = Query(None)
):
    estimated = False
    used_station = station
    # If no station provided, but lat/lon provided, find nearest station
    if not station and lat is not None and lon is not None:
        stations = load_stations()
        for s in stations:
            s["distance_km"] = haversine(lat, lon, float(s["lat"]), float(s["lon"]))
        stations.sort(key=lambda s: s["distance_km"])
        nearest = stations[0]
        used_station = nearest["id"]
        estimated = True
        source_station = nearest
    else:
        source_station = None
    week = []
    today = datetime.date.today()
    for i in range(7):
        day = today + datetime.timedelta(days=i)
        date_str = day.strftime("%Y%m%d")
        params = {
            "station": used_station or NOAA_DEFAULT_STATION,
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
        day_result = {"date": day.strftime("%Y-%m-%d"), "highs": highs, "lows": lows, "moon_phase": moon_phase}
        week.append(day_result)
    response = {"week": week}
    if estimated:
        response["estimated"] = True
        response["source_station"] = source_station
    return response

@app.get("/predictions/week")
def predictions_week():
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
