use GlobalToyz
go

--1.����һ����ͼ�����������ı�š�ʱ�䡢����Լ��ջ��˵����������Ҵ���͹�������
create view OrderView as
select o.cOrderNo, dOrderDate, mTotalCost,vFirstName, vLastName, cState,cCountryId
from Orders o, Recipient r
where o.cOrderNo = r.cOrderNo
go

--2.���ڣ�1���ж������ͼ����ѯ���й��Ҵ���Ϊ��001�����ջ��˵��������������¶����ı������������ܽ��
select (vFirstName +' '+ vLastName) as Name, COUNT(cOrderNo) as Total, SUM(mTotalCost) as TotalCost
from OrderView
where cCountryId = '001' 
group by (vFirstName + ' '+ vLastName) 
go

--3.������������ͼ
CREATE VIEW vwOrderWrapper
AS
	SELECT cOrderNo, cToyId, siQty, vDescription, mWrapperRate
	FROM OrderDetail JOIN Wrapper
	ON OrderDetail.cWrapperId = Wrapper.cWrapperId
go

--instead of������
create trigger Wrapper_update
on vwOrderWrapper
instead of update
as 
begin
	--���»���OrderDetail
	update OrderDetail
	set siQty = i.siQty, cWrapperId = w.cWrapperId
	from inserted i join OrderDetail od 
	on i.cOrderNo = od.cOrderNo and i.cToyId = od.cToyId
	join Wrapper w 
	on i.mWrapperRate = w.mWrapperRate
	
	--���»���Wrapper	
	update Wrapper
	set mWrapperRate = i.mWrapperRate 
	from inserted i join OrderDetail od
	on i.cOrderNo = od.cOrderNo 
	join Wrapper w
	on od.cWrapperId = w.cWrapperId
end

UPDATE vwOrderWrapper
SET siQty = 2, mWrapperRate = mWrapperRate + 1 
WHERE cOrderNo = '000001'

--9.��GlobalToyz���ݿ��ﴴ��һ���û����û���Ϊuser_xxxx�����ѧ�ţ�
--ͨ����ͼ���Ƹ��û�ֻ�ܷ���Orders����2017����ǰ������
create login user_001 with password = '123145'
go

create user user_001 for login user_001
go

--����һ����ͼ��ֻ���2018����ǰ������
create view Orders_2018
as
select *
from Orders
where dOrderDate < '2018-01-01 00:00:00.000'
go
--��Ȩ
grant select on Orders_2018 to user_001;
go

--10.��������ȷ�϶���ʱ��Ӧ�ð�������Ĳ��裺
--11.��1�������µĶ����ţ�Ҫ�󴴽�һ���洢���̣����ڲ����¶����ţ���
--12.��2�������ţ���ǰ���ڣ����ﳵID���͹�����IDӦ�üӵ�Orders���С�
--13.��3�������ţ����ID������Ӧ�ӵ�OrderDetail���С�
--14.��4����OrderDetail���и�����߳ɱ�������ʾ��Toy cost = Quantity * Toy Rate����
--   ��5����ShoppingCart���н������ѹ�������ɾ����
--���������趨��Ϊһ�����񡣱�дһ�������Թ��ﳵID�͹�����IDΪ������ʵ���������
--����ʾ��������Ҫ�޸ı�ShoppingCart�Ľṹ���ڱ�������һ���ֶΡ�Status�������ֶ�ȡֵΪ1����ʾ�����Ϊ�����¶���ʱҪ�������ߣ�������һЩģ�����ݡ���

--1).������Ҫ�޸ı�ShoppingCart�Ľṹ���ڱ�������һ���ֶΡ�Status��
--�޸ı�ShoppingCart�ṹ
alter table ShoppingCart 
add Status smallint 

