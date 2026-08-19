-- =========================================================
-- QUESTION 9
-- Within the priority states, which local areas show
-- overlapping school-based mental-health staffing
-- constraints and community mental-health provider
-- shortages?
--
-- PART 1:
-- Load the NCES LEA-to-county geographic relationship file.
-- =========================================================

INSTALL excel;
LOAD excel;

CREATE OR REPLACE TABLE nces_lea_county_crosswalk AS

SELECT *
FROM read_xlsx(
    '../data/raw/NCES_CC_GEO/GRF25/GRF25/grf25_lea_county.xlsx'
);

DESCRIBE nces_lea_county_crosswalk;

-- =========================================================
-- QUESTION 9
-- PART 3:
-- Standardize the district-to-county crosswalk.
--
-- Keep only the district ID, district name,
-- county FIPS, and county name.
--
-- LEAID and county FIPS stay as VARCHAR so
-- leading zeros are preserved.
-- =========================================================

CREATE OR REPLACE VIEW vw_q9_district_county_crosswalk AS

SELECT DISTINCT

    TRIM(LEAID) AS LEAID,

    TRIM(NAME_LEA25) AS district_name,

    LPAD(TRIM(STCOUNTY), 5, '0') AS county_fips,

    TRIM(NAME_COUNTY25) AS county_name

FROM nces_lea_county_crosswalk

WHERE LEAID IS NOT NULL
  AND STCOUNTY IS NOT NULL;

  SELECT
    COUNT(*) AS crosswalk_rows,
    COUNT(DISTINCT LEAID) AS unique_districts,
    COUNT(DISTINCT county_fips) AS unique_counties
FROM vw_q9_district_county_crosswalk;

-- =========================================================
-- QUESTION 9
-- PART 4:
-- Map the priority school districts from Question 7
-- to their counties using the NCES geographic crosswalk.
-- =========================================================

CREATE OR REPLACE VIEW vw_q9_priority_district_counties AS

SELECT
    d.state_name,
    d.state_abbreviation,

    d.LEAID,
    d.LEA_NAME,

    d.total_students,
    d.students_per_psychologist,
    d.students_per_guidance_counselor,

    d.combined_school_support_rank_within_state,

    x.county_fips,
    x.county_name

FROM vw_q7_priority_district_support_ranked AS d

INNER JOIN vw_q9_district_county_crosswalk AS x
    ON TRIM(CAST(d.LEAID AS VARCHAR)) = x.LEAID;

    SELECT
    COUNT(*) AS mapped_rows,
    COUNT(DISTINCT LEAID) AS mapped_districts,
    COUNT(DISTINCT county_fips) AS mapped_counties

FROM vw_q9_priority_district_counties;

-- =========================================================
-- QUESTION 9
-- PART 5:
-- Join mapped priority school districts to county-level
-- HPSA mental-health shortage results from Question 7.
--
-- This creates the local overlap table:
--
-- thin school support
--        +
-- severe community provider shortage
-- =========================================================

CREATE OR REPLACE VIEW vw_q9_local_overlap AS

SELECT
    d.state_name,
    d.state_abbreviation,

    d.LEAID,
    d.LEA_NAME,

    d.total_students,
    d.students_per_psychologist,
    d.students_per_guidance_counselor,
    d.combined_school_support_rank_within_state,

    d.county_fips,
    d.county_name,

    h.hpsa_designation_count,
    h.avg_hpsa_score,
    h.max_hpsa_score,
    h.county_shortage_rank_within_state

FROM vw_q9_priority_district_counties AS d

INNER JOIN vw_q7_priority_county_hpsa_ranked_final AS h
    ON d.state_abbreviation = h.state_abbreviation
   AND d.county_fips = h.county_fips;

   SELECT
    COUNT(*) AS overlap_rows,
    COUNT(DISTINCT LEAID) AS overlap_districts,
    COUNT(DISTINCT county_fips) AS overlap_counties

FROM vw_q9_local_overlap;

-- =========================================================
-- QUESTION 9
-- PART 6:
-- Rank local areas where BOTH school support is thin
-- and community mental-health provider shortage is severe.
--
-- Lower score = stronger overlap.
-- =========================================================

CREATE OR REPLACE VIEW vw_q9_local_overlap_ranked AS

SELECT
    *,

    ROUND(
        (
            combined_school_support_rank_within_state
            + county_shortage_rank_within_state
        ) / 2.0,
        2
    ) AS local_overlap_score

FROM vw_q9_local_overlap;

