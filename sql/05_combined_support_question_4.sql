-- =========================================================
-- QUESTION 4
-- Which states have the lowest combined school-based
-- and community mental-health support capacity?
--
-- This combines:
--   Q2 = school-support vulnerability
--   Q3 = community-support vulnerability
--
-- Lower rank values indicate weaker support capacity.
-- =========================================================


-- ---------------------------------------------------------
-- PART 1:
-- Join the final school-support and community-support
-- rankings by state abbreviation.
--
-- Tennessee is missing from the final school composite.
-- Vermont is missing from the final community composite.
-- Those reporting gaps are preserved as missing, not zero.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_state_combined_support AS

SELECT
    COALESCE(s.state_abbreviation, c.state_abbreviation)
        AS state_abbreviation,

    s.state_name,

    -- School support
    s.students_per_psychologist,
    s.students_per_guidance_counselor,
    s.psychologist_capacity_rank,
    s.guidance_counselor_capacity_rank,
    s.avg_school_support_rank,

    -- Community support
    c.avg_hpsa_score,
    c.pct_designated_population_underserved,
    c.provider_shortage_per_100k,
    c.hpsa_severity_rank,
    c.underserved_share_rank,
    c.provider_shortage_rate_rank,
    c.avg_community_support_rank

FROM vw_nces_state_school_support_final AS s

FULL OUTER JOIN vw_hpsa_state_community_support_final AS c
    ON s.state_abbreviation = c.state_abbreviation;

    -- ---------------------------------------------------------
-- PART 1 QA:
-- Confirm joined coverage and preserve reporting gaps.
-- ---------------------------------------------------------

SELECT *
FROM vw_state_combined_support
ORDER BY state_abbreviation;

-- ---------------------------------------------------------
-- PART 2:
-- Rank states by combined school + community support
-- vulnerability.
--
-- Both underlying composite rankings are weighted equally.
--
-- Lower average rank = weaker combined support capacity.
-- ---------------------------------------------------------

CREATE OR REPLACE VIEW vw_state_combined_support_ranking AS

WITH complete_support AS (

    SELECT *
    FROM vw_state_combined_support

    WHERE avg_school_support_rank IS NOT NULL
      AND avg_community_support_rank IS NOT NULL
)

SELECT
    *,

    ROUND(
        (
            avg_school_support_rank
            + avg_community_support_rank
        ) / 2.0,
        2
    ) AS avg_combined_support_rank

FROM complete_support;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Which states have the weakest combined school and
-- community support capacity?
-- ---------------------------------------------------------

SELECT *
FROM vw_state_combined_support_ranking
ORDER BY avg_combined_support_rank ASC;

-- ---------------------------------------------------------
-- PART 2 QA:
-- Which states have comparatively stronger support
-- capacity across BOTH school and community systems?
--
-- These may be useful cases for later desk research.
-- ---------------------------------------------------------

SELECT *
FROM vw_state_combined_support_ranking
ORDER BY avg_combined_support_rank DESC;