import streamlit as st
import pandas as pd
from db import get_connection

# =====================================
# UTILITAIRE : vérifier si une vue existe
# =====================================
def vue_existe(conn, schema, vue):
    q = """
    SELECT 1 FROM information_schema.views
    WHERE table_schema = %s AND table_name = %s
    """
    df = pd.read_sql(q, conn, params=(schema, vue))
    return not df.empty

# =====================================
# INTERFACE DOYEN / VICE-DOYEN
# =====================================
def interface_doyen(user):
    st.markdown("""<style> .stMetric { background-color: #f0f2f6; padding: 10px; border-radius: 10px; } </style>""", unsafe_allow_html=True)

    with st.sidebar:
     
        st.divider()
        menu = st.radio("Navigation", ["Tableau de bord", "Emplois du temps", "Indicateurs", "Rapports"], index=0)
        if st.button("Se déconnecter", use_container_width=True):
            st.session_state.logged_in = False
            st.rerun()

    conn = get_connection()

    # =======================
    # TABLEAU DE BORD
    # =======================
    if menu == "Tableau de bord":
        st.title("Tableau de bord stratégique")
        
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Examens", pd.read_sql("SELECT COUNT(*) FROM planning.examens", conn).iloc[0,0])
        c2.metric("Étudiants", pd.read_sql("SELECT COUNT(*) FROM planning.etudiants", conn).iloc[0,0])
        c3.metric("Salles", pd.read_sql("SELECT COUNT(*) FROM planning.lieu_examen", conn).iloc[0,0])
        c4.metric("Professeurs", pd.read_sql("SELECT COUNT(*) FROM planning.professeurs", conn).iloc[0,0])

        st.subheader("Occupation des salles / Amphis")

        if not vue_existe(conn, "planning", "v_occupation_salles"):
            cur = conn.cursor()
            cur.execute("""
                CREATE OR REPLACE VIEW planning.v_occupation_salles AS
                SELECT l.nom AS salle_nom, l.capacite,
                COUNT(i.id) AS nb_inscrits,
                ROUND((COUNT(i.id)::numeric / NULLIF(l.capacite,0)) * 100, 2) AS taux_occupation
                FROM planning.lieu_examen l
                LEFT JOIN planning.examens e ON l.id = e.salle_id
                LEFT JOIN planning.inscriptions i ON e.examen_id = i.examen_id
                GROUP BY l.id, l.nom, l.capacite
            """)
            conn.commit()

        df_salles = pd.read_sql("SELECT * FROM planning.v_occupation_salles", conn)
        st.dataframe(df_salles, use_container_width=True)
        st.bar_chart(df_salles.set_index("salle_nom")["taux_occupation"])

        st.subheader("Analyse des conflits par Departement")
        # Version corrigée du calcul de taux
        df_conflicts_dept = pd.read_sql("""
            SELECT 
                d.nom AS departement,
                COUNT(DISTINCT CASE WHEN e2.id IS NOT NULL THEN e1.id END) AS examens_en_conflit,
                COUNT(DISTINCT e1.id) AS total_examens,
                ROUND(
                    COUNT(DISTINCT CASE WHEN e2.id IS NOT NULL THEN e1.id END)::numeric / 
                    NULLIF(COUNT(DISTINCT e1.id), 0) * 100, 2
                ) AS taux_conflit_percent
            FROM planning.departements d
            JOIN planning.formations f ON f.dept_id = d.id
            JOIN planning.modules m ON m.formation_id = f.id
            JOIN planning.examens e1 ON e1.module_id = m.id
            LEFT JOIN planning.examens e2 ON e1.salle_id = e2.salle_id 
                AND e1.date_heure = e2.date_heure 
                AND e1.id != e2.id
            GROUP BY d.nom
        """, conn)
        
        st.dataframe(df_conflicts_dept, use_container_width=True)
    # =======================
    # EMPLOIS DU TEMPS
    # =======================
    elif menu == "Emplois du temps":
        st.title("Gestion des Emplois du Temps")
        
        df = pd.read_sql("""
            SELECT d.nom AS departement, COUNT(e.id) AS nb_examens
            FROM planning.departements d
            LEFT JOIN planning.formations f ON f.dept_id = d.id
            LEFT JOIN planning.modules m ON m.formation_id = f.id
            LEFT JOIN planning.examens e ON e.module_id = m.id
            GROUP BY d.nom
        """, conn)
        st.dataframe(df, use_container_width=True)

        if st.button("Valider définitivement l’EDT"):
            cur = conn.cursor()
            cur.execute("UPDATE planning.examens SET valide_doyen = TRUE")
            conn.commit()
            st.success("EDT valide officiellement par le Doyen")

    # =======================
    # INDICATEURS
    # =======================
    elif menu == "Indicateurs":
        st.title("Indicateurs de Performance (KPIs)")
        
        # Section Contraintes Critiques (Exigence 100% PDF)
        st.subheader("Respect des contraintes critiques")
        col_c1, col_c2 = st.columns(2)
        
        with col_c1:
            # Etudiants avec plus de 1 exam / jour
            surplus_etud = pd.read_sql("""
                SELECT COUNT(*) FROM (
                    SELECT i.etudiant_id, e.date_heure::date
                    FROM planning.inscriptions i
                    JOIN planning.examens e ON i.examen_id = e.id
                    GROUP BY i.etudiant_id, e.date_heure::date
                    HAVING COUNT(e.id) > 1
                ) AS violations
            """, conn).iloc[0,0]
            st.metric("Violations Etudiants (>1 exam/j)", surplus_etud, delta_color="inverse")

        with col_c2:
            # Professeurs avec plus de 3 exam / jour
            surplus_prof = pd.read_sql("""
                SELECT COUNT(*) FROM (
                    SELECT prof_id, date_heure::date
                    FROM planning.examens
                    GROUP BY prof_id, date_heure::date
                    HAVING COUNT(id) > 3
                ) AS violations
            """, conn).iloc[0,0]
            st.metric("Violations Profs (>3 surveillances/j)", surplus_prof, delta_color="inverse")

        st.subheader("Charge horaire par Professeur")
        df_profs = pd.read_sql("""
            SELECT p.nom, COUNT(e.id) * 2 AS total_heures
            FROM planning.professeurs p
            LEFT JOIN planning.examens e ON p.id = e.prof_id
            GROUP BY p.nom
            ORDER BY total_heures DESC
        """, conn)
        st.bar_chart(df_profs.set_index("nom"))
        
        st.subheader("Taux d'utilisation par Departement")
        query_taux = """
            SELECT 
                d.nom AS departement,
                ROUND(AVG(CASE WHEN l.capacite > 0 THEN (
                    SELECT COUNT(*)::numeric FROM planning.inscriptions inst 
                    WHERE inst.examen_id = e.id) / l.capacite * 100 
                ELSE 0 END), 2) AS taux_utilisation
            FROM planning.departements d
            JOIN planning.formations f ON f.dept_id = d.id
            JOIN planning.modules m ON m.formation_id = f.id
            JOIN planning.examens e ON e.module_id = m.id
            JOIN planning.lieu_examen l ON l.id = e.salle_id
            GROUP BY d.nom
        """
        df_taux = pd.read_sql(query_taux, conn)
        st.bar_chart(df_taux.set_index("departement"))

    # =======================
    # RAPPORTS
    # =======================
    elif menu == "Rapports":
        st.title("Rapports et Exportations")
        
        df = pd.read_sql("""
            SELECT m.nom AS module, l.nom AS salle, e.date_heure, p.nom AS professeur
            FROM planning.examens e
            JOIN planning.modules m ON m.id = e.module_id
            JOIN planning.lieu_examen l ON l.id = e.salle_id
            JOIN planning.professeurs p ON p.id = e.prof_id
        """, conn)
        st.dataframe(df, use_container_width=True)
        csv = df.to_csv(index=False).encode("utf-8")
        st.download_button("Exporter en CSV", csv, "examens_valides.csv")

    conn.close()
