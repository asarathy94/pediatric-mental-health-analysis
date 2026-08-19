-- =========================================================
-- QUESTION 1
-- Among children ages 6–17, in which states are current
-- anxiety, depression, or ADHD most concentrated?
-- =========================================================

-- NSCH coding for anxiety_24, depress_24, and ADHD_24:
-- 1 = does not have condition
-- 2 = previously diagnosed, not current
-- 3 = currently has condition
-- 99 = missing
-- ---------------------------------------------------------
-- STEP 1: Verify raw condition coding and counts
-- ---------------------------------------------------------

SELECT
    'ADHD_24' AS variable,
    CAST(ADHD_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n
FROM nsch_children
GROUP BY ADHD_24

UNION ALL

SELECT
    'anxiety_24' AS variable,
    CAST(anxiety_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n
FROM nsch_children
GROUP BY anxiety_24

UNION ALL

SELECT
    'depress_24' AS variable,
    CAST(depress_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n
FROM nsch_children
GROUP BY depress_24

ORDER BY variable, response_code;
-- ---------------------------------------------------------
-- STEP 2: Create clean current-condition flags
-- ---------------------------------------------------------
-- NSCH coding:
-- 1 = does not have condition
-- 2 = previously diagnosed, not current
-- 3 = currently has condition
-- 99 = missing
CREATE OR REPLACE VIEW vw_nsch_current_conditions AS

SELECT
    n.state_fips_code,
    d.state_name,
    d.state_abbreviation,
    n.final_sampling_weight,

    CASE
        WHEN n.anxiety_24 = 3 THEN 1
        WHEN n.anxiety_24 IN (1, 2) THEN 0
        ELSE NULL
    END AS current_anxiety,

    CASE
        WHEN n.depress_24 = 3 THEN 1
        WHEN n.depress_24 IN (1, 2) THEN 0
        ELSE NULL
    END AS current_depression,

    CASE
        WHEN n.ADHD_24 = 3 THEN 1
        WHEN n.ADHD_24 IN (1, 2) THEN 0
        ELSE NULL
    END AS current_adhd

FROM nsch_children AS n

LEFT JOIN dim_state AS d
    ON n.state_fips_code = d.state_fips;
    SELECT *
FROM vw_nsch_current_conditions
LIMIT 20;

-- ---------------------------------------------------------
-- STEP 3: Calculate weighted state-level condition prevalence
-- ---------------------------------------------------------
-- Each condition uses its own valid-response denominator.
-- Missing code 99 is excluded only from that condition.
-- NSCH final sampling weights are used.

CREATE OR REPLACE VIEW vw_nsch_state_condition_concentration AS

SELECT
    state_fips_code,
    state_name,
    state_abbreviation,

    COUNT(*) AS total_sample_n,

    -- Anxiety
    COUNT(current_anxiety) AS anxiety_valid_n,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN current_anxiety = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        /
        SUM(
            CASE
                WHEN current_anxiety IS NOT NULL
                THEN final_sampling_weight
                ELSE 0
            END
        ),
        2
    ) AS pct_current_anxiety,

    -- Depression
    COUNT(current_depression) AS depression_valid_n,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN current_depression = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        /
        SUM(
            CASE
                WHEN current_depression IS NOT NULL
                THEN final_sampling_weight
                ELSE 0
            END
        ),
        2
    ) AS pct_current_depression,

    -- ADHD
    COUNT(current_adhd) AS adhd_valid_n,
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN current_adhd = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        /
        SUM(
            CASE
                WHEN current_adhd IS NOT NULL
                THEN final_sampling_weight
                ELSE 0
            END
        ),
        2
    ) AS pct_current_adhd

FROM vw_nsch_current_conditions

GROUP BY
    state_fips_code,
    state_name,
    state_abbreviation;

    SELECT *
FROM vw_nsch_state_condition_concentration
ORDER BY pct_current_anxiety DESC;

-- ---------------------------------------------------------
-- STEP 4: Calculate weighted condition overlap
-- ---------------------------------------------------------
-- This answers:
-- Among children ages 6–17, what percentage in each state
-- currently have:
--   1) any anxiety, depression, or ADHD
--   2) two or more of the three conditions
--   3) all three conditions
--
-- All three condition fields must be valid for a child
-- to be included in these overlap calculations.
-- NSCH final sampling weights are used.

CREATE OR REPLACE VIEW vw_nsch_state_condition_overlap AS

WITH complete_cases AS (

    SELECT
        state_fips_code,
        state_name,
        state_abbreviation,
        final_sampling_weight,
        current_anxiety,
        current_depression,
        current_adhd

    FROM vw_nsch_current_conditions

    WHERE current_anxiety IS NOT NULL
      AND current_depression IS NOT NULL
      AND current_adhd IS NOT NULL
)

SELECT
    state_fips_code,
    state_name,
    state_abbreviation,

    COUNT(*) AS complete_case_n,

    -- Any one or more current conditions
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN current_anxiety = 1
                  OR current_depression = 1
                  OR current_adhd = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        /
        SUM(final_sampling_weight),
        2
    ) AS pct_any_current_condition,

    -- Two or more current conditions
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN current_anxiety
                   + current_depression
                   + current_adhd >= 2
                THEN final_sampling_weight
                ELSE 0
            END
        )
        /
        SUM(final_sampling_weight),
        2
    ) AS pct_two_or_more_conditions,

    -- All three current conditions
    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN current_anxiety
                   + current_depression
                   + current_adhd = 3
                THEN final_sampling_weight
                ELSE 0
            END
        )
        /
        SUM(final_sampling_weight),
        2
    ) AS pct_all_three_conditions

FROM complete_cases

GROUP BY
    state_fips_code,
    state_name,
    state_abbreviation;

    -- ---------------------------------------------------------
-- STEP 4 QA:
-- Rank states by overall condition overlap
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_state_condition_overlap
ORDER BY
    pct_any_current_condition DESC,
    pct_two_or_more_conditions DESC;


   -- ---------------------------------------------------------
-- STEP 5: Final combined state table for Question 1
-- ---------------------------------------------------------
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW vw_nsch_state_question_1_final AS

SELECT
    o.state_fips_code,
    c.state_name,
    c.state_abbreviation,

    c.total_sample_n,

    c.anxiety_valid_n,
    c.pct_current_anxiety,

    c.depression_valid_n,
    c.pct_current_depression,

    c.adhd_valid_n,
    c.pct_current_adhd,

    o.complete_case_n,
    o.pct_any_current_condition,
    o.pct_two_or_more_conditions,
    o.pct_all_three_conditions

FROM vw_nsch_state_condition_concentration AS c

LEFT JOIN vw_nsch_state_condition_overlap AS o
    ON c.state_abbreviation = o.state_abbreviation;

    -- ---------------------------------------------------------
-- STEP 5 QA:
-- Rank states by prevalence of any current condition
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_state_question_1_final
ORDER BY
    pct_any_current_condition DESC,
    pct_two_or_more_conditions DESC;