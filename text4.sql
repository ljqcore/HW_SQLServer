use GlobalToyz
go

--1.定义一个视图，包括定单的编号、时间、金额以及收货人的姓名、国家代码和国家名称
create view OrderView as
select o.cOrderNo, dOrderDate, mTotalCost,vFirstName, vLastName, cState,cCountryId
from Orders o, Recipient r
where o.cOrderNo = r.cOrderNo
go

--2.基于（1）中定义的视图，查询所有国家代码为‘001’的收货人的姓名和他们所下定单的笔数及定单的总金额
select (vFirstName +' '+ vLastName) as Name, COUNT(cOrderNo) as Total, SUM(mTotalCost) as TotalCost
from OrderView
where cCountryId = '001' 
group by (vFirstName + ' '+ vLastName) 
go

--3.创建并分析视图
CREATE VIEW vwOrderWrapper
AS
	SELECT cOrderNo, cToyId, siQty, vDescription, mWrapperRate
	FROM OrderDetail JOIN Wrapper
	ON OrderDetail.cWrapperId = Wrapper.cWrapperId
go

--instead of触发器
create trigger Wrapper_update
on vwOrderWrapper
instead of update
as 
begin
	--更新基表OrderDetail
	update OrderDetail
	set siQty = i.siQty, cWrapperId = w.cWrapperId
	from inserted i join OrderDetail od 
	on i.cOrderNo = od.cOrderNo and i.cToyId = od.cToyId
	join Wrapper w 
	on i.mWrapperRate = w.mWrapperRate
	
	--更新基表Wrapper	
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

--9.在GlobalToyz数据库里创建一个用户，用户名为user_xxxx（你的学号）
--通过视图限制该用户只能访问Orders表中2017年以前的数据
create login user_001 with password = '123145'
go

create user user_001 for login user_001
go

--创建一个视图，只存放2018年以前的数据
create view Orders_2018
as
select *
from Orders
where dOrderDate < '2018-01-01 00:00:00.000'
go
--授权
grant select on Orders_2018 to user_001;
go

--10.当购物者确认定单时，应该包含下面的步骤：
--11.（1）产生新的定单号（要求创建一个存储过程，用于产生新定单号）。
--12.（2）定单号，当前日期，购物车ID，和购物者ID应该加到Orders表中。
--13.（3）定单号，玩具ID和数量应加到OrderDetail表中。
--14.（4）在OrderDetail表中更新玩具成本。（提示：Toy cost = Quantity * Toy Rate）。
--   （5）从ShoppingCart表中将本次已购买的玩具删除。
--将上述步骤定义为一个事务。编写一个过程以购物车ID和购物者ID为参数，实现这个事务。
--（提示：首先需要修改表ShoppingCart的结构，在表中新增一个字段‘Status’。该字段取值为1，表示该玩具为本次下订单时要购买的玩具，并产生一些模拟数据。）

--1).首先需要修改表ShoppingCart的结构，在表中新增一个字段‘Status’
--修改表ShoppingCart结构
alter table ShoppingCart 
add Status smallint 

update ShoppingCart
set Status = 1
go
--2).创建名为prcGenOrder的存储过程，产生存在于数据库中的定单号
--生成新的订单号
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

--3).定义为一个事务，编写一个过程以购物车ID和购物者ID为参数，实现这个事务。
--（2）定单号，当前日期，购物车ID，和购物者ID应该加到Orders表中。
--（3）定单号，玩具ID和数量应加到OrderDetail表中。
--（4）在OrderDetail表中更新玩具成本。（提示：Toy cost = Quantity * Toy Rate）。
--（5）从ShoppingCart表中将本次已购买的玩具删除。

begin transaction
    --count记录事务中出现错误的次数
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

	--定单号，当前日期，购物车ID，和购物者ID应该加到Orders表中
	insert into Orders
	values(@OrderNo,getdate(),@CartId,@ShopperId,null,null,null,null,null,null)
	set @count=@count+@@ERROR --记录上条语句是否产生错误

	--定单号，玩具ID和数量应加到OrderDetail表中
	insert into OrderDetail 
	values(@OrderNo,@ToyId,@Qty,null,null,null,@Qty*@ToyRate)
	set @count=@count+@@ERROR --记录上条语句是否产生错误

	--从ShoppingCart表中将本次已购买的玩具删除
	delete from ShoppingCart where Status=1 and cToyId=@ToyId
	set @count=@count+@@ERROR --记录上条语句是否产生错误

	--如果@count的值大于0，则说明事务中有一个或多个操作失败，此时需要进行回滚；否则，所有操作都成功执行，可以进行提交。
	if(@count>0)
	begin
		print'Error'
		rollback
	end
	else
		commit
go
----创建存储过程
--create procedure newOrderNumber
--	@orderNo int output  --表示为输出参数
--as
--begin
--	declare @newID char(6)

--	while 1=1
--	begin
--		--NEWID()生成一个全局唯一标识符
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

----修改表ShoppingCart结构
--alter table ShoppingCart 
--add Status smallint 

