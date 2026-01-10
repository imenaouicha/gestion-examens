import streamlit as st
import pandas as pd
from datetime import datetime, timedelta
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
# INTERFACE ADMIN EXAMENS
# ===========================

def interface_adminexamen(user):
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
    </style>
    """, unsafe_allow_html=True)

    # ===========================
    # SIDEBAR
    # ===========================
    with st.sidebar:
        st.markdown("### Menu Administration")
        menu = st.radio(
            "Navigation",
            ["Generation EDT", "Detection Conflits", "Optimisation"],
            label_visibility="collapsed"
        )
        st.markdown("---")
        if st.button("Deconnexion"):
            st.session_state.clear()
            st.rerun()

    # ===========================
    # 1. GENERATION EDT
    # ===========================
    if menu == "Generation EDT":
        st.markdown("### Generation automatique du planning")
        
        df_form = execute_query("SELECT id, nom FROM planning.formations ORDER BY nom")
        
        if df_form.empty:
            st.warning("Aucune formation trouvee dans la base de donnees.")
            return

        formation_nom = st.selectbox("Selectionner une formation", df_form["nom"])
        formation_id = int(df_form[df_form["nom"]==formation_nom]["id"].iloc[0])
        
        col1, col2 = st.columns(2)
        with col1:
            date_debut = st.date_input("Date de debut", datetime.now())
        with col2:
            duree_exam = st.number_input("Duree standard (min)", value=120, step=30)

        if st.button("Generer les examens"):
            # Recuperer les modules de cette formation qui n'ont pas encore d'examen
            modules = execute_query("""
                SELECT m.id, m.nom FROM planning.modules m 
                LEFT JOIN planning.examens e ON m.id = e.module_id 
                WHERE m.formation_id = %s AND e.id IS NULL
            """, (formation_id,))

            if modules.empty:
                st.info("Tous les modules de cette formation sont deja planifies.")
                return

            salles = execute_query("SELECT id FROM planning.lieu_examen ORDER BY capacite DESC")
            profs = execute_query("SELECT id FROM planning.professeurs LIMIT 1")

            if salles.empty or profs.empty:
                st.error("Erreur : Verifiez que vous avez des salles et au moins un professeur.")
                return

            success_count = 0
            prof_id = int(profs.iloc[0]['id'])

            for i, row in modules.iterrows():
                # Planification : 1 module par jour a 09:00 pour eviter les conflits de base
                date_exam = date_debut + timedelta(days=i)
                heure_full = datetime.combine(date_exam, datetime.strptime("09:00", "%H:%M").time())
                salle_id = int(salles.iloc[i % len(salles)]['id'])
                
                query = """
                    INSERT INTO planning.examens (module_id, prof_id, salle_id, date_heure, duree_minutes, statut) 
                    VALUES (%s, %s, %s, %s, %s, 'en attente')
                """
                if execute_update(query, (int(row['id']), prof_id, salle_id, heure_full, duree_exam)):
                    success_count += 1
            
            st.success(f"Generation terminee : {success_count} examens crees en attente de validation.")

    # ===========================
    # 2. DETECTION CONFLITS
    # ===========================
    elif menu == "Detection Conflits":
        st.markdown("### Analyse des conflits de ressources")
        
        if st.button("Lancer le scan des conflits"):
            # Conflit de salle : meme salle, meme moment
            query_salles = """
                SELECT e1.id as ex1, e2.id as ex2, l.nom as salle, e1.date_heure
                FROM planning.examens e1
                JOIN planning.examens e2 ON e1.salle_id = e2.salle_id 
                    AND e1.id < e2.id 
                    AND e1.date_heure = e2.date_heure
                JOIN planning.lieu_examen l ON e1.salle_id = l.id
            """
            
            # Conflit de professeur : meme prof, meme moment
            query_profs = """
                SELECT e1.id as ex1, e2.id as ex2, p.nom as professeur, e1.date_heure
                FROM planning.examens e1
                JOIN planning.examens e2 ON e1.prof_id = e2.prof_id 
                    AND e1.id < e2.id 
                    AND e1.date_heure = e2.date_heure
                JOIN planning.professeurs p ON e1.prof_id = p.id
            """
            
            df_s = execute_query(query_salles)
            df_p = execute_query(query_profs)

            if df_s.empty and df_p.empty:
                st.success("Aucun conflit de salle ou de professeur detecte.")
            else:
                if not df_s.empty:
                    st.error("Conflits de salle identifies :")
                    st.dataframe(df_s, use_container_width=True, hide_index=True)
                if not df_p.empty:
                    st.error("Conflits de professeur identifies :")
                    st.dataframe(df_p, use_container_width=True, hide_index=True)

    # ===========================
    # 3. OPTIMISATION
    # ===========================
    elif menu == "Optimisation":
        st.markdown("### Optimisation des ressources")
        st.write("Ce processus tente de resoudre les conflits de salles en deplaçant les examens vers des salles libres.")
        
        if st.button("Lancer l'Optimisation"):
            # 1. Trouver les examens qui sont en conflit de salle
            conflits = execute_query("""
                SELECT e1.id, e1.date_heure, e1.salle_id 
                FROM planning.examens e1
                WHERE EXISTS (
                    SELECT 1 FROM planning.examens e2 
                    WHERE e1.salle_id = e2.salle_id 
                    AND e1.date_heure = e2.date_heure 
                    AND e1.id <> e2.id
                )
            """)
            
            if conflits.empty:
                st.success("Aucun conflit de salle a optimiser.")
                return

            # 2. Pour chaque examen en conflit, chercher une salle vide a ce moment-la
            repaired = 0
            for _, row in conflits.iterrows():
                exam_id = int(row['id'])
                date_h = row['date_heure']
                
                # Chercher une salle qui n'a PAS d'examen a cette date/heure
                salle_libre = execute_query("""
                    SELECT id FROM planning.lieu_examen 
                    WHERE id NOT IN (
                        SELECT salle_id FROM planning.examens 
                        WHERE date_heure = %s
                    ) LIMIT 1
                """, (date_h,))
                
                if not salle_libre.empty:
                    nouvelle_salle = int(salle_libre.iloc[0]['id'])
                    # Appliquer la correction
                    if execute_update("UPDATE planning.examens SET salle_id=%s WHERE id=%s", (nouvelle_salle, exam_id)):
                        repaired += 1
            
            if repaired > 0:
                st.success(f"Optimisation reussie : {repaired} conflits de salles ont ete resolus.")
            else:
                st.warning("L'optimisation a echoue : Aucune salle libre n'a ete trouvee pour deplacer les examens.")

# Note: Ce fichier doit etre importe dans votre app.py principal.