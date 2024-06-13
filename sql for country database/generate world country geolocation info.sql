USE Country;
GO

SELECT TOP (1000) [country]
      ,[coordinates]
  FROM [Country].[dbo].[WorldCountries]

ALTER TABLE WorldCountries
DROP COLUMN IF EXISTS geom;

ALTER TABLE WorldCountries
ADD geom geography;

SELECT * FROM WorldCountries;

UPDATE WorldCountries
SET geom = geography::STGeomFromText(CONVERT(nvarchar(max), coordinates), 4326)

SELECT DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'WorldCountries' AND COLUMN_NAME = 'coordinates';

SELECT country, coordinates, geom.ToString() as converted
FROM WorldCountries;
