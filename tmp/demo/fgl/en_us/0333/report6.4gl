DATABASE stores

MAIN

	DEFINE p_items RECORD LIKE items.*,
		p_stock RECORD LIKE stock.*

	DECLARE q_curs CURSOR FOR
		SELECT items.stock_num, items.manu_code,
			quantity, description, unit
		FROM items, stock
		WHERE items.stock_num = stock.stock_num
			AND items.manu_code = stock.manu_code
			AND items.stock_num = 5

	START REPORT qty_rep2

	FOREACH q_curs INTO p_items.stock_num, 
				p_items.manu_code,
				p_items.quantity,
				p_stock.description,
				p_stock.unit

		OUTPUT TO REPORT qty_rep2 (p_items.stock_num,
						p_items.manu_code,
						p_items.quantity,
						p_stock.description,
						p_stock.unit)

	END FOREACH

	FINISH REPORT qty_rep2

END MAIN
		
				

REPORT qty_rep2 (stock_num, manu_code, quantity, description, unit)

	DEFINE stock_num	LIKE items.stock_num,
		manu_code	LIKE items.manu_code,
		quantity	LIKE items.quantity,
		description	LIKE stock.description,
		unit	LIKE stock.unit

	ORDER BY stock_num

	FORMAT
		PAGE HEADER
			PRINT "Stock Number",
				COLUMN 15, "Manufacturer",
				COLUMN 30, "Description",
				COLUMN 50, "Unit",
				COLUMN 60, "Quantity"
			SKIP 2 LINES

		ON EVERY ROW
			PRINT stock_num,
				COLUMN 15, manu_code,
				COLUMN 30, description,
				COLUMN 50, unit,
				COLUMN 60, quantity

		ON LAST ROW
			SKIP 1 LINE
			PRINT COLUMN 20, "Total Quantity on Order: ",
				COLUMN 55, SUM(quantity) USING "###"
			SKIP 2 LINES
			PRINT COLUMN 20, "Total Number of Orders: ",
				COLUMN 55, COUNT(*) USING "###"

END REPORT
