-- two ways of checking databases in sql server

sp_databases;

SELECT name, database_id, create_date
FROM sys.databases;

-- go to the database needed to work on
USE Meteorite;
GO

-- check tables
SELECT * FROM MeteoriteInfo
--ORDER BY 2, 3
;

SELECT * FROM MeteoriteMass
--ORDER BY name
;

SELECT * FROM MeteoriteLanding
ORDER BY name, year
;


/* Old script for future reference!! (ignore)
-- Narrow down the data
SELECT name, recclass, year, mass
FROM MeteoriteMass
ORDER BY 2, 3;

-- if adding one column based on other existing columns, we can do select (column 1/column 2)*100 as new_column_name

-- Modify the table LandingInfo
SELECT name, recclass, fall, year, reclat, reclong
FROM LandingInfo
ORDER BY 2, 4;

-- ALTER TABLE LandingInfo
-- DROP COLUMN computed_region_cbhk_fwbd, computed_region_nnqa_25f4;

SELECT *
FROM LandingInfo
ORDER BY name, recclass;
*/

ALTER TABLE MeteoriteLanding
DROP COLUMN IF EXISTS country;

ALTER TABLE MeteoriteLanding
ADD country VARCHAR(256);

-- Remove missing values or 0 values
--DELETE FROM MeteoriteLanding
--WHERE (reclat = 0 OR reclat IS NULL)
--  AND (reclong = 0 OR reclong IS NULL)
--  AND (reclat > 90 OR reclat < -90)
--  AND (reclong > 180 OR reclong < -180)




-- Generate new geography type column with the existing lat and long info
ALTER TABLE MeteoriteLanding
DROP COLUMN IF EXISTS location;

ALTER TABLE MeteoriteLanding
ADD location geography;

SELECT * FROM MeteoriteLanding;

UPDATE MeteoriteLanding
SET location = geography::Point(reclat, reclong, 4326)
WHERE (reclat <> 0) AND (reclong <> 0) AND (reclat >= -90) and (reclat <= 90) and (reclat IS NOT NULL) AND (reclong IS NOT NULL)
;

 --SELECT *, 
 --    geography::STGeomFromText('POINT(' + CAST([reclat] AS VARCHAR(20)) + ' ' + CAST([reclong] AS VARCHAR(20)) + ')', 4326) as GEOM,
 --    geography::Point([reclat], [reclong], 4326) as SAME_GEOM
 --FROM MeteoriteLanding
 --WHERE (reclat <> 0) AND (reclong <> 0) AND (reclat >= -90) and (reclat <= 90) and (reclat IS NOT NULL) AND (reclong IS NOT NULL)

--SELECT location.STAsText() AS wkt_representation
--FROM MeteoriteLanding;

/* an alternative way of generating geographical column 
UPDATE MeteoriteLanding
SET location = geography::STGeomFromText('POINT(' + CONVERT(VARCHAR(30), [reclong]) + ' ' + CONVERT(VARCHAR(30), [reclat]) + ')', 4326)
WHERE (reclat <> 0) AND (reclong <> 0) AND (reclat >= -90) and (reclat <= 90) and (reclat IS NOT NULL) AND (reclong IS NOT NULL)
*/

SELECT * FROM sys.spatial_reference_systems WHERE spatial_reference_id = 4326;

-- Populate the new country column with actual values
-- use country info from another database to see if the point falls into any country
-- if so, append the country name
UPDATE MeteoriteLanding
SET country = AC.name
FROM MeteoriteLanding AS ML
JOIN Country.dbo.AdministrativeCountries AS AC
ON (CASE
        WHEN AC.geom.MakeValid().STArea() > AC.geom.MakeValid().ReorientObject().STArea()
            THEN AC.geom.MakeValid().ReorientObject()
        ELSE AC.geom.MakeValid()
      END).STIntersects(ML.location.MakeValid()) = 1;


/*
-- insert non-administrative country names
ALTER TABLE MeteoriteLanding
DROP COLUMN IF EXISTS country_nonadmin;

ALTER TABLE MeteoriteLanding
ADD country_nonadmin VARCHAR(256);

UPDATE MeteoriteLanding
SET country_nonadmin = WC.country
FROM MeteoriteLanding AS ML
JOIN Country.dbo.WorldCountries AS WC
ON (CASE
        WHEN WC.geom.MakeValid().STArea() > WC.geom.MakeValid().ReorientObject().STArea()
            THEN WC.geom.MakeValid().ReorientObject()
        ELSE WC.geom.MakeValid()
      END).STIntersects(ML.location.MakeValid()) = 1;
*/


-- check the populated values
SELECT name, year, fall, location 
	, location.ToString() AS geostring
	, country
	, country_nonadmin
FROM MeteoriteLanding
-- WHERE country IS NOT NULL
ORDER BY country;

-- inner join three tables
SELECT MI.id, MI.name, MI.nametype, MI.recclass, MI.fall
	, MM.[mass (g)]
	, ML.year, ML.country, ML.geolocation, ML.location
	, ML.country_nonadmin
FROM MeteoriteInfo AS MI 
	INNER JOIN MeteoriteMass AS MM
		ON MI.id = MM.id
	INNER JOIN MeteoriteLanding AS ML
		ON MI.id = ML.id

-- update continent and region info also for Tableau viz
ALTER TABLE MeteoriteLanding
DROP COLUMN IF EXISTS continent

ALTER TABLE MeteoriteLanding
ADD continent VARCHAR(256);

ALTER TABLE MeteoriteLanding
DROP COLUMN IF EXISTS region;

ALTER TABLE MeteoriteLanding
ADD region VARCHAR(256);

/*
IF EXISTS (SELECT * FROM sys.columns 
           WHERE Name = N'continent' AND Object_ID = Object_ID(N'MeteoriteLanding'))
BEGIN
    ALTER TABLE MeteoriteLanding
    DROP COLUMN continent;
END
*/

UPDATE MeteoriteLanding
SET region = AC.region
	, continent = AC.continent
FROM MeteoriteLanding AS ML
JOIN Country.dbo.AdministrativeCountries AS AC
ON (CASE
        WHEN AC.geom.MakeValid().STArea() > AC.geom.MakeValid().ReorientObject().STArea()
            THEN AC.geom.MakeValid().ReorientObject()
        ELSE AC.geom.MakeValid()
      END).STIntersects(ML.location.MakeValid()) = 1;
