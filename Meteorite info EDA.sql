USE Meteorite;
GO

SELECT * FROM MeteoriteInfo;

/*
SELECT recclass
    -- , nametype
    -- , fall
    , COUNT(recclass) AS [class numbers]
    -- , COUNT(nametype) AS [type counts]
    -- , COUNT(fall) AS [whether landing or not]
FROM MeteoriteInfo
GROUP BY recclass 
    -- , nametype 
    -- , fall
ORDER BY recclass
--     , [class numbers] DESC
--     , [type counts] DESC
--     , [whether landing or not]
;
*/


-- Count of recclass, nametype and fall
SELECT recclass
    , COUNT(recclass) AS [class numbers]
FROM MeteoriteInfo
GROUP BY recclass 
ORDER BY [class numbers] DESC
;

SELECT nametype
    , COUNT(nametype) AS [type counts]
FROM MeteoriteInfo
GROUP BY nametype 
--ORDER BY [type counts]
;

SELECT fall
    , COUNT(fall) AS [whether fell or not]
FROM MeteoriteInfo
GROUP BY fall
--ORDER BY [whether landing or not]
;


-- the numbers of different meteorite classes and their nametypes that fell or not
SELECT recclass
    , nametype
    , fall
    , COUNT(*) AS [class numbers]
FROM MeteoriteInfo
GROUP BY recclass
    , nametype
    , fall
ORDER BY recclass
    --, [class numbers] DESC  
    --, nametype
    --, fall
;

