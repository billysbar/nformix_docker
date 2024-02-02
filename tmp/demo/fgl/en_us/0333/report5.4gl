DATABASE stores

MAIN

	DEFINE p_stock RECORD LIKE stock.*

	DECLARE q_curs CURSOR FOR
		SELECT stock_num, manu_code,
			description, unit, unit_price
		FROM stock

	START REPORT qty_rep

	FOREACH q_curs INTO p_stock.stock_num, 
				p_stock.manu_code,
				p_stock.description,
				p_stock.unit,
				p_stock.unit_price

		OUTPUT TO REPORT qty_rep (p_stock.stock_num,
						p_stock.manu_code,
						p_stock.description,
						p_stock.unit,
						p_stock.unit_price)

	END FOREACH

	FINISH REPORT qty_rep

END MAIN
		
				

REPORT qty_rep (stock_num, manu_code, description, unit, unit_price)

	DEFINE stock_num	LIKE stock.stock_num,
		manu_code	LIKE stock.manu_code,
		description	LIKE stock.description,
		unit	LIKE stock.unit,
		unit_price	LIKE stock.unit_price


	FORMAT
		PAGE HEADER
			PRINT "Stock Number",
				column 15, "Manufacturer",
				column 30, "Description",
				column 50, "Unit",
				column 57, "New Unit Price"
			SKIP 2 lines

		ON EVERY ROW
			PRINT stock_num,
				column 15, manu_code,
				column 30, description,
				column 50, unit,
				column 57, unit_price * 1.15 USING "$$$$$.$$"


END REPORT
