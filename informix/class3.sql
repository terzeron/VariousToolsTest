drop table newonsite;
drop table schedule;
drop table onsite;

drop function revenue(onsite_t);
drop function revenue(schedule_t);

drop row type onsite_t restrict;
drop row type internal_t restrict;
drop row type schedule_t restrict;

create row type schedule_t (
	schedule_id int,
	class_id int,
	location varchar(50),
	date_start date,
	date_end date);
create row type onsite_t (
	cost dollars,
	company varchar(30),
	co_address address,
	contact name_t) under schedule_t;
create row type internal_t (
	department char(6),
	char_account char(10),
	requested_by name_t) under schedule_t;

create table schedule of type schedule_t;
create table internal of type internal_t;
create table onsite of type onsite_t;

alter table schedule modify schedule_id int primary key;
alter table schedule add contraint (foreign key (class_id) references class);

insert into schedule values (1,1,"Downers Grove, IL, USA", "10/1/97", "10/3/97");
insert into schedule values (2,2,"New Delhi, India", "9/17/97", "9/19/97");
insert into onsite values (3,1,"USA", "8/19/97", "8/21/97", 12000.00::dollars,"AG America", 
	row("10 streeter RD", " ", "Fresco", "CA", "93310"::address_t, row
	row("Jean", "Midlleton")::name_t);
insert into internal values (5,1,"Menlo Park, 4100", "11/1/97", "11/3/97", 'ESOP', '3300',
	row("Jim", "Beam")::name_t);
select * from schedule;
select schedule from schedule;
select * from only(schedule);

drop function revenue(onsite_t);
create function revenue(o1 onsite_t)
	returning dollar;
	return o1.cost;
end function;
select renenue(o)  from onsite o;

create function revenue(s1 schedule_t)
	returning dollar;
	define total dollar;
	let total = '0.0'::dollar;
	select sum(amt_paid) into total from roster where schedule_id = s1.schedule_id;
	return total;
end function;
select revenue(o) from schedule s;


drop table newonsite;	
drop row type newonsite_t restrict;
create row type newonsite_t (
	on_class_name varchar(10),
	on_pre set(varchar(10) not null),
	length int,
	in_deparment varchar(10),
	in_accout varchar(10),
	in_request name_t) under schedule_t;

create table newonsite of type newonsite_t;

select * from onsite;

insert into newonsite values (
	1,
	246,
	"KOREA",
	"8/1/91".
	"9/1/92".
	2000.00::dollar,
	"Informix",
	row("1 timepiece plaza", " ", "fsjlf", "kfjs", "12414")::address_t,
	row("Kim", "Hoon")::name_t,
	
);


drop function revenue
create function revenue(s1 newonsite_t)
	returning dollar;
	define total dollar;
	let total = 0.0::dollar;
	select sum(amt_paid) into total from roster where schedule_id = s1.schedule_id;
	return total;
end function;

drop function revenue(schedule_t);
create function revenue(s1 schedule_t)
	returning dollar;
	define total dollar;
	let total = '0.0'::dollar;
	select sum(amt_paid) into total from roster where schedule_id = s1.schedule_id;
	return total;
end function;	
	
select revenue(s) from schedule s;
select revenue(s) from onsite s;
