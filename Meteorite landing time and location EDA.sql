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

-- look at the numbers of meteorite falls after year 2000
SELECT year
    , COUNT(name) AS [numbers of meteorite falls]
FROM MeteoriteLanding
WHERE year >= '2000-01-01'
    AND fall = 'fell'
GROUP BY year
ORDER BY 
    year
    --[numbers of meteorite falls] DESC
;

-- check the top 5 year that has the most meteorite found and fall
SELECT TOP 5 year
    , COUNT(fall) AS [number_of_fell_meteorites]
FROM MeteoriteLanding
WHERE fall = 'Fell'
GROUP BY year
ORDER BY [number_of_fell_meteorites] DESC;

SELECT year
    , COUNT(fall) AS [number_of_found_meteorites]
FROM MeteoriteLanding
WHERE fall = 'Found'
GROUP BY year
ORDER BY [number_of_found_meteorites] DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY; -- another way of fetch top numbers of rows


/* two other ways of aggregation
-- 1.
WITH FellMeteorites AS (
    SELECT
        year,
        'Fell' AS fall,
        COUNT(fall) AS [number_of_meteorites],
        ROW_NUMBER() OVER (ORDER BY COUNT(fall) DESC) AS rn
    FROM
        MeteoriteLanding
    WHERE
        fall = 'Fell'
    GROUP BY
        year
),
FoundMeteorites AS (
    SELECT
        year,
        'Found' AS fall,
        COUNT(fall) AS [number_of_meteorites],
        ROW_NUMBER() OVER (ORDER BY COUNT(fall) DESC) AS rn
    FROM
        MeteoriteLanding
    WHERE
        fall = 'Found'
    GROUP BY
        year
)
SELECT
    year,
    fall,
    [number_of_meteorites]
FROM
    FellMeteorites
WHERE
    rn <= 5

UNION ALL

SELECT
    year,
    fall,
    [number_of_meteorites]
FROM
    FoundMeteorites
WHERE
    rn <= 5;


-- 2.
WITH RankedMeteorites AS (
    SELECT
        year,
        fall,
        COUNT(fall) AS [number_of_meteorites],
        ROW_NUMBER() OVER (PARTITION BY fall ORDER BY COUNT(fall) DESC) AS rn
    FROM
        MeteoriteLanding
    GROUP BY
        year,
        fall
)
SELECT
    year,
    fall,
    [number_of_meteorites]
FROM
    RankedMeteorites
WHERE
    rn <= 5
ORDER BY
    fall,
    [number_of_meteorites] DESC;
*/

-- think about combine the mass?