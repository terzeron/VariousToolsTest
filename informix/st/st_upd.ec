#include <stdio.h>
#include "stock.h"

EXEC SQL include sqlca;
EXEC SQL include decimal;

EXEC SQL begin declare section;
EXEC SQL include "table.h";
EXEC SQL end declare section;

stock_upd(stp)
     EXEC SQL begin declare section;
     stock_t *stp;
     EXEC SQL end declare section;
{
  stock_t edit;
  stock_t orig;

  EXEC SQL select description, unit_price, unit, unit_descr 
    into :stp->description, :stp->unit_price, :stp->unit, :stp->unit_descr 
    from stock 
    where stock_num = :stp->stock_num and manu_code = :stp->manu_code;
  
  memcpy((char *) &orig, (char *) stp, sizeof(stock_t));
  memcpy((char *) &edit, (char *) stp, sizeof(stock_t));

  stock_dsp(&edit);
  stock_inp(&edit, 0);
  
  EXEC SQL declare upd_cur cursor for 
    select description, unit_price, unit, unit_descr 
	     from stock
	     where stock_num = :stp->stock_num and manu_code = :stp->manu_code
	     for update;
  sqlfatal();

  EXEC SQL open upd_cur;
  sqlfatal();

  EXEC SQL fetch upd_cur into :stp->description, :stp->unit_price, :stp->unit,
    :stp->unit_descr;
  
  if (memcmp((char *) stp, (char *) &orig, sizeof(stock_t))) {
    printf("\nRecord has changed, update aborted.\n\n");
    stock_dsp(stp);
  } else {
    memcpy((char *) stp, (char *) &edit, sizeof(stock_t));

    EXEC SQL update stock set (description, unit_price, unit, unit_descr) = 
      (:stp->description, :stp->unit_price, :stp->unit, :stp->unit_descr)
      where current of upd_cur;
    sqlfatal();
    printf("\nRecord updated.\n\n");
  }

  EXEC SQL close upd_cur;
  sqlfatal();
  
}
