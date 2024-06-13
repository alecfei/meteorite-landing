USE Meteorite;
GO

-- check averagemass of each class
--CREATE VIEW AverageMeteoriteMass AS
SELECT id, name, recclass, [mass (g)], AVG([mass (g)]) OVER (PARTITION BY recclass) as averagemass
FROM MeteoriteMass
;

SELECT * FROM AverageMeteoriteMass
ORDER BY recclass, averagemass
;