DROP TABLE IF EXISTS dbo.Country
 
CREATE TABLE dbo.Country
(
	Id int IDENTITY PRIMARY KEY,
	country nvarchar(300),
	[type] nvarchar(300),
	Coordinates nvarchar(max)
)
 
 
DECLARE @JSON nvarchar(max)
 
-- load the geojson into the variable
SELECT @JSON = BulkColumn
FROM OPENROWSET (BULK '/var/opt/mssql/Longitude_Graticules_and_World_Countries_Boundaries.geojson', SINGLE_CLOB) as JSON
 
INSERT INTO dbo.Country (country, [type], Coordinates)

select country, [type], Coordinates
from   openjson (@Json, '$.features')
with
(
        country nvarchar(300) '$.properties.CNTRY_NAME',
        [type] nvarchar(300) '$.geometry.type',
        Coordinates NVARCHAR(max) '$.geometry.coordinates' as json
)
as GeoData
OUTER APPLY (
select 
   stuff( 
      (
        select concat(',  ', json_value(Value,'$[0]'),' ',json_value(Value,'$[1]'))  
        from openjson(GeoData.coordinates,'$[0]') 
        order by cast([key] as int)
        for xml path('')
      ),1,3,'') [path]
      WHERE GeoData.[type] = 'Polygon'
) PolygonData
OUTER APPLY (
    SELECT  STUFF(
        (
            SELECT CONCAT(',  ', polygon)
            FROM OPENJSON(GeoData.coordinates) as Poly 
            CROSS APPLY OPENJSON(Poly.value) as Shape 
            CROSS APPLY (
                SELECT '(' + stuff( 
                (
                    select concat(',  ', json_value(Value,'$[0]'),' ',json_value(Value,'$[1]'))  
                    from OPENJSON(Shape.value)
                    order by cast([key] as int)
                    for xml path('')
                ),1,3,'')+')' polygon
        ) Polygons
        for xml path('')
    ),1,3,'') multi
    WHERE GeoData.[type] = 'MultiPolygon'
) MultigonData
cross apply (
    SELECT concat(upper(GeoData.[type]),'((',COALESCE(PolygonData.path, MultigonData.multi),'))') WKT
) shapeDef
-- Extract the SRID from the feature collection header.
outer apply (
    select ID = Substring(name, CharIndex('::', name) + 2, LEN(name) - CharIndex('::', name)) from  openjson (@Json, '$.crs.properties')
    with ( name varchar(100) '$.name')
) SRID
outer apply (
    select geography::STGeomFromText(WKT,IsNull(SRID.ID, 4326)).MakeValid().ReorientObject() as geom
) geography
outer apply (
    select CASE WHEN geom.EnvelopeAngle() > 90 THEN geom.ReorientObject() ELSE geom END as fixed
) fixes

Select * FROM Country
order by country;


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
FROM OPENROWSET (BULK '/var/opt/mssql/Longitude_Graticules_and_World_Countries_Boundaries.geojson', SINGLE_CLOB) as JSON
 
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

