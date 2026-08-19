-- =========================================================
-- QUESTION 8
-- Across states, is stronger school- and community-based
-- mental-health support associated with lower pediatric
-- mental-health burden?
--
-- PURPOSE:
-- Test whether the support-capacity measures developed in
-- Questions 2–4 are associated with the pediatric
-- mental-health burden identified in Question 1.
--
-- IMPORTANT:
-- This analysis tests ASSOCIATION, not causation.
--
-- Higher students-per-staff ratios = THINNER school support.
-- Higher HPSA shortage measures = THINNER community support.
--
-- If stronger support is associated with lower burden,
-- we would generally expect POSITIVE relationships between
-- shortage measures and mental-health burden:
--
--   more students per provider
--   / greater provider shortage
--            +
--   higher mental-health prevalence
--
-- =========================================================


-- ---------------------------------------------------------
-- PART 1:
-- Create one state-level table containing:
--
--   1) pediatric mental-health burden from Question 1
--   2) school support capacity from Question 2
--   3) community support capacity from Question 3
--
-- This becomes the base table for Question 8.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q8_support_burden_analysis AS

SELECT
    q1.state_name,
    q1.state_abbreviation,
    q1.state_fips_code,

    -- -----------------------------------------------------
    -- Mental-health burden measures from Question 1
    -- -----------------------------------------------------

    q1.pct_current_anxiety,
    q1.pct_current_depression,
    q1.pct_current_adhd,

    q1.pct_any_current_condition,
    q1.pct_two_or_more_conditions,
    q1.pct_all_three_conditions,

    -- -----------------------------------------------------
    -- School support measures from Question 2
    --
    -- Higher ratios = thinner school support.
    -- -----------------------------------------------------

    school.total_students,
    school.total_school_psychologists,
    school.total_guidance_counselors,

    school.students_per_psychologist,
    school.students_per_guidance_counselor,

    school.avg_school_support_rank,

    -- -----------------------------------------------------
    -- Community support measures from Question 3
    --
    -- Higher values = greater community shortage.
    -- -----------------------------------------------------

    community.avg_hpsa_score,

    community.pct_designated_population_underserved,

    community.provider_shortage_per_100k,

    community.avg_community_support_rank

FROM vw_nsch_state_question_1_final AS q1

LEFT JOIN vw_nces_state_school_support_final AS school
    ON q1.state_abbreviation = school.state_abbreviation

LEFT JOIN vw_hpsa_state_community_support_final AS community
    ON q1.state_abbreviation = community.state_abbreviation;

    -- ---------------------------------------------------------
-- PART 1 QA:
-- Inspect the final state-level Question 8 analysis table.
-- ---------------------------------------------------------

SELECT *
FROM vw_q8_support_burden_analysis
ORDER BY state_name;

-- ---------------------------------------------------------
-- PART 1 QA:
-- Check how many states have usable data for each support
-- measure before calculating relationships.
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS total_states,

    COUNT(pct_any_current_condition)
        AS states_with_mental_health_data,

    COUNT(students_per_psychologist)
        AS states_with_psychologist_data,

    COUNT(students_per_guidance_counselor)
        AS states_with_guidance_counselor_data,

    COUNT(avg_hpsa_score)
        AS states_with_hpsa_severity_data,

    COUNT(pct_designated_population_underserved)
        AS states_with_underserved_share_data,

    COUNT(provider_shortage_per_100k)
        AS states_with_provider_shortage_data

FROM vw_q8_support_burden_analysis;

-- ---------------------------------------------------------
-- PART 2:
-- Test whether thinner school and community mental-health
-- support is associated with greater pediatric
-- mental-health burden across states.
--
-- CORRELATION INTERPRETATION:
--
--   r near +1 = strong positive relationship
--   r near -1 = strong negative relationship
--   r near  0 = little/no linear relationship
--
-- Because HIGHER values on the support measures below mean
-- THINNER / WORSE support:
--
-- A POSITIVE correlation would support the hypothesis that
-- thinner support tends to occur alongside greater
-- mental-health burden.
--
-- A NEGATIVE correlation would indicate the opposite
-- pattern.
--
-- These are state-level associations only and should NOT
-- be interpreted as causal effects.
-- ---------------------------------------------------------

