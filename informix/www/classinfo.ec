#include <stdio.h>
#include "register.h"

EXEC SQL include sqlca;
EXEC SQL begin declare section;
EXEC SQL include "entity.h";
EXEC SQL end declare section;

int classinfo(char select[], char college[], char dept[], char prof[], char class[]);
int show_head(void);
int show_body(class_t *class, dept_t *dept);
int show_end(int count);

int classinfo(select, college, deptname, prof, classname)
     char select[];
     EXEC SQL begin declare section;
     char college[], deptname[], prof[], classname[];
     EXEC SQL end declare section;
{
  EXEC SQL begin declare section;
  class_t class;
  dept_t dept;
  EXEC SQL end declare section;
  int count = 0;

  printf("<font color=green>�������� ����</font>\n");
  printf("<p>\n");
  printf("<table border=0>");
  printf("<tr><td align=center bgcolor=antiquewhite>����ũ</td><td>�� ������ ������û��Ȳ�� ��ȸ�� �� �ֽ��ϴ�.</td></tr>\n");
  printf("<tr><td align=center bgcolor=antiquewhite>���и�ũ, �а���ũ, ������ũ</td><td>�� ����� ���õ� �������� ������ ��ȸ�� �� �ֽ��ϴ�.</td></tr>\n");
  printf("</table><p>\n");

  if (!strcmp(select, "college")) {
    EXEC SQL declare co_cursor cursor for
      select class.name, professor, point, time, max_capacity, present_size, open, dept_name, department.college from class, department where department.name = class.dept_name and department.college = :college;
    EXEC SQL open co_cursor;

    show_head();
    while (SQLCODE == 0) {
      EXEC SQL fetch co_cursor into :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :dept.name, :dept.college;
      if (SQLCODE != 0)
	break;

      show_body(&class, &dept);
      count++;
    }
    show_end(count);
    EXEC SQL close co_cursor;
    EXEC SQL free co_cursor;
  } else if (!strcmp(select, "dept")) {
    EXEC SQL declare de_cursor cursor for
      select class.name, professor, point, time, max_capacity, present_size, open, dept_name, department.college from class, department where department.name = class.dept_name and department.name = :deptname;
    EXEC SQL open de_cursor;

    show_head();
    while (SQLCODE == 0) {
      EXEC SQL fetch de_cursor into :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :dept.name, :dept.college;
      if (SQLCODE != 0)
	break;

      show_body(&class, &dept);
      count++;
    }
    show_end(count);
    EXEC SQL close de_cursor;
    EXEC SQL free de_cursor;
  } else if (!strcmp(select, "prof")) {
    EXEC SQL declare pr_cursor cursor for
      select class.name, professor, point, time, max_capacity, present_size, open, dept_name, department.college from class, department where department.name = class.dept_name and class.professor = :prof;
    EXEC SQL open pr_cursor;

    show_head();
    while (SQLCODE == 0) {
      EXEC SQL fetch pr_cursor into :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :dept.name, :dept.college;
      if (SQLCODE != 0)
	break;

      show_body(&class, &dept);
      count++;
    }
    show_end(count);
    EXEC SQL close pr_cursor;
    EXEC SQL free pr_cursor;
  } else if (!strcmp(select, "class")) {
    EXEC SQL declare cl_cursor cursor for
      select class.name, professor, point, time, max_capacity, present_size, open, dept_name, department.college from class, department where department.name = class.dept_name and class.name = :classname;
    EXEC SQL open cl_cursor;

    show_head();
    while (SQLCODE == 0) {
      EXEC SQL fetch cl_cursor into :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :dept.name, :dept.college;
      if (SQLCODE != 0)
	break;

      show_body(&class, &dept);
      count++;
    }
    show_end(count);
    EXEC SQL close cl_cursor;
    EXEC SQL free cl_cursor;
  } else if (!strcmp(select, "all")) {
    EXEC SQL declare al_cursor cursor for
      select class.name, professor, point, time, max_capacity, present_size, open, dept_name, department.college from class, department where department.name = class.dept_name;
    EXEC SQL open al_cursor;

    show_head();
    while (SQLCODE == 0) {
      EXEC SQL fetch al_cursor into :class.name, :class.professor, :class.point, :class.time, :class.max_capacity, :class.present_size, :class.open, :dept.name, :dept.college;
      if (SQLCODE != 0)
	break;

      show_body(&class, &dept);
      count++;
    }
    show_end(count);
    EXEC SQL close al_cursor;
    EXEC SQL free al_cursor;
  }

  return 0;
}


int show_head(void)
{
  printf("<table border=1>\n");
  printf("<tr>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>����</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>����</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>�а�</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>����</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>����</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>�ο�����</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>��û�ο�</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>Ÿ��������</font></td>\n");
  printf("<td align=center cellpadding=0 bgcolor=#d0d0d0><font size=-2>�ð�</font></td>\n");
  printf("</tr>\n");
}


int show_body(class_t *class, dept_t *dept) 
{
  int i, ret, time1, time2;
  char week[6][3] = {"��", "ȭ", "��", "��", "��", "��"};

  chop(class->name);
  chop(dept->college);
  chop(dept->name);
  chop(class->professor);
  printf("<tr>\n");
  printf("<td align=center cellpadding=0><font size=-2><a href=register.cgi?service=status&class=%s>%s</a></font></td>\n", class->name, class->name);
  printf("<td align=center cellpadding=0><font size=-2><a href=register.cgi?service=classinfo&select=college&college=%s>%s</a></font></td>\n", dept->college, dept->college);
  printf("<td align=center cellpadding=0><font size=-2><a href=register.cgi?service=classinfo&select=dept&dept=%s>%s</a></font></td>\n", dept->name, dept->name);
  printf("<td align=center cellpadding=0><font size=-2><a href=register.cgi?service=classinfo&select=prof&prof=%s>%s</a></font></td>\n", class->professor, class->professor);
  printf("<td align=center cellpadding=0><font size=-2>%d</font></td>\n", class->point);
  if (class->max_capacity == 0) {
    printf("<td align=center cellpadding=0><font size=-2>����</font></td>\n");
  } else {
    printf("<td align=center cellpadding=0><font size=-2>%d��</font></td>\n", class->max_capacity);
  }
  printf("<td align=center cellpadding=0><font size=-2>%d��</font></td>\n", class->present_size);
  if (class->open == 0) {
    printf("<td align=center cellpadding=0><font size=-2>�Ұ���</font></td>\n", class->open);
  } else {
    printf("<td align=center cellpadding=0><font size=-2>����</font></td>\n", class->open);
  }
  printf("<td align=center cellpadding=0 nowrap><font size=-2>");
  for (i = 4; i < strlen(class->time); i++) {
    ret = sscanf(&class->time[i], "%1d%2d", &time1, &time2);
    if (ret < 0)
      break;
    printf("%s%d ", week[time1-1], time2);
    while (class->time[i] != ',' && class->time[i] != '\0')
      i++;
  }
  printf("</font></td>\n</tr>\n");
}


int show_end(int count)
{
  if (count == 0) {
    printf("<tr>");
    printf("<td colspan=9align=center><font color=red>");
    printf("���� ���� ������ ã�� �� �����ϴ�. ���и�, �а���, ������,<br> ");
    printf("������� ��Ȯ�ϰ� �Է��Ͽ����� �ٽ� Ȯ���Ͻñ� �ٶ��ϴ�.");
    printf("</font></td>\n");
    printf("</tr>");
  }

  printf("</table>\n");
  printf("</center>\n</body>\n</html>\n");
}
