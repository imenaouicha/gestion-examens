--
-- PostgreSQL database dump
--

\restrict s0aNcm1lzOqePx4Kh6vDkQjfdioVjY1lImGFo1zhkCwVd6l2x8bvC6Y5cPRm90v

-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

-- Started on 2026-01-10 02:16:19

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 16401)
-- Name: planning; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA planning;


--
-- TOC entry 4991 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA planning; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA planning IS 'CREATE SCHEMA planning; SET search_path TO planning;';


--
-- TOC entry 245 (class 1255 OID 32804)
-- Name: check_salle_capacite(); Type: FUNCTION; Schema: planning; Owner: -
--

CREATE FUNCTION planning.check_salle_capacite() RETURNS trigger
    LANGUAGE plpgsql
    AS '
DECLARE
    v_capacite INT;
    v_nb_inscrits INT;
BEGIN
    -- 1. Récupérer la capacité de la salle associée à l''examen
    -- On passe par la table examens car salle_id n''est pas dans inscriptions
    SELECT l.capacite INTO v_capacite
    FROM planning.lieu_examen l
    JOIN planning.examens e ON e.salle_id = l.id
    WHERE e.id = NEW.examen_id;

    -- 2. Compter le nombre d''étudiants déjà inscrits à cet examen
    SELECT COUNT(*) INTO v_nb_inscrits
    FROM planning.inscriptions
    WHERE examen_id = NEW.examen_id;

    -- 3. Vérifier si on dépasse la capacité
    -- (v_nb_inscrits + 1) car l''étudiant actuel n''est pas encore compté
    IF (v_nb_inscrits + 1) > v_capacite THEN
        RAISE EXCEPTION ''Action annulée : La salle est déjà pleine (Capacité max : %)'', v_capacite;
    END IF;

    RETURN NEW;
END;
';


SET default_table_access_method = heap;

--
-- TOC entry 221 (class 1259 OID 16433)
-- Name: departements; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.departements (
    id integer NOT NULL,
    nom character varying(100) NOT NULL
);


--
-- TOC entry 220 (class 1259 OID 16432)
-- Name: departements_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.departements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4992 (class 0 OID 0)
-- Dependencies: 220
-- Name: departements_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.departements_id_seq OWNED BY planning.departements.id;


--
-- TOC entry 225 (class 1259 OID 16457)
-- Name: etudiants; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.etudiants (
    id integer NOT NULL,
    nom character varying(100),
    prenom character varying(100),
    formation_id integer,
    promo character varying(50),
    utilisateur_id integer
);


--
-- TOC entry 224 (class 1259 OID 16456)
-- Name: etudiants_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.etudiants_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4993 (class 0 OID 0)
-- Dependencies: 224
-- Name: etudiants_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.etudiants_id_seq OWNED BY planning.etudiants.id;


--
-- TOC entry 233 (class 1259 OID 16520)
-- Name: examens; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.examens (
    id integer NOT NULL,
    module_id integer,
    prof_id integer,
    salle_id integer,
    date_heure timestamp without time zone NOT NULL,
    duree_minutes integer,
    statut character varying(20) DEFAULT 'en attente'::character varying,
    valide_doyen boolean DEFAULT false,
    niveau character varying(10),
    CONSTRAINT examens_duree_minutes_check CHECK (((duree_minutes >= 30) AND (duree_minutes <= 360)))
);


--
-- TOC entry 232 (class 1259 OID 16519)
-- Name: examens_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.examens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4994 (class 0 OID 0)
-- Dependencies: 232
-- Name: examens_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.examens_id_seq OWNED BY planning.examens.id;


--
-- TOC entry 223 (class 1259 OID 16442)
-- Name: formations; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.formations (
    id integer NOT NULL,
    nom character varying(120) NOT NULL,
    dept_id integer,
    nb_modules integer,
    CONSTRAINT formations_nb_modules_check CHECK ((nb_modules >= 0))
);


--
-- TOC entry 222 (class 1259 OID 16441)
-- Name: formations_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.formations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4995 (class 0 OID 0)
-- Dependencies: 222
-- Name: formations_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.formations_id_seq OWNED BY planning.formations.id;


--
-- TOC entry 236 (class 1259 OID 16600)
-- Name: inscriptions; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.inscriptions (
    etudiant_id integer NOT NULL,
    examen_id integer NOT NULL,
    note numeric(4,2)
);


