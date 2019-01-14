drop procedure if process_desk_orders_routine();

create procedure process_desk_orders_routine()
Begin

  DROP TABLE IF EXISTS temp_Desk_Aggregation_Staging;

  CREATE TABLE `temp_Desk_Aggregation_Staging`
  (
    `Trader`      varchar(30) COLLATE latin1_general_ci         DEFAULT NULL,
    `SecurityID`  varchar(20) COLLATE latin1_general_ci         DEFAULT NULL,
    `Side`        char(1) COLLATE latin1_general_ci             DEFAULT NULL,
    `OrderType`   varchar(50) COLLATE latin1_general_ci         DEFAULT NULL,
    `Start_Date`  datetime                                      DEFAULT NULL,
    `end_date`    datetime                                      DEFAULT NULL,
    `OrderID`     varchar(20) COLLATE latin1_general_ci         DEFAULT NULL,
    `Client`      varchar(10) COLLATE latin1_general_ci         DEFAULT NULL,
    `BREAK`       varchar(9) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `ROW_COUNTER` bigint(21)                                    DEFAULT NULL,
    KEY `idx1` (`ROW_COUNTER`, `Start_Date`, `SecurityID`, `Side`),
    KEY `idx2` (`ROW_COUNTER`, `BREAK`),
    KEY `idx3` (`SecurityID`, `Side`, `Start_Date`, `OrderID`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  SET @cnt = 0;
  INSERT INTO temp_Desk_Aggregation_Staging
  SELECT Trader
       , SecurityID
       , Side
       , Ordertype
       , Start_Date
       , end_date
       , OrderID
       , Client
       ,'NEW ORDER'       AS BREAK
       , @cnt := @cnt + 1 AS ROW_COUNTER
  FROM temp_aggregate_accounts_for_desk_working
  order by OrderType
         , SecurityID
         , side
         , Trader
         , Start_Date
         , end_date
         , OrderID;


  UPDATE temp_Desk_Aggregation_Staging A
    , temp_Desk_Aggregation_Staging B
  SET A.BREAK = 'SAME'
  WHERE A.row_counter = B.row_counter + 1
    AND TIMESTAMPDIFF(MINUTE, B.start_date, A.start_date) < 30
    AND A.SecurityID = B.SecurityID
    AND A.SIDE = B.SIDE;
  # AND
  # A.Trader = B.Trader
  # AND
  # A.client = B.client
  #AND
  #  A.OrderType=B.OrderType;


  DROP TABLE IF EXISTS temp_get_row_for_start_desk;

  CREATE TABLE `temp_get_row_for_start_desk`
  (
    `row_counter`      bigint(21) DEFAULT NULL,
    `DeskORDERIDFINAL` bigint(21) DEFAULT NULL
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_get_row_for_start_desk
  SELECT A.row_counter
       , MAX(B.row_counter) AS DeskORDERIDFINAL
  FROM temp_Desk_Aggregation_Staging A
         JOIN temp_Desk_Aggregation_Staging B
              ON B.break = 'NEW ORDER'
                AND
                 A.SecurityID = B.SecurityID
                AND
                 A.SIDE = B.SIDE
                #  AND
                #   A.Trader = B.Trader
                AND
                 A.row_counter >= B.row_counter
       # AND
       #    A.Client=B.Client
       # AND
       # A.OrderType=B.OrderType
  GROUP BY A.row_counter;


  DROP TABLE IF EXISTS temp_show_desk_aggregated;

  CREATE TABLE `temp_show_desk_aggregated`
  (
    `SecurityID`       varchar(20) COLLATE latin1_general_ci         DEFAULT NULL,
    `Trader`           varchar(30) COLLATE latin1_general_ci         DEFAULT NULL,
    `Side`             char(1) COLLATE latin1_general_ci             DEFAULT NULL,
    `Start_Date`       datetime                                      DEFAULT NULL,
    `End_Date`         datetime                                      DEFAULT NULL,
    `orderid`          varchar(20) COLLATE latin1_general_ci         DEFAULT NULL,
    `BREAK`            varchar(9) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `ROW_COUNTER`      bigint(21)                                    DEFAULT NULL,
    `DeskORDERIDFINAL` bigint(21)                                    DEFAULT NULL,
    `Client`           varchar(10) COLLATE latin1_general_ci         DEFAULT NULL
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  INSERT INTO temp_show_desk_aggregated
  SELECT ta.SecurityID
       , ta.Trader
       , ta.Side
       , ta.Start_Date
       , ta.End_Date
       , ta.orderid
       , ta.BREAK
       , a.ROW_COUNTER
       , a.DeskORDERIDFINAL
       , Client
  FROM temp_Desk_Aggregation_Staging ta
         JOIN temp_get_row_for_start_desk a
              ON
                ta.row_counter = a.row_counter;


  DROP TABLE IF EXISTS temp_show_final_desk_aggregation;

  CREATE TABLE `temp_show_final_desk_aggregation`
  (
    `client`           varchar(10) COLLATE latin1_general_ci         DEFAULT NULL,
    `SecurityID`       varchar(20) COLLATE latin1_general_ci         DEFAULT NULL,
    `Trader`           varchar(30) COLLATE latin1_general_ci         DEFAULT NULL,
    `SIDE`             char(1) COLLATE latin1_general_ci             DEFAULT NULL,
    `start_date`       datetime                                      DEFAULT NULL,
    `end_date`         datetime                                      DEFAULT NULL,
    `BREAK`            varchar(9) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `ROW_COUNTER`      bigint(21)                                    DEFAULT NULL,
    `orderid`          varchar(20) COLLATE latin1_general_ci         DEFAULT NULL,
    `DeskORDERIDFINAL` bigint(21)                                    DEFAULT NULL,
    `FINALDESKID`      varchar(20) COLLATE latin1_general_ci         DEFAULT NULL,
    KEY `idx_link_to_source` (`orderid`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  INSERT INTO temp_show_final_desk_aggregation
  SELECT ta.client
       , ta.SecurityID
       , ta.Trader
       , ta.SIDE
       , ta.start_date
       , ta.end_date
       , ta.BREAK
       , ta.ROW_COUNTER
       , ta.orderid
       , ta.DeskORDERIDFINAL
       , tas.orderid AS FINALDESKID
  FROM temp_Desk_Aggregation_Staging tas
         JOIN temp_show_desk_aggregated ta
              ON
                tas.row_counter = ta.deskORDERIDFINAL;
END;

