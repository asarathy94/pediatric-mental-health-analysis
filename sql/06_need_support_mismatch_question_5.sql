-- =========================================================
-- QUESTION 5
-- Which states have high pediatric mental-health burden
-- AND comparatively low school and community support?
--
-- This combines:
--   Q1 = pediatric mental-health burden
--   Q4 = combined school/community support capacity
--
-- Goal:
-- Identify states where high need and thin support overlap.
-- =========================================================


-- ---------------------------------------------------------
-- PART 1:
-- Join Q1 mental-health burden to Q4 combined support.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_state_need_support_mismatch AS

SELECT
    q1.state_name,
    q1.state_abbreviation,

    -- Mental-health burden
    q1.pct_current_anxiety,
    q1.pct_current_depression,
    q1.pct_current_adhd,
    q1.pct_any_current_condition,
    q1.pct_two_or_more_conditions,
    q1.pct_all_three_conditions,

    -- School support
    q4.avg_school_support_rank,

    -- Community support
    q4.avg_community_support_rank,

    -- Combined support
    q4.avg_combined_support_rank

FROM vw_nsch_state_question_1_final AS q1

LEFT JOIN vw_state_combined_support_ranking AS q4
    ON q1.state_abbreviation = q4.state_abbreviation;

    -- ---------------------------------------------------------
-- PART 1 QA:
-- Check joined burden + support data.
-- ---------------------------------------------------------

SELECT *
FROM vw_state_need_support_mismatch
ORDER BY state_abbreviation;

-- ---------------------------------------------------------
-- PART 2:
-- Rank states by pediatric mental-health burden.
--
-- Primary need measure:
-- percent of children with 2+ current conditions.
--
-- Higher prevalence = higher need.
-- Rank 1 = highest burden.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_state_need_support_mismatch_ranked AS

WITH ranked AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY pct_two_or_more_conditions DESC
        ) AS mental_health_burden_rank

    FROM vw_state_need_support_mismatch

    WHERE pct_two_or_more_conditions IS NOT NULL
      AND avg_combined_support_rank IS NOT NULL
)

SELECT
    *,

    ROUND(
        (
            mental_health_burden_rank
            + avg_combined_support_rank
        ) / 2.0,
        2
    ) AS avg_need_support_mismatch_rank

FROM ranked;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Which states show the strongest combination of
-- high pediatric mental-health burden + weak support?
--
-- Lower score = stronger need-support mismatch.
-- ---------------------------------------------------------

SELECT *
FROM vw_state_need_support_mismatch_ranked
ORDER BY avg_need_support_mismatch_rank ASC;

-- ---------------------------------------------------------
-- PART 3:
-- Sensitivity check for the need-support mismatch ranking.
--
-- The original Question 5 ranking uses:
--   pct_two_or_more_conditions
--
-- This second version tests whether the same states still
-- emerge when pediatric mental-health burden is defined more
-- broadly as:
--   pct_any_current_condition
--
-- If similar states rank highly under both definitions,
-- the need-support mismatch finding is more robust and is
-- less dependent on a single definition of mental-health need.
--
-- Higher mental-health prevalence = higher need.
-- Lower combined-support rank = weaker support.
-- Lower final mismatch score = stronger need-support mismatch.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_state_need_support_mismatch_any_condition AS

WITH ranked AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY pct_any_current_condition DESC
        ) AS any_condition_burden_rank

    FROM vw_state_need_support_mismatch

    WHERE pct_any_current_condition IS NOT NULL
      AND avg_combined_support_rank IS NOT NULL
)

SELECT
    *,

    ROUND(
        (
            any_condition_burden_rank
            + avg_combined_support_rank
        ) / 2.0,
        2
    ) AS avg_any_condition_mismatch_rank

FROM ranked;

-- ---------------------------------------------------------
-- PART 3 QA:
-- Which states show the strongest combination of:
--   - high prevalence of ANY current anxiety, depression,
--     or ADHD
--   - comparatively weak combined school/community support
--
-- Lower score = stronger need-support mismatch.
-- ---------------------------------------------------------

SELECT *
FROM vw_state_need_support_mismatch_any_condition

ORDER BY
    avg_any_condition_mismatch_rank ASC,
    any_condition_burden_rank ASC;

    -- ---------------------------------------------------------
-- PART 3B QA:
-- Compare the two Question 5 burden definitions:
--
--   1) 2+ current conditions
--   2) any current condition
--
-- This helps identify states that remain high-priority
-- regardless of how pediatric mental-health burden is defined.
-- ---------------------------------------------------------

SELECT
    a.state_name,
    a.state_abbreviation,

    a.mental_health_burden_rank
        AS two_or_more_burden_rank,

    a.avg_need_support_mismatch_rank
        AS two_or_more_mismatch_rank,

    b.any_condition_burden_rank,

    b.avg_any_condition_mismatch_rank

FROM vw_state_need_support_mismatch_ranked AS a

INNER JOIN vw_state_need_support_mismatch_any_condition AS b
    ON a.state_abbreviation = b.state_abbreviation

ORDER BY
    (
        a.avg_need_support_mismatch_rank
        + b.avg_any_condition_mismatch_rank
    ) / 2.0 ASC;

    -- ---------------------------------------------------------
-- PART 4:
-- Consensus / robustness ranking for Question 5.
--
-- Question 5 asks:
-- Which states have high pediatric mental-health burden
-- AND comparatively weak school/community support?
--
-- We have tested this using two valid definitions of need:
--   1) percent with 2+ current conditions
--   2) percent with any current condition
--
-- This consensus step combines the two mismatch rankings
-- to identify states that remain high-priority across BOTH
-- burden definitions.
--
-- Lower consensus score = more persistent need-support mismatch.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_state_need_support_mismatch_consensus AS

SELECT
    a.state_name,
    a.state_abbreviation,

    a.mental_health_burden_rank
        AS two_or_more_burden_rank,

    a.avg_need_support_mismatch_rank
        AS two_or_more_mismatch_rank,

    b.any_condition_burden_rank,

    b.avg_any_condition_mismatch_rank,

    ROUND(
        (
            a.avg_need_support_mismatch_rank
            + b.avg_any_condition_mismatch_rank
        ) / 2.0,
        2
    ) AS consensus_mismatch_rank

FROM vw_state_need_support_mismatch_ranked AS a

INNER JOIN vw_state_need_support_mismatch_any_condition AS b
    ON a.state_abbreviation = b.state_abbreviation;

    -- ---------------------------------------------------------
-- PART 4 QA:
-- Which states show the most persistent need-support
-- mismatch across BOTH definitions of pediatric need?
--
-- Lower consensus score = stronger recurring mismatch.
-- ---------------------------------------------------------

SELECT *
FROM vw_state_need_support_mismatch_consensus
ORDER BY consensus_mismatch_rank ASC;

-- ---------------------------------------------------------
-- PART 4B QA:
-- Show the top 10 most persistent need-support mismatch states.
-- ---------------------------------------------------------

SELECT *
FROM vw_state_need_support_mismatch_consensus
ORDER BY consensus_mismatch_rank ASC
LIMIT 10;