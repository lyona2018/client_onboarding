create procedure process_routine(IN processDate_in date)
BEGIN

  -- test --

  /*CD removed JH as definer - 7/30/2018 */ # recent

  insert into processing_status values (processDate_in, 'Step 1 - set up temp_account_manager_mapping', now());
  DROP TABLE IF EXISTS temp_account_manager_mapping;
  CREATE TABLE `temp_account_manager_mapping`
  (
    `Acct_Cd`   varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `Acct_Name` varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `Manager`   varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `User_Cd`   varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `User_Name` varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `Init`      varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    KEY `idx1` (`Acct_Cd`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  /* update to broker map lines 24-3 - change made by Joe Hipps on 7/18/2018 */
  INSERT INTO temp_account_manager_mapping
    (SELECT Acct_Cd, Acct_Name, Manager, User_Cd, User_Name, Init
     FROM mfs2_data.funds fr,
          mfs2_data.users ur
     WHERE fr.manager = ur.user_cd
     GROUP BY Acct_Cd);

  /* update to broker map lines 37, 40-81 - change made by Joe Hipps on 7/18/2018 */
  insert into processing_status values (processDate_in, 'Step 2a - set up temp_placements_working', now());
  DROP TABLE IF EXISTS temp_placements_working;
  CREATE TABLE `temp_placements_working`
  (
    `order_id`            varchar(17) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `place_id`            varchar(17) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `exec_broker`         varchar(18) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `place_date`          datetime                              DEFAULT NULL,
    `broker_reason`       varchar(13) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `FCM_BBG`             ENUM ('N.A.', 'FCM', 'BBG')           DEFAULT NULL, #look here
    `create_user`         varchar(18) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `user_name`           varchar(59) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `init`                varchar(7) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `exec_amt`            varchar(22) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `exec_qty`            varchar(22) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `place_qty`           varchar(22) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `instruction`         varchar(10) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `instruction2`        varchar(20) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `limit_price`         varchar(25) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `comments`            varchar(25) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `bkr_cd`              varchar(54) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `bkr_name`            varchar(54) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `bkr_typ_cd`          varchar(10) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `bkr_reason_cd`       varchar(10) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `bkr_cd_4`            varchar(4) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `Broker_Code`         varchar(15) COLLATE latin1_general_ci DEFAULT NULL, -- from mfs schema and used for xip data
    `Broker_Name`         varchar(60) COLLATE latin1_general_ci DEFAULT NULL, -- from mfs schema and used for xip data
    `Parent_Broker`       varchar(60) COLLATE latin1_general_ci DEFAULT NULL, -- from mfs schema and used for xip data
    `Broker_Type`         varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `ECN/DMA`             varchar(5) COLLATE latin1_general_ci  DEFAULT NULL, -- from mfs schema and used for xip data
    `PTCOMM`              varchar(5) COLLATE latin1_general_ci  DEFAULT NULL, -- from mfs schema and used for xip data
    `ALGO/ATS`            varchar(5) COLLATE latin1_general_ci  DEFAULT NULL, -- from mfs schema and used for xip data
    `Crossnet`            varchar(5) COLLATE latin1_general_ci  DEFAULT NULL, -- from mfs schema and used for xip data
    `DarkPool`            varchar(5) COLLATE latin1_general_ci  DEFAULT NULL, -- from mfs schema and used for xip data
    `min_fill_date`       datetime                              DEFAULT NULL,
    `max_fill_date`       datetime                              DEFAULT NULL,
    `max_fill_date_adj`   datetime                              DEFAULT NULL,
    `fill_qty`            int(10) unsigned                      DEFAULT NULL,
    `fill_amt`            double                                DEFAULT NULL,
    `ORDER_EXEC_QTY`      double                                DEFAULT NULL,
    `ORD_COMMISSIONS`     double                                DEFAULT NULL,
    `FACTOR`              double                                DEFAULT NULL,
    `PLC_COMMISSIONS`     double                                DEFAULT NULL,
    `price`               double                                DEFAULT NULL,
    `multi_placement_tag` varchar(1)                            DEFAULT NULL,
    `ALGO_STRATEGY`       varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `Venue`               varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `VENUE_ORDER_ID`      varchar(50) CHARACTER SET latin1
      COLLATE latin1_general_ci                                 DEFAULT NULL,
    `ORIG_BROKER`         varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    KEY `idx1` (`order_id`),
    KEY `idx2` (`place_id`),
    KEY `idx3` (`broker_code`),
    KEY `idx4` (`exec_broker`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  /* update to broker map lines 85, 87-132 - change made by Joe Hipps on 7/18/2018/ */
  INSERT INTO temp_placements_working
    (SELECT p.order_id,
            p.place_id,
            p.exec_broker,
            CAST(p.place_date AS DATETIME),
            p.broker_reason,
            NULL,
            p.create_user,
            NULL,
            NULL,
            p.exec_amt,
            p.exec_qty,
            p.place_qty,
            IF(LEFT(p.instruction, 1) = 'L', 'LMT', 'MKT') AS instruction,
            IF(p.instruction IS NULL OR p.instruction = '', 'NONE PROVIDED', p.instruction),
            p.limit_price,
            p.comments,
            br.bkr_cd,
            br.bkr_name,
            br.bkr_typ_cd,
            br.bkr_reason_cd,
            LEFT(br.BKR_CD, 4),
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            SUM(a.EXEC_QTY),

            SUM(a.COMMISSION_AMT),
            p.exec_qty / SUM(a.EXEC_QTY),
            p.exec_qty * SUM(a.COMMISSION_AMT) / SUM(a.EXEC_QTY),
            NULL,
            NULL,
            NULL,
            NULL,
            NULL,
            br.BKR_CD
     FROM mfs2_data.placements p
            LEFT JOIN mfs2_data.brokers br ON p.exec_broker = br.bkr_cd #look here
            LEFT JOIN mfs2_data.allocations a ON p.order_id = a.order_id
     GROUP BY a.order_id, p.place_id);


  truncate mfstca_brkclass;
  insert into mfstca_brkclass select * from mfs2_data.mfstca_brkclass;


  # Pulling algo strategy from fix # Lucky Yona 08/06/2018
  insert into processing_status values (processDate_in, 'Setup temp_fix_working', now());
  DROP TABLE IF EXISTS temp_fix_working;
  CREATE TABLE `temp_fix_working`
  (
    `PLACE_ID`      decimal(10, 0) DEFAULT NULL,
    `ALGO_STRATEGY` varchar(50) CHARACTER SET latin1
      COLLATE latin1_general_ci    DEFAULT NULL,
    KEY `idx1` (`PLACE_ID`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_cs;

  INSERT INTO temp_fix_working
    (SELECT f.PLACE_ID, f.ALGO_STRATEGY FROM mfs2_data.fix_outgoing f GROUP BY PLACE_ID);

  # Introducing algo strategy to temp_placements_working. Changes Made by Lucky Yona Aug 2018
  UPDATE temp_placements_working p LEFT JOIN temp_fix_working f
    ON p.place_id = f.PLACE_ID
  SET p.ALGO_STRATEGY = f.ALGO_STRATEGY;

  #Update underlying broker for FCM

  update temp_placements_working
  set exec_broker = 'AACM'
  where ALGO_STRATEGY = 'FGBGLSAA';

  update temp_placements_working
  set exec_broker = 'NACM' # Could also be NMCM
  where ALGO_STRATEGY = 'FGBGLSAN';

  update temp_placements_working
  set exec_broker = 'DACM'
  where ALGO_STRATEGY = 'FGBGDARK'
     or exec_broker like 'DF%';

  update temp_placements_working
  set exec_broker = 'PO10' # Could also be PO7 or PM10
  where ALGO_STRATEGY = 'FGBGPOV';

  update temp_placements_working
  set exec_broker = 'FCMS-EQ'
  where ALGO_STRATEGY = 'FGBGVWAP';

  update temp_placements_working
  set exec_broker = 'FCMS-EQ'
  where ALGO_STRATEGY = 'FGBGLSAP';


  # Lucky Yona
  insert into processing_status
  values (processDate_in,
          'Step 2b - update temp_placements_working with broker map',
          now()); #update to broker map lines 130-141
  UPDATE temp_placements_working p JOIN mfs_data.mfstca_brkclass m
    ON LEFT(p.exec_broker, 4) = m.BROKER_CODE #look here
  SET p.Broker_Code   = m.Broker_Code,
      p.Broker_Name   = m.Broker_Name,
      p.Parent_Broker = IFNULL(m.PARENT_BROKER_NAME, m.Broker_Name),
      p.Broker_Type   = m.BROKER_CLASSIFICATION;


  update temp_placements_working
  SET Broker_Code   = exec_broker,
      Broker_Name   = bkr_name,
      Parent_Broker = bkr_name,
      Broker_Type   = 'ALGO/ATS',
      Parent_Broker = bkr_name
  where exec_broker regexp 'ALEX';


  update temp_placements_working
  set Broker_Code   = left(exec_broker, 4),
      Broker_Name   = bkr_name,
      Parent_Broker = bkr_name,
      Broker_Type   = IF(bkr_typ_cd = 'E', 'ALGO/ATS', 'N.A.')
  where Broker_Name is null;

  UPDATE temp_placements_working p
  SET p.FCM_BBG = (
    CASE
      WHEN p.BROKER_NAME LIKE '%FCM%' THEN 'FCM'
      WHEN p.BROKER_NAME LIKE '%BLOOM%'
        OR p.BROKER_NAME LIKE '%BLM%'
        OR p.PARENT_BROKER LIKE '%BLOOM%' THEN 'BBG'
      ELSE 'N.A.'
      END);

  UPDATE temp_placements_working
  set FCM_BBG = 'FCM'
  where exec_broker like '%FCM%';


  /* update to broker map lines 149-1553 - change made by Joe Hipps on 7/18/2018 */
  insert into processing_status values (processDate_in, 'Step 3 - update temp_placements_working', now());
  UPDATE temp_placements_working p JOIN (SELECT * FROM mfs2_data.fills_aggregate GROUP BY placement_id) fa
    ON p.place_id = fa.placement_id
  SET p.min_fill_date     = CAST(fa.min_FILLDATE AS DATETIME),
      p.max_fill_date     = CAST(fa.max_FILLDATE AS DATETIME),
      p.max_fill_date_adj = CAST(fa.max_FILLDATE AS DATETIME),
      p.fill_qty          = fa.SUM_fillqty,
      p.fill_amt          = fa.SUM_fillamt;

  insert into processing_status values (processDate_in, '4 update placements working with orders', now());
  UPDATE temp_placements_working p JOIN mfs2_data.orders o
    ON p.order_id = o.order_id
  SET p.create_user = o.trader;

  insert into processing_status
  values (processDate_in, '5 update placements working with placements working ', now());
  UPDATE temp_placements_working p JOIN temp_placements_working q
    ON p.order_id = q.order_id
  SET p.create_user = q.create_user
  WHERE p.user_name IS NULL
    AND q.user_name IS NOT NULL;

  insert into processing_status values (processDate_in, '6 update placements working with users ', now());
  UPDATE temp_placements_working p JOIN mfs2_data.users u
    ON p.create_user = u.user_cd
  SET p.user_name = u.user_name,
      p.init      = u.init;

  # Introducing Venue into temp_placements_working, changes made by Lucky Yona 8/13/2018
  insert into processing_status values (processDate_in, 'Setup temp_venue_working', now());
  DROP TABLE IF EXISTS temp_venue_working;
  CREATE TABLE `temp_venue_working`
  (
    `PLACE_ID`       decimal(10, 0) DEFAULT NULL,
    `ORDER_ID`       varchar(17) CHARACTER SET latin1
      COLLATE latin1_general_ci     DEFAULT NULL,
    `LAST_MKT`       varchar(50) CHARACTER SET latin1
      COLLATE latin1_general_ci     DEFAULT NULL,
    `VENUE_ORDER_ID` varchar(50) CHARACTER SET latin1
      COLLATE latin1_general_ci     DEFAULT NULL,
    KEY `idx1` (`PLACE_ID`),
    KEY `idx2` (`VENUE_ORDER_ID`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_cs;

  INSERT INTO temp_venue_working
    (SELECT PLACEMENT_ID, ORDER_ID, LAST_MKT, FILL_ID FROM mfs2_data.fills GROUP BY PLACEMENT_ID);


  insert into processing_status values (processDate_in, 'Update placements working with Venue ', now());
  UPDATE temp_placements_working p LEFT JOIN temp_venue_working f
    ON p.place_id = f.PLACE_ID
  SET p.venue          = f.last_mkt,
      p.VENUE_ORDER_ID = f.VENUE_ORDER_ID;


  insert into processing_status values (processDate_in, 'Step 7 - setup temp_allocations_working', now());
  DROP TABLE IF EXISTS temp_allocations_working;
  CREATE TABLE `temp_allocations_working`
  (
    `ORDER_ID`         varchar(17) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `TRADE_ID`         varchar(17) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `ACCT_CD`          varchar(24) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `TOTAL_TARGET_QTY` double                                                     DEFAULT NULL,
    `TOTAL_TARGET_AMT` double                                                     DEFAULT NULL,
    `TOTAL_EXEC_QTY`   double                                                     DEFAULT NULL,
    `TOTAL_EXEC_AMT`   double                                                     DEFAULT NULL,
    `TOT_COMMISSION`   double                                                     DEFAULT NULL,
    `ORDER_MANAGER`    varchar(21) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `EXEC_BROKER`      varchar(18) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `LIMIT_PRICE`      varchar(26) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `ORIG_ORDER_ID`    varchar(68) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `COMMENTS`         varchar(469) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `TOT_FEES`         double                                                     DEFAULT NULL,
    `Acct_Name`        varchar(67) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `Manager`          varchar(50) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `User_Name`        varchar(59) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `Init`             varchar(64) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `status`           varchar(16) CHARACTER SET latin1
      COLLATE latin1_general_ci                                                   DEFAULT NULL,
    `STRATEGY_CODE`    varchar(24) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
    KEY `idx1` (`ORDER_ID`),
    KEY `idx2` (`ORIG_ORDER_ID`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_cs;

  INSERT INTO temp_allocations_working
    (SELECT a.ORDER_ID,
            a.TRADE_ID,
            a.ACCT_CD,
            SUM(TARGET_QTY)                                                               TOTAL_TARGET_QTY,
            SUM(TARGET_AMT)                                                               TOTAL_TARGET_AMT,
            SUM(EXEC_QTY)                                                                 TOTAL_EXEC_QTY,
            SUM(EXEC_AMT)                                                                 TOTAL_EXEC_AMT,
            SUM(commission_AMT)                                                           TOT_COMMISSION,
            a.ORDER_MANAGER,
            a.EXEC_BROKER,
            a.LIMIT_PRICE,
            a.ORIG_ORDER_ID,
            a.COMMENTS,
            SUM(FEE_1_AMT + FEE_2_AMT + FEE_3_AMT + FEE_4_AMT + FEE_5_AMT + FEE_6_AMT) AS TOT_FEES,
            if(isnull(m.Acct_Name), a.ACCT_CD, m.Acct_Name),
            m.Manager,
            m.User_Name,
            m.Init,
            a.STATUS,
            NULL
     FROM mfs2_data.allocations a
            LEFT JOIN temp_account_manager_mapping m ON a.ACCT_CD = m.Acct_CD
     WHERE a.EXEC_QTY > 0
       AND (a.EXEC_BROKER <> 'INKIND' OR a.EXEC_BROKER IS NULL)
     GROUP BY a.ORDER_ID,
              a.ACCT_CD);

  #Update to match XIP 9/5/2018

  UPDATE temp_allocations_working a, account_mapping ram
  SET a.`STRATEGY_CODE` =
        IF(ram.STRATEGY_CODE IN ('MIT', 'DCCE'), 'MIT-DCCE',
           IF(ram.STRATEGY_CODE IN ('LGE', 'FTCE'), 'LGE-FTCE',
              IF(ram.STRATEGY_CODE IN ('MIG', 'USGE', 'WGF', 'DFGC'), 'MIG-USGE-WGF-DFGC',
                 IF(ram.STRATEGY_CODE IN ('MEG', 'DTRK', 'MEGF', 'OTC', 'DTRI'), 'MEG-DTRK-MEGF-OTC-DTRI',
                    IF(ram.STRATEGY_CODE IN ('RES', 'DCSE'), 'RES-DCSE',
                       IF(ram.STRATEGY_CODE IN ('EVF', 'FGI'), 'EVF-FGI',
                          IF(ram.STRATEGY_CODE IN ('DIFR', 'GRE'), 'DIFR-GRE',
                             IF(ram.STRATEGY_CODE IN ('MUK', 'RBKE'), 'MUK-RBKE',
                                IF(ram.STRATEGY_CODE IN ('EIF', 'MWTE'), 'EIF-MWTE',
                                   IF(ram.STRATEGY_CODE IN ('MDV', 'MTRE'), 'MDV-MTRE',
                                      ram.STRATEGY_CODE))))))))))
  WHERE a.acct_cd = ram.CLIENT_CODE;

  UPDATE temp_allocations_working a, strategy_mapping ram
  SET a.`STRATEGY_CODE` =
        IF(ram.Strategy IN ('MIT', 'DCCE'), 'MIT-DCCE',
           IF(ram.Strategy IN ('LGE', 'FTCE'), 'LGE-FTCE',
              IF(ram.Strategy IN ('MIG', 'USGE', 'WGF', 'DFGC'), 'MIG-USGE-WGF-DFGC',
                 IF(ram.Strategy IN ('MEG', 'DTRK', 'MEGF', 'OTC', 'DTRI'), 'MEG-DTRK-MEGF-OTC-DTRI',
                    IF(ram.Strategy IN ('RES', 'DCSE'), 'RES-DCSE',
                       IF(ram.Strategy IN ('EVF', 'FGI'), 'EVF-FGI',
                          IF(ram.Strategy IN ('DIFR', 'GRE'), 'DIFR-GRE',
                             IF(ram.Strategy IN ('MUK', 'RBKE'), 'MUK-RBKE',
                                IF(ram.Strategy IN ('EIF', 'MWTE'), 'EIF-MWTE',
                                   IF(ram.Strategy IN ('MDV', 'MTRE'), 'MDV-MTRE',
                                      Strategy))))))))))
  WHERE a.acct_cd = ram.Account;

  update temp_allocations_working set STRATEGY_CODE = 'N.A.' where STRATEGY_CODE is null or STRATEGY_CODE = '';

  insert into processing_status values (processDate_in, 'Step 8 - setup temp_orders_working', now());
  DROP TABLE IF EXISTS temp_orders_working;
  CREATE TABLE `temp_orders_working`
  (
    `ORDER_ID`           varchar(11) COLLATE latin1_general_ci  NOT NULL,
    `CREATE_DATE`        datetime                                        DEFAULT NULL,
    `TO_TRADER_DATE`     datetime                                        DEFAULT NULL,
    `TRANS_TYPE`         varchar(15) COLLATE latin1_general_ci           DEFAULT NULL,
    `SIDE`               varchar(7) CHARACTER SET utf8                   DEFAULT NULL,
    `ORDER_TYPE`         varchar(3) CHARACTER SET utf8          NOT NULL DEFAULT '',
    `INSTRUCTION`        varchar(255) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    `ORDER_DURATION`     varchar(5) COLLATE latin1_general_ci            DEFAULT NULL,
    `LIMIT_PRICE`        double                                          DEFAULT NULL,
    `IPO`                char(1) COLLATE latin1_general_ci               DEFAULT NULL,
    `MANAGER`            varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `TRADER`             varchar(20) COLLATE latin1_general_ci           DEFAULT NULL,
    `SEC_ID`             varchar(25) COLLATE latin1_general_ci           DEFAULT NULL,
    `CUSIP`              char(9) COLLATE latin1_general_ci               DEFAULT NULL,
    `ISIN`               varchar(50) COLLATE latin1_general_ci           DEFAULT NULL,
    `SEDOL`              varchar(7) COLLATE latin1_general_ci            DEFAULT NULL,
    `TICKER`             varchar(50) COLLATE latin1_general_ci           DEFAULT NULL,
    `TARGET_QTY`         double                                          DEFAULT NULL,
    `ORIG_TARGET_QTY`    double                                          DEFAULT NULL,
    `COMMISSION_AMT`     double                                          DEFAULT NULL,
    `COMMISSION_RATE`    double                                          DEFAULT NULL,
    `LOC_CRRNCY_CD`      varchar(3) COLLATE latin1_general_ci            DEFAULT NULL,
    `LIST_EXCH_CD`       varchar(10) COLLATE latin1_general_ci           DEFAULT NULL,
    `EXT_SEC_ID`         varchar(10) COLLATE latin1_general_ci           DEFAULT NULL,
    `SEC_TYP_CD`         varchar(10) COLLATE latin1_general_ci           DEFAULT NULL,
    `PROGRAM_NONPROGRAM` varchar(11) CHARACTER SET utf8         NOT NULL DEFAULT '',
    `PROG_TRD_ID`        varchar(8) COLLATE latin1_general_ci            DEFAULT NULL,
    `DESCR`              varchar(255) COLLATE latin1_general_ci          DEFAULT NULL,
    `PROGRAM_CODE`       varchar(50) COLLATE latin1_general_ci           DEFAULT NULL,
    `CFT_TAG`            varchar(50) COLLATE latin1_general_ci  NOT NULL,
    `QR_TAG`             varchar(50) COLLATE latin1_general_ci  NOT NULL,
    `TRANSITION_TAG`     varchar(50) COLLATE latin1_general_ci  NOT NULL,
    `TAG`                varchar(50) COLLATE latin1_general_ci  NOT NULL,
    `BASKET_CREATE_DATE` date                                            DEFAULT NULL,
    `STATUS`             varchar(15) COLLATE latin1_general_ci           DEFAULT NULL,
    `PAIRS_TRADE`        varchar(15) COLLATE latin1_general_ci           DEFAULT NULL,
    `CONTINGENT_ID`      varchar(15) COLLATE latin1_general_ci           DEFAULT NULL,
    `G_RATIO`            varchar(15) COLLATE latin1_general_ci           DEFAULT NULL,
    `BROKER_REASON`      varchar(55) COLLATE latin1_general_ci           DEFAULT NULL,
    KEY `idx1` (`ORDER_ID`)
  )
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_orders_working (SELECT o.Order_ID,
                                          CAST(o.CREATE_DATE AS DATETIME)                   as CREATE_DATE,
                                          CAST(o.TO_TRADER_DATE AS DATETIME)                as TO_TRADER_DATE,
                                          o.Trans_Type,
                                          CASE LEFT(o.TRANS_TYPE, 1)
                                            WHEN 'B' THEN 'Buy'
                                            WHEN 'S' THEN 'Sell'
                                            ELSE 'Unknown'
                                            END                                             AS Side,
                                          IF(LEFT(o.instruction, 1) = 'L', 'LMT', 'MKT')    AS order_type,
                                          ifnull(o.instruction, '')                         AS instruction,
                                          o.ORDER_DURATION,
                                          o.LIMIT_PRICE,
                                          o.IPO,
                                          o.MANAGER,
                                          o.TRADER,
                                          o.SEC_ID,
                                          o.CUSIP,
                                          null,
                                          o.SEDOL,
                                          o.TICKER,
                                          o.TARGET_QTY,
                                          o.ORIG_TARGET_QTY,
                                          o.COMMISSION_AMT,
                                          o.COMMISSION_RATE,
                                          o.LOC_CRRNCY_CD,
                                          o.LIST_EXCH_CD,
                                          o.EXT_SEC_ID,
                                          o.SEC_TYP_CD,
                                          IF(o.PROG_TRD_ID = '0', 'NON-PROGRAM', 'PROGRAM') AS PROGRAM_NONPROGRAM,
                                          right(o.PROG_TRD_ID, 8)                           AS PROG_TRD_ID,
                                          pr.DESCR,
                                          SUBSTRING_INDEX(pr.DESCR, ' ', 1),
                                          'N.A.',
                                          'N.A.',
                                          'N.A.',
                                          'N.A.',
                                          CAST(pr.CREATE_DATE AS DATE)                      AS Basket_Create_Date,
                                          o.status,
                                          'N.A.',
                                          NULL,
                                          G_RATIO,
                                          BROKER_REASON
                                   FROM mfs2_data.orders o
                                          LEFT JOIN (SELECT * FROM mfs2_data.programs GROUP BY prog_trd_id) AS pr
                                                    ON o.prog_trd_id = pr.prog_trd_id);

  ## Adhoc rename of early programs per Khaled ##
  UPDATE temp_orders_working SET descr = 'XT3 5.18.18' WHERE prog_trd_id = '11998735';
  UPDATE temp_orders_working SET descr = 'PT10 04.30.18' WHERE prog_trd_id = '07685445';


  # call process_start_times(); # OCX

  UPDATE temp_orders_working
  SET CFT_TAG = 'Cash Flow Trades',
      TAG     = 'Cash Flow Trades'
  WHERE (PROGRAM_CODE regexp '^[XP]T$' OR
         PROGRAM_CODE regexp '^[XP]T[1-9]$' OR
         PROGRAM_CODE regexp '^[XP]T[1-2][0-9]$');
  UPDATE temp_orders_working
  SET QR_TAG = 'Quant Portfolio Rebalances',
      TAG    = 'Quant Portfolio Rebalances'
  WHERE PROGRAM_CODE regexp '^XT[5-6][0-9]$';
  UPDATE temp_orders_working
  SET TRANSITION_TAG = 'Transitions',
      TAG            = 'Transitions'
  WHERE PROGRAM_CODE regexp '^XT7[0-9]$';


  insert into processing_status values (processDate_in, 'Step 8.1 - updates/tagging temp_orders_working', now());
  delete from temp_orders_working where sec_typ_cd in ('PFD', 'IFUT');

  UPDATE temp_orders_working
  SET CFT_TAG = 'Cash Flow Trades',
      TAG     = 'Cash Flow Trades'
  WHERE (PROGRAM_CODE regexp '^[XP]T$' OR PROGRAM_CODE regexp '^[XP]T[1-9]$' OR
         PROGRAM_CODE regexp '^[XP]T[1-2][0-9]$');
  UPDATE temp_orders_working
  SET QR_TAG = 'Quant Portfolio Rebalances',
      TAG    = 'Quant Portfolio Rebalances'
  WHERE PROGRAM_CODE regexp '^XT[5-6][0-9]$';
  UPDATE temp_orders_working
  SET TRANSITION_TAG = 'Transitions',
      TAG            = 'Transitions'
  WHERE PROGRAM_CODE regexp '^XT7[0-9]$';

  call process_pairs_trades(processDate_in);

  insert into processing_status values (processDate_in, 'Step 9 - setup temp_order_trail_working', now());
  DROP TABLE IF EXISTS temp_order_trail_working;
  CREATE TABLE `temp_order_trail_working`
  (
    `order_id`               varchar(15) COLLATE latin1_general_ci DEFAULT NULL,
    `orig_order_id`          varchar(15) COLLATE latin1_general_ci DEFAULT NULL,
    `acct_cd`                varchar(15) COLLATE latin1_general_ci DEFAULT NULL,
    `orig_order_create_date` datetime                              DEFAULT NULL,
    `orig_order_trader_date` datetime                              DEFAULT NULL,
    KEY `idx1` (`orig_order_id`, `acct_cd`),
    KEY `idx2` (`order_id`, `acct_cd`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_order_trail_working (SELECT a.order_id,
                                               a.orig_order_id,
                                               a.acct_cd,
                                               MIN(o.CREATE_DATE),
                                               MIN(o.TO_TRADER_DATE)
                                        FROM mfs2_data.allocations a
                                               LEFT JOIN temp_orders_working o ON a.orig_order_id = o.order_id
                                        GROUP BY a.order_id, a.orig_order_id, a.acct_cd);

  DROP TABLE IF EXISTS temp_order_trail_working_dtg;
  CREATE TABLE `temp_order_trail_working_dtg`
  (
    `order_id`               varchar(15) COLLATE latin1_general_ci DEFAULT NULL,
    `orig_order_create_date` datetime                              DEFAULT NULL,
    `orig_order_trader_date` datetime                              DEFAULT NULL,
    KEY `idx1` (`order_id`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_order_trail_working_dtg (SELECT order_id, MIN(orig_order_create_date), MIN(orig_order_trader_date)
                                            FROM temp_order_trail_working
                                            GROUP BY order_id);

  UPDATE temp_order_trail_working a, temp_order_trail_working_dtg b
  SET a.orig_order_create_date = b.orig_order_create_date
  WHERE a.orig_order_create_date IS NULL
    AND a.order_id = b.order_id;

  UPDATE temp_order_trail_working a, temp_order_trail_working_dtg b
  SET a.orig_order_trader_date = b.orig_order_trader_date
  WHERE a.orig_order_trader_date IS NULL
    AND a.order_id = b.order_id;

  insert into processing_status values (processDate_in, 'Step 11 - setup temp_placement_rollups_working', now());
  DROP TABLE IF EXISTS temp_placement_rollups_working;
  CREATE TABLE `temp_placement_rollups_working`
  (
    `order_id`              varchar(17) COLLATE latin1_general_ci DEFAULT NULL,
    `broker`                varchar(18) COLLATE latin1_general_ci DEFAULT NULL,
    `trader`                varchar(18) COLLATE latin1_general_ci DEFAULT NULL,
    `trader_name`           varchar(59) COLLATE latin1_general_ci DEFAULT NULL,
    `placement_date`        datetime                              DEFAULT NULL,
    `broker_reason`         longtext CHARACTER SET utf8,
    `FCM_BBG`               ENUM ('N.A.', 'FCM', 'BBG')           DEFAULT NULL,
    `placement_exec_amt`    double                                DEFAULT NULL,
    `placement_exec_shares` double                                DEFAULT NULL,
    `qty_placed`            double                                DEFAULT NULL,
    `broker_order_type`     varchar(10) COLLATE latin1_general_ci DEFAULT NULL,
    `broker_order_type_2`   varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `min_place_limit`       varchar(25) COLLATE latin1_general_ci DEFAULT NULL,
    `max_place_limit`       varchar(25) COLLATE latin1_general_ci DEFAULT NULL,
    `comments`              longtext CHARACTER SET utf8,
    `broker_name`           varchar(54) COLLATE latin1_general_ci DEFAULT NULL,
    `broker_type_code`      varchar(10) COLLATE latin1_general_ci DEFAULT NULL,
    `broker_reason_code`    varchar(64) COLLATE latin1_general_ci DEFAULT NULL,
    `total_fill`            decimal(32, 0)                        DEFAULT NULL,
    `total_amt`             double                                DEFAULT NULL,
    `first_fill_date`       datetime                              DEFAULT NULL,
    `last_fill_date`        datetime                              DEFAULT NULL,
    `Parent_Broker`         varchar(60) COLLATE latin1_general_ci DEFAULT NULL,
    `Broker_Type`           varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `ALGO_STRATEGY`         varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `Venue`                 varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `VENUE_ORDER_ID`        varchar(50) CHARACTER SET latin1
      COLLATE latin1_general_ci                                   DEFAULT NULL,
    `FCM_Broker`            varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    KEY `idx1` (`order_id`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_placement_rollups_working (SELECT order_id,
                                                     IF(MIN(exec_broker) = MAX(exec_broker),
                                                        MIN(exec_broker), IF(exec_broker IS NULL, 'Not Provided',
                                                                             'Multi')),
                                                     IF(MIN(create_user) = MAX(create_user),
                                                        MIN(create_user),
                                                        'Multi'),
                                                     IF(MIN(user_name) = MAX(user_name),
                                                        MIN(user_name),
                                                        'Multi'),
                                                     MIN(place_date),
                                                     CAST(GROUP_CONCAT(DISTINCT broker_reason SEPARATOR ' - ') AS CHAR),
                                                     FCM_BBG,
                                                     SUM(exec_amt),
                                                     SUM(exec_qty),
                                                     SUM(place_qty),
                                                     MIN(instruction),
                                                     MIN(instruction2),
                                                     MIN(limit_price),
                                                     MAX(limit_price),
                                                     CAST(GROUP_CONCAT(DISTINCT comments SEPARATOR ' - ') AS CHAR),
                                                     IF(MIN(bkr_name) = MAX(bkr_name),
                                                        MIN(bkr_name), IF(bkr_name IS NULL, 'Not Provided',
                                                                          'Multi')),
                                                     IF(MIN(bkr_typ_cd) = MAX(bkr_typ_cd),
                                                        MIN(bkr_typ_cd), IF(bkr_typ_cd IS NULL, 'Not Provided',
                                                                            'Multi')),
                                                     IF(MIN(bkr_reason_cd) = MAX(bkr_reason_cd),
                                                        MIN(bkr_reason_cd), IF(bkr_reason_cd IS NULL, 'Not Provided',
                                                                               'Multi')),
                                                     SUM(fill_qty),
                                                     SUM(fill_amt),
                                                     MIN(min_fill_date),
                                                     MAX(max_fill_date),
                                                     IFNULL(Parent_Broker, 'Not provided'),
                                                     IFNULL(Broker_Type, 'Not Provided'),
                                                     ALGO_STRATEGY,
                                                     Venue,
                                                     VENUE_ORDER_ID,
                                                     NULL
                                              FROM temp_placements_working
                                              WHERE exec_amt > 0
                                              GROUP BY order_id);

  UPDATE temp_placement_rollups_working set FCM_Broker = IF(FCM_BBG LIKE '%FCM%', 'FCM', 'N.A.');

  insert into processing_status values (processDate_in, 'Step 12 - setup temp_aggregated_info_working', now());
  DROP TABLE IF EXISTS temp_aggregated_info_working;
  CREATE TABLE `temp_aggregated_info_working`
  (
    `order_id`                      varchar(11)                           DEFAULT NULL,
    `orig_order_create_date`        datetime                              DEFAULT NULL,
    `orig_order_trader_date`        datetime                              DEFAULT NULL,
    `orig_order_create_date_adj`    datetime                              DEFAULT NULL,
    `orig_order_trader_date_adj`    datetime                              DEFAULT NULL,
    `create_date`                   datetime                              DEFAULT NULL,
    `to_trader_date`                datetime                              DEFAULT NULL,
    `trans_type`                    varchar(15)                           DEFAULT NULL,
    `side`                          varchar(7)                            DEFAULT NULL,
    `order_type`                    varchar(3)                            DEFAULT NULL,
    `instruction`                   varchar(255)                          DEFAULT NULL,
    `order_duration`                varchar(8)                            DEFAULT NULL,
    `ORDERS_LIMIT`                  double                                DEFAULT NULL,
    `ipo`                           char(1)                               DEFAULT NULL,
    `ORDERS_MANAGER`                varchar(40)                           DEFAULT NULL,
    `ORDERS_TRADER`                 varchar(20)                           DEFAULT NULL,
    `sec_id`                        varchar(25)                           DEFAULT NULL,
    `cusip`                         char(9)                               DEFAULT NULL,
    `isin`                          varchar(25)                           DEFAULT NULL,
    `sedol`                         varchar(7)                            DEFAULT NULL,
    `ticker`                        varchar(50)                           DEFAULT NULL,
    `target_qty`                    double                                DEFAULT NULL,
    `commission_amt`                double                                DEFAULT NULL,
    `ORIG_TARGET_QTY`               double                                DEFAULT NULL,
    `commission_rate`               double                                DEFAULT NULL,
    `loc_crrncy_cd`                 varchar(3)                            DEFAULT NULL,
    `list_exch_cd`                  varchar(10)                           DEFAULT NULL,
    `ext_sec_id`                    varchar(40)                           DEFAULT NULL,
    `sec_typ_cd`                    varchar(10) COLLATE latin1_general_ci DEFAULT NULL,
    `program_nonprogram`            varchar(11)                           DEFAULT NULL,
    `prog_trd_id`                   varchar(8)                            DEFAULT NULL,
    `descr`                         varchar(255)                          DEFAULT NULL,
    `basket_create_date`            date                                  DEFAULT NULL,
    `status`                        varchar(15)                           DEFAULT NULL,
    `CFT_TAG`                       varchar(50) COLLATE latin1_general_ci NOT NULL,
    `QR_TAG`                        varchar(50) COLLATE latin1_general_ci NOT NULL,
    `TRANSITION_TAG`                varchar(50) COLLATE latin1_general_ci NOT NULL,
    `TAG`                           varchar(50) COLLATE latin1_general_ci NOT NULL,
    `PAIRS_TRADE`                   varchar(15) COLLATE latin1_general_ci DEFAULT NULL,
    `ALLOCATIONS_ACCT_CD`           varchar(24)                           DEFAULT NULL,
    `ALLOCATIONS_TRADE_ID`          varchar(24)                           DEFAULT NULL,
    `ALLOCATIONS_TARGET_QTY`        double                                DEFAULT NULL,
    `ALLOCATIONS_TARGET_AMT`        double                                DEFAULT NULL,
    `ALLOCATIONS_EXEC_QTY`          double                                DEFAULT NULL,
    `ALLOCATIONS_EXEC_AMT`          double                                DEFAULT NULL,
    `ALLOCATIONS_TOT_COMMISSION`    double                                DEFAULT NULL,
    `ALLOCATIONS_ORDER_MANAGER`     varchar(21)                           DEFAULT NULL,
    `ALLOCATIONS_EXEC_BROKER`       varchar(18)                           DEFAULT NULL,
    `ALLOCATIONS_LIMIT_PRICE`       varchar(26)                           DEFAULT NULL,
    `ORIG_ORDER_ID`                 varchar(68)                           DEFAULT NULL,
    `PM_ORDER_ID`                   varchar(68)                           DEFAULT NULL,
    `DESK_ORDER_ID`                 varchar(68)                           DEFAULT '',
    `BROKER_ORDER_ID`               varchar(68)                           DEFAULT NULL,
    `DESK_ORDER_TRADER`             varchar(64)                           DEFAULT NULL,
    `ALLOCATIONS_COMMENTS`          varchar(255)                          DEFAULT NULL,
    `ALLOCATIONS_TOTAL_FEES`        double                                DEFAULT NULL,
    `Acct_Name`                     varchar(67)                           DEFAULT NULL,
    `ACCT_MANAGER_CODE`             varchar(50)                           DEFAULT NULL,
    `ACCT_MANAGER_NAME`             varchar(50)                           DEFAULT NULL,
    `ACCT_MANAGER_INITIALS`         varchar(50)                           DEFAULT NULL,
    `broker`                        varchar(50)                           DEFAULT NULL,
    `broker_name`                   varchar(54)                           DEFAULT NULL,
    `broker_type_code`              varchar(10)                           DEFAULT NULL,
    `broker_reason_code`            varchar(64)                           DEFAULT NULL,
    `FCM_BBG`                       ENUM ('N.A.', 'FCM', 'BBG')           DEFAULT NULL,
    `broker_order_type`             varchar(10)                           DEFAULT NULL,
    `broker_order_type_2`           varchar(20)                           DEFAULT NULL,
    `placements_trader`             varchar(18)                           DEFAULT NULL,
    `trader_name`                   varchar(59)                           DEFAULT NULL,
    `placement_date`                datetime                              DEFAULT NULL,
    `broker_reason`                 varchar(255)                          DEFAULT NULL,
    `placement_exec_amt`            double                                DEFAULT NULL,
    `placement_exec_shares`         double                                DEFAULT NULL,
    `qty_placed`                    double                                DEFAULT NULL,
    `min_place_limit`               varchar(25)                           DEFAULT NULL,
    `max_place_limit`               varchar(25)                           DEFAULT NULL,
    `placement_comments`            varchar(255)                          DEFAULT NULL,
    `total_fill`                    decimal(33, 0)                        DEFAULT NULL,
    `total_amt`                     double                                DEFAULT NULL,
    `first_fill_date`               datetime                              DEFAULT NULL,
    `last_fill_date`                datetime                              DEFAULT NULL,
    `last_fill_date_adj`            datetime                              DEFAULT NULL,
    `sec_check_status`              varchar(22)                           DEFAULT NULL,
    `sjls_ticker`                   varchar(17)                           DEFAULT NULL,
    `sjls_currency`                 varchar(3)                            DEFAULT NULL,
    `sjls_secid`                    varchar(23)                           DEFAULT NULL,
    `exchange_code`                 varchar(2)                            DEFAULT NULL,
    `cash_flow`                     varchar(1)                            DEFAULT NULL,
    `multi_placement_tag`           varchar(1)                            DEFAULT NULL,
    `Parent_Broker`                 varchar(60) COLLATE latin1_general_ci DEFAULT NULL,
    `Broker_Type`                   varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `ALGO_STRATEGY`                 varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `Venue`                         varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `VENUE_ORDER_ID`                varchar(50) CHARACTER SET latin1
      COLLATE latin1_general_ci                                           DEFAULT NULL,
    `FCM_Broker`                    varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `Strategy_Code`                 varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `trader_date_updated`           varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `action_type`                   varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `msg_text`                      varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `SHARES_OPEN`                   varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `ORDER_ID_ALLOCATIONS_EXEC_QTY` varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `CONTINGENT_ID`                 varchar(50) COLLATE latin1_general_ci DEFAULT 'N.A.',
    `row_counter`                   int(11)                               NOT NULL AUTO_INCREMENT,
    `OCX_ID`                        VARCHAR(64)                           DEFAULT NULL,
    `G_Ratio`                       VARCHAR(64)                           DEFAULT NULL,
    key row_counter (`row_counter`)

  )
    ENGINE = InnoDB
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  ALTER TABLE temp_aggregated_info_working
    ADD INDEX (order_id);
  ALTER TABLE temp_aggregated_info_working
    ADD INDEX (desk_order_id);
  ALTER TABLE temp_aggregated_info_working
    ADD INDEX (orig_order_id);
  ALTER TABLE temp_aggregated_info_working
    ADD INDEX (venue_order_id),
    ADD INDEX (`row_counter`);

  ALTER TABLE temp_aggregated_info_working
    ADD INDEX (OCX_ID);

  INSERT INTO temp_aggregated_info_working (SELECT o.order_id,
                                                   ot.orig_order_create_date,
                                                   ot.orig_order_trader_date,
                                                   ot.orig_order_create_date,
                                                   ot.orig_order_trader_date,
                                                   o.create_date,
                                                   o.to_trader_date,
                                                   o.trans_type,
                                                   o.side,
                                                   o.order_type,
                                                   o.instruction,
                                                   if(instr(aw.comments, 'MOC') > 0, 'ON_CLOSE', o.order_duration) as order_duration,
                                                   o.limit_price                                                   AS ORDERS_LIMIT,
                                                   o.ipo,
                                                   o.manager                                                       AS ORDERS_MANAGER,
                                                   o.trader                                                        AS ORDERS_TRADER,
                                                   o.sec_id,
                                                   o.cusip,
                                                   o.isin,
                                                   o.sedol,
                                                   o.ticker,
                                                   o.target_qty,
                                                   o.ORIG_TARGET_QTY,
                                                   o.commission_amt,
                                                   o.commission_rate,
                                                   o.loc_crrncy_cd,
                                                   o.list_exch_cd,
                                                   o.ext_sec_id,
                                                   o.SEC_TYP_CD,
                                                   o.program_nonprogram,
                                                   o.prog_trd_id,
                                                   IF(o.descr IS NULL, 'Not applicable', o.descr)                  AS descr,
                                                   o.basket_create_date,
                                                   o.status,
                                                   o.CFT_TAG,
                                                   o.QR_TAG,
                                                   o.TRANSITION_TAG,
                                                   o.TAG,
                                                   o.PAIRS_TRADE,
                                                   aw.ACCT_CD                                                      as ALLOCATIONS_ACCT_CD,
                                                   aw.TRADE_ID,
                                                   aw.TOTAL_TARGET_QTY                                             as ALLOCATIONS_TARGET_QTY,
                                                   aw.TOTAL_TARGET_AMT                                             As ALLOCATIONS_TARGET_AMT,
                                                   aw.TOTAL_EXEC_QTY                                               As ALLOCATIONS_EXEC_QTY,
                                                   aw.TOTAL_EXEC_AMT                                               As ALLOCATIONS_EXEC_AMT,
                                                   aw.TOT_COMMISSION                                               AS ALLOCATIONS_TOT_COMMISSION,
                                                   aw.ORDER_MANAGER                                                AS ALLOCATIONS_ORDER_MANAGER,
                                                   aw.EXEC_BROKER                                                  AS ALLOCATIONS_EXEC_BROKER,
                                                   aw.LIMIT_PRICE                                                  AS ALLOCATIONS_LIMIT_PRICE,
                                                   aw.orig_order_id                                                AS ORIG_ORDER_ID,
                                                   aw.orig_order_id                                                AS PM_ORDER_ID,
                                                   aw.orig_order_id                                                AS DESK_ORDER_ID,
                                                   aw.orig_order_id                                                AS BROKER_ORDER_ID,
                                                   pw.trader_name # overwrite for multi orders
                                                ,
                                                   aw.COMMENTS                                                     AS ALLOCATIONS_COMMENTS,
                                                   aw.TOT_FEES                                                     AS ALLOCATIONS_TOTAL_FEES,
                                                   aw.Acct_Name,
                                                   NULL                                                            As ACCT_MANAGER_CODE,
                                                   NULL                                                            AS ACCT_MANAGER_NAME,
                                                   NULL                                                            AS ACCT_MANAGER_INITIALS,
                                                   pw.broker,
                                                   pw.broker_name,
                                                   pw.broker_type_code,
                                                   pw.broker_reason_code,
                                                   pw.FCM_BBG,
                                                   pw.broker_order_type,
                                                   pw.broker_order_type_2,
                                                   pw.trader,
                                                   pw.trader_name,
                                                   pw.placement_date,
                                                   o.BROKER_REASON,
                                                   pw.placement_exec_amt,
                                                   pw.placement_exec_shares,
                                                   pw.qty_placed,
                                                   pw.min_place_limit,
                                                   pw.max_place_limit,
                                                   pw.comments,
                                                   pw.total_fill,
                                                   pw.total_amt,
                                                   pw.first_fill_date,
                                                   pw.last_fill_date,
                                                   pw.last_fill_date,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   pw.Parent_Broker,
                                                   pw.Broker_Type,
                                                   ifnull(pw.ALGO_STRATEGY, 'Not Provided'),
                                                   pw.Venue,
                                                   pw.VENUE_ORDER_ID,
                                                   FCM_Broker,
                                                   aw.STRATEGY_CODE,
                                                   'N',
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   o.CONTINGENT_ID,
                                                   0,
                                                   NULL,
                                                   o.G_RATIO
                                            FROM temp_allocations_working aw
                                                   LEFT JOIN temp_orders_working o ON aw.order_id = o.order_id
                                                   LEFT JOIN temp_placement_rollups_working pw
                                                             ON pw.order_id = o.order_id
                                                   LEFT JOIN temp_order_trail_working ot ON aw.order_id = ot.order_id
                                              AND
                                                                                            aw.ACCT_CD = ot.ACCT_CD
                                            where o.`status` NOT IN ('CNCLACCT', 'CNCL')
                                              AND ot.ORIG_ORDER_ID);


  call order_construction(); #OCX


  insert into processing_status values (processDate_in, 'Step 13 - update temp_aggregated_info_working', now());
  UPDATE temp_aggregated_info_working aw JOIN mfs2_data.users u
    ON aw.ALLOCATIONS_ORDER_MANAGER = u.USER_CD
  SET aw.ACCT_MANAGER_NAME     = u.USER_NAME,
      aw.ACCT_MANAGER_CODE     = u.USER_CD,
      aw.ACCT_MANAGER_INITIALS = u.INIT;

  update temp_aggregated_info_working aw, account_mapping am
  set aw.Strategy_Code = am.strategy_code
  where aw.ALLOCATIONS_ACCT_CD = am.CLIENT_CODE
    and aw.Strategy_Code is null;

  insert into processing_status values (processDate_in, 'Step 14 - update temp_aggregate_accounts_for_pm', now());
  DROP TABLE IF EXISTS temp_aggregate_accounts_for_pm;
  CREATE TABLE `temp_aggregate_accounts_for_pm`
  (
    `Start_Date`    datetime                              DEFAULT NULL,
    `End_Date`      datetime                              DEFAULT NULL,
    `Manager`       varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `Manager_Group` varchar(50) COLLATE latin1_general_ci DEFAULT NULL,
    `SecurityID`    varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `Side`          varchar(7) COLLATE latin1_general_ci  DEFAULT NULL,
    `OrderID`       varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `Client`        varchar(10) COLLATE latin1_general_ci DEFAULT NULL
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_aggregate_accounts_for_pm (SELECT MIN(ORIG_ORDER_CREATE_DATE),
                                                     MAX(LAST_FILL_DATE),
                                                     Allocations_Order_Manager,
                                                     Allocations_Order_Manager,
                                                     SEC_ID,
                                                     SIDE,
                                                     ORIG_ORDER_ID,
                                                     'mfs2'
                                              FROM temp_aggregated_info_working
                                              WHERE prog_trd_id = '0'
                                                AND IPO <> "Y"
                                                AND ORIG_ORDER_CREATE_DATE IS NOT NULL
                                              GROUP BY ORIG_ORDER_ID, Allocations_Order_Manager
                                              ORDER BY ORIG_ORDER_ID);

  insert into processing_status values (processDate_in, 'Step 15  - Start get_pm_orders_cursor_routine', now());
  CALL get_pm_orders_cursor_routine;
  insert into processing_status values (processDate_in, 'Step 15  - End get_pm_orders_cursor_routine', now());

  insert into processing_status values (processDate_in, 'Step 16  - Update temp_aggregated_info_working', now());
  UPDATE temp_aggregated_info_working aw JOIN temp_show_final_order_aggregation ta
    ON aw.ORIG_ORDER_ID = ta.orderid
      AND aw.Allocations_Order_Manager = ta.Manager
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
    `Side`       varchar(7) COLLATE latin1_general_ci  DEFAULT NULL,
    `OrderID`    varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
    `Client`     varchar(10) COLLATE latin1_general_ci DEFAULT NULL
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_aggregate_accounts_for_desk_working (Start_Date,
                                                        End_Date,
                                                        OrderType,
                                                        SecurityID,
                                                        Side,
                                                        OrderID,
                                                        `Client`)

  SELECT MIN(orig_order_trader_date), MAX(LAST_FILL_DATE), order_type, SEC_ID, SIDE, ORIG_ORDER_ID, 'mfs2'
  FROM temp_aggregated_info_working
  WHERE prog_trd_id = '0'
    AND IPO <> "Y"
    AND ORIG_ORDER_CREATE_DATE IS NOT NULL
  GROUP BY ORIG_ORDER_ID
  ORDER BY ORIG_ORDER_ID;

  insert into processing_status values (processDate_in, 'Step 20  - Start process_desk_orders_routine', now());
  CALL process_desk_orders_routine; # OCX
  insert into processing_status values (processDate_in, 'Step 20 - End process_desk_orders_routine', now());

  insert into processing_status values (processDate_in, 'Step 21  - Update  temp_aggregated_info_working', now());
  UPDATE temp_aggregated_info_working aw JOIN temp_show_final_desk_aggregation tfa
    ON aw.ORIG_ORDER_ID = tfa.orderid
  SET DESK_ORDER_ID  = finaldeskid,
      last_fill_date = end_date;

  # Desk ownership done here originally # OCX
  call process_desk_order_ownership(processDate_in);

  # Mappings
  insert ignore into country_mapping (select list_exch_cd, NULL
                                      from temp_aggregated_info_working
                                      where list_exch_cd not in (select `exchange` from country_mapping));

  UPDATE temp_aggregated_info_working a, trader_translation_mapping t
  SET a.trader_name = t.xip_trader
  WHERE a.trader_name = t.crd_trader;


  call process_adjust_trader_end_qty_routine; # OCX

  insert into processing_status values (processDate_in, 'Step 22  - set ip  temp_convert_secs_check_prices', now());
  DROP TABLE IF EXISTS temp_convert_secs_check_prices;
  CREATE TABLE `temp_convert_secs_check_prices`
  (
    `ticker`         varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `cusip`          varchar(10) COLLATE latin1_general_ci DEFAULT NULL,
    `sedol`          varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `isin`           varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `country`        varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `sjls_ticker`    varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `sjls_secid`     varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `Date_Generated` date                                  DEFAULT NULL,
    `Date_Closed`    date                                  DEFAULT NULL,
    `orderid`        varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `Price`          double                                DEFAULT NULL,
    `Status`         varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `HighPrice`      double                                DEFAULT NULL,
    `LowPrice`       double                                DEFAULT NULL,
    `Currency`       varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    `sjls_currency`  varchar(45) COLLATE latin1_general_ci DEFAULT NULL,
    KEY `idx1` (`orderid`),
    KEY `idx2` (`isin`, `country`, `sjls_secid`, `Date_Generated`),
    KEY `idx3` (`sedol`, `country`, `sjls_secid`, `Date_Generated`),
    KEY `idx4` (`ticker`, `country`, `sjls_secid`, `Date_Generated`),
    KEY `idx5` (`sjls_secid`, `Date_Generated`, `Date_Closed`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_convert_secs_check_prices (SELECT aw.ticker,
                                                     LEFT(aw.cusip, 8),
                                                     LEFT(aw.sedol, 6),
                                                     LEFT(aw.isin, 11),
                                                     TRIM(map.country),
                                                     NULL,
                                                     NULL,
                                                     MIN(aw.create_date),
                                                     MAX(aw.last_fill_date),
                                                     aw.order_id,
                                                     SUM(aw.allocations_exec_amt) / SUM(aw.allocations_exec_qty),
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     loc_crrncy_cd,
                                                     NULL
                                              FROM temp_aggregated_info_working aw
                                                     JOIN country_mapping map ON aw.list_exch_cd = map.`exchange`
                                              GROUP BY aw.order_id);

  insert into processing_status values (processDate_in, 'Step 23  - Start check_securityid_prices_routine', now());
  call check_securityid_prices_routine(processDate_in);
  insert into processing_status values (processDate_in, 'Step 23  - End check_securityid_prices_routine', now());

  UPDATE temp_convert_secs_check_prices
  SET `status` = 'Order of Magnitude',
      Price    = price * 100
  WHERE `status` = 'Suspect'
    AND price * 100 < HighPrice * 110
    AND price * 100 > LowPrice * 90;


  insert into processing_status values (processDate_in, 'Step 23.2', now());


  UPDATE temp_convert_secs_check_prices
  SET `status` = 'Order of Magnitude',
      Price    = PxDiv100
  WHERE `status` = 'Suspect'
    AND PxDiv100 < HighPrice * 1.1
    AND PxDiv100 > LowPrice * .9;


  insert into processing_status values (processDate_in, 'Step 24  - Update temp_aggregated_info_working', now());
  UPDATE temp_aggregated_info_working aw, temp_convert_secs_check_prices cp
  SET aw.SJLS_TICKER      = cp.sjls_ticker,
      aw.SJLS_CURRENCY    = cp.sjls_currency,
      aw.SJLS_secid       = cp.sjls_secid,
      aw.Sec_CHECK_STATUS = cp.`status`
  WHERE aw.order_id = cp.orderid;

  UPDATE temp_aggregated_info_working SET exchange_code = right(SJLS_TICKER, 2) where SJLS_TICKER is not null;

  update temp_aggregated_info_working
  set orig_order_create_date = create_date,
      orig_order_trader_date = to_trader_date
  where orig_order_create_date is null;


  SET @opportunity_set_index = (select index_name
                                from information_schema.STATISTICS
                                where table_schema = 'mfs2_data'
                                  and table_name = 'opportunity_set'
                                  and index_name = 'parent');

  if @opportunity_set_index is null then
    begin

      ALTER TABLE mfs2_data.opportunity_set
        MODIFY COLUMN PARENT_ORDER_ID VARCHAR(64);

      ALTER TABLE mfs2_data.opportunity_set
        MODIFY COLUMN ORDER_ID VARCHAR(64);

      ALTER TABLE mfs2_data.opportunity_set
        MODIFY COLUMN START_TIME DATETIME;

      ALTER TABLE mfs2_data.opportunity_set
        ADD INDEX `parent` (PARENT_ORDER_ID);

      ALTER TABLE mfs2_data.opportunity_set
        ADD INDEX `child` (ORDER_ID);

      ALTER TABLE mfs2_data.opportunity_set
        ADD INDEX `temporal` (START_TIME);
    end;
  end if;


  UPDATE temp_aggregated_info_working aw, mfs2_data.opportunity_set d
  SET aw.OCX_ID = d.PARENT_ORDER_ID
  WHERE DESK_ORDER_ID = d.ORDER_ID
    AND DESK_ORDER_ID is not NULL
    AND DESK_ORDER_ID != '';


  UPDATE temp_aggregated_info_working aw, mfs2_data.opportunity_set d
  SET aw.DESK_ORDER_ID              = aw.OCX_ID,
      aw.orig_order_trader_date     = d.START_TIME,
      aw.orig_order_trader_date_adj = d.START_TIME,
      aw.to_trader_date             = d.START_TIME
  WHERE aw.OCX_ID = d.PARENT_ORDER_ID
    AND aw.OCX_ID is not null;


  # Process desk ownership down here for testing.
  call process_desk_order_ownership(processDate_in);
  #___________________


  update temp_aggregated_info_working
  set ALGO_STRATEGY = 'FGBGLSAA'
  where broker = 'AACM'
    and ALGO_STRATEGY = 'Not Provided';

  update temp_aggregated_info_working
  SET ALGO_STRATEGY = 'FGBGLSAN'
  WHERE broker = 'NACM'
    and ALGO_STRATEGY = 'Not Provided';

  update temp_aggregated_info_working
  set ALGO_STRATEGY = 'FGBGDARK'
  where broker = 'DACM'
     or broker like 'DF%'
     or broker_name regexp 'DARK'
    and ALGO_STRATEGY = 'Not Provided';

  update temp_aggregated_info_working
  set ALGO_STRATEGY = 'FGBGPOV'
  where broker = 'PO10'
    and ALGO_STRATEGY = 'Not Provided';

  update temp_placements_working
  set exec_broker = 'FCMS-EQ'
  where ALGO_STRATEGY = 'FGBGVWAP';

  update temp_aggregated_info_working
  SET ALGO_STRATEGY = 'FGBGLSAP/FGBGVWAP'
  where broker = 'FCMS-EQ'
    and ALGO_STRATEGY = 'Not Provided';

  UPDATE temp_aggregated_info_working aw, manager_mapping m
  SET ALLOCATIONS_ORDER_MANAGER = XIP_CODE
  where ALLOCATIONS_ORDER_MANAGER = CRD_CODE;

  #_________________________ Get appropriate blotter sweep start time 


  DROP TABLE IF EXISTS temp_blotter_sweep;
  CREATE TABLE `temp_blotter_sweep`
  (
    `SEND_TIME` datetime       DEFAULT NULL,
    `PLACE_ID`  decimal(10, 0) DEFAULT NULL,
    PRIMARY KEY (`PLACE_ID`) USING BTREE
  ) ENGINE = TokuDB
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_blotter_sweep(SELECT MIN(SEND_TIME),
                                        PLACE_ID
                                 FROM mfs2_data.fix_outgoing
                                 group by PLACE_ID);

  update temp_placements_working p, temp_blotter_sweep t
  set place_date = SEND_TIME
  where p.place_id = t.PLACE_ID
    and left(p.Broker_Code, 4) in ('ITPS', 'LQNS', 'LMNS', 'BISS');


  select p.place_date, t.SEND_TIME
  from temp_placements_working p,
       temp_blotter_sweep t
  where p.place_id = t.place_id
    and p.Broker_Code in ('ITPS', 'LQNS', 'LMNS', 'BISS');
  # Matching security types with XIP
  alter table temp_aggregated_info_working
    add index sec_type (`sec_typ_cd`);

  update temp_aggregated_info_working aw, security_type_map s
  set sec_typ_cd = `﻿XIP_Type`
  where sec_typ_cd = trim(CRD_Type);

  call time_zone_conversion_routine(processDate_in);

  insert into processing_status values (processDate_in, 'Step 25  - delete from standard output', now());
  TRUNCATE standardoutput;

  insert into processing_status values (processDate_in, 'Step 26  - build standard output PM View', now());
  INSERT INTO standardoutput (date_time_gen,
                              date_time_sent,
                              date_time_closed,
                              client_code,
                              pm_order_id,
                              `source`,
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
                              trader,
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
                              strategy,
                              traderteam,
                              total_commissions,
                              account,
                              currency,
                              settlement_currency,
                              subaccount,
                              instructions,
                              sjls_secid,
                              file_date,
                              `algorithm`,
                              `Venue`)
  SELECT MIN(orig_order_create_date_adj) AS orig_order_create_date,
         MIN(orig_order_trader_date_adj) AS orig_order_trader_date,
         MAX(last_fill_date_adj),
         'MFS2',
         PM_ORDER_ID,
         'UPLOAD',
         LEFT(side, 1),
         SUM(allocations_exec_qty),
         SUM(allocations_exec_qty),
         sjls_ticker,
         'BLOOMBERG',
         order_type,
         order_duration,
         IF(side = 'Sell',
            MAX(ORDERS_LIMIT),
            MIN(ORDERS_LIMIT)),
         SUM(allocations_exec_amt) / SUM(allocations_exec_qty),
         IF(MIN(BROKER) = MAX(broker), broker, 'Multi')                                                  ## removed min and max statment, need to verify with client. # Lucky#
      ,
         IF(MIN(trader_NAME) = MAX(trader_NAME),
            MIN(trader_NAME), IF(trader_NAME IS NULL, 'Not Provided',
                                 'Multi')),
         RIGHT(sjls_ticker, 2)
    /*
, IF(MIN(ORDERS_MANAGER) = MAX(ORDERS_MANAGER),
        MIN(ORDERS_MANAGER),
        if(ORDERS_MANAGER IS NULL,'NOT PROVIDED','Multi'))
, if(min(BROKER_REASON)=max(BROKER_REASON),
        min(BROKER_REASON),
        if(BROKER_REASON IS NULL,'NOT PROVIDED','Multi'))
, CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
, CAST(GROUP_CONCAT(DISTINCT order_id ORDER BY order_id SEPARATOR ' - ') AS CHAR)
, IF(MIN(descr) = MAX(descr),
        MIN(descr),
        'Multi')
, IF(MIN(prog_trd_id) = MAX(prog_trd_id),
        MIN(prog_trd_id),
        'Multi')
, IF(MIN(program_nonprogram) = MAX(program_nonprogram),
        MIN(program_nonprogram),
        'Multi')
, NULL
, NULL
, NULL
*/
      ,
         IFNULL(Parent_Broker, 'Not Provided')                                                           # Level1
      ,
         IF(MIN(TAG) != MAX(TAG), GROUP_CONCAT(DISTINCT TAG ORDER BY TAG ASC SEPARATOR '-'), TAG)        # Level2
      ,
         IF(MIN(TAG) = 'Cash Flow Trades' and MAX(TAG) = 'Cash Flow Trades', 'CFT Filter', 'N.A.')       #Level3
      ,
         CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR) # Level4
      ,
         IF(MAX(IPO) = 'Y', 'IPO', 'N.A.')                                                               # Level5
      ,
         'Global Filter'                                                                                 # Level6
      ,
         IF(MIN(CONCAT(prog_trd_id, '-', descr)) = MAX(CONCAT(prog_trd_id, '-', descr)),
            MIN(CONCAT(prog_trd_id, '-', descr)), 'Multi')                                               # Level7
      ,
         IF(MAX(min_place_limit) is not null, 'LMT', 'MKT')                                              #Level8
      ,
         IF(MIN(TAG) = 'Quant Portfolio Rebalances' and MAX(TAG) = 'Quant Portfolio Rebalances', 'QR Filter',
            'N.A.')                                                                                      #L9
      ,
         CONCAT(IFNULL(aw.G_Ratio, 'N.A.')#L10
           , '~', 'N.A.' #L11
           , '~', 'N.A.' -- level 12
           , '~', 'N.A.' #L13
           , '~', 'Outlier Reason' #L14
           , '~', 'Options' #L15
           , '~', IF(MIN(program_nonprogram) = MAX(program_nonprogram), MIN(program_nonprogram), 'PROGRAM') #L16
           , '~', IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER), MIN(ALLOCATIONS_ORDER_MANAGER),
                     IF(ALLOCATIONS_ORDER_MANAGER IS NULL, 'NOT PROVIDED', 'MULTI')) #L17
           , '~', CONCAT_WS('-', Parent_Broker, Broker_Type) #L18
           , '~', IFNULL(Broker_Type, 'N.A.') #L19
           , '~', IFNULL(sjls_ticker, 'N.A.') #L20
           , '~', IFNULL(sec_typ_cd, 'N.A.') #L21
           , '~', 'Start Time Bucket' #L22
           , '~', 'Tick Pilot'#L23
           , '~', 'Exchange_Code'
           , '~', 'N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.' #Used to match CRD to XIP custom fields
           , '~', IFNULL(aw.ALGO_STRATEGY, 'N.A.')
           , '~', IFNULL(aw.CONTINGENT_ID, 'N.A.')
           , '~', IFNULL(aw.broker_reason, 'N.A.')
           ),
         Strategy_Code,
         IF(MIN(PAIRS_TRADE) = MAX(PAIRS_TRADE), MIN(PAIRS_TRADE), 'Pairs Trades')                       #Pairs
      ,
         SUM(aw.ALLOCATIONS_TOT_COMMISSION),
         IF(MIN(allocations_acct_cd) = MAX(allocations_acct_cd),
            MIN(allocations_acct_cd), IF(allocations_acct_cd IS NULL, 'Not Provided',
                                         'Multi')),
         sjls_currency,
         sjls_currency,
         IF(MIN(aw.allocations_acct_cd) = MAX(aw.allocations_acct_cd),
            MIN(aw.allocations_acct_cd), IF(aw.allocations_acct_cd IS NULL, 'Not Provided',
                                            'Multi')),
         IF(MIN(instruction) = MAX(instruction), MIN(instruction), IF(instruction IS NULL, 'Not Provided', 'Multi')),
         sjls_secid,
         processDate_in,
         FCM_Broker,
         IF(MIN(Venue) = MAX(venue), MAX(Venue), 'Multi')
  FROM temp_aggregated_info_working aw
  WHERE sjls_ticker <> ''
    AND sjls_ticker IS NOT NULL
  GROUP BY pm_order_id;

  insert into processing_status values (processDate_in, 'Step 27  - build standard output Desk View', now());
  INSERT INTO standardoutput (date_time_gen,
                              date_time_sent,
                              date_time_closed,
                              client_code,
                              bs_order_id,
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
                              trader,
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
                              strategy,
                              traderteam,
                              total_commissions,
                              account,
                              currency,
                              settlement_currency,
                              subaccount,
                              instructions,
                              sjls_secid,
                              file_date,
                              `algorithm`,
                              `Venue`)
  SELECT MIN(orig_order_trader_date_adj) AS orig_order_create_date,
         MIN(orig_order_trader_date_adj) AS orig_order_trader_date,
         MAX(last_fill_date_adj),
         'MFS2',
         desk_order_id,
         'UPLOAD',
         LEFT(side, 1),
         SUM(allocations_exec_qty),
         SUM(allocations_exec_qty),
         sjls_ticker,
         'BLOOMBERG',
         order_type,
         order_duration,
         IF(side = 'Sell',
            MAX(ORDERS_LIMIT),
            MIN(ORDERS_LIMIT)),
         SUM(allocations_exec_amt) / SUM(allocations_exec_qty),
         IF(MIN(BROKER) = MAX(broker), broker, 'MULTI'),
         IF(MIN(DESK_ORDER_TRADER) = MAX(DESK_ORDER_TRADER), DESK_ORDER_TRADER, 'MULTI'),
         RIGHT(sjls_ticker, 2)
    /*
, IF(MIN(ORDERS_MANAGER) = MAX(ORDERS_MANAGER),
        MIN(ORDERS_MANAGER),
        if(ORDERS_MANAGER IS NULL,'NOT PROVIDED','Multi'))
, if(min(BROKER_REASON)=max(BROKER_REASON),
        min(BROKER_REASON),
        if(BROKER_REASON IS NULL,'NOT PROVIDED','Multi'))
, CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
, CAST(GROUP_CONCAT(DISTINCT order_id ORDER BY order_id SEPARATOR ' - ') AS CHAR)
, IF(MIN(descr) = MAX(descr),
        MIN(descr),
        'Multi')
, IF(MIN(prog_trd_id) = MAX(prog_trd_id),
        MIN(prog_trd_id),
        'Multi')
, IF(MIN(program_nonprogram) = MAX(program_nonprogram),
        MIN(program_nonprogram),
        'Multi')
, NULL
, NULL
, NULL
*/
      ,
         IFNULL(Parent_Broker, 'Not Provided')                                                           # Level1
      ,
         IF(MIN(TAG) != MAX(TAG), GROUP_CONCAT(DISTINCT TAG ORDER BY TAG ASC SEPARATOR '-'), TAG)        # Level2
      ,
         IF(MIN(TAG) = 'Cash Flow Trades' and MAX(TAG) = 'Cash Flow Trades', 'CFT Filter', 'N.A.')       #Level3
      ,
         CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR) # Level4
      ,
         IF(MAX(aw.IPO) = 'Y', 'IPO', 'N.A.')                                                            # Level5
      ,
         'Global Filter'                                                                                 # Level6
      ,
         IF(MIN(CONCAT(prog_trd_id, '-', descr)) = MAX(CONCAT(prog_trd_id, '-', descr)),
            MIN(CONCAT(prog_trd_id, '-', descr)), 'Multi')                                               # Level7
      ,
         IF(MAX(min_place_limit) is not null, 'LMT', 'MKT')                                              #Level8
      ,
         IF(MIN(aw.TAG) = 'Quant Portfolio Rebalances' and MAX(TAG) = 'Quant Portfolio Rebalances', 'QR Filter',
            'N.A.')                                                                                      #L9
      ,
         CONCAT(IFNULL(aw.G_Ratio, 'N.A.') #L10
           , '~', 'N.A.' #L11 Legal Entity
           , '~', 'N.A.' -- level 12
           , '~', 'N.A.' #L13 Separately Managed
           , '~', 'Outlier Reason' #L14
           , '~', 'Options' #L15
           , '~', IF(MIN(program_nonprogram) = MAX(program_nonprogram), MIN(program_nonprogram), 'PROGRAM') #L16
           , '~', IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER), MIN(ALLOCATIONS_ORDER_MANAGER),
                     IF(ALLOCATIONS_ORDER_MANAGER IS NULL, 'Not Provided', 'Multi')) #L17
           , '~', CONCAT_WS('-', Parent_Broker, Broker_Type) #L18
           , '~', IFNULL(Broker_Type, 'N.A.') #L19
           , '~', IFNULL(sjls_ticker, 'N.A') #L20
           , '~', IFNULL(sec_typ_cd, 'N.A.') #L21
           , '~', 'Start Time Bucket' #L22
           , '~', 'Tick Pilot' #L23
           , '~', 'Exchange_Code'
           , '~', 'N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.' #Used to match CRD to XIP custom fields
           , '~', IFNULL(aw.ALGO_STRATEGY, 'N.A.')
           , '~', IFNULL(aw.CONTINGENT_ID, 'N.A.')
           , '~', IFNULL(aw.broker_reason, 'N.A.')
           ),
         Strategy_Code,
         IF(MIN(PAIRS_TRADE) = MAX(PAIRS_TRADE), MIN(PAIRS_TRADE), 'Pairs Trades')                       #Pairs
      ,
         SUM(aw.ALLOCATIONS_TOT_COMMISSION),
         IF(MIN(allocations_acct_cd) = MAX(allocations_acct_cd),
            MIN(allocations_acct_cd), IF(allocations_acct_cd IS NULL, 'Not Provided',
                                         'Multi')),
         sjls_currency,
         sjls_currency,
         IF(MIN(allocations_acct_cd) = MAX(allocations_acct_cd),
            MIN(allocations_acct_cd), IF(allocations_acct_cd IS NULL, 'Not Provided',
                                         'MULTI'))                                                       # to provide the fund code.
      ,
         GROUP_CONCAT(DISTINCT instruction separator '-'),
         sjls_secid,
         processDate_in,
         FCM_Broker,
         IF(MIN(Venue) = MAX(venue), MAX(Venue), 'MULTI')
  FROM temp_aggregated_info_working aw
  WHERE sjls_ticker <> ''
    AND sjls_ticker IS NOT NULL
  GROUP BY desk_order_id;


  CALL adjust_cum_order_qty(); #OCX


  CALL process_shares_ordered_routine(processDate_in); #OCX

  insert into processing_status values (processdate_in, 'Step 28  - build standard output broker View', now());
  INSERT INTO standardoutput (date_time_gen,
                              date_time_sent,
                              date_time_closed,
                              client_code,
                              broker_order_id,
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
                              trader,
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
                              strategy,
                              total_commissions,
                              currency,
                              settlement_currency,
                              account,
                              sjls_secid,
                              subaccount,
                              file_date,
                              instructions,
                              `algorithm`,
                              `Venue`)
  SELECT place_date,
         place_date,
         max_fill_date_adj,
         'MFS2',
         place_id,
         'UPLOAD',
         LEFT(side, 1),
         place_qty,
         exec_qty,
         sjls_ticker,
         'BLOOMBERG',
         p.instruction,
         'Day',
         IF(side = 'Sell',
            MAX(limit_price),
            MIN(limit_price)),
         IF(p.multi_placement_tag = 'Y', p.price,
            SUM(aw.allocations_exec_amt) / SUM(aw.allocations_exec_qty)),
         IF(p.Broker_Code IS NULL, 'Not Provided',
            IF(MIN(p.Broker_Code) = MAX(p.Broker_Code), p.Broker_Code,
               'Multi'))                                                                                 # removed min max statement, changed form broker code to broker as in MFS #
      ,
         IF(MIN(trader_NAME) = MAX(trader_NAME),
            MIN(trader_NAME),
            'Multi'),
         RIGHT(sjls_ticker, 2)
         #
    /*
, IF(MIN(ORDERS_MANAGER) = MAX(ORDERS_MANAGER),
        MIN(ORDERS_MANAGER),
        if(ORDERS_MANAGER IS NULL,'NOT PROVIDED','Multi'))
, if(min(BROKER_REASON)=max(BROKER_REASON),
        min(BROKER_REASON),
        if(BROKER_REASON IS NULL,'NOT PROVIDED','Multi'))
, CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
, CAST(GROUP_CONCAT(DISTINCT order_id ORDER BY order_id SEPARATOR ' - ') AS CHAR)
, IF(MIN(descr) = MAX(descr),
        MIN(descr),
        'Multi')
, IF(MIN(prog_trd_id) = MAX(prog_trd_id),
        MIN(prog_trd_id),
        'Multi')
, IF(MIN(program_nonprogram) = MAX(program_nonprogram),
        MIN(program_nonprogram),
        'Multi')
, NULL
, NULL
, NULL
*/
      ,
         IFNULL(p.Parent_Broker, 'Not Provided')                                                         # Level1 'Parent Broker'
      ,
         IF(MIN(aw.TAG) != MAX(aw.TAG), GROUP_CONCAT(DISTINCT aw.TAG ORDER BY aw.TAG ASC SEPARATOR '-'),
            aw.TAG)                                                                                      # Level2
      ,
         IF(MIN(aw.TAG) = 'Cash Flow Trades' and MAX(aw.TAG) = 'Cash Flow Trades', 'CFT Filter', 'N.A.') #Level3
      ,
         CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR) # Level4
      ,
         IF(MAX(aw.IPO) = 'Y', 'IPO', 'N.A.')                                                            # Level5
      ,
         'Global Filter'                                                                                 # Level6
      ,
         IF(MIN(CONCAT(prog_trd_id, '-', descr)) = MAX(CONCAT(prog_trd_id, '-', descr)),
            MIN(CONCAT(prog_trd_id, '-', descr)), 'Multi')                                               # Level7
      ,
         IF(MAX(min_place_limit) is not null, 'LMT', 'MKT')                                              #Level8
      ,
         IF(MIN(aw.TAG) = 'Quant Portfolio Rebalances' and MAX(aw.TAG) = 'Quant Portfolio Rebalances', 'QR Filter',
            'N.A.')                                                                                      #L9
      ,
         CONCAT(IFNULL(aw.G_Ratio, 'N.A.')#L10
           , '~', 'N.A.' #L11 Legal Entity
           , '~', 'N.A.' -- level 12
           , '~', 'N.A.' #L13 Separately managed
           , '~', 'Outlier Reason' #L14
           , '~', 'Options' #L15
           , '~', IF(MIN(program_nonprogram) = MAX(program_nonprogram), MIN(program_nonprogram), 'PROGRAM') #L16
           , '~', IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER), MIN(ALLOCATIONS_ORDER_MANAGER),
                     IF(ALLOCATIONS_ORDER_MANAGER IS NULL, 'Not Provided', 'Multi')) #L17
           , '~', CONCAT_WS('-', p.Parent_Broker, p.Broker_Type) #L18 'Broker + Type'
           , '~', IFNULL(p.Broker_Type, 'Not Provided') #L19 'Broker Type'
           , '~', IFNULL(sjls_ticker, 'N.A.') #L20
           , '~', IFNULL(sec_typ_cd, 'N.A.') #L21
           , '~', 'Start Time Bucket' #L22
           , '~', 'Tick Pilot' #L23
           , '~', 'Exchange_Code'
           , '~', 'N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.' #Used to match CRD to XIP custom fields
           , '~', IFNULL(MAX(p.ALGO_STRATEGY), 'Not Provided')
           , '~', IFNULL(aw.CONTINGENT_ID, 'N.A.')
           , '~', IFNULL(aw.broker_reason, 'N.A.')
           ),
         Strategy_Code,
         PLC_COMMISSIONS,
         sjls_currency,
         sjls_currency,
         IF(MIN(allocations_acct_cd) = MAX(allocations_acct_cd),
            MIN(allocations_acct_cd), IF(allocations_acct_cd IS NULL, 'Not Provided',
                                         'Multi'))#
      ,
         sjls_secid,
         IF(MIN(aw.allocations_acct_cd) = MAX(aw.allocations_acct_cd),
            MIN(aw.allocations_acct_cd), IF(aw.allocations_acct_cd IS NULL, 'Not Provided',
                                            'Multi'))#
      ,
         processDate_in                                                                                  #
      ,
         IF(MIN(aw.instruction) = MAX(aw.instruction),
            MIN(aw.instruction), IF(aw.instruction IS NULL, 'Not Provided',
                                    'Multi'))
      ,
         aw.FCM_Broker,
         IF(MIN(aw.Venue) = MAX(aw.venue), MAX(aw.Venue), 'Multi')
  FROM temp_aggregated_info_working aw,
       temp_placements_working p
  WHERE aw.order_id = p.order_id
    AND sjls_ticker IS NOT NULL
  GROUP BY place_id;


  INSERT INTO processing_status VALUES (processDate_in, '29 - Account View', now());
  INSERT INTO standardoutput (date_time_gen,
                              date_time_sent,
                              date_time_closed,
                              client_code,
                              bs_order_id,
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
                              trader,
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
                              strategy,
                              traderteam,
                              total_commissions,
                              account,
                              currency,
                              settlement_currency,
                              subaccount,
                              instructions,
                              sjls_secid,
                              file_date,
                              `algorithm`,
                              `Venue`)
  SELECT min_fill_date AS orig_order_create_date,
         min_fill_date AS orig_order_trader_date,
         max_fill_date_adj,
         'MFS2',
         DESK_ORDER_ID,
         TRIM(LEFT(CONCAT(place_id, '-', ALLOCATIONS_ACCT_CD), 64)),
         'UPLOAD',
         LEFT(side, 1),
         round(SUM(aw.ALLOCATIONS_EXEC_QTY) * p.exec_qty / p.ORDER_EXEC_QTY, 0),
         round(SUM(aw.ALLOCATIONS_EXEC_QTY) * p.exec_qty / p.ORDER_EXEC_QTY, 0),
         sjls_ticker,
         'BLOOMBERG',
         order_type,
         order_duration,
         IF(side = 'Sell',
            MAX(ORDERS_LIMIT),
            MIN(ORDERS_LIMIT)),
         IF(p.multi_placement_tag = 'Y', p.price,
            SUM(aw.allocations_exec_amt) / SUM(aw.allocations_exec_qty)),
         IF(MIN(BROKER) = MAX(BROKER),
            MIN(BROKER), IF(BROKER IS NULL, 'Not Provided',
                            'Multi')),
         IF(MIN(trader_NAME) = MAX(trader_NAME),
            MIN(trader_NAME), IF(trader_NAME IS NULL, 'Not Provided',
                                 'Multi')),
         RIGHT(sjls_ticker, 2)
    /*
, IF(MIN(ORDERS_MANAGER) = MAX(ORDERS_MANAGER),
        MIN(ORDERS_MANAGER),
        if(ORDERS_MANAGER IS NULL,'NOT PROVIDED','Multi'))
, if(min(BROKER_REASON)=max(BROKER_REASON),
        min(BROKER_REASON),
        if(BROKER_REASON IS NULL,'NOT PROVIDED','Multi'))
, CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR)
, CAST(GROUP_CONCAT(DISTINCT order_id ORDER BY order_id SEPARATOR ' - ') AS CHAR)
, IF(MIN(descr) = MAX(descr),
        MIN(descr),
        'Multi')
, IF(MIN(prog_trd_id) = MAX(prog_trd_id),
        MIN(prog_trd_id),
        'Multi')
, IF(MIN(program_nonprogram) = MAX(program_nonprogram),
        MIN(program_nonprogram),
        'Multi')
, NULL
, NULL
, NULL
*/
      ,
         IFNULL(p.Parent_Broker, 'Not Provided')                                                         # Level1
      ,
         IF(MIN(TAG) != MAX(TAG), GROUP_CONCAT(DISTINCT TAG ORDER BY TAG ASC SEPARATOR '-'), TAG)        # Level2
      ,
         IF(MIN(TAG) = 'Cash Flow Trades' and MAX(TAG) = 'Cash Flow Trades', 'CFT Filter', 'N.A.')       #Level3
      ,
         CAST(GROUP_CONCAT(DISTINCT sec_check_status ORDER BY sec_check_status SEPARATOR ' - ') AS CHAR) # Level4
      ,
         IF(MAX(IPO) = 'Y', 'IPO', 'N.A.')                                                               # Level5
      ,
         'Global Filter'                                                                                 # Level6
      ,
         IF(MIN(CONCAT(prog_trd_id, '-', descr)) = MAX(CONCAT(prog_trd_id, '-', descr)),
            MIN(CONCAT(prog_trd_id, '-', descr)), 'Multi')                                               # Level7
      ,
         IF(MAX(min_place_limit) is not null, 'LMT', 'MKT')                                              #Level8
      ,
         IF(MIN(TAG) = 'Quant Portfolio Rebalances' and MAX(TAG) = 'Quant Portfolio Rebalances', 'QR Filter',
            'N.A.')                                                                                      #L9
      ,
         CONCAT(IFNULL(aw.G_Ratio, 'N.A.') #L10
           , '~', 'N.A.' #L11 # Legal Entity
           , '~', 'N.A.' -- level 12
           , '~', 'N.A.' #L13 Separately Managed
           , '~', 'Outlier Reason' #L14
           , '~', 'Options' #L15 Options
           , '~', IF(MIN(program_nonprogram) = MAX(program_nonprogram), MIN(program_nonprogram), 'PROGRAM') #L16
           , '~', IF(MIN(ALLOCATIONS_ORDER_MANAGER) = MAX(ALLOCATIONS_ORDER_MANAGER), MIN(ALLOCATIONS_ORDER_MANAGER),
                     IF(ALLOCATIONS_ORDER_MANAGER IS NULL, 'NOT PROVIDED', 'Multi')) #L17
           , '~', CONCAT_WS('-', p.Parent_Broker, p.Broker_Type) #L18
           , '~', IFNULL(p.Broker_Type, 'N.A.') #L19
           , '~', IFNULL(sjls_ticker, 'N.A.') #L20
           , '~', IFNULL(sec_typ_cd, 'N.A.') #L21
           , '~', 'Start Time Bucket' #L22
           , '~', 'Tick Pilot' #L23
           , '~', 'Exchange_Code'
           , '~', 'N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.~N.A.' #Used to match CRD to XIP custom fields
           , '~', IFNULL(aw.ALGO_STRATEGY, 'Not Provided')
           , '~', IFNULL(aw.CONTINGENT_ID, 'N.A.')
           , '~', IFNULL(aw.broker_reason, 'N.A.')
           ),
         aw.Strategy_Code,
         IF(MIN(PAIRS_TRADE) = MAX(PAIRS_TRADE), MIN(PAIRS_TRADE), 'Pairs Trades')                       #Pairs
      ,
         SUM(aw.ALLOCATIONS_TOT_COMMISSION),
         IF(MIN(allocations_acct_cd) = MAX(allocations_acct_cd),
            MIN(allocations_acct_cd), IF(allocations_acct_cd IS NULL, 'Not Provided',
                                         'Multi')),
         sjls_currency,
         sjls_currency,
         IF(MIN(aw.allocations_acct_cd) = MAX(allocations_acct_cd),
            MIN(aw.allocations_acct_cd), IF(allocations_acct_cd IS NULL, 'Not Provided',
                                            'Multi')),
         IF(MIN(aw.instruction) = MAX(aw.instruction), MIN(aw.instruction),
            IF(aw.instruction IS NULL, 'Not Provided', 'Multi')),
         sjls_secid,
         processDate_in,
         FCM_Broker,
         IF(MIN(p.Venue) = MAX(p.venue), MAX(aw.Venue), 'Multi')
  FROM temp_aggregated_info_working aw,
       temp_placements_working p
  WHERE aw.order_id = p.order_id
    AND sjls_ticker IS NOT NULL
  GROUP BY p.place_id, ALLOCATIONS_ACCT_CD;


  insert into processing_status values (processDate_in, '33 - Updates', now());
  UPDATE standardoutput
  SET date_time_closed = date_time_gen + INTERVAL 1 SECOND
  WHERE date_time_gen >= Date_time_Closed;

  UPDATE standardoutput SET time_in_force = 'DAY' WHERE time_in_force IN ('D', 'Day');
  # CFT and QR Filters to N.A. for suspect data, pairs, MOC
  UPDATE standardoutput
  SET level3 = 'N.A.',
      level9 = 'N.A.'
  WHERE level4 regexp 'Suspect'
     OR traderteam != 'N.A.'
     OR instructions IN ('MCL', 'MCC', 'MCN');
  # Remove regional suffix from broker-codes to match XIP
  UPDATE standardoutput
  SET broker = TRIM(TRAILING SUBSTRING_INDEX(broker, '-', -1) FROM broker)
  WHERE broker regexp '-';

  insert into processing_status values (processDate_in, '34 - MOO,MOC', now());
  update standardoutput
  set date_time_gen = if(date(date_time_closed) + interval 7 hour < date_time_closed,
                         cast(date(date_time_closed) + interval 7 hour as datetime),
                         cast((date_time_closed - interval 5 minute) as datetime)),
      `status`      = 'update times for moo and moc'
  where time_in_force = 'ON_CLOSE'
    and date(date_time_gen) <> date(date_time_closed)
    and file_date = processDate_in
    and broker_order_id is null;

  insert into processing_status
  values (processDate_in, 'Step 35  - Update standard output with major/minor currency', now());
  UPDATE standardoutput so, market_data.adjust_prices ap
  SET average_exec_price = average_exec_price * Multiplier,
      limit_price        = limit_price * Multiplier,
      total_commissions  = total_commissions * Multiplier
  WHERE ExchangeCode = Country
    AND (Currency collate latin1_general_cs NOT IN ('EUR', 'USD', 'GBP') OR Currency IS NULL)
    AND file_date = processdate_in;

  insert into processing_status
  values (processDate_in, 'Step 36  - DELETE FRPM standard output FOR county CB', now());
  UPDATE standardoutput
  SET limit_price = CASE
                      WHEN limit_price > 100 * average_exec_price THEN NULL
                      WHEN limit_price < average_exec_price / 100 THEN NULL
                      ELSE limit_price
    END;

  UPDATE standardoutput SET shares_ordered = 0 WHERE shares_ordered IS NULL;
  UPDATE standardoutput SET shares_executed = 0 WHERE shares_executed IS NULL;

  insert into processing_status values (processDate_in, 'Step 37.0  - StdO Updates', now());

  #CALL process_standardoutput_fills_aggregate_routine(processDate_in);

  insert into processing_status values (processDate_in, 'Step 37.1 - EU Composite and Canada interlisted', now());
  CALL process_eu_composite_routine_sedol(processDate_in, '2014-01-01');

  # Lucky Yona 8/27/2018 reintroduced cash flow line from original MFS

  UPDATE standardoutput
  SET level2 = CASE
                 WHEN level2 IN ('Cash Flow Trades-Cross', 'Cash Flow Trades-N.A.')
                   THEN 'Cash Flow Trades'
                 WHEN level2 IN ('Cash Flow Trades-Quant Portfolio Rebalances',
                                 'Cross-Quant Portfolio Rebalances',
                                 'N.A.-Quant Portfolio Rebalances')
                   THEN 'Quant Portfolio Rebalances'
                 ELSE level2
    END;

  UPDATE standardoutput
  SET level6 = 'N.A.',
      level3 = 'N.A.'
  WHERE level2 = 'MULTI'
     OR LEFT(level10, 5) = 'MULTI';

  UPDATE standardoutput s, market_data.security_master m
  SET s.symbol = m.cusip
  WHERE s.sjls_secid = m.sjls_secid
    AND date(s.date_time_gen) BETWEEN m.effective_date AND m.expire_date;

  UPDATE standardoutput s, market_data.security_master m
  SET s.sjls_secid  = m.sjls_secid,
      s.security_id = CONCAT(m.ticker, ' _U')
  WHERE s.country = 'US'
    AND s.symbol = m.cusip
    AND m.exchange_code = '_U'
    AND date(s.date_time_gen) BETWEEN m.effective_date AND m.expire_date
    AND LEFT(s.security_id, 3) != 'VRX';

  UPDATE standardoutput s, market_data.security_master m
  SET s.sjls_secid  = m.sjls_secid,
      s.security_id = CONCAT(m.ticker, ' _U')
  WHERE s.country = 'US'
    AND s.symbol = m.cusip
    AND m.exchange_code = '_U'
    AND date(s.date_time_gen) BETWEEN m.effective_date AND m.expire_date
    AND LEFT(s.security_id, 3) != 'VRX';

  insert into processing_status values (processDate_in, 'Step 37.2 - Liquidity/ADV Check', now());
  CALL process_liquidity_check_routine(processDate_in);

  insert into processing_status values (processDate_in, 'Step 37.3 - Options Check', now());
  ##Lucky Yona, reactivated process_options_trades_check after implementing dependencies. 8/14/2018
  CALL process_options_trades_check(processDate_in);

  ### Populate Time Buckets and Process Outlier Reason and Global Filters
  # Created new subroutine that translated old XIP time bucket mechanism for CRD Lucky Yona 08/14/2018 and disaggregated it from outlier reason

  insert into processing_status values (processDate_in, 'Process Time Buckets', now());

  CALL process_time_buckets(processDate_in);

  # Edited process outlier reason to make it compatible with mfs2.
  CALL process_outlier_reason(processDate_in);

  update standardoutput
  set level6 = 'Other';

  update standardoutput
  set level6 = 'Analyze'
  where level10 regexp 'None';

  # Update in tick pilot groups
  UPDATE standardoutput s, cloned_pt.tick_pilot_list t
  SET level10 = REPLACE(s.level10, 'Tick Pilot', t.`Group`)
  WHERE s.sjls_secid = t.sjls_secid;
  UPDATE standardoutput s SET level10 = REPLACE(s.level10, 'Tick Pilot', 'Not Applicable');

  #### Update separately managed status -- Lucky Yona 8/14/2018
  insert into processing_status values (processDate_in, 'Update Separately Managed Status', now());

  call XIP_adjust();

  # Assign Order type based on hierarchy in cases where construction logic results in multi order types.
  UPDATE standardoutput
  SET instructions = IF(instructions regexp 'MCC', 'MCC',
                        IF(instructions regexp 'MCN' and instructions not regexp 'MCC', 'MCN',
                           IF(instructions regexp 'LMT' and instructions not regexp 'MCC' and
                              instructions not regexp 'MCN', 'LMT',
                              IF(instructions regexp 'LVL' and instructions not regexp 'MCC' and
                                 instructions not regexp 'MCN' and instructions not regexp 'LMT', 'LVL',
                                 instructions))));


  # Per Mark's request, if there is any other more restrictive order type in an order's life, that needs to override the reported final order type.

  drop table if exists temp_order_history;
  CREATE TABLE `temp_order_history`
  (
    `ORDER_ID` varchar(255) COLLATE latin1_general_ci   NOT NULL DEFAULT '',
    `MSG_TEXT` varchar(65000) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    KEY ORDER_ID (`ORDER_ID`)
  )
    ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  insert into temp_order_history (
    select ORDER_ID,MSG_TEXT
    from mfs2_data.order_history
    where MSG_TEXT regexp ' MCC '
       or MSG_TEXT regexp ' MCC '
       or MSG_TEXT regexp ' MCN '
       or MSG_TEXT regexp ' LMT '
       or MSG_TEXT regexp ' LVL ');


  DROP TABLE IF EXISTS order_type_history;
  CREATE TABLE `order_type_history`
  (
    `ORDER_ID` varchar(255) COLLATE latin1_general_ci   NOT NULL DEFAULT '',
    `MSG_TEXT` varchar(65000) COLLATE latin1_general_ci NOT NULL DEFAULT '',
    KEY (`ORDER_ID`),
    KEY `by_filedate` (`MSG_TEXT`)
  ) ENGINE = TokuDB
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;


  insert into order_type_history (
    select ORDER_ID, GROUP_CONCAT(MSG_TEXT SEPARATOR '<>') from temp_order_history group by ORDER_ID
  );

  delete from order_type_history where ORDER_ID in ('140023055');

  update temp_aggregated_info_working aw, order_type_history h
  set aw.instruction = IF(h.MSG_TEXT regexp 'MCC', 'MCC',
                          IF(h.MSG_TEXT regexp 'MCN' and h.MSG_TEXT not regexp 'MCC', 'MCN',
                             IF(h.MSG_TEXT regexp 'LMT' and h.MSG_TEXT not regexp 'MCC' and h.MSG_TEXT not regexp 'MCN',
                                'LMT',
                                IF(h.MSG_TEXT regexp 'LVL' and h.MSG_TEXT not regexp 'MCC' and
                                   h.MSG_TEXT not regexp 'MCN' and h.MSG_TEXT not regexp 'LMT', 'LVL', h.MSG_TEXT))))
  where aw.order_id = h.ORDER_ID;


  insert into processing_status values (processDate_in, 'Step 38  - Truncate standardformat', now());
  SELECT CURRENT_DATE(), CURRENT_TIME();

  TRUNCATE TABLE standardformat;

  insert into processing_status values (processDate_in, 'Step 39  - Insert to standardformat', now());
  INSERT IGNORE INTO standardformat (date_time_gen,
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


  #Lucky Yona -- Merge XIP and CRD data as below

  delete from mfs.standardformat where date_time_gen > '2018-04-27';

  replace into mfs.standardformat(select * from mfs2.standardformat);

  update mfs.standardformat set client_code = 'MFS' where client_code = 'MFS2';

  insert into processing_status values (processDate_in, 'END Process', now());
END;

