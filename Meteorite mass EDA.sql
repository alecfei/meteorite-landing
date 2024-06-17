USE Meteorite;
GO

-- the heaviest meteorite found and fell on earth
WITH meteorite_mass AS (
    SELECT MM.id
        , MM.name
        , MM.recclass AS class
        , MI.fall
        , MI.nametype AS type
        , YEAR(ML.year) AS year
        , ML.country
        , MM.[mass (g)]
    FROM MeteoriteMass AS MM
        INNER JOIN MeteoriteInfo AS MI
            ON MM.id = MI.id
        INNER JOIN MeteoriteLanding AS ML
            ON MM.id = ML.id
)

-- Query to find the heaviest meteorite that was found
SELECT * FROM meteorite_mass
WHERE 
    [mass (g)] = (
            SELECT MAX([mass (g)]) 
            FROM meteorite_mass
            WHERE fall = 'Found'
        )
    --AND fall = 'Found'

UNION ALL

-- Query to find the heaviest meteorite that fell
SELECT * FROM meteorite_mass
WHERE 
    [mass (g)] = (
            SELECT MAX([mass (g)]) 
            FROM meteorite_mass
            WHERE fall = 'Fell'
        )
    --AND fall = 'Fell'
;

-- aggregate mass of each class
SELECT recclass
    , AVG([mass (g)]) AS [average mass]
    , MAX([mass (g)]) AS [maximum mass]
    , MIN([mass (g)]) AS [minimum mass]
    , SUM([mass (g)]) AS [total mass]
FROM MeteoriteMass
GROUP BY recclass
ORDER BY 
    recclass
    --[average mass] DESC
;


/*
--CREATE VIEW AverageMeteoriteMass AS
SELECT id
    , name
    , recclass
    , [mass (g)]
    , AVG([mass (g)]) OVER (PARTITION BY recclass) AS averagemass
FROM MeteoriteMass
;

SELECT recclass
    , AVG([mass (g)]) AS [average mass]
FROM MeteoriteMass
GROUP BY recclass
ORDER BY [average mass] DESC
;

SELECT recclass 
    , MAX([mass (g)]) AS [maximum mass]
FROM MeteoriteMass
GROUP BY recclass
ORDER BY [maximum mass] DESC
;

SELECT recclass
    , MIN([mass (g)]) AS [minimum mass]
FROM MeteoriteMass
GROUP BY recclass
ORDER BY [minimum mass]
;
*/

SELECT TOP 10 recclass
    , AVG([mass (g)]) AS [average mass]
FROM MeteoriteMass
GROUP BY recclass
ORDER BY [average mass] DESC
;