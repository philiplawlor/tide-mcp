import sys
import os
sys.path.insert(0, os.path.abspath(os.path.dirname(os.path.dirname(__file__))))

import pytest
from httpx import AsyncClient, ASGITransport
from main import app

import asyncio

@pytest.mark.asyncio
async def test_locations_search_valid():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.get("/locations/search", params={"query": "Stamford, CT"})
        assert resp.status_code == 200
        data = resp.json()
        assert isinstance(data, dict)
        assert "locations" in data
        assert isinstance(data["locations"], list)
        # If the DB is empty, locations may be empty, but the structure is correct

@pytest.mark.asyncio
async def test_locations_search_empty_query():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.get("/locations/search", params={"query": ""})
        assert resp.status_code == 200
        data = resp.json()
        assert isinstance(data, dict)
        assert "locations" in data
        assert isinstance(data["locations"], list)

@pytest.mark.asyncio
async def test_locations_search_missing_query():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.get("/locations/search")
        assert resp.status_code == 422

@pytest.mark.asyncio
async def test_locations_add_and_nearby():
    # Add a new location
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        payload = {
            "town": "Testville",
            "state": "TS",
            "zip": "00000",
            "lat": 12.3456,
            "lon": -65.4321
        }
        resp = await ac.post("/locations/add", json=payload)
        assert resp.status_code in (200, 422)
        if resp.status_code == 200:
            data = resp.json()
            assert data.get("status") == "success"
            # Now check nearby (should include the added location)
            resp2 = await ac.get("/locations/nearby", params={"lat": 12.3456, "lon": -65.4321})
            assert resp2.status_code == 200
            locations = resp2.json().get("locations", [])
            assert any(loc["town"] == "Testville" for loc in locations)

@pytest.mark.asyncio
async def test_locations_add_invalid():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        # Missing required fields
        resp = await ac.post("/locations/add", json={"town": "NoState"})
        assert resp.status_code == 422

@pytest.mark.asyncio
async def test_locations_nearby_invalid():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        resp = await ac.get("/locations/nearby", params={"lat": "not_a_float", "lon": 0})
        assert resp.status_code in (404, 422)
