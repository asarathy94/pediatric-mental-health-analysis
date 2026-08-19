-- =========================================================
-- QUESTION 3
-- Which states have the greatest shortage of
-- community-based mental-health care capacity?
--
-- We will use HRSA Mental Health HPSA designations
-- to measure shortage severity and scale by state.
-- =========================================================


-- ---------------------------------------------------------
-- PART 1: Verify the HPSA designation fields available
-- ---------------------------------------------------------

DESCRIBE vw_hpsa_designations;

-- ---------------------------------------------------------
-- PART 1 QA:
-- Preview the community mental-health shortage measures
-- available at the unique HPSA designation level.
-- ---------------------------------------------------------

SELECT
    "HPSA ID",
    primary_state_abbreviation,
    state_fips_code,
    hpsa_score,
    hpsa_status,
    designation_population,
    estimated_served_population,
    estimated_underserved_population,
    hpsa_fte,
    hpsa_formal_ratio,
    provider_ratio_goal,
    hpsa_shortage

FROM vw_hpsa_designations
LIMIT 25;

-- ---------------------------------------------------------
-- PART 2:
-- Which states have the greatest shortage of community-based
-- mental-health care capacity?
--
-- Aggregate unique HPSA designations to the state level.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_hpsa_state_community_support AS

SELECT
    primary_state_abbreviation AS state_abbreviation,
    state_fips_code,

    COUNT(*) AS hpsa_designation_count,

    -- HPSA severity
    ROUND(AVG(hpsa_score), 2) AS avg_hpsa_score,
    MAX(hpsa_score) AS max_hpsa_score,

    -- Population affected
    ROUND(SUM(designation_population), 0)
        AS total_designation_population,

    ROUND(SUM(estimated_served_population), 0)
        AS total_estimated_served_population,

    ROUND(SUM(estimated_underserved_population), 0)
        AS total_estimated_underserved_population,

    -- Current provider capacity
    ROUND(SUM(hpsa_fte), 2) AS total_provider_fte,

    -- Estimated provider shortage
    ROUND(SUM(hpsa_shortage), 2) AS total_provider_shortage

FROM vw_hpsa_designations

WHERE hpsa_status = 'Designated'

GROUP BY
    primary_state_abbreviation,
    state_fips_code;

    -- ---------------------------------------------------------
-- PART 2 QA:
-- Rank states by estimated underserved population.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support
ORDER BY total_estimated_underserved_population DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Rank states by total estimated provider shortage.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support
ORDER BY total_provider_shortage DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Rank states by average HPSA severity score.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support
ORDER BY avg_hpsa_score DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2B QA:
-- Which HPSA jurisdictions are outside the 50 states + DC?
-- ---------------------------------------------------------

SELECT
    state_abbreviation,
    state_fips_code,
    hpsa_designation_count,
    avg_hpsa_score,
    max_hpsa_score
FROM vw_hpsa_state_community_support
WHERE state_abbreviation NOT IN (
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
    'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
    'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
    'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
    'DC'
)
ORDER BY avg_hpsa_score DESC;

-- ---------------------------------------------------------
-- PART 2C:
-- Restrict Question 3 to the 50 states + DC.
-- Territories remain available for separate analysis.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_hpsa_state_community_support_states_only AS

SELECT *
FROM vw_hpsa_state_community_support

WHERE state_abbreviation IN (
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
    'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
    'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
    'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
    'DC'
);

-- ---------------------------------------------------------
-- PART 2C QA:
-- Rank the 50 states + DC by estimated underserved population.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support_states_only
ORDER BY total_estimated_underserved_population DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2C QA:
-- Rank the 50 states + DC by estimated provider shortage.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support_states_only
ORDER BY total_provider_shortage DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2C QA:
-- Rank the 50 states + DC by average HPSA severity.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support_states_only
ORDER BY avg_hpsa_score DESC NULLS LAST;

SELECT COUNT(*)
FROM vw_hpsa_state_community_support_states_only;

