-- ============================================================
-- GLP-1 FAERS Case Study
-- SQL Analysis
-- BigQuery
-- ============================================================


-- 1. Report counts by drug
-- report_level contains one row per safety report.

SELECT
    generic_name,
    COUNT(*) AS reports
FROM `savvy-serenity-499215-a3.glp1_faers.report_level`
GROUP BY generic_name
ORDER BY reports DESC;


-- 2. Validate report counts using reaction-level data
-- DISTINCT is required because one safety report may contain
-- multiple adverse reactions.

SELECT
    generic_name,
    COUNT(DISTINCT safetyreportid) AS reports
FROM `savvy-serenity-499215-a3.glp1_faers.reaction_level`
GROUP BY generic_name
ORDER BY reports DESC;


-- 3. Full post-approval safety metrics

SELECT
    generic_name,
    COUNT(*) AS reports,
    AVG(CAST(serious AS INT64)) * 100 AS serious_pct,
    AVG(CAST(seriousness_hospitalization AS INT64)) * 100 AS hospitalization_pct,
    AVG(CAST(seriousness_death AS INT64)) * 100 AS death_pct,
    AVG(CAST(seriousness_lifethreatening AS INT64)) * 100 AS life_threatening_pct,
    AVG(CAST(seriousness_disabling AS INT64)) * 100 AS disabling_pct
FROM `savvy-serenity-499215-a3.glp1_faers.report_level`
GROUP BY generic_name
ORDER BY reports DESC;


-- 4. Safety metrics for the comparable full-year period
-- 2018-2022 was selected because 2023 is incomplete for liraglutide.

SELECT
    generic_name,
    COUNT(*) AS reports,
    AVG(CAST(serious AS INT64)) * 100 AS serious_pct,
    AVG(CAST(seriousness_hospitalization AS INT64)) * 100 AS hospitalization_pct,
    AVG(CAST(seriousness_death AS INT64)) * 100 AS death_pct,
    AVG(CAST(seriousness_lifethreatening AS INT64)) * 100 AS life_threatening_pct,
    AVG(CAST(seriousness_disabling AS INT64)) * 100 AS disabling_pct
FROM `savvy-serenity-499215-a3.glp1_faers.report_level`
WHERE report_year BETWEEN 2018 AND 2022
GROUP BY generic_name
ORDER BY reports DESC;


-- 5. All adverse reactions by drug: full post-approval history

SELECT
    generic_name,
    reaction,
    COUNT(DISTINCT safetyreportid) AS reports
FROM `savvy-serenity-499215-a3.glp1_faers.reaction_level`
GROUP BY generic_name, reaction
ORDER BY generic_name, reports DESC;


-- 6. Top 10 adverse reactions per drug during 2018-2022

SELECT
    generic_name,
    reaction,
    COUNT(DISTINCT safetyreportid) AS reports
FROM `savvy-serenity-499215-a3.glp1_faers.reaction_level`
WHERE report_year BETWEEN 2018 AND 2022
GROUP BY generic_name, reaction
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY generic_name
    ORDER BY COUNT(DISTINCT safetyreportid) DESC
) <= 10
ORDER BY generic_name, reports DESC;


-- 7. Percentage of reports mentioning each reaction during 2018-2022

WITH reaction_counts AS (
    SELECT
        generic_name,
        reaction,
        COUNT(DISTINCT safetyreportid) AS reports_with_reaction
    FROM `savvy-serenity-499215-a3.glp1_faers.reaction_level`
    WHERE report_year BETWEEN 2018 AND 2022
    GROUP BY generic_name, reaction
),

report_totals AS (
    SELECT
        generic_name,
        COUNT(*) AS total_reports
    FROM `savvy-serenity-499215-a3.glp1_faers.report_level`
    WHERE report_year BETWEEN 2018 AND 2022
    GROUP BY generic_name
)

SELECT
    r.generic_name,
    r.reaction,
    r.reports_with_reaction,
    t.total_reports,
    r.reports_with_reaction / t.total_reports * 100 AS report_pct
FROM reaction_counts AS r
JOIN report_totals AS t
    ON r.generic_name = t.generic_name
ORDER BY r.generic_name, report_pct DESC;

-- SQL validation summary:
-- BigQuery reproduced the main Python results for report counts,
-- safety metrics, and adverse-reaction rankings.
-- The primary comparison period used was 2018-2022.