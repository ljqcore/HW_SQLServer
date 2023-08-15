--1. �������ݿ⣬�����ļ�--
CREATE DATABASE CAP on ( 
NAME=cap, 
FILENAME='D:\Sql\CAPData.mdf', 
SIZE=50,
MAXSIZE=500, 
FILEGROWTH=10 
)
GO
use CAP;
GO

--2. ������--
create table Customers (
cid char(10) primary key, 
cname varchar(12),
city varchar(32),
discnt numeric(6,2) check(discnt >=0 and discnt <=30),
);
GO

insert into customers values('C001','TipTop','Duluth',10)
insert into customers values('C002','Basics','Dallas',12)
insert into customers values('C003','Allied','Dallas',8)
insert into customers values('C004','ACME','Duluth',8)
insert into customers values('C005','Oriental','Kyoto',6)
insert into customers values('C006','ACME','Kyoto',0)
GO

select * from customers;
GO

create table Products(
    Pid char(10) Primary key ,
    pname char(10),
    city char(10),
    quantity int,
    price float(10) NOT NULL,
);
GO
insert into Products values('P01','comb','Dallas',111400,0.5)
insert into Products values('P02','brush','Newark',203000,0.5)
insert into Products values('P03','razor','Duluth',150600,1)
insert into Products values('P04','Pen','Duluth',125300,1)
insert into Products values('P05','pencil','Dallas',221400,1)
insert into Products values('P06','folder','Dallas',123100,2)
insert into Products values('P07','case','Newark',100500,1)
GO
select * from Products
GO

create table Agents(
    Aid char(10) Primary key,
    aname char(10),
    city char(10),
    "percent" int,
);
GO
insert into Agents values('A01','smith','New York',6)
insert into Agents values('A02','Jones','Newark',6)
insert into Agents values('A03','Brown','Tokyo',7)
insert into Agents values('A04','Gray','New York',6)
insert into Agents values('A05','Otasi','Duluth',5)
insert into Agents values('A06','Smith','Dallas',5)
GO
select * from Agents
GO

create table Orders(
    Ordno int Primary key,
    month char(10),
    cid char(10),
    aid char(10),
    pid char(10),
    qty int,
    dollars float(10),
);
GO
insert into Orders values(1024,'Mar','C006','A06','P01',800,400)
insert into Orders values(1020,'Feb','C005','A03','P07',600,600)
insert into Orders values(1016,'Jan','C004','A01','P01',1000,500)
insert into Orders values(1021,'Feb','C004','A06','P01',1000,460)
insert into Orders values(1014,'Jan','C003','A03','P05',1200,1104)
insert into Orders values(1015,'Jan','C003','A03','P05',1200,1104)
insert into Orders values(1026,'May','C002','A05','P03',800,704)
insert into Orders values(1013,'Jan','C002','A03','P03',1000,880)
insert into Orders values(1025,'Apr','C001','A05','P07',800,720)
insert into Orders values(1022,'Mar','C001','A05','P06',400,720)
insert into Orders values(1023,'Mar','C001','A04','P05',500,450)
insert into Orders values(1018,'Feb','C001','A03','P04',600,540)
insert into Orders values(1017,'Feb','C001','A06','P03',600,540)
insert into Orders values(1019,'Feb','C001','A02','P02',400,180)
insert into Orders values(1012,'Jan','C001','A01','P01',1000,450)
insert into Orders values(1011,'Jan','C001','A01','P01',1000,450)
GO
select * from Orders
GO

--�������Լ��--
ALTER TABLE Orders
ADD FOREIGN KEY (cid)
REFERENCES customers(cid)
GO

ALTER TABLE Orders
ADD FOREIGN KEY (aid)
REFERENCES Agents(aid)
GO

ALTER TABLE Orders
ADD FOREIGN KEY (pid)
REFERENCES Products(pid)
GO

use cap
go
--3������ϵͳԤ����Ĵ洢����sp_helpdb�鿴���ݿ�������Ϣ�����������ߡ���С���������ڵȡ�--
EXEC sp_helpdb CAP
GO

