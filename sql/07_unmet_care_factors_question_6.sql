-- =========================================================
-- QUESTION 6
-- Among children ages 6–17 with current anxiety, depression,
-- or ADHD, which child, family, insurance, school, and
-- neighborhood factors are most strongly associated with
-- unmet mental-health care?
--
-- SUB-QUESTION 6A:
-- Is greater ACE exposure associated with higher unmet
-- mental-health care, and how does unmet care vary across
-- ACE burden?
--
-- IMPORTANT:
-- This is a child-level NSCH analysis.
-- Associations are observational and should not be
-- interpreted as causal effects.
-- NSCH final sampling weights must be preserved.
-- =========================================================

-- ---------------------------------------------------------
-- PART 1:
-- Inspect the exact variables available in the cleaned
-- NSCH child-level table before defining factor groups.
-- ---------------------------------------------------------

DESCRIBE nsch_children;
-- ---------------------------------------------------------
-- PART 1 QA:
-- Find likely fields for unmet care, mental-health need,
-- ACEs, insurance, family, school, neighborhood,
-- demographics, and healthcare access.
-- ---------------------------------------------------------

SELECT
    column_name

FROM information_schema.columns

WHERE table_name = 'nsch_children'

  AND (
       LOWER(column_name) LIKE '%mental%'
    OR LOWER(column_name) LIKE '%care%'
    OR LOWER(column_name) LIKE '%need%'
    OR LOWER(column_name) LIKE '%ace%'
    OR LOWER(column_name) LIKE '%insur%'
    OR LOWER(column_name) LIKE '%pover%'
    OR LOWER(column_name) LIKE '%income%'
    OR LOWER(column_name) LIKE '%family%'
    OR LOWER(column_name) LIKE '%school%'
    OR LOWER(column_name) LIKE '%neigh%'
    OR LOWER(column_name) LIKE '%race%'
    OR LOWER(column_name) LIKE '%eth%'
    OR LOWER(column_name) LIKE '%sex%'
    OR LOWER(column_name) LIKE '%age%'
  )

ORDER BY column_name;

-- ---------------------------------------------------------
-- PART 1B:
-- Verify the ACE variables retained in the final NSCH table.
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS total_children,

    COUNT(ACEct_24) AS ace_count_valid_n,
    COUNT(ACE2more_24) AS ace_two_plus_valid_n

FROM nsch_children;

-- ---------------------------------------------------------
-- PART 1B QA:
-- Inspect the actual coding used by the retained ACE fields
-- before analyzing them.
-- ---------------------------------------------------------

