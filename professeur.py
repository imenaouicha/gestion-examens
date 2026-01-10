import streamlit as st
import pandas as pd
from datetime import datetime
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
# INTERFACE PROFESSEUR
# ===========================

def interface_professeur(user):
    user_id = user.get("id")

    # 1. Verification du lien Professeur (Securite contre l'erreur Foreign Key)
    df_prof = execute_query("""
        SELECT p.id, p.nom, d.nom as departement, p.dept_id 
        FROM planning.professeurs p
        JOIN planning.departements d ON p.dept_id = d.id
        WHERE p.utilisateur_id = %s
    """, (user_id,))

    if df_prof.empty:
        st.warning("⚠️ Accès Restreint : Votre compte utilisateur n'est lié à aucune fiche Professeur.")
        st.info("Veuillez demander à l'administrateur de vous lier à la table professeurs.")
        if st.button("Déconnexion"):
            st.session_state.clear()
            st.rerun()
        return

    prof_id = int(df_prof.iloc[0]['id'])
    prof_nom = df_prof.iloc[0]['nom']
    dept_nom = df_prof.iloc[0]['departement']
    dept_id = int(df_prof.iloc[0]['dept_id'])

    # ===========================
    # STYLE CSS (DESIGN EPURE)
    # ===========================
    st.markdown("""
    <style>
    .stButton>button { width: 100%; border-radius: 4px; background-color: #002b5c; color: white; }
    h3 { color: #002b5c; border-bottom: 2px solid #eee; padding-bottom: 10px; }
    .status-badge { padding: 2px 8px; border-radius: 12px; font-size: 0.8em; }
    </style>
    """, unsafe_allow_html=True)

    # ===========================
    # SIDEBAR (PLANNING PERSONNALISE)
    # ===========================
    with st.sidebar:
        st.markdown(f"### Espace Professeur")
        st.write(f"**Nom :** {prof_nom}")
        st.write(f"**Dépt :** {dept_nom}")
        st.markdown("---")
        menu = st.radio("Navigation", ["Mon Planning", "Proposer Examen", "Conflits & Alertes"], label_visibility="collapsed")
        st.markdown("---")
        if st.button("Déconnexion"):
            st.session_state.clear()
            st.rerun()

    # ===========================
    # 1. MON PLANNING (Filtrage Dept/Perso)
    # ===========================
    if menu == "Mon Planning":
        st.markdown("### Consultation du planning personnalisé")
        
        tab1, tab2 = st.tabs(["Mes Examens (Responsable)", "Mes Surveillances"])
        
        with tab1:
            # Planning des examens dont il est le responsable
            df_mes_exams = execute_query("""
                SELECT e.date_heure, m.nom as module, f.nom as formation, l.nom as salle, e.statut
                FROM planning.examens e
                JOIN planning.modules m ON e.module_id = m.id
                JOIN planning.formations f ON m.formation_id = f.id
                JOIN planning.lieu_examen l ON e.salle_id = l.id
                WHERE e.prof_id = %s
                ORDER BY e.date_heure
            """, (prof_id,))
            
            if df_mes_exams.empty:
                st.info("Vous n'êtes responsable d'aucun examen pour le moment.")
            else:
                st.dataframe(df_mes_exams, use_container_width=True, hide_index=True)

        with tab2:
            # Planning où il est invité à surveiller
            df_surv = execute_query("""
                SELECT e.date_heure, m.nom as module, l.nom as salle, f.nom as formation
                FROM planning.surveillances s
                JOIN planning.examens e ON s.examen_id = e.id
                JOIN planning.modules m ON e.module_id = m.id
                JOIN planning.formations f ON m.formation_id = f.id
                JOIN planning.lieu_examen l ON e.salle_id = l.id
                WHERE s.prof_id = %s
                ORDER BY e.date_heure
            """, (prof_id,))
            
            if df_surv.empty:
                st.info("Aucune surveillance ne vous a été attribuée.")
            else:
                st.dataframe(df_surv, use_container_width=True, hide_index=True)

    # ===========================
    # 2. PROPOSER EXAMEN (Workflow vers Chef Dept)
    # ===========================
    elif menu == "Proposer Examen":
        st.markdown("### Proposer une planification d'examen")
        
        # On ne propose que pour les formations de son département
        df_form = execute_query("SELECT id, nom FROM planning.formations WHERE dept_id = %s", (dept_id,))
        df_mod = execute_query("SELECT id, nom FROM planning.modules WHERE formation_id IN (SELECT id FROM planning.formations WHERE dept_id = %s)", (dept_id,))
        df_sal = execute_query("SELECT id, nom FROM planning.lieu_examen ORDER BY nom")

        if df_mod.empty:
            st.warning("Aucun module disponible pour votre département.")
            return

        with st.form("form_prop"):
            col1, col2 = st.columns(2)
            with col1:
                mod_nom = st.selectbox("Module", df_mod["nom"])
                date_e = st.date_input("Date souhaitée")
            with col2:
                salle_nom = st.selectbox("Salle souhaitée", df_sal["nom"])
                heure_e = st.time_input("Heure")
            
            duree = st.number_input("Durée (minutes)", value=120)
            
            if st.form_submit_button("Soumettre la demande"):
                m_id = int(df_mod[df_mod["nom"] == mod_nom]["id"].iloc[0])
                s_id = int(df_sal[df_sal["nom"] == salle_nom]["id"].iloc[0])
                dt_combined = datetime.combine(date_e, heure_e)

                success = execute_update("""
                    INSERT INTO planning.examens (module_id, prof_id, salle_id, date_heure, duree_minutes, statut)
                    VALUES (%s, %s, %s, %s, %s, 'en attente')
                """, (m_id, prof_id, s_id, dt_combined, duree))
                
                if success:
                    st.success("Demande envoyée. Elle doit être validée par le Chef de Département.")
                else:
                    st.error("Échec de l'envoi de la demande.")

    # ===========================
    # 3. CONFLITS PERSONNELS
    # ===========================
    elif menu == "Conflits & Alertes":
        st.markdown("### Mes alertes de planning")
        # Vérifie si le prof est à deux endroits en même temps
        df_conf = execute_query("""
            SELECT e1.date_heure, m1.nom as module_1, m2.nom as module_2, l1.nom as salle_1, l2.nom as salle_2
            FROM planning.examens e1
            JOIN planning.examens e2 ON e1.date_heure = e2.date_heure AND e1.id < e2.id
            JOIN planning.modules m1 ON e1.module_id = m1.id
            JOIN planning.modules m2 ON e2.module_id = m2.id
            JOIN planning.lieu_examen l1 ON e1.salle_id = l1.id
            JOIN planning.lieu_examen l2 ON e2.salle_id = l2.id
            WHERE e1.prof_id = %s OR e2.prof_id = %s
        """, (prof_id, prof_id))
        
        if df_conf.empty:
            st.success("Votre planning ne présente aucun conflit d'horaire.")
        else:
            st.error("Conflits détectés dans votre emploi du temps !")
            st.dataframe(df_conf, use_container_width=True, hide_index=True)