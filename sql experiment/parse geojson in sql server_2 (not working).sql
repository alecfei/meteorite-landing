DROP TABLE IF EXISTS dbo.Country
 
CREATE TABLE dbo.Country
(
	Id int IDENTITY PRIMARY KEY,
	country nvarchar(300),
	[type] nvarchar(300),
	Coordinates GEOGRAPHY
)

DECLARE @JSON nvarchar(max)
 
-- Load the GeoJSON into the variable
SELECT @JSON = BulkColumn
FROM OPENROWSET (BULK 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQL_WINDOWMS\MSSQL\DATA\Longitude_Graticules_and_World_Countries_Boundaries.geojson', 
				 SINGLE_CLOB) as JSON
 
-- Insert into dbo.Country table
INSERT INTO dbo.Country (country, [type], Coordinates)
SELECT country, [type], Coordinates
FROM OPENJSON (@Json, '$.features')
WITH
(
    country nvarchar(300) '$.properties.CNTRY_NAME',
    [type] nvarchar(300) '$.geometry.type',
    Coordinates NVARCHAR(max) '$.geometry.coordinates' AS json
) AS GeoData
OUTER APPLY (
    -- Handle Polygon type
    SELECT 
        CASE WHEN GeoData.[type] = 'Polygon' 
            THEN geography::STGeomFromText(
                CONCAT('POLYGON((', STUFF((
                    SELECT CONCAT(', ', json_value(Value, '$[0]'), ' ', json_value(Value, '$[1]'))  
                    FROM OPENJSON(GeoData.coordinates, '$[0]') 
                    ORDER BY CAST([key] AS int) FOR XML PATH('')
                ), 1, 2, ''), '))'), 4326)
        -- Handle MultiPolygon type
        WHEN GeoData.[type] = 'MultiPolygon' 
            THEN geography::STGeomFromText(
                CONCAT('MULTIPOLYGON(', STUFF((
                    SELECT CONCAT('(', STUFF((
                        SELECT CONCAT(', ', json_value(Value, '$[0]'), ' ', json_value(Value, '$[1]'))  
                        FROM OPENJSON(Poly.value)
                        ORDER BY CAST([key] AS int)
                        FOR XML PATH('')
                    ), 1, 2, ''), ')')  
                    FROM OPENJSON(GeoData.coordinates) AS Poly 
                    FOR XML PATH('')
                ), 1, 1, '')), 4326)
        END AS geom
) AS geography

-- Now you have geography data in the dbo.Country table, you can select from it
SELECT * FROM dbo.Country
ORDER BY country;
