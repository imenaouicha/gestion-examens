import psycopg2
import streamlit as st

def get_connection():
    # On construit l'adresse complète directement
    # Format: postgresql://USER:PASSWORD@HOST:PORT/DATABASE
    conn_str = f"postgresql://{st.secrets['DB_USER']}:{st.secrets['DB_PASSWORD']}@{st.secrets['DB_HOST']}:{st.secrets['DB_PORT']}/{st.secrets['DB_NAME']}?sslmode=require"
    
    return psycopg2.connect(conn_str)
