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

DESCRIBE vw_final_state_analysis;



DESCRIBE nces_lea_county_crosswalk;

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
    -- Geography
    q1.state_name,
    q1.state_abbreviation,

    -- Pediatric mental-health burden
    q1.pct_current_anxiety,
    q1.pct_current_depression,
    q1.pct_current_adhd,

    q1.pct_any_current_condition,
    q1.pct_two_or_more_conditions,
    q1.pct_all_three_conditions,

    -- Primary condition profile
    q1.dominant_condition_profile,
    q1.dominant_profile_pct,

    -- Multi-condition profile
    q1.dominant_cooccurring_profile,
    q1.dominant_cooccurring_pct,

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


-- ---------------------------------------------------------
-- PART 3 QA:
-- Confirm state view has expected geography and measures.
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_abbreviation) AS unique_states,
    SUM(q5_priority_state) AS priority_states
FROM vw_final_state_analysis;

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
  -- Pediatric mental-health burden
q1.pct_current_anxiety,
q1.pct_current_depression,
q1.pct_current_adhd,

q1.pct_any_current_condition,
q1.pct_two_or_more_conditions,
q1.pct_all_three_conditions,

-- Primary condition profile
q1.dominant_condition_profile,
q1.dominant_profile_pct,

-- Multi-condition profile
q1.dominant_cooccurring_profile,
q1.dominant_cooccurring_pct,

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

-- =========================================================
-- TABLEAU EXPORT
-- QUESTION:
-- Across the 10 priority states, what patterns of pediatric
-- mental-health need, school support, and provider shortage
-- help explain why these states surfaced?
--
-- PURPOSE:
-- Create one Tableau-ready state table using the FINAL
-- validated SQL views already produced in Questions 1-9.
--
-- Higher pressure_score = greater relative pressure
-- within THIS 10-state group.
-- =========================================================


CREATE OR REPLACE VIEW vw_tableau_priority_states AS

WITH priority_base AS (

    SELECT
        f.state_name,
        f.state_abbreviation,

        -- Final consensus ranking from Question 5
        p.consensus_mismatch_rank,

        ROW_NUMBER() OVER (
            ORDER BY p.consensus_mismatch_rank ASC
        ) AS priority_rank,

        -- ---------------------------------------------
        -- PEDIATRIC MENTAL-HEALTH NEED
        -- ---------------------------------------------
        f.pct_any_current_condition,
        f.pct_two_or_more_conditions,

        -- ---------------------------------------------
        -- SCHOOL MENTAL-HEALTH SUPPORT
        -- Higher students-per-staff = thinner capacity
        -- ---------------------------------------------
        f.students_per_psychologist,
        f.students_per_guidance_counselor,

        -- ---------------------------------------------
        -- COMMUNITY MENTAL-HEALTH ACCESS
        -- ---------------------------------------------
        f.avg_hpsa_score,
        f.max_hpsa_score,
        f.pct_designated_population_underserved,
        f.provider_shortage_per_100k

    FROM vw_final_state_analysis AS f

    INNER JOIN vw_q7_priority_states AS p
        ON f.state_abbreviation = p.state_abbreviation
),

scored AS (

    SELECT
        *,

        -- =====================================================
        -- NORMALIZED PRESSURE SCORES
        --
        -- Tableau heatmaps should not compare raw percentages,
        -- ratios, and HPSA scores on one shared color scale.
        --
        -- These convert each measure to a 0-100 RELATIVE score
        -- within the 10 priority states.
        --
        -- 100 = greatest relative pressure in this group
        -- 0   = lowest relative pressure in this group
        -- =====================================================

        ROUND(
            100 * PERCENT_RANK() OVER (
                ORDER BY pct_two_or_more_conditions ASC
            ),
            1
        ) AS need_2plus_pressure_score,

        ROUND(
            100 * PERCENT_RANK() OVER (
                ORDER BY pct_any_current_condition ASC
            ),
            1
        ) AS need_any_pressure_score,

        ROUND(
            100 * PERCENT_RANK() OVER (
                ORDER BY students_per_psychologist ASC
            ),
            1
        ) AS psychologist_pressure_score,

        ROUND(
            100 * PERCENT_RANK() OVER (
                ORDER BY students_per_guidance_counselor ASC
            ),
            1
        ) AS counselor_pressure_score,

        ROUND(
            100 * PERCENT_RANK() OVER (
                ORDER BY avg_hpsa_score ASC
            ),
            1
        ) AS hpsa_pressure_score,

        ROUND(
            100 * PERCENT_RANK() OVER (
                ORDER BY provider_shortage_per_100k ASC
            ),
            1
        ) AS provider_shortage_pressure_score

    FROM priority_base
)

