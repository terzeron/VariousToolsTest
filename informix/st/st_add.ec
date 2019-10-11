#include <stdio.h>
#include "stock.h"

EXEC SQL include sqlca;
EXEC SQL begin declare section;
EXEC SQL include "table.h";
EXEC SQL end declare section;

void stock_inp(stock_t *recp, int inputpk);
void stock_ins(stock_t *recp);
int manufact_exist(char *manu_code);


void stock_inp(stock_t *recp, int inputpk)
{
  char s[80];
  int ret;

  if (inputpk) {
    printf("Stock number: ");
    gets(s);
    
    while (1) {
      printf("Manufacturer Code: ");
      gets(recp->manu_code);
      if (0 == manufact_exist(recp->manu_code))
	break;
      printf("\nInvalid code\n");
    }
    
    printf("Description: ");
    gets(recp->description);
    printf("Unit price: ");
    gets(s);
    rstod(s, &recp->unit_price);
    
    printf("Unit: "); 
    gets(recp->unit);
    printf("Unit Description: ");
    gets(recp->unit_descr);
  }
}  

void stock_ins(recp)
     EXEC SQL begin declare section;
     stock_t *recp;
     EXEC SQL end declare section;
{
  EXEC SQL insert into stock(stock_num, manu_code, description, unit_price, unit, unit_descr) values (:recp->stock_num, :recp->manu_code, :recp->description, :recp->unit_price, :recp->unit, :recp->unit_descr);

  sqlfatal();
}


int manufact_exist(manu_code)
     EXEC SQL begin declare section;
     char *manu_code;
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  stock_t tmp;
  EXEC SQL end declare section;
  
  EXEC SQL select manu_code into :tmp.manu_code from manufact where manu_code = :manu_code;
  
  if (SQLCODE) 
    return -1;
  return 0;
}






