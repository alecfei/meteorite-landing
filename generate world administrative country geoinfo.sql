SELECT TOP (1000) [continent]
      ,[region]
      ,[name]
      ,[id]
      ,[WKT]
  FROM [Country].[dbo].[AdminstrativeCountries]


ALTER TABLE AdministrativeCountries
DROP COLUMN IF EXISTS geom;

ALTER TABLE AdministrativeCountries
ADD geom geography;

SELECT * FROM AdministrativeCountries;

UPDATE AdministrativeCountries
SET geom = geography::STGeomFromText(CONVERT(nvarchar(max), WKT), 4326)

SELECT name, WKT, geom.ToString() as converted
FROM AdministrativeCountries;

DECLARE @point GEOGRAPHY = GEOGRAPHY::Point(50.775, 6.08333, 4326);

-- Ensure the point is valid
SET @point = @point.MakeValid();

-- Query the table to check for intersections, ensuring polygons are correctly oriented
SELECT name
FROM AdministrativeCountries
WHERE (CASE
        WHEN geom.MakeValid().STArea() > geom.MakeValid().ReorientObject().STArea()
            THEN geom.MakeValid().ReorientObject()
        ELSE geom.MakeValid()
      END).STIntersects(@point) = 1;