SELECT *
FROM scored

ORDER BY priority_rank;

SELECT *
FROM vw_tableau_priority_states
ORDER BY priority_rank;

SELECT
    COUNT(*) AS rows,
    COUNT(DISTINCT state_abbreviation) AS unique_states,
    MIN(priority_rank) AS first_rank,
    MAX(priority_rank) AS last_rank
FROM vw_tableau_priority_states;

-- =========================================================
-- TABLEAU LONG FORMAT
--
-- One row = one state x one indicator
--
-- This is ideal for:
-- Rows    = State
-- Columns = Indicator
-- Color   = Pressure Score
-- =========================================================


CREATE OR REPLACE VIEW vw_tableau_priority_states_long AS


-- 2+ CURRENT CONDITIONS
SELECT
    state_name,
    state_abbreviation,
    priority_rank,
    consensus_mismatch_rank,

    'Mental-health need' AS indicator_group,
    '2+ current conditions' AS indicator,

    pct_two_or_more_conditions AS raw_value,
    '%' AS unit,

    need_2plus_pressure_score AS pressure_score

FROM vw_tableau_priority_states


UNION ALL


-- ANY CURRENT CONDITION
SELECT
    state_name,
    state_abbreviation,
    priority_rank,
    consensus_mismatch_rank,

    'Mental-health need',
    'Any current condition',

    pct_any_current_condition,
    '%',

    need_any_pressure_score

FROM vw_tableau_priority_states


UNION ALL


-- SCHOOL PSYCHOLOGISTS
SELECT
    state_name,
    state_abbreviation,
    priority_rank,
    consensus_mismatch_rank,

    'School support',
    'Students per psychologist',

    students_per_psychologist,
    'students per staff FTE',

    psychologist_pressure_score

FROM vw_tableau_priority_states


UNION ALL


-- GUIDANCE COUNSELORS
SELECT
    state_name,
    state_abbreviation,
    priority_rank,
    consensus_mismatch_rank,

    'School support',
    'Students per guidance counselor',

    students_per_guidance_counselor,
    'students per staff FTE',

    counselor_pressure_score

FROM vw_tableau_priority_states


UNION ALL


-- HPSA SEVERITY
SELECT
    state_name,
    state_abbreviation,
    priority_rank,
    consensus_mismatch_rank,

    'Provider access',
    'Average HPSA score',

    avg_hpsa_score,
    'HPSA score',

    hpsa_pressure_score

FROM vw_tableau_priority_states


UNION ALL


-- PROVIDER SHORTAGE
SELECT
    state_name,
    state_abbreviation,
    priority_rank,
    consensus_mismatch_rank,

    'Provider access',
    'Provider shortage per 100k',

    provider_shortage_per_100k,
    'shortage per 100k',

    provider_shortage_pressure_score

FROM vw_tableau_priority_states;

SELECT *
FROM vw_tableau_priority_states_long
ORDER BY
    priority_rank,
    indicator_group,
    indicator;

    COPY (
    SELECT *
    FROM vw_tableau_priority_states_long
    ORDER BY priority_rank, indicator_group, indicator
)
TO '../data/exports_tableau/tableau_priority_states_long.csv'
(
    HEADER,
    DELIMITER ','
);

COPY (
    SELECT *
    FROM vw_tableau_priority_states
    ORDER BY priority_rank
)
TO '../data/exports_tableau/tableau_priority_states_wide.csv'
(
    HEADER,
    DELIMITER ','
);