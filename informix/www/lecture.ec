#include <stdio.h>
#include "register.h"

EXEC SQL include sqlca;
EXEC SQL begin declare section;
EXEC SQL include "entity.h";
EXEC SQL end declare section;

int show_lecture(char student_number[], char student_name[]);
int insert_lecture(char student_number[], char class_name[]);
int delete_lecture(char student_number[], char class_name[]);
int update_lecture(char student_number[], char oldclass[], char newclass[]);
int show_tail(student_t *student, class_t *class);
int fetch_cur(class_t *class);
int open_cur(char student_number[]);
void close_cur(void);

static int open = 0;
char time_table[10][6][20];

int show_lecture(student_number, student_name)
     EXEC SQL begin declare section;
     char student_number[];
     char student_name[];
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  class_t class;
  student_t student;
  EXEC SQL end declare section;

  EXEC SQL select number, name, class_year, total_point, present_point, dept_name into :student.number, :student.name, :student.class_year, :student.total_point, :student.present_point, :student.dept_name from student where number = :student_number and name = :student_name;
  if (SQLCODE == SQLNOTFOUND) {
    printf("등록되어 있지 않은 학생입니다.<br>\n");
    printf("</center></body></html>\n");
  }
  sqlfatal();

  open_cur(student_number);

  show_tail(&student, &class);
  
  return 0;
}


int insert_lecture(student_number, class_name)
     EXEC SQL begin declare section;
     parameter char student_number[];
     char class_name[];
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  class_t class;
  student_t student;
  EXEC SQL end declare section;

  EXEC SQL select number, name, class_year, total_point, present_point, dept_name into :student.number, :student.name, :student.class_year, :student.total_point, :student.present_point, :student.dept_name from student where :student_number = number;
  if (SQLCODE == SQLNOTFOUND) {
    printf("<font color=red>\"%s\"는 등록되어 있지 않은 학생입니다.</font><br>\n", student_number);
  } else {
    EXEC SQL select name, professor, point, time, max_capacity, present_size, open, dept_name into :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :class.dept_name from class where name = :class_name;
    if (SQLCODE == SQLNOTFOUND) {
      printf("<font color=red>\"%s\"는 등록되어 있지 않은 과목입니다.<br>\n", class_name);
      printf("과목이 선택되어 있지 않은지 확인하시기 바랍니다.</font><br>\n");
    } else {
      if (student.present_point + class.point > student.total_point) {
	printf("<font color=red>수강학점을 초과하였습니다.</font><br>\n");
      } else {
	if (class.max_capacity != 0 && 
	    class.present_size + 1 > class.max_capacity) {
	  printf("<font color=red>수강정원을 초과하였습니다.</font><br>\n");
	} else {
	  if (class.open == 0 && strcmp(student.dept_name, class.dept_name)) {
	    printf("<font color=red>타과생 수강이 가능하지 않은 과목입니다.</font><br>\n");
	  } else {
	    if (check_time(student_number, &class, (class_t *) NULL) < 0) {
	      printf("<font color=red>수업시간이 중복되는 과목입니다.</font><br>\n");
	    } else {
	      EXEC SQL begin work;
	      EXEC SQL insert into lecture values (:student_number, :class_name);
	      if (SQLCODE)
		EXEC SQL rollback work;
	      
	      EXEC SQL update student set (present_point) = (present_point + :class.point) where number = :student_number;
	      if (SQLCODE)
		EXEC SQL rollback work;
	      student.present_point += class.point;
	      
	      EXEC SQL update class set (present_size) = (present_size + 1) where name = :class.name;
	      if (SQLCODE)
		EXEC SQL rollback work;
	      class.present_size ++;
	      EXEC SQL commit work;
	    }
	  }
	}
      }
    }
  }

  open_cur(student_number);

  show_tail(&student, &class);

  return 0;
}


