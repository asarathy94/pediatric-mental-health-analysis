-- =========================================================
-- CLAUDE DASHBOARD EXPORT
-- PART 1:
-- Export finalized national state-level analysis data.
-- =========================================================

COPY (
    SELECT *
    FROM vw_final_state_analysis
    ORDER BY state_name
)
TO 'C:/Users/akila/pediatric-mental-health-analysis/data/claude_exports/claude_dashboard_state_analysis.csv'
WITH (
    HEADER,
    DELIMITER ','
);

SELECT COUNT(*)
FROM read_csv_auto(
    'C:/Users/akila/pediatric-mental-health-analysis/data/claude_exports/claude_dashboard_state_analysis.csv'
);
SELECT current_setting('home_directory') AS home_directory;

SELECT current_setting('temp_directory') AS temp_directory;

SELECT *
FROM glob('*');

SELECT *
FROM glob('data/*');

-- =========================================================
-- CLAUDE DASHBOARD EXPORT
-- PART 2:
-- Export finalized Oregon county-level overlap data.
--
-- This file will power:
--   4. Oregon County Drill-Down
-- =========================================================

COPY (
    SELECT *
    FROM vw_final_oregon_county_overlap
    ORDER BY county_candidate_rank_within_state
)
TO 'C:/Users/akila/pediatric-mental-health-analysis/data/claude_exports/claude_dashboard_oregon_counties.csv'
WITH (
    HEADER,
    DELIMITER ','
);

SELECT COUNT(*)
FROM read_csv_auto(
    'C:/Users/akila/pediatric-mental-health-analysis/data/claude_exports/claude_dashboard_oregon_counties.csv'
);

-- =========================================================
-- CLAUDE DASHBOARD EXPORT
-- PART 3:
-- Export finalized Oregon district-level overlap data.
--
-- This file will power:
--   5. Jackson County Focus
--   and district-level drill-downs within Oregon.
-- =========================================================

COPY (
    SELECT *
    FROM vw_final_oregon_district_overlap
    ORDER BY
        county_name,
        combined_school_support_rank_within_state
)
TO 'C:/Users/akila/pediatric-mental-health-analysis/data/claude_exports/claude_dashboard_oregon_districts.csv'
WITH (
    HEADER,
    DELIMITER ','
);

SELECT COUNT(*)
FROM read_csv_auto(
    'C:/Users/akila/pediatric-mental-health-analysis/data/claude_exports/claude_dashboard_oregon_districts.csv'
);