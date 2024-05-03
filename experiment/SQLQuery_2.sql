DECLARE @g geography;
DECLARE @h geography;
SET @g = geography::STGeomFromText('POINT(-122.35900 47.65129)', 4326);
SET @h = geography::STGeomFromText('POINT(-122.34720 47.65100)', 4326);
SELECT @g.STDistance(@h);

DECLARE @g geography;  
SET @g = geography::STGeomFromWKB(0xE6100000010C33333333336349404C1AA37554551840, 4326);  
SELECT @g.ToString();

DECLARE @g geography;   
SET @g = geography::Point(47.65100, -122.34900, 4326)  
SELECT @g.ToString();

SELECT servicename, service_account
FROM sys.dm_server_services;
