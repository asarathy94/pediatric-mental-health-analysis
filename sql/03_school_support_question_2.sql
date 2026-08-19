-- =========================================================
-- QUESTION 2
-- Which states have the lowest school-based
-- mental-health support capacity?
--
-- We will evaluate school support using NCES district
-- enrollment and staffing measures, then aggregate to state.
-- =========================================================


-- ---------------------------------------------------------
-- PART 1: Verify the district-level support fields available
-- ---------------------------------------------------------

DESCRIBE vw_nces_district_master;
-- ---------------------------------------------------------
-- PART 1 QA:
-- Preview the school-support fields we expect to use.
-- ---------------------------------------------------------

SELECT
    LEAID,
    STATENAME,
    ST,
    district_student_count,
    school_counselors,
    school_psychologists,
    student_support_services_staff

FROM vw_nces_district_master
LIMIT 25;

-- ---------------------------------------------------------
-- PART 2:
-- Which states have the lowest school-based mental-health
-- support capacity?
--
-- Aggregate district enrollment and staffing to the state
-- level before calculating student-to-staff ratios.
--
-- Higher students-per-staff = lower support capacity.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nces_state_school_support AS

SELECT
    STATENAME AS state_name,
    ST AS state_abbreviation,

    COUNT(DISTINCT LEAID) AS district_count,

    SUM(district_student_count) AS total_students,

    SUM(school_counselors) AS total_school_counselors,
    SUM(school_psychologists) AS total_school_psychologists,
    SUM(student_support_services_staff) AS total_student_support_staff,

    -- Students per counselor
    ROUND(
        SUM(district_student_count)
        / NULLIF(SUM(school_counselors), 0),
        1
    ) AS students_per_counselor,

    -- Students per psychologist
    ROUND(
        SUM(district_student_count)
        / NULLIF(SUM(school_psychologists), 0),
        1
    ) AS students_per_psychologist,

    -- Students per broader student-support staff member
    ROUND(
        SUM(district_student_count)
        / NULLIF(SUM(student_support_services_staff), 0),
        1
    ) AS students_per_student_support_staff

FROM vw_nces_district_master

WHERE district_student_count IS NOT NULL
  AND district_student_count > 0
GROUP BY
    STATENAME,
    ST;

    -- ---------------------------------------------------------
-- PART 2 QA:
-- Which states have the thinnest counselor capacity?
-- Higher ratio = fewer counselors relative to students.
-- ---------------------------------------------------------

SELECT *
FROM vw_nces_state_school_support
ORDER BY students_per_counselor DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Which states have the thinnest psychologist capacity?
-- ---------------------------------------------------------

SELECT *
FROM vw_nces_state_school_support
ORDER BY students_per_psychologist DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Which states have the thinnest broader student-support
-- staffing capacity?
-- ---------------------------------------------------------

SELECT *
FROM vw_nces_state_school_support
ORDER BY students_per_student_support_staff DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 2B QA:
-- Which NCES jurisdictions are outside the 50 states + DC?
-- ---------------------------------------------------------

SELECT
    state_name,
    state_abbreviation,
    district_count,
    total_students,
    total_school_counselors,
    total_school_psychologists,
    total_student_support_staff

FROM vw_nces_state_school_support

WHERE state_abbreviation NOT IN (
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
    'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
    'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
    'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
    'DC'
)

ORDER BY state_name;

-- ---------------------------------------------------------
-- PART 2C:
-- Restrict Question 2 to the 50 states + DC.
-- Non-state NCES jurisdictions remain available separately.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nces_state_school_support_states_only AS

SELECT *
FROM vw_nces_state_school_support

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
-- Confirm 50 states + DC only.
-- ---------------------------------------------------------

SELECT COUNT(*) AS state_dc_count
FROM vw_nces_state_school_support_states_only;

-- Counselor capacity
SELECT *
FROM vw_nces_state_school_support_states_only
ORDER BY students_per_counselor DESC NULLS LAST;

-- Psychologist capacity
SELECT *
FROM vw_nces_state_school_support_states_only
ORDER BY students_per_psychologist DESC NULLS LAST;

