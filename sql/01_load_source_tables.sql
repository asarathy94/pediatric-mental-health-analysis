-- =========================================================
-- NSCH SOURCE TABLE
-- Final cleaned file: NSCH_2024_cleaned_ages_6_to_17.csv
-- Grain: one child record, ages 6–17
-- Expected shape: 37,534 rows x 107 columns
-- Role: core child-level dataset for unmet mental health
--       care, child/family factors, insurance, ACEs,
--       school, and neighborhood context
-- =========================================================

CREATE OR REPLACE TABLE nsch_children AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/NSCH_2024_cleaned_ages_6_to_17.csv',
    header = true
);
-- =========================================================
-- NSCH QA CHECK
-- Confirm expected column count
-- Expected: 107 columns
-- =========================================================

SELECT
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'nsch_children';
-- =========================================================
-- YRBSS NATIONAL SOURCE TABLE
-- Final cleaned file: yrbss_2023_cleaned.csv
-- Grain: one adolescent respondent
-- Role: national adolescent mental health burden,
--       suicidality, bullying, school connectedness,
--       sleep, adverse experiences, and protective factors
-- =========================================================

CREATE OR REPLACE TABLE yrbss_national AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/yrbss_2023_cleaned.csv',
    header = true
);
-- =========================================================
-- YRBSS NATIONAL QA CHECK
-- Confirm source table loaded successfully
-- =========================================================

SELECT
    COUNT(*) AS row_count
FROM yrbss_national;
-- =========================================================
-- YRBSS NATIONAL QA CHECK
-- Confirm column count
-- =========================================================

SELECT
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'yrbss_national';
-- =========================================================
-- YRBSS STATE SOURCE TABLE
-- Final cleaned file: yrbss_2019_2023_state_cleaned.csv
-- Grain: respondent within participating state-year sample
-- Role: weighted state-level youth mental health burden
--       and trends across participating jurisdictions
-- =========================================================

CREATE OR REPLACE TABLE yrbss_state AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/yrbss_2019_2023_state_cleaned.csv',
    header = true
);
-- =========================================================
-- YRBSS STATE QA CHECK
-- Confirm source table loaded successfully
-- =========================================================

SELECT
    COUNT(*) AS row_count
FROM yrbss_state;
-- =========================================================
-- YRBSS STATE QA CHECK
-- Confirm column count
-- =========================================================

SELECT
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'yrbss_state';
-- =========================================================
-- YRBSS DISTRICT SOURCE TABLE
-- Final cleaned file: yrbss_2019_2023_district_cleaned.csv
-- Grain: respondent within participating district-year sample
-- Role: weighted district-level youth mental health burden
--       and trends across participating jurisdictions
-- =========================================================

CREATE OR REPLACE TABLE yrbss_district AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/yrbss_2019_2023_district_cleaned.csv',
    header = true
);
-- =========================================================
-- YRBSS DISTRICT QA CHECK
-- Confirm source table loaded successfully
-- =========================================================

SELECT
    COUNT(*) AS row_count
FROM yrbss_district;
-- =========================================================
-- YRBSS DISTRICT QA CHECK
-- Confirm column count
-- =========================================================

SELECT
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'yrbss_district';
-- =========================================================
-- ACS COMMUNITY SOURCE TABLE
-- Final cleaned file: ACS_2024_cleaned_state_district.csv
-- Grain: state or unified school district geography
-- Role: socioeconomic, household, insurance, language,
--       housing, transportation, broadband, and other
--       community vulnerability context
-- =========================================================

CREATE OR REPLACE TABLE acs_community AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/ACS_2024_cleaned_state_district.csv',
    header = true
);
-- =========================================================
-- ACS COMMUNITY QA CHECK
-- Confirm source table loaded successfully
-- =========================================================

SELECT
    COUNT(*) AS row_count
FROM acs_community;
-- =========================================================
-- ACS COMMUNITY QA CHECK
-- Confirm column count
-- =========================================================

SELECT
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'acs_community';
-- =========================================================
-- NCES FISCAL SOURCE TABLE
-- Final cleaned file: NCES_CCD_2022_23_Fiscal_cleaned.csv
-- Grain: one local education agency (LEA) / district
-- Role: district revenue, expenditure, per-pupil spending,
--       and other financial/resource capacity measures
-- =========================================================

CREATE OR REPLACE TABLE nces_fiscal AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/NCES_CCD_2022_23_Fiscal_cleaned.csv',
    header = true
);
-- =========================================================
-- NCES FISCAL QA CHECK
-- Confirm source table loaded successfully
-- =========================================================

SELECT
    COUNT(*) AS row_count
FROM nces_fiscal;
-- =========================================================
-- NCES FISCAL QA CHECK
-- Confirm column count
-- =========================================================

SELECT
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'nces_fiscal';
-- =========================================================
-- NCES DIRECTORY SOURCE TABLE
-- Final cleaned file: NCES_CCD_2024_25_District_Directory_clean.csv
-- Grain: one local education agency (LEA) / district
-- Role: district identity, geography, district type,
--       operational status, school count, and reference fields
-- =========================================================

CREATE OR REPLACE TABLE nces_directory AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/NCES_CCD_2024_25_District_Directory_clean.csv',
    header = true
);
-- =========================================================
-- NCES DIRECTORY QA CHECK
-- Confirm source table loaded successfully
-- =========================================================

SELECT
    COUNT(*) AS row_count
FROM nces_directory;
-- =========================================================
-- NCES DIRECTORY QA CHECK
-- Confirm column count
-- =========================================================

SELECT
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'nces_directory';
-- =========================================================
-- NCES MEMBERSHIP SOURCE TABLE
-- Final cleaned file: NCES_CCD_2024_25_District_Membership_clean.csv
-- Grain: one local education agency (LEA) / district
-- Role: district enrollment and membership measures used
--       as denominators and context for staffing analysis
-- =========================================================

CREATE OR REPLACE TABLE nces_membership AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/NCES_CCD_2024_25_District_Membership_clean.csv',
    header = true
);
-- =========================================================
-- NCES MEMBERSHIP QA CHECK
-- Confirm source table loaded successfully
-- =========================================================

SELECT
    COUNT(*) AS row_count
FROM nces_membership;
-- =========================================================
-- NCES MEMBERSHIP GRAIN CHECK
-- Determine whether LEAID repeats across membership rows
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM nces_membership;
-- =========================================================
-- NCES MEMBERSHIP SAMPLE
-- Inspect why each district has multiple rows
-- =========================================================

SELECT *
FROM nces_membership
LIMIT 10;
-- =========================================================
-- NCES MEMBERSHIP COLUMN CHECK
-- Inspect the fields that define repeated membership rows
-- =========================================================

DESCRIBE nces_membership;
-- =========================================================
-- NCES MEMBERSHIP TOTAL INDICATOR CHECK
-- Inspect available total/subgroup reporting categories
-- =========================================================

