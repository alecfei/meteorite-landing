CREATE PROCEDURE InsertGeoJSONData @json NVARCHAR(MAX)
AS
BEGIN
    IF JSON_VALUE(@json, '$.geometry.type') = 'Polygon'
    BEGIN
        INSERT INTO GeoData (geoData, OBJECTID, CNTRY_NAME)
        SELECT 
            geography::STGeomFromText('POLYGON(' + PolygonCoords + ')', 4326),
            JSON_VALUE(@json, '$.properties.OBJECTID') AS OBJECTID,
            JSON_VALUE(@json, '$.properties.CNTRY_NAME') AS CNTRY_NAME
        FROM (
            SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), x) + ' ' + CONVERT(NVARCHAR(MAX), y), ',') AS PolygonCoords
            FROM OPENJSON(@json, '$.geometry.coordinates') 
            CROSS APPLY OPENJSON(value) WITH (x FLOAT '$[0]', y FLOAT '$[1]') AS Coordinates
        ) AS PolygonData;
    END
    ELSE IF JSON_VALUE(@json, '$.geometry.type') = 'MultiPolygon'
    BEGIN
        INSERT INTO GeoData (geoData, OBJECTID, CNTRY_NAME)
        SELECT 
            geography::STGeomFromText('MULTIPOLYGON(' + MultiPolygonCoords + ')', 4326),
            JSON_VALUE(@json, '$.properties.OBJECTID') AS OBJECTID,
            JSON_VALUE(@json, '$.properties.CNTRY_NAME') AS CNTRY_NAME
        FROM (
            SELECT STRING_AGG('((' + PolygonCoords + '))', ',') AS MultiPolygonCoords
            FROM (
                SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), x) + ' ' + CONVERT(NVARCHAR(MAX), y), ',') AS PolygonCoords
                FROM OPENJSON(@json, '$.geometry.coordinates') 
                CROSS APPLY OPENJSON(value) WITH (x FLOAT '$[0]', y FLOAT '$[1]') AS Coordinates
            ) AS PolygonData
        ) AS MultiPolygonData;
    END
    ELSE
    BEGIN
        RAISERROR('Unsupported geometry type', 16, 1);
    END
END;

DROP Table If EXISTS dbo.GeoData
-- Create the table
CREATE TABLE dbo.GeoData (
    id INT IDENTITY(1,1) PRIMARY KEY,
    geoData geography,
    OBJECTID INT,
    CNTRY_NAME NVARCHAR(255)
);

DECLARE @g nvarchar(max)
 
-- load the geojson into the variable
SELECT @g = BulkColumn
FROM OPENROWSET (BULK '/var/opt/mssql/Longitude_Graticules_and_World_Countries_Boundaries.geojson', SINGLE_CLOB) as JSON

EXEC InsertGeoJSONData @g;

Select * from GeoData;
