import psycopg2
from psycopg2 import OperationalError

def get_connection():
    try:
        conn = psycopg2.connect(
            host="aws-1-eu-west-2.pooler.supabase.com",   # host correct
            database="postgres",
            user="postgres.pgnlawlfykbmrivtothz",         # utilisateur complet
            password="imanebdd2003",                       # ton mot de passe
            port="6543",
            sslmode="require"
        )
        return conn
    except OperationalError as e:
        print("Erreur de connexion à la base de données :", e)
        return None