SELECT
    TOTAL_INDICATOR,
    COUNT(*) AS row_count
FROM nces_membership
GROUP BY TOTAL_INDICATOR
ORDER BY row_count DESC;
-- =========================================================
-- NCES DISTRICT MEMBERSHIP VIEW
-- One row per LEA/district
-- Uses total enrollment excluding adult education
-- Appropriate for school-aged enrollment denominators
-- =========================================================

CREATE OR REPLACE VIEW vw_nces_district_membership AS

SELECT
    LEAID,
    ST_LEAID,
    LEA_NAME,
    FIPST,
    STATENAME,
    ST,
    SCHOOL_YEAR,
    STUDENT_COUNT AS district_student_count
FROM nces_membership
WHERE TOTAL_INDICATOR =
    'Derived - Education Unit Total minus Adult Education Count';
    -- =========================================================
-- NCES DISTRICT MEMBERSHIP VIEW QA
-- Expected: 18,548 district rows
-- =========================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM vw_nces_district_membership;
-- =========================================================
-- NCES STAFF SOURCE TABLE
-- Final cleaned file: NCES_CCD_2024_25_District_Staff_clean.csv
-- Grain: to be verified after load
-- Role: district staffing capacity, including counselors,
--       psychologists, teachers, and support staff
-- =========================================================

CREATE OR REPLACE TABLE nces_staff AS
SELECT *
FROM read_csv_auto(
    '../data/cleaned/NCES_CCD_2024_25_District_Staff_clean.csv',
    header = true
);
-- =========================================================
-- NCES STAFF GRAIN CHECK
-- Confirm total rows and unique districts
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM nces_staff;
-- =========================================================
-- NCES STAFF COLUMN CHECK
-- Inspect the fields that define repeated staffing rows
-- =========================================================

DESCRIBE nces_staff;
-- =========================================================
-- NCES STAFF CATEGORY CHECK
-- Inspect the staff categories available in the source file
-- =========================================================

SELECT
    STAFF,
    COUNT(*) AS row_count
FROM nces_staff
GROUP BY STAFF
ORDER BY row_count DESC;
-- =========================================================
-- NCES STAFF TOTAL INDICATOR CHECK
-- Inspect how staff rows are labeled as totals/subtotals
-- =========================================================

SELECT
    TOTAL_INDICATOR,
    COUNT(*) AS row_count
FROM nces_staff
GROUP BY TOTAL_INDICATOR
ORDER BY row_count DESC;
-- =========================================================
-- NCES STAFF CATEGORY STRUCTURE CHECK
-- Verify reporting level for the staffing categories
-- most relevant to pediatric mental health support
-- =========================================================

SELECT
    STAFF,
    TOTAL_INDICATOR,
    COUNT(*) AS row_count,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM nces_staff
WHERE STAFF IN (
    'Guidance Counselors',
    'School Psychologists',
    'Student Support Services Staff (w/o Psychology)',
    'Teachers'
)
GROUP BY
    STAFF,
    TOTAL_INDICATOR
ORDER BY
    STAFF,
    TOTAL_INDICATOR;
    -- =========================================================
-- NCES STAFF CATEGORY INVENTORY
-- List all distinct staff categories in the cleaned source
-- =========================================================

SELECT DISTINCT
    STAFF
FROM nces_staff
ORDER BY STAFF;
-- =========================================================
-- NCES STAFF CATEGORY STRUCTURE CHECK
-- Show every staff category and the reporting level it uses
-- so we can distinguish specific occupations from totals
-- and overlapping subgroup categories before pivoting.
-- =========================================================

SELECT
    STAFF,
    TOTAL_INDICATOR,
    COUNT(*) AS row_count,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM nces_staff
GROUP BY
    STAFF,
    TOTAL_INDICATOR
ORDER BY
    TOTAL_INDICATOR,
    STAFF;
    -- =========================================================
-- NCES FULL DISTRICT STAFFING VIEW
-- One row per LEA/district
-- Includes all 25 staff categories from the cleaned source
-- Raw nces_staff table remains unchanged
-- =========================================================

CREATE OR REPLACE VIEW vw_nces_district_staffing_full AS

SELECT
    LEAID,
    MAX(ST_LEAID) AS ST_LEAID,
    MAX(LEA_NAME) AS LEA_NAME,
    MAX(FIPST) AS FIPST,
    MAX(STATENAME) AS STATENAME,
    MAX(ST) AS ST,
    MAX(SCHOOL_YEAR) AS SCHOOL_YEAR,

    MAX(CASE WHEN STAFF = 'All Other Support Staff'
        THEN STAFF_COUNT END) AS all_other_support_staff,

    MAX(CASE WHEN STAFF = 'Elementary School Counselors'
        THEN STAFF_COUNT END) AS elementary_school_counselors,

    MAX(CASE WHEN STAFF = 'Elementary Teachers'
        THEN STAFF_COUNT END) AS elementary_teachers,

    MAX(CASE WHEN STAFF = 'Guidance Counselors'
        THEN STAFF_COUNT END) AS guidance_counselors,

    MAX(CASE WHEN STAFF = 'Instructional Coordinators and Supervisors to the Staff'
        THEN STAFF_COUNT END) AS instructional_coordinators_supervisors,

    MAX(CASE WHEN STAFF = 'Kindergarten Teachers'
        THEN STAFF_COUNT END) AS kindergarten_teachers,

    MAX(CASE WHEN STAFF = 'LEA Administrative Support Staff'
        THEN STAFF_COUNT END) AS lea_administrative_support_staff,

    MAX(CASE WHEN STAFF = 'LEA Administrators'
        THEN STAFF_COUNT END) AS lea_administrators,

    MAX(CASE WHEN STAFF = 'LEA Staff'
        THEN STAFF_COUNT END) AS lea_staff,

    MAX(CASE WHEN STAFF = 'Librarians/media specialists'
        THEN STAFF_COUNT END) AS librarians_media_specialists,

    MAX(CASE WHEN STAFF = 'Library/Media Support Staff'
        THEN STAFF_COUNT END) AS library_media_support_staff,

    MAX(CASE WHEN STAFF = 'No Category Codes'
        THEN STAFF_COUNT END) AS no_category_codes,

    MAX(CASE WHEN STAFF = 'Other Staff'
        THEN STAFF_COUNT END) AS other_staff,

    MAX(CASE WHEN STAFF = 'Paraprofessionals/Instructional Aides'
        THEN STAFF_COUNT END) AS paraprofessionals_instructional_aides,

    MAX(CASE WHEN STAFF = 'Pre-kindergarten Teachers'
        THEN STAFF_COUNT END) AS prekindergarten_teachers,

    MAX(CASE WHEN STAFF = 'School Administrative Support Staff'
        THEN STAFF_COUNT END) AS school_administrative_support_staff,

    MAX(CASE WHEN STAFF = 'School Counselors'
        THEN STAFF_COUNT END) AS school_counselors,

    MAX(CASE WHEN STAFF = 'School Psychologists'
        THEN STAFF_COUNT END) AS school_psychologists,

    MAX(CASE WHEN STAFF = 'School Staff'
        THEN STAFF_COUNT END) AS school_staff,

    MAX(CASE WHEN STAFF = 'School administrators'
        THEN STAFF_COUNT END) AS school_administrators,

    MAX(CASE WHEN STAFF = 'Secondary School Counselors'
        THEN STAFF_COUNT END) AS secondary_school_counselors,

    MAX(CASE WHEN STAFF = 'Secondary Teachers'
        THEN STAFF_COUNT END) AS secondary_teachers,

    MAX(CASE WHEN STAFF = 'Student Support Services Staff (w/o Psychology)'
        THEN STAFF_COUNT END) AS student_support_services_staff,

    MAX(CASE WHEN STAFF = 'Teachers'
        THEN STAFF_COUNT END) AS teachers,

    MAX(CASE WHEN STAFF = 'Ungraded Teachers'
        THEN STAFF_COUNT END) AS ungraded_teachers