--
-- TOC entry 229 (class 1259 OID 16491)
-- Name: lieu_examen; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.lieu_examen (
    id integer NOT NULL,
    nom character varying(100),
    capacite integer,
    type character varying(30),
    batiment character varying(80),
    CONSTRAINT lieu_examen_capacite_check CHECK ((capacite > 0)),
    CONSTRAINT lieu_examen_type_check CHECK (((type)::text = ANY ((ARRAY['amphi'::character varying, 'salle_td'::character varying, 'laboratoire'::character varying])::text[])))
);


--
-- TOC entry 228 (class 1259 OID 16490)
-- Name: lieu_examen_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.lieu_examen_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4996 (class 0 OID 0)
-- Dependencies: 228
-- Name: lieu_examen_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.lieu_examen_id_seq OWNED BY planning.lieu_examen.id;


--
-- TOC entry 231 (class 1259 OID 16502)
-- Name: modules; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.modules (
    id integer NOT NULL,
    nom character varying(120),
    credits integer,
    formation_id integer,
    pre_req_id integer,
    CONSTRAINT modules_credits_check CHECK ((credits >= 0))
);


--
-- TOC entry 230 (class 1259 OID 16501)
-- Name: modules_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.modules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4997 (class 0 OID 0)
-- Dependencies: 230
-- Name: modules_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.modules_id_seq OWNED BY planning.modules.id;


--
-- TOC entry 227 (class 1259 OID 16474)
-- Name: professeurs; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.professeurs (
    id integer NOT NULL,
    nom character varying(120),
    dept_id integer,
    specialite character varying(120),
    utilisateur_id integer
);


--
-- TOC entry 226 (class 1259 OID 16473)
-- Name: professeurs_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.professeurs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4998 (class 0 OID 0)
-- Dependencies: 226
-- Name: professeurs_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.professeurs_id_seq OWNED BY planning.professeurs.id;


--
-- TOC entry 217 (class 1259 OID 16408)
-- Name: roles; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.roles (
    id integer NOT NULL,
    nom character varying(50) NOT NULL
);


--
-- TOC entry 216 (class 1259 OID 16407)
-- Name: roles_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 4999 (class 0 OID 0)
-- Dependencies: 216
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.roles_id_seq OWNED BY planning.roles.id;


--
-- TOC entry 235 (class 1259 OID 16558)
-- Name: surveillances; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.surveillances (
    id integer NOT NULL,
    examen_id integer,
    prof_id integer,
    priorite_dept boolean DEFAULT true
);


--
-- TOC entry 234 (class 1259 OID 16557)
-- Name: surveillances_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.surveillances_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5000 (class 0 OID 0)
-- Dependencies: 234
-- Name: surveillances_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.surveillances_id_seq OWNED BY planning.surveillances.id;


--
-- TOC entry 219 (class 1259 OID 16417)
-- Name: utilisateurs; Type: TABLE; Schema: planning; Owner: -
--

CREATE TABLE planning.utilisateurs (
    id integer NOT NULL,
    nom character varying(100) NOT NULL,
    email character varying(120) NOT NULL,
    mot_de_passe character varying(255) NOT NULL,
    role_id integer NOT NULL,
    actif boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now()
);


--
-- TOC entry 218 (class 1259 OID 16416)
-- Name: utilisateurs_id_seq; Type: SEQUENCE; Schema: planning; Owner: -
--

CREATE SEQUENCE planning.utilisateurs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5001 (class 0 OID 0)
-- Dependencies: 218
-- Name: utilisateurs_id_seq; Type: SEQUENCE OWNED BY; Schema: planning; Owner: -
--

ALTER SEQUENCE planning.utilisateurs_id_seq OWNED BY planning.utilisateurs.id;


--
-- TOC entry 237 (class 1259 OID 24598)
-- Name: v_occupation_salles; Type: VIEW; Schema: planning; Owner: -
--

CREATE VIEW planning.v_occupation_salles AS
 SELECT l.id AS salle_id,
    l.nom AS salle_nom,
    COALESCE(count(i.etudiant_id), (0)::bigint) AS nb_inscrits,
    l.capacite,
    round((((COALESCE(count(i.etudiant_id), (0)::bigint))::numeric / (NULLIF(l.capacite, 0))::numeric) * (100)::numeric), 2) AS taux_occupation
   FROM ((planning.lieu_examen l
     LEFT JOIN planning.examens e ON ((e.salle_id = l.id)))
     LEFT JOIN planning.inscriptions i ON ((i.examen_id = e.id)))
  GROUP BY l.id, l.nom, l.capacite
  ORDER BY l.nom;