--4������ϵͳԤ����Ĵ洢����sp_helpconstraint�鿴���г��ֵ�Լ��������Primary key, Foreign key, check constraint, default, unique��--
EXEC sp_helpconstraint Customers
GO
EXEC sp_helpconstraint Orders
GO

--5������һ�ű�Orders_Jan����Ľṹ��Orders��ͬ����Orders����monthΪ��Jan���Ķ�����¼���Ƶ���Orders_Jan��--
select * into Orders_Jan
from Orders
where 1 = 0;
GO
--ʼ�շ���false,���Ḵ�����ݣ�ֻ�Ḵ�Ʊ�Ľṹ--

insert into Orders_Jan
select * from Orders
where month = 'Jan'
GO

--���
select * from Orders_Jan

--6����Orders����monthΪ��Jan���Ķ�����¼ȫ��ɾ����--
delete from Orders
where month = 'Jan'
GO

--7���������¹���dollars������500�Ķ����Ŀͻ�������discntֵ����2���ٷֵ㣨+2��--
update Customers 
set discnt += 2
where (cid in (select Customers.cid
				from Customers, Orders
				where Customers.cid = Orders.cid and Orders.dollars > 500))
Go

--8��дһ��TSQL�������Orders������5000����¼��Ҫ�󶩵������ܾ��ȵطֲ���12�����С�
DECLARE @counter INT = 1,
		@Ordno INT = 1028,
	    @mon CHAR(3),
        @cid CHAR(4),
		@aid CHAR(3),
	    @pid CHAR(3),
		@qty INT,
		@dollars NUMERIC(10,2),
		@randnum INT;

WHILE @counter <= 5000
BEGIN
    SET @randnum = ABS(CHECKSUM(NewId())) % 12 + 1; -- �����·�
    
    SET @mon =
        CASE @randnum
            WHEN 1 THEN 'Jan'
            WHEN 2 THEN 'Feb'
            WHEN 3 THEN 'Mar'
            WHEN 4 THEN 'Apr'
            WHEN 5 THEN 'May'
            WHEN 6 THEN 'Jun'
            WHEN 7 THEN 'Jul'
            WHEN 8 THEN 'Aug'
            WHEN 9 THEN 'Sep'
            WHEN 10 THEN 'Oct'
            WHEN 11 THEN 'Nov'
            WHEN 12 THEN 'Dec'
        END;
    
    SELECT TOP 1 @cid = cid FROM Customers ORDER BY NEWID(); -- ��ȡ����ͻ��� cid
    
    SELECT TOP 1 @aid = aid FROM Agents ORDER BY NEWID(); -- ��ȡ��������̵� aid
    
    SELECT TOP 1 @pid = pid FROM Products ORDER BY NEWID(); -- ��ȡ�����Ʒ�� pid
    
	--����һ������1��100֮����������
    SET @qty = ABS(CHECKSUM(NewId())) % 100 + 1; -- ��������
    
	--����һ������0��1000֮��������������������ת��ΪNUMERIC���͵����ݣ�������λС��
    SET @dollars = CAST(RAND() * 1000 AS NUMERIC(10,2)); -- ���ɽ��
    
    INSERT INTO Orders VALUES (CAST(@Ordno AS CHAR(4)), @mon, @cid, @aid, @pid, @qty, @dollars); -- �����¶���
    
    SET @counter += 1;
	-- ��������һ
    SET @Ordno += 1;
END;

----9���ڱ�Orders�ġ�month���ֶ��Ͻ���������--
create index month_idx on Orders(month)

/*10������һ����ͼorder_month_summary��
��ͼ�е��ֶΰ����·ݡ����µĶ��������͸��µĶ����ܽ�
������ͼorder_month_summary����ѯ��һ���ȸ����·ݵĶ��������Ͷ����ܽ��
*/
use cap
go
--������ͼ--
create view order_month_summary as 
select Orders.month as month,COUNT(*) as total_orders,SUM(Orders.dollars) as sum_dollars 
from Orders
group by Orders.month

--��ѯ--
select month,total_orders,sum_dollars
from order_month_summary