FROM nces_staff
GROUP BY LEAID;
-- =========================================================
-- NCES FULL DISTRICT STAFFING VIEW QA
-- Confirm one row per LEA/district
-- =========================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM vw_nces_district_staffing_full;
-- =========================================================
-- HPSA MENTAL HEALTH SOURCE TABLE
-- Final cleaned file: HPSA_2026_snapshot_mental_health_cleaned.csv
-- Grain: to be verified after load
-- Role: mental-health provider shortage severity, provider
--       capacity, underserved population, and geography
-- =========================================================

-- =========================================================
-- HPSA MENTAL HEALTH SOURCE TABLE
-- Final cleaned file: HPSA_2026_snapshot_mental_health_cleaned.csv
-- Grain: to be verified after load
-- Role: mental-health provider shortage severity, provider
--       capacity, underserved population, and geography
-- =========================================================

CREATE OR REPLACE TABLE hpsa_mental_health AS
SELECT *
FROM read_csv_auto(
    'C:/Users/akila/pediatric-mental-health-analysis/data/cleaned/HPSA_2026_snapshot_mental_health_cleaned.csv',
    header = true
);
-- =========================================================
-- HPSA MENTAL HEALTH GRAIN CHECK
-- Confirm total rows and unique HPSA designations
-- =========================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT "HPSA ID") AS unique_hpsa_ids
FROM hpsa_mental_health;
-- =========================================================
-- HPSA COLUMN CHECK
-- Inspect fields that define repeated HPSA records
-- =========================================================

DESCRIBE hpsa_mental_health;
-- =========================================================
-- HPSA DUPLICATE STRUCTURE CHECK
-- Inspect how repeated HPSA IDs vary across geography
-- =========================================================

SELECT
    "HPSA ID",
    COUNT(*) AS row_count,
    COUNT(DISTINCT "HPSA Geography Identification Number") AS geography_count,
    COUNT(DISTINCT "Common State County FIPS Code") AS county_count
FROM hpsa_mental_health
GROUP BY "HPSA ID"
HAVING COUNT(*) > 1
ORDER BY row_count DESC
LIMIT 20;
-- =========================================================
-- HPSA DESIGNATION FIELD CONSISTENCY CHECK
-- Test whether designation-level measures repeat consistently
-- across geographic component rows
-- =========================================================

SELECT
    "HPSA ID",

    COUNT(DISTINCT "HPSA Score") AS score_versions,
    COUNT(DISTINCT "HPSA Status") AS status_versions,
    COUNT(DISTINCT "HPSA Designation Population") AS population_versions,
    COUNT(DISTINCT "HPSA Estimated Underserved Population") AS underserved_versions,
    COUNT(DISTINCT "HPSA FTE") AS fte_versions,
    COUNT(DISTINCT "HPSA Shortage") AS shortage_versions

FROM hpsa_mental_health
GROUP BY "HPSA ID"
HAVING COUNT(*) > 1
ORDER BY "HPSA ID";
-- =========================================================
-- HPSA MULTI-COUNTY CHECK
-- Determine whether any HPSA designation spans more than
-- one county before collapsing to one row per HPSA ID
-- =========================================================

SELECT
    MAX(county_count) AS max_counties_per_hpsa,
    COUNT(*) FILTER (WHERE county_count > 1) AS multi_county_hpsas
FROM (
    SELECT
        "HPSA ID",
        COUNT(DISTINCT "Common State County FIPS Code") AS county_count
    FROM hpsa_mental_health
    GROUP BY "HPSA ID"
);
-- =========================================================
-- HPSA DESIGNATION VIEW
-- One row per HPSA designation
-- Keeps designation-level measures only
-- County/geographic component detail remains in the raw
-- hpsa_mental_health table because some HPSAs span
-- multiple counties.
-- =========================================================

CREATE OR REPLACE VIEW vw_hpsa_designations AS

SELECT
    "HPSA ID",

    MAX("HPSA Name") AS hpsa_name,
    MAX("Designation Type") AS designation_type,
    MAX("HPSA Discipline Class") AS hpsa_discipline_class,
    MAX("HPSA Score") AS hpsa_score,
    MAX("HPSA Status") AS hpsa_status,
    MAX("HPSA Designation Date") AS designation_date,
    MAX("HPSA Designation Last Update Date") AS last_update_date,

    MAX("Primary State Abbreviation") AS primary_state_abbreviation,
    MAX("Common State FIPS Code") AS state_fips_code,

    MAX("HPSA Designation Population") AS designation_population,
    MAX("HPSA Estimated Served Population") AS estimated_served_population,
    MAX("HPSA Estimated Underserved Population") AS estimated_underserved_population,
    MAX("% of Population Below 100% Poverty") AS pct_population_below_100_poverty,

    MAX("HPSA Population Type") AS population_type,
    MAX("HPSA FTE") AS hpsa_fte,
    MAX("HPSA Formal Ratio") AS hpsa_formal_ratio,
    MAX("HPSA Provider Ratio Goal") AS provider_ratio_goal,
    MAX("HPSA Shortage") AS hpsa_shortage,

    MAX("Rural Status") AS rural_status,
    MAX("Metropolitan Indicator") AS metropolitan_indicator

FROM hpsa_mental_health
GROUP BY "HPSA ID";
-- =========================================================
-- HPSA DESIGNATION VIEW QA
-- Expected: 6,420 rows and 6,420 unique HPSA IDs
-- =========================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT "HPSA ID") AS unique_hpsa_ids
FROM vw_hpsa_designations;
-- =========================================================
-- NCES DISTRICT MASTER VIEW
-- One row per LEA/district
--
-- Anchor:
--   NCES Directory 2024-25
--
-- Adds:
--   district enrollment from Membership 2024-25
--   all 25 staffing categories from Staff 2024-25
--   fiscal/resource data from Fiscal 2022-23
--
-- Important:
-- Fiscal and nonfiscal files come from different school years.
-- The join links the same LEAID across sources but does NOT
-- imply that all measures were observed in the same year.
-- =========================================================