--
-- TOC entry 4751 (class 2604 OID 16436)
-- Name: departements id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.departements ALTER COLUMN id SET DEFAULT nextval('planning.departements_id_seq'::regclass);


--
-- TOC entry 4753 (class 2604 OID 16460)
-- Name: etudiants id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.etudiants ALTER COLUMN id SET DEFAULT nextval('planning.etudiants_id_seq'::regclass);


--
-- TOC entry 4757 (class 2604 OID 16523)
-- Name: examens id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.examens ALTER COLUMN id SET DEFAULT nextval('planning.examens_id_seq'::regclass);


--
-- TOC entry 4752 (class 2604 OID 16445)
-- Name: formations id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.formations ALTER COLUMN id SET DEFAULT nextval('planning.formations_id_seq'::regclass);


--
-- TOC entry 4755 (class 2604 OID 16494)
-- Name: lieu_examen id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.lieu_examen ALTER COLUMN id SET DEFAULT nextval('planning.lieu_examen_id_seq'::regclass);


--
-- TOC entry 4756 (class 2604 OID 16505)
-- Name: modules id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.modules ALTER COLUMN id SET DEFAULT nextval('planning.modules_id_seq'::regclass);


--
-- TOC entry 4754 (class 2604 OID 16477)
-- Name: professeurs id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.professeurs ALTER COLUMN id SET DEFAULT nextval('planning.professeurs_id_seq'::regclass);


--
-- TOC entry 4747 (class 2604 OID 16411)
-- Name: roles id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.roles ALTER COLUMN id SET DEFAULT nextval('planning.roles_id_seq'::regclass);


--
-- TOC entry 4760 (class 2604 OID 16561)
-- Name: surveillances id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.surveillances ALTER COLUMN id SET DEFAULT nextval('planning.surveillances_id_seq'::regclass);


--
-- TOC entry 4748 (class 2604 OID 16420)
-- Name: utilisateurs id; Type: DEFAULT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.utilisateurs ALTER COLUMN id SET DEFAULT nextval('planning.utilisateurs_id_seq'::regclass);


--
-- TOC entry 4970 (class 0 OID 16433)
-- Dependencies: 221
-- Data for Name: departements; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.departements (id, nom) VALUES (1, 'Informatique') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (2, 'Mathématiques') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (3, 'Physique') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (4, 'Chimie') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (5, 'Biologie') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (6, 'Génie Civil') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (7, 'Électronique') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (8, 'Architecture') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (9, 'Gestion') ON CONFLICT DO NOTHING;
INSERT INTO planning.departements (id, nom) VALUES (10, 'Langues') ON CONFLICT DO NOTHING;


