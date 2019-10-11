#include <stdio.h>
#include "stock.h"

EXEC SQL include sqlca;
EXEC SQL begin declare section;
EXEC SQL include "table.h";
EXEC SQL end declare section;

int main(int argc, char *argv[]);
void stock_mnu(void);
void notyet(void);
int sqlfatal_loc(char *f, int ln);


int main(int argc, char *argv[])
{
  EXEC SQL begin declare section;
  char dbname[19];
  EXEC SQL end declare section;

  printf("Enter name of database: ");
  gets(dbname);

  EXEC SQL database :dbname;
  sqlfatal();

  stock_mnu();
  exit(0);
}

void stock_mnu(void)
{
  EXEC SQL begin declare section;
  stock_t stockrec;
  stock_t stqryrec;
  EXEC SQL end declare section;
  char s[80];

  while (1) {
    printf("Stock: A)dd D)elete E)xit N)ext P)revious U)pdate Q)uery");
    printf("\n\n> ");
    gets(s);
    
    if (s[0] == 'e')
      break;

    switch (s[0]) {
    case 'a':
      stock_inp(&stockrec);
      stock_ins(&stockrec);
      break;
    case 'u':
      if (stock_opn())
	stock_upd(&stqryrec);
      else
	printf("\nPlease query first\n\n");
      break;
    case 'd':
      notyet();
      break;
    case 'n':
    case 'p':
      if (!stock_opn()) 
	printf("\nPlease query first.\n\n");
      else {
	if (0 == stock_fet(&stqryrec, (s[0] == 'n' ? 1 : -1)))
	  stock_dsp(&stqryrec);
	else
	  printf("\nNo more rows in that direction\n\n");
      }	
      break;
    case 'q':
      if (0 == stock_qry(&stqryrec))
	stock_dsp(&stqryrec);
      break;
    }
  }
}


void notyet(void) 
{
  printf("\nNot yet implemented\n\n");
}


int sqlfatal_loc(char *f, int ln)
{
  char msg[160];
  
  if (SQLCODE) {
    fprintf(stderr, "sqlcode %ld, isam %ld, file %s, line %d\n", SQLCODE, sqlca.sqlerrd[1], f, ln);

    rgetmsg((short) sqlca.sqlcode, msg, sizeof(msg));
    fprintf(stderr, "Sql: ");
    fprintf(stderr, msg, sqlca.sqlerrm);
    
    if (sqlca.sqlerrd[1]) {
      rgetmsg((short) (sqlca.sqlerrd[1]), msg, sizeof(msg));
      fprintf(stderr, "%s", msg);
    }
    exit(1);
  }
}