-- ---------------------------------------------------------
-- PART 3:
-- Which states have consistently weak community mental-health
-- support capacity?
--
-- For cross-state comparison, raw shortage totals alone can
-- be misleading because states differ greatly in population.
--
-- We therefore compare:
--   1) average HPSA severity score
--   2) percent of HPSA-designated population estimated
--      to be underserved
--   3) estimated provider shortage per 100,000 people
--      in the HPSA-designated population
--
-- Higher values indicate greater shortage.
-- Rank 1 = greatest community-support vulnerability.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_hpsa_state_community_support_ranking AS

WITH rates AS (

    SELECT
        state_abbreviation,
        state_fips_code,

        hpsa_designation_count,
        avg_hpsa_score,
        max_hpsa_score,

        total_designation_population,
        total_estimated_served_population,
        total_estimated_underserved_population,

        total_provider_fte,
        total_provider_shortage,

        ROUND(
            100.0
            * total_estimated_underserved_population
            / NULLIF(total_designation_population, 0),
            2
        ) AS pct_designated_population_underserved,

        ROUND(
            100000.0
            * total_provider_shortage
            / NULLIF(total_designation_population, 0),
            2
        ) AS provider_shortage_per_100k

    FROM vw_hpsa_state_community_support_states_only
),

ranked AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY avg_hpsa_score DESC NULLS LAST
        ) AS hpsa_severity_rank,

        RANK() OVER (
            ORDER BY pct_designated_population_underserved DESC NULLS LAST
        ) AS underserved_share_rank,

        RANK() OVER (
            ORDER BY provider_shortage_per_100k DESC NULLS LAST
        ) AS provider_shortage_rate_rank

    FROM rates
)

SELECT
    *,

    ROUND(
        (
            hpsa_severity_rank
            + underserved_share_rank
            + provider_shortage_rate_rank
        ) / 3.0,
        2
    ) AS avg_community_support_rank

FROM ranked;

-- ---------------------------------------------------------
-- PART 3 QA:
-- Rank states by weakness across all three community
-- mental-health support measures.
--
-- Lower average rank = greater overall shortage.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support_ranking
ORDER BY
    avg_community_support_rank ASC,
    hpsa_severity_rank ASC;

    -- ---------------------------------------------------------
-- PART 3B QA:
-- Check whether missing or zero HPSA values could distort
-- the final community-support ranking.
--
-- We inspect the measures used to calculate:
--   1) average HPSA severity
--   2) percent of designated population underserved
--   3) provider shortage per 100,000 designated population
-- ---------------------------------------------------------

SELECT
    state_abbreviation,
    state_fips_code,

    hpsa_designation_count,
    avg_hpsa_score,

    total_designation_population,
    total_estimated_underserved_population,
    total_provider_shortage

FROM vw_hpsa_state_community_support_states_only

WHERE avg_hpsa_score IS NULL

   OR total_designation_population IS NULL
   OR total_designation_population = 0

   OR total_estimated_underserved_population IS NULL

   OR total_provider_shortage IS NULL

ORDER BY state_abbreviation;