--
-- TOC entry 4974 (class 0 OID 16457)
-- Dependencies: 225
-- Data for Name: etudiants; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (1, 'Benali', 'Amine', 1, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (2, 'Saidi', 'Sara', 1, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (3, 'Gasmi', 'Karim', 2, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (4, 'Hamidi', 'Yasmine', 2, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (9, 'Nacer', 'Hedi', 2, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (5, 'Ouali', 'Riad', 3, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (6, 'Zekri', 'Lyna', 4, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (7, 'Bairi', 'Omar', 5, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (8, 'Taleb', 'Ines', 6, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.etudiants (id, nom, prenom, formation_id, promo, utilisateur_id) VALUES (10, 'Smail', 'Anis', 7, NULL, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 4982 (class 0 OID 16520)
-- Dependencies: 233
-- Data for Name: examens; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (3, 3, 2, 1, '2026-01-20 09:00:00', 120, 'en attente', true, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (5, 5, 6, 9, '2026-01-21 09:00:00', 120, 'en attente', true, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (11, 11, 4, 2, '2026-01-20 09:00:00', 180, 'en attente', true, 'L3') ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (13, 13, 7, 4, '2026-01-22 10:00:00', 90, 'en attente', true, 'L2') ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (14, 14, 9, 3, '2026-01-23 09:00:00', 120, 'en attente', true, 'M2') ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (15, 15, 10, 10, '2026-01-24 11:00:00', 240, 'en attente', true, 'L1') ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (12, 12, 6, 1, '2026-01-21 13:00:00', 120, 'validé', true, 'M1') ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (80, 10, 2, 1, '2026-01-31 09:00:00', 120, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (81, 4, 2, 1, '2026-02-18 09:00:00', 90, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (74, 1, 1, 2, '2025-06-20 09:00:00', NULL, 'en attente', true, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (78, 1, 1, 3, '2025-06-20 09:00:00', 90, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (77, 1, 1, 4, '2025-06-20 09:00:00', 90, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (75, 2, 2, 5, '2025-06-20 09:00:00', NULL, 'en attente', true, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (79, 1, 2, 1, '2026-01-20 09:00:00', 120, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (76, 1, 1, 1, '2026-01-25 10:00:00', 90, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (84, 1, 12, 1, '2026-01-10 01:24:00', 91, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (85, 1, 1, 1, '2026-06-15 10:00:00', 120, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (86, 12, 12, 1, '2026-01-10 01:35:00', 120, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (2, 2, 1, 1, '2026-01-20 09:00:00', 120, 'en attente', true, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (1, 1, 1, 1, '2026-01-20 09:00:00', 120, 'validé', true, 'M1') ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (4, 9, 12, 4, '2026-05-20 09:00:00', 90, 'en attente', true, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (6, 6, 12, 5, '2026-05-20 09:00:00', 120, 'en attente', true, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (87, 10, 12, 8, '2026-01-30 01:41:00', 120, 'en attente', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (102, 118, 1, 1, '2026-06-15 09:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (103, 119, 1, 1, '2026-06-16 09:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (104, 120, 1, 1, '2026-06-17 09:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (105, 121, 1, 1, '2026-06-18 09:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (106, 122, 1, 1, '2026-06-19 09:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (107, 123, 1, 1, '2026-06-20 09:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (108, 124, 1, 1, '2026-06-21 09:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (109, 125, 2, 2, '2026-06-15 14:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (110, 126, 2, 2, '2026-06-16 14:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (111, 127, 2, 2, '2026-06-17 14:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (112, 128, 2, 2, '2026-06-18 14:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (113, 129, 2, 2, '2026-06-19 14:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (114, 130, 2, 2, '2026-06-20 14:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.examens (id, module_id, prof_id, salle_id, date_heure, duree_minutes, statut, valide_doyen, niveau) VALUES (115, 131, 2, 2, '2026-06-21 14:00:00', 120, 'validé', false, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 4972 (class 0 OID 16442)
-- Dependencies: 223
-- Data for Name: formations; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (1, 'M1 Génie Logiciel', 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (2, 'L3 Systèmes Info', 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (3, 'M2 Data Science', 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (4, 'L2 Algèbre', 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (5, 'M1 Physique Atomique', 3, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (6, 'L1 Chimie', 4, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (7, 'M2 Microbiologie', 5, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (8, 'L3 Topographie', 6, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (9, 'M1 Systèmes Embarqués', 7, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.formations (id, nom, dept_id, nb_modules) VALUES (10, 'L2 Architecture', 8, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 4985 (class 0 OID 16600)
-- Dependencies: 236
-- Data for Name: inscriptions; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (1, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (1, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (2, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (2, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (3, 4, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (4, 4, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (5, 3, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (10, 6, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (6, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (7, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (8, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (9, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (6, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (7, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (8, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (9, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (6, 3, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.inscriptions (etudiant_id, examen_id, note) VALUES (7, 3, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 4978 (class 0 OID 16491)
-- Dependencies: 229
-- Data for Name: lieu_examen; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (1, 'Amphi A', 250, NULL, 'Bloc A') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (2, 'Amphi B', 200, NULL, 'Bloc A') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (3, 'Amphi C', 150, NULL, 'Bloc B') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (4, 'Salle 101', 20, NULL, 'Bloc C') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (5, 'Salle 102', 20, NULL, 'Bloc C') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (6, 'Salle 103', 20, NULL, 'Bloc C') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (7, 'Salle 104', 20, NULL, 'Bloc C') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (8, 'Labo Info 1', 25, NULL, 'Bloc D') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (9, 'Amphi D', 180, NULL, 'Bloc B') ON CONFLICT DO NOTHING;
INSERT INTO planning.lieu_examen (id, nom, capacite, type, batiment) VALUES (10, 'Salle 201', 30, NULL, 'Bloc D') ON CONFLICT DO NOTHING;


--
-- TOC entry 4980 (class 0 OID 16502)
-- Dependencies: 231
-- Data for Name: modules; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (118, 'Algorithmique et Complexité', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (119, 'Bases de Données Relationnelles', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (120, 'Réseaux et Protocoles IP', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (121, 'Systèmes d Exploitation Linux', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (122, 'Développement Web Avancé', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (123, 'Intelligence Artificielle', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (124, 'Cybersécurité et Cryptographie', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (125, 'Comptabilité de Gestion', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (126, 'Analyse Financière', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (127, 'Marketing International', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (128, 'Droit des Sociétés', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (129, 'Gestion des Ressources Humaines', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (130, 'Microéconomie Appliquée', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (131, 'Management Stratégique', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (1, 'Compilation', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (2, 'IE', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (3, 'IA', NULL, 3, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (4, 'Analyse', NULL, 5, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (5, 'Thermodynamique', NULL, 6, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (6, 'Génétique', NULL, 7, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (7, 'RDM', NULL, 8, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (8, 'VHDL', NULL, 9, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (9, 'BDD', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (10, 'Design Patterns', NULL, 1, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (11, 'Analyse Réelle', NULL, 2, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (12, 'Mécanique Quantique', NULL, 3, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (13, 'Chimie Organique', NULL, 4, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (14, 'Calcul des Structures', NULL, 5, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.modules (id, nom, credits, formation_id, pre_req_id) VALUES (15, 'Dessin Technique', NULL, 6, NULL) ON CONFLICT DO NOTHING;


--
-- TOC entry 4976 (class 0 OID 16474)
-- Dependencies: 227
-- Data for Name: professeurs; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (2, 'Dr. Djeddai', 1, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (3, 'Dr. Hamadouche', 1, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (4, 'Dr. Ziani', 2, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (5, 'M. Brahimi', 2, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (6, 'Mme. Amrani', 3, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (7, 'Dr. Messaoudi', 4, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (8, 'Dr. Khaldi', 5, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (9, 'M. Yousfi', 6, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (10, 'Mme. Belhadj', 7, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (1, 'Dr. Lounas', 1, NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (11, 'Chef Département Info', 1, 'Informatique', 14) ON CONFLICT DO NOTHING;
INSERT INTO planning.professeurs (id, nom, dept_id, specialite, utilisateur_id) VALUES (12, 'Nom du Chef', 1, 'Informatique', 12) ON CONFLICT DO NOTHING;


--
-- TOC entry 4966 (class 0 OID 16408)
-- Dependencies: 217
-- Data for Name: roles; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.roles (id, nom) VALUES (1, 'etudiant') ON CONFLICT DO NOTHING;
INSERT INTO planning.roles (id, nom) VALUES (2, 'professeur') ON CONFLICT DO NOTHING;
INSERT INTO planning.roles (id, nom) VALUES (3, 'admin') ON CONFLICT DO NOTHING;
INSERT INTO planning.roles (id, nom) VALUES (4, 'chef_dept') ON CONFLICT DO NOTHING;
INSERT INTO planning.roles (id, nom) VALUES (5, 'vice_doyen') ON CONFLICT DO NOTHING;
INSERT INTO planning.roles (id, nom) VALUES (6, 'doyen') ON CONFLICT DO NOTHING;


--
-- TOC entry 4984 (class 0 OID 16558)
-- Dependencies: 235
-- Data for Name: surveillances; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.surveillances (id, examen_id, prof_id, priorite_dept) VALUES (1, 1, 1, true) ON CONFLICT DO NOTHING;
INSERT INTO planning.surveillances (id, examen_id, prof_id, priorite_dept) VALUES (2, 2, 1, false) ON CONFLICT DO NOTHING;
INSERT INTO planning.surveillances (id, examen_id, prof_id, priorite_dept) VALUES (3, 1, 1, true) ON CONFLICT DO NOTHING;
INSERT INTO planning.surveillances (id, examen_id, prof_id, priorite_dept) VALUES (4, 4, 12, true) ON CONFLICT DO NOTHING;


--
-- TOC entry 4968 (class 0 OID 16417)
-- Dependencies: 219
-- Data for Name: utilisateurs; Type: TABLE DATA; Schema: planning; Owner: -
--

INSERT INTO planning.utilisateurs (id, nom, email, mot_de_passe, role_id, actif, created_at) VALUES (4, 'Doyen Test', 'doyen@example.com', '$2b$12$AtNwx7Y/n6hj15YChdpbI.kRf1wI5MOk6VFldPrmlAYKK6uLm5wgS', 6, true, '2025-12-22 23:31:15.972569') ON CONFLICT DO NOTHING;
INSERT INTO planning.utilisateurs (id, nom, email, mot_de_passe, role_id, actif, created_at) VALUES (11, 'Etudiant 1', 'etud1@univ.dz', '$2b$12$f7opi3ZUbGFRtEKLtBNYDOL2JCEOUAVbEU0D/Gv8REMQz6hbSnQsS', 1, true, '2025-12-23 13:45:16.448331') ON CONFLICT DO NOTHING;
INSERT INTO planning.utilisateurs (id, nom, email, mot_de_passe, role_id, actif, created_at) VALUES (12, 'Professeur 1', 'prof1@univ.dz', '$2b$12$fLF3VAKAYmbQ8/up/4vvseZ/kvByGOGzzuBn/.2rCHZg539yqHgXO', 2, true, '2025-12-23 13:45:16.448331') ON CONFLICT DO NOTHING;
INSERT INTO planning.utilisateurs (id, nom, email, mot_de_passe, role_id, actif, created_at) VALUES (13, 'Admin Examens', 'admin.exam@univ.dz', '$2b$12$yiaVPIfrXecPsw2R7ahc4eWuG.DDA.fAiH0kEeQ.vSNDBg.gDK6FC', 3, true, '2025-12-23 13:45:16.448331') ON CONFLICT DO NOTHING;
INSERT INTO planning.utilisateurs (id, nom, email, mot_de_passe, role_id, actif, created_at) VALUES (14, 'Chef Département', 'chef.info@univ.dz', '$2b$12$F3P39UK/KrcgmMpLUnGG7.v.2SmjxCFaqNKdW8HwTSE2LJnLSGZ7.', 4, true, '2025-12-23 13:45:16.448331') ON CONFLICT DO NOTHING;
INSERT INTO planning.utilisateurs (id, nom, email, mot_de_passe, role_id, actif, created_at) VALUES (15, 'Vice Doyen', 'vicedoyen@univ.dz', '$2b$12$I0HPU6GNtHfR8sYYCQsJ.OLnT2SiUELzu.rSOjxUs6kQSf6xe2jeq', 5, true, '2025-12-23 13:45:16.448331') ON CONFLICT DO NOTHING;
INSERT INTO planning.utilisateurs (id, nom, email, mot_de_passe, role_id, actif, created_at) VALUES (16, 'Doyen', 'doyen@univ.dz', '$2b$12$B1Cw8MMRoIuZyjC27GV8hO/5WACXOHSIfQtOx7VxxHwo8YNXVFqEG', 6, true, '2025-12-23 13:45:16.448331') ON CONFLICT DO NOTHING;


--
-- TOC entry 5002 (class 0 OID 0)
-- Dependencies: 220
-- Name: departements_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.departements_id_seq', 28, true);


--
-- TOC entry 5003 (class 0 OID 0)
-- Dependencies: 224
-- Name: etudiants_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.etudiants_id_seq', 5, true);


--
-- TOC entry 5004 (class 0 OID 0)
-- Dependencies: 232
-- Name: examens_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.examens_id_seq', 115, true);


--
-- TOC entry 5005 (class 0 OID 0)
-- Dependencies: 222
-- Name: formations_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.formations_id_seq', 37, true);


--
-- TOC entry 5006 (class 0 OID 0)
-- Dependencies: 228
-- Name: lieu_examen_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.lieu_examen_id_seq', 7, true);


--
-- TOC entry 5007 (class 0 OID 0)
-- Dependencies: 230
-- Name: modules_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.modules_id_seq', 131, true);


--
-- TOC entry 5008 (class 0 OID 0)
-- Dependencies: 226
-- Name: professeurs_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.professeurs_id_seq', 12, true);


--
-- TOC entry 5009 (class 0 OID 0)
-- Dependencies: 216
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.roles_id_seq', 1, false);


--
-- TOC entry 5010 (class 0 OID 0)
-- Dependencies: 234
-- Name: surveillances_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.surveillances_id_seq', 4, true);


--
-- TOC entry 5011 (class 0 OID 0)
-- Dependencies: 218
-- Name: utilisateurs_id_seq; Type: SEQUENCE SET; Schema: planning; Owner: -
--

SELECT pg_catalog.setval('planning.utilisateurs_id_seq', 16, true);


--
-- TOC entry 4776 (class 2606 OID 16440)
-- Name: departements departements_nom_key; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.departements
    ADD CONSTRAINT departements_nom_key UNIQUE (nom);


--
-- TOC entry 4778 (class 2606 OID 16438)
-- Name: departements departements_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.departements
    ADD CONSTRAINT departements_pkey PRIMARY KEY (id);


--
-- TOC entry 4784 (class 2606 OID 16462)
-- Name: etudiants etudiants_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.etudiants
    ADD CONSTRAINT etudiants_pkey PRIMARY KEY (id);


--
-- TOC entry 4796 (class 2606 OID 16526)
-- Name: examens examens_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.examens
    ADD CONSTRAINT examens_pkey PRIMARY KEY (id);


--
-- TOC entry 4780 (class 2606 OID 16450)
-- Name: formations formations_nom_dept_id_key; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.formations
    ADD CONSTRAINT formations_nom_dept_id_key UNIQUE (nom, dept_id);


--
-- TOC entry 4782 (class 2606 OID 16448)
-- Name: formations formations_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.formations
    ADD CONSTRAINT formations_pkey PRIMARY KEY (id);


--
-- TOC entry 4802 (class 2606 OID 16604)
-- Name: inscriptions inscriptions_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.inscriptions
    ADD CONSTRAINT inscriptions_pkey PRIMARY KEY (etudiant_id, examen_id);


--
-- TOC entry 4788 (class 2606 OID 16500)
-- Name: lieu_examen lieu_examen_batiment_nom_key; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.lieu_examen
    ADD CONSTRAINT lieu_examen_batiment_nom_key UNIQUE (batiment, nom);


--
-- TOC entry 4790 (class 2606 OID 16498)
-- Name: lieu_examen lieu_examen_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.lieu_examen
    ADD CONSTRAINT lieu_examen_pkey PRIMARY KEY (id);


--
-- TOC entry 4792 (class 2606 OID 24604)
-- Name: modules modules_nom_formation_unique; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.modules
    ADD CONSTRAINT modules_nom_formation_unique UNIQUE (nom, formation_id);


--
-- TOC entry 4794 (class 2606 OID 16508)
-- Name: modules modules_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.modules
    ADD CONSTRAINT modules_pkey PRIMARY KEY (id);


--
-- TOC entry 4786 (class 2606 OID 16479)
-- Name: professeurs professeurs_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.professeurs
    ADD CONSTRAINT professeurs_pkey PRIMARY KEY (id);


--
-- TOC entry 4768 (class 2606 OID 16415)
-- Name: roles roles_nom_key; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.roles
    ADD CONSTRAINT roles_nom_key UNIQUE (nom);


--
-- TOC entry 4770 (class 2606 OID 16413)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- TOC entry 4800 (class 2606 OID 16564)
-- Name: surveillances surveillances_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.surveillances
    ADD CONSTRAINT surveillances_pkey PRIMARY KEY (id);


--
-- TOC entry 4772 (class 2606 OID 16426)
-- Name: utilisateurs utilisateurs_email_key; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.utilisateurs
    ADD CONSTRAINT utilisateurs_email_key UNIQUE (email);


--
-- TOC entry 4774 (class 2606 OID 16424)
-- Name: utilisateurs utilisateurs_pkey; Type: CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.utilisateurs
    ADD CONSTRAINT utilisateurs_pkey PRIMARY KEY (id);


--
-- TOC entry 4797 (class 1259 OID 16595)
-- Name: idx_examens_date; Type: INDEX; Schema: planning; Owner: -
--

CREATE INDEX idx_examens_date ON planning.examens USING btree (date_heure);


--
-- TOC entry 4798 (class 1259 OID 16596)
-- Name: idx_examens_salle; Type: INDEX; Schema: planning; Owner: -
--

CREATE INDEX idx_examens_salle ON planning.examens USING btree (salle_id);


--
-- TOC entry 4819 (class 2620 OID 24577)
-- Name: inscriptions trg_inscription_capacite; Type: TRIGGER; Schema: planning; Owner: -
--

CREATE TRIGGER trg_inscription_capacite BEFORE INSERT ON planning.inscriptions FOR EACH ROW EXECUTE FUNCTION public.check_inscription_capacite();


--
-- TOC entry 4818 (class 2620 OID 16592)
-- Name: examens trg_prof_exam; Type: TRIGGER; Schema: planning; Owner: -
--

CREATE TRIGGER trg_prof_exam BEFORE INSERT ON planning.examens FOR EACH ROW EXECUTE FUNCTION public.check_prof_max3();


--
-- TOC entry 4820 (class 2620 OID 32805)
-- Name: inscriptions trg_salle_capacite; Type: TRIGGER; Schema: planning; Owner: -
--

CREATE TRIGGER trg_salle_capacite BEFORE INSERT ON planning.inscriptions FOR EACH ROW EXECUTE FUNCTION public.check_salle_capacite();


--
-- TOC entry 4805 (class 2606 OID 16463)
-- Name: etudiants etudiants_formation_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.etudiants
    ADD CONSTRAINT etudiants_formation_id_fkey FOREIGN KEY (formation_id) REFERENCES planning.formations(id);


--
-- TOC entry 4806 (class 2606 OID 16468)
-- Name: etudiants etudiants_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.etudiants
    ADD CONSTRAINT etudiants_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES planning.utilisateurs(id);


--
-- TOC entry 4811 (class 2606 OID 16527)
-- Name: examens examens_module_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.examens
    ADD CONSTRAINT examens_module_id_fkey FOREIGN KEY (module_id) REFERENCES planning.modules(id);


--
-- TOC entry 4812 (class 2606 OID 16532)
-- Name: examens examens_prof_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.examens
    ADD CONSTRAINT examens_prof_id_fkey FOREIGN KEY (prof_id) REFERENCES planning.professeurs(id);


--
-- TOC entry 4813 (class 2606 OID 16537)
-- Name: examens examens_salle_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.examens
    ADD CONSTRAINT examens_salle_id_fkey FOREIGN KEY (salle_id) REFERENCES planning.lieu_examen(id);


--
-- TOC entry 4804 (class 2606 OID 16451)
-- Name: formations formations_dept_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.formations
    ADD CONSTRAINT formations_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES planning.departements(id);


--
-- TOC entry 4816 (class 2606 OID 16605)
-- Name: inscriptions inscriptions_etudiant_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.inscriptions
    ADD CONSTRAINT inscriptions_etudiant_id_fkey FOREIGN KEY (etudiant_id) REFERENCES planning.etudiants(id);


--
-- TOC entry 4817 (class 2606 OID 16610)
-- Name: inscriptions inscriptions_examen_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.inscriptions
    ADD CONSTRAINT inscriptions_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES planning.examens(id);


--
-- TOC entry 4809 (class 2606 OID 16509)
-- Name: modules modules_formation_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.modules
    ADD CONSTRAINT modules_formation_id_fkey FOREIGN KEY (formation_id) REFERENCES planning.formations(id);


--
-- TOC entry 4810 (class 2606 OID 16514)
-- Name: modules modules_pre_req_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.modules
    ADD CONSTRAINT modules_pre_req_id_fkey FOREIGN KEY (pre_req_id) REFERENCES planning.modules(id);


--
-- TOC entry 4807 (class 2606 OID 16480)
-- Name: professeurs professeurs_dept_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.professeurs
    ADD CONSTRAINT professeurs_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES planning.departements(id);


--
-- TOC entry 4808 (class 2606 OID 16485)
-- Name: professeurs professeurs_utilisateur_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.professeurs
    ADD CONSTRAINT professeurs_utilisateur_id_fkey FOREIGN KEY (utilisateur_id) REFERENCES planning.utilisateurs(id);


--
-- TOC entry 4814 (class 2606 OID 16565)
-- Name: surveillances surveillances_examen_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.surveillances
    ADD CONSTRAINT surveillances_examen_id_fkey FOREIGN KEY (examen_id) REFERENCES planning.examens(id);


--
-- TOC entry 4815 (class 2606 OID 16570)
-- Name: surveillances surveillances_prof_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.surveillances
    ADD CONSTRAINT surveillances_prof_id_fkey FOREIGN KEY (prof_id) REFERENCES planning.professeurs(id);


--
-- TOC entry 4803 (class 2606 OID 16427)
-- Name: utilisateurs utilisateurs_role_id_fkey; Type: FK CONSTRAINT; Schema: planning; Owner: -
--

ALTER TABLE ONLY planning.utilisateurs
    ADD CONSTRAINT utilisateurs_role_id_fkey FOREIGN KEY (role_id) REFERENCES planning.roles(id);


-- Completed on 2026-01-10 02:16:19

--
-- PostgreSQL database dump complete
--

\unrestrict s0aNcm1lzOqePx4Kh6vDkQjfdioVjY1lImGFo1zhkCwVd6l2x8bvC6Y5cPRm90v