update ShoppingCart
set Status = 1
go
--2).������ΪprcGenOrder�Ĵ洢���̣��������������ݿ��еĶ�����
--�����µĶ�����
create procedure prcGenOrder
@OrderNo char(6) output
as
	select @OrderNo=Max(cOrderNo)  
	from Orders

	select @OrderNo=
	case
		when @OrderNo>=0 and @OrderNo<9 Then
				  '00000'+Convert(char,@OrderNo+1)
		when @OrderNo>=9 and @OrderNo<99 Then
				  '0000'+Convert(char,@OrderNo+1)
		when @OrderNo>=99 and @OrderNo<999 Then
				  '000'+Convert(char,@OrderNo+1)
		when @OrderNo>=999 and @OrderNo<9999 Then
				  '00'+Convert(char,@OrderNo+1)
		when @OrderNo>=9999 and @OrderNo<99999 Then
				  '0'+Convert(char,@OrderNo+1)
		when @OrderNo>=99999 Then 
				  Convert(char,@OrderNo+1)
	end

	print @OrderNo
return
go

--3).����Ϊһ�����񣬱�дһ�������Թ��ﳵID�͹�����IDΪ������ʵ���������
--��2�������ţ���ǰ���ڣ����ﳵID���͹�����IDӦ�üӵ�Orders���С�
--��3�������ţ����ID������Ӧ�ӵ�OrderDetail���С�
--��4����OrderDetail���и�����߳ɱ�������ʾ��Toy cost = Quantity * Toy Rate����
--��5����ShoppingCart���н������ѹ�������ɾ����

begin transaction
    --count��¼�����г��ִ���Ĵ���
	declare @count int
	set @count=0
	declare @OrderNo char(6)
	exec prcGenOrder @OrderNo output 
	set @count=@count+@@ERROR

	declare @ToyId char (6)
	declare @ShopperId char (6)
	declare @ToyRate money
	declare @CartId char (6)
	declare @Qty int
	set @CartId='000009'
	set @ShopperId='000007'
	set @ToyId='000008'
	set @Qty=2

	select @ToyRate=mToyRate
	from Toys
	where cToyId=@ToyId

	--�����ţ���ǰ���ڣ����ﳵID���͹�����IDӦ�üӵ�Orders����
	insert into Orders
	values(@OrderNo,getdate(),@CartId,@ShopperId,null,null,null,null,null,null)
	set @count=@count+@@ERROR --��¼��������Ƿ��������

	--�����ţ����ID������Ӧ�ӵ�OrderDetail����
	insert into OrderDetail 
	values(@OrderNo,@ToyId,@Qty,null,null,null,@Qty*@ToyRate)
	set @count=@count+@@ERROR --��¼��������Ƿ��������

	--��ShoppingCart���н������ѹ�������ɾ��
	delete from ShoppingCart where Status=1 and cToyId=@ToyId
	set @count=@count+@@ERROR --��¼��������Ƿ��������

	--���@count��ֵ����0����˵����������һ����������ʧ�ܣ���ʱ��Ҫ���лع����������в������ɹ�ִ�У����Խ����ύ��
	if(@count>0)
	begin
		print'Error'
		rollback
	end
	else
		commit
go
----�����洢����
--create procedure newOrderNumber
--	@orderNo int output  --��ʾΪ�������
--as
--begin
--	declare @newID char(6)

--	while 1=1
--	begin
--		--NEWID()����һ��ȫ��Ψһ��ʶ��
--		set @newID = (select convert(char(6), NEWID())) 

--		if not exists(
--			select cOrderNo
--			from Orders
--			where Orders.cOrderNo = @newID
--		)
--		begin
--		    break
--		end
--	end
--	set @orderNo = @newID
--end
--go

----�޸ı�ShoppingCart�ṹ
--alter table ShoppingCart 
--add Status smallint 

--update ShoppingCart
--set Status = 1
--go

----��������
--create procedure ConfirmOrder(
--	@ShoppingCartID char(6),
--	@ShopperID char(6)
--)
--as
--begin
--	--��ʼ����TRANSACTION
--	begin TRANSACTION

