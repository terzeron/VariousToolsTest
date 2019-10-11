create row type name_t (fname char(20), lname char(20));
create row type address_t (street1 char(20), street2 char(20), city char(20), state char(10), zip char(10));
create table student (
	name name_t,
	address address_t,
	student_id int primary key,
	company varchar(30));
create table class (
	prerequisites set(varchar(10) not null),
	class_id int primary key,
	class_name varchar(10),
	length int);
insert into student values (
	row('Kim', 'Amugae')::name_t, 
	row('1', '2', 'Seoul', 'Korea', '234-234')::address_t,
	1234,
	'ABC');
insert into student values (
	row('Chang', 'Sam')::name_t, 
	row('3', '4', 'Pusan', 'Korea', '134-214')::address_t,
	1235,
	'UTY');
insert into student values (
	row('Lee', 'Sa')::name_t, 
	row('1', '2', 'New York', 'USA', '123-865')::address_t,
	1236,
	'FSG');
select * from student;
insert into class values (
	'set{"DS", "Computer Architecture"}',
	324,
	'Database',
	60);
insert into class values (
	'set{"SQL", "SPL"}',
	346,
	'Informsix',
	360);
select * from class;
select * from student where name.lname = 'Sa';
update student  set name = row('Park', 'Chan-Ho')::name_t where student_id = 1234;
select * from student;
update student set address = row('100', 'Jong-ro', address.city, address.state, address.zip)::address_t where student_id = 1236;
update class set prerequisites = "set{'SQL', 'SPL', 'OODBMS Design'}" where class_id = 346;
select * from class;
select *  from class where ( 'OODBMS Des') in prerequisites;


drop table schedule;
create table schedule (
	schedule_id int primary key,
	class_id int references class(class_id),
	location char(30),
	start_date date,
	end_date date);
drop table roster;
create table roster (
	schedule_id int references schedule,
	student_id int references student,
	amt_paid money,
	primary key(schedule_id, student_id));

insert into schedule values (
	1,
	346,
	'Informix',
	'123075',
	'012076');

insert into schedule values (
	2,
	324,
	"Oracle",
	"032497",
	"041098");

insert into roster values (
	1,
	1234,
	780000);

insert into roster values (
	2,
	1235,
	340000);
insert into roster values (
	1,
	1236,
	170000);
		
select * from schedule;
select * from  roster;

drop function dollars_to_lira;
create function dollars_to_lira(pamt money)
	returning money;
	define result money;
	let result = pamt  *1700;
	return result;
end function;
	
drop function lira_to_dollars;
create function lira_to_dollars(lpamt money)
	returning money;
	define result money;
	let result = lpamt / 1700;
	return result;
end function;

drop procedure amtlira_to_dollar;

create procedure amtlira_to_dollar(schedule_id int, student_id int);
	update roster set amt_paid = lira_to_dollars(amt_paid) 
	where roster.student_id = student_id and roster.schedule_id = schedule_id;
end procedure;

execute procedure amtlira_to_dollar(1, 1236);
execute procedure amtlira_to_dollar(2, 1235);

select * from roster;

--create distinct type dollar as money;
--create distinct type lira as money;

alter table roster
	modify (amt_paid dollar);

drop cast (lira as dollar);
create explicit cast (lira as dollar with lira_to_dollars);

select * from roster;
delete from roster where schedule_id = 1 and student_id = 1234;
delete from roster where schedule_id = 2 and student_id = 1236;
insert into roster values (
	1,
	1234,
	7800::money::dollar);

select * from roster;

drop cast (dollar as money);
drop cast (lira as dollar);

create implicit cast (lira as dollar with lira_to_dollars);
delete from roster where schedule_id = 1 and student_id = 1236;
insert into roster values (
	1,
	1236,
	170000.0::money::lira);
