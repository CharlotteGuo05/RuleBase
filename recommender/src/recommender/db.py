# src/recommender/db.py
import os
from dotenv import load_dotenv
import psycopg

# 1. Load your .env
load_dotenv()

# 2. Grab the URL
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("Please set DATABASE_URL in your .env")

# 3. Use it directly
def get_conn():
    return psycopg.connect(DATABASE_URL)
