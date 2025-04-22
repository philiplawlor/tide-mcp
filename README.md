# Tide MCP

A Flutter + FastAPI app for Stamford, CT tides, moon phases, and fishing/hunting predictions.

## Setup

### Backend
- `cd backend`
- Copy `.env.sample` to `.env` and add API keys if needed
- `pip install -r requirements.txt`
- `uvicorn main:app --reload`

### Frontend
- `cd frontend`
- `flutter run`

## Features
- Tide chart and times for Stamford, CT
- Moon phases
- Week-at-a-glance view with fishing/hunting predictions