SELECT

    -- =====================================================
    -- SCHOOL SUPPORT
    -- =====================================================

    CORR(
        students_per_psychologist,
        pct_any_current_condition
    ) AS corr_psychologist_ratio_any_condition,

    CORR(
        students_per_guidance_counselor,
        pct_any_current_condition
    ) AS corr_counselor_ratio_any_condition,


    -- =====================================================
    -- COMMUNITY SUPPORT
    -- =====================================================

    CORR(
        avg_hpsa_score,
        pct_any_current_condition
    ) AS corr_hpsa_score_any_condition,

    CORR(
        pct_designated_population_underserved,
        pct_any_current_condition
    ) AS corr_underserved_any_condition,

    CORR(
        provider_shortage_per_100k,
        pct_any_current_condition
    ) AS corr_provider_shortage_any_condition

FROM vw_q8_support_burden_analysis;

-- ---------------------------------------------------------
-- PART 2B:
-- Test whether thinner support is associated specifically
-- with greater COMPLEX mental-health burden.
--
-- pct_two_or_more_conditions represents children with at
-- least two current conditions among anxiety, depression,
-- and ADHD.
-- ---------------------------------------------------------

SELECT

    -- School support

    CORR(
        students_per_psychologist,
        pct_two_or_more_conditions
    ) AS corr_psychologist_ratio_two_plus,

    CORR(
        students_per_guidance_counselor,
        pct_two_or_more_conditions
    ) AS corr_counselor_ratio_two_plus,


    -- Community support

    CORR(
        avg_hpsa_score,
        pct_two_or_more_conditions
    ) AS corr_hpsa_score_two_plus,

    CORR(
        pct_designated_population_underserved,
        pct_two_or_more_conditions
    ) AS corr_underserved_two_plus,

    CORR(
        provider_shortage_per_100k,
        pct_two_or_more_conditions
    ) AS corr_provider_shortage_two_plus

FROM vw_q8_support_burden_analysis;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Identify jurisdictions excluded from the paired
-- support-burden analysis because support data are missing.
-- ---------------------------------------------------------

SELECT
    state_name,
    state_abbreviation,
    students_per_psychologist,
    students_per_guidance_counselor,
    avg_hpsa_score,
    pct_designated_population_underserved,
    provider_shortage_per_100k

FROM vw_q8_support_burden_analysis

WHERE students_per_psychologist IS NULL
   OR students_per_guidance_counselor IS NULL
   OR avg_hpsa_score IS NULL
   OR pct_designated_population_underserved IS NULL
   OR provider_shortage_per_100k IS NULL;

   -- ---------------------------------------------------------
-- PART 2 QA:
-- Count the number of paired state observations actually
-- used by each Question 8 relationship.
--
-- Vermont lacks community/HPSA measures.
-- Tennessee lacks school-support measures.
-- ---------------------------------------------------------

SELECT

    COUNT(
        CASE
            WHEN students_per_psychologist IS NOT NULL
             AND pct_any_current_condition IS NOT NULL
            THEN 1
        END
    ) AS n_psychologist_any_condition,

    COUNT(
        CASE
            WHEN students_per_guidance_counselor IS NOT NULL
             AND pct_any_current_condition IS NOT NULL
            THEN 1
        END
    ) AS n_counselor_any_condition,

    COUNT(
        CASE
            WHEN avg_hpsa_score IS NOT NULL
             AND pct_any_current_condition IS NOT NULL
            THEN 1
        END
    ) AS n_hpsa_any_condition,

    COUNT(
        CASE
            WHEN pct_designated_population_underserved IS NOT NULL
             AND pct_any_current_condition IS NOT NULL
            THEN 1
        END
    ) AS n_underserved_any_condition,

    COUNT(
        CASE
            WHEN provider_shortage_per_100k IS NOT NULL
             AND pct_any_current_condition IS NOT NULL
            THEN 1
        END
    ) AS n_shortage_any_condition

FROM vw_q8_support_burden_analysis;