int delete_lecture(student_number, class_name)
     EXEC SQL begin declare section;
     parameter char student_number[];
     char class_name[];
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  class_t class;
  student_t student;
  EXEC SQL end declare section;

  EXEC SQL select number, name, class_year, total_point, present_point, dept_name into :student.number, :student.name, :student.class_year, :student.total_point, :student.present_point, :student.dept_name from student where :student_number = number;
  if (SQLCODE == SQLNOTFOUND) {
    printf("<font color=red>\"%s\"는 등록되어 있지 않은 학생입니다.</font><br>\n", student_number);
  } else {
    EXEC SQL select class.name, professor, point, time, max_capacity, present_size, open, class.dept_name into :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :class.dept_name from class, lecture where lecture.class_name = class.name and class.name = :class_name and lecture.student_number = :student_number;
    if (SQLCODE == SQLNOTFOUND) {
      printf("<font color=red>\"%s\"는 등록되어 있지 않은 과목입니다.<br>\n", class_name);
      printf("과목이 선택되어 있지 않은지 확인하시기 바랍니다.</font><br>\n");
    } else {
      if (student.present_point - class.point >= 0) {
	if (class.present_size-1 >= 0) {
	  EXEC SQL begin work;
	  EXEC SQL delete from lecture where student_number = :student_number and  class_name = :class_name;
	  if (SQLCODE) 
	    EXEC SQL rollback work;
	  
	  EXEC SQL update student set (present_point) = (present_point - :class.point) where number = :student_number;
	  if (SQLCODE) 
	    EXEC SQL rollback work;
	  student.present_point -= class.point;
	  
	  EXEC SQL update class set (present_size) = (present_size - 1) where name = :class.name;
	  if (SQLCODE)
	    EXEC SQL rollback work;
	  class.present_size --;
	  EXEC SQL commit work;
	}
      }
    }
  }

  open_cur(student_number);

  show_tail(&student, &class);

  return 0;
}


int update_lecture(student_number, oldclass_name, newclass_name)
     EXEC SQL begin declare section;
     parameter char student_number[];
     char oldclass_name[];
     char newclass_name[];
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  class_t oldclass;
  class_t newclass;
  student_t student;
  EXEC SQL end declare section;

  /* 학생의 정보를 체크 */
  EXEC SQL select number, name, class_year, total_point, present_point, dept_name into :student.number, :student.name, :student.class_year, :student.total_point, :student.present_point, :student.dept_name from student where :student_number = number;
  if (SQLCODE == SQLNOTFOUND) {
    printf("<font color=red>\"%s\"는 등록되어 있지 않은 학생입니다.</font><br>\n", student_number);
  } else {
    /* 학생이 수강 신청을 해 놓은 과목인지 체크 */
    EXEC SQL select name, professor, point, time, max_capacity, present_size, open, dept_name into :oldclass.name, :oldclass.professor, :oldclass.point, :oldclass.time, :oldclass.max_capacity, :oldclass.present_size, :oldclass.open, :oldclass.dept_name from class, lecture where lecture.class_name = name and name = :oldclass_name and lecture.student_number = :student_number;
    if (SQLCODE == SQLNOTFOUND) {
      printf("<font color=red>\"%s\"는 신청되어 있지 않은 과목입니다.<br>\n", oldclass_name);
      printf("과목이 선택되어 있지 않은지 확인하시기 바랍니다.</font><br>\n");
    } else {
      /* 학생이 새로 신청하려는 과목이 등록되어 있는 과목인지 체크 */
      EXEC SQL select name, professor, point, time, max_capacity, present_size, open, dept_name into :newclass.name, :newclass.professor, :newclass.point, :newclass.time, :newclass.max_capacity, :newclass.present_size, :newclass.open, :newclass.dept_name from class where name = :newclass_name;
      if (SQLCODE == SQLNOTFOUND) {
	printf("<font color=red>\"%s\"는 등록되어 있지 않은 과목입니다.<br>\n", newclass_name);
	printf("과목이 선택되어 있지 않은지 확인하시기 바랍니다.</font><br>\n");
      } else {
	if (student.present_point - oldclass.point +  newclass.point 
	    > student.total_point) {
	  printf("<font color=red>수강학점을 초과하였습니다.</font><br>\n");
	} else if (student.present_point - oldclass.point+newclass.point 
		   >= 0) {
	  if (newclass.max_capacity != 0 && newclass.present_size + 1 
	      > newclass.max_capacity) {
	    printf("<font color=red>수강정원을 초과하였습니다.</font><br>\n");
	  } else if (oldclass.present_size - 1 >= 0) {
	    if (newclass.open == 0 
		&& strcmp(student.dept_name, newclass.dept_name)) {
	      printf("<font color=red>타과생 수강이 가능하지 않은 과목입니다.</font><br>\n");
	    } else {
	      if (check_time(student_number, &newclass, &oldclass) < 0) {
		printf("<font color=red>수업시간이 중복되는 과목입니다.</font><br>\n");
	      } else {
		EXEC SQL begin work;
		EXEC SQL update lecture set (student_number, class_name) = (:student_number, :newclass.name) where student_number = :student_number and class_name = :oldclass.name;
		if (SQLCODE) 
		  EXEC SQL rollback work;
		
		EXEC SQL update student set (present_point) = (present_point - :oldclass.point + :newclass.point) where number = :student_number;
		if (SQLCODE)
		  EXEC SQL rollback work;
		student.present_point = student.present_point - oldclass.point + newclass.point;
		
		EXEC SQL update class set (present_size) = (present_size + 1) where name = :newclass.name;
		if (SQLCODE)
		  EXEC SQL rollback work;
		EXEC SQL update class set (present_size) = (present_size - 1) where name = :oldclass.name;
		if (SQLCODE)
		  EXEC SQL rollback work;
		EXEC SQL commit work;
	      }
	    }
	  }
	}
      }
    }
  }

  open_cur(student_number);

  show_tail(&student, &newclass);

  return 0;
}


