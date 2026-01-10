import streamlit as st
import pandas as pd
from db import get_connection
from fpdf import FPDF

def interface_etudiant(user):
    # Le style CSS est calqué sur l'interface Admin/Doyen
    st.markdown("""
        <style>
        .main { background-color: #f8f9fa; }
        h2 { color: #002b5c; font-family: 'Segoe UI', sans-serif; border-bottom: 2px solid #002b5c; padding-bottom: 10px; }
        .stButton>button { background-color: #002b5c; color: white; border-radius: 4px; }
        .stSelectbox label { color: #002b5c; font-weight: bold; }
        </style>
    """, unsafe_allow_html=True)

    st.markdown("<h2>Consultation du Planning Officiel</h2>", unsafe_allow_html=True)

    with st.sidebar:
       
        st.markdown("---")
        if st.button("Deconnexion"):
            st.session_state.clear()
            st.rerun()

    conn = get_connection()

    # --- Etape 1 : Selection Departement ---
    df_depts = pd.read_sql("SELECT id, nom FROM planning.departements ORDER BY nom", conn)
    dept_nom = st.selectbox("Departement", df_depts['nom'])
    dept_id = df_depts[df_depts['nom'] == dept_nom]['id'].iloc[0]

    # --- Etape 2 : Selection Formation ---
    df_forms = pd.read_sql(
        "SELECT id, nom FROM planning.formations WHERE dept_id = %s", 
        conn, params=(int(dept_id),)
    )
    
    if df_forms.empty:
        st.info("Aucune formation enregistree pour ce departement.")
        return
        
    form_nom = st.selectbox("Formation / Specialite", df_forms['nom'])
    form_id = df_forms[df_forms['nom'] == form_nom]['id'].iloc[0]

    # --- Etape 3 : Affichage du Planning ---
    query = """
        SELECT m.nom AS module, l.nom AS salle,
               TO_CHAR(e.date_heure,'DD-MM-YYYY') AS date,
               TO_CHAR(e.date_heure,'HH24:MI') AS heure
        FROM planning.examens e
        JOIN planning.modules m ON e.module_id = m.id
        JOIN planning.lieu_examen l ON e.salle_id = l.id
        WHERE m.formation_id = %s AND e.statut = 'validé'
        ORDER BY e.date_heure
    """
    df_plan = pd.read_sql(query, conn, params=(int(form_id),))

    if df_plan.empty:
        st.warning("Le planning pour cette formation n'a pas encore ete valide par l'administration.")
    else:
        st.write(f"Planning pour la formation : **{form_nom}**")
        st.dataframe(df_plan, use_container_width=True, hide_index=True)

        # --- Export PDF ---
        if st.button("Exporter le planning (PDF)"):
            pdf = FPDF()
            pdf.add_page()
            pdf.set_font("Arial", 'B', 16)
            pdf.cell(0, 15, f"PLANNING DES EXAMENS - {form_nom.upper()}", ln=True, align='C')
            pdf.ln(10)
            
            # Entetes
            pdf.set_font("Arial", 'B', 12)
            pdf.cell(40, 10, "Date", 1)
            pdf.cell(30, 10, "Heure", 1)
            pdf.cell(80, 10, "Module", 1)
            pdf.cell(40, 10, "Salle", 1, 1)
            
            # Lignes
            pdf.set_font("Arial", '', 11)
            for _, row in df_plan.iterrows():
                pdf.cell(40, 10, str(row['date']), 1)
                pdf.cell(30, 10, str(row['heure']), 1)
                pdf.cell(80, 10, str(row['module']), 1)
                pdf.cell(40, 10, str(row['salle']), 1, 1)

            pdf_output = pdf.output(dest='S').encode('latin1')
            st.download_button("Telecharger PDF", data=pdf_output, file_name="planning.pdf")
