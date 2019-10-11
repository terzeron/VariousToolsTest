#include <stdio.h>
#include <string.h>
#include "register.h"

EXEC SQL include sqlca;
EXEC SQL begin declare section;
EXEC SQL include "entity.h";
EXEC SQL end declare section;

#define DEFAULTSIZ 4

int status(char classname[]);
int add_college(char collegename[]);
int add_dept(char deptname[]);
int add_year(int year);

EXEC SQL begin declare section;
char **college, **dept_name;
int *yeartable;
EXEC SQL end declare section;
int num_college = 0, num_dept = 0, num_year = 0;
int max_college = 0, max_dept = 0, max_year = 0;

int status(classname) 
     EXEC SQL begin declare section;
     char classname[];
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  student_t student;
  dept_t dept;
  int present_size;
  int max_capacity;
  int cnt;
  EXEC SQL end declare section;
  int i;
  
  /* the number of students and max_capacity */
  EXEC SQL select present_size, max_capacity into :present_size, :max_capacity from class where name = :classname;
  sqlfatal();

  printf("<font color=green>%s 과목의 신청현황조회</font><br>\n", classname);
  printf("<p>\n");
  printf("현재 수강을 신청한 인원은 %d명이고, ", present_size);
  printf("인원제한은 ");
  if (max_capacity == 0) 
    printf("없습니다.<p>\n");
  else 
    printf("%d명입니다.<p>\n", max_capacity);

  if (present_size == 0) {
    printf("</center></body></html>\n");
    return 0;
  }

  EXEC SQL declare de_cursor cursor for 
    select s.class_year, d.name, d.college from student s, department d, lecture l where s.dept_name = d.name and l.student_number = s.number and l.class_name = :classname;
  EXEC SQL open de_cursor;
  sqlfatal();
  
  while (SQLCODE == 0) {
    EXEC SQL fetch de_cursor into :student.class_year, :dept.name, :dept.college;
    if (SQLCODE != 0)
      break;
    
    /* collect college and department information */
    add_dept(dept.name);
    add_college(dept.college);
    add_year(student.class_year);
  }
  if (SQLCODE != SQLNOTFOUND)
    sqlfatal();

  EXEC SQL close de_cursor;
  EXEC SQL free de_cursor;

  printf("<table border=1 width=80%%>\n");
  printf("<tr><td colspan=2 align=center bgcolor=#d0d0d0>대학별 수강신청현황</td></tr>\n");
  for (i = 0; i < num_college; i++) {
    EXEC SQL select count(student.number) into :cnt from student, lecture, department where lecture.student_number = student.number and lecture.class_name = :classname and student.dept_name = department.name and department.college = :college[i];
    sqlfatal();

    chop(college[i]);
    printf("<tr>\n");
    printf("<td cellpadding=0 align=center>%s</td>\n", college[i]);
    printf("<td cellpadding=0 align=center>%d명</td>\n", cnt);
    printf("</tr>\n");
  }
  printf("</table><p>\n");

  printf("<table border=1 width=80%%>\n");
  printf("<tr><td colspan=2 align=center bgcolor=#d0d0d0>학과별 수강신청현황</td></tr>\n");
  for (i = 0; i < num_dept; i++) {
    EXEC SQL select count(student.number) into :cnt from student, lecture where lecture.student_number = student.number and lecture.class_name = :classname and student.dept_name = :dept_name[i];
    sqlfatal();

    chop(dept_name[i]);
    printf("<tr>\n");
    printf("<td cellpadding=0 align=center>%s</td>\n", dept_name[i]);
    printf("<td cellpadding=0 align=center>%d명</td>\n", cnt);
    printf("</tr>\n");
  }
  printf("</table><p>\n");

  printf("<table border=1 width=80%%>\n");
  printf("<tr><td colspan=2 align=center bgcolor=#d0d0d0>학년별 수강신청현황</td></tr>\n");
  for (i = 0; i < num_year; i++) {
    EXEC SQL select count(student.number) into :cnt from student, lecture where lecture.student_number = student.number and lecture.class_name = :classname and student.class_year = :yeartable[i];
    sqlfatal();

    printf("<tr>\n");
    printf("<td cellpadding=0 align=center>%d학년</td>\n", yeartable[i]);
    printf("<td cellpadding=0 align=center>%d명</td>\n", cnt);
    printf("</tr>\n");
  }
  printf("</table><p>\n");

  printf("<table border=1 width=80%%>\n");
  printf("<tr><td colspan=5 align=center bgcolor=#d0d0d0>수강신청한 학생명단</td></tr>\n");
  EXEC SQL declare st_cursor cursor for 
    select student.number, student.name, student.class_year, student.total_point, student.present_point, department.name, department.college from student, lecture, department where lecture.student_number = student.number and lecture.class_name = :classname and student.dept_name = department.name;
  EXEC SQL open st_cursor;
  sqlfatal();

  while (SQLCODE == 0) {
    EXEC SQL fetch st_cursor into :student.number, :student.name, :student.class_year, :student.total_point, :student.present_point, :dept.name, :dept.college;
    if (SQLCODE != 0)
      break;
    
    chop(student.number);
    chop(student.name);
    chop(dept.college);
    chop(dept.name);
    printf("<tr>\n");
    printf("<td cellpadding=0 align=center>%s</td>\n", dept.college);
    printf("<td cellpadding=0 align=center>%s</td>\n", dept.name);
    printf("<td cellpadding=0 align=center>%d학년</td>\n", student.class_year);
    printf("<td cellpadding=0 align=center>%s</td>\n", student.number);
    printf("<td cellpadding=0 align=center><a href=register.cgi?service=register&number=%s&name=%s>%s</td>\n", student.number, student.name, student.name);
    printf("</tr>\n");
  }
  if (SQLCODE != SQLNOTFOUND)
    sqlfatal();
  printf("</table>\n");

  printf("</center></body></html>\n");
  
  return 0;	
}		