--	declare 
--	@OrderNo char(6),
--	@OrderDate datetime,
--	@totalCost money,
--	@cShippingModeId char(2),
--	@mShippingCharges money,
--	@mGiftWrapCharges money,
--	@cOrderProcessed char(1),
--	@mTotalCost money,
--	@dExpDelDate datetime,
--	@ToyId char(6),
--	@siQty smallint,
--	@coutryID char(3),
--	@shippingRate money,
--	@wrapperRate money,
--	@cToyRate money,
--	@ToyCost money,
--	@cWrapperId char(3),
--	@cur cursor 

--	--��ȡ�¶�����
--	exec newOrderNumber @OrderNo out

--	--��ȡ��ǰ����
--	set @OrderDate = getdate()

--	--����@cShippingModeId
--	set @cShippingModeId = (
--		 select cModeId
--		 from ShippingMode
--		 order by NEWID()
--	)
--	--�����α�
--	declare cur cursor 
--	for select cToyId 
--	from ShoppingCart
--	where cCartId = @ShoppingCartID;
--	--���α�
--	OPEN @cur;
--	FETCH NEXT FROM @cur INTO @ToyId;

--	while @@FETCH_STATUS = 0
--	begin
--		--����ÿһ�е�����
--			select @coutryID = Shopper.cCountryId
--			from Shopper
--			where Shopper.cShopperId = @ShopperID

--			select @shippingRate = mRatePerPound
--			from ShippingRate
--			where ShippingRate.cModeId = @cShippingModeId and ShippingRate.cCountryID = @coutryID

--			set @mShippingCharges = @shippingRate * @siQty

--			select @wrapperRate = mWrapperRate, @cWrapperId = cWrapperId
--			from Wrapper
--			order by newid() 

--				set @cWrapperId = 
--		case 
--			when @GiftWrapper = 'Y' then @cWrapperId
--			when @GiftWrapper = 'N' then NULL
--		end

--	set @mGiftWrapCharges =
--        case
--        when @GiftWrapper = 'Y' then @wrapperRate * @siQty
--        when @GiftWrapper = 'N' then 0
--        END
--			set @mGiftWrapCharges = @wrapperRate * @siQty
			
--			set @ToyCost = @cToyRate * @siQty
--			set @mTotalCost = @ToyCost+ @mShippingCharges + @mGiftWrapCharges  

--			set @dExpDelDate =  DATEADD(day, 2, '2023-05-19 00:00:00') --Ԥ�ƽ�������

--		--����һ���α�Ž���ǰ������
--		FETCH NEXT FROM @cur INTO @ToyId;
--	end

--CLOSE @Cursor;
--DEALLOCATE @Cursor;
--	--��ߵ�ID��������cartId������
--	while 1=1
--		begin
--		set @ToyId = (select cToyId 
--				  from ShoppingCart
--				  where ShoppingCart.cCartId = @ShoppingCartID)
--		end
	
--	--�����Ϣ��Orders��
--	insert into Orders 
--	values(@OrderNo, @OrderDate, @ShoppingCartID, @cShippingModeId, 
--	@mShippingCharges, @mGiftWrapCharges, @cOrderProcessed,@mTotalCost,@dExpDelDate)


--	--�ύ����
--	commit TRANSACTION

--end
--go

--15.��дһ��������ʾÿ��Ķ���״̬���������Ķ���ֵ�ܺϴ���150������ʾ��High sales��,
--������ʾ��Low sales����Ҫ���г����ڡ�����״̬�Ͷ����ܼ�ֵ����Ҫ�����α�ʵ�֣�
insert into Orders values('010001','05/29/2023','000002','000002','01',6,1.2500,'Y',62.2200,'06/04/2023')
insert into Orders values('010002','05/29/2023','000001','000005','02',8,2.0000,'Y',96.5000,'06/03/2023')
insert into Orders values('010003','05/29/2023','000003','000007','01',12,0,'Y',83.9700,'06/05/2023')
go
--ɾ���洢����
drop procedure show_daily_sales


