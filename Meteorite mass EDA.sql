USE Meteorite;
GO

-- aggregate mass of each class
SELECT recclass
    , AVG([mass (g)]) AS [average mass]
    , MAX([mass (g)]) AS [maximum mass]
    , MIN([mass (g)]) AS [minimum mass]
FROM MeteoriteMass
GROUP BY recclass
ORDER BY 
   -- recclass
    [average mass] DESC
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
