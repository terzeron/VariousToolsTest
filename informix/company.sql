create row type emp_t (
	name varchar(30),
	base_salary money(8,2),
	manager varchar(30));

drop table engineer;
drop row type engineer_t restrict;
create row type engineer_t (
	skills varchar(20),
	bonus money(8,2)) under emp_t;
create row type sales_t (
	territory varchar(30),
	commission money(8,2),
	annual_sales money(8,2)) under emp_t;

create table emp of type emp_t;
create table engineer of type engineer_t;
create table sales of type sales_t;

insert into emp values ("Jane Smith",20000.00, "Jane Smith");
insert into engineer values ("John Doe", 28000.00, "Jane Smith", "Coding", 10000.00);
insert into sales values ("Mike Girard", 28000.00, "Jane Smith", "All US", 25, 10000.00);

select * from emp;
select * from engineer;
select * from only(emp);
select e from emp e;

update emp set manager = 'Frog, Kermit The' where manager = 'Jane Smith';

create index enginner_ix on engineer(name);
select * from sysindexes;
	