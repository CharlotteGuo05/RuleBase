# recommender/test_db.py
from recommender.db import get_conn

def main():
    with get_conn() as conn, conn.cursor() as cur:
        # List all tables in the public schema
        cur.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'public';")
        tables = [row[0] for row in cur.fetchall()]
    print("Your tables:", tables)

if __name__ == "__main__":
    main()
