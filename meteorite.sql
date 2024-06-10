-- two ways of checking databases in sql server

sp_databases;

SELECT name, database_id, create_date
FROM sys.databases;

-- go to the database needed to work on
USE Meteorite;
GO

-- check tables
SELECT * FROM MeteoriteInfo
--order by 2, 3
;

SELECT * FROM MeteoriteMass
--order by name
;

SELECT * FROM MeteoriteLanding
order by name, year
;


/* Old script for future reference!! (ignore)
-- Narrow down the data used
SELECT name, recclass, year, mass
FROM MeteoriteMass
order by 2, 3;

-- if adding one column based on other existing columns, we can do select (column 1/column 2)*100 as new_column_name


-- Modify the table LandingInfo
SELECT name, recclass, fall, year, reclat, reclong
FROM LandingInfo
ORDER BY 2, 4;

-- ALTER TABLE LandingInfo
-- DROP COLUMN computed_region_cbhk_fwbd, computed_region_nnqa_25f4;

SELECT *
FROM LandingInfo
order by name, recclass;
*/

ALTER TABLE LandingInfo
ADD country VARCHAR(256);

-- Remove missing values or 0 values
DELETE FROM LandingInfo
WHERE (reclat = 0 OR reclat IS NULL)
  AND (reclong = 0 OR reclong IS NULL)

DELETE FROM LandingInfo
WHERE (reclat > 90 OR reclat < -90)
  AND (reclong > 180 OR reclong < -180)

-- SELECT *, 
--     geography::STGeomFromText('POINT(' + CAST([reclat] AS VARCHAR(20)) + ' ' + CAST([reclong] AS VARCHAR(20)) + ')', 4326) as GEOM,
--     geography::Point([reclat], [reclong], 4326) as SAME_GEOM
-- FROM LandingInfo
-- WHERE (reclat <> 0) AND (reclong <> 0) AND (reclat >= -90) and (reclat <= 90) and (reclat IS NOT NULL) AND (reclong IS NOT NULL)


-- Generate new geography type column with the existing lat and long info
ALTER TABLE LandingInfo 
DROP COLUMN IF EXISTS location;

ALTER TABLE LandingInfo 
ADD location geography;

UPDATE LandingInfo
SET location = geography::Point(reclat, reclong, 4326);

SELECT location.STAsText() AS wkt_representation
FROM LandingInfo;

-- an alternative way of generating geographical column 
UPDATE LandingInfo
SET location = geography::STGeomFromText('POINT(' + CONVERT(VARCHAR(30), [reclong]) + ' ' + CONVERT(VARCHAR(30), [reclat]) + ')', 4326);

-- SELECT * FROM sys.spatial_reference_systems WHERE spatial_reference_id = 4326;

-- Populate the new country column with actual values
SELECT name, recclass, location.ToString() as geostring, country
From LandingInfo;

Select * from WorldCountry -- This table was created after various effort, containing country name and its corresponding geographical info
order by name;  

UPDATE LandingInfo
SET LandingInfo.country = WorldCountry.name
FROM WorldCountry
WHERE geography::STGeomFromText(LandingInfo.location.STAsText(), 4326).MakeValid().STIntersects(WorldCountry.WKT_geom.MakeValid()) = 1;

Select name, recclass, fall, year, country
From LandingInfo
order by country;


SELECT name, recclass, mass, year, AVG(mass) OVER (partition by recclass) as averagemass
From MeteoriteMass
order by averagemass;

SELECT LandingInfo.name, LandingInfo.recclass, LandingInfo.fall,
        LandingInfo.year, LandingInfo.location, LandingInfo.country,
        LandingInfo.geolocation, LandingInfo.country1, MeteoriteMass.mass, MeteoriteMass.nametype
FROM LandingInfo INNER JOIN MeteoriteMass 
    ON LandingInfo.name = MeteoriteMass.name