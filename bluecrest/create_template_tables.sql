create procedure create_template_tables()
BEGIN

  SELECT NOW() AS `Creating Tables`;


  DROP TABLE IF EXISTS jobs;
  CREATE TABLE `jobs`
  (
    `CLIENT` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `REGION` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `GEN`    DATETIME                                        DEFAULT NULL,
    `ASOF`   DATETIME                                        DEFAULT NULL,
    `DESC`   varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `SEQ`    varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `STATUS` varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    KEY `idx1` (`Acct_Cd`)
  ) ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  insert into processing_status values (processDate_in, 'END Process', now());


  DROP TABLE IF EXISTS sch;
  CREATE TABLE `jobs`
  (
    `CLIENT`    varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `REGION`    varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `GEN`       DATETIME                                        DEFAULT NULL,
    `ASOF`      DATETIME                                        DEFAULT NULL,
    `DESC`      varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `User_Name` varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `Init`      varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    KEY `idx1` (`Acct_Cd`)
  ) ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


END;

