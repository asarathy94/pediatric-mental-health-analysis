-- =========================================================
-- 11_flourish_why_jackson.sql
--
-- FLOURISH VISUALIZATION EXPORT
--
-- QUESTION:
-- Why did Jackson County become a useful local case for
-- understanding unmet pediatric mental-health needs?
--
-- PURPOSE:
-- Create a small synthesis dataset for a 5-bubble Flourish
-- visualization.
--
-- Each bubble represents one contributing condition that
-- emerged from the quantitative analysis + local desk
-- research + service-design synthesis.
--
-- IMPORTANT:
-- Bubble sizes are intentionally equal.
--
-- We do NOT have evidence that one issue is quantitatively
-- "larger" or more important than another.
--
-- opportunity_level describes how directly the issue may be
-- addressable through service / digital design.
-- It is a synthesis classification, NOT a measured score.
-- =========================================================


-- =========================================================
-- 1. CREATE THE FIVE-BUBBLE DATASET
-- =========================================================

CREATE OR REPLACE VIEW vw_flourish_why_jackson AS

SELECT *

FROM (

    VALUES

    -- -----------------------------------------------------
    -- SCHOOL SUPPORT
    -- -----------------------------------------------------

    (
        1,

        'School staffing pressure',

        1,

        'School support',

        'School mental-health support capacity varies across local districts, creating different starting conditions for identifying needs and helping families reach additional care.',

        'Quantitative + local system evidence',

        'Medium',

        'Partly addressable through service design'
    ),


    -- -----------------------------------------------------
    -- PROVIDER / WORKFORCE CAPACITY
    -- -----------------------------------------------------

    (
        2,

        'Provider & workforce shortage',

        1,

        'Care capacity',

        'Southern Oregon faces behavioral-health provider shortages and workforce recruitment and retention pressure, contributing to limited appointment availability and longer waits.',

        'Documented local and provider-access evidence',

        'Low',

        'Primarily a structural capacity constraint'
    ),


    -- -----------------------------------------------------
    -- RURAL / GEOGRAPHIC ACCESS
    -- -----------------------------------------------------

    (
        3,

        'Rural access burden',

        1,

        'Geographic access',

        'Distance, transportation, and rural geography can make available mental-health services harder for families to reach in practice.',

        'Documented local context',

        'Low',

        'Primarily structural, with some navigation opportunities'
    ),


    -- -----------------------------------------------------
    -- COVERAGE + PROVIDER MATCHING
    -- -----------------------------------------------------

    (
        4,

        'Coverage & provider fit',

        1,

        'Access complexity',

        'A provider may exist but still not be a workable option because of insurance network, age, specialty, acuity, language, geography, or current availability.',

        'Documented + service-system synthesis',

        'High',

        'Strong service-design opportunity'
    ),


    -- -----------------------------------------------------
    -- NAVIGATION + HANDOFF
    -- -----------------------------------------------------

    (
        5,

        'Navigation & handoff friction',

        1,

        'Care connection',

        'Families may move across schools, coverage systems, coordinators, providers, referrals, and fallback options without one universal closed-loop path from concern to confirmed care.',

        'Supported service-system interpretation',

        'High',

        'Strong service-design opportunity'
    )

)

AS t (

    issue_id,

    issue,

    bubble_size,

    issue_group,

    evidence_summary,

    evidence_status,

    opportunity_level,

    opportunity_note

);

-- =========================================================
-- 2. QA THE FLOURISH DATASET
-- =========================================================

SELECT *
FROM vw_flourish_why_jackson
ORDER BY issue_id;

-- Confirm we have exactly five unique issues.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT issue_id) AS unique_issues

FROM vw_flourish_why_jackson;

-- =========================================================
-- 3. CHECK COLOR GROUPS
-- =========================================================

SELECT
    opportunity_level,
    COUNT(*) AS issue_count

FROM vw_flourish_why_jackson

GROUP BY opportunity_level

ORDER BY
    CASE opportunity_level
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
    END;

    -- =========================================================
-- 4. EXPORT FOR FLOURISH
-- =========================================================

COPY (

    SELECT *
    FROM vw_flourish_why_jackson
    ORDER BY issue_id

)

TO '../data/flourish_export/flourish_why_jackson.csv'

(
    HEADER,
    DELIMITER ','
);