int add_college(char collegename[]) 
{
  int i;
  int found_flag = 0;
  char **tmp;

  /* search */
  for (i = 0; i < num_college; i++) {
    if (!strcmp(college[i], collegename)) {
      found_flag = 1;
      break;
    }
  }

  if (max_college == 0) {
    max_college = DEFAULTSIZ;
    college = (char **) malloc(sizeof(char *) * max_college);
    if (college == NULL) {
      printf("Error: can't allocate any more memory!<br>\n");
      return -1;
    }
    college[num_college] = (char *) malloc(sizeof(char) * 20);
    strcpy(college[num_college], collegename);
    num_college++;
    return 0;
  }
  
  if (found_flag == 0) {
    /* add */
    if (num_college >= max_college) {
      /* doubling */
      max_college += DEFAULTSIZ;
      tmp = (char **) realloc(college, sizeof(char *) * max_college);
      college = tmp;
      if (college == NULL) {
	printf("Error: can't allocate any more memory!<br>\n");
	return -1;
      }
    }
    college[num_college] = (char *) malloc(sizeof(char) * 20);
    strcpy(college[num_college], collegename);
    num_college++;
  }

  return 0;
}


int add_dept(char deptname[]) 
{
  int i;
  int found_flag = 0;
  char **tmp;

  /* search */
  for (i = 0; i < num_dept; i++) {
    if (!strcmp(dept_name[i], deptname)) {
      found_flag = 1;
      break;
    }
  }
  
  if (max_dept == 0) {
    max_dept = DEFAULTSIZ;
    dept_name = (char **) malloc(sizeof(char *) * max_dept);
    if (dept_name == NULL) {
      printf("Error: can't allocate any more memory!<br>\n");
      return -1;
    }
    dept_name[num_dept] = (char *) malloc(sizeof(char) * 20);
    strcpy(dept_name[num_dept], deptname);
    num_dept++;
    return 0;
  }
  
  if (found_flag == 0) {
    /* add */
    if (num_dept >= max_dept) {
      /* doubling */
      max_dept += DEFAULTSIZ;
      tmp = (char **) realloc(dept_name, sizeof(char *) * max_dept);
      dept_name = tmp;
      if (dept_name == NULL) {
	printf("Error: can't allocate any more memory!<br>\n");
	return -1;
      }
    }
    dept_name[num_dept] = (char *) malloc(sizeof(char) * 20);
    strcpy(dept_name[num_dept], deptname);
    num_dept++;
  }

  return 0;
}


int add_year(int year) 
{
  int i;
  int found_flag = 0;
  int *tmp;

  /* search */
  for (i = 0; i < num_year; i++) {
    if (yeartable[i] == year) {
      found_flag = 1;
      break;
    }
  }
  
  if (max_year == 0) {
    max_year = DEFAULTSIZ;
    yeartable = (int *) malloc(sizeof(int) * max_year);
    if (yeartable == NULL) {
      printf("Error: can't allocate any more memory!<br>\n");
      return -1;
    }
    yeartable[num_year] = year;
    num_year++;
    return 0;
  }
  
  if (found_flag == 0) {
    /* add */
    if (num_year >= max_year) {
      /* doubling */
      max_year += DEFAULTSIZ;
      tmp = (int *) realloc(yeartable, sizeof(int) * max_year);
      yeartable = tmp;
      if (yeartable == NULL) {
	printf("Error: can't allocate any more memory!<br>\n");
	return -1;
      }
    }
    yeartable[num_year] = year;
    num_year++;
  }

  return 0;
}


