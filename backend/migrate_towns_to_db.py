import json
import os
import sqlite3

dir_path = os.path.dirname(__file__)
DB_PATH = os.path.join(dir_path, "locations.db")
TOWNS_PATH = os.path.join(dir_path, "towns.json")

def migrate():
    with open(TOWNS_PATH, "r") as f:
        towns = json.load(f)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    for t in towns:
        c.execute("SELECT id FROM locations WHERE town=? AND state=?", (t["town"], t["state"]))
        if not c.fetchone():
            c.execute(
                "INSERT INTO locations (town, state, zip, lat, lon, stationId) VALUES (?, ?, ?, ?, ?, ?)",
                (t["town"], t["state"], t["zip"], t["lat"], t["lon"], t["stationId"])
            )
    conn.commit()
    conn.close()
    print(f"Migrated {len(towns)} towns to locations.db")

if __name__ == "__main__":
    migrate()
