import psycopg2
import streamlit as st
import os

def get_connection():
    return psycopg2.connect(
        # On utilise l'hôte direct mais avec le port du pooler
        host="db.pgnlawlfykbmrivtothz.supabase.co", 
        database="postgres",
        user="postgres", # Ici, on remet juste postgres sans le point
        password=st.secrets["DB_PASSWORD"],
        port=6543,
        sslmode="require"
    )
