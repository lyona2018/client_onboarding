create procedure process_adjust_fills_majorminor_ccy_routine(IN processDate_in date)
BEGIN


  INSERT INTO processing_status VALUES (processDate_in, 'BEGIN - process_adjust_fills_majorminor_ccy_routine', now());
  INSERT INTO processing_status
  VALUES (processDate_in, 'Step 1 - Create Temp Tables for use in Major Minor ccy adj', now());

  INSERT INTO processing_status
  VALUES (processDate_in, 'Step 1a - temp_secids - unique secid and trade_date list', now());
  DROP TABLE IF EXISTS temp_secids;
  CREATE TABLE `temp_secids`
  (
    `sjls_secid`    varchar(23) DEFAULT NULL,
    `adj_fill_date` date        DEFAULT NULL
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_secids
  SELECT b.sjls_secid, b.FILL_DATE
  FROM temp_fills_buckets_working b
  WHERE b.exchange_code IN ('LN', 'IT', 'KK', 'SJ')
  GROUP BY sjls_secid, FILL_DATE;

  INSERT INTO processing_status
  VALUES (processDate_in, 'Step 1b - create index on temp_secids - secid and adj_fill_date', now());

  ALTER TABLE temp_secids
    ADD INDEX idxsjlssec (sjls_secid),
    ADD INDEX idxsdt (adj_fill_date);

  INSERT INTO processing_status
  VALUES (processDate_in, 'Step 1c - temp_secstats - unique secid and trade_date list, pl and ph', now());
  DROP TABLE IF EXISTS temp_secstats;
  CREATE TABLE `temp_secstats`
  (
    `sjls_secid`    varchar(22) COLLATE latin1_general_ci NOT NULL,
    `adj_fill_date` date                                  NOT NULL,
    `pl`            decimal(14, 6) DEFAULT NULL,
    `ph`            decimal(14, 6) DEFAULT NULL,
    PRIMARY KEY (`sjls_secid`, `adj_fill_date`)
  ) ENGINE = MyISAM
    DEFAULT CHARSET = latin1
    COLLATE = latin1_general_ci;

  INSERT INTO temp_secstats (
    SELECT STRAIGHT_JOIN i.sjls_secid,
                         i.adj_fill_date,
                         s.pl,
                         s.ph
    FROM temp_secids i,
         market_data.sec_daily_stats s
    WHERE i.sjls_secid = s.sjls_secid
      AND s.trade_date = i.adj_fill_date);

  INSERT IGNORE INTO temp_secstats (
    SELECT STRAIGHT_JOIN i.sjls_secid,
                         i.adj_fill_date,
                         s.pl,
                         s.ph
    FROM temp_secids i,
         market_data.sec_daily_stats s
    WHERE i.sjls_secid = s.sjls_secid
      AND s.trade_date = DATE_SUB(i.adj_fill_date, INTERVAL 1 DAY));

  INSERT IGNORE INTO temp_secstats (
    SELECT STRAIGHT_JOIN i.sjls_secid,
                         i.adj_fill_date,
                         s.pl,
                         s.ph
    FROM temp_secids i,
         market_data.sec_daily_stats s
    WHERE i.sjls_secid = s.sjls_secid
      AND s.trade_date = DATE_SUB(i.adj_fill_date, INTERVAL 3 DAY));

  INSERT IGNORE INTO temp_secstats (
    SELECT STRAIGHT_JOIN i.sjls_secid,
                         i.adj_fill_date,
                         s.pl,
                         s.ph
    FROM temp_secids i,
         market_data.sec_daily_stats s
    WHERE i.sjls_secid = s.sjls_secid
      AND s.trade_date = DATE_SUB(i.adj_fill_date, INTERVAL 4 DAY));

  INSERT INTO processing_status VALUES (processDate_in, 'Step 2 - FILL_AMTS with major/minor currency adjusts', now());
  UPDATE temp_fills_buckets_working f
    JOIN
    market_data.adjust_prices a
    ON
      f.exchange_code = a.exchangecode
    JOIN
    temp_secstats s
    ON
        f.sjls_secid = s.sjls_secid
        AND
        s.adj_fill_date = f.FILL_DATE
  SET f.FILL_AMT = IF(f.FILL_AMT / f.FILL_QTY * a.multiplier > s.pl - 5 * s.pl / 100
                        AND f.FILL_AMT / f.FILL_QTY * a.multiplier < s.ph + 5 * s.ph / 100,
                      f.FILL_AMT / f.FILL_QTY * a.multiplier,
                      f.FILL_AMT / f.FILL_QTY) * f.FILL_QTY;

  INSERT INTO processing_status VALUES (processDate_in, 'drop temp stats and secids tables', now());


  INSERT INTO processing_status VALUES (processDate_in, 'END - process_adjust_fills_majorminor_ccy_routine', now());
END;