-- Broader student-support capacity
SELECT *
FROM vw_nces_state_school_support_states_only
ORDER BY students_per_student_support_staff DESC NULLS LAST;

-- ---------------------------------------------------------
-- PART 3:
-- Which states have consistently low school-based
-- mental-health support capacity across multiple staff types?
--
-- Higher students-per-staff ratios indicate thinner support.
--
-- Each state is ranked separately on:
--   1) students per counselor
--   2) students per psychologist
--   3) students per broader student-support staff member
--
-- Rank 1 = weakest capacity.
-- The average of the three ranks creates an overall
-- school-support vulnerability ranking.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nces_state_school_support_ranking AS

WITH ranked AS (

    SELECT
        state_name,
        state_abbreviation,

        total_students,
        total_school_counselors,
        total_school_psychologists,
        total_student_support_staff,

        students_per_counselor,
        students_per_psychologist,
        students_per_student_support_staff,

        RANK() OVER (
            ORDER BY students_per_counselor DESC NULLS LAST
        ) AS counselor_capacity_rank,

        RANK() OVER (
            ORDER BY students_per_psychologist DESC NULLS LAST
        ) AS psychologist_capacity_rank,

        RANK() OVER (
            ORDER BY students_per_student_support_staff DESC NULLS LAST
        ) AS student_support_capacity_rank

    FROM vw_nces_state_school_support_states_only
)

SELECT
    *,

    ROUND(
        (
            counselor_capacity_rank
            + psychologist_capacity_rank
            + student_support_capacity_rank
        ) / 3.0,
        2
    ) AS avg_school_support_rank

FROM ranked;

-- ---------------------------------------------------------
-- PART 3 QA:
-- Rank states by weakness across all three school-support
-- capacity measures.
--
-- Lower average rank = weaker overall school support.
-- ---------------------------------------------------------

SELECT *
FROM vw_nces_state_school_support_ranking
ORDER BY
    avg_school_support_rank ASC,
    psychologist_capacity_rank ASC,
    counselor_capacity_rank ASC;

    -- ---------------------------------------------------------
-- PART 3B QA:
-- Identify states with zero or missing school mental-health
-- staffing totals before interpreting the final ranking.
-- ---------------------------------------------------------

SELECT
    state_name,
    state_abbreviation,
    total_students,

    total_school_counselors,
    total_school_psychologists,
    total_student_support_staff,

    students_per_counselor,
    students_per_psychologist,
    students_per_student_support_staff

FROM vw_nces_state_school_support_states_only

WHERE total_school_counselors IS NULL
   OR total_school_counselors = 0

   OR total_school_psychologists IS NULL
   OR total_school_psychologists = 0

   OR total_student_support_staff IS NULL
   OR total_student_support_staff = 0

ORDER BY state_name;

-- ---------------------------------------------------------
-- PART 3C QA:
-- How complete is state-level reporting for each school
-- mental-health staffing measure?
-- ---------------------------------------------------------

SELECT

    COUNT(*) AS total_states_dc,

    COUNT(total_school_counselors)
        AS states_with_counselor_data,

    COUNT(total_school_psychologists)
        AS states_with_psychologist_data,

    COUNT(total_student_support_staff)
        AS states_with_student_support_data,

    SUM(
        CASE
            WHEN total_school_counselors IS NULL
              OR total_school_counselors = 0
            THEN 1 ELSE 0
        END
    ) AS counselor_missing_or_zero_states,

    SUM(
        CASE
            WHEN total_school_psychologists IS NULL
              OR total_school_psychologists = 0
            THEN 1 ELSE 0
        END
    ) AS psychologist_missing_or_zero_states,

    SUM(
        CASE
            WHEN total_student_support_staff IS NULL
              OR total_student_support_staff = 0
            THEN 1 ELSE 0
        END
    ) AS student_support_missing_or_zero_states

FROM vw_nces_state_school_support_states_only;

-- ---------------------------------------------------------
-- PART 3D QA:
-- Which state/DC is missing or reporting zero
-- school psychologist staffing?
-- ---------------------------------------------------------