-- ---------------------------------------------------------
-- PART 3:
-- Test whether COMMUNITY mental-health provider shortage
-- is associated differently with anxiety, depression,
-- and ADHD prevalence across states.
--
-- Higher values on these HPSA measures generally indicate
-- thinner community mental-health provider capacity.
-- ---------------------------------------------------------

SELECT

    -- =====================================================
    -- ANXIETY
    -- =====================================================

    CORR(
        avg_hpsa_score,
        pct_current_anxiety
    ) AS corr_hpsa_anxiety,

    CORR(
        pct_designated_population_underserved,
        pct_current_anxiety
    ) AS corr_underserved_anxiety,

    CORR(
        provider_shortage_per_100k,
        pct_current_anxiety
    ) AS corr_provider_shortage_anxiety,


    -- =====================================================
    -- DEPRESSION
    -- =====================================================

    CORR(
        avg_hpsa_score,
        pct_current_depression
    ) AS corr_hpsa_depression,

    CORR(
        pct_designated_population_underserved,
        pct_current_depression
    ) AS corr_underserved_depression,

    CORR(
        provider_shortage_per_100k,
        pct_current_depression
    ) AS corr_provider_shortage_depression,


    -- =====================================================
    -- ADHD
    -- =====================================================

    CORR(
        avg_hpsa_score,
        pct_current_adhd
    ) AS corr_hpsa_adhd,

    CORR(
        pct_designated_population_underserved,
        pct_current_adhd
    ) AS corr_underserved_adhd,

    CORR(
        provider_shortage_per_100k,
        pct_current_adhd
    ) AS corr_provider_shortage_adhd

FROM vw_q8_support_burden_analysis;

-- ---------------------------------------------------------
-- PART 4:
-- Test whether SCHOOL mental-health support capacity is
-- associated differently with anxiety, depression,
-- and ADHD prevalence across states.
--
-- Higher students-per-staff ratios indicate thinner
-- school support capacity.
-- ---------------------------------------------------------

SELECT

    -- =====================================================
    -- ANXIETY
    -- =====================================================

    CORR(
        students_per_psychologist,
        pct_current_anxiety
    ) AS corr_psychologist_anxiety,

    CORR(
        students_per_guidance_counselor,
        pct_current_anxiety
    ) AS corr_counselor_anxiety,


    -- =====================================================
    -- DEPRESSION
    -- =====================================================

    CORR(
        students_per_psychologist,
        pct_current_depression
    ) AS corr_psychologist_depression,

    CORR(
        students_per_guidance_counselor,
        pct_current_depression
    ) AS corr_counselor_depression,


    -- =====================================================
    -- ADHD
    -- =====================================================

    CORR(
        students_per_psychologist,
        pct_current_adhd
    ) AS corr_psychologist_adhd,

    CORR(
        students_per_guidance_counselor,
        pct_current_adhd
    ) AS corr_counselor_adhd

FROM vw_q8_support_burden_analysis;

-- =========================================================
-- QUESTION 8B
-- What socioeconomic, family, insurance, and access
-- characteristics distinguish states with lower pediatric
-- mental-health burden from states with higher burden?
--
-- PURPOSE:
-- Expand beyond school and provider capacity to examine
-- whether lower-burden states share broader contextual
-- characteristics.
--
-- IMPORTANT:
-- These are state-level associations only.
-- They identify patterns, not causal explanations.
-- =========================================================


-- ---------------------------------------------------------
-- PART 5:
-- Add ACS socioeconomic and access context to the
-- Question 8 state-level mental-health burden table.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_q8_burden_context_analysis AS

SELECT
    q8.*,

    -- Household / economic context
    acs.median_household_income,
    acs.pct_households_receiving_snap,
    acs.pct_families_with_children_below_poverty,
    acs.pct_under_18_below_poverty,
    acs.pct_children_5_17_below_poverty,

    -- Insurance
    acs.pct_under_19_uninsured,

    -- Family / household structure
    acs.pct_female_householder_with_children,

    -- Language / digital access
    acs.pct_limited_english,
    acs.pct_households_with_computer,
    acs.pct_households_with_broadband

FROM vw_q8_support_burden_analysis AS q8

