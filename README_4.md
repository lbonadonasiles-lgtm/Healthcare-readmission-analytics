# Hospital Readmission Analytics

An end-to-end healthcare analytics project investigating which patient and operational
factors are associated with hospital readmission among diabetic patients. The project
spans the full data pipeline: exploratory analysis in **Python**, relational database
design and querying in **SQL (SQLite)**, and an interactive **Power BI** dashboard.

> **Scope:** This is a *descriptive* analysis built to surface and communicate risk
> patterns to a healthcare-operations audience — not a predictive model. All findings
> describe **associations, not proven causes.**

![Dashboard overview](outputs/figures/dashboard.png)

---

## Objective

Hospital readmissions are costly and often preventable. Using a dataset of 25,000
diabetic patient encounters, this project asks:

- Which patient groups experience the highest readmission rates?
- How do prior healthcare-utilization patterns relate to readmission?
- How do diabetes-management indicators differ between readmitted and non-readmitted patients?
- Which diagnoses and medical specialties are most associated with readmission?

The emphasis is on designing a clean relational data model, writing analytical SQL,
and translating the results into business-oriented insights.

---

## Dataset

- **Source:** Publicly available hospital readmissions dataset (Kaggle). *(Add link.)*
- **Size:** 25,000 hospital encounters spanning roughly a ten-year period.
- **Grain:** one row = one hospital encounter.
- **Contents:** patient age band, length of stay, prior-utilization counts (inpatient,
  emergency, outpatient), hospitalization characteristics, up to three diagnosis
  categories, diabetes lab tests (A1C, glucose), medication change/usage, and the
  readmission outcome.

**Data-quality note:** missing values are encoded as the literal string `"Missing"`
rather than true nulls, so a naive null check reports a clean dataset. In reality
roughly half of `medical_specialty` values are `"Missing"` — a fact that is disclosed
and accounted for rather than hidden.

---

## Tech stack

- **Python** (pandas) — data ingestion, exploratory analysis, ETL into the database
- **SQL / SQLite** — relational schema design (DDL with primary/foreign keys),
  analytical queries
- **Power BI** — interactive dashboard and KPI reporting
- **Jupyter Notebook** — analysis environment

---

## Repository structure

```
.
├── data/
│   └── hospital_readmissions.csv          # raw dataset
├── notebooks/
│   ├── 01_database_setup.ipynb            # data loading, EDA & data-quality profiling
│   ├── 02_database_build.ipynb            # build the normalized SQLite database (schema DDL lives here)
│   ├── 03_sql_analysis.ipynb              # analytical SQL queries
│   └── 04_visualization.ipynb             # export summary tables for the dashboard
├── sql/
│   └── 02_analysis_queries.sql            # standalone analytical queries
├── outputs/
│   ├── exports/                           # summary CSVs that feed the dashboard
│   ├── figures/                           # dashboard image(s)
│   └── HC_readmission_db.pbix             # Power BI report
└── healthcare_readmissions.db             # generated SQLite database
```

---

## Methodology

**1. Exploratory analysis (`01_database_setup.ipynb`).** Loaded the raw CSV in pandas,
profiled distributions and data types, and uncovered the `"Missing"`-as-string
data-quality issue. Established the overall readmission baseline (~47%) and first-pass
associations.

**2. Database design (`02_database_build.ipynb`).** Transformed the flat file into a
normalized **star schema** in SQLite. The encounter is the grain; because the dataset
has no patient identifier, a surrogate `encounter_id` was generated and the schema was
deliberately modeled around the encounter rather than implying a patient-level
relationship the data cannot support. The repeating diagnosis columns (`diag_1/2/3`) —
a first-normal-form violation — were unpivoted into a bridge table, the one genuinely
normalizing step in the data. Tables were created with explicit DDL, primary keys, and
enforced foreign keys.

| Table                          | Role                                            |
|--------------------------------|-------------------------------------------------|
| `fact_encounters`              | Fact table — one row per encounter, measures + FKs |
| `dim_age`                      | Age-band dimension (with sort order)            |
| `dim_specialty`                | Medical-specialty dimension                     |
| `dim_diagnosis`                | Diagnosis-category dimension                    |
| `bridge_encounter_diagnosis`   | Resolves the encounter <-> diagnosis many-to-many |

**3. Analytical SQL (`03_sql_analysis.ipynb` / `sql/02_analysis_queries.sql`).** Wrote
queries using joins, `CASE`-based segmentation, and aggregations to quantify readmission
rates across age, prior utilization, diabetes indicators, diagnosis, and specialty.

**4. Visualization (`04_visualization.ipynb` + Power BI).** Exported summary tables to
CSV and built an interactive dashboard with KPI cards and takeaway-titled charts, using
color deliberately to highlight the strongest findings.

---

## Key findings

**Prior hospital use is by far the strongest driver of readmission.** Readmission rises
steeply and consistently with prior utilization — a textbook dose-response:

- Prior **inpatient stays**: 40% (none) -> 55% -> 66% -> **81%** (4+ stays)
- Prior **emergency visits**: 45% (none) -> 59% -> **71%** (2+ visits)

**Readmission increases with age**, climbing from ~44% in the 40s-50s to ~50% in the
80s, with a dip in the 90-100 group (the smallest, noisiest segment).

**Primary diagnosis matters.** Diabetes-as-primary carries the highest readmission
(~54%), down to musculoskeletal (~40%).

**Diabetes-management indicators are comparatively weak.** A high glucose reading is
modestly associated with higher readmission (~52% vs ~47%); A1C results show essentially
no difference; patients on diabetes medication readmit somewhat more (~49% vs ~41%), most
likely because medication marks more serious diabetes rather than causing readmission.

**Specialty differences reflect patient mix, not performance.** General practice and
emergency lead; surgery is lowest — consistent with the kinds of patients each sees, not
a judgment of care quality. Note that about half of encounters have a `"Missing"`
specialty, so the specialty view covers only encounters with a recorded specialty.

**Overall baseline readmission rate: ~47%.**

---

## Dashboard

The Power BI report presents the headline KPIs and the breakdowns above on a single page.
A static image is in `outputs/figures/` for viewing without Power BI; the editable report
is `outputs/HC_readmission_db.pbix`.

---

## Limitations

- **Descriptive, not causal.** Every result is an association. High readmission for a
  diagnosis or specialty reflects sicker patient populations, not proven causation.
- **No patient identifier.** Encounters cannot be linked to individuals, so the model is
  built at the encounter grain; a patient-level dimension was intentionally avoided.
- **Missing specialty data.** About half of encounters have no recorded specialty; the
  specialty analysis should be read with that coverage gap in mind.
- **Single dataset, fixed time window.** Findings are specific to this dataset and not
  validated against external data.

---

## Reproducing this project

1. Place the dataset CSV in `data/`.
2. Run the notebooks in order (`01` -> `04`). Notebook `02` builds the SQLite database;
   `04` writes the summary CSVs into `outputs/exports/`.
3. Open the Power BI report (or connect Power BI to the exported CSVs) to view the dashboard.

---

## Author

Luciano Bonadona Siles— Biomedical Engineering graduate building toward Biomedical data/analytics roles.
https://www.linkedin.com/in/luciano-bonadona-2b39b3304/portfolio

