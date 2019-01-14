create procedure process_routine(IN processDate_in date)
BEGIN

  insert into processing_status values (processDate_in, 'START - 38 steps', now());
  insert into processing_status values (processDate_in, 'Step 1 - set up temp_account_manager_mapping', now());


  DROP TABLE IF EXISTS temp_account_manager_mapping;
  CREATE TABLE `temp_account_manager_mapping`
  (
    `Acct_Cd`        varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `Acct_Name`      varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `Manager`        varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `STRATEGY_GROUP` varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `User_Name`      varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `Init`           varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    KEY `idx1` (`Acct_Cd`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_account_manager_mapping
    (SELECT Acct_Cd
          ,Acct_Name
          ,Manager
          ,''
          ,User_Name
          ,Init
     FROM acadian_data.funds fr
        ,acadian_data.users ur
     WHERE fr.manager = ur.user_cd
     GROUP BY ACCT_CD);

  insert into processing_status values (processDate_in, 'Step 2 - set up temp_placements_working', now());

  DROP TABLE IF EXISTS temp_placements_working;
  CREATE TABLE `temp_placements_working`
  (
    `order_id`            varchar(17) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `place_id`            varchar(17) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `exec_broker`         varchar(18) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `place_date`          datetime                                                   DEFAULT NULL,
    `broker_reason`       varchar(13) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `create_user`         varchar(18) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `user_name`           varchar(59) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `init`                varchar(7) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `exec_amt`            varchar(22) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `exec_qty`            varchar(22) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `place_qty`           varchar(22) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `instruction`         varchar(10) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `instruction2`        varchar(20) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `limit_price`         varchar(25) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `comments`            varchar(25) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `bkr_name`            varchar(54) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `parent_broker`       varchar(54) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `bkr_typ_cd`          varchar(10) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `bkr_reason_cd`       varchar(10) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `venue`               varchar(20) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `min_fill_date`       datetime                                                   DEFAULT NULL,
    `min_fill_date_adj`   datetime                                                   DEFAULT NULL,
    `max_fill_date`       datetime                                                   DEFAULT NULL,
    `max_fill_date_adj`   datetime                                                   DEFAULT NULL,
    `fill_qty`            int(10) unsigned                                           DEFAULT NULL,
    `fill_amt`            double                                                     DEFAULT NULL,
    `ORDER_EXEC_QTY`      double                                                     DEFAULT NULL,
    `ORD_COMMISSIONS`     double                                                     DEFAULT NULL,
    `FACTOR`              double                                                     DEFAULT NULL,
    `PLC_COMMISSIONS`     double                                                     DEFAULT NULL,
    `price`               double                                                     DEFAULT NULL,
    `multi_placement_tag` varchar(1)                                                 DEFAULT NULL,
    KEY `idx1` (`order_id`),
    KEY `idx2` (`place_id`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  INSERT INTO temp_placements_working
    (SELECT p.order_id
          , p.place_id
          , p.exec_broker
          , p.place_date
          , p.broker_reason
          , p.create_user
          , NULL
          , NULL
          , p.exec_amt
          , p.exec_qty
          , p.place_qty
          , IF(LEFT(p.instruction, 1) = 'L', 'LMT', 'MKT') AS instruction
          , IF(p.instruction IS NULL OR p.instruction = '', 'NONE PROVIDED', p.instruction)
          , p.limit_price
          , p.comments
          , replace(br.bkr_name, ',', '')
          , IFNULL(br.address1, 'Not Provided')            AS parent_broker
          , br.bkr_typ_cd
          , br.bkr_reason_cd
          , NULL
          , NULL
          , NULL
          , NULL
          , NULL
          , NULL
          , NULL
          , SUM(a.EXEC_QTY)
          , SUM(a.COMMISSION_AMT)
          , p.exec_qty / SUM(a.EXEC_QTY)
          , p.exec_qty * SUM(a.COMMISSION_AMT) / SUM(a.EXEC_QTY)
          , NULL
          , 'N'
     FROM acadian_data.placements p
            LEFT JOIN acadian_data.brokers br
                      ON p.exec_broker = br.bkr_cd
                        AND p.exec_broker <> 'INKIND'
            LEFT JOIN acadian_data.allocations a
                      ON p.order_id = a.order_id


     GROUP BY a.order_id,p.place_id
    );


  insert into processing_status values (processDate_in, 'Step 3 - update temp_placements_working', now());
  UPDATE temp_placements_working p JOIN (SELECT * FROM acadian_data.fills_aggregate GROUP BY placement_id) fa
    ON p.place_id = fa.placement_id
  SET p.min_fill_date     = fa.min_FILLDATE,
      p.min_fill_date_adj = fa.min_FILLDATE,
      p.max_fill_date     = fa.max_FILLDATE,
      p.max_fill_date_adj = fa.max_FILLDATE,
      p.fill_qty          = fa.SUM_fillqty,
      p.fill_amt          = fa.SUM_fillamt;

  UPDATE temp_placements_working p JOIN (SELECT placement_id
                                              , IFNULL(
        IF(MIN(LAST_MKT) = MAX(LAST_MKT),
           MIN(LAST_MKT),
           'MULTI'),
        'Not Provided')
      AS venue
                                         FROM acadian_data.fills
                                         GROUP BY placement_id) fa
    ON p.place_id = fa.placement_id
  SET p.venue = fa.venue;


  insert into processing_status values (processDate_in, '4 update placements working with orders', now());

  UPDATE temp_placements_working p JOIN acadian_data.orders o
    ON p.order_id = o.order_id
  SET p.create_user = o.trader;


  insert into processing_status values (processDate_in, '5 update placements working with placements working ', now());
  UPDATE temp_placements_working p JOIN temp_placements_working q
    ON p.order_id = q.order_id
  SET p.create_user = q.create_user
  WHERE p.user_name IS NULL
    AND q.user_name IS NOT NULL;


  insert into processing_status values (processDate_in, '6 update placements working with users ', now());
  UPDATE temp_placements_working p JOIN acadian_data.users u
    ON p.create_user = u.user_cd
  SET p.user_name = u.user_name,
      p.init      = u.init;

  insert into processing_status values (processDate_in, 'Step 7 - setup temp_allocations_working', now());
  DROP TABLE IF EXISTS temp_allocations_working;

  CREATE TABLE `temp_allocations_working`
  (
    `ORDER_ID`         varchar(17) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `ACCT_CD`          varchar(24) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `TOTAL_TARGET_QTY` double                                                      DEFAULT NULL,
    `TOTAL_TARGET_AMT` double                                                      DEFAULT NULL,
    `TOTAL_EXEC_QTY`   double NOT NULL,
    `TOTAL_EXEC_AMT`   double NOT NULL,
    `TOT_COMMISSION`   double                                                      DEFAULT NULL,
    `COMMISSION_RATE`  double                                                      DEFAULT NULL,
    `ORDER_MANAGER`    varchar(21) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `EXEC_BROKER`      varchar(18) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `LIMIT_PRICE`      varchar(26) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `ORIG_ORDER_ID`    varchar(68) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `COMMENTS`         varchar(469) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    `TOT_FEES`         double                                                      DEFAULT NULL,
    `Acct_Name`        varchar(67) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `Manager`          varchar(50) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `User_Name`        varchar(59) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `Init`             varchar(7) CHARACTER SET latin1 COLLATE latin1_general_ci   DEFAULT NULL,
    `STRATEGY_GROUP`   varchar(30) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    `status`           varchar(16) CHARACTER SET latin1 COLLATE latin1_general_ci  DEFAULT NULL,
    KEY `idx1` (`ORDER_ID`),
    KEY `idx2` (`ORIG_ORDER_ID`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_cs;

  INSERT INTO temp_allocations_working
    (SELECT a.ORDER_ID
          , UPPER(a.ACCT_CD)
          , SUM(TARGET_QTY)                                                               TOTAL_TARGET_QTY
          , SUM(TARGET_AMT)                                                               TOTAL_TARGET_AMT
          , SUM(EXEC_QTY)                                                                 TOTAL_EXEC_QTY
          , SUM(EXEC_AMT)                                                                 TOTAL_EXEC_AMT
          , SUM(commission_AMT)                                                           TOT_COMMISSION
          , a.COMMISSION_RATE
          , a.ORDER_MANAGER
          , a.EXEC_BROKER
          , a.LIMIT_PRICE
          , a.ORIG_ORDER_ID
          , a.COMMENTS
          , SUM(FEE_1_AMT + FEE_2_AMT + FEE_3_AMT + FEE_4_AMT + FEE_5_AMT + FEE_6_AMT) AS TOT_FEES

          , if(isnull(m.Acct_Name), a.ACCT_CD, m.Acct_Name)
          , m.Manager
          , m.User_Name
          , m.Init
          , m.STRATEGY_GROUP
          , a.STATUS
     FROM acadian_data.allocations a
            LEFT JOIN temp_account_manager_mapping m
                      ON a.ACCT_CD = m.Acct_CD
     WHERE a.EXEC_QTY IS NOT NULL
       AND a.EXEC_QTY != 0
     GROUP BY a.ORDER_ID,
              a.ACCT_CD);


  DROP TABLE IF EXISTS temp_fix_outgoing;
  CREATE TABLE temp_fix_outgoing
  (
    PRIMARY KEY (ORDER_ID),
    `ALGO_STRATEGY` varchar(25) DEFAULT NULL
  )
  SELECT ORDER_ID
       , 'N.A.' AS ALGO_STRATEGY
  FROM acadian_data.fix_outgoing_hist
  GROUP BY ORDER_ID;

  REPLACE INTO temp_fix_outgoing (ORDER_ID, ALGO_STRATEGY)
  SELECT ORDER_ID,
         ALGO_STRATEGY
  FROM acadian_data.fix_outgoing
  GROUP BY ORDER_ID;

  insert into processing_status values (processDate_in, 'Step 8a - setup temp_orders_working', now());
  DROP TABLE IF EXISTS temp_orders_working;
  CREATE TABLE temp_orders_working
  (
    INDEX (order_id)
  )
  SELECT o.Order_ID
       , o.create_date
       , o.create_date                                                                             AS create_date_adj
       , o.TO_TRADER_DATE
       , o.Trans_Type
       , IF(o.Trans_Type = 'PROGRAM', 'PROGRAM', 'Non-Program')                                    as PROGRAM
       , CASE o.TRANS_TYPE
           WHEN 'BUYL' THEN 'B'
           WHEN 'SELLL' THEN 'S'
           WHEN 'BUYS' THEN 'BC'
           WHEN 'SELLS' THEN 'SS'
           ELSE 'B'
    END                                                                                            AS Side
       , IF(LEFT(o.instruction, 1) = 'L', 'LMT', 'MKT')                                            AS order_type
       , ifnull(o.instruction, '')                                                                 AS instruction
       , o.ORDER_DURATION
       , o.LIMIT_PRICE
       , IF(o.IPO = 'Y' OR o.broker_reason LIKE '%SYN%' OR o.broker_reason LIKE '%IPO%', 'Y', 'N') as ipo
       , o.CREATE_USER
       , o.MANAGER
       , o.TRADER
       , o.SEC_ID
       , o.CUSIP
       , o.SEDOL
       , o.TICKER
       , o.TARGET_QTY
       , o.COMMISSION_AMT
       , o.LOC_CRRNCY_CD
       , o.LIST_EXCH_CD
       , o.EXT_SEC_ID
       , o.PROG_TRD_ID
       , o.status
       , o.NET_TRADE_IND
       , o.CNTRY_OF_RISK
       , o.BKR_COMMENT                                                                             as COMMENTS
       , IF(fo.ALGO_STRATEGY IS NULL OR fo.ALGO_STRATEGY = '', 'N.A.', fo.ALGO_STRATEGY)           AS `ALGO_STRATEGY`
       , IF(fo.order_id IS NULL, 'Manually Filled', 'FIX')                                         as manually_filled
       , o.trade_date
       , o.settle_date
       , DATEDIFF(o.settle_date, o.trade_date)                                                     AS `days_to_settle`
       , o.sec_typ_cd                                                                              as sec_typ_cd
       , o.REASON_CD
  FROM acadian_data.orders o
         LEFT JOIN temp_fix_outgoing fo
                   ON o.order_id = fo.order_id;


  DELETE from temp_orders_working where sec_typ_cd = 'RTS';


  insert into processing_status values (processDate_in, 'Step 8f - find start times in order history', now());


  ALTER TABLE acadian_data.order_history
    ADD INDEX idx1 (order_id, act_timestamp, seq);

  DROP TABLE IF EXISTS temp_start_times1;
  CREATE TABLE temp_start_times1 AS
  SELECT ORDER_ID,
         PARENT_ORDER_ID,
         CAST(ACT_TIMESTAMP AS DATETIME) ACT_TIMESTAMP,
         ACTION_TYPE,
         MSG_TEXT,
         LEFT(MSG_TEXT, 18)              MSG_TEXT_SHORT,
         SHARES_ACTION
  FROM acadian_data.order_history
  WHERE (ACTION_TYPE IN ('MRGDFROM', 'MRGDINTO') AND SHARES_ACTION > '0')
     OR (ACTION_TYPE IN ('SPLBKRFROM', 'SPLDEBINTO') AND SHARES_ACTION > '0')
     OR (ACTION_TYPE = 'STT')
     OR (ACTION_TYPE = 'CHG' AND MSG_TEXT = 'Changed Status from NEW to OPEN.')
     OR (ACTION_TYPE = 'CHG' AND MSG_TEXT = 'Changed Status from OPEN to WORK.')
     OR LEFT(MSG_TEXT, 18) = 'Changed Trade Date'
  GROUP BY order_id,act_timestamp,seq
  ORDER BY order_id,ACT_TIMESTAMP,seq;

  ALTER TABLE acadian_data.order_history
    DROP INDEX idx1;

  ALTER TABLE temp_start_times1
    ADD INDEX idx1 (ORDER_ID, act_timestamp),
    ADD INDEX idx2 (PARENT_ORDER_ID),
    ADD INDEX idx3 (action_type),
    ADD INDEX idx4 (MSG_TEXT_SHORT);

  DROP TABLE IF EXISTS temp_start_times2;
  CREATE TABLE temp_start_times2 AS
  SELECT *
  FROM temp_start_times1
  WHERE action_type = 'MRGDFROM'
     OR MSG_TEXT_SHORT = 'Changed Trade Date';

  ALTER TABLE temp_start_times2
    ADD INDEX idx1 (ORDER_ID, act_timestamp),
    ADD INDEX idx2 (PARENT_ORDER_ID),
    ADD INDEX idx3 (action_type),
    ADD INDEX idx4 (MSG_TEXT_SHORT);

  DELETE a.*
  FROM temp_start_times1 a
         INNER JOIN temp_start_times2 b
                    ON b.order_id = a.order_id AND b.act_timestamp > a.act_timestamp
                      AND b.msg_text_short = 'Changed Trade Date';

  DELETE a.*
  FROM temp_start_times1_test a
         INNER JOIN temp_start_times2_test b
                    ON b.order_id = a.parent_order_id AND b.act_timestamp > a.act_timestamp
                      AND b.action_type = 'MRGDFROM';


  insert into processing_status values (processDate_in, 'Step 9 - setup temp_order_trail_working', now());
  DROP TABLE IF EXISTS temp_order_trail_working;

  CREATE TABLE temp_order_trail_working
  AS
  SELECT a.order_id
       , a.orig_order_id
       , a.acct_cd
       , MIN(o.CREATE_DATE)    AS orig_order_create_date
       , MIN(o.TO_TRADER_DATE) AS orig_order_trader_date
  FROM acadian_data.allocations a
         LEFT JOIN temp_orders_working o
                   ON a.orig_order_id = o.order_id

  GROUP BY a.order_id
         , a.orig_order_id
         , a.acct_cd;

  ALTER TABLE temp_order_trail_working
    ADD INDEX idx1 (orig_order_id, acct_cd),
    ADD INDEX idx2 (order_id, acct_cd);


  DROP TABLE IF EXISTS temp_order_trail_working_dtg;

  CREATE TABLE temp_order_trail_working_dtg
  AS
  SELECT order_id
       , MIN(orig_order_create_date) AS orig_order_create_date
       , MIN(orig_order_trader_date) AS orig_order_trader_date
  FROM temp_order_trail_working
  GROUP BY order_id;

  ALTER TABLE temp_order_trail_working_dtg
    ADD INDEX idx1 (order_id);

  UPDATE temp_order_trail_working a, temp_order_trail_working_dtg b
  SET a.orig_order_create_date = b.orig_order_create_date
  WHERE a.orig_order_create_date IS NULL
    AND a.order_id = b.order_id;

  UPDATE temp_order_trail_working a, temp_order_trail_working_dtg b
  SET a.orig_order_trader_date = b.orig_order_trader_date
  WHERE a.orig_order_trader_date IS NULL
    AND a.order_id = b.order_id;

  insert into processing_status values (processDate_in, 'Step 10 - remove non-equity instrument orders', now());


  insert into processing_status
  values (processDate_in, 'Step 10.1 - tag non-equity cusip/sedol  non-equity instrument orders', now());
  DROP TABLE IF EXISTS temp_order_target;
  CREATE TABLE temp_order_target
  SELECT order_id
       , cusip
       , sec_typ_cd
       , LEFT(TRIM(cusip), 8) as clean_cusip
       , sedol
       , LEFT(TRIM(sedol), 6) as clean_sedol
       , 'xxxxxx'             as xcusip
       , 'xxxxxx'             as xsedol
  FROM temp_orders_working;

  ALTER TABLE temp_order_target
    ADD KEY idx1 (clean_cusip),
    ADD KEY idx2 (clean_sedol);

  insert into processing_status
  values (processDate_in, 'Step 10.2 - tag non-equity cusip non-equity instrument orders', now());
  UPDATE temp_order_target o
    LEFT JOIN market_data.security_master m
    ON o.clean_cusip = m.cusip
  SET xcusip = 'delete'
  WHERE o.cusip IS NOT NULL
    AND m.cusip is null
    AND o.sec_typ_cd != 'COM';

  insert into processing_status
  values (processDate_in, 'Step 10.3 - tag non-equity cusip non-equity instrument orders', now());
  UPDATE temp_order_target
  SET xcusip = 'delete'
  WHERE cusip IS NULL
    AND sec_typ_cd != 'COM';


  insert into processing_status
  values (processDate_in, 'Step 10.4 - tag non-equity sedol non-equity instrument orders', now());
  UPDATE temp_order_target o
    LEFT JOIN market_data.security_master m
    ON o.clean_sedol = m.sedol
  SET xsedol = 'delete'
  WHERE o.sedol IS NOT NULL
    AND m.sedol is null;

  insert into processing_status
  values (processDate_in, 'Step 10.5 - tag non-equity cusip/sedol instrument orders', now());
  UPDATE temp_order_target
  SET xsedol = 'delete'
  WHERE sedol IS NULL
    AND sec_typ_cd != 'COM';


  insert into processing_status values (processDate_in, 'Step 10.6 - remove tagged cusip/sedol', now());
  DELETE w.*
  FROM temp_orders_working w,
       temp_order_target t
  WHERE w.order_id = t.order_id
    AND t.xcusip = 'delete'
    AND t.xsedol = 'delete';

  insert into processing_status values (processDate_in, 'Step 10.7 - remove tagged cusip/sedol', now());
  DELETE aw.*
  FROM temp_allocations_working aw,
       temp_order_target t
  WHERE aw.orig_order_id = t.order_id
    AND t.xcusip = 'delete'
    AND t.xsedol = 'delete';

  insert into processing_status values (processDate_in, 'Step 10.8 - remove tagged cusip/sedol', now());
  DELETE pw.*
  FROM temp_placements_working pw,
       temp_order_target t
  WHERE pw.order_id = t.order_id
    AND t.xcusip = 'delete'
    AND t.xsedol = 'delete';


  insert into processing_status values (processDate_in, 'Step 11 - setup temp_placement_rollups_working', now());
  DROP TABLE IF EXISTS temp_placement_rollups_working;

  CREATE TABLE temp_placement_rollups_working
  SELECT order_id
       , IF(MIN(exec_broker) = MAX(exec_broker),
            MIN(exec_broker),
            'MULTI')                                                        AS broker
       , IF(MIN(create_user) = MAX(create_user),
            MIN(create_user),
            'MULTI')                                                        AS trader
       , IF(MIN(user_name) = MAX(user_name),
            MIN(user_name),
            'MULTI')                                                        AS trader_name
       , MIN(place_date)                                                    AS placement_date
       , CAST(GROUP_CONCAT(DISTINCT broker_reason SEPARATOR ' - ') AS CHAR) AS broker_reason
       , SUM(exec_amt)                                                      AS placement_exec_amt
       , SUM(exec_qty)                                                      AS placement_exec_shares
       , SUM(place_qty)                                                     AS qty_placed
       , MIN(instruction)                                                   AS broker_order_type
       , MIN(instruction2)                                                  AS broker_order_type_2
       , MIN(limit_price)                                                   AS min_place_limit
       , MAX(limit_price)                                                   AS max_place_limit
       , CAST(GROUP_CONCAT(DISTINCT comments SEPARATOR ' - ') AS CHAR)      AS comments
       , IF(MIN(bkr_name) = MAX(bkr_name),
            MIN(bkr_name),
            'MULTI')                                                        AS broker_name
       , IF(MIN(parent_broker) = MAX(parent_broker),
            MIN(parent_broker),
            'MULTI')                                                        AS parent_broker
       , IF(MIN(bkr_typ_cd) = MAX(bkr_typ_cd),
            MIN(bkr_typ_cd),
            'MULTI')                                                        AS broker_type_code
       , IF(MIN(bkr_reason_cd) = MAX(bkr_reason_cd),
            MIN(bkr_reason_cd),
            'MULTI')                                                        AS broker_reason_code
       , IF(MIN(venue) = MAX(venue),
            MIN(venue),
            'MULTI')                                                        AS venue
       , SUM(fill_qty)                                                      AS total_fill
       , SUM(fill_amt)                                                      AS total_amt
       , MIN(min_fill_date)                                                 AS first_fill_date
       , MAX(max_fill_date)                                                 AS last_fill_date
  FROM temp_placements_working
  WHERE exec_amt > 0
  GROUP BY order_id;

  ALTER TABLE temp_placement_rollups_working
    ADD INDEX idx1 (order_id);


  SELECT NOW() AS `insert into temp_aggregated_info_working`;
  insert into processing_status values (processDate_in, 'Step 12 - setup temp_aggregated_info_working', now());
  DROP TABLE IF EXISTS temp_aggregated_info_working;

  CREATE TABLE `temp_aggregated_info_working`
  (
    `order_id`                   varchar(11) COLLATE latin1_general_ci,
    `orig_order_create_date`     datetime,
    `orig_order_trader_date`     datetime                                 DEFAULT NULL,
    `orig_order_create_date_adj` datetime,
    `orig_order_trader_date_adj` datetime                                 DEFAULT NULL,
    `create_date`                datetime                                 DEFAULT NULL,
    `create_date_adj`            datetime                                 DEFAULT NULL,
    `client_to_trader_date`      datetime                                 DEFAULT NULL,
    `to_trader_date`             datetime                                 DEFAULT NULL,
    `trader_date_updated`        varchar(1) COLLATE latin1_general_ci     DEFAULT NULL,
    `trans_type`                 varchar(15) COLLATE latin1_general_ci    DEFAULT NULL,
    `side`                       char(2) CHARACTER SET latin1             DEFAULT NULL,
    `order_type`                 varchar(3) CHARACTER SET latin1          DEFAULT '',
    `instruction`                varchar(255) COLLATE latin1_general_ci   DEFAULT '',
    `order_duration`             varchar(8) COLLATE latin1_general_ci     DEFAULT NULL,
    `ORDERS_LIMIT`               double                                   DEFAULT NULL,
    `IPO`                        varchar(4) COLLATE latin1_general_ci     DEFAULT NULL,
    `ORDERS_TRADER`              varchar(20) COLLATE latin1_general_ci    DEFAULT NULL,
    `sec_id`                     varchar(25) COLLATE latin1_general_ci    DEFAULT NULL,
    `cusip`                      char(9) COLLATE latin1_general_ci        DEFAULT NULL,
    `sedol`                      varchar(7) COLLATE latin1_general_ci     DEFAULT NULL,
    `ticker`                     varchar(50) COLLATE latin1_general_ci    DEFAULT NULL,
    `target_qty`                 double                                   DEFAULT NULL,
    `commission_amt`             double                                   DEFAULT NULL,
    `commission_rate`            double                                   DEFAULT NULL,
    `loc_crrncy_cd`              char(3) COLLATE latin1_general_ci        DEFAULT NULL,
    `list_exch_cd`               varchar(10) COLLATE latin1_general_ci    DEFAULT NULL,
    `ext_sec_id`                 varchar(40) COLLATE latin1_general_ci    DEFAULT NULL,
    `Program`                    varchar(15) COLLATE latin1_general_ci    DEFAULT NULL,
    `program_id`                 varchar(20) COLLATE latin1_general_ci    DEFAULT NULL,
    `status`                     varchar(15) COLLATE latin1_general_ci    DEFAULT NULL,
    `principal_agency`           varchar(15) COLLATE latin1_general_ci    DEFAULT NULL,
    `cntry_of_risk`              varchar(50) COLLATE latin1_general_ci    DEFAULT NULL,
    `ALLOCATIONS_ACCT_CD`        varchar(24) COLLATE latin1_general_ci    DEFAULT NULL,
    `ALLOCATIONS_TARGET_QTY`     double                                   DEFAULT NULL,
    `ALLOCATIONS_TARGET_AMT`     double                                   DEFAULT NULL,
    `ALLOCATIONS_EXEC_QTY`       double                                   DEFAULT NULL,
    `ALLOCATIONS_EXEC_AMT`       double                                   DEFAULT NULL,
    `ALLOCATIONS_TOT_COMMISSION` double                                   DEFAULT NULL,
    `ALLOCATIONS_ORDER_MANAGER`  varchar(21) COLLATE latin1_general_ci    DEFAULT NULL,
    `ALLOCATIONS_EXEC_BROKER`    varchar(18) COLLATE latin1_general_ci    DEFAULT NULL,
    `ALLOCATIONS_LIMIT_PRICE`    varchar(26) COLLATE latin1_general_ci    DEFAULT NULL,
    `ORIG_ORDER_ID`              varchar(68) COLLATE latin1_general_ci    DEFAULT NULL,
    `PM_ORDER_ID`                varchar(68) COLLATE latin1_general_ci    DEFAULT NULL,
    `DESK_ORDER_ID`              varchar(68) COLLATE latin1_general_ci    DEFAULT NULL,
    `BROKER_ORDER_ID`            varchar(68) COLLATE latin1_general_ci    DEFAULT NULL,
    `ALLOCATIONS_COMMENTS`       varchar(469) COLLATE latin1_general_ci   DEFAULT NULL,
    `ALLOCATIONS_TOTAL_FEES`     double                                   DEFAULT NULL,
    `Acct_Name`                  varchar(67) COLLATE latin1_general_ci    DEFAULT NULL,
    `STRATEGY_GROUP`             varchar(30) COLLATE latin1_general_ci    DEFAULT NULL,
    `sjls_exchange_rate`         varchar(6) CHARACTER SET latin1 NOT NULL DEFAULT '',
    `broker`                     varchar(18) COLLATE latin1_general_ci    DEFAULT NULL,
    `broker_name`                varchar(54) COLLATE latin1_general_ci    DEFAULT NULL,
    `parent_broker`              varchar(54) COLLATE latin1_general_ci    DEFAULT NULL,
    `broker_type_code`           varchar(10) COLLATE latin1_general_ci    DEFAULT NULL,
    `broker_reason_code`         varchar(10) COLLATE latin1_general_ci    DEFAULT NULL,
    `broker_order_type`          varchar(10) COLLATE latin1_general_ci    DEFAULT NULL,
    `broker_order_type_2`        varchar(20) COLLATE latin1_general_ci    DEFAULT NULL,
    `placements_trader`          varchar(18) COLLATE latin1_general_ci    DEFAULT NULL,
    `trader_name`                varchar(59) COLLATE latin1_general_ci    DEFAULT NULL,
    `placement_date`             datetime                                 DEFAULT NULL,
    `broker_reason`              longtext CHARACTER SET latin1,
    `placement_exec_amt`         double                                   DEFAULT NULL,
    `placement_exec_shares`      double                                   DEFAULT NULL,
    `qty_placed`                 double                                   DEFAULT NULL,
    `min_place_limit`            varchar(25) COLLATE latin1_general_ci    DEFAULT NULL,
    `max_place_limit`            varchar(25) COLLATE latin1_general_ci    DEFAULT NULL,
    `placement_comments`         longtext CHARACTER SET latin1,
    `total_fill`                 decimal(33, 0)                           DEFAULT NULL,
    `total_amt`                  double                                   DEFAULT NULL,
    `first_fill_date`            datetime                                 DEFAULT NULL,
    `last_fill_date`             datetime                                 DEFAULT NULL,
    `last_fill_date_adj`         datetime                                 DEFAULT NULL,
    `sec_check_status`           varchar(22)                              DEFAULT NULL,
    `adjusted_price`             double                          NOT NULL,
    `adjust_ratio`               double                          NOT NULL,
    `sjls_ticker`                varchar(17)                              DEFAULT NULL,
    `sjls_currency`              char(3)                                  DEFAULT NULL,
    `sjls_secid`                 char(18)                                 DEFAULT NULL,
    `exchange_code`              char(2)                                  DEFAULT NULL,
    `region`                     varchar(9)                               DEFAULT NULL,
    `COMMENTS`                   varchar(13)                              DEFAULT NULL,
    `ALGO_STRATEGY`              varchar(25)                              DEFAULT NULL,
    `multi_placement_tag`        varchar(1)                               DEFAULT NULL,
    `amended`                    varchar(8)                      NOT NULL DEFAULT 'N.A.',
    `trade_date`                 date                                     DEFAULT NULL,
    `settle_date`                date                                     DEFAULT NULL,
    `days_to_settle`             tinyint                                  DEFAULT NULL,
    `settlement`                 varchar(15)                              DEFAULT NULL,
    `form_b`                     varchar(8)                      NOT NULL DEFAULT 'N.A.',
    `manually_filled`            varchar(15)                              DEFAULT NULL,
    `venue`                      varchar(10)                              DEFAULT NULL,
    `tzc_status`                 varchar(50)                              DEFAULT NULL,
    `SIMG`                       varchar(10)                              DEFAULT NULL,
    `REASON_CODE`                varchar(255)                             DEFAULT 'N/A',
    `THA_Decile`                 varchar(255)                             DEFAULT 'N/A',
    `MTH_Decile`                 varchar(255)                             DEFAULT 'N/A',
    `Security_Type`              varchar(255)                             DEFAULT 'N.A.',
    KEY `idx_orig` (`orig_order_id`),
    KEY `idx_ord` (`order_id`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  INSERT IGNORE INTO temp_aggregated_info_working
    (SELECT o.order_id
          , ot.orig_order_create_date
          , o.to_trader_date                                                as orig_order_trader_date
          , ot.orig_order_create_date                                       as orig_order_create_date_adj
          , o.to_trader_date                                                as orig_order_trader_date_adj
          , o.create_date
          , o.create_date_adj
          , o.to_trader_date
          , o.to_trader_date
          , 'N'
          , o.trans_type
          , o.side
          , o.order_type
          , o.instruction
          , if(instr(aw.comments, 'MOC') > 0, "ON_CLOSE", o.order_duration) as order_duration
          , o.limit_price                                                   AS ORDERS_LIMIT
          , IF(o.ipo = 'Y', 'IPO', 'N.A.')                                  as IPO
          , o.trader                                                        AS ORDERS_TRADER
          , o.sec_id
          , left(o.cusip, 8)
          , left(o.sedol, 6)
          , o.ticker
          , o.target_qty
          , o.commission_amt
          , aw.commission_rate
          , o.loc_crrncy_cd
          , o.list_exch_cd
          , o.ext_sec_id
          , o.program                                                       as Program
          , o.prog_trd_id                                                   as program_id
          , o.status
          , IF(o.net_trade_ind = 'P', 'Principal', 'Agency')                as principal_agency
          , o.cntry_of_risk
          , aw.ACCT_CD                                                      as ALLOCATIONS_ACCT_CD
          , aw.TOTAL_TARGET_QTY                                             as ALLOCATIONS_TARGET_QTY
          , aw.TOTAL_TARGET_AMT                                             As ALLOCATIONS_TARGET_AMT
          , aw.TOTAL_EXEC_QTY                                               As ALLOCATIONS_EXEC_QTY
          , aw.TOTAL_EXEC_AMT                                               As ALLOCATIONS_EXEC_AMT
          , aw.TOT_COMMISSION                                               AS ALLOCATIONS_TOT_COMMISSION
          , aw.ORDER_MANAGER                                                AS ALLOCATIONS_ORDER_MANAGER
          , aw.EXEC_BROKER                                                  AS ALLOCATIONS_EXEC_BROKER
          , aw.LIMIT_PRICE                                                  AS ALLOCATIONS_LIMIT_PRICE
          , aw.orig_order_id                                                AS ORIG_ORDER_ID
          , aw.orig_order_id                                                AS PM_ORDER_ID
          , aw.orig_order_id                                                AS DESK_ORDER_ID
          , aw.orig_order_id                                                AS BROKER_ORDER_ID
          , aw.COMMENTS                                                     AS ALLOCATIONS_COMMENTS
          , aw.TOT_FEES                                                     AS ALLOCATIONS_TOTAL_FEES
          , aw.Acct_Name
          , aw.STRATEGY_GROUP
          , '1.0000'                                                        AS sjls_exchange_rate
          , pw.broker
          , pw.broker_name
          , IFNULL(pw.parent_broker, 'Not Provided')
          , pw.broker_type_code
          , pw.broker_reason_code
          , pw.broker_order_type
          , pw.broker_order_type_2
          , pw.trader                                                       AS placements_trader
          , pw.trader_name
          , pw.placement_date
          , pw.broker_reason
          , pw.placement_exec_amt
          , pw.placement_exec_shares
          , pw.qty_placed
          , pw.min_place_limit
          , pw.max_place_limit
          , pw.comments                                                     AS placement_comments
          , pw.total_fill
          , pw.total_amt
          , pw.first_fill_date
          , pw.last_fill_date
          , pw.last_fill_date                                               as last_fill_date_adj
          , 0                                                               as adjusted_price
          , 0                                                               as adjust_ratio
          , NULL                                                            AS sec_check_status
          , NULL                                                            AS sjls_ticker
          , NULL                                                            AS sjls_currency
          , NULL                                                            AS sjls_secid
          , NULL                                                            as exchange_code
          , NULL                                                            as region
          , o.COMMENTS
          , IFNULL(o.ALGO_STRATEGY, 'N.A.')
          , NULL
          , 'N.A.'
          , o.trade_date
          , o.settle_date
          , o.days_to_settle
          , 'Standard'                                                      AS settlement
          , NULL
          , o.manually_filled
          , pw.venue
          , NULL
          , NULL
          , o.REASON_CD
          , 'No Score'
          , 'No Score'
          , o.sec_typ_cd
     FROM temp_allocations_working aw
            LEFT JOIN temp_orders_working o
                      ON aw.order_id = o.order_id
            LEFT JOIN temp_placement_rollups_working pw
                      ON pw.order_id = o.order_id
            LEFT JOIN temp_order_trail_working ot
                      ON aw.order_id = ot.order_id
                        AND aw.ACCT_CD = ot.ACCT_CD);


  DELETE
  FROM temp_aggregated_info_working
  WHERE `status` in ('CNCL', 'CNCLACCT');

  UPDATE temp_aggregated_info_working a, temp_start_times1 b
  SET a.orig_order_trader_date     = b.act_timestamp,
      a.to_trader_date             = b.act_timestamp,
      a.orig_order_trader_date_adj = b.act_timestamp,
      a.trader_date_updated        = 'Y'
  WHERE a.orig_order_id = b.parent_order_id
    AND b.action_type = 'MRGDFROM';

  UPDATE temp_aggregated_info_working a, temp_start_times1 b
  SET a.orig_order_trader_date     = b.act_timestamp,
      a.to_trader_date             = b.act_timestamp,
      a.orig_order_trader_date_adj = b.act_timestamp,
      a.trader_date_updated        = 'Y'
  WHERE a.order_id = b.order_id
    AND a.trader_date_updated = 'N'
    AND b.MSG_TEXT = 'Changed Status from OPEN to WORK.';

  UPDATE temp_aggregated_info_working a, temp_start_times1 b
  SET a.orig_order_trader_date     = b.act_timestamp,
      a.to_trader_date             = b.act_timestamp,
      a.orig_order_trader_date_adj = b.act_timestamp,
      a.trader_date_updated        = 'Y'
  WHERE a.order_id = b.order_id
    AND a.trader_date_updated = 'N'
    AND b.action_type = 'MRGDFROM';


  UPDATE temp_aggregated_info_working a, temp_start_times1 b
  SET a.orig_order_trader_date     = b.act_timestamp,
      a.to_trader_date             = b.act_timestamp,
      a.orig_order_trader_date_adj = b.act_timestamp,
      a.trader_date_updated        = 'Y'
  WHERE a.orig_order_id = b.order_id
    AND a.trader_date_updated = 'N'
    AND b.MSG_TEXT = 'Changed Status from OPEN to WORK.';

  UPDATE temp_aggregated_info_working a, temp_start_times1 b
  SET a.orig_order_trader_date     = b.act_timestamp,
      a.to_trader_date             = b.act_timestamp,
      a.orig_order_trader_date_adj = b.act_timestamp,
      a.trader_date_updated        = 'Y'
  WHERE a.order_id = b.order_id
    AND a.trader_date_updated = 'N'
    AND b.MSG_TEXT = 'Changed Status from NEW to OPEN.';

  UPDATE temp_aggregated_info_working a, acadian_data.order_history b
  SET a.amended = 'Amended'
  WHERE a.order_id = b.order_id
    AND b.ACTION_TYPE IN (
                          'RPLCNLACCT',
                          'REOPENCNCL',
                          'CLONE',
                          'CLONETO');


  insert into processing_status values (processDate_in, 'Step 13 - update temp_aggregated_info_working', now());

  update acadian.temp_aggregated_info_working a, acadian.alpha_scores b
  set a.THA_Decile = b.THA_decile,
      a.MTH_DECILE = b.MTH_decile
  where b.SecIDType = 'sedol'
    and b.SecurityID = a.sedol
    and a.trade_date = b.TradeDate;

  update acadian.temp_aggregated_info_working a, acadian.alpha_scores b
  set a.THA_Decile = b.THA_decile,
      a.MTH_Decile = b.MTH_decile
  where b.SecIDType = 'cusip'
    and b.SecurityID = a.cusip
    and a.trade_date = b.TradeDate;

  insert into processing_status values (processDate_in, 'Step 14 - update temp_aggregate_accounts_for_pm', now());
  DROP TABLE IF EXISTS temp_aggregate_accounts_for_pm;

  CREATE TABLE `temp_aggregate_accounts_for_pm`
  (
    `Start_Date`    datetime                              DEFAULT NULL,
    `End_Date`      datetime                              DEFAULT NULL,
    `Manager`       varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `Manager_Group` varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `SecurityID`    varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `Side`          char(2) COLLATE latin1_general_ci     DEFAULT NULL,
    `OrderID`       varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `Client`        varchar(10) COLLATE latin1_general_ci DEFAULT NULL
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  INSERT IGNORE INTO temp_aggregate_accounts_for_pm
    (SELECT MIN(ORIG_ORDER_CREATE_DATE)
          , MAX(LAST_FILL_DATE)
          , ALLOCATIONS_ORDER_MANAGER
          , ALLOCATIONS_ORDER_MANAGER
          , SEC_ID
          , SIDE
          , ORIG_ORDER_ID
          , 'acadian'
     FROM temp_aggregated_info_working
     WHERE IPO <> 'IPO'
       AND ORIG_ORDER_CREATE_DATE IS NOT NULL
       AND ALLOCATIONS_ORDER_MANAGER IS NOT NULL
     GROUP BY ORIG_ORDER_ID
            , ALLOCATIONS_ORDER_MANAGER
     ORDER BY ORIG_ORDER_ID
    );


  insert into processing_status values (processDate_in, 'Step 15  - Start get_pm_orders_cursor_routine', now());
  CALL get_pm_orders_cursor_routine;
  insert into processing_status values (processDate_in, 'Step 15  - End get_pm_orders_cursor_routine', now());


  insert into processing_status values (processDate_in, 'Step 16  - Update temp_aggregated_info_working', now());

  UPDATE temp_aggregated_info_working aw JOIN temp_show_final_order_aggregation ta
    ON aw.ORIG_ORDER_ID = ta.orderid
      AND aw.ALLOCATIONS_ORDER_MANAGER = ta.Manager
  SET aw.PM_ORDER_ID = CONCAT(finalorderid, '-', ta.Manager);


  INSERT INTO processing_status
  values (processDate_in, 'Step 19  - setup temp_aggregate_accounts_for_desk_working', now());
  DROP TABLE IF EXISTS temp_aggregate_accounts_for_desk_working;

  CREATE TABLE `temp_aggregate_accounts_for_desk_working`
  (
    `Start_Date` datetime                              DEFAULT NULL,
    `End_Date`   datetime                              DEFAULT NULL,
    `OrderType`  varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `SecurityID` varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `Trader`     varchar(30) COLLATE latin1_general_ci DEFAULT NULL,
    `Side`       char(1) COLLATE latin1_general_ci     DEFAULT NULL,
    `OrderID`    varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `Client`     varchar(10) COLLATE latin1_general_ci DEFAULT NULL
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_aggregate_accounts_for_desk_working
  SELECT MIN(orig_order_trader_date)
       , MAX(LAST_FILL_DATE)
       , order_type
       , SEC_ID
       , trader_name
       , SIDE
       , ORIG_ORDER_ID
       , 'acadian'
  FROM temp_aggregated_info_working
  WHERE Program = 'Non-Program'
    AND IPO != 'IPO'
    AND ORIG_ORDER_CREATE_DATE IS NOT NULL
  GROUP BY ORIG_ORDER_ID
  ORDER BY ORIG_ORDER_ID;

  insert into processing_status values (processDate_in, 'Step 20  - Start process_desk_orders_routine', now());
  CALL process_desk_orders_routine;
  insert into processing_status values (processDate_in, 'Step 20 - End process_desk_orders_routine', now());


  insert into processing_status values (processDate_in, 'Step 21  - Update  temp_aggregated_info_working', now());
  UPDATE temp_aggregated_info_working aw JOIN temp_show_final_desk_aggregation tfa
    ON
      aw.ORIG_ORDER_ID = tfa.orderid
  SET DESK_ORDER_ID = finaldeskid;


  insert into processing_status values (processDate_in, 'Step 22  - set up  temp_convert_secs_check_prices', now());
  DROP TABLE IF EXISTS temp_convert_secs_check_prices;

  CREATE TABLE `temp_convert_secs_check_prices`
  (
    `ticker`          varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `cusip`           varchar(10) COLLATE latin1_general_ci DEFAULT NULL,
    `sedol`           varchar(45) COLLATE latin1_general_ci DEFAULT NULL,

    `isin`            varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `country`         varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `sjls_ticker`     varchar(45) COLLATE latin1_general_ci DEFAULT NULL,

    `sjls_secid`      char(18) COLLATE latin1_general_ci    DEFAULT NULL,
    `Date_Generated`  date                                  DEFAULT NULL,
    `Date_Closed`     date                                  DEFAULT NULL,

    `orderid`         varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `Price`           double                                DEFAULT NULL,
    `Status`          varchar(45) COLLATE latin1_general_ci DEFAULT NULL,

    `LowPrice`        double                                DEFAULT NULL,
    `HighPrice`       double                                DEFAULT NULL,
    `Currency`        char(3) COLLATE latin1_general_ci     DEFAULT NULL,

    `PxTimes100`      double                                DEFAULT NULL,
    `PxDiv100`        double                                DEFAULT NULL,
    `PxTimesFx`       double                                DEFAULT NULL,
    `PxDivFx`         double                                DEFAULT NULL,
    `FXRate`          double                                DEFAULT NULL,

    `sjls_currency`   char(3) COLLATE latin1_general_ci     DEFAULT NULL,
    `pm_order_id`     varchar(68) COLLATE latin1_general_ci DEFAULT NULL,
    `bs_order_id`     varchar(68) COLLATE latin1_general_ci DEFAULT NULL,
    `broker_order_id` varchar(68) COLLATE latin1_general_ci DEFAULT NULL,

    KEY `idx1` (`orderid`),
    KEY `idx2` (`cusip`, `country`, `sjls_secid`, `Date_Generated`),
    KEY `idx3` (`sedol`, `country`, `sjls_secid`, `Date_Generated`),
    KEY `idx4` (`ticker`, `country`, `sjls_secid`, `Date_Generated`),
    KEY `idx5` (`sjls_secid`, `Date_Generated`, `Date_Closed`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  insert into processing_status values (processDate_in, 'Step 22.1', now());

  INSERT INTO temp_convert_secs_check_prices
  ( ticker
  , cusip
  , sedol
  , country
  , Date_Generated
  , Date_Closed
  , orderid
  , Price
  , Currency
  , pm_order_id
  , bs_order_id
  , broker_order_id)
  SELECT IF(INSTR(aw.ticker, ' ') > 0,
            CONCAT(REPLACE(aw.ticker, ' ', '.'), ' ', TRIM(map.country)),
            CONCAT(TRIM(aw.ticker), ' ', TRIM(map.country)))
       , LEFT(aw.cusip, 8)
       , LEFT(aw.sedol, 6)
       , TRIM(map.country)
       , aw.create_date
       , aw.last_fill_date
       , aw.order_id
       , SUM(aw.allocations_exec_amt) / SUM(aw.allocations_exec_qty)
       , loc_crrncy_cd
       , aw.PM_ORDER_ID
       , aw.DESK_ORDER_ID
       , aw.BROKER_ORDER_ID
  FROM temp_aggregated_info_working aw
         JOIN acadian_country_mapping map
              ON
                aw.list_exch_cd = map.exchange
  GROUP BY aw.order_id;

  SELECT NOW() AS `check_security_id_prices_routine`;
  insert into processing_status values (processDate_in, 'Step 23  - Start check_securityid_prices_routine', now());
  call check_securityid_prices_routine(processDate_in);
  insert into processing_status values (processDate_in, 'Step 23  - End check_securityid_prices_routine', now());


  UPDATE temp_convert_secs_check_prices
  SET `status` = 'Order of Magnitude',
      Price    = PxTimes100
  WHERE `status` = 'Suspect'
    AND PxTimes100 < HighPrice * 1.1
    AND PxTimes100 > LowPrice * .9;


  insert into processing_status values (processDate_in, 'Step 23.2', now());


  UPDATE temp_convert_secs_check_prices
  SET `status` = 'Order of Magnitude',
      Price    = PxDiv100
  WHERE `status` = 'Suspect'
    AND PxDiv100 < HighPrice * 1.1
    AND PxDiv100 > LowPrice * .9;

  ##Given what we see in Acadian data, also check for two orders of Magnitude off -- Lucky Yona

  UPDATE temp_convert_secs_check_prices
  SET `status` = 'Order of Magnitude',
      Price    = PxTimes100 * 100
  WHERE `status` = 'Suspect'
    AND PxTimes100 * 100 < HighPrice * 1.1
    AND PxTimes100 * 100 > LowPrice * .9; #MM attempt


  UPDATE temp_convert_secs_check_prices
  SET `status` = 'Order of Magnitude',
      Price    = PxDiv100 / 100
  WHERE `status` = 'Suspect'
    AND PxDiv100 / 100 < HighPrice * 1.1
    AND PxDiv100 / 100 > LowPrice * .9;


  insert into processing_status values (processDate_in, 'Step 23.3', now());

  UPDATE temp_convert_secs_check_prices
  SET `status` = 'FX Adjust',
      Price    = PxTimesFX
  WHERE `status` = 'Suspect'
    AND PxTimesFX < HighPrice * 1.1
    AND PxTimesFX > LowPrice * .9;

  insert into processing_status values (processDate_in, 'Step 23.4', now());


  UPDATE temp_convert_secs_check_prices
  SET `status` = 'FX Adjust',
      Price    = PxDivFX
  WHERE `status` = 'Suspect'
    AND PxDivFX < HighPrice * 1.1
    AND PxDivFX > LowPrice * .9;

  insert into processing_status values (processDate_in, 'Step 23.5', now());


  UPDATE temp_convert_secs_check_prices
  SET `status` = 'Outlier'
  WHERE `status` = 'Suspect'
    AND ((Price > HighPrice * 1.2) OR (Price < LowPrice * .8));

  insert into processing_status
  values (processDate_in, 'Step 24.1  - Update temp_aggregated_info_working commissions for order of mag', now());

  UPDATE
    temp_aggregated_info_working a, temp_convert_secs_check_prices b
  SET a.sec_check_status = b.status
  WHERE b.`status` in ('FX Adjust', 'Order of Magnitude', 'Outlier')
    AND a.order_id = b.orderid;

  DROP TABLE IF EXISTS temp_commission_magnitude_adjust;
  CREATE TABLE
    temp_commission_magnitude_adjust
  (
    INDEX (order_id),
    adjust_ratio decimal(14, 6) NOT NULL DEFAULT 0
  )
  SELECT order_id,
         adjusted_price,
         SUM(allocations_exec_amt) /
         SUM(allocations_exec_qty) as price_orig,
         0                         as adjust_ratio
  FROM temp_aggregated_info_working
  WHERE sec_check_status IN ('FX Adjust', 'Order of Magnitude', 'Outlier')
  GROUP BY order_id;

  UPDATE temp_aggregated_info_working a, temp_convert_secs_check_prices b
  SET allocations_exec_amt   = allocations_exec_qty * b.Price,
      allocations_target_amt = allocations_target_qty * b.Price,
      adjusted_price         = b.price
  WHERE b.`status` in ('FX Adjust', 'Order of Magnitude', 'Outlier')
    AND a.order_id = b.orderid;

  UPDATE
    temp_commission_magnitude_adjust a, temp_aggregated_info_working b
  SET a.adjusted_price = b.adjusted_price
  WHERE a.order_id = b.order_id;

  UPDATE temp_commission_magnitude_adjust
  SET adjust_ratio = adjusted_price / price_orig;

  insert into processing_status
  values (processDate_in, 'Step 24.1  - Update temp_aggregated_info_working commissions for order of mag', now());
  UPDATE temp_aggregated_info_working a, temp_commission_magnitude_adjust b
  SET a.ALLOCATIONS_TOT_COMMISSION = a.ALLOCATIONS_TOT_COMMISSION * b.adjust_ratio
  WHERE a.order_id = b.order_id;

  UPDATE temp_placements_working a, temp_commission_magnitude_adjust b
  SET a.PLC_COMMISSIONS = a.PLC_COMMISSIONS * b.adjust_ratio
  WHERE a.order_id = b.order_id;

  insert into processing_status values (processDate_in, 'Step 24.1  - Update temp_aggregated_info_working', now());
  UPDATE temp_aggregated_info_working aw, temp_convert_secs_check_prices cp
  SET aw.SJLS_TICKER      = cp.sjls_ticker
    , aw.SJLS_CURRENCY    = cp.sjls_currency
    , aw.SJLS_secid       = cp.sjls_secid
    , aw.Sec_CHECK_STATUS = cp.status
  WHERE aw.order_id = cp.orderid;

  insert into processing_status values (processDate_in, 'Step 24.2', now());
  UPDATE temp_aggregated_info_working
  set exchange_code=right(SJLS_TICKER, 2)
  where SJLS_TICKER is not null;


  UPDATE temp_aggregated_info_working
  SET days_to_settle =
        IF(dayofweek(settle_date) < dayofweek(trade_date),
           days_to_settle - 2,
           days_to_settle);

  alter table temp_aggregated_info_working
    add index by_exchange_code (exchange_code);


  insert into processing_status values (processDate_in, 'Step 24.4', now());
  call time_zone_conversion_routine(processDate_in);

  insert into processing_status values (processDate_in, 'Step 24.5', now());
  UPDATE temp_aggregated_info_working a, market_data.exchange_rates b
  SET sjls_exchange_rate = '1' / exchange_rate
  WHERE a.sjls_currency = b.currency
    AND DATE(a.last_fill_date_adj) = b.trade_date;

  insert into processing_status values (processDate_in, 'Step 24.6', now());
  UPDATE temp_aggregated_info_working a, market_data.exchange_rates b
  SET sjls_exchange_rate = '1' / exchange_rate
  WHERE a.sjls_currency = b.currency
    AND (DATE(a.last_fill_date_adj) - INTERVAL 1 DAY) = b.trade_date
    AND sjls_currency != 'USD'
    AND sjls_exchange_rate = '1.0000';

  UPDATE temp_aggregated_info_working a, acadian_country_mapping b
  SET a.region = b.region
  WHERE a.exchange_code = b.country;

  insert into processing_status values (processDate_in, 'Step 25 - Call process_broker_view_prices', now());


  CALL process_broker_view_prices(processDate_in);


  insert into processing_status values (processDate_in, 'Step 25  - delete from standard output', now());


  alter table temp_aggregated_info_working
    add index by_pm_order_id (pm_order_id),
    add index by_desk_order_id (desk_order_id);


  SELECT NOW() AS `Insert into standardoutput`;
  TRUNCATE standardoutput;

  insert into processing_status values (processDate_in, 'Step 26  - build standard output Allocation View', now());
  INSERT INTO standardoutput
  ( date_time_gen
  , date_time_sent
  , date_time_closed
  , client_code
  , pm_order_id
  , source
  , side
  , shares_executed
  , shares_ordered
  , security_id
  , security_id_type
  , ordertype
  , time_in_force
  , limit_price
  , average_exec_price
  , broker
  , trader
  , country
  , level1
  , level2
  , level3
  , level4
  , level5
  , level6
  , level7
  , level8
  , level9
  , level10
  , strategy
  , algorithm
  , traderteam
  , total_commissions
  , account
  , currency
  , settlement_currency
  , subaccount
  , instructions
  , venue
  , tax
  , sjls_secid
  , file_date)
  SELECT MIN(orig_order_create_date_adj) AS orig_order_create_date
       , MIN(orig_order_trader_date_adj) AS orig_order_trader_date
       , MAX(last_fill_date_adj)
       , 'acadian'
       , CONCAT(ORIG_ORDER_ID, '-', ALLOCATIONS_ACCT_CD)
       , 'UPLOAD'
       , LEFT(SIDE, 1)
       , SUM(allocations_exec_qty)
       , SUM(allocations_target_qty)
       , sjls_ticker
       , 'BLOOMBERG'
       , order_type
       , order_duration
       , IF(side = 'S',
            MAX(ORDERS_LIMIT),
            MIN(ORDERS_LIMIT))
       , SUM(allocations_exec_amt) / SUM(allocations_exec_qty)
       , IF(MIN(BROKER_NAME) = MAX(BROKER_NAME),
            MIN(BROKER_NAME),
            'MULTI')
       , IF(MIN(trader_NAME) = MAX(trader_NAME),
            MIN(trader_NAME),
            'MULTI')
       , RIGHT(sjls_ticker, 2)
       , IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER),
            MIN(ALLOCATIONS_ORDER_MANAGER),
            IF(ALLOCATIONS_ORDER_MANAGER IS NULL,
               'NOT PROVIDED',
               'MULTI'))
       , trans_type
       , CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
       , REASON_CODE
       , MTH_Decile
       , THA_Decile

       , IF(MIN(principal_agency) = MAX(principal_agency),
            MIN(principal_agency),
            'MULTI')
       , IPO
       ,'No Score'
       , CONCAT_WS('~', 'Tick Pilot', 'No Score', IFNULL(sedol, 'N.A.'), IFNULL(cusip, 'N.A.'), 'Start Time Bucket',
                   'Child_Orders', Security_Type)

       , 'N.A.'
       , IF(ALGO_STRATEGY = '' OR ALGO_STRATEGY = 'N.A.', 'N.A.', CONCAT(PARENT_BROKER, '-', ALGO_STRATEGY))
       , cntry_of_risk
       , SUM(aw.ALLOCATIONS_TOT_COMMISSION)
       , IF(MIN(ALLOCATIONS_ACCT_CD) = MAX(ALLOCATIONS_ACCT_CD),
            MIN(ALLOCATIONS_ACCT_CD),
            'MULTI')
       , sjls_currency
       , sjls_currency

       , 'N.A.'
       , IFNULL(GROUP_CONCAT(DISTINCT BROKER_REASON ORDER BY BROKER_REASON SEPARATOR '-'), 'N.A.')
       , IF(MIN(Venue) = MAX(Venue), MIN(Venue), 'MULTI')
       , adjust_ratio
       , sjls_secid
       , processdate_in

  FROM temp_aggregated_info_working aw
  WHERE sjls_ticker IS NOT NULL
  GROUP BY ORIG_ORDER_ID, ALLOCATIONS_ACCT_CD;


  insert into processing_status values (processDate_in, 'Step 27  - build standard output Trading View', now());
  INSERT INTO standardoutput
  ( date_time_gen
  , date_time_sent
  , date_time_closed
  , client_code
  , pm_order_id
  , bs_order_id
  , source
  , side
  , shares_executed
  , shares_ordered
  , security_id
  , security_id_type
  , ordertype
  , time_in_force
  , limit_price
  , average_exec_price
  , broker
  , trader
  , country
  , level1
  , level2
  , level3
  , level4
  , level5
  , level6
  , level7
  , level8
  , level9
  , level10
  , strategy
  , algorithm
  , traderteam
  , total_commissions
  , account
  , currency
  , settlement_currency
  , subaccount
  , instructions
  , venue
  , tax
  , sjls_secid
  , file_date)
  SELECT MIN(orig_order_create_date_adj) # Formerly  (orig_order_trader_date_adj)
       , MIN(orig_order_create_date_adj)
       , MAX(last_fill_date_adj)
       , 'acadian'
       , PM_ORDER_ID
       , IF(MIN(REASON_CODE) = MAX(REASON_CODE), ORIG_ORDER_ID, CONCAT(ORIG_ORDER_ID, '-', REASON_CODE))
       , 'UPLOAD'
       , LEFT(SIDE, 1)
       , SUM(allocations_exec_qty)
       , SUM(allocations_target_qty)
       , sjls_ticker
       , 'BLOOMBERG'
       , order_type
       , order_duration
       , IF(side = 'S',
            MAX(ORDERS_LIMIT),
            MIN(ORDERS_LIMIT))
       , SUM(allocations_exec_amt) / SUM(allocations_exec_qty)
       , IF(MIN(BROKER_NAME) = MAX(BROKER_NAME),
            MIN(BROKER_NAME),
            'MULTI')

       , MIN(trader_NAME)

       , RIGHT(sjls_ticker, 2)
       , IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER),
            MIN(ALLOCATIONS_ORDER_MANAGER),
            if(ALLOCATIONS_ORDER_MANAGER IS NULL, 'NOT PROVIDED', 'MULTI'))
       , trans_type
       , CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
       , REASON_CODE
       , MTH_Decile
       , THA_Decile
       , IF(MIN(principal_agency) = MAX(principal_agency),
            MIN(principal_agency),
            'MULTI')
       , IPO

       , 'No Score'
       , CONCAT_WS('~', 'Tick Pilot', 'No Score', IFNULL(sedol, 'N.A.'), IFNULL(cusip, 'N.A.'), 'Start Time Bucket',
                   'Child_Orders', Security_Type)

       , 'N.A.'
       , IF(ALGO_STRATEGY = '' OR ALGO_STRATEGY = 'N.A.', 'N.A.', CONCAT(PARENT_BROKER, '-', ALGO_STRATEGY))
       , cntry_of_risk
       , SUM(aw.ALLOCATIONS_TOT_COMMISSION)
       , IF(MIN(ALLOCATIONS_ACCT_CD) = MAX(ALLOCATIONS_ACCT_CD),
            MIN(ALLOCATIONS_ACCT_CD),
            'MULTI')
       , sjls_currency
       , sjls_currency

       , 'N.A.'
       , IFNULL(GROUP_CONCAT(DISTINCT BROKER_REASON ORDER BY BROKER_REASON SEPARATOR '-'), 'N.A.')
       , IF(MIN(Venue) = MAX(Venue), MIN(Venue), 'MULTI')
       , adjust_ratio
       , sjls_secid
       , processdate_in

  FROM temp_aggregated_info_working aw
  WHERE sjls_ticker IS NOT NULL
  GROUP BY ORIG_ORDER_ID, REASON_CODE;


  insert into processing_status values (processDate_in, 'Step 28  - build standard output TX', now());

  INSERT INTO standardoutput
  ( date_time_gen
  , date_time_sent
  , date_time_closed
  , client_code
  , pm_order_id
  , BROKER_ORDER_ID
  , source
  , side
  , shares_executed
  , shares_ordered
  , security_id
  , security_id_type
  , ordertype
  , time_in_force
  , limit_price
  , average_exec_price
  , broker
  , trader
  , country
  , level1
  , level2
  , level3
  , level4
  , level5
  , level6
  , level7
  , level8
  , level9
  , level10
  , strategy
  , algorithm
  , traderteam
  , total_commissions
  , account
  , currency
  , settlement_currency
  , subaccount
  , instructions
  , venue
  , tax
  , sjls_secid
  , file_date)
  SELECT MIN(orig_order_trader_date_adj) # Formerly  (orig_order_trader_date_adj)
       , MIN(orig_order_trader_date_adj)
       , MAX(last_fill_date_adj)
       , 'acadian'
       , PM_ORDER_ID
       , IF(MIN(REASON_CODE) = MAX(REASON_CODE), DESK_ORDER_ID, CONCAT(DESK_ORDER_ID, '-', REASON_CODE))
       , 'UPLOAD'
       , LEFT(SIDE, 1)
       , SUM(allocations_exec_qty)
       , SUM(allocations_target_qty)
       , sjls_ticker
       , 'BLOOMBERG'
       , order_type
       , order_duration
       , IF(side = 'S',
            MAX(ORDERS_LIMIT),
            MIN(ORDERS_LIMIT))
       , SUM(allocations_exec_amt) / SUM(allocations_exec_qty)
       , IF(MIN(BROKER_NAME) = MAX(BROKER_NAME),
            MIN(BROKER_NAME),
            'MULTI')

       , MIN(trader_NAME)

       , RIGHT(sjls_ticker, 2)
       , IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER),
            MIN(ALLOCATIONS_ORDER_MANAGER),
            if(ALLOCATIONS_ORDER_MANAGER IS NULL, 'NOT PROVIDED', 'MULTI'))
       , trans_type
       , CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
       , REASON_CODE
       , MTH_Decile
       , THA_Decile
       , IF(MIN(principal_agency) = MAX(principal_agency),
            MIN(principal_agency),
            'MULTI')
       , IPO

       , 'No Score'
       , CONCAT_WS('~', 'Tick Pilot', 'No Score', IFNULL(sedol, 'N.A.'), IFNULL(cusip, 'N.A.'), 'Start Time Bucket',
                   'Child_Orders', Security_Type)

       , 'N.A.'
       , IF(ALGO_STRATEGY = '' OR ALGO_STRATEGY = 'N.A.', 'N.A.', CONCAT(PARENT_BROKER, '-', ALGO_STRATEGY))
       , cntry_of_risk
       , SUM(aw.ALLOCATIONS_TOT_COMMISSION)
       , IF(MIN(ALLOCATIONS_ACCT_CD) = MAX(ALLOCATIONS_ACCT_CD),
            MIN(ALLOCATIONS_ACCT_CD),
            'MULTI')
       , sjls_currency
       , sjls_currency

       , 'N.A.'
       , IFNULL(GROUP_CONCAT(DISTINCT BROKER_REASON ORDER BY BROKER_REASON SEPARATOR '-'), 'N.A.')
       , IF(MIN(Venue) = MAX(Venue), MIN(Venue), 'MULTI')
       , adjust_ratio
       , sjls_secid
       , processdate_in

  FROM temp_aggregated_info_working aw
  WHERE sjls_ticker IS NOT NULL
  GROUP BY DESK_ORDER_ID, REASON_CODE;


  SELECT NOW() AS `INSERT INTO standardoutput for Venue`;
  INSERT INTO processing_status VALUES (processDate_in, '29 - AX', now());
  INSERT IGNORE INTO standardoutput
  ( date_time_gen
  , date_time_sent
  , date_time_closed
  , client_code
  , pm_order_id
  , venue_order_id
  , source
  , side
  , shares_executed
  , shares_ordered
  , security_id
  , security_id_type
  , ordertype
  , time_in_force
  , limit_price
  , average_exec_price
  , broker
  , trader
  , country
  , level1
  , level2
  , level3
  , level4
  , level5
  , level6
  , level7
  , level8
  , level9
  , level10
  , strategy
  , algorithm
  , traderteam
  , total_commissions
  , account
  , currency
  , settlement_currency
  , subaccount
  , instructions
  , venue
  , tax
  , sjls_secid
  , file_date)
  SELECT MIN(orig_order_create_date_adj)
       , MIN(orig_order_create_date_adj)
       , MAX(last_fill_date_adj)
       , 'acadian'
       , PM_ORDER_ID
       , CONCAT(pm_order_id, "-", acct_name)
       , 'UPLOAD'
       , LEFT(SIDE, 1)
       , SUM(allocations_exec_qty)
       , SUM(allocations_target_qty)
       , sjls_ticker
       , 'BLOOMBERG'
       , order_type
       , order_duration
       , IF(side = 'S',
            MAX(ORDERS_LIMIT),
            MIN(ORDERS_LIMIT))
       , SUM(allocations_exec_amt) / SUM(allocations_exec_qty)
       , IF(MIN(BROKER_NAME) = MAX(BROKER_NAME),
            MIN(BROKER_NAME),
            'MULTI')

       , MIN(trader_NAME)

       , RIGHT(sjls_ticker, 2)
       , IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER),
            MIN(ALLOCATIONS_ORDER_MANAGER),
            if(ALLOCATIONS_ORDER_MANAGER IS NULL, 'NOT PROVIDED', 'MULTI'))
       , trans_type
       , CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
       , REASON_CODE
       , MTH_Decile
       , THA_Decile
       , IF(MIN(principal_agency) = MAX(principal_agency),
            MIN(principal_agency),
            'MULTI')
       , IPO

       , 'No Score'
       , CONCAT_WS('~', 'Tick Pilot', 'No Score', IFNULL(sedol, 'N.A.'), IFNULL(cusip, 'N.A.'), 'Start Time Bucket',
                   'N.A.', Security_Type)

       , 'N.A.'
       , IF(ALGO_STRATEGY = '' OR ALGO_STRATEGY = 'N.A.', 'N.A.', CONCAT(PARENT_BROKER, '-', ALGO_STRATEGY))
       , cntry_of_risk
       , SUM(aw.ALLOCATIONS_TOT_COMMISSION)
       , IF(MIN(ALLOCATIONS_ACCT_CD) = MAX(ALLOCATIONS_ACCT_CD),
            MIN(ALLOCATIONS_ACCT_CD),
            'MULTI')
       , sjls_currency
       , sjls_currency

       , 'N.A.'
       , IFNULL(GROUP_CONCAT(DISTINCT BROKER_REASON ORDER BY BROKER_REASON SEPARATOR '-'), 'N.A.')
       , IF(MIN(Venue) = MAX(Venue), MIN(Venue), 'MULTI')
       , adjust_ratio
       , sjls_secid
       , processDate_in

  FROM temp_aggregated_info_working aw
  WHERE sjls_ticker IS NOT NULL
  GROUP BY pm_order_id, ALLOCATIONS_ACCT_CD;


  insert into processing_status values (processDate_in, '30 -Overlapping', now());


  UPDATE standardoutput
  SET date_time_closed = date_time_gen + INTERVAL 1 SECOND
  WHERE date_time_gen >= Date_time_Closed;
  UPDATE standardoutput
  SET time_in_force = 'DAY'
  WHERE time_in_force IN ('D', 'Day');

  insert into processing_status values (processDate_in, '34 - MOO,MOC', now());

  update standardoutput
  set date_time_gen = if(date(date_time_closed) + interval 7 hour < date_time_closed,
                         cast(date(date_time_closed) + interval 7 hour as datetime),
                         cast((date_time_closed - interval 5 minute) as datetime)),
      status        = 'update times for moo and moc'
  where time_in_force = 'ON_CLOSE'
    and date(date_time_gen) <> date(date_time_closed)
    and file_date = processDate_in
    and broker_order_id is null;

  insert into processing_status values (processDate_in, 'Step 36  - DELETE FROM standard output FOR county CB', now());

  call process_standardoutput_fills_aggregate_routine(processDate_in);

  insert into processing_status values (processDate_in, 'Step 37  - Truncate standardformat', now());
  SELECT CURRENT_DATE(), CURRENT_TIME();

  UPDATE standardoutput
  SET limit_price = CASE
                      WHEN limit_price > 100 * average_exec_price THEN NULL
                      WHEN limit_price < average_exec_price / 100 THEN NULL
                      ELSE limit_price
    END;

  UPDATE standardoutput
  SET shares_ordered = 0
  WHERE shares_ordered IS NULL;

  UPDATE standardoutput
  SET shares_executed = 0
  WHERE shares_executed IS NULL;


  ## Need a means to show the client what original order_ids constitute stitched orders as per Jigger's request. Lucky Yona 12/12/18

  drop table if exists child_orders;
  create table child_orders
  (
    PM_ORDER_ID  VARCHAR(25) COLLATE latin1_general_ci    default NULL,
    BS_ORDER_ID  VARCHAR(25) COLLATE latin1_general_ci    default NULL,
    CHILD_ORDERS VARCHAR(15000) COLLATE latin1_general_ci default NULL,
    KEY idx (PM_ORDER_ID, BS_ORDER_ID)
  )
    ENGINE = 'MyISAM';

  insert into child_orders (select PM_ORDER_ID, NULL, group_concat(distinct order_id separator '-')
                            from temp_aggregated_info_working
                            group by PM_ORDER_ID);

  insert into child_orders (select NULL, DESK_ORDER_ID, group_concat(distinct order_id separator '-')
                            from temp_aggregated_info_working
                            group by DESK_ORDER_ID);

  delete from child_orders where CHILD_ORDERS not regexp '-';

  update standardoutput s, child_orders c
  set level10 = replace(level10, 'Child_Orders', c.CHILD_ORDERS)
  where s.pm_order_id = c.PM_ORDER_ID
    and c.BS_ORDER_ID is null;

  update standardoutput s, child_orders c
  set level10 = replace(level10, 'Child_Orders', c.CHILD_ORDERS)
  where s.bs_order_id = c.BS_ORDER_ID
    and c.PM_ORDER_ID is null;


  update standardoutput
  set level10 = replace(level10, 'Child_Orders', 'N.A.');

  ########


  insert into processing_status values (processDate_in, 'Step 37 - Calculate overlapping shares', now());


  DROP TABLE IF EXISTS temp_overlapping_shares;
  CREATE TABLE `temp_overlapping_shares`
  (
    `pmorderid`       varchar(64) COLLATE latin1_general_ci DEFAULT NULL,
    `bsorderid`       varchar(64) COLLATE latin1_general_ci DEFAULT NULL,
    `symbol`          varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `side`            char(2) COLLATE latin1_general_ci     DEFAULT NULL,
    `shares_executed` int(11)                               DEFAULT NULL,
    `datetime_gen`    datetime                              DEFAULT NULL,
    `datetime_closed` datetime                              DEFAULT NULL,
    KEY `idx1` (`bsorderid`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_overlapping_shares
    (SELECT pm_order_id
          , bs_order_id
          , sjls_secid
          , side
          , shares_executed
          , date_time_gen
          , date_time_closed
     FROM standardoutput
     WHERE bs_order_id IS NOT NULL
       AND broker_order_id IS NULL
       AND sjls_secid IS NOT NULL
       AND DATE(date_time_closed) > CURDATE() - INTERVAL 7 DAY
     GROUP BY bs_order_id);

  CALL get_overlapping_shares_routine(processDate_in);

  CALL process_input_for_pm_orders_aggregation_routine(processDate_in);

  CALL process_pm_orders_aggregation_routine(processDate_in);


  UPDATE standardoutput
  SET level5 = 'N.A.'
  WHERE level3 LIKE '%Suspect%'
     OR level3 LIKE '%NULL%';


  UPDATE standardoutput s , cloned_pt.tick_pilot_list t
  SET level10 = REPLACE(s.level10, 'Tick Pilot', t.`Group`)
  WHERE s.sjls_secid = t.sjls_secid;
  UPDATE standardoutput s SET level10 = REPLACE(s.level10, 'Tick Pilot', 'Not Applicable');

  #Bucket the deciles as requested by Joel Feinberg. Changes made by Lucky Yona
  call process_alpha_score_buckets();

  Delete from standardoutput where currency in ('VND', 'KWD');


  # Lucky Yona - 10/25/2018. Correcting for a few orders where we get Major minor wrong. List of ORDER_IDs in mm_correction table - Update as needed.

  UPDATE standardoutput s, major_minor_correction m
  SET average_exec_price = m.Price
  WHERE s.pm_order_id = m.ORDER_ID
    AND m.VIEW regexp 'PM';

  UPDATE standardoutput s, major_minor_correction m
  SET average_exec_price = m.price
  WHERE bs_order_id = m.ORDER_ID
    AND m.VIEW regexp 'DESK';


  UPDATE standardoutput s, major_minor_correction m
  SET average_exec_price = m.Price
  WHERE broker_order_id = m.ORDER_ID
    AND m.VIEW regexp 'BROKER';

  ########

  call process_time_buckets(processDate_in);

  TRUNCATE TABLE standardformat;

  insert into processing_status values (processDate_in, 'Step 38  - Insert to standardformat', now());
  INSERT IGNORE INTO standardformat
  (date_time_gen,
   date_time_sent,
   date_time_closed,
   client_code,
   pm_order_id,
   bs_order_id,
   broker_order_id,
   venue_order_id,
   source,
   side,
   shares_executed,
   shares_ordered,
   security_id,
   security_id_type,
   ordertype,
   time_in_force,
   limit_price,
   average_exec_price,
   broker,
   venue,
   trader,
   `algorithm`,
   country,
   level1,
   level2,
   level3,
   level4,
   level5,
   level6,
   level7,
   level8,
   level9,
   level10,
   instructions,
   total_commissions,
   moo_shares,
   moc_shares,
   tax,
   other_fee,
   account,
   subaccount,
   strategy,
   traderteam,
   client_benchmark,
   currency,
   settlement_currency,
   datetime_ope,
   executed_shares_interval_ope,
   overlapping_shares_same,
   overlapping_shares_opposite,
   symbol,
   symbol2)
  SELECT date_time_gen,
         date_time_sent,
         date_time_closed,
         TRIM(client_code),
         TRIM(pm_order_id),
         TRIM(bs_order_id),
         TRIM(broker_order_id),
         TRIM(venue_order_id),
         TRIM(source),
         TRIM(side),
         TRIM(shares_executed),
         TRIM(shares_ordered),
         TRIM(security_id),
         TRIM(security_id_type),
         TRIM(ordertype),
         TRIM(time_in_force),
         TRIM(limit_price),
         TRIM(average_exec_price),
         TRIM(broker),
         TRIM(venue),
         TRIM(trader),
         TRIM(`algorithm`),
         TRIM(country),
         TRIM(level1),
         TRIM(level2),
         TRIM(level3),
         TRIM(level4),
         TRIM(level5),
         TRIM(level6),
         TRIM(level7),
         TRIM(level8),
         TRIM(level9),
         TRIM(level10),
         TRIM(instructions),
         TRIM(total_commissions),
         TRIM(moo_shares),
         TRIM(moc_shares),
         TRIM(tax),
         TRIM(other_fee),
         TRIM(account),
         TRIM(subaccount),
         TRIM(strategy),
         TRIM(traderteam),
         TRIM(client_benchmark),
         TRIM(currency),
         TRIM(settlement_currency),
         TRIM(datetime_ope),
         TRIM(executed_shares_interval_ope),
         TRIM(overlapping_shares_same),
         TRIM(overlapping_shares_opposite),
         TRIM(symbol),
         TRIM(symbol2)
  FROM standardoutput
  WHERE file_date = processDate_in
    and date_time_gen is not null
    and date_time_closed is not null;

  insert into processing_status values (processDate_in, 'END Process', now());

END;