LEFT JOIN vw_acs_state_core_context AS acs
    ON q8.state_fips_code = acs.state_fips;

    -- ---------------------------------------------------------
-- PART 5 QA:
-- Confirm ACS contextual measures joined to the state-level
-- pediatric mental-health burden table.
-- ---------------------------------------------------------

SELECT
    state_name,
    pct_any_current_condition,
    median_household_income,
    pct_under_18_below_poverty,
    pct_under_19_uninsured,
    pct_households_with_broadband

FROM vw_q8_burden_context_analysis

ORDER BY pct_any_current_condition ASC;

-- ---------------------------------------------------------
-- PART 6:
-- Test relationships between broader state context and
-- pediatric mental-health burden.
--
-- Negative correlations mean higher values of the context
-- measure tend to occur with LOWER mental-health burden.
--
-- Positive correlations mean higher values tend to occur
-- with HIGHER mental-health burden.
-- ---------------------------------------------------------

SELECT

    -- Economic resources
    CORR(
        median_household_income,
        pct_any_current_condition
    ) AS corr_income_any_condition,

    CORR(
        pct_households_receiving_snap,
        pct_any_current_condition
    ) AS corr_snap_any_condition,

    CORR(
        pct_under_18_below_poverty,
        pct_any_current_condition
    ) AS corr_child_poverty_any_condition,

    CORR(
        pct_families_with_children_below_poverty,
        pct_any_current_condition
    ) AS corr_family_poverty_any_condition,

    -- Insurance
    CORR(
        pct_under_19_uninsured,
        pct_any_current_condition
    ) AS corr_uninsured_any_condition,

    -- Family structure
    CORR(
        pct_female_householder_with_children,
        pct_any_current_condition
    ) AS corr_female_householder_any_condition,

    -- Access infrastructure
    CORR(
        pct_households_with_broadband,
        pct_any_current_condition
    ) AS corr_broadband_any_condition,

    CORR(
        pct_limited_english,
        pct_any_current_condition
    ) AS corr_limited_english_any_condition

FROM vw_q8_burden_context_analysis;

-- =========================================================
-- QUESTION 8B
-- What socioeconomic, family, insurance, and access
-- characteristics distinguish states with lower pediatric
-- mental-health burden from states with higher burden?
--
-- ACS fields are explicitly converted to DOUBLE here
-- because some were imported as VARCHAR/text.
-- =========================================================

CREATE OR REPLACE VIEW vw_q8_burden_context_analysis AS

SELECT
    q8.*,

    -- -----------------------------------------------------
    -- Household / economic context
    -- -----------------------------------------------------

    TRY_CAST(acs.median_household_income AS DOUBLE)
        AS median_household_income,

    TRY_CAST(acs.pct_households_receiving_snap AS DOUBLE)
        AS pct_households_receiving_snap,

    TRY_CAST(acs.pct_families_with_children_below_poverty AS DOUBLE)
        AS pct_families_with_children_below_poverty,

    TRY_CAST(acs.pct_under_18_below_poverty AS DOUBLE)
        AS pct_under_18_below_poverty,

    TRY_CAST(acs.pct_children_5_17_below_poverty AS DOUBLE)
        AS pct_children_5_17_below_poverty,


    -- -----------------------------------------------------
    -- Insurance
    -- -----------------------------------------------------

    TRY_CAST(acs.pct_under_19_uninsured AS DOUBLE)
        AS pct_under_19_uninsured,


    -- -----------------------------------------------------
    -- Family / household structure
    -- -----------------------------------------------------

    TRY_CAST(acs.pct_female_householder_with_children AS DOUBLE)
        AS pct_female_householder_with_children,


    -- -----------------------------------------------------
    -- Language / digital access
    -- -----------------------------------------------------

    TRY_CAST(acs.pct_limited_english AS DOUBLE)
        AS pct_limited_english,

    TRY_CAST(acs.pct_households_with_computer AS DOUBLE)
        AS pct_households_with_computer,

    TRY_CAST(acs.pct_households_with_broadband AS DOUBLE)
        AS pct_households_with_broadband


FROM vw_q8_support_burden_analysis AS q8

