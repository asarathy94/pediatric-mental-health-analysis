-- =========================================================
-- EXPORT VISUALIZATION TABLES
-- Purpose:
-- Export final SQL analysis views as CSV files for
-- Power BI, Tableau, and portfolio visualization work.
-- =========================================================


-- ---------------------------------------------------------
-- 1. Final state-level analysis
-- Main Power BI / Tableau national analysis table
-- ---------------------------------------------------------

COPY (
    SELECT *
    FROM vw_final_state_analysis
    ORDER BY state_name
)
TO '../data/analysis_exports/10_final_state_analysis.csv'
WITH (
    HEADER,
    DELIMITER ','
);


-- ---------------------------------------------------------
-- 2. Oregon county-level overlap
-- County drill-down for local service-design case study
-- ---------------------------------------------------------

COPY (
    SELECT *
    FROM vw_final_oregon_county_overlap
    ORDER BY county_candidate_rank_within_state
)
TO '../data/analysis_exports/10b_oregon_counties.csv'
WITH (
    HEADER,
    DELIMITER ','
);


-- ---------------------------------------------------------
-- 3. Oregon district-level overlap
-- District drill-down beneath Oregon counties
-- ---------------------------------------------------------

COPY (
    SELECT *
    FROM vw_final_oregon_district_overlap
    ORDER BY
        county_shortage_rank_within_state,
        combined_school_support_rank_within_state
)
TO '../data/analysis_exports/10c_oregon_districts.csv'
WITH (
    HEADER,
    DELIMITER ','
);