-- ---------------------------------------------------------
-- PART 3C QA:
-- How complete is reporting across the 50 states + DC
-- for the community-support measures used in Part 3?
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS total_states_dc,

    COUNT(avg_hpsa_score)
        AS states_with_hpsa_score,

    COUNT(total_designation_population)
        AS states_with_designation_population,

    COUNT(total_estimated_underserved_population)
        AS states_with_underserved_population,

    COUNT(total_provider_shortage)
        AS states_with_provider_shortage,

    SUM(
        CASE
            WHEN avg_hpsa_score IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_hpsa_score_states,

    SUM(
        CASE
            WHEN total_designation_population IS NULL
              OR total_designation_population = 0
            THEN 1 ELSE 0
        END
    ) AS missing_or_zero_designation_population_states,

    SUM(
        CASE
            WHEN total_estimated_underserved_population IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_underserved_population_states,

    SUM(
        CASE
            WHEN total_provider_shortage IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_provider_shortage_states

FROM vw_hpsa_state_community_support_states_only;

-- ---------------------------------------------------------
-- PART 3D QA:
-- Inspect the normalized community-support measures used
-- in the final composite ranking.
-- ---------------------------------------------------------

SELECT
    state_abbreviation,

    avg_hpsa_score,

    total_designation_population,
    total_estimated_underserved_population,

    ROUND(
        100.0
        * total_estimated_underserved_population
        / NULLIF(total_designation_population, 0),
        2
    ) AS pct_designated_population_underserved,

    total_provider_shortage,

    ROUND(
        100000.0
        * total_provider_shortage
        / NULLIF(total_designation_population, 0),
        2
    ) AS provider_shortage_per_100k

FROM vw_hpsa_state_community_support_states_only

ORDER BY
    pct_designated_population_underserved DESC NULLS LAST;

    -- ---------------------------------------------------------
-- PART 3E QA:
-- Which state/DC is missing the community-support measures
-- used in the final composite ranking?
-- ---------------------------------------------------------

SELECT
    state_abbreviation,
    state_fips_code,

    hpsa_designation_count,
    avg_hpsa_score,
    total_designation_population,
    total_estimated_underserved_population,
    total_provider_shortage

FROM vw_hpsa_state_community_support_states_only

WHERE total_estimated_underserved_population IS NULL
   OR total_provider_shortage IS NULL

ORDER BY state_abbreviation;

-- ---------------------------------------------------------
-- PART 3F:
-- Final community-support vulnerability ranking.
--
-- Final measures:
--   1) average HPSA severity score
--   2) percent of designated population underserved
--   3) provider shortage per 100,000 designated population
--
-- Vermont is excluded from the composite ranking because
-- estimated underserved population and provider shortage
-- are missing in this HPSA extract.
--
-- IMPORTANT:
-- Vermont is treated as a reporting gap, NOT as having
-- no community mental-health shortage.
--
-- Higher values = greater shortage.
-- Rank 1 = greatest community-support vulnerability.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_hpsa_state_community_support_final AS

WITH rates AS (

    SELECT
        state_abbreviation,
        state_fips_code,

        hpsa_designation_count,
        avg_hpsa_score,
        max_hpsa_score,

        total_designation_population,
        total_estimated_served_population,
        total_estimated_underserved_population,

        total_provider_fte,
        total_provider_shortage,

        ROUND(
            100.0
            * total_estimated_underserved_population
            / NULLIF(total_designation_population, 0),
            2
        ) AS pct_designated_population_underserved,

        ROUND(
            100000.0
            * total_provider_shortage
            / NULLIF(total_designation_population, 0),
            2
        ) AS provider_shortage_per_100k

    FROM vw_hpsa_state_community_support_states_only

    WHERE total_estimated_underserved_population IS NOT NULL
      AND total_provider_shortage IS NOT NULL
),

ranked AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY avg_hpsa_score DESC
        ) AS hpsa_severity_rank,

        RANK() OVER (
            ORDER BY pct_designated_population_underserved DESC
        ) AS underserved_share_rank,

        RANK() OVER (
            ORDER BY provider_shortage_per_100k DESC
        ) AS provider_shortage_rate_rank

    FROM rates
)

SELECT
    *,

    ROUND(
        (
            hpsa_severity_rank
            + underserved_share_rank
            + provider_shortage_rate_rank
        ) / 3.0,
        2
    ) AS avg_community_support_rank

FROM ranked;

-- ---------------------------------------------------------
-- PART 3F QA:
-- Rank states/DC by overall community-support vulnerability.
-- Vermont is intentionally excluded because of missing
-- composite measures.
-- ---------------------------------------------------------

SELECT *
FROM vw_hpsa_state_community_support_final

ORDER BY
    avg_community_support_rank ASC,
    hpsa_severity_rank ASC;

    -- ---------------------------------------------------------
-- PART 3F REPORTING GAP:
-- Preserve jurisdictions that cannot be included in the
-- final community-support composite.
-- ---------------------------------------------------------

SELECT
    state_abbreviation,
    state_fips_code,
    hpsa_designation_count,
    avg_hpsa_score,
    total_designation_population,
    total_estimated_underserved_population,
    total_provider_shortage

FROM vw_hpsa_state_community_support_states_only

WHERE total_estimated_underserved_population IS NULL
   OR total_provider_shortage IS NULL;