CREATE OR REPLACE VIEW vw_nces_district_master AS

SELECT
    d.*,

    -- Membership
    m.district_student_count,

    -- Whether this district matched the membership source
    CASE
        WHEN m.LEAID IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_membership_data,

    -- Staffing: all 25 categories
    s.* EXCLUDE (
        LEAID,
        ST_LEAID,
        LEA_NAME,
        FIPST,
        STATENAME,
        ST,
        SCHOOL_YEAR
    ),

    CASE
        WHEN s.LEAID IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_staff_data,

    -- Fiscal
    f.* EXCLUDE (LEAID),

    CASE
        WHEN f.LEAID IS NOT NULL THEN TRUE
        ELSE FALSE
    END AS has_fiscal_data

FROM nces_directory AS d

LEFT JOIN vw_nces_district_membership AS m
    ON d.LEAID = m.LEAID

LEFT JOIN vw_nces_district_staffing_full AS s
    ON d.LEAID = s.LEAID

LEFT JOIN nces_fiscal AS f
    ON d.LEAID = f.LEAID;
    -- =========================================================
-- NCES DISTRICT MASTER VIEW QA
-- Confirm the join stayed at one row per district
-- Expected anchor size: 19,630 Directory districts
-- =========================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM vw_nces_district_master;
-- =========================================================
-- NCES SOURCE COVERAGE CHECK
-- Determine how many Directory districts successfully
-- matched Membership, Staff, and Fiscal data
-- =========================================================

SELECT
    COUNT(*) AS directory_districts,

    SUM(
        CASE WHEN has_membership_data THEN 1 ELSE 0 END
    ) AS districts_with_membership,

    SUM(
        CASE WHEN has_staff_data THEN 1 ELSE 0 END
    ) AS districts_with_staff,

    SUM(
        CASE WHEN has_fiscal_data THEN 1 ELSE 0 END
    ) AS districts_with_fiscal,

    SUM(
        CASE
            WHEN has_membership_data
             AND has_staff_data
             AND has_fiscal_data
            THEN 1
            ELSE 0
        END
    ) AS districts_with_all_three

FROM vw_nces_district_master;
-- =========================================================
-- NCES DISTRICT CAPACITY VIEW
-- One row per LEA/district
-- Adds student-to-staff ratios using validated district
-- enrollment and staffing measures.
--
-- Ratios remain NULL when enrollment or staffing is missing,
-- or when the relevant staff count is zero.
-- =========================================================

CREATE OR REPLACE VIEW vw_nces_district_capacity AS

SELECT
    *,

    CASE
        WHEN district_student_count > 0
         AND guidance_counselors > 0
        THEN district_student_count / guidance_counselors
    END AS students_per_guidance_counselor,

    CASE
        WHEN district_student_count > 0
         AND school_counselors > 0
        THEN district_student_count / school_counselors
    END AS students_per_school_counselor,

    CASE
        WHEN district_student_count > 0
         AND school_psychologists > 0
        THEN district_student_count / school_psychologists
    END AS students_per_school_psychologist,

    CASE
        WHEN district_student_count > 0
         AND student_support_services_staff > 0
        THEN district_student_count / student_support_services_staff
    END AS students_per_student_support_staff,

    CASE
        WHEN district_student_count > 0
         AND teachers > 0
        THEN district_student_count / teachers
    END AS students_per_teacher

FROM vw_nces_district_master;
-- =========================================================
-- NCES DISTRICT CAPACITY QA
-- Confirm the derived view remains one row per district
-- =========================================================

SELECT
    COUNT(*) AS row_count,
    COUNT(DISTINCT LEAID) AS unique_districts
FROM vw_nces_district_capacity;
-- =========================================================
-- NCES STATE CAPACITY VIEW
-- One row per state
--
-- Rolls district-level enrollment and staffing up to state.
-- State staffing ratios are calculated from summed students
-- divided by summed staff counts, rather than averaging
-- district-level ratios.
-- =========================================================

CREATE OR REPLACE VIEW vw_nces_state_capacity AS

SELECT
    FIPST,
    MAX(STATENAME) AS state_name,
    MAX(ST) AS state_abbreviation,

    COUNT(*) AS district_count,

    SUM(district_student_count) AS total_students,

    SUM(guidance_counselors) AS total_guidance_counselors,
    SUM(school_counselors) AS total_school_counselors,
    SUM(school_psychologists) AS total_school_psychologists,
    SUM(student_support_services_staff) AS total_student_support_staff,
    SUM(teachers) AS total_teachers,

    CASE
        WHEN SUM(guidance_counselors) > 0
        THEN SUM(district_student_count) / SUM(guidance_counselors)
    END AS students_per_guidance_counselor,

    CASE
        WHEN SUM(school_counselors) > 0
        THEN SUM(district_student_count) / SUM(school_counselors)
    END AS students_per_school_counselor,

    CASE
        WHEN SUM(school_psychologists) > 0
        THEN SUM(district_student_count) / SUM(school_psychologists)
    END AS students_per_school_psychologist,

    CASE
        WHEN SUM(student_support_services_staff) > 0
        THEN SUM(district_student_count) / SUM(student_support_services_staff)
    END AS students_per_student_support_staff,

    CASE
        WHEN SUM(teachers) > 0
        THEN SUM(district_student_count) / SUM(teachers)
    END AS students_per_teacher

FROM vw_nces_district_capacity

WHERE FIPST IS NOT NULL

GROUP BY FIPST;
-- =========================================================
-- NCES STATE CAPACITY QA
-- Confirm state-level grain
-- =========================================================

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT FIPST) AS unique_state_fips
FROM vw_nces_state_capacity;
SELECT *
FROM vw_nces_state_capacity
ORDER BY state_name
LIMIT 10;
-- =========================================================
-- NCES 50 STATES + DC CAPACITY VIEW
-- Restricts the NCES state rollup to the 50 states
-- plus the District of Columbia for comparable analysis.
-- =========================================================

CREATE OR REPLACE VIEW vw_nces_state_capacity_50dc AS

SELECT *
FROM vw_nces_state_capacity
WHERE state_abbreviation IN (
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
    'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
    'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
    'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
    'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY',
    'DC'
);
-- =========================================================
-- NCES 50 STATES + DC QA
-- Expected: 51 rows
-- =========================================================

SELECT
    COUNT(*) AS state_rows
FROM vw_nces_state_capacity_50dc;
-- =========================================================
-- ACS COLUMN CHECK
-- Inspect the cleaned ACS fields before separating
-- state and unified-school-district geography.
-- =========================================================

DESCRIBE acs_community;
-- =========================================================
-- ACS GEOGRAPHY IDENTIFIER SAMPLE
-- Inspect geography IDs and labels so we can identify
-- exactly how state vs district rows are represented.
-- =========================================================