LEFT JOIN vw_acs_state_core_context AS acs
    ON q8.state_fips_code = acs.state_fips;

    -- ---------------------------------------------------------
-- PART 6:
-- Test relationships between broader state context and
-- pediatric mental-health burden.
--
-- Positive correlation:
-- higher contextual measure tends to occur with
-- higher mental-health burden.
--
-- Negative correlation:
-- higher contextual measure tends to occur with
-- lower mental-health burden.
--
-- These are associations only, not causal effects.
-- ---------------------------------------------------------

SELECT

    -- Economic resources
    CORR(
        median_household_income,
        pct_any_current_condition
    ) AS corr_income_any_condition,

    CORR(
        pct_households_receiving_snap,
        pct_any_current_condition
    ) AS corr_snap_any_condition,

    CORR(
        pct_under_18_below_poverty,
        pct_any_current_condition
    ) AS corr_child_poverty_any_condition,

    CORR(
        pct_families_with_children_below_poverty,
        pct_any_current_condition
    ) AS corr_family_poverty_any_condition,


    -- Insurance
    CORR(
        pct_under_19_uninsured,
        pct_any_current_condition
    ) AS corr_uninsured_any_condition,


    -- Family structure
    CORR(
        pct_female_householder_with_children,
        pct_any_current_condition
    ) AS corr_female_householder_any_condition,


    -- Digital / access context
    CORR(
        pct_households_with_broadband,
        pct_any_current_condition
    ) AS corr_broadband_any_condition,

    CORR(
        pct_limited_english,
        pct_any_current_condition
    ) AS corr_limited_english_any_condition

FROM vw_q8_burden_context_analysis;

-- ---------------------------------------------------------
-- PART 7:
-- Test whether broader state contextual factors are
-- associated differently with anxiety, depression,
-- and ADHD prevalence.
--
-- This helps determine whether the overall relationships
-- observed in Question 8B are consistent across conditions
-- or driven primarily by one diagnosis.
--
-- These are state-level associations only.
-- ---------------------------------------------------------

SELECT

    -- =====================================================
    -- MEDIAN HOUSEHOLD INCOME
    -- =====================================================

    CORR(
        median_household_income,
        pct_current_anxiety
    ) AS corr_income_anxiety,

    CORR(
        median_household_income,
        pct_current_depression
    ) AS corr_income_depression,

    CORR(
        median_household_income,
        pct_current_adhd
    ) AS corr_income_adhd,


    -- =====================================================
    -- CHILD POVERTY
    -- =====================================================

    CORR(
        pct_under_18_below_poverty,
        pct_current_anxiety
    ) AS corr_child_poverty_anxiety,

    CORR(
        pct_under_18_below_poverty,
        pct_current_depression
    ) AS corr_child_poverty_depression,

    CORR(
        pct_under_18_below_poverty,
        pct_current_adhd
    ) AS corr_child_poverty_adhd,


    -- =====================================================
    -- INSURANCE
    -- =====================================================

    CORR(
        pct_under_19_uninsured,
        pct_current_anxiety
    ) AS corr_uninsured_anxiety,

    CORR(
        pct_under_19_uninsured,
        pct_current_depression
    ) AS corr_uninsured_depression,

    CORR(
        pct_under_19_uninsured,
        pct_current_adhd
    ) AS corr_uninsured_adhd,


    -- =====================================================
    -- BROADBAND
    -- =====================================================

    CORR(
        pct_households_with_broadband,
        pct_current_anxiety
    ) AS corr_broadband_anxiety,

    CORR(
        pct_households_with_broadband,
        pct_current_depression
    ) AS corr_broadband_depression,

    CORR(
        pct_households_with_broadband,
        pct_current_adhd
    ) AS corr_broadband_adhd,


    -- =====================================================
    -- LIMITED ENGLISH
    -- =====================================================

    CORR(
        pct_limited_english,
        pct_current_anxiety
    ) AS corr_limited_english_anxiety,

    CORR(
        pct_limited_english,
        pct_current_depression
    ) AS corr_limited_english_depression,

    CORR(
        pct_limited_english,
        pct_current_adhd
    ) AS corr_limited_english_adhd

FROM vw_q8_burden_context_analysis;