SELECT
    state_name,
    state_abbreviation,
    total_students,
    total_school_psychologists,
    students_per_psychologist

FROM vw_nces_state_school_support_states_only

WHERE total_school_psychologists IS NULL
   OR total_school_psychologists = 0;

   -- ---------------------------------------------------------
-- PART 3D QA:
-- Which state/DC jurisdictions are missing or reporting zero
-- broader student-support staffing?
-- ---------------------------------------------------------

SELECT
    state_name,
    state_abbreviation,
    total_students,
    total_student_support_staff,
    students_per_student_support_staff

FROM vw_nces_state_school_support_states_only

WHERE total_student_support_staff IS NULL
   OR total_student_support_staff = 0;

   -- ---------------------------------------------------------
-- PART 3E QA:
-- Which school staffing categories have usable reporting
-- across all 50 states + DC?
--
-- This checks state-level coverage for every staffing field
-- currently carried into the district master.
-- ---------------------------------------------------------

SELECT
    COUNT(*) AS total_states_dc,

    COUNT(total_school_counselors) AS counselor_states,
    COUNT(total_school_psychologists) AS psychologist_states,
    COUNT(total_student_support_staff) AS student_support_states

FROM vw_nces_state_school_support_states_only;

-- ---------------------------------------------------------
-- PART 3E QA:
-- What staffing categories are available in the full
-- NCES district staffing view?
-- ---------------------------------------------------------

DESCRIBE vw_nces_district_staffing_full;

-- ---------------------------------------------------------
-- PART 3E:
-- Which school-support staffing categories have usable
-- reporting across all 50 states + DC?
--
-- This aggregates each staffing category to the state level
-- and counts how many states/DC have a positive reported total.
-- ---------------------------------------------------------

WITH state_staff AS (

    SELECT
        STATENAME AS state_name,
        ST AS state_abbreviation,

        SUM(school_psychologists) AS school_psychologists,
        SUM(student_support_services_staff) AS student_support_services_staff,
        SUM(school_counselors) AS school_counselors,
        SUM(elementary_school_counselors) AS elementary_school_counselors,
        SUM(secondary_school_counselors) AS secondary_school_counselors,
        SUM(guidance_counselors) AS guidance_counselors,
        SUM(all_other_support_staff) AS all_other_support_staff

    FROM vw_nces_district_staffing_full

    WHERE ST IN (
        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
        'DC'
    )

    GROUP BY
        STATENAME,
        ST
)

SELECT

    COUNT(*) AS total_states_dc,

    SUM(CASE WHEN school_psychologists > 0 THEN 1 ELSE 0 END)
        AS states_with_school_psychologists,

    SUM(CASE WHEN student_support_services_staff > 0 THEN 1 ELSE 0 END)
        AS states_with_student_support_services_staff,

    SUM(CASE WHEN school_counselors > 0 THEN 1 ELSE 0 END)
        AS states_with_school_counselors,

    SUM(CASE WHEN elementary_school_counselors > 0 THEN 1 ELSE 0 END)
        AS states_with_elementary_counselors,

    SUM(CASE WHEN secondary_school_counselors > 0 THEN 1 ELSE 0 END)
        AS states_with_secondary_counselors,

    SUM(CASE WHEN guidance_counselors > 0 THEN 1 ELSE 0 END)
        AS states_with_guidance_counselors,

    SUM(CASE WHEN all_other_support_staff > 0 THEN 1 ELSE 0 END)
        AS states_with_other_support_staff

FROM state_staff;

-- ---------------------------------------------------------
-- PART 3F QA:
-- Which state/DC lacks positive reporting for school
-- psychologists or guidance counselors?
-- ---------------------------------------------------------

WITH state_staff AS (

    SELECT
        STATENAME AS state_name,
        ST AS state_abbreviation,

        SUM(school_psychologists) AS school_psychologists,
        SUM(guidance_counselors) AS guidance_counselors

    FROM vw_nces_district_staffing_full

    WHERE ST IN (
        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
        'DC'
    )

    GROUP BY
        STATENAME,
        ST
)

SELECT *
FROM state_staff