SELECT
    state_name,
    state_abbreviation,
    LEA_NAME,
    county_name,

    students_per_psychologist,
    students_per_guidance_counselor,
    combined_school_support_rank_within_state,

    avg_hpsa_score,
    max_hpsa_score,
    county_shortage_rank_within_state,

    local_overlap_score

FROM vw_q9_local_overlap_ranked

ORDER BY
    local_overlap_score ASC,
    combined_school_support_rank_within_state ASC,
    county_shortage_rank_within_state ASC

LIMIT 30;

-- =========================================================
-- QUESTION 9
-- PART 7:
-- Identify counties where MULTIPLE school districts show
-- thin school mental-health support while the county also
-- shows a strong community mental-health provider shortage.
--
-- This helps distinguish isolated district findings from
-- broader local system-pressure clusters.
-- =========================================================

SELECT
    state_name,
    state_abbreviation,

    county_name,
    county_fips,

    COUNT(DISTINCT LEAID)
        AS overlapping_district_count,

    ROUND(
        AVG(combined_school_support_rank_within_state),
        2
    ) AS avg_school_support_rank,

    ROUND(
        AVG(students_per_psychologist),
        1
    ) AS avg_students_per_psychologist,

    ROUND(
        AVG(students_per_guidance_counselor),
        1
    ) AS avg_students_per_guidance_counselor,

    MAX(avg_hpsa_score)
        AS avg_hpsa_score,

    MAX(max_hpsa_score)
        AS max_hpsa_score,

    MAX(county_shortage_rank_within_state)
        AS county_shortage_rank_within_state

FROM vw_q9_local_overlap_ranked

GROUP BY
    state_name,
    state_abbreviation,
    county_name,
    county_fips

HAVING COUNT(DISTINCT LEAID) >= 2

ORDER BY
    overlapping_district_count DESC,
    county_shortage_rank_within_state ASC,
    avg_school_support_rank ASC;

    -- =========================================================
-- QUESTION 9
-- PART 8:
-- Rank county-level local overlap clusters within each
-- priority state.
--
-- A stronger candidate has:
--   1. comparatively thin school support across districts
--   2. comparatively severe community provider shortage
--
-- Number of overlapping districts is preserved as context,
-- but is NOT treated as proof that a county has greater need.
--
-- Lower combined score = stronger local overlap.
-- =========================================================

CREATE OR REPLACE VIEW vw_q9_county_overlap_candidates AS

WITH county_summary AS (

    SELECT
        state_name,
        state_abbreviation,

        county_name,
        county_fips,

        COUNT(DISTINCT LEAID)
            AS overlapping_district_count,

        ROUND(
            AVG(combined_school_support_rank_within_state),
            2
        ) AS avg_school_support_rank,

        ROUND(
            AVG(students_per_psychologist),
            1
        ) AS avg_students_per_psychologist,

        ROUND(
            AVG(students_per_guidance_counselor),
            1
        ) AS avg_students_per_guidance_counselor,

        MAX(avg_hpsa_score)
            AS avg_hpsa_score,

        MAX(max_hpsa_score)
            AS max_hpsa_score,

        MAX(county_shortage_rank_within_state)
            AS county_shortage_rank_within_state

    FROM vw_q9_local_overlap_ranked

    GROUP BY
        state_name,
        state_abbreviation,
        county_name,
        county_fips
),

scored AS (

    SELECT
        *,

        ROUND(
            (
                avg_school_support_rank
                + county_shortage_rank_within_state
            ) / 2.0,
            2
        ) AS county_overlap_score

    FROM county_summary
)

SELECT
    *,

    ROW_NUMBER() OVER (
        PARTITION BY state_abbreviation
        ORDER BY
            county_overlap_score ASC,
            avg_hpsa_score DESC,
            overlapping_district_count DESC
    ) AS county_candidate_rank_within_state

FROM scored;

SELECT
    state_name,
    county_name,

    overlapping_district_count,

    avg_students_per_psychologist,
    avg_students_per_guidance_counselor,

    avg_school_support_rank,

    avg_hpsa_score,
    max_hpsa_score,
    county_shortage_rank_within_state,

    county_overlap_score,
    county_candidate_rank_within_state

FROM vw_q9_county_overlap_candidates

WHERE county_candidate_rank_within_state <= 3

ORDER BY
    state_name,
    county_candidate_rank_within_state;

    -- =========================================================
