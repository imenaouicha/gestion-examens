import streamlit as st
import pandas as pd
from db import get_connection

# ===========================
# OUTILS BDD
# ===========================

def execute_query(query, params=None):
    conn = get_connection()
    try:
        return pd.read_sql(query, conn, params=params)
    finally:
        conn.close()

def execute_update(query, params=None):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(query, params)
        conn.commit()
        return True
    except Exception as e:
        conn.rollback()
        st.error(f"Erreur SQL : {e}")
        return False
    finally:
        conn.close()

# ===========================
# INTERFACE CHEF DE DEPARTEMENT
# ===========================

def interface_chefdept(user):
    # Recuperation du lien reel avec le departement
    user_id = user.get("id")
    df_link = execute_query("""
        SELECT dept_id FROM planning.professeurs 
        WHERE utilisateur_id = %s LIMIT 1
    """, (user_id,))

    if not df_link.empty:
        dept_id = int(df_link.iloc[0]['dept_id'])
    else:
        st.error("Erreur : Ce compte n'est lie a aucun departement.")
        return

    # ===========================
    # STYLE GLOBAL (DESIGN EPURE)
    # ===========================
    st.markdown("""
    <style>
    .main { background-color: #f8f9fa; }
    .stSidebar { background-color: #ffffff !important; border-right: 1px solid #e0e0e0; }
    
    /* Boutons uniformes bleu marine */
    .stButton>button {
        width: 100%;
        border-radius: 4px;
        border: 1px solid #002b5c;
        background-color: #002b5c;
        color: white;
        padding: 0.5rem;
    }
    .stButton>button:hover {
        background-color: #004085;
        border-color: #004085;
    }
    
    /* Titres sections */
    h3 { color: #002b5c; font-family: 'Segoe UI', sans-serif; font-weight: 600; margin-top: 1rem; }
    
    /* Nettoyage bordures sidebar */
    hr { margin: 1rem 0; }
    </style>
    """, unsafe_allow_html=True)

    # ===========================
    # SIDEBAR
    # ===========================
    with st.sidebar:
        st.markdown("### Menu")
        menu = st.radio(
            "Navigation",
            ["Statistiques", "Examens", "Conflits", "Validation"],
            label_visibility="collapsed"
        )
        
        st.markdown("---")
        if st.button("Deconnexion"):
            st.session_state.clear()
            st.rerun()

    # ===========================
    # CONTENU PAR MENU
    # ===========================

    if menu == "Statistiques":
        st.markdown("### Statistiques par formation")
        df_stats = execute_query("""
            SELECT f.nom AS formation, COUNT(e.id) AS nombre_examens
            FROM planning.formations f
            LEFT JOIN planning.modules m ON m.formation_id = f.id
            LEFT JOIN planning.examens e ON e.module_id = m.id
            WHERE f.dept_id = %s
            GROUP BY f.nom
            ORDER BY f.nom
        """, (dept_id,))
        
        if not df_stats.empty:
            st.dataframe(df_stats, use_container_width=True, hide_index=True)
            st.bar_chart(df_stats.set_index("formation"))
        else:
            st.info("Aucune donnee disponible.")

    elif menu == "Examens":
        st.markdown("### Planning des examens")
        df_examens = execute_query("""
            SELECT 
                e.id, f.nom AS formation, m.nom AS module,
                p.nom AS professeur, l.nom AS salle,
                e.date_heure, e.duree_minutes, e.statut
            FROM planning.examens e
            JOIN planning.modules m ON e.module_id = m.id
            JOIN planning.formations f ON m.formation_id = f.id
            JOIN planning.professeurs p ON e.prof_id = p.id
            JOIN planning.lieu_examen l ON e.salle_id = l.id
            WHERE f.dept_id = %s
            ORDER BY e.date_heure
        """, (dept_id,))
        st.dataframe(df_examens, use_container_width=True, hide_index=True)

    elif menu == "Conflits":
        st.markdown("### Analyse des conflits")
        df_conflits = execute_query("""
            SELECT 
                f.nom AS formation, DATE(e.date_heure) AS jour,
                COUNT(e.id) AS nb_examens
            FROM planning.examens e
            JOIN planning.modules m ON e.module_id = m.id
            JOIN planning.formations f ON m.formation_id = f.id
            WHERE f.dept_id = %s
            GROUP BY f.nom, DATE(e.date_heure)
            HAVING COUNT(e.id) > 1
            ORDER BY jour
        """, (dept_id,))
        
        if df_conflits.empty:
            st.success("Aucun conflit detecte.")
        else:
            st.warning("Conflits de dates identifies.")
            st.dataframe(df_conflits, use_container_width=True, hide_index=True)

    elif menu == "Validation":
        st.markdown("### Validation des examens")
        df_all = execute_query("""
            SELECT e.id, m.nom AS module, f.nom AS formation, e.date_heure, e.statut
            FROM planning.examens e
            JOIN planning.modules m ON e.module_id = m.id
            JOIN planning.formations f ON m.formation_id = f.id
            WHERE f.dept_id = %s AND e.statut = 'en attente'
            ORDER BY e.date_heure
        """, (dept_id,))

        if df_all.empty:
            st.info("Aucun examen en attente.")
        else:
            st.dataframe(df_all, use_container_width=True, hide_index=True)
            
            st.markdown("---")
            col_sel, col_act = st.columns([2, 1])
            
            with col_sel:
                exam_id = st.selectbox("ID Examen", df_all["id"], label_visibility="collapsed")
            
            with col_act:
                c1, c2 = st.columns(2)
                with c1:
                    if st.button("Valider"):
                        if execute_update("UPDATE planning.examens SET statut='validé' WHERE id=%s", (exam_id,)):
                            st.rerun()
                with c2:
                    if st.button("Refuser"):
                        if execute_update("UPDATE planning.examens SET statut='refusé' WHERE id=%s", (exam_id,)):
                            st.rerun()