WHERE school_psychologists IS NULL
   OR school_psychologists = 0
   OR guidance_counselors IS NULL
   OR guidance_counselors = 0

ORDER BY state_name;

-- ---------------------------------------------------------
-- PART 3G:
-- Final school-support vulnerability ranking.
--
-- Final measures:
--   1) students per school psychologist
--   2) students per guidance counselor
--
-- These are the two most complete mental-health/support
-- staffing measures in the NCES staffing extract:
--   - school psychologists: 50/51 states + DC
--   - guidance counselors: 50/51 states + DC
--
-- Tennessee is excluded from the composite ranking because
-- it has no positive reported state-level total for either
-- measure in this extract.
--
-- IMPORTANT:
-- Tennessee is treated as a reporting gap, NOT as having
-- zero actual school psychologists or guidance counselors.
--
-- Higher students-per-staff = thinner support capacity.
-- Rank 1 = weakest support capacity.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_nces_state_school_support_final AS

WITH state_staff AS (

    SELECT
        m.STATENAME AS state_name,
        m.ST AS state_abbreviation,

        SUM(m.district_student_count) AS total_students,

        SUM(s.school_psychologists) AS total_school_psychologists,
        SUM(s.guidance_counselors) AS total_guidance_counselors

    FROM vw_nces_district_master AS m

    LEFT JOIN vw_nces_district_staffing_full AS s
        ON m.LEAID = s.LEAID

    WHERE m.ST IN (
        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
        'DC'
    )

    AND m.district_student_count IS NOT NULL
    AND m.district_student_count > 0

    GROUP BY
        m.STATENAME,
        m.ST
),

rates AS (

    SELECT
        state_name,
        state_abbreviation,
        total_students,

        total_school_psychologists,
        total_guidance_counselors,

        ROUND(
            total_students
            / NULLIF(total_school_psychologists, 0),
            1
        ) AS students_per_psychologist,

        ROUND(
            total_students
            / NULLIF(total_guidance_counselors, 0),
            1
        ) AS students_per_guidance_counselor

    FROM state_staff
),

rankable AS (

    SELECT *
    FROM rates

    WHERE total_school_psychologists > 0
      AND total_guidance_counselors > 0
),

ranked AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY students_per_psychologist DESC
        ) AS psychologist_capacity_rank,

        RANK() OVER (
            ORDER BY students_per_guidance_counselor DESC
        ) AS guidance_counselor_capacity_rank

    FROM rankable
)

SELECT
    *,

    ROUND(
        (
            psychologist_capacity_rank
            + guidance_counselor_capacity_rank
        ) / 2.0,
        2
    ) AS avg_school_support_rank

FROM ranked;

-- ---------------------------------------------------------
-- PART 3G QA:
-- Rank states by weakness across school psychologist and
-- guidance counselor capacity.
--
-- Lower average rank = thinner overall school support.
-- Tennessee is intentionally excluded because of the
-- identified reporting gap.
-- ---------------------------------------------------------

SELECT *
FROM vw_nces_state_school_support_final

ORDER BY
    avg_school_support_rank ASC,
    psychologist_capacity_rank ASC;

    -- ---------------------------------------------------------
-- PART 3G REPORTING GAP:
-- Preserve states/DC that cannot be included in the final
-- school-support ranking because one or both measures lack
-- a positive reported staffing total.
-- ---------------------------------------------------------

WITH state_staff AS (

    SELECT
        m.STATENAME AS state_name,
        m.ST AS state_abbreviation,

        SUM(s.school_psychologists) AS total_school_psychologists,
        SUM(s.guidance_counselors) AS total_guidance_counselors

    FROM vw_nces_district_master AS m

    LEFT JOIN vw_nces_district_staffing_full AS s
        ON m.LEAID = s.LEAID

    WHERE m.ST IN (
        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
        'DC'
    )

    GROUP BY
        m.STATENAME,
        m.ST
)

SELECT *
FROM state_staff

WHERE total_school_psychologists IS NULL
   OR total_school_psychologists = 0
   OR total_guidance_counselors IS NULL
   OR total_guidance_counselors = 0

ORDER BY state_name;