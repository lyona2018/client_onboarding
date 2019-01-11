create procedure adjust_cum_order_qty()
BEGIN

    DECLARE _row_counter double;
    DECLARE _DESK_ORDER_ID varchar(68);
    DECLARE _ORIG_ORDER_ID varchar(68);
    DECLARE _sum_fills double;
    DECLARE _orig_target_qty double;
    DECLARE _cum_target_qty double;
    DECLARE _prev_ORIG_ORDER_ID varchar(68);
    DECLARE _prev_sum_fills double;
    DECLARE _prev_cum_target_qty double;

    DECLARE done integer default 0;
    DECLARE orders_cursor cursor for select row_counter,DESK_ORDER_ID,ORIG_ORDER_ID,sum_fills,orig_target_qty,cum_target_qty from temp_sum_fills_trader_times;
    DECLARE continue handler for not found set done = 1;

    SET @cnt = 0;
    SET _prev_ORIG_ORDER_ID = 0;


	DROP TABLE IF EXISTS temp_cum_order_qty;
    CREATE TABLE `temp_cum_order_qty` (
	  `row_counter`  int NOT NULL AUTO_INCREMENT,
	  `DESK_ORDER_ID` varchar(68) COLLATE latin1_general_ci DEFAULT NULL,
	  `ORIG_ORDER_ID` varchar(68) COLLATE latin1_general_ci DEFAULT NULL,
	  `sum_fills` double DEFAULT NULL,
	  `orig_target_qty` double DEFAULT NULL,
	  `cum_target_qty` double DEFAULT NULL,
	  PRIMARY KEY (`row_counter`)
    ) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

    INSERT INTO temp_cum_order_qty
    SELECT
		@cnt,
        DESK_ORDER_ID,
        ORIG_ORDER_ID,
        sum_fills,
        orig_target_qty,
        cum_target_qty
    FROM
        temp_sum_fills_trader_times
    ORDER BY
		row_counter;


    OPEN orders_cursor;

	DROP TABLE IF EXISTS temp_final_cum_order_qty;
    CREATE TABLE `temp_final_cum_order_qty` (
	  `row_counter` double,
	  `DESK_ORDER_ID` varchar(68) COLLATE latin1_general_ci DEFAULT NULL,
	  `ORIG_ORDER_ID` varchar(68) COLLATE latin1_general_ci DEFAULT NULL,
	  `sum_fills` double DEFAULT NULL,
	  `orig_target_qty` double DEFAULT NULL,
	  `cum_target_qty` double DEFAULT NULL,
      KEY `idx1` (`DESK_ORDER_ID`)
    ) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;

    REPEAT

        FETCH orders_cursor
            INTO
                _row_counter
              , _DESK_ORDER_ID
              , _ORIG_ORDER_ID
              , _sum_fills
              , _orig_target_qty
              , _cum_target_qty;

        IF  _ORIG_ORDER_ID = _prev_ORIG_ORDER_ID
        THEN
            SET
			_cum_target_qty = _prev_cum_target_qty -_prev_sum_fills;
          END IF;

		INSERT INTO
            temp_final_cum_order_qty
        SELECT
                _row_counter
              , _DESK_ORDER_ID
              , _ORIG_ORDER_ID
              , _sum_fills
              , _orig_target_qty
              , _cum_target_qty;

         SET _prev_cum_target_qty =_cum_target_qty;
         SET _prev_ORIG_ORDER_ID =_ORIG_ORDER_ID;
         SET _prev_sum_fills =_sum_fills;

    UNTIL done END REPEAT;

    UPDATE temp_aggregated_info_working a, temp_final_cum_order_qty b
    SET a.orig_target_qty = b.cum_target_qty
    WHERE a.DESK_ORDER_ID = b.DESK_ORDER_ID;


  END;

