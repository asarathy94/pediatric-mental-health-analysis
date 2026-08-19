-- =========================================================
-- QUESTION 7
-- Within the priority states identified in Question 5,
-- which demographic and geographic communities appear
-- most affected?
--
-- Q7A = demographic communities
--       especially race / ethnicity
--
-- Q7B = literal geographic communities
--       including school districts and available
--       HPSA geographic areas
--
-- IMPORTANT:
-- NSCH supports demographic analysis within states,
-- but does NOT contain a validated child-level county
-- or school-district identifier.
--
-- Local geography therefore comes from other datasets
-- such as NCES and HPSA and is interpreted contextually,
-- not attached directly to individual NSCH children.
-- =========================================================


-- ---------------------------------------------------------
-- ---------------------------------------------------------
-- PART 1:
-- Create the top-10 priority-state shortlist from the
-- Question 5 consensus need-support mismatch ranking.
--
-- Add state FIPS so the child-level NSCH data can be joined
-- reliably to the priority-state list.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_states AS

SELECT
    c.state_name,
    c.state_abbreviation,
    q1.state_fips_code,
    c.consensus_mismatch_rank

FROM vw_state_need_support_mismatch_consensus AS c

LEFT JOIN vw_nsch_state_question_1_final AS q1
    ON c.state_abbreviation = q1.state_abbreviation

ORDER BY c.consensus_mismatch_rank ASC

LIMIT 10;

SELECT *
FROM vw_q7_priority_states
ORDER BY consensus_mismatch_rank ASC;

-- ---------------------------------------------------------
-- PART 2A:
-- Check racial-group sample sizes within each priority state.
--
-- NSCH child records are joined to the Q5 priority-state
-- shortlist using state FIPS code.
-- ---------------------------------------------------------

SELECT
    p.state_name,
    p.state_abbreviation,
    n.child_race,

    COUNT(*) AS sample_n

FROM vw_nsch_q6_unmet_care_cohort AS n

INNER JOIN vw_q7_priority_states AS p
    ON n.state_fips_code = p.state_fips_code

GROUP BY
    p.state_name,
    p.state_abbreviation,
    n.child_race

ORDER BY
    p.state_name,
    sample_n DESC;

    -- ---------------------------------------------------------
-- PART 2A QA:
-- Check Hispanic ethnicity sample sizes within each
-- priority state.
-- ---------------------------------------------------------

SELECT
    p.state_name,
    p.state_abbreviation,
    n.child_hispanic_ethnicity,

    COUNT(*) AS sample_n

FROM vw_nsch_q6_unmet_care_cohort AS n

INNER JOIN vw_q7_priority_states AS p
    ON n.state_fips_code = p.state_fips_code

GROUP BY
    p.state_name,
    p.state_abbreviation,
    n.child_hispanic_ethnicity

ORDER BY
    p.state_name,
    sample_n DESC;

    -- ---------------------------------------------------------
-- PART 3A:
-- Demographic communities across the combined priority-state
-- cohort.
--
-- Because many state-by-race cells are very small, this
-- analysis pools the 10 priority states before comparing
-- demographic groups.
--
-- This produces more stable weighted estimates than
-- interpreting tiny race cells within individual states.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_demographic_rates AS

