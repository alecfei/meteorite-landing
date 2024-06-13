USE Meteorite;
GO

-- check the rows that has country value in MeteoriteLanding
SELECT * FROM MeteoriteLanding
WHERE country IS NOT NULL;

SELECT * FROM MeteoriteLanding
WHERE country_nonadmin IS NOT NULL
AND country_nonadmin <> 'Antarctica';   --both retrieve 9822 rows!

-- look at the numbers of countries that meteorite has landed in
SELECT COUNT(DISTINCT country) 
AS distinct_country
FROM MeteoriteLanding         -- by default, DISTINCT doesn't count NULL values

-- including null
SELECT COUNT(DISTINCT 
              CASE 
                WHEN country IS NULL THEN 'NULL' 
                ELSE country 
              END) AS distinct_count
FROM MeteoriteLanding;

-- SELECT COUNT(*)
-- FROM (
--   SELECT DISTINCT country, country_nonadmin
--   FROM MeteoriteLanding
--   WHERE country IS NOT NULL AND country_nonadmin IS NOT NULL
-- ) AS distinct_country_value;

-- look at the numbers of recclasses of meteorites
SELECT recclass
  , COUNT(*) AS numberofrecclass
FROM MeteoriteInfo
GROUP BY recclass
ORDER BY COUNT(*) DESC;

-- look at top (ten) countries the meteorites landed in
SELECT TOP 10 country
  , COUNT(*) AS [landing counts]
FROM MeteoriteLanding
--WHERE country IS NOT NULL
GROUP BY country
ORDER BY COUNT(*) DESC;

SELECT country_nonadmin
  , COUNT(*) AS [landing counts]
FROM MeteoriteLanding
--WHERE country IS NOT NULL
GROUP BY country_nonadmin
ORDER BY COUNT(*) DESC;

-- look at the details of meteorites that landed in Ireland
--CREATE VIEW MeteoriteLandingInIreland AS
SELECT MI.id, MI.name, MI.nametype, MI.recclass, MI.fall
	, MM.[mass (g)]
	, ML.year, ML.country, ML.geolocation
FROM MeteoriteInfo AS MI 
	INNER JOIN MeteoriteMass AS MM
		ON MI.id = MM.id
	INNER JOIN MeteoriteLanding AS ML
		ON MI.id = ML.id
WHERE ML.country = 'Ireland'
;


-- look at the average landing counts across all the countries
WITH LandingCounts AS (
    SELECT country, COUNT(*) AS landing_count
    FROM MeteoriteLanding
    WHERE country IS NOT NULL
    GROUP BY country
)
SELECT AVG(landing_count) AS [average landing counts]
FROM LandingCounts
;