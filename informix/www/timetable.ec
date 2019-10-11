#include <stdio.h>
#include <string.h>
#include "register.h"

EXEC SQL include sqlca;
EXEC SQL begin declare section;
EXEC SQL include "entity.h";
EXEC SQL end declare section;

int timetable(char student_name[], char student_number[]);
int check_time(char student_number[], class_t *newclass, class_t *oldclass);
int lexer(char timeset[], char class_name[]);

char time_table[10][6][20];

int timetable(student_number, student_name)
     EXEC SQL begin declare section;
     char student_number[];
     char student_name[];
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  class_t class;
  student_t student;
  EXEC SQL end declare section;
  int i, j;

  /* initialization */
  for (i = 0; i < 10; i++) {
    for (j = 0; j < 6; j++) {
      strcpy(time_table[i][j], "");
    }
  }

  EXEC SQL declare timecursor cursor for 
    select student.number, student.name, student.class_year, student.total_point, student.present_point, student.dept_name, class.name, class.professor, class.point, class.time, class.max_capacity, class.present_size, class.open, class.dept_name from lecture, class, student where lecture.student_number = student.number and lecture.class_name = class.name and student.number = :student_number;

  EXEC SQL open timecursor;
  
  while (SQLCODE == 0) {
    EXEC SQL fetch next timecursor into :student.number, :student.name, :student.class_year, :student.total_point, :student.present_point, :student.dept_name, :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :class.dept_name;
    
    if (SQLCODE != 0) 
      break;

    /* make time table */
    lexer(class.time, class.name);
  }
  if (SQLCODE != SQLNOTFOUND)
    sqlfatal();

  chop(student.name);
  chop(student.number);

  /* display time table */
  printf("<font color=green>%s %s의 시간표</font><p>&nbsp</p>\n", student.dept_name, student.name);
  printf("<table border=1>\n");
  printf("<tr><td bgcolor=#d0d0d0 align=center width=15%%>&nbsp</td>\n");
  printf("<td bgcolor=#d0d0d0 align=center width=15%%><font size=-3>월</font></td>\n");
  printf("<td bgcolor=#d0d0d0 align=center width=15%%><font size=-3>화</font></td>\n");
  printf("<td bgcolor=#d0d0d0 align=center width=15%%><font size=-3>수</font></td>\n");
  printf("<td bgcolor=#d0d0d0 align=center width=15%%><font size=-3>목</font></td>\n");
  printf("<td bgcolor=#d0d0d0 align=center width=15%%><font size=-3>금</font></td>\n");
  printf("<td bgcolor=#d0d0d0 align=center width=15%%><font size=-3>토</font></td>\n");
  printf("</tr>\n");

  for (i = 0; i < 10; i++) {
    printf("<tr>\n<td bgcolor=#d0d0d0 align=center><font size=-3>%d교시</font></td>", i+1);
    for (j = 0; j < 6; j++) {
      if (strcmp(time_table[i][j], "")) {
	printf("<td align=center bgcolor=antiquewhite><font size=-3><a href=register.cgi?service=classinfo&select=class&class=%s>%s</a></font></td>\n", time_table[i][j], time_table[i][j]); 
      } else {
	printf("<td>&nbsp</td>\n");
      }
    }
    printf("</tr>\n");
  }
  printf("</table>\n");
  printf("<p>&nbsp</p>\n");
	 
  printf("<form action=register.cgi method=post>\n");
  printf("<input type=hidden name=service value=register>\n");
  printf("<input type=hidden name=number value=\"%s\">\n", student.number);
  printf("<input type=hidden name=name value=\"%s\">\n", student.name);
  printf("<input type=submit value=\"수강신청페이지로 되돌아가기\">\n");
  printf("</center><body></html>\n");
  
  EXEC SQL close timecursor;
  EXEC SQL free timecursor;

  return 0;
}


int check_time(student_number, newclass, oldclass)
     EXEC SQL begin declare section;
     parameter char student_number[];
     class_t *oldclass;
     class_t *newclass;
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  class_t class;
  EXEC SQL end declare section;

  EXEC SQL declare ti_cursor cursor for
    select class.name, class.time into :class.name, :class.time from class, student, lecture where lecture.student_number = student.number and lecture.class_name = class.name and student.number = :student_number;
  EXEC SQL open ti_cursor;
  
  while (SQLCODE == 0) {
    EXEC SQL fetch ti_cursor;
    if (SQLCODE != 0)
      break;
    
    if (oldclass != NULL && !strcmp(oldclass->name, class.name))
      continue;
    
    /* make timetable on present schedule */
    lexer(class.time, class.name);
  }
  if (SQLCODE != SQLNOTFOUND) 
    sqlfatal();

  /* compare present schedule with new class */
  if (lexer(newclass->time, newclass->name) < 0)
    return -1;

  EXEC SQL close ti_cursor;
  EXEC SQL free ti_cursor;
  
  return 0;
}
  

int lexer(char timeset[], char class_name[])
{
  int i = 4, ret;
  int time1, time2;

  if (timeset == NULL || timeset[0] == '\0')
    return -1;
  
  for (i = 4; i < strlen(timeset); i++) {
    ret = sscanf(&timeset[i], "%1d%2d", &time2, &time1);
    if (ret < 0)
      break;
    if (strcmp(time_table[time1-1][time2-1], ""))
      return -1;
    else {
      strcpy(time_table[time1-1][time2-1], class_name);
      while (timeset[i] != ',' && timeset[i] != '\0')
	i++;
    }
  }

  return 0;
}


