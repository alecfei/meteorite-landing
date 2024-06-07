sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
GO
RECONFIGURE;
GO

ALTER SERVER ROLE sysadmin ADD MEMBER localhost;

GRANT ADMINISTER DATABASE BULK OPERATIONS TO portfolios;

GRANT CONTROL to PortfolioProject; 