int show_tail(student, class)
     EXEC SQL begin declare section;
     student_t *student;
     class_t *class;
     EXEC SQL end declare section;
{
  int count = 0;
  EXEC SQL begin declare section;
  dept_t dept;
  EXEC SQL end declare section;

  EXEC SQL select name, college into :dept.name, :dept.college from department where name = :student->dept_name;
  sqlfatal();

  chop(dept.college);
  chop(dept.name);
  chop(student->number);
  chop(student->name);
  printf("<form action=register.cgi method=post>\n");
  printf("<input type=hidden name=service value=register>\n");
  printf("<input type=hidden name=number value=%s>\n", student->number);
  printf("<table border=0 width=80%%>\n");
  printf("<caption><font color=green>수강신청</font></caption>\n");
  printf("<tr><td colspan=8>&nbsp</td></tr>\n");

  printf("<tr align=center>\n");
  printf("<td colspan=2 bgcolor=antiquewhite>%s</td>\n", dept.college);
  printf("<td colspan=2 bgcolor=antiquewhite>%s</td>\n", dept.name);
  printf("<td colspan=2 bgcolor=antiquewhite>%s</td>\n", student->number);
  printf("<td colspan=1 bgcolor=antiquewhite>%d학년</td>\n", student->class_year);
  printf("<td colspan=1 bgcolor=antiquewhite>%s</td>\n", student->name);

  printf("</tr>\n");
  printf("<td colspan=5 align=center nowrap>총 %d학점 중 %d학점 추가신청 가능</td>\n", student->total_point, student->total_point - student->present_point);
  printf("<td><input type=radio name=act value=insert checked>추가</td>\n");
  printf("<td><input type=radio name=act value=delete>삭제</td>\n");
  printf("<td><input type=radio name=act value=update>수정</td>\n");
  printf("</tr>\n");
  printf("</table>\n");

  printf("<table border=1 width=80%%>\n");
  printf("<tr>\n");
  printf("<td align=center bgcolor=#d0d0d0>&nbsp</td>\n");
  printf("<td align=center bgcolor=#d0d0d0>과목</td>\n");
  printf("<td align=center bgcolor=#d0d0d0>교수</td>\n");
  printf("<td align=center bgcolor=#d0d0d0>학점</td>\n");
  printf("<td align=center bgcolor=#d0d0d0>개설학과</td>\n");
  printf("<td align=center bgcolor=#d0d0d0>신청인원</td></tr>\n");

  while (fetch_cur(class) >=0) {
    chop(class->name);
    chop(class->professor);
    chop(class->dept_name);
    printf("<tr>\n");
    printf("<td align=center><input type=radio name=class value=%s></td>\n", class->name);
    printf("<td align=center><a href=register.cgi?service=classinfo&select=class&class=%s>%s</a></td>\n", class->name, class->name);
    printf("<td align=center><a href=register.cgi?service=classinfo&select=prof&prof=%s>%s</a></td>\n", class->professor, class->professor);
    printf("<td align=center>%d</td>\n", class->point);
    printf("<td align=center><a href=register.cgi?service=classinfo&select=dept&dept=%s>%s</a></td>\n", class->dept_name, class->dept_name);
    if (class->max_capacity == 0) {
      printf("<td align=center>%d / ?</td></tr>\n", class->present_size);
    } else {
      printf("<td align=center>%d / %d</td></tr>\n", class->present_size, class->max_capacity);
    }
    printf("</tr>\n");
    count++;
  }
  if (count == 0) {
    printf("<tr><td align=center colspan=6><font color=blue>어떤 과목도 신청되어 있지 않습니다.</blue></td></tr>\n");
  }

  close_cur();

  /* for insertion of new registration */
  printf("<tr>\n");
  printf("<td align=center colspan=2>신청과목</td>\n");
  printf("<td align=center colspan=4><input type=text name=newclass value=\"\"></td>\n");
  printf("</tr>\n");

  printf("</table>\n");
  printf("<p>&nbsp</p>\n");
  printf("<input type=submit value=\"입력완료\">\n");
  printf("<input type=reset value=\"입력취소\">\n");
  printf("</form>\n");

  chop(student->number);
  chop(student->name);
  printf("<form action=register.cgi method=post>\n");
  printf("<input type=hidden name=service value=timetable>\n");
  printf("<input type=hidden name=number value=\"%s\">\n", student->number);
  printf("<input type=hidden name=name value=\"%s\">\n", student->name);
  printf("<input type=submit value=\"시간표 확인하기\">\n");
  printf("</form>\n");
  printf("<form action=register.cgi method=post>\n");
  printf("<input type=hidden name=service value=register>\n");
  printf("<input type=hidden name=number value=\"%s\">\n", student->number);
  printf("<input type=hidden name=name value=\"%s\">\n", student->name);
  printf("<input type=submit value=\"화면 정리하기\">\n");
  printf("</form>\n");
  printf("</center><body></html>\n");

  return 0;
}


int fetch_cur(class)
     EXEC SQL begin declare section;
     parameter class_t *class;
     EXEC SQL end declare section;
{
  EXEC SQL fetch next mycursor into :class->name, :class->professor, :class->point, :class->time, :class->max_capacity, :class->present_size, :class->open, :class->dept_name;
  
  if (SQLCODE < 0)
    sqlfatal();
  if (SQLCODE == SQLNOTFOUND) 
    return -1;
  return 0;
}


int open_cur(student_number) 
     EXEC SQL begin declare section;
     parameter char student_number[];
     EXEC SQL end declare section;
{
  EXEC SQL declare mycursor cursor for 
    select class.name, class.professor, class.point, class.time, class.max_capacity, class.present_size, class.open, class.dept_name from lecture, class, student where lecture.class_name = class.name and lecture.student_number = student.number and student.number = :student_number;
  if (open)
    close_cur();
  
  EXEC SQL open mycursor;
  sqlfatal();

  open = 1;
  return 1;
}


void close_cur(void)
{
  EXEC SQL close mycursor;
  EXEC SQL free mycursor;
  sqlfatal();
  open = 0;
}

