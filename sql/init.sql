IF DB_ID('SplunkLab') IS NULL
BEGIN
    CREATE DATABASE SplunkLab;
END;
GO

USE SplunkLab;
GO

IF OBJECT_ID('dbo.ApplicationEvents', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.ApplicationEvents
    (
        EventID        BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_ApplicationEvents PRIMARY KEY,
        EventTime      DATETIME2(0) NOT NULL,
        Application    VARCHAR(100) NOT NULL,
        Environment    VARCHAR(20) NOT NULL,
        HostName       VARCHAR(100) NOT NULL,
        LogLevel       VARCHAR(20) NOT NULL,
        UserName       VARCHAR(100) NULL,
        ActionName     VARCHAR(100) NOT NULL,
        StatusCode     INT NOT NULL,
        ResponseTimeMs INT NOT NULL,
        SourceIP       VARCHAR(45) NULL,
        Message        VARCHAR(500) NOT NULL
    );
END;
GO

IF OBJECT_ID('dbo.SecurityEvents', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SecurityEvents
    (
        SecurityEventID BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_SecurityEvents PRIMARY KEY,
        EventTime       DATETIME2(0) NOT NULL,
        UserName        VARCHAR(100) NOT NULL,
        SourceIP        VARCHAR(45) NOT NULL,
        DestinationHost VARCHAR(100) NOT NULL,
        EventType       VARCHAR(100) NOT NULL,
        Result          VARCHAR(20) NOT NULL,
        RiskScore       INT NOT NULL,
        Description     VARCHAR(500) NOT NULL
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.ApplicationEvents)
BEGIN
    INSERT INTO dbo.ApplicationEvents
    (
        EventTime,
        Application,
        Environment,
        HostName,
        LogLevel,
        UserName,
        ActionName,
        StatusCode,
        ResponseTimeMs,
        SourceIP,
        Message
    )
    VALUES
    (DATEADD(MINUTE,-55,SYSDATETIME()),'customer-portal','production','web-01','INFO','alice','login',200,145,'10.10.1.20','User login completed'),
    (DATEADD(MINUTE,-50,SYSDATETIME()),'customer-portal','production','web-02','WARN','bob','login',401,92,'10.10.1.21','Invalid username or password'),
    (DATEADD(MINUTE,-45,SYSDATETIME()),'payment-api','production','api-01','ERROR','alice','submit_payment',500,1850,'10.10.1.20','Payment provider timeout'),
    (DATEADD(MINUTE,-40,SYSDATETIME()),'payment-api','production','api-02','INFO','charlie','submit_payment',200,320,'10.10.1.22','Payment completed'),
    (DATEADD(MINUTE,-35,SYSDATETIME()),'inventory-service','test','test-01','DEBUG','developer1','get_stock',200,75,'10.20.1.10','Stock lookup completed'),
    (DATEADD(MINUTE,-30,SYSDATETIME()),'customer-portal','production','web-01','ERROR','diana','checkout',503,2400,'10.10.1.23','Inventory service unavailable'),
    (DATEADD(MINUTE,-25,SYSDATETIME()),'payment-api','production','api-01','WARN','bob','submit_payment',429,44,'10.10.1.21','Rate limit exceeded'),
    (DATEADD(MINUTE,-20,SYSDATETIME()),'customer-portal','production','web-02','INFO','alice','logout',200,31,'10.10.1.20','User logout completed'),
    (DATEADD(MINUTE,-15,SYSDATETIME()),'inventory-service','production','inventory-01','INFO','service_account','update_stock',200,110,'10.30.1.15','Stock updated'),
    (DATEADD(MINUTE,-10,SYSDATETIME()),'customer-portal','production','web-01','ERROR','eve','login',403,55,'203.0.113.50','Account locked after repeated failures');
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.SecurityEvents)
BEGIN
    INSERT INTO dbo.SecurityEvents
    (
        EventTime,
        UserName,
        SourceIP,
        DestinationHost,
        EventType,
        Result,
        RiskScore,
        Description
    )
    VALUES
    (DATEADD(MINUTE,-50,SYSDATETIME()),'bob','10.10.1.21','web-02','authentication','failure',25,'Invalid username or password'),
    (DATEADD(MINUTE,-35,SYSDATETIME()),'admin','198.51.100.25','vpn-01','vpn_login','failure',60,'VPN authentication failed'),
    (DATEADD(MINUTE,-32,SYSDATETIME()),'admin','198.51.100.25','vpn-01','vpn_login','failure',70,'Repeated VPN authentication failure'),
    (DATEADD(MINUTE,-28,SYSDATETIME()),'admin','198.51.100.25','vpn-01','vpn_login','success',80,'Successful login after repeated failures'),
    (DATEADD(MINUTE,-15,SYSDATETIME()),'service_account','10.30.1.15','inventory-01','privileged_action','success',40,'Inventory update executed'),
    (DATEADD(MINUTE,-10,SYSDATETIME()),'eve','203.0.113.50','web-01','authentication','failure',85,'Account locked after repeated login failures');
END;
GO

CREATE OR ALTER VIEW dbo.vw_ApplicationEventsForSplunk
AS
SELECT
    EventID,
    EventTime,
    Application,
    Environment,
    HostName,
    LogLevel,
    UserName,
    ActionName,
    StatusCode,
    ResponseTimeMs,
    SourceIP,
    Message
FROM dbo.ApplicationEvents;
GO

CREATE OR ALTER VIEW dbo.vw_SecurityEventsForSplunk
AS
SELECT
    SecurityEventID,
    EventTime,
    UserName,
    SourceIP,
    DestinationHost,
    EventType,
    Result,
    RiskScore,
    Description
FROM dbo.SecurityEvents;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.sql_logins
    WHERE name = 'splunk_reader'
)
BEGIN
    CREATE LOGIN splunk_reader
    WITH PASSWORD = 'SplunkReader1234!',
         CHECK_POLICY = ON;
END;
GO

USE SplunkLab;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = 'splunk_reader'
)
BEGIN
    CREATE USER splunk_reader FOR LOGIN splunk_reader;
END;
GO

ALTER ROLE db_datareader ADD MEMBER splunk_reader;
GO

SELECT
    'Database initialization completed' AS InitializationStatus,
    COUNT(*) AS ApplicationEventCount
FROM dbo.ApplicationEvents;
GO