SELECT
    GEO_ID,
    FIPSST,
    *
FROM acs_community
LIMIT 20;
-- =========================================================
-- ACS STATE CONTEXT VIEW
-- One row per state
-- Filters the mixed ACS source to Census state geography
-- and restricts analysis to the 50 states + DC.
--
-- District-level ACS rows remain available separately in
-- the raw acs_community source for later analysis.
-- =========================================================

CREATE OR REPLACE VIEW vw_acs_state_context AS

SELECT *
FROM acs_community

WHERE GEO_ID LIKE '0400000US%'

  AND FIPSST IN (
      '01','02','04','05','06','08','09','10','11','12',
      '13','15','16','17','18','19','20','21','22','23',
      '24','25','26','27','28','29','30','31','32','33',
      '34','35','36','37','38','39','40','41','42','44',
      '45','46','47','48','49','50','51','53','54','55',
      '56'
  );
  SELECT
    GEO_ID,
    FIPSST,
    NAME
FROM vw_acs_state_context
ORDER BY FIPSST;
-- =========================================================
-- ACS COLUMN INVENTORY
-- Show all retained ACS variables and identify which
-- data profile each field came from.
-- =========================================================

SELECT
    column_name,
    CASE
        WHEN column_name LIKE 'DP02_%' THEN 'DP02 - Social'
        WHEN column_name LIKE 'DP03_%' THEN 'DP03 - Economic'
        WHEN column_name LIKE 'DP04_%' THEN 'DP04 - Housing'
        WHEN column_name LIKE 'DP05_%' THEN 'DP05 - Demographic'
        ELSE 'Geography / derived'
    END AS acs_profile
FROM information_schema.columns
WHERE table_name = 'acs_community'
ORDER BY
    acs_profile,
    column_name;
  -- =========================================================
-- ACS STATE CONTEXT QA
-- Expected: 51 rows, one for each state + DC
-- =========================================================

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT FIPSST) AS unique_state_fips
FROM vw_acs_state_context;
-- =========================================================
-- ACS PROFILE SUMMARY
-- Count retained variables by ACS data profile.
-- =========================================================

SELECT
    CASE
        WHEN column_name LIKE 'DP02_%' THEN 'DP02 - Social'
        WHEN column_name LIKE 'DP03_%' THEN 'DP03 - Economic'
        WHEN column_name LIKE 'DP04_%' THEN 'DP04 - Housing'
        WHEN column_name LIKE 'DP05_%' THEN 'DP05 - Demographic'
        ELSE 'Geography / derived'
    END AS acs_profile,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_name = 'acs_community'
GROUP BY 1
ORDER BY 1;
-- =========================================================
-- ACS CORE MEASURE INVENTORY
-- Display the main retained ACS measures used for
-- community vulnerability and contextual analysis.
--
-- E  = estimate/count or value
-- PE = percent estimate
-- PM = percent margin of error
-- =========================================================

SELECT
    FIPSST,
    NAME,

    -- =====================================================
    -- DP02: FAMILY / SOCIAL / ACCESS
    -- =====================================================

    DP02_0011PE AS pct_female_householder_with_children,

    DP02_0074PE AS pct_children_under_18_with_disability,

    DP02_0115PE AS pct_limited_english,

    DP02_0153PE AS pct_households_with_computer,

    DP02_0154PE AS pct_households_with_broadband,

    -- =====================================================
    -- DP03: ECONOMIC / INSURANCE / POVERTY
    -- =====================================================

    DP03_0009E AS unemployment_rate,

    DP03_0062E AS median_household_income,

    DP03_0074PE AS pct_households_receiving_snap,

    DP03_0101PE AS pct_under_19_uninsured,

    DP03_0120PE AS pct_families_with_children_below_poverty,

    DP03_0129PE AS pct_under_18_below_poverty,

    DP03_0132PE AS pct_children_5_17_below_poverty,

    -- =====================================================
    -- DP04: HOUSING / TRANSPORTATION
    -- =====================================================

    DP04_0058PE AS pct_no_vehicle_available,

    DP04_0078PE AS pct_crowded_1_01_to_1_50,

    DP04_0079PE AS pct_crowded_1_51_plus,

    DP04_0115PE AS pct_owner_cost_burden_35_plus,

    DP04_0142PE AS pct_rent_burden_35_plus,

    DP04_0134E AS median_gross_rent,

    -- =====================================================
    -- DP05: POPULATION / DEMOGRAPHIC CONTEXT
    -- =====================================================

    DP05_0001E AS total_population,

    DP05_0019PE AS pct_population_under_18,

    DP05_0045PE AS pct_black,

    DP05_0061PE AS pct_asian,

    DP05_0090PE AS pct_hispanic_latino

FROM vw_acs_state_context

ORDER BY FIPSST;
-- =========================================================
-- ACS STATE CORE CONTEXT VIEW
-- One row per state + DC
--
-- Curates the most interpretable ACS measures for
-- socioeconomic, family, insurance, housing, access,
-- and demographic context.
--
-- The full 176-column ACS source and state view remain intact.
-- =========================================================

CREATE OR REPLACE VIEW vw_acs_state_core_context AS

SELECT
    FIPSST AS state_fips,
    NAME AS state_name,

    -- =====================================================
    -- DP02: FAMILY / SOCIAL / ACCESS
    -- =====================================================

    DP02_0011PE AS pct_female_householder_with_children,
    DP02_0074PE AS pct_children_under_18_with_disability,
    DP02_0115PE AS pct_limited_english,
    DP02_0153PE AS pct_households_with_computer,
    DP02_0154PE AS pct_households_with_broadband,

    -- =====================================================
    -- DP03: ECONOMIC / INSURANCE / POVERTY
    -- =====================================================

    DP03_0009E AS unemployment_rate,
    DP03_0062E AS median_household_income,
    DP03_0074PE AS pct_households_receiving_snap,
    DP03_0101PE AS pct_under_19_uninsured,
    DP03_0120PE AS pct_families_with_children_below_poverty,
    DP03_0129PE AS pct_under_18_below_poverty,
    DP03_0132PE AS pct_children_5_17_below_poverty,

    -- =====================================================
    -- DP04: HOUSING / TRANSPORTATION
    -- =====================================================

    DP04_0058PE AS pct_no_vehicle_available,
    DP04_0078PE AS pct_crowded_1_01_to_1_50,
    DP04_0079PE AS pct_crowded_1_51_plus,
    DP04_0115PE AS pct_owner_cost_burden_35_plus,
    DP04_0142PE AS pct_rent_burden_35_plus,
    DP04_0134E AS median_gross_rent,

    -- =====================================================
    -- DP05: DEMOGRAPHIC CONTEXT
    -- =====================================================

    DP05_0001E AS total_population,
    DP05_0019PE AS pct_population_under_18,
    DP05_0045PE AS pct_black,
    DP05_0061PE AS pct_asian,
    DP05_0090PE AS pct_hispanic_latino