-- RACE
SELECT
    'Race' AS demographic_type,
    CAST(n.child_race AS VARCHAR) AS demographic_category,

    COUNT(*) AS sample_n,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN n.unmet_mental_health_care = 1
                THEN n.final_sampling_weight
                ELSE 0
            END
        )
        / SUM(n.final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort AS n

INNER JOIN vw_q7_priority_states AS p
    ON n.state_fips_code = p.state_fips_code

GROUP BY n.child_race


UNION ALL


-- HISPANIC ETHNICITY
SELECT
    'Hispanic ethnicity',
    CAST(n.child_hispanic_ethnicity AS VARCHAR),

    COUNT(*),

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN n.unmet_mental_health_care = 1
                THEN n.final_sampling_weight
                ELSE 0
            END
        )
        / SUM(n.final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort AS n

INNER JOIN vw_q7_priority_states AS p
    ON n.state_fips_code = p.state_fips_code

GROUP BY n.child_hispanic_ethnicity


UNION ALL


-- SEX
SELECT
    'Sex',
    CAST(n.child_sex AS VARCHAR),

    COUNT(*),

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN n.unmet_mental_health_care = 1
                THEN n.final_sampling_weight
                ELSE 0
            END
        )
        / SUM(n.final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort AS n

INNER JOIN vw_q7_priority_states AS p
    ON n.state_fips_code = p.state_fips_code

GROUP BY n.child_sex;

-- ---------------------------------------------------------
-- PART 3A QA:
-- Inspect demographic unmet-care patterns across the
-- combined priority-state cohort.
--
-- Very small demographic categories should still be
-- interpreted cautiously.
-- ---------------------------------------------------------

SELECT *
FROM vw_q7_priority_demographic_rates

ORDER BY
    demographic_type,
    weighted_unmet_care_pct DESC;

    -- ---------------------------------------------------------
-- PART 3A CONSERVATIVE QA:
-- Only show demographic categories with at least
-- 100 sampled children across the priority-state cohort.
-- ---------------------------------------------------------

SELECT *
FROM vw_q7_priority_demographic_rates

WHERE sample_n >= 100

ORDER BY
    demographic_type,
    weighted_unmet_care_pct DESC;

    DESCRIBE vw_nces_district_master;

    DESCRIBE hpsa_mental_health;

    -- ---------------------------------------------------------
-- PART 3B:
-- Within the Question 7 priority states, which school
-- districts have the thinnest school mental-health support?
--
-- Measures:
--   1) students per school psychologist
--   2) students per guidance counselor
--
-- Higher students-per-staff = thinner support capacity.
--
-- Districts with missing/zero staffing are preserved as
-- reporting gaps and are not treated as literal zero staff.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_district_support AS

SELECT
    m.STATENAME AS state_name,
    m.ST AS state_abbreviation,

    m.LEAID,
    m.LEA_NAME,

    m.LCITY,
    m.LSTATE,
    m.LZIP,

    m.district_student_count AS total_students,

    s.school_psychologists,
    s.guidance_counselors,

    ROUND(
        m.district_student_count
        / NULLIF(s.school_psychologists, 0),
        1
    ) AS students_per_psychologist,

    ROUND(
        m.district_student_count
        / NULLIF(s.guidance_counselors, 0),
        1
    ) AS students_per_guidance_counselor

FROM vw_nces_district_master AS m

INNER JOIN vw_nces_district_staffing_full AS s
    ON m.LEAID = s.LEAID

INNER JOIN vw_q7_priority_states AS p
    ON m.ST = p.state_abbreviation

WHERE m.district_student_count IS NOT NULL
  AND m.district_student_count > 0;

  -- ---------------------------------------------------------
-- PART 3B QA:
-- Identify priority-state districts with missing or zero
-- psychologist/guidance-counselor staffing.
-- ---------------------------------------------------------

SELECT
    state_name,
    state_abbreviation,
    LEAID,
    LEA_NAME,
    total_students,
    school_psychologists,
    guidance_counselors

FROM vw_q7_priority_district_support

WHERE school_psychologists IS NULL
   OR school_psychologists = 0
   OR guidance_counselors IS NULL
   OR guidance_counselors = 0

ORDER BY
    state_name,
    total_students DESC;

    -- ---------------------------------------------------------
-- PART 3B:
-- Rank districts with usable staffing data by combined
-- school-support weakness.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_district_support_ranked AS

WITH valid AS (

    SELECT *
    FROM vw_q7_priority_district_support

    WHERE school_psychologists > 0
      AND guidance_counselors > 0
),