--update ShoppingCart
--set Status = 1
--go

----创建事务
--create procedure ConfirmOrder(
--	@ShoppingCartID char(6),
--	@ShopperID char(6)
--)
--as
--begin
--	--开始事务TRANSACTION
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

--	--获取新订单号
--	exec newOrderNumber @OrderNo out

--	--获取当前日期
--	set @OrderDate = getdate()

--	--更新@cShippingModeId
--	set @cShippingModeId = (
--		 select cModeId
--		 from ShippingMode
--		 order by NEWID()
--	)
--	--声明游标
--	declare cur cursor 
--	for select cToyId 
--	from ShoppingCart
--	where cCartId = @ShoppingCartID;
--	--打开游标
--	OPEN @cur;
--	FETCH NEXT FROM @cur INTO @ToyId;

--	while @@FETCH_STATUS = 0
--	begin
--		--处理每一行的数据
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

--			set @dExpDelDate =  DATEADD(day, 2, '2023-05-19 00:00:00') --预计交付日期

--		--将下一行游标放进当前变量中
--		FETCH NEXT FROM @cur INTO @ToyId;
--	end

--CLOSE @Cursor;
--DEALLOCATE @Cursor;
--	--玩具的ID和数量由cartId得来的
--	while 1=1
--		begin
--		set @ToyId = (select cToyId 
--				  from ShoppingCart
--				  where ShoppingCart.cCartId = @ShoppingCartID)
--		end
	
--	--添加信息到Orders表
--	insert into Orders 
--	values(@OrderNo, @OrderDate, @ShoppingCartID, @cShippingModeId, 
--	@mShippingCharges, @mGiftWrapCharges, @cOrderProcessed,@mTotalCost,@dExpDelDate)


--	--提交事务
--	commit TRANSACTION

--end
--go

--15.编写一个程序显示每天的定单状态。如果当天的定单值总合大于150，则显示“High sales”,
--否则显示”Low sales”。要求列出日期、定单状态和定单总价值。（要求用游标实现）
insert into Orders values('010001','05/29/2023','000002','000002','01',6,1.2500,'Y',62.2200,'06/04/2023')
insert into Orders values('010002','05/29/2023','000001','000005','02',8,2.0000,'Y',96.5000,'06/03/2023')
insert into Orders values('010003','05/29/2023','000003','000007','01',12,0,'Y',83.9700,'06/05/2023')
go
--删除存储过程
drop procedure show_daily_sales


--15.15.编写一个程序显示每天的定单状态。如果当天的定单值总合大于150，
--则显示“High sales”,否则显示”Low sales”。要求列出日期、定单状态和定单总价值。（要求用游标实现）
DECLARE @OrderDate DATE
DECLARE @OrderAmount MONEY
DECLARE @TotalSales MONEY = 0
DECLARE @OrderStatus NVARCHAR(20)

--定义游标
DECLARE order_cursor CURSOR FOR
SELECT dOrderDate, mTotalCost
FROM Orders

--打开游标
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
--释放游标
DEALLOCATE order_cursor

/*
--16.基于表Orders和Shopper，以下列格式生成报表：
      购货人ID   XXX    购货人姓名   XXX    
      购货人地址  XXXXXX 
      定单号XXX  定单时间XXX  定单金额XXX
      定单号XXX  定单时间XXX  定单金额XXX
*/
--未用游标
SELECT Shopper.cShopperId AS '购货人ID',
       CONCAT(Shopper.vFirstName,' ',Shopper.vLastName) AS '购货人姓名',
       Shopper.vAddress AS '购货人地址',
       Orders.cOrderNo AS '定单号',
       Orders.dOrderDate AS '定单时间',
       Orders.mTotalCost AS '定单金额'
FROM Orders
INNER JOIN Shopper ON Orders.cShopperId = Shopper.cShopperId
ORDER BY Shopper.cShopperId, Orders.cOrderNo;

--使用游标

--定义游标
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

--打开游标
OPEN order_cursor

FETCH NEXT FROM order_cursor INTO @cShopperId, @cShopperName, @vAddress, @cOrderNo, @dOrderDate, @mTotalCost

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		PRINT '购货人ID' + CONVERT(NVARCHAR(6), @cShopperId) + '    ' +
		 '购货人姓名 ' + CONVERT(NVARCHAR(40), @cShopperName) + CHAR(13)+CHAR(10)+
		 '购货人地址' + CONVERT(NVARCHAR(40), @vAddress) + CHAR(13)+CHAR(10)+
		 '定单号'+ CONVERT(NVARCHAR(6), @cOrderNo)  + '    '+	
		 '定单时间' + CONVERT(NVARCHAR(20), @dOrderDate) + '    ' + 
		 '定单金额' + CONVERT(NVARCHAR(6), @mTotalCost)+ CHAR(13)+CHAR(10);
		 
		 FETCH NEXT FROM order_cursor INTO @cShopperId, @cShopperName, @vAddress, @cOrderNo, @dOrderDate, @mTotalCost

	END

CLOSE order_cursor