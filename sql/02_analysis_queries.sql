/* ============================================================
   Healthcare Readmission Analytics
   02_analysis_queries.sql

   Analytical queries run against the star-schema database
   (healthcare_readmissions.db). Grain of fact_encounters is
   one hospital encounter. Readmission rate is computed as the
   average of a 1/0 flag (1 = readmitted), expressed as a percent.

   Overall baseline readmission rate is ~47%; compare each
   breakdown below against that baseline.
   ============================================================ */


/* ------------------------------------------------------------
   0. Baseline: overall readmission rate
   ------------------------------------------------------------ */
SELECT
    COUNT(*)                                                              AS total_encounters,
    ROUND(AVG(CASE WHEN readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS overall_readmit_pct
FROM fact_encounters;


/* ------------------------------------------------------------
   1. Readmission rate by age band
      Q: Which patient groups have the highest readmission rates?
      Joins the fact table to dim_age; sorted youngest -> oldest
      using the sort_order column built into the dimension.
   ------------------------------------------------------------ */
SELECT
    a.age_band,
    COUNT(*)                                                                AS encounters,
    ROUND(AVG(CASE WHEN f.readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters f
JOIN dim_age a
    ON f.age_band = a.age_band
GROUP BY a.age_band, a.sort_order
ORDER BY a.sort_order;


/* ------------------------------------------------------------
   2. Readmission rate by prior inpatient stays
      Q: How does prior hospital use relate to readmission?
      Buckets the raw count of prior admissions. Strongest
      signal in the analysis (steep dose-response).
   ------------------------------------------------------------ */
SELECT
    CASE
        WHEN n_inpatient = 0            THEN '0 prior stays'
        WHEN n_inpatient = 1            THEN '1 prior stay'
        WHEN n_inpatient BETWEEN 2 AND 3 THEN '2-3 prior stays'
        ELSE '4+ prior stays'
    END                                                                   AS prior_inpatient_group,
    COUNT(*)                                                              AS encounters,
    ROUND(AVG(CASE WHEN readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters
GROUP BY prior_inpatient_group
ORDER BY MIN(n_inpatient);


/* ------------------------------------------------------------
   3. Readmission rate by prior emergency visits
      Q: Does prior ER use relate to readmission?
      Same dose-response pattern as inpatient stays.
   ------------------------------------------------------------ */
SELECT
    CASE
        WHEN n_emergency = 0 THEN '0 ER visits'
        WHEN n_emergency = 1 THEN '1 ER visit'
        ELSE '2+ ER visits'
    END                                                                   AS prior_er_group,
    COUNT(*)                                                              AS encounters,
    ROUND(AVG(CASE WHEN readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters
GROUP BY prior_er_group
ORDER BY MIN(n_emergency);


/* ------------------------------------------------------------
   4. Readmission rate by A1C test result
      Q: Do diabetes-management indicators differ by outcome?
      Reusable shape: swap a1c_test for diabetes_med or
      glucose_test in BOTH the SELECT and the GROUP BY.
   ------------------------------------------------------------ */
SELECT
    a1c_test,
    COUNT(*)                                                              AS encounters,
    ROUND(AVG(CASE WHEN readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters
GROUP BY a1c_test
ORDER BY readmit_pct DESC;


/* ------------------------------------------------------------
   5. Readmission rate by diabetes medication
   ------------------------------------------------------------ */
SELECT
    diabetes_med,
    COUNT(*)                                                              AS encounters,
    ROUND(AVG(CASE WHEN readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters
GROUP BY diabetes_med
ORDER BY readmit_pct DESC;


/* ------------------------------------------------------------
   6. Readmission rate by glucose test result
   ------------------------------------------------------------ */
SELECT
    glucose_test,
    COUNT(*)                                                              AS encounters,
    ROUND(AVG(CASE WHEN readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters
GROUP BY glucose_test
ORDER BY readmit_pct DESC;


/* ------------------------------------------------------------
   7. Readmission rate by PRIMARY diagnosis
      Q: Which diagnoses are most associated with readmission?
      Walks fact -> bridge -> dim_diagnosis and keeps only the
      primary diagnosis (slot 1) so each encounter counts once.
   ------------------------------------------------------------ */
SELECT
    d.diagnosis_category                                                    AS primary_diagnosis,
    COUNT(*)                                                                AS encounters,
    ROUND(AVG(CASE WHEN f.readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters f
JOIN bridge_encounter_diagnosis b
    ON f.encounter_id = b.encounter_id
JOIN dim_diagnosis d
    ON b.diagnosis_id = d.diagnosis_id
WHERE b.diagnosis_position = 1
GROUP BY d.diagnosis_category
ORDER BY readmit_pct DESC;


/* ------------------------------------------------------------
   8. Readmission rate by medical specialty
      Q: Which specialties are most associated with readmission?
      Note: ~half of encounters have a 'Missing' specialty; it
      appears as its own row and should be flagged, not hidden.
      Read as correlation (who the dept sees), not causation.
   ------------------------------------------------------------ */
SELECT
    s.specialty_name,
    COUNT(*)                                                                AS encounters,
    ROUND(AVG(CASE WHEN f.readmitted = 'yes' THEN 1.0 ELSE 0 END) * 100, 1) AS readmit_pct
FROM fact_encounters f
JOIN dim_specialty s
    ON f.specialty_id = s.specialty_id
GROUP BY s.specialty_name
ORDER BY readmit_pct DESC;