-- SQL CLOSEOUT
-- PART 1:
-- Final Oregon county-level overlap view
--
-- PURPOSE:
-- Preserve all Oregon county candidates where school-based
-- mental-health staffing constraints overlap with community
-- mental-health provider shortages.
--
-- This becomes the geographic foundation for the
-- Oregon service-design / case-study phase.
-- =========================================================

CREATE OR REPLACE VIEW vw_final_oregon_county_overlap AS

SELECT
    state_name,
    state_abbreviation,

    county_name,
    county_fips,

    overlapping_district_count,

    avg_students_per_psychologist,
    avg_students_per_guidance_counselor,

    avg_school_support_rank,

    avg_hpsa_score,
    max_hpsa_score,
    county_shortage_rank_within_state,

    county_overlap_score,
    county_candidate_rank_within_state

FROM vw_q9_county_overlap_candidates

WHERE state_abbreviation = 'OR'

ORDER BY county_candidate_rank_within_state;

SELECT *
FROM vw_final_oregon_county_overlap
ORDER BY county_candidate_rank_within_state;

-- =========================================================
-- SQL CLOSEOUT
-- PART 2:
-- Final Oregon district-level overlap view
--
-- PURPOSE:
-- Preserve the individual school districts underlying
-- Oregon's county-level overlap findings.
--
-- This allows Power BI / the case study to drill from:
--
-- Oregon
--   -> County
--      -> School district
--
-- while retaining both school staffing and community
-- mental-health shortage measures.
-- =========================================================

CREATE OR REPLACE VIEW vw_final_oregon_district_overlap AS

SELECT
    state_name,
    state_abbreviation,

    county_name,
    county_fips,

    LEAID,
    LEA_NAME,

    total_students,

    students_per_psychologist,
    students_per_guidance_counselor,
    combined_school_support_rank_within_state,

    hpsa_designation_count,
    avg_hpsa_score,
    max_hpsa_score,
    county_shortage_rank_within_state,

    local_overlap_score

FROM vw_q9_local_overlap_ranked

WHERE state_abbreviation = 'OR'

ORDER BY
    county_shortage_rank_within_state,
    combined_school_support_rank_within_state;

    SELECT
    COUNT(*) AS district_county_rows,
    COUNT(DISTINCT LEAID) AS unique_districts,
    COUNT(DISTINCT county_fips) AS unique_counties
FROM vw_final_oregon_district_overlap;

-- =========================================================
-- SQL CLOSEOUT
-- PART 3:
-- Final state-level analysis view for Power BI / reporting.
--
-- PURPOSE:
-- Combine the core state-level burden and support measures
-- used across Questions 1–5 into one clean export view.
-- =========================================================

CREATE OR REPLACE VIEW vw_final_state_analysis AS

SELECT
    q1.state_name,
    q1.state_abbreviation,

    -- Pediatric mental-health burden
    q1.pct_any_current_condition,
    q1.pct_two_or_more_conditions,

    -- School mental-health support
    q2.students_per_psychologist,
    q2.students_per_guidance_counselor,

    -- Community mental-health support
    q3.avg_hpsa_score,
    q3.max_hpsa_score,
    q3.pct_designated_population_underserved,
    q3.provider_shortage_per_100k,

    -- Flag the 10 states selected in Question 5
    CASE
        WHEN q1.state_abbreviation IN (
            'UT', 'MS', 'WV', 'IN', 'MT',
            'OR', 'KY', 'IA', 'WA', 'WY'
        )
        THEN 1
        ELSE 0
    END AS q5_priority_state

FROM vw_nsch_state_question_1_final AS q1

LEFT JOIN vw_nces_state_school_support_final AS q2
    ON q1.state_abbreviation = q2.state_abbreviation

LEFT JOIN vw_hpsa_state_community_support_final AS q3
    ON q1.state_abbreviation = q3.state_abbreviation;

    SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_abbreviation) AS unique_states,
    SUM(q5_priority_state) AS priority_states
FROM vw_final_state_analysis;

-- =========================================================
-- SQL CLOSEOUT
-- PART 4:
-- Final QA across national, Oregon county,
-- and Oregon district analysis views.
-- =========================================================

SELECT
    'state_analysis' AS dataset,
    COUNT(*) AS row_count
FROM vw_final_state_analysis

UNION ALL

SELECT
    'oregon_county_overlap' AS dataset,
    COUNT(*) AS row_count
FROM vw_final_oregon_county_overlap

UNION ALL

SELECT
    'oregon_district_overlap' AS dataset,
    COUNT(*) AS row_count
FROM vw_final_oregon_district_overlap;