FROM vw_acs_state_context;
-- =========================================================
-- ACS STATE CORE CONTEXT QA
-- Expected: 51 rows / 51 unique states + DC
-- =========================================================

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_fips) AS unique_state_fips
FROM vw_acs_state_core_context;
-- =========================================================
-- ACS STATE CORE CONTEXT SAMPLE
-- =========================================================

SELECT *
FROM vw_acs_state_core_context
ORDER BY state_name
LIMIT 10;
-- =========================================================
-- HPSA STATE SHORTAGE VIEW
-- One row per state
--
-- Rolls one-row-per-HPSA designation records to state level.
-- Separates shortage scale from shortage severity.
-- =========================================================

CREATE OR REPLACE VIEW vw_hpsa_state_shortage AS

SELECT
    state_fips_code AS state_fips,
    MAX(primary_state_abbreviation) AS state_abbreviation,

    COUNT(*) AS hpsa_designation_count,

    MEDIAN(hpsa_score) AS median_hpsa_score,
    AVG(hpsa_score) AS mean_hpsa_score,

    SUM(designation_population) AS total_designation_population,
    SUM(estimated_served_population) AS total_estimated_served_population,
    SUM(estimated_underserved_population) AS total_estimated_underserved_population,

    SUM(hpsa_fte) AS total_hpsa_fte,
    SUM(hpsa_shortage) AS total_hpsa_shortage

FROM vw_hpsa_designations

WHERE state_fips_code IS NOT NULL

GROUP BY state_fips_code;
-- =========================================================
-- HPSA STATE SHORTAGE QA
-- Check number of state/territory rows before restricting
-- to the 50 states + DC.
-- =========================================================

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_fips) AS unique_state_fips
FROM vw_hpsa_state_shortage;
-- =========================================================
-- HPSA 50 STATES + DC SHORTAGE VIEW
-- Restricts state-level HPSA rollup to the 50 states + DC
-- for comparable cross-dataset state analysis.
-- =========================================================

CREATE OR REPLACE VIEW vw_hpsa_state_shortage_50dc AS

SELECT *
FROM vw_hpsa_state_shortage

WHERE state_fips IN (
    '01','02','04','05','06','08','09','10','11','12',
    '13','15','16','17','18','19','20','21','22','23',
    '24','25','26','27','28','29','30','31','32','33',
    '34','35','36','37','38','39','40','41','42','44',
    '45','46','47','48','49','50','51','53','54','55',
    '56'
);
-- =========================================================
-- HPSA 50 STATES + DC QA
-- Expected: 51 rows / 51 unique state FIPS codes
-- =========================================================

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_fips) AS unique_state_fips
FROM vw_hpsa_state_shortage_50dc;
SELECT *
FROM vw_hpsa_state_shortage_50dc
ORDER BY state_fips
LIMIT 10;
-- =========================================================
-- YRBSS STATE COLUMN CHECK
-- Inspect identifiers, year, survey weight, and retained
-- mental-health outcome fields before weighted aggregation.
-- =========================================================

DESCRIBE yrbss_state;
-- =========================================================
-- YRBSS STATE STRUCTURE CHECK
-- Confirm participating state identifiers and survey years.
-- =========================================================

SELECT DISTINCT
    sitecode,
    sitename,
    sitetype,
    year
FROM yrbss_state
ORDER BY
    year,
    sitename;
    -- =========================================================
-- YRBSS STATE BURDEN VIEW
-- One row per participating state/site and survey year.
--
-- Uses YRBSS survey weights to calculate weighted
-- prevalence for retained Boolean outcomes.
--
-- Missing responses are excluded from each outcome's
-- denominator rather than treated as FALSE / "No".
-- =========================================================

CREATE OR REPLACE VIEW vw_yrbss_state_burden AS

SELECT
    sitecode,
    sitename,
    sitetype,
    year,

    COUNT(*) AS respondent_count,

    -- =====================================================
    -- BULLYING
    -- =====================================================

    100.0 *
    SUM(weight) FILTER (
        WHERE bullied_at_school = TRUE
    )
    /
    NULLIF(
        SUM(weight) FILTER (
            WHERE bullied_at_school IS NOT NULL
        ),
        0
    ) AS pct_bullied_at_school,

    100.0 *
    SUM(weight) FILTER (
        WHERE electronically_bullied = TRUE
    )
    /
    NULLIF(
        SUM(weight) FILTER (
            WHERE electronically_bullied IS NOT NULL
        ),
        0
    ) AS pct_electronically_bullied,

    -- =====================================================
    -- MENTAL HEALTH / SUICIDALITY
    -- =====================================================

    100.0 *
    SUM(weight) FILTER (
        WHERE persistent_sadness_hopelessness = TRUE
    )
    /
    NULLIF(
        SUM(weight) FILTER (
            WHERE persistent_sadness_hopelessness IS NOT NULL
        ),
        0
    ) AS pct_persistent_sadness_hopelessness,

    100.0 *
    SUM(weight) FILTER (
        WHERE considered_suicide = TRUE
    )
    /
    NULLIF(
        SUM(weight) FILTER (
            WHERE considered_suicide IS NOT NULL
        ),
        0
    ) AS pct_considered_suicide,

    100.0 *
    SUM(weight) FILTER (
        WHERE made_suicide_plan = TRUE
    )
    /
    NULLIF(
        SUM(weight) FILTER (
            WHERE made_suicide_plan IS NOT NULL
        ),
        0
    ) AS pct_made_suicide_plan,

    -- =====================================================
    -- ADVERSE EXPERIENCE
    -- =====================================================

    100.0 *
    SUM(weight) FILTER (
        WHERE parent_guardian_incarceration = TRUE
    )
    /
    NULLIF(
        SUM(weight) FILTER (
            WHERE parent_guardian_incarceration IS NOT NULL
        ),
        0
    ) AS pct_parent_guardian_incarceration

FROM yrbss_state

WHERE weight IS NOT NULL

GROUP BY
    sitecode,
    sitename,
    sitetype,
    year;
    -- =========================================================
-- YRBSS STATE BURDEN QA
-- Confirm one row per state/site-year combination.
-- =========================================================

SELECT
    COUNT(*) AS state_year_rows,
    COUNT(
        DISTINCT sitecode || '-' || CAST(year AS VARCHAR)
    ) AS unique_state_years
FROM vw_yrbss_state_burden;
SELECT *
FROM vw_yrbss_state_burden
ORDER BY year DESC, sitename
LIMIT 20;
-- =========================================================
-- YRBSS 2023 STATE COVERAGE CHECK
-- Inspect participating 2023 state samples before joining
-- them to the 50 states + DC contextual layer.
--
-- Partial-state samples must not be treated as whole-state
-- estimates.
-- =========================================================