ranked AS (

    SELECT
        *,

        RANK() OVER (
            PARTITION BY state_abbreviation
            ORDER BY students_per_psychologist DESC
        ) AS psychologist_rank_within_state,

        RANK() OVER (
            PARTITION BY state_abbreviation
            ORDER BY students_per_guidance_counselor DESC
        ) AS guidance_rank_within_state

    FROM valid
)

SELECT
    *,

    ROUND(
        (
            psychologist_rank_within_state
            + guidance_rank_within_state
        ) / 2.0,
        2
    ) AS combined_school_support_rank_within_state

FROM ranked;

-- ---------------------------------------------------------
-- PART 3B QA:
-- Show the weakest school-support districts within each
-- priority state.
-- ---------------------------------------------------------

SELECT *
FROM vw_q7_priority_district_support_ranked

ORDER BY
    state_name,
    combined_school_support_rank_within_state ASC;

    -- ---------------------------------------------------------
-- PART 3C:
-- Show the 10 weakest rankable school districts within each
-- priority state.
--
-- Districts with zero/null psychologist or guidance-
-- counselor staffing are excluded from this ranking and
-- preserved separately as reporting gaps.
-- ---------------------------------------------------------

WITH ranked AS (

    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY state_abbreviation
            ORDER BY combined_school_support_rank_within_state ASC
        ) AS priority_order

    FROM vw_q7_priority_district_support_ranked
)

SELECT
    state_name,
    state_abbreviation,
    LEAID,
    LEA_NAME,
    LCITY,
    LZIP,
    total_students,
    school_psychologists,
    guidance_counselors,
    students_per_psychologist,
    students_per_guidance_counselor,
    psychologist_rank_within_state,
    guidance_rank_within_state,
    combined_school_support_rank_within_state

FROM ranked

WHERE priority_order <= 10

ORDER BY
    state_name,
    priority_order;

    -- ---------------------------------------------------------
-- PART 4A QA:
-- Identify local HPSA shortage fields available for
-- county-level community-support analysis.
-- ---------------------------------------------------------

SELECT column_name
FROM information_schema.columns
WHERE table_name = 'hpsa_mental_health'
  AND (
       LOWER(column_name) LIKE '%underserved%'
    OR LOWER(column_name) LIKE '%provider%'
    OR LOWER(column_name) LIKE '%shortage%'
  )
ORDER BY column_name;

-- ---------------------------------------------------------
-- PART 4B QA:
-- Determine whether HPSA shortage and underserved-population
-- values are repeated across multiple county/component rows
-- within the same HPSA designation.
--
-- If designation-level values repeat across county rows,
-- they must NOT be summed directly at county level.
-- ---------------------------------------------------------

SELECT
    "HPSA ID",

    COUNT(*) AS component_rows,

    COUNT(DISTINCT "Common State County FIPS Code")
        AS county_count,

    COUNT(DISTINCT "HPSA Estimated Underserved Population")
        AS distinct_underserved_values,

    COUNT(DISTINCT "HPSA Shortage")
        AS distinct_shortage_values,

    MIN("HPSA Estimated Underserved Population")
        AS min_underserved_population,

    MAX("HPSA Estimated Underserved Population")
        AS max_underserved_population,

    MIN("HPSA Shortage")
        AS min_shortage,

    MAX("HPSA Shortage")
        AS max_shortage

FROM hpsa_mental_health

WHERE "Primary State Abbreviation" IN (
    SELECT state_abbreviation
    FROM vw_q7_priority_states
)

GROUP BY "HPSA ID"

HAVING COUNT(DISTINCT "Common State County FIPS Code") > 1

ORDER BY county_count DESC;

-- ---------------------------------------------------------
-- PART 4C:
-- Create a safe county-level community mental-health
-- shortage profile within the Question 7 priority states.
--
-- This uses metrics that can be aggregated from component
-- geography without summing repeated designation-level
-- population or shortage values.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_county_hpsa AS

