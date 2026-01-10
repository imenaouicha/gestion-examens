import psycopg2
from psycopg2 import OperationalError

DB_HOST = "aws-0-eu-central-1.pooler.supabase.com"
DB_NAME = "postgres"
DB_USER = "postgres"
DB_PASSWORD = "imanebdd2003"
DB_PORT = "6543"

def get_connection():
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            port=DB_PORT,
            sslmode="require"
        )
        return conn
    except OperationalError as e:
        print("Erreur de connexion à la base de données :", e)
        return None
