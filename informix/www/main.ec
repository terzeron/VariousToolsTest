#include <stdio.h>
#include "register.h"

EXEC SQL include sqlca;

int main(int argc, char *argv[]);
void show_header(char *argv[]);
int sqlfatal_loc(char *f, int ln);
int chop(char *string);

int main(int argc, char *argv[])
{
  int i;
  EXEC SQL begin declare section;
  char dbname[19] = "terzeron";
  char id[10] = "terzeron";
  char passwd[10] = "0mvaldhf";
  EXEC SQL end declare section;
  
  EXEC SQL connect to "@cs_shm" user:id using:passwd;
  EXEC SQL database :dbname;
  sqlfatal();

  show_header(argv);

  /*
  for (i = 0; i < argc; i++) {
    printf("%d %s<br>\n", i, argv[i]);
  }
  */

  if (!strcmp(argv[1], "1")) {
    /* register */
    show_lecture(argv[2], argv[3]);
  } else if (!strcmp(argv[1], "2")) {
    /* timetable */
    timetable(argv[2], argv[3]);
  } else if (!strcmp(argv[1], "3")) {
    /* classinfo */
    classinfo(argv[2], argv[3], argv[4], argv[5], argv[6]);
  } else if (!strcmp(argv[1], "4")) {
    /* status */
    status(argv[2]);
  } else if (!strcmp(argv[1], "5")) {
    /* insert lecture */
    insert_lecture(argv[2], argv[3]);
  } else if (!strcmp(argv[1], "6")) {
    /* delete lecture */
    delete_lecture(argv[2], argv[3]);
  } else if (!strcmp(argv[1], "7")) {
    /* update lecture */
    update_lecture(argv[2], argv[3], argv[4]);
  }

  return 0;
}

void show_header(char *argv[])
{
  printf("<script language=javascript>\n");
  printf("menu1 = new Image();\n");
  printf("menu2 = new Image();\n");
  printf("menu3 = new Image();\n");
  printf("menu4 = new Image();\n");
  printf("menu1i = new Image();\n");
  printf("menu2i = new Image();\n");
  printf("menu3i = new Image();\n");
  printf("menu4i = new Image();\n");
  printf("menu1.src = \"register.gif\";\n");
  printf("menu2.src = \"timetable.gif\";\n");
  printf("menu3.src = \"classinfo.gif\";\n");
  printf("menu4.src = \"status.gif\";\n");
  printf("menu1i.src = \"register-i.gif\";\n");
  printf("menu2i.src = \"timetable-i.gif\";\n");
  printf("menu3i.src = \"classinfo-i.gif\";\n");
  printf("menu4i.src = \"status-i.gif\";\n");
  printf("</script>\n");
  printf("<p>&nbsp</p>\n");
  printf("<center>\n");
  printf("<table border=0>\n");
  printf("<tr>\n");
  printf("<td><a href=menu1.html onMouseOver=\"menu1.src=menu1i.src;window.status='수강신청';return true\" onMouseOut=\"menu1.src='register.gif'\"><img name=menu1 src=register.gif border=0></a></td>\n");
  printf("<td><p>&nbsp</p></td>\n");
  printf("<td><a href=menu2.html onMouseOver=\"menu2.src=menu2i.src;window.status='시간표';return true\" onMouseOut=\"menu2.src='timetable.gif'\"><img name=menu2 src=timetable.gif border=0></a></td>\n", argv[2]);
  printf("<td><p>&nbsp</p></td>\n");
  printf("<td><a href=menu3.html onMouseOver=\"menu3.src=menu3i.src;window.status='개설과목조회';return true\" onMouseOut=\"menu3.src='classinfo.gif'\"><img name=menu3 src=classinfo.gif border=0></a></td>\n");
  printf("<td><p>&nbsp</p></td>\n");
  printf("<td><a href=menu4.html onMouseOver=\"menu4.src=menu4i.src;window.status='신청현황조회';return true\" onMouseOut=\"menu4.src='status.gif'\"><img name=menu4 src=status.gif border=0></a></td>\n");
  printf("</tr>\n");
  printf("</table>\n");
  printf("</center>\n");
  printf("&nbsp\n");
  printf("<hr width=80%%>\n");
  printf("&nbsp\n");
  printf("<center>\n");
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


int chop(char *string)
{
  int i;

  if (string[0] == '\0' || string == NULL)
    return -1;

  for (i = 0; i < strlen(string); i++) {
    if (isspace(string[i])) {
      string[i] = '\0';
      break;
    }
  }
  
  return 0;
}