SELECT
    h."Primary State Abbreviation" AS state_abbreviation,

    h."Common County Name" AS county_name,

    h."Common State County FIPS Code" AS county_fips,

    COUNT(DISTINCT h."HPSA ID")
        AS hpsa_designation_count,

    ROUND(
        AVG(h."HPSA Score"),
        2
    ) AS avg_hpsa_score,

    MAX(h."HPSA Score")
        AS max_hpsa_score

FROM hpsa_mental_health AS h

INNER JOIN vw_q7_priority_states AS p
    ON h."Primary State Abbreviation" = p.state_abbreviation

WHERE h."Common County Name" IS NOT NULL

GROUP BY
    h."Primary State Abbreviation",
    h."Common County Name",
    h."Common State County FIPS Code";

    -- ---------------------------------------------------------
-- PART 4C QA:
-- Show counties with the most severe local HPSA patterns
-- inside the priority states.
-- ---------------------------------------------------------

SELECT *
FROM vw_q7_priority_county_hpsa

ORDER BY
    state_abbreviation,
    avg_hpsa_score DESC,
    hpsa_designation_count DESC;

    -- ---------------------------------------------------------
-- PART 4D:
-- Rank counties within each priority state by local HPSA
-- severity.
--
-- Rank 1 = highest average HPSA severity within the state.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_county_hpsa_ranked AS

SELECT
    *,

    RANK() OVER (
        PARTITION BY state_abbreviation
        ORDER BY avg_hpsa_score DESC,
                 hpsa_designation_count DESC
    ) AS county_shortage_rank_within_state

FROM vw_q7_priority_county_hpsa;

-- ---------------------------------------------------------
-- PART 4D QA:
-- Show the top 10 highest-severity HPSA counties within
-- each priority state.
-- ---------------------------------------------------------

WITH ranked AS (

    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY state_abbreviation
            ORDER BY county_shortage_rank_within_state ASC
        ) AS priority_order

    FROM vw_q7_priority_county_hpsa_ranked
)

SELECT *
FROM ranked

WHERE priority_order <= 10

ORDER BY
    state_abbreviation,
    priority_order;

    -- ---------------------------------------------------------
-- PART 4E:
-- Create a deduplicated county-HPSA bridge.
--
-- One row = one HPSA designation touching one county.
--
-- This prevents repeated raw component rows from giving
-- individual HPSA designations extra weight in county-level
-- severity calculations.
--
-- "Not Determined" / XXXXX geography is excluded because
-- it cannot be mapped to a literal county.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_county_hpsa_bridge AS

SELECT DISTINCT
    h."Primary State Abbreviation" AS state_abbreviation,

    h."Common County Name" AS county_name,

    h."Common State County FIPS Code" AS county_fips,

    h."HPSA ID" AS hpsa_id,

    h."HPSA Score" AS hpsa_score

FROM hpsa_mental_health AS h

INNER JOIN vw_q7_priority_states AS p
    ON h."Primary State Abbreviation" = p.state_abbreviation

WHERE h."Common County Name" IS NOT NULL

  AND h."Common County Name" <> 'Not Determined'

  AND h."Common State County FIPS Code" IS NOT NULL

  AND h."Common State County FIPS Code" <> 'XXXXX';

  -- ---------------------------------------------------------
-- PART 4F:
-- Final county-level community mental-health shortage
-- profile within the Question 7 priority states.
--
-- Safe measures:
--   - distinct HPSA designations touching the county
--   - average HPSA severity
--   - maximum HPSA severity
--
-- Designation-level underserved population and provider
-- shortage are NOT summed because QA confirmed those values
-- repeat across counties for multi-county HPSAs.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_county_hpsa_final AS

SELECT
    state_abbreviation,
    county_name,
    county_fips,

    COUNT(DISTINCT hpsa_id)
        AS hpsa_designation_count,

    ROUND(
        AVG(hpsa_score),
        2
    ) AS avg_hpsa_score,

    MAX(hpsa_score)
        AS max_hpsa_score

