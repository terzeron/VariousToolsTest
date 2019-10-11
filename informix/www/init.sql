create table department (
  name char(20) primary key,
  college char(20) not null);

create table student (
  number char(20) primary key,
  name char(10) not null, 
  class_year smallint not null, 
  total_point smallint not null,
  present_point smallint not null,
  dept_name char(20) references department(name));

create table class (
  name char(20) primary key,
  professor char(10) not null,
  point smallint not null,
  time set(smallint not null),
  max_capacity smallint not null,
  present_size smallint not null,
  open smallint not null,
  dept_name char(20) references department(name));

create table lecture (
  student_number char(20) references student(number),
  class_name char(20) references class(name),
  primary key (student_number, class_name));
  
