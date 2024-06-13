DROP TABLE IF EXISTS dbo.Country;

CREATE TABLE dbo.Country
(
    id nvarchar(60) NOT NULL PRIMARY KEY,
    country nvarchar(300),
    [type] nvarchar(300),
    WKT geography
);

DECLARE @JSON nvarchar(max);

-- Load the GeoJSON into the variable
SELECT @JSON = BulkColumn
FROM OPENROWSET (BULK '/var/opt/mssql/world-administrative-boundaries.geojson', SINGLE_CLOB) as JSON;

INSERT INTO dbo.Country (id, country, [type], WKT)
SELECT 
    id,
    country,
    [type],
    WKT
FROM OPENJSON(@Json, '$.features') 
WITH
(
    id nvarchar(60) '$.properties.color_code',
    country nvarchar(300) '$.properties.name',
    [type] nvarchar(300) '$.geometry.type',
    Coordinates NVARCHAR(max) '$.geometry.coordinates' AS JSON
) AS GeoData
OUTER APPLY (
    SELECT 
        CASE WHEN GeoData.[type] = 'Polygon' THEN
            CONCAT(
                'POLYGON((',
                STUFF(
                    (
                        SELECT CONCAT(', ', json_value(Value,'$[0]'),' ',json_value(Value,'$[1]'))  
                        FROM OPENJSON(GeoData.Coordinates,'$[0]') 
                        ORDER BY CAST([key] as int)
                        FOR XML PATH('')
                    ), 
                    1, 
                    2, 
                    ''
                ), 
                '))'
            )
        ELSE
            CONCAT(
                'MULTIPOLYGON(',
                STUFF(
                    (
                        SELECT 
                            ', (' +
                            STUFF(
                                (
                                    SELECT 
                                        ', ' + 
                                        STUFF(
                                            (
                                                SELECT CONCAT(' ', json_value(Rings.value,'$[0]'),' ',json_value(Rings.value,'$[1]'))  
                                                FROM OPENJSON(Poly.value) AS Rings
                                                ORDER BY CAST([key] as int)
                                                FOR XML PATH('')
                                            ),
                                            1, 
                                            2, 
                                            ''
                                        ) + ' '
                                    FROM OPENJSON(GeoData.Coordinates) AS Poly 
                                    WHERE json_value(Poly.value, '$[0][0]') = 'MultiPolygon'
                                    FOR XML PATH('')
                                ), 
                                1, 
                                2, 
                                ''
                            ) +
                            ')'
                        FOR XML PATH('')
                    ), 
                    1, 
                    2, 
                    ''
                ) +
                ')'
            )
        END AS WKT
) AS PolygonData;

SELECT * FROM Country;