FROM vw_q7_priority_county_hpsa_bridge

GROUP BY
    state_abbreviation,
    county_name,
    county_fips;

    -- ---------------------------------------------------------
-- PART 4G:
-- Rank counties within each priority state by community
-- mental-health shortage severity.
--
-- Primary ordering:
--   1) higher average HPSA score
--   2) more distinct HPSA designations
--   3) higher maximum HPSA score
--
-- Rank 1 = strongest local community-shortage signal
-- within that state.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q7_priority_county_hpsa_ranked_final AS

SELECT
    *,

    RANK() OVER (
        PARTITION BY state_abbreviation

        ORDER BY
            avg_hpsa_score DESC,
            hpsa_designation_count DESC,
            max_hpsa_score DESC
    ) AS county_shortage_rank_within_state

FROM vw_q7_priority_county_hpsa_final;

-- ---------------------------------------------------------
-- PART 4G QA:
-- Show the 10 strongest local community-shortage signals
-- within each Question 7 priority state.
-- ---------------------------------------------------------

WITH ranked AS (

    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY state_abbreviation
            ORDER BY
                county_shortage_rank_within_state ASC,
                county_name
        ) AS priority_order

    FROM vw_q7_priority_county_hpsa_ranked_final
)

SELECT *
FROM ranked

WHERE priority_order <= 10

ORDER BY
    state_abbreviation,
    priority_order;

    -- =========================================================
-- QUESTION 7 FINDINGS SUMMARY
--
-- QUESTION:
-- Within the priority states identified in Question 5,
-- which demographic and geographic communities appear
-- most affected?
--
-- DEMOGRAPHIC FINDINGS:
-- State-by-race NSCH sample sizes were generally too small
-- for reliable race-specific estimates within individual
-- priority states.
--
-- Therefore, demographic estimates were pooled across the
-- 10 priority states.
--
-- Conservative pooled results (n >= 100):
--   Hispanic children:       14.84% weighted unmet care
--   Non-Hispanic children:   12.97%
--
--   Male children:           13.67%
--   Female children:         12.83%
--
-- Race-specific estimates were not emphasized because most
-- minority race categories had insufficient sample sizes
-- within the priority-state cohort.
--
--
-- GEOGRAPHIC FINDINGS:
--
-- School geography:
-- NCES district-level staffing identified districts within
-- each priority state with comparatively thin psychologist
-- and/or guidance-counselor capacity.
--
-- Districts with zero or missing staffing values were
-- treated as reporting gaps rather than assumed to have
-- literally zero staff.
--
-- Community geography:
-- HPSA county/component geography identified local areas
-- with severe mental-health provider-shortage designations.
--
-- Examples of leading within-state shortage signals include:
--
--   IA: Crawford County
--   IN: Delaware County
--   KY: Cumberland County / Lewis County
--   MS: Sunflower County
--   MT: Blaine County / Pondera County
--   OR: Washington County
--   UT: Salt Lake County
--   WA: Franklin County
--   WV: Putnam County
--   WY: Campbell / Johnson / Sheridan / Weston Counties
--
-- IMPORTANT INTERPRETATION:
-- These counties are NOT being identified as having the
-- highest measured pediatric unmet-care prevalence.
--
-- Rather, they are local areas within states already
-- identified as national need-support pressure points that
-- also show comparatively severe community mental-health
-- provider-shortage signals.
--
-- HPSA designation-level underserved-population and provider-
-- shortage totals were NOT summed by county because QA showed
-- that those values repeat across component rows for
-- multi-county HPSA designations.
--
-- NCES school districts and HPSA counties are separate
-- geographic systems. They should not be directly joined
-- without a validated district-to-county crosswalk.
--
-- All findings are descriptive/contextual and should not be
-- interpreted as causal relationships.
-- =========================================================