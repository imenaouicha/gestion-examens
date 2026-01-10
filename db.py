import psycopg2
import streamlit as st

def get_connection():
    # On force les paramètres du pooler
    return psycopg2.connect(
        host="aws-0-eu-central-1.pooler.supabase.com",
        database="postgres",
        user="postgres.pgnlawlfykbmrivtothz",
        password=st.secrets["DB_PASSWORD"],
        port=6543,
        sslmode="require"
    )
