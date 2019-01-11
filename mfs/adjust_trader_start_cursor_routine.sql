create procedure adjust_trader_start_cursor_routine()
BEGIN
     DECLARE _row_counter double;
    DECLARE _trader_date_updated varchar(1);
    DECLARE _client_to_trader_date datetime(3);
    DECLARE _to_trader_date datetime(3);
    DECLARE _first_fill_date datetime(3);
    DECLARE _last_fill_date datetime(3);
    DECLARE _orig_target_qty double;
    DECLARE _shares_open double;
    DECLARE _orig_order_id varchar(11);
	DECLARE _order_id varchar(11);
    DECLARE _action_type varchar(10);
    DECLARE _USR_CLASS_CD_2 varchar(30);
    DECLARE _trader_name varchar(59);
    DECLARE _order_type varchar(3);
    DECLARE _sec_id varchar(20);
    DECLARE _side varchar(7);
    DECLARE _prev_orig_target_qty double; 
    DECLARE _prev_shares_open double;
    DECLARE _prev_side varchar(7);
    DECLARE _prev_sec_id varchar(20);
    DECLARE _prev_trader_name varchar(59);
    DECLARE _prev_order_type varchar(3);
	DECLARE _prev_to_trader_date datetime(3);
	DECLARE _prev_orig_order_id varchar(11);
	DECLARE _prev_order_id varchar(11);
	DECLARE _prev_first_fill_date datetime(3);
    DECLARE _prev_action_type varchar(10);
    DECLARE _prev_USR_CLASS_CD_2 varchar(30);
    
    DECLARE done integer default 0;
    DECLARE orders_cursor cursor for select row_counter,to_trader_date,first_fill_date,last_fill_date,orig_target_qty,shares_open,orig_order_id,order_id,action_type,usr_class_cd_2,trader_name, order_type, sec_id, side from temp_trader_start_times;
    DECLARE continue handler for not found set done = 1;
    
    SET _prev_to_trader_date  = '2009-01-01 12:00:00';
    SET @cnt = 0;
        
    DROP TABLE IF EXISTS temp_trader_start_times;
    CREATE TABLE `temp_trader_start_times` (
        `row_counter`  int NOT NULL AUTO_INCREMENT,
        `trader_date_updated` varchar(1) COLLATE latin1_general_ci DEFAULT NULL,
        `client_to_trader_date` datetime(3) DEFAULT NULL,
        `to_trader_date` datetime(3) DEFAULT NULL,        
        `first_fill_date` datetime(3) DEFAULT NULL,
        `last_fill_date` datetime(3) DEFAULT NULL,
        `orig_target_qty` double DEFAULT NULL,
        `shares_open` double DEFAULT NULL,
        `orig_order_id` varchar(11) COLLATE latin1_general_ci DEFAULT NULL,
        `order_id` varchar(11) COLLATE latin1_general_ci DEFAULT NULL,
        `action_type` varchar(10) COLLATE latin1_general_ci DEFAULT NULL,
        `USR_CLASS_CD_2` varchar(30) COLLATE latin1_general_ci DEFAULT NULL,
        `trader_name` varchar(59) COLLATE latin1_general_ci DEFAULT NULL,
		`order_type` varchar(3) COLLATE latin1_general_ci DEFAULT '',
        `sec_id` varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
        `side` varchar(7) COLLATE latin1_general_ci DEFAULT NULL,
        `BREAK` varchar(9) COLLATE latin1_general_ci NOT NULL DEFAULT '',
          PRIMARY KEY (`row_counter`)
    ) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
    

    INSERT INTO temp_trader_start_times
    SELECT 
		@cnt as `row_counter`,
		trader_date_updated,
		to_trader_date,
		IF(to_trader_date > first_fill_date and trader_date_updated = 'N',first_fill_date,to_trader_date),
		first_fill_date,
		last_fill_date,
		ORIG_TARGET_QTY,
		shares_open,
		orig_order_id,
		order_id,
		action_type,
		NULL,
		trader_name,
        order_type,
		sec_id,
		side,
		'YES'
    FROM
        temp_aggregated_info_working
	WHERE
		  program_nonprogram = 'NON-PROGRAM' AND (IPO != 'Y')
    ORDER BY
		row_counter;

		
		UPDATE temp_trader_start_times a
			 , temp_trader_start_times b 
		SET a.to_trader_date = a.first_fill_date
		WHERE
		a.sec_id = b.sec_id AND 
		a.side = b.side AND
		a.trader_name != b.trader_name AND
		
		a.row_counter = (b.row_counter + 1) AND
		a.to_trader_date <= b.to_trader_date AND
        a.first_fill_date > b.first_fill_date
		;
        
		UPDATE temp_trader_start_times a
			 , temp_trader_start_times b 
		SET a.to_trader_date = a.client_to_trader_date
		WHERE
		a.sec_id = b.sec_id AND 
		a.side = b.side AND
		a.trader_name != b.trader_name AND
		a.to_trader_date < b.first_fill_date AND
		a.client_to_trader_date BETWEEN a.to_trader_date AND a.first_fill_date AND
		a.action_type = 'CHG' AND
		a.row_counter = (b.row_counter + 1);
        
		UPDATE temp_trader_start_times a
			 , temp_trader_start_times b 
		SET a.to_trader_date = a.first_fill_date
		WHERE
		a.sec_id = b.sec_id AND 
		a.side = b.side AND
		a.trader_name = b.trader_name AND
		
        a.order_type = b.order_type AND
        
        a.order_id != b.order_id AND
		a.row_counter = (b.row_counter + 1) AND
		a.to_trader_date <= b.last_fill_date AND
        a.first_fill_date > b.last_fill_date
		;
			
    OPEN orders_cursor;

    DROP TABLE IF EXISTS temp_final_trader_start_times;
    CREATE TABLE `temp_final_trader_start_times` (
        `row_counter` double DEFAULT NULL,
        
        
        `to_trader_date` datetime(3) DEFAULT NULL,        
        `first_fill_date` datetime(3) DEFAULT NULL,
        `last_fill_date` datetime(3) DEFAULT NULL,
        `orig_target_qty` double DEFAULT NULL,
        `shares_open` double DEFAULT NULL,
        `orig_order_id` varchar(11) COLLATE latin1_general_ci DEFAULT NULL,
        `order_id` varchar(11) COLLATE latin1_general_ci DEFAULT NULL,
        `action_type` varchar(10) COLLATE latin1_general_ci DEFAULT NULL,
        `USR_CLASS_CD_2` varchar(30) COLLATE latin1_general_ci DEFAULT NULL,
        `trader_name` varchar(59) COLLATE latin1_general_ci DEFAULT NULL,
		`order_type` varchar(3) COLLATE latin1_general_ci DEFAULT '',
        `sec_id` varchar(20) COLLATE latin1_general_ci DEFAULT NULL,
        `side` varchar(7) COLLATE latin1_general_ci DEFAULT NULL,
        `BREAK` varchar(9) COLLATE latin1_general_ci NOT NULL DEFAULT '',
        KEY `idx_link_to_source` (`orig_order_id`,`order_id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=latin1 COLLATE=latin1_general_ci;
        
    REPEAT
        FETCH orders_cursor 
            INTO 
                _row_counter
              , _to_trader_date
              , _first_fill_date
              , _last_fill_date
              , _orig_target_qty
              , _shares_open
              , _orig_order_id
              , _order_id
              , _action_type
              , _usr_class_cd_2
              , _trader_name
              , _order_type
              , _sec_id
              , _side;              
		
        IF  		(_prev_orig_target_qty	>= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_to_trader_date 		>= _to_trader_date)
						OR
                    (_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_to_trader_date 		<= _to_trader_date
					AND
						_prev_orig_order_id			<= _orig_order_id
					AND
						_prev_order_id >= _order_id
					) 
						OR
					(
						_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_first_fill_date 		= _first_fill_date
					AND
						_prev_shares_open			= _shares_open
					AND 
						_prev_usr_class_cd_2		= _usr_class_cd_2
                    )
						OR
                    (_prev_orig_target_qty	= _orig_target_qty 
					AND
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_first_fill_date 		= _first_fill_date
					AND 
						(_action_type IS NULL OR _action_type NOT IN ('SPLITFROM','MRGDFROM')
                    )
                    OR
                    					(
						_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name	
					AND
						_prev_order_type          	= _order_type
					AND
						(_prev_action_type			!= _action_type OR 
							_prev_action_type IS NULL  )
					AND
						(_action_type != 'MRGDFROM' OR _action_type IS NULL)
					AND
                        TIMESTAMPDIFF(MONTH,_prev_to_trader_date,_to_trader_date) <= 1
					)
                    OR
					(
						_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_to_trader_date 		<= _to_trader_date
					AND
						_prev_orig_order_id			>= _orig_order_id 
					AND
						_prev_shares_open > _shares_open
					) 
                    )
        THEN
            SET 
			_to_trader_date = _prev_to_trader_date;
        
        END IF;
        
        
        INSERT INTO  
            temp_final_trader_start_times 
            
        SELECT
				_row_counter
              , _to_trader_date
              , _first_fill_date
              , _last_fill_date
              , _orig_target_qty
              , _shares_open
              , _orig_order_id
              , _order_id
              , _action_type
              , _usr_class_cd_2
              , _trader_name
              , _order_type
			  , _sec_id
              , _side
			  , IF((_prev_orig_target_qty	>= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_to_trader_date 		>= _to_trader_date)
                    OR
                    (_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_to_trader_date 		<= _to_trader_date
					AND
						_prev_orig_order_id			<= _orig_order_id
					AND
						_prev_order_id >= _order_id)
					OR
					(
						_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_first_fill_date 		= _first_fill_date
					AND
						_prev_shares_open			= _shares_open
					AND 
						_prev_usr_class_cd_2		= _usr_class_cd_2
                    )
                    OR
                    (_prev_orig_target_qty	= _orig_target_qty 
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND 
						_prev_first_fill_date 		= _first_fill_date
					AND 
						(_action_type IS NULL OR _action_type NOT IN ('SPLITFROM','MRGDFROM'))
					OR
					(
						_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND
						(_prev_action_type			!= _action_type OR 
							_prev_action_type IS NULL  )
					AND
						(_action_type != 'MRGDFROM' OR _action_type IS NULL)
					AND
                        TIMESTAMPDIFF(MONTH,_prev_to_trader_date,_to_trader_date) <= 1
					) 
                    OR
					(
						_prev_orig_target_qty	= _orig_target_qty 
					AND 
						_prev_side 					= _side 
					AND 
						_prev_sec_id    			= _sec_id
					AND
						_prev_trader_name          	= _trader_name
					AND
						_prev_order_type          	= _order_type
					AND 
						_prev_to_trader_date 		<= _to_trader_date
					AND
						_prev_orig_order_id			>= _orig_order_id 
					AND
						_prev_shares_open > _shares_open
					) 
                        )
                        ,'NO','YES'); 
         
         SET _prev_orig_target_qty =_orig_target_qty;
         SET _prev_side =_side;
         SET _prev_sec_id =_sec_id;
         SET _prev_trader_name =_trader_name;
         SET _prev_order_type = _order_type;
         SET _prev_to_trader_date =_to_trader_date;
         SET _prev_orig_order_id = _orig_order_id;
         SET _prev_order_id = _order_id;
         SET _prev_action_type = _action_type;
         SET _prev_shares_open = _shares_open;
         SET _prev_first_fill_date = _first_fill_date; 
		 SET _prev_usr_class_cd_2 = _usr_class_cd_2; 

    UNTIL done END REPEAT;
  END;

