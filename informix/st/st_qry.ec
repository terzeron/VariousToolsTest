#include <stdio.h>
#include "stock.h"

EXEC SQL include sqlca;
EXEC SQL include sqltypes;
EXEC SQL include decimal;

EXEC SQL begin declare section;
EXEC SQL include "table.h";
EXEC SQL end declare section;

#define nullchar(a) (risnull(CCHARTYPE,a) ? "<null>" : a)

static int open;

int stock_opn(void);
int stock_qry(stock_t *stp);
void static close_cur(void);
int stock_fet(stock_t *stp, int dir);
void stock_dsp(stock_t *dsp);


int stock_opn(void)
{
  return(open);
}


int stock_qry(stp)
     EXEC SQL begin declare section;
     stock_t *stp;
     EXEC SQL end declare section;
{
  int ret;

  EXEC SQL declare st_cur scroll cursor for select * from stock;
  sqlfatal();
  
  if (open) 
    close_cur();

  EXEC SQL open st_cur;
  sqlfatal();

  open = 1;
  
  ret = stock_fet(stp, 1);
  if (ret == -1)
    close_cur();
  return ret;
}


void static close_cur(void)
{
  EXEC SQL close st_cur;
  sqlfatal();
  open = 0;
}


int stock_fet(stp, dir)
     EXEC SQL begin declare section;
     parameter stock_t *stp;
     int dir;
     EXEC SQL end declare section;
{
  EXEC SQL fetch relative :dir st_cur into 
    :stp->stock_num, 
    :stp->manu_code, 
    :stp->description, 
    :stp->unit_price,
    :stp->unit,
    :stp->unit_descr;
    
  if (SQLCODE < 0)
    sqlfatal();
  if (SQLCODE == SQLNOTFOUND) 
    return -1;
  return 0;
}


void stock_dsp(stock_t *stp)
{
  char tmp[20];

  printf("\n");
  printf("Stock number: ");
  if (risnull(CINTTYPE, (char *) &stp->stock_num))
    printf("<null>\n");
  else
    printf("%d\n", stp->stock_num);

  printf("Manufactor code: %s\n", nullchar(stp->manu_code));
  printf("Description: %s\n", nullchar(stp->description));

  printf("Unit price: ");
  if (risnull(CINTTYPE, (char *) &stp->unit_price))
    printf("<null>\n");
  else {
    dectoasc(&stp->unit_price, tmp, sizeof(tmp), 2);
    tmp[19] = '\0';
    printf("%s\n", tmp);
  }

  printf("Unit: %s\n", nullchar(stp->unit));
  printf("Unit Description: %s\n", nullchar(stp->unit));
  printf("\n");
}