SELECT
    sitecode,
    sitename,
    respondent_count,

    CASE
        WHEN LOWER(sitename) LIKE '%excluding%'
        THEN 'Partial state sample'
        ELSE 'Candidate full state sample'
    END AS coverage_type

FROM vw_yrbss_state_burden

WHERE year = 2023
  AND sitetype = 'State'

ORDER BY sitename;
-- =========================================================
-- YRBSS 2023 PARTICIPATION SUMMARY
-- =========================================================

SELECT
    COUNT(*) AS participating_state_sites,

    SUM(
        CASE
            WHEN LOWER(sitename) LIKE '%excluding%'
            THEN 1
            ELSE 0
        END
    ) AS partial_state_sites

FROM vw_yrbss_state_burden

WHERE year = 2023
  AND sitetype = 'State';
  -- =========================================================
-- YRBSS 2023 FULL-STATE BURDEN VIEW
-- Keeps only 2023 state samples that represent the full
-- participating state jurisdiction.
--
-- Partial-state samples such as New York excluding NYC
-- are excluded from whole-state cross-dataset comparison.
-- =========================================================

CREATE OR REPLACE VIEW vw_yrbss_state_burden_2023 AS

SELECT *
FROM vw_yrbss_state_burden

WHERE year = 2023
  AND sitetype = 'State'
  AND LOWER(sitename) NOT LIKE '%excluding%';
  -- =========================================================
-- YRBSS 2023 FULL-STATE QA
-- Expected: 27 comparable full-state sites
-- =========================================================

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT sitecode) AS unique_state_sites
FROM vw_yrbss_state_burden_2023;
SELECT
    sitecode,
    sitename,
    respondent_count,
    pct_persistent_sadness_hopelessness,
    pct_considered_suicide,
    pct_made_suicide_plan
FROM vw_yrbss_state_burden_2023
ORDER BY sitename;
-- =========================================================
-- NSCH MENTAL-HEALTH FIELD CHECK
-- Identify the exact retained variables for mental-health
-- need, care access, diagnoses, and the constructed
-- unmet-care outcome before state-level aggregation.
-- =========================================================

SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'nsch_children'
  AND (
      LOWER(column_name) LIKE '%mental%'
      OR LOWER(column_name) LIKE '%unmet%'
      OR LOWER(column_name) LIKE '%care%'
      OR LOWER(column_name) LIKE '%anxiety%'
      OR LOWER(column_name) LIKE '%depress%'
      OR LOWER(column_name) LIKE '%adhd%'
  )
ORDER BY column_name;
-- =========================================================
-- NSCH STATE + WEIGHT CHECK
-- Confirm the state and survey-weight fields needed for
-- weighted state summaries.
-- =========================================================
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'nsch_children'
  AND column_name IN (
      'state_fips_code',
      'final_sampling_weight'
  );
  -- =========================================================
-- NSCH MENTAL HEALTH ACCESS VIEW
-- One row per child in the primary access-analysis cohort.
--
-- Population:
--   Ages 6–17 already enforced in the cleaned source
--   AND current anxiety, depression, or ADHD
--   AND valid mental-health care need/access response
--
-- Outcome:
--   0 = received needed mental-health care
--   1 = needed mental-health care but did not receive it
-- =========================================================

SELECT
    COUNT(*) AS children_needing_care,

    SUM(
        CASE
            WHEN unmet_mental_health_care = 1 THEN 1
            ELSE 0
        END
    ) AS children_with_unmet_care,

    ROUND(
        100.0 *
        AVG(unmet_mental_health_care),
        2
    ) AS unweighted_unmet_care_pct

FROM vw_nsch_mental_health_access;
-- =========================================================

-CREATE OR REPLACE VIEW vw_nsch_mental_health_access AS

SELECT
    *,

    CASE
        WHEN MentHCare_24 = 1 THEN 0
        WHEN MentHCare_24 = 2 THEN 1
    END AS unmet_mental_health_care

FROM nsch_children

WHERE MentHCare_24 IN (1, 2);
SELECT
    COUNT(*) AS children_needing_care,

    SUM(
        CASE
            WHEN unmet_mental_health_care = 1 THEN 1
            ELSE 0
        END
    ) AS children_with_unmet_care,

    ROUND(
        100.0 * AVG(unmet_mental_health_care),
        2
    ) AS unweighted_unmet_care_pct
FROM vw_nsch_mental_health_access;
-- =========================================================
-- NSCH STATE SUMMARY
-- One row per state
-- =========================================================

CREATE OR REPLACE VIEW vw_nsch_state_summary AS

SELECT
    LPAD(
        CAST(state_fips_code AS VARCHAR),
        2,
        '0'
    ) AS state_fips,

    COUNT(*) AS access_cohort_sample_n,

    SUM(
        CASE
            WHEN unmet_mental_health_care = 1 THEN 1
            ELSE 0
        END
    ) AS unmet_care_sample_n,

    SUM(final_sampling_weight) AS weighted_access_population,

    SUM(
        CASE
            WHEN unmet_mental_health_care = 1
            THEN final_sampling_weight
            ELSE 0
        END
    ) AS weighted_unmet_care_population,

    100.0 *
    SUM(
        CASE
            WHEN unmet_mental_health_care = 1
            THEN final_sampling_weight
            ELSE 0
        END
    )
    /
    NULLIF(SUM(final_sampling_weight), 0)
        AS pct_unmet_mental_health_care

FROM vw_nsch_mental_health_access

WHERE
    state_fips_code IS NOT NULL
    AND final_sampling_weight IS NOT NULL

GROUP BY state_fips_code;
SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_fips) AS unique_state_fips
FROM vw_nsch_state_summary;
SELECT *
FROM vw_nsch_state_summary
ORDER BY state_fips;
-- =========================================================
-- STATE DIMENSION
-- One row per state + DC
--
-- Uses NCES as the 51-state backbone and standardizes
-- state FIPS to two-character text for cross-source joins.
-- =========================================================

CREATE OR REPLACE VIEW dim_state AS

SELECT
    LPAD(
        CAST(FIPST AS VARCHAR),
        2,
        '0'
    ) AS state_fips,

    state_name,
    state_abbreviation

FROM vw_nces_state_capacity_50dc;
SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_fips) AS unique_state_fips,
    COUNT(DISTINCT state_abbreviation) AS unique_state_abbreviations
FROM dim_state;
-- =========================================================
-- FINAL STATE CONTEXT VIEW
-- One row per state + DC
--
-- Combines:
--   NCES  - school staffing/capacity
--   ACS   - community socioeconomic context
--   HPSA  - mental-health provider shortage
--   NSCH  - unmet pediatric mental-health care
--   YRBSS - adolescent distress / risk indicators
--
-- IMPORTANT:
-- YRBSS 2023 contains only participating full-state
-- samples. Nonparticipating states remain NULL, not zero.
--
-- Source years differ and should remain explicit:
--   NCES membership/staff: 2024-25
--   NCES fiscal:          2022-23
--   ACS:                  2024
--   NSCH:                 2024
--   YRBSS:                2023
--   HPSA:                 2026 snapshot
-- =========================================================

