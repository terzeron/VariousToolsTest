typedef struct anyclass {
  char name[20];
  char professor[20];
  int point;
  char time[30];
  int max_capacity;
  int present_size;
  int open;
  char dept_name[20];
} class_t;

typedef struct anystudent {
  char number[20];
  char name[20];
  int class_year;
  int total_point;
  int present_point;
  char dept_name[20];
} student_t;

typedef struct anydepartment {
  char name[20];
  char college[20];
} dept_t;



