create procedure check_securityid_prices_routine(IN processDate_in date)
BEGIN

  insert into processing_status
  values (processDate_in, 'Step 18.2  - set sjls_ticker, secid and currency for all US tickers', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker  = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid   = sec.sjls_secid
    , cp.sjls_currency= sec.currency
  WHERE LEFT(cp.ticker, LENGTH(TRIM(cp.ticker)) - 3) = sec.ticker
    AND sec.exchange_code = 'US'
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated
    AND (cp.country = 'USA' OR cp.country = 'US');

  insert into processing_status
  values (processDate_in, 'Step 18.3 - set sjls_ticker, secid and currency based on SEDOl Join', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker   = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid    = sec.sjls_secid
    , cp.sjls_currency = sec.currency
  WHERE cp.sjls_secid IS NULL
    AND cp.sedol = sec.sedol
    AND cp.country = sec.exchange_code
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated
    AND cp.country != 'USA'
    AND cp.country != 'US';

  insert into processing_status
  values (processDate_in, 'Step 18.4 - set sjls_ticker, secid and currency based on ISIN Join', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker   = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid    = sec.sjls_secid
    , cp.sjls_currency = sec.currency
  WHERE cp.sjls_secid IS NULL
    AND cp.isin = sec.isin
    AND cp.country = sec.exchange_code
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated;

  insert into processing_status
  values (processDate_in, 'Step 18.5 - set sjls_ticker, secid and currency based on CUSIP Join', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker   = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid    = sec.sjls_secid
    , cp.sjls_currency = sec.currency
  WHERE cp.sjls_secid IS NULL
    AND sec.exchange_code = 'US'
    AND cp.cusip = sec.cusip
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated
    AND (cp.country = 'USA' or cp.country = 'US');

  insert into processing_status
  values (processDate_in, 'Step 18.6 - set sjls_ticker, secid and currency based on sjls_secid IS NULL', now());
  UPDATE temp_convert_secs_check_prices cp , market_data.exception_ticker_mapping et
  SET cp.ticker = CONCAT(et.sjls_ticker, ' ', cp.country)
  WHERE LEFT(cp.ticker, LENGTH(TRIM(cp.ticker)) - 3) = et.exception_ticker
    AND cp.sjls_secid IS NULL;

  insert into processing_status
  values (processDate_in, 'Step 18.7 - set sjls_ticker, secid and currency based on ticker Join', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker   = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid    = sec.sjls_secid
    , cp.sjls_currency = sec.currency
  WHERE LEFT(cp.ticker, LENGTH(TRIM(cp.ticker)) - 3) = sec.ticker
    AND cp.country = sec.exchange_code
    AND cp.sjls_secid IS NULL
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated;

  insert into processing_status
  values (processDate_in, 'Step 18.8 - set sjls_ticker, secid and currency for all US tickers', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker   = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid    = sec.sjls_secid
    , cp.sjls_currency = sec.currency
  WHERE CONCAT(LEFT(cp.ticker, 4), '.', MID(cp.ticker, 5, 1)) = sec.ticker
    AND LENGTH(TRIM(cp.ticker)) - 3 = 5
    AND cp.country = 'US'
    AND cp.country = sec.exchange_code
    AND cp.sjls_secid IS NULL
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated;

  insert into processing_status
  values (processDate_in,
          'Step 18.9 - set sjls_ticker, secid and currency for all US tickers where sjls_secid IS still NULL', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker   = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid    = sec.sjls_secid
    , cp.sjls_currency = sec.currency
  WHERE cp.sjls_secid IS NULL
    AND cp.sedol = sec.sedol
    AND cp.country = sec.exchange_code
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated
    AND (cp.country = 'USA' or cp.country = 'US');

  insert into processing_status
  values (processDate_in,
          'Step 18.9 - set sjls_ticker, secid and currency for all US tickers where sjls_secid IS still NULL', now());
  UPDATE temp_convert_secs_check_prices cp
    , market_data.security_master sec
  SET cp.sjls_ticker   = CONCAT(sec.ticker, ' ', sec.exchange_code)
    , cp.sjls_secid    = sec.sjls_secid
    , cp.sjls_currency = sec.currency
  WHERE cp.sjls_secid IS NULL
    AND cp.sedol = sec.sedol
    AND substring_index(cp.ticker, ' ', -1) = sec.exchange_code
    AND cp.Date_Generated >= sec.effective_date
    AND sec.expire_date >= cp.Date_Generated
    AND cp.Currency = sec.currency;

  insert into processing_status values (processDate_in, 'Step 18.14 - START - check_all_prices_routine', now());
  call check_all_prices_routine(processDate_in);
  insert into processing_status values (processDate_in, 'Step 18.14 - END - check_all_prices_routine', now());

  insert into processing_status values (processDate_in, 'Step 18.19 - tag where No Match', now());
  UPDATE temp_convert_secs_check_prices
  SET status = 'No Match'
  WHERE sjls_secid is null;

  insert into processing_status values (processDate_in, 'Step 18.20 - tag where New Security', now());
  UPDATE temp_convert_secs_check_prices cp
  SET status = 'New Security'
  WHERE cp.sjls_secid is not null
    AND NOT EXISTS(SELECT s.sjls_secid
                   FROM market_data.sec_daily_stats s
                   WHERE cp.sjls_secid = s.sjls_secid
                     AND DATE_ADD(DATE(cp.Date_Generated), INTERVAL -1 DAY) > s.trade_date);

  insert into processing_status values (processDate_in, 'Step 18.21 - set currencies on specials', now());
  UPDATE temp_convert_secs_check_prices t
    , market_data.security_master s
  SET t.sjls_currency = s.currency
  WHERE t.sjls_secid = s.sjls_secid
    AND t.country = s.exchange_code
    AND Date_Generated >= s.effective_date
    AND s.expire_date >= Date_Generated;

  call russian_securities_correction_routine(processDate_in);

END;