CREATE OR REPLACE VIEW vw_state_context AS

SELECT

    -- =====================================================
    -- STATE IDENTITY
    -- =====================================================

    d.state_fips,
    d.state_name,
    d.state_abbreviation,


    -- =====================================================
    -- NSCH 2024
    -- PEDIATRIC MENTAL-HEALTH ACCESS
    -- =====================================================

    nsch.access_cohort_sample_n AS nsch_access_cohort_sample_n,
    nsch.unmet_care_sample_n AS nsch_unmet_care_sample_n,
    nsch.weighted_access_population AS nsch_weighted_access_population,
    nsch.weighted_unmet_care_population AS nsch_weighted_unmet_care_population,
    nsch.pct_unmet_mental_health_care AS nsch_pct_unmet_mental_health_care,


    -- =====================================================
    -- YRBSS 2023
    -- ADOLESCENT DISTRESS / RISK
    -- =====================================================

    yr.respondent_count AS yrbss_respondent_count,
    yr.pct_bullied_at_school AS yrbss_pct_bullied_at_school,
    yr.pct_electronically_bullied AS yrbss_pct_electronically_bullied,
    yr.pct_persistent_sadness_hopelessness
        AS yrbss_pct_persistent_sadness_hopelessness,
    yr.pct_considered_suicide
        AS yrbss_pct_considered_suicide,
    yr.pct_made_suicide_plan
        AS yrbss_pct_made_suicide_plan,
    yr.pct_parent_guardian_incarceration
        AS yrbss_pct_parent_guardian_incarceration,


    -- =====================================================
    -- NCES
    -- SCHOOL CAPACITY
    -- =====================================================

    nces.district_count AS nces_district_count,
    nces.total_students AS nces_total_students,

    nces.total_guidance_counselors
        AS nces_total_guidance_counselors,

    nces.total_school_counselors
        AS nces_total_school_counselors,

    nces.total_school_psychologists
        AS nces_total_school_psychologists,

    nces.total_student_support_staff
        AS nces_total_student_support_staff,

    nces.total_teachers
        AS nces_total_teachers,

    nces.students_per_guidance_counselor
        AS nces_students_per_guidance_counselor,

    nces.students_per_school_counselor
        AS nces_students_per_school_counselor,

    nces.students_per_school_psychologist
        AS nces_students_per_school_psychologist,

    nces.students_per_student_support_staff
        AS nces_students_per_student_support_staff,

    nces.students_per_teacher
        AS nces_students_per_teacher,


    -- =====================================================
    -- HPSA 2026 SNAPSHOT
    -- MENTAL-HEALTH PROVIDER SHORTAGE
    -- =====================================================

    h.hpsa_designation_count,
    h.median_hpsa_score,
    h.mean_hpsa_score,
    h.total_designation_population,
    h.total_estimated_served_population,
    h.total_estimated_underserved_population,
    h.total_hpsa_fte,
    h.total_hpsa_shortage,


    -- =====================================================
    -- ACS 2024
    -- FAMILY / SOCIAL CONTEXT
    -- =====================================================

    acs.pct_female_householder_with_children,
    acs.pct_children_under_18_with_disability,
    acs.pct_limited_english,
    acs.pct_households_with_computer,
    acs.pct_households_with_broadband,


    -- =====================================================
    -- ACS 2024
    -- ECONOMIC / INSURANCE / POVERTY
    -- =====================================================

    acs.unemployment_rate,
    acs.median_household_income,
    acs.pct_households_receiving_snap,
    acs.pct_under_19_uninsured,
    acs.pct_families_with_children_below_poverty,
    acs.pct_under_18_below_poverty,
    acs.pct_children_5_17_below_poverty,


    -- =====================================================
    -- ACS 2024
    -- HOUSING / TRANSPORT
    -- =====================================================

    acs.pct_no_vehicle_available,
    acs.pct_crowded_1_01_to_1_50,
    acs.pct_crowded_1_51_plus,
    acs.pct_owner_cost_burden_35_plus,
    acs.pct_rent_burden_35_plus,
    acs.median_gross_rent,


    -- =====================================================
    -- ACS 2024
    -- DEMOGRAPHIC CONTEXT
    -- =====================================================

    acs.total_population,
    acs.pct_population_under_18,
    acs.pct_black,
    acs.pct_asian,
    acs.pct_hispanic_latino,


    -- =====================================================
    -- COVERAGE FLAGS
    -- Lets us distinguish unavailable data from true zero.
    -- =====================================================

    CASE
        WHEN nsch.state_fips IS NOT NULL THEN 1
        ELSE 0
    END AS has_nsch_data,

    CASE
        WHEN yr.sitecode IS NOT NULL THEN 1
        ELSE 0
    END AS has_yrbss_2023_data,

    CASE
        WHEN nces.FIPST IS NOT NULL THEN 1
        ELSE 0
    END AS has_nces_data,

    CASE
        WHEN h.state_fips IS NOT NULL THEN 1
        ELSE 0
    END AS has_hpsa_data,

    CASE
        WHEN acs.state_fips IS NOT NULL THEN 1
        ELSE 0
    END AS has_acs_data


FROM dim_state d


LEFT JOIN vw_nsch_state_summary nsch
    ON d.state_fips = nsch.state_fips


LEFT JOIN vw_yrbss_state_burden_2023 yr
    ON d.state_abbreviation = yr.sitecode


LEFT JOIN vw_nces_state_capacity_50dc nces
    ON d.state_fips =
       LPAD(CAST(nces.FIPST AS VARCHAR), 2, '0')


LEFT JOIN vw_hpsa_state_shortage_50dc h
    ON d.state_fips = h.state_fips


LEFT JOIN vw_acs_state_core_context acs
    ON d.state_fips = acs.state_fips;
    -- =========================================================
-- FINAL STATE CONTEXT QA
-- Must remain exactly one row per state + DC.
-- =========================================================

SELECT
    COUNT(*) AS state_rows,
    COUNT(DISTINCT state_fips) AS unique_state_fips,
    COUNT(DISTINCT state_abbreviation) AS unique_states
FROM vw_state_context;
-- =========================================================
-- FINAL STATE CONTEXT SOURCE COVERAGE
-- YRBSS should be 27.
-- Other state-level sources should generally be 51.
-- =========================================================

SELECT
    SUM(has_nsch_data) AS states_with_nsch,
    SUM(has_yrbss_2023_data) AS states_with_yrbss_2023,
    SUM(has_nces_data) AS states_with_nces,
    SUM(has_hpsa_data) AS states_with_hpsa,
    SUM(has_acs_data) AS states_with_acs
FROM vw_state_context;
SELECT *
FROM vw_state_context
ORDER BY state_name;