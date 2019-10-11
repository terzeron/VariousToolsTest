#include <stdio.h>

EXEC SQL include sqlca;

int main(int argc, char *argv[])
{
  EXEC SQL begin declare section;
  char dbname[19];
  EXEC SQL end declare section;

  printf("Enter name of database : ");
  gets(dbname);

  EXEC SQL database :dbname;
  
  if (SQLCODE == 0)
    printf("Database %s is now open.\n", dbname);
  else
    printf("Error %ld opening database\n", SQLCODE);
  
  exit(0);
}