--15.15.��дһ��������ʾÿ��Ķ���״̬���������Ķ���ֵ�ܺϴ���150��
--����ʾ��High sales��,������ʾ��Low sales����Ҫ���г����ڡ�����״̬�Ͷ����ܼ�ֵ����Ҫ�����α�ʵ�֣�
DECLARE @OrderDate DATE
DECLARE @OrderAmount MONEY
DECLARE @TotalSales MONEY = 0
DECLARE @OrderStatus NVARCHAR(20)

--�����α�
DECLARE order_cursor CURSOR FOR
SELECT dOrderDate, mTotalCost
FROM Orders

--���α�
OPEN order_cursor

FETCH NEXT FROM order_cursor INTO @OrderDate, @OrderAmount

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @TotalSales = @TotalSales + @OrderAmount
    
	IF @TotalSales > 150
		SET @OrderStatus = 'High sales'
	ELSE
		SET @OrderStatus = 'Low sales'
    
	PRINT CONVERT(NVARCHAR(10), @OrderDate, 120) + ': ' + @OrderStatus + ', Total Order Amount: ' + CONVERT(NVARCHAR(20), @TotalSales, 2)
    
	FETCH NEXT FROM order_cursor INTO @OrderDate, @OrderAmount
END

CLOSE order_cursor
--�ͷ��α�
DEALLOCATE order_cursor

/*
--16.���ڱ�Orders��Shopper�������и�ʽ���ɱ���
      ������ID   XXX    ����������   XXX    
      �����˵�ַ  XXXXXX 
      ������XXX  ����ʱ��XXX  �������XXX
      ������XXX  ����ʱ��XXX  �������XXX
*/
--δ���α�
SELECT Shopper.cShopperId AS '������ID',
       CONCAT(Shopper.vFirstName,' ',Shopper.vLastName) AS '����������',
       Shopper.vAddress AS '�����˵�ַ',
       Orders.cOrderNo AS '������',
       Orders.dOrderDate AS '����ʱ��',
       Orders.mTotalCost AS '�������'
FROM Orders
INNER JOIN Shopper ON Orders.cShopperId = Shopper.cShopperId
ORDER BY Shopper.cShopperId, Orders.cOrderNo;

--ʹ���α�

--�����α�
DECLARE order_cursor CURSOR FOR
SELECT Shopper.cShopperId ,
       CONCAT(Shopper.vFirstName,' ',Shopper.vLastName) ,
       Shopper.vAddress ,
       Orders.cOrderNo ,
       Orders.dOrderDate ,
       Orders.mTotalCost 
FROM Orders
INNER JOIN Shopper ON Orders.cShopperId = Shopper.cShopperId

declare @cShopperId char(6)
declare @cShopperName varchar(40)
declare @vAddress varchar(40)
declare @cOrderNo char(6)
declare @dOrderDate Datetime
declare @mTotalCost money

--���α�
OPEN order_cursor

FETCH NEXT FROM order_cursor INTO @cShopperId, @cShopperName, @vAddress, @cOrderNo, @dOrderDate, @mTotalCost

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		PRINT '������ID' + CONVERT(NVARCHAR(6), @cShopperId) + '    ' +
		 '���������� ' + CONVERT(NVARCHAR(40), @cShopperName) + CHAR(13)+CHAR(10)+
		 '�����˵�ַ' + CONVERT(NVARCHAR(40), @vAddress) + CHAR(13)+CHAR(10)+
		 '������'+ CONVERT(NVARCHAR(6), @cOrderNo)  + '    '+	
		 '����ʱ��' + CONVERT(NVARCHAR(20), @dOrderDate) + '    ' + 
		 '�������' + CONVERT(NVARCHAR(6), @mTotalCost)+ CHAR(13)+CHAR(10);
		 
		 FETCH NEXT FROM order_cursor INTO @cShopperId, @cShopperName, @vAddress, @cOrderNo, @dOrderDate, @mTotalCost

	END

CLOSE order_cursor