SELECT
    'ACEct_24' AS variable,
    CAST(ACEct_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n

FROM nsch_children
GROUP BY ACEct_24

UNION ALL

SELECT
    'ACE2more_24' AS variable,
    CAST(ACE2more_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n

FROM nsch_children
GROUP BY ACE2more_24

ORDER BY variable, response_code;

-- ---------------------------------------------------------
-- PART 2:
-- Define the Question 6 analysis population.
--
-- Population:
-- Children ages 6–17 with CURRENT anxiety, depression,
-- or ADHD.
--
-- Outcome:
-- Unmet mental-health care among children with mental-health
-- need.
--
-- IMPORTANT:
-- We verify MentHCare_24 and mhneeds_24 coding before
-- constructing the final unmet-care flag.
-- ---------------------------------------------------------


-- Check mental-health need coding
SELECT
    'mhneeds_24' AS variable,
    CAST(mhneeds_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n

FROM nsch_children
GROUP BY mhneeds_24

UNION ALL

-- Check mental-health care coding
SELECT
    'MentHCare_24' AS variable,
    CAST(MentHCare_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n

FROM nsch_children
GROUP BY MentHCare_24

ORDER BY variable, response_code;

-- ---------------------------------------------------------
-- PART 2B:
-- Inspect coding for the main factor families that will be
-- compared with unmet mental-health care.
-- ---------------------------------------------------------

SELECT
    'insurance_24' AS variable,
    CAST(insurance_24 AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n
FROM nsch_children
GROUP BY insurance_24

UNION ALL

SELECT
    'FAMILY_R',
    CAST(FAMILY_R AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY FAMILY_R

UNION ALL

SELECT
    'SchlEngage_24',
    CAST(SchlEngage_24 AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY SchlEngage_24

UNION ALL

SELECT
    'SchoolReadiness_24',
    CAST(SchoolReadiness_24 AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY SchoolReadiness_24

UNION ALL

SELECT
    'cares_24',
    CAST(cares_24 AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY cares_24

UNION ALL

SELECT
    'neighborhood_safety',
    CAST(neighborhood_safety AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY neighborhood_safety

UNION ALL

SELECT
    'neighborhood_support',
    CAST(neighborhood_support AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY neighborhood_support

ORDER BY variable, response_code;

-- ---------------------------------------------------------
-- PART 2C:
-- Inspect demographic coding for later subgroup comparisons.
-- ---------------------------------------------------------

SELECT
    'child_race' AS variable,
    CAST(child_race AS VARCHAR) AS response_code,
    COUNT(*) AS sample_n
FROM nsch_children
GROUP BY child_race

UNION ALL

SELECT
    'child_hispanic_ethnicity',
    CAST(child_hispanic_ethnicity AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY child_hispanic_ethnicity

UNION ALL

SELECT
    'child_sex',
    CAST(child_sex AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY child_sex

UNION ALL

SELECT
    'child_age_years',
    CAST(child_age_years AS VARCHAR),
    COUNT(*)
FROM nsch_children
GROUP BY child_age_years

ORDER BY variable, response_code;

-- ---------------------------------------------------------
-- PART 3:
-- Create the final Question 6 child-level analysis cohort.
--
-- QUESTION:
-- Among children ages 6–17 with CURRENT anxiety,
-- depression, or ADHD, which child, family, insurance,
-- school, and neighborhood factors are most strongly
-- associated with unmet mental-health care?
--
-- CONDITION CODING:
--   1 = does not have condition
--   2 = previously diagnosed, not current
--   3 = currently has condition
--   99 = missing
--
-- UNMET-CARE CODING:
--   MentHCare_24 = 1 -> received needed care -> unmet = 0
--   MentHCare_24 = 2 -> needed care but did not receive it
--                      -> unmet = 1
--
-- MentHCare codes 3 and 99 are not part of the
-- needed-care comparison.
--
-- NSCH final sampling weights are preserved.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nsch_q6_unmet_care_cohort AS

SELECT
    *,

    CASE
        WHEN MentHCare_24 = 1 THEN 0
        WHEN MentHCare_24 = 2 THEN 1
    END AS unmet_mental_health_care

FROM nsch_children

WHERE
    (
           anxiety_24 = 3
        OR depress_24 = 3
        OR ADHD_24 = 3
    )

    AND MentHCare_24 IN (1, 2)

    AND final_sampling_weight IS NOT NULL;

    -- ---------------------------------------------------------
-- PART 3 QA:
-- Confirm the size and weighted unmet-care prevalence
-- of the exact Question 6 population.
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS analysis_sample_n,

    SUM(
        CASE
            WHEN unmet_mental_health_care = 1
            THEN 1 ELSE 0
        END
    ) AS unmet_care_sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort;

-- ---------------------------------------------------------
-- PART 4:
-- Broad factor screening.
--
-- Compare weighted unmet-care prevalence across categories
-- of child, family, insurance, school, and neighborhood
-- factors.
--
-- This is descriptive association screening.
-- It does NOT establish causation.
--
-- Code 99 and other known special/missing values are
-- excluded from each factor-specific comparison.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nsch_q6_factor_rates AS


-- INSURANCE
SELECT
    'Insurance' AS factor_family,
    'insurance_24' AS factor,
    CAST(insurance_24 AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
WHERE insurance_24 <> 99
GROUP BY insurance_24


UNION ALL


-- FAMILY STRUCTURE
SELECT
    'Family' AS factor_family,
    'FAMILY_R' AS factor,
    CAST(FAMILY_R AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
WHERE FAMILY_R <> 99
GROUP BY FAMILY_R


UNION ALL


-- SCHOOL ENGAGEMENT
SELECT
    'School' AS factor_family,
    'SchlEngage_24' AS factor,
    CAST(SchlEngage_24 AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
WHERE SchlEngage_24 <> 99
GROUP BY SchlEngage_24


UNION ALL


-- CARES ABOUT DOING WELL IN SCHOOL
SELECT
    'School' AS factor_family,
    'cares_24' AS factor,
    CAST(cares_24 AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
WHERE cares_24 <> 99
GROUP BY cares_24


UNION ALL


-- NEIGHBORHOOD SAFETY
SELECT
    'Neighborhood' AS factor_family,
    'neighborhood_safety' AS factor,
    CAST(neighborhood_safety AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
WHERE neighborhood_safety <> 99
GROUP BY neighborhood_safety


UNION ALL


-- NEIGHBORHOOD SUPPORT
SELECT
    'Neighborhood' AS factor_family,
    'neighborhood_support' AS factor,
    CAST(neighborhood_support AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
WHERE neighborhood_support <> 99
GROUP BY neighborhood_support


UNION ALL


-- SEX
SELECT
    'Child demographic' AS factor_family,
    'child_sex' AS factor,
    CAST(child_sex AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
GROUP BY child_sex


UNION ALL


-- RACE
SELECT
    'Child demographic' AS factor_family,
    'child_race' AS factor,
    CAST(child_race AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
GROUP BY child_race


UNION ALL


-- HISPANIC ETHNICITY
SELECT
    'Child demographic' AS factor_family,
    'child_hispanic_ethnicity' AS factor,
    CAST(child_hispanic_ethnicity AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort
GROUP BY child_hispanic_ethnicity;

-- ---------------------------------------------------------
-- PART 4 QA:
-- Inspect weighted unmet-care prevalence by factor/category.
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_q6_factor_rates
ORDER BY
    factor_family,
    factor,
    weighted_unmet_care_pct DESC;

    -- ---------------------------------------------------------
-- PART 4B:
-- Summarize the descriptive strength of each broad factor.
--
-- For each factor, calculate:
--   - lowest weighted unmet-care rate
--   - highest weighted unmet-care rate
--   - percentage-point gap between them
--   - smallest category sample size
--
-- Larger gaps indicate stronger descriptive association.
--
-- IMPORTANT:
-- This is still descriptive screening, not a causal effect
-- and not an adjusted statistical model.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nsch_q6_factor_summary AS

SELECT
    factor_family,
    factor,

    MIN(weighted_unmet_care_pct)
        AS min_weighted_unmet_care_pct,

    MAX(weighted_unmet_care_pct)
        AS max_weighted_unmet_care_pct,

    ROUND(
        MAX(weighted_unmet_care_pct)
        - MIN(weighted_unmet_care_pct),
        2
    ) AS unmet_care_pct_point_gap,

    MIN(sample_n)
        AS smallest_category_n,

    SUM(sample_n)
        AS factor_sample_n

FROM vw_nsch_q6_factor_rates

GROUP BY
    factor_family,
    factor;

-- ---------------------------------------------------------
-- PART 4B QA:
-- Rank broad factors by the size of the weighted unmet-care
-- gap across their categories.
--
-- Factors with very small category sample sizes should be
-- interpreted cautiously.
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_q6_factor_summary

ORDER BY
    unmet_care_pct_point_gap DESC;

    -- ---------------------------------------------------------
-- PART 4C QA:
-- More conservative factor ranking.
--
-- Only show factors where every displayed category has at
-- least 100 sampled children in the Question 6 cohort.
-- This reduces the influence of unstable tiny cells.
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_q6_factor_summary

WHERE smallest_category_n >= 100

ORDER BY
    unmet_care_pct_point_gap DESC;

    -- ---------------------------------------------------------
-- PART 5 / QUESTION 6A:
-- Is greater ACE exposure associated with higher unmet
-- mental-health care among children ages 6–17 with current
-- anxiety, depression, or ADHD who needed care?
--
-- ACEct_24:
--   0–9 = number of reported ACEs
--   99  = missing / special response
--
-- ACE2more_24:
--   1 = 0 ACEs
--   2 = 1 ACE
--   3 = 2+ ACEs
--   99 = missing / special response
--
-- NSCH final sampling weights are used.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nsch_q6_ace_rates AS

SELECT
    'ACE count' AS ace_measure,
    CAST(ACEct_24 AS VARCHAR) AS ace_category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEct_24 <> 99

GROUP BY ACEct_24


UNION ALL


SELECT
    'ACE grouped' AS ace_measure,
    CAST(ACE2more_24 AS VARCHAR) AS ace_category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACE2more_24 <> 99

GROUP BY ACE2more_24;

-- ---------------------------------------------------------
-- PART 5 QA:
-- Inspect unmet-care rates across increasing ACE exposure.
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_q6_ace_rates
ORDER BY
    ace_measure,
    CAST(ace_category AS INTEGER);

    -- ---------------------------------------------------------
-- PART 5B QA:
-- Compare 0 ACEs, 1 ACE, and 2+ ACEs directly.
-- ---------------------------------------------------------

SELECT
    CASE ACE2more_24
        WHEN 1 THEN '0 ACEs'
        WHEN 2 THEN '1 ACE'
        WHEN 3 THEN '2+ ACEs'
    END AS ace_group,

    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACE2more_24 IN (1, 2, 3)

GROUP BY ACE2more_24

ORDER BY ACE2more_24;

-- ---------------------------------------------------------
-- PART 5C:
-- Test whether the clearest ACE difference is between
-- NO reported ACE exposure and ANY reported ACE exposure.
--
-- This complements the 0 / 1 / 2+ ACE comparison.
-- ---------------------------------------------------------

SELECT
    CASE
        WHEN ACEct_24 = 0 THEN 'No ACEs'
        WHEN ACEct_24 BETWEEN 1 AND 10 THEN 'Any ACE'
    END AS ace_exposure_group,

    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEct_24 <> 99

GROUP BY
    CASE
        WHEN ACEct_24 = 0 THEN 'No ACEs'
        WHEN ACEct_24 BETWEEN 1 AND 10 THEN 'Any ACE'
    END

ORDER BY weighted_unmet_care_pct;

-- ---------------------------------------------------------
-- PART 6:
-- Which individual ACEs are most strongly associated with
-- unmet mental-health care?
--
-- Each ACE is evaluated separately within the Question 6
-- cohort of children ages 6–17 with current anxiety,
-- depression, or ADHD who needed mental-health care.
--
-- For each ACE:
--   - compare weighted unmet-care prevalence across response
--     categories
--   - preserve sample size
--   - exclude special/missing code 99
--
-- IMPORTANT:
-- These are descriptive associations, not causal effects.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nsch_q6_individual_ace_rates AS


-- DIVORCE / SEPARATION
SELECT
    'ACEdivorce_24' AS ace_factor,
    CAST(ACEdivorce_24 AS VARCHAR) AS category,
    COUNT(*) AS sample_n,

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    ) AS weighted_unmet_care_pct

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEdivorce_24 <> 99
GROUP BY ACEdivorce_24


UNION ALL


-- DOMESTIC VIOLENCE
SELECT
    'ACEdomviol_24',
    CAST(ACEdomviol_24 AS VARCHAR),
    COUNT(*),

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEdomviol_24 <> 99
GROUP BY ACEdomviol_24


UNION ALL


-- HOUSEHOLD SUBSTANCE USE
SELECT
    'ACEdrug_24',
    CAST(ACEdrug_24 AS VARCHAR),
    COUNT(*),

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEdrug_24 <> 99
GROUP BY ACEdrug_24


UNION ALL


-- HOUSEHOLD INCARCERATION
SELECT
    'ACEjail_24',
    CAST(ACEjail_24 AS VARCHAR),
    COUNT(*),

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEjail_24 <> 99
GROUP BY ACEjail_24


UNION ALL


-- HOUSEHOLD MENTAL ILLNESS
SELECT
    'ACEmhealth_24',
    CAST(ACEmhealth_24 AS VARCHAR),
    COUNT(*),

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEmhealth_24 <> 99
GROUP BY ACEmhealth_24


UNION ALL


-- NEIGHBORHOOD VIOLENCE
SELECT
    'ACEneighviol_24',
    CAST(ACEneighviol_24 AS VARCHAR),
    COUNT(*),

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEneighviol_24 <> 99
GROUP BY ACEneighviol_24


UNION ALL


-- DISCRIMINATION
SELECT
    'ACEdiscrim_24',
    CAST(ACEdiscrim_24 AS VARCHAR),
    COUNT(*),

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEdiscrim_24 <> 99
GROUP BY ACEdiscrim_24


UNION ALL


-- DEATH OF PARENT / GUARDIAN
SELECT
    'ACEdeath_24',
    CAST(ACEdeath_24 AS VARCHAR),
    COUNT(*),

    ROUND(
        100.0
        * SUM(
            CASE
                WHEN unmet_mental_health_care = 1
                THEN final_sampling_weight
                ELSE 0
            END
        )
        / SUM(final_sampling_weight),
        2
    )

FROM vw_nsch_q6_unmet_care_cohort

WHERE ACEdeath_24 <> 99
GROUP BY ACEdeath_24;

-- ---------------------------------------------------------
-- PART 6 QA:
-- Inspect weighted unmet-care prevalence for each
-- individual ACE response category.
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_q6_individual_ace_rates

ORDER BY
    ace_factor,
    weighted_unmet_care_pct DESC;

    -- ---------------------------------------------------------
-- PART 6B:
-- Rank individual ACEs by the size of the weighted
-- unmet-care gap across their response categories.
--
-- Larger percentage-point gaps indicate stronger
-- descriptive association with unmet care.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nsch_q6_individual_ace_summary AS

SELECT
    ace_factor,

    MIN(weighted_unmet_care_pct)
        AS min_weighted_unmet_care_pct,

    MAX(weighted_unmet_care_pct)
        AS max_weighted_unmet_care_pct,

    ROUND(
        MAX(weighted_unmet_care_pct)
        - MIN(weighted_unmet_care_pct),
        2
    ) AS unmet_care_pct_point_gap,

    MIN(sample_n)
        AS smallest_category_n,

    SUM(sample_n)
        AS factor_sample_n

FROM vw_nsch_q6_individual_ace_rates

GROUP BY ace_factor;

-- ---------------------------------------------------------
-- PART 6B QA:
-- Which individual ACEs show the largest descriptive
-- differences in unmet mental-health care?
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_q6_individual_ace_summary

ORDER BY
    unmet_care_pct_point_gap DESC;

    -- ---------------------------------------------------------
-- PART 6C QA:
-- Conservative individual-ACE ranking.
--
-- Only include ACE factors where every displayed category
-- has at least 100 sampled children.
-- ---------------------------------------------------------

SELECT *
FROM vw_nsch_q6_individual_ace_summary

WHERE smallest_category_n >= 100

ORDER BY
    unmet_care_pct_point_gap DESC;

    -- =========================================================
-- QUESTION 6 SUMMARY
-- =========================================================
--
-- MAIN QUESTION:
-- Among children ages 6–17 with current anxiety, depression,
-- or ADHD who needed mental-health care, which child, family,
-- insurance, school, and neighborhood factors are most
-- strongly associated with unmet mental-health care?
--
-- ANALYSIS COHORT:
--   n = 5,911
--   unmet-care sample n = 717
--   weighted unmet-care prevalence = 13.71%
--
-- BROAD FACTOR FINDINGS:
-- After excluding factors with very small category sample
-- sizes, the largest descriptive gaps in weighted unmet-care
-- prevalence were:
--
--   1. Neighborhood safety
--      17.71 percentage-point gap
--
--   2. Family context (FAMILY_R)
--      13.36 percentage-point gap
--
--   3. School caring / engagement (cares_24)
--      11.02 percentage-point gap
--
--   4. Neighborhood support
--      7.82 percentage-point gap
--
--   5. School engagement (SchlEngage_24)
--      7.47 percentage-point gap
--
--   6. Insurance status
--      6.07 percentage-point gap
--
-- Demographic differences were smaller in this descriptive
-- screen. Race was not treated as a stable ranked finding
-- because one subgroup contained only 11 sampled children.
--
--
-- SUB-QUESTION 6A:
-- Is ACE exposure associated with higher unmet
-- mental-health care?
--
-- ACE BURDEN FINDINGS:
--
--   0 ACEs:
--      8.61% weighted unmet care
--
--   1 ACE:
--      15.35% weighted unmet care
--
--   2+ ACEs:
--      16.85% weighted unmet care
--
--   No ACEs vs Any ACE:
--      8.61% vs 16.32%
--      7.71 percentage-point difference
--
-- The largest contrast appears between no reported ACE
-- exposure and any ACE exposure, rather than a perfectly
-- linear increase with additional ACEs.
--
--
-- INDIVIDUAL ACE FINDINGS:
-- Largest descriptive unmet-care gaps:
--
--   1. Parental divorce / separation
--      18.31% vs 10.72%
--      7.59 percentage-point gap
--
--   2. Household incarceration
--      19.51% vs 12.75%
--      6.76 percentage-point gap
--
--   3. Parent / guardian death
--      17.73% vs 13.39%
--      4.34 percentage-point gap
--
--   4. Domestic violence
--      16.62% vs 13.15%
--      3.47 percentage-point gap
--
--   5. Discrimination
--      16.73% vs 13.35%
--      3.38 percentage-point gap
--
-- INTERPRETATION:
-- Unmet mental-health care is not associated with one single
-- factor. The strongest descriptive patterns span the child's
-- surrounding service and social environment, particularly
-- neighborhood safety, family context, school experience,
-- neighborhood support, insurance, and ACE exposure.
--
-- Any ACE exposure is associated with substantially higher
-- unmet-care prevalence, with parental divorce/separation
-- and household incarceration showing the largest individual
-- ACE differences in this analysis.
--
-- IMPORTANT LIMITATION:
-- These are weighted descriptive associations.
-- They do not establish causation and are not adjusted for
-- overlap or confounding among factors.
-- =========================================================