

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