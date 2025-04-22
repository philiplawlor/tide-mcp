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

NOAA_DEFAULT_STATION = "8467150"  # Bridgeport, CT (fallback)
NOAA_PRODUCT = "predictions"
NOAA_DATUM = "MLLW"
NOAA_UNITS = "english"
NOAA_TIMEZONE = "lst_ldt"
NOAA_API = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
MOON_API = "https://api.farmsense.net/v1/moonphases/"

# Hardcoded NOAA stations (id, name, lat, lon)
NOAA_STATIONS = [
    {"id": "8418150", "name": "Portland, ME", "lat": 43.6615, "lon": -70.2553},
    {"id": "8419807", "name": "Kennebunkport, ME", "lat": 43.3618, "lon": -70.4762},
    {"id": "8413320", "name": "Bar Harbor, ME", "lat": 44.3876, "lon": -68.2039},
    {"id": "8419317", "name": "Wells, ME", "lat": 43.3212, "lon": -70.5806},
    {"id": "8419528", "name": "York, ME", "lat": 43.1617, "lon": -70.6467},
    {"id": "8423745", "name": "Portsmouth, NH", "lat": 43.0718, "lon": -70.7626},
    {"id": "8429489", "name": "Hampton, NH", "lat": 42.9117, "lon": -70.8120},
    {"id": "8440466", "name": "Newburyport, MA", "lat": 42.8126, "lon": -70.8773},
    {"id": "8441841", "name": "Gloucester, MA", "lat": 42.6159, "lon": -70.6610},
    {"id": "8442645", "name": "Salem, MA", "lat": 42.5195, "lon": -70.8967},
    {"id": "8443970", "name": "Boston, MA", "lat": 42.3601, "lon": -71.0589},
    {"id": "8446493", "name": "Plymouth, MA", "lat": 41.9584, "lon": -70.6673},
    {"id": "8447435", "name": "Chatham, MA", "lat": 41.6826, "lon": -69.9656},
    {"id": "8447930", "name": "Hyannis, MA", "lat": 41.6525, "lon": -70.2881},
    {"id": "8447180", "name": "Sandwich, MA", "lat": 41.7587, "lon": -70.4934},
    {"id": "8452660", "name": "Newport, RI", "lat": 41.4901, "lon": -71.3128},
    {"id": "8454658", "name": "Narragansett, RI", "lat": 41.4501, "lon": -71.4495},
    {"id": "8455189", "name": "Westerly, RI", "lat": 41.3776, "lon": -71.8273},
    {"id": "8461490", "name": "Stonington, CT", "lat": 41.3357, "lon": -71.9054},
    {"id": "8461809", "name": "Mystic, CT", "lat": 41.3543, "lon": -71.9665},
    {"id": "8465705", "name": "Old Saybrook, CT", "lat": 41.2915, "lon": -72.3764},
    {"id": "8467150", "name": "Bridgeport, CT", "lat": 41.1792, "lon": -73.1894},
    {"id": "8468448", "name": "Stamford, CT", "lat": 41.0534, "lon": -73.5387},
]

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
    return {"stations": []}

@app.get("/tide/today")
def tide_today(
    date: str = Query(None),
    station: str = Query(None),
    lat: float = Query(None),
    lon: float = Query(None),
    town: str = Query(None),
    state: str = Query(None),
    zip: str = Query('', alias='zip')
):
    if date is None:
        date = datetime.date.today().strftime("%Y-%m-%d")
    estimated = False
    used_station = station
    # If no station provided, but lat/lon provided, find nearest station
    if not station and lat is not None and lon is not None:
        min_dist = float('inf')
        nearest = None
        for s in NOAA_STATIONS:
            dist = haversine(lat, lon, s["lat"], s["lon"])
            if dist < min_dist:
                min_dist = dist
                nearest = s
        used_station = nearest["id"] if nearest else NOAA_DEFAULT_STATION
        estimated = True
        source_station = nearest
        # Save location to locations.db
        if town and state:
            add_or_update_location(town, state, zip, lat, lon, used_station)
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
    state: str = Query(None),
    zip: str = Query('', alias='zip')
):
    estimated = False
    used_station = station
    # If no station provided, but lat/lon provided, find nearest station
    if not station and lat is not None and lon is not None:
        min_dist = float('inf')
        nearest = None
        for s in NOAA_STATIONS:
            dist = haversine(lat, lon, s["lat"], s["lon"])
            if dist < min_dist:
                min_dist = dist
                nearest = s
        used_station = nearest["id"] if nearest else NOAA_DEFAULT_STATION
        estimated = True
        source_station = nearest
        # Save location to locations.db
        if town and state:
            add_or_update_location(town, state, zip, lat, lon, used_station)
    else:
        source_station = None
    week = []
    today = datetime.date.today()
    end_day = today + datetime.timedelta(days=6)
    date_range = f"{today.strftime('%Y%m%d')},{end_day.strftime('%Y%m%d')}"
    params = {
        "station": used_station or NOAA_DEFAULT_STATION,
        "product": NOAA_PRODUCT,
        "date": date_range,
        "datum": NOAA_DATUM,
        "units": NOAA_UNITS,
        "time_zone": NOAA_TIMEZONE,
        "format": "json",
        "interval": "hilo"
    }
    resp = requests.get(NOAA_API, params=params)
    data = resp.json()
    predictions = data.get("predictions", [])
    # Group predictions by date
    predictions_by_date = {}
    for t in predictions:
        d = t["t"][:10]  # e.g. '2025-04-22'
        if d not in predictions_by_date:
            predictions_by_date[d] = []
        predictions_by_date[d].append(t)
    for i in range(7):
        day = today + datetime.timedelta(days=i)
        day_str = day.strftime("%Y-%m-%d")
        day_preds = predictions_by_date.get(day_str, [])
        highs = [t for t in day_preds if t["type"] == "H"]
        lows = [t for t in day_preds if t["type"] == "L"]
        try:
            jd = int(day.strftime("%j"))
            moon_resp = requests.get(MOON_API, params={"d": jd})
            moon_data = moon_resp.json()
            moon_phase = moon_data[0]["Phase"] if moon_data else "Unknown"
        except Exception:
            moon_phase = "Unknown"
        day_result = {"date": day_str, "highs": highs, "lows": lows, "moon_phase": moon_phase}
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
