import os
from dotenv import load_dotenv
import psycopg2
from pgvector.psycopg2 import register_vector

load_dotenv()

def get_db_connection():
    """Establish connection to PostgreSQL and register pgvector."""
    db_url = os.getenv("DATABASE_URL", "postgresql://postgres:%40Minhtrung1408@localhost:5432/hrm_ai")
    conn = psycopg2.connect(db_url)
    register_vector(conn)
    return conn
