drop table schedule;
create row type schedule_t (
	schedule_id int,
	class_id int,
	location varchar(30),
	start_date date,
	end_date date);
create table schedule of type schedule_t;
alter table schedule add constraint (primary key (schedule_id));
alter table schedule add constraint (foreign key (class_id) references class);
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
select * from schedule;

create row type onsite_t (
	onsite_id int,
	class_id int,
	location char(30),
	start_date date,
	end_date date,
	cost dollar,
	company varchar(10),
	co_address address_t,
	contact name_t);	
drop table onsite;
create table onsite of type onsite_t;
alter table onsite add constraint (primary key (onsite_id));
alter table onsite add constraint (foreign key(class_id) references class);
select * from class;
select * from onsite;
insert into onsite values (
	3, 
	346, 
	"USA", 
	"8/19/97", 
	"8/21/97", 
	'12000.00'::dollar, 
	"AG America", 
	row("10 Streeter Rd", "  ", "Fresco", "CA", "93310")::address_t, 
	row("Middle-ton", "Jean")::name_t);
insert into onsite values(
	2,
	324,
	"USA",
	"8/1/97",
	"8/3/97",
	'15000.00'::dollar,
	"Clocks R' US",
	row("1 Timepiece Plaza", "   ",  "Houston", "TX", "52212")::address_t,
	row("Buck", "George")::name_t);

select * from onsite;

drop function revenue(onsite_t);
create function revenue(parm1 onsite_t)
	returning dollar;
	return parm1.cost;
end function;
drop function revenue(schedule_t);
create function revenue(parm1 schedule_t)
	returning dollar;
	define total dollar;
	let total = '0.0'::dollar;
	select sum(amt_paid) into total from roster where schedule_id = parm1.schedule_id;
	return total;
end function;
select revenue(s) from schedule s;	

--select revenue(onsite) from onsite;
select revenue(o) from onsite o;

create function times(d1 dollar, d2 dollar)
	returning dollar;
	return (d1::float * d2::float)::dollar;
end function;
drop function revenue(schedule_t);
create function revenue(s1 schedule_t)
	returning dollar;
	define total dollar;
	let total = '0.0'::dollar;
	select sum(amt_paid) into total from roster where schedule_id = s1.schedule_id;
	return ((total + (total * 0.08))::dollar);
end function;

select revenue(s) from schedule s;
select  * from roster;
