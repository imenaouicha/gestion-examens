import psycopg2

def get_connection():
    return psycopg2.connect(
        host="aws-0-eu-central-1.pooler.supabase.com",  # Host du pooler
        port=6543,                                      # Port du pooler
        database="postgres",
        user="postgres",
        password="imanebdd2003",                    # Remplace par ton mot de passe Supabase
        sslmode="require"
    )

