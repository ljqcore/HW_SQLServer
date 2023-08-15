--3．在Orders表中增加1000笔订单数据，注意与其它表之间的关系--
use GlobalToyz
go

--新插入1000条数据--
DECLARE @i int = 11, @cOrderNo as char(6), @cToyId as char(6), @dOrderDate as datetime, @cShopperId as char(6), @cCartId as char(6),
@cShippingModeId as char(2), @mShippingCharges as money, @mGiftWrapCharges as money, @cOrderProcessed as char(1), @mTotalCost as money, @dExpDelDate as datetime, @siQty as smallint, @cWrapperId as char(3), @vMessage as varchar(256), @toycost as money, @minTotalCost as money, @sum as money, @shippingRate as money,
@coutryID as char(3), @wrapperRate as money, @GiftWrapper as char(1), @cToyRate as money, @iMaxDelay int;
WHILE (@i<=1011)
BEGIN
	--订单号
	--RIGHT:截取该字符串的右侧部分（也就是末尾），并在其左侧添加0，直到总长度为6位
	set @cOrderNo = (RIGHT('000000' + CAST(@i AS VARCHAR(6)), 6))

	--订单产生日期
	set @dOrderDate = DATEADD(hour, @i, '2023-05-19 00:00:00')

	--从表中选择一个购物车id
	select @cCartId = cCartId
	from ShoppingCart
	order by newid()

	--从表中选择一个玩具id，玩具单价
    select @cToyId = cToyId, @cToyRate = mToyRate
    from Toys
    order by newid()

	--从表中选择一个购物者id
	select @cShopperId = cShopperId
	from Shopper
	order by newid()

	--从表中选择一个玩具运输种类
	select @cShippingModeId = cModeId
	from ShippingMode
	order by newid()

	--从表中找到玩具质量
	select @siQty = ShoppingCart.siQty
	from ShoppingCart
	where ShoppingCart.cToyId = @cToyId and ShoppingCart.cCartId = @cCartId 
	--set @siQty = CAST(rand() * 5 as int)

	--购物者家乡号Id由购物者Id确定
	select @coutryID = Shopper.cCountryId
	from Shopper
	where Shopper.cShopperId = @cShopperId

	--每个玩具的每磅运输的单价
	select @shippingRate = mRatePerPound
	from ShippingRate
	where ShippingRate.cModeId = @cShippingModeId and ShippingRate.cCountryID = @coutryID

	--购物总价=每磅运输的单价*玩具质量
	set @mShippingCharges = @shippingRate * @siQty

	--处理orderDetail表,先随机取出包装单价和包装种类Id
	select @wrapperRate = mWrapperRate, @cWrapperId = cWrapperId
	from Wrapper
	order by newid() 

	--订单是否被处理：Y-已处理
	set @cOrderProcessed = 'Y' 
	
	--标识玩具是否需要包装费用  Y-需要   N-不需要
	set @GiftWrapper = (SELECT CASE WHEN RAND() < 0.5 THEN 'Y' ELSE 'N' END)

	--玩具的包装种类Id
	set @cWrapperId = 
		case 
			when @GiftWrapper = 'Y' then @cWrapperId
			when @GiftWrapper = 'N' then NULL
		end

	--玩具的包装费=玩具单个包装费用*数量
	set @mGiftWrapCharges =
        case
			when @GiftWrapper = 'Y' then @wrapperRate * @siQty
			when @GiftWrapper = 'N' then 0
        end
	
	--玩具价值=玩具单价*质量
	--由于这里是一对一，只需要产生一条
	set @ToyCost = @cToyRate * @siQty

	--玩具总费用=玩具价值+运输费用+包装费用
    set @mTotalCost = @ToyCost+ @mShippingCharges + @mGiftWrapCharges  

	--交付时间：最大延迟时间由ShippingMode寻找
	select @iMaxDelay
	from ShippingMode
	where @cShippingModeId = ShippingMode.iMaxDelDays
	set @dExpDelDate =  DATEADD(day, @iMaxDelay, '2023-05-19 00:00:00') --预计交付日期
	
	--插入数据到Orders表
	INSERT INTO Orders
	VALUES (@cOrderNo, @dOrderDate, @cCartId, @cShopperId, @cShippingModeId, @mShippingCharges,
	    @mGiftWrapCharges, @cOrderProcessed, @mTotalCost, @dExpDelDate)

	set @vMessage = NULL
	
	--插入数据到OrderDetail表
	INSERT INTO OrderDetail (cOrderNo, cToyId, siQty, cGiftWrap, cWrapperId, vMessage, mToyCost)
	VALUES (
		@cOrderNo, -- cOrderNo
		@cToyId, -- cToyId
		@siQty, -- siQty
		@GiftWrapper, -- cGiftWrap
		@cWrapperId, -- cWrapperId
		@vMessage, -- vMessage
		@toycost
	);

	SET @i = @i + 1
END
GO

--删除数据库--
set nocount    on
USE master

SELECT session_id, login_name, host_name, program_name
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID('GlobalToyz');
ALTER DATABASE GlobalToyz SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
drop database GlobalToyz
go


--4.在Orders表中新增数据之后，更新PickofMonth表--
INSERT INTO PickOfMonth(cToyId, siMonth, iYear, iTotalSold)
SELECT cToyId, MONTH(dOrderDate), YEAR(dOrderDate),sum(mToyCost)
FROM OrderDetail
JOIN Orders ON OrderDetail.cOrderNo = Orders.cOrderNo
GROUP BY cToyId, MONTH(dOrderDate), YEAR(dOrderDate)
GO


--实验二具体内容--

--1.查找属于California和Florida州的顾客的名、姓和emailID--
select vFirstName, vLastName, vEmailId
from Shopper
where Shopper.cState ='California' or Shopper.cState='Florida'

---2.查找定单号码、顾客ID，定单的总价值，并以定单的总价值的升序排列-
select cOrderNo,cShopperId, mTotalCost
from Orders
Order by Orders.mTotalCost

--3.查找在orderDetail表中vMessage为空值的行--
select *
from OrderDetail
where OrderDetail.vMessage is NULL

--4.查找玩具名字中有“Racer”字样的所有玩具的基本资料--
select *
from Toys
where Toys.vToyName like '%Racer%'

--5.根据2016年的玩具销售总数，查找“Pick of the Month”玩具的前五名玩具的ID--
select top 5 cToyId
from PickOfMonth
where PickOfMonth.iYear = '2016'
group by PickOfMonth.cToyId
order by sum(PickOfMonth.iTotalSold) desc

--6.根据OrderDetail表，查找玩具总价值大于￥50的定单的号码和玩具总价值--
select cOrderNo, SUM(mToyCost) as ToyCost
from OrderDetail
group by cOrderNo
having SUM(mToyCost) > 50

--7.查找一份包含所有装运信息的报表
--包括：Order Number, Shipment Date, Actual Delivery Date（shipment）, Days in Transit. 
--(提示：Days in Transit = Actual Delivery Date – Shipment Date)
select cOrderNo, dShipmentDate, dActualDeliveryDate, (dActualDeliveryDate-dShipmentDate) as Days_in_Transit 
from Shipment

--8.查找所有玩具的名称、商标和种类（Toy Name, Brand, Category）
select vToyName,cBrandName,cCategory   
from Toys, ToyBrand, Category
where Toys.cBrandId = ToyBrand.cBrandId and Toys.cCategoryId = Category.cCategoryId

--9.查找玩具的名称和所有玩具的购物车ID。如果玩具不在购物车中，也需在结果中出现
select vToyName, cCartId
from Toys left join ShoppingCart
on Toys.cToyId = ShoppingCart.cToyId

--10.以下列格式查找所有购物者的名字和他们的简称：（Initials, vFirstName, vLastName）
--例如Angela Smith的Initials为A.S
select SUBSTRING(vFirstName,1,1)+'.' +SUBSTRING(vLastName,1,1)as Initials, vFirstName, vLastName
from Shopper

--11.查找所有玩具的平均价格，并舍入到整数
--cast转换数据类型   round()截取
select cast(ROUND(AVG(mToyRate),0)as int)
from Toys

--12.查找所有购买者和收货人的名、姓、地址和所在城市，要求保留结果中的重复记录
--all保留所有重复的记录
select ALL s.vFirstName, s.vLastName, s.vAddress, s.cCity, r.vFirstName, r.vLastName, r.vAddress, r.cCity 
from Orders o, Shopper s, Recipient r
where o.cShopperId = s.cShopperId and o.cOrderNo = r.cOrderNo

--13.查找没有包装的所有玩具的名称。（要求用子查询实现）
select vToyName
from Toys
where cToyId in (
select cToyId
from OrderDetail
where OrderDetail.cWrapperId is NULL
)

--14.查找已收货定单的定单号码以及下定单的时间（要求用子查询实现）
select cOrderNo, dOrderDate
from Orders
where cOrderNo in(
	select cOrderNo
	from Orders
	where Orders.cOrderProcessed = 'Y'
) 

--15.查找一份基于Orderdetail的报表，包括cOrderNo,cToyId和mToyCost
--记录以cOrderNo升序排列，并计算每一笔定单的玩具总价值
select cOrderNo, cToyId
from OrderDetail
order by cOrderNo

select cOrderNo, sum(mToyCost) as ToyCost
from OrderDetail
group by cOrderNo
order by cOrderNo

--16.查找从来没有下过订单的顾客
select cShopperId
from Shopper
where cShopperId not in(
	select cShopperId
	from Orders
)

--17.删除“Largo”牌的所有玩具
--关闭外键约束
-- 禁用外键约束
ALTER TABLE ShoppingCart NOCHECK CONSTRAINT FK__ShoppingC__cToyI__4CA06362;

-- 删除 ShoppingCart 表中与 Largo 品牌关联的记录
delete from ShoppingCart
where cToyId IN (
    SELECT cToyId
    FROM Toys
    WHERE cBrandId IN (
        SELECT cBrandId
        FROM ToyBrand
        WHERE cBrandName = 'Largo'
    )
);
--删除OrderDetail表中与Largo相关记录
delete from OrderDetail
where cToyId in(
	select cToyId
	from Toys
	where cBrandId IN(
		SELECT cBrandId
        FROM ToyBrand
        WHERE cBrandName = 'Largo'
	)
)
--删除PickOfMonth表中与Largo相关记录
delete from PickOfMonth
where cToyId in(
	select cToyId
	from Toys
	where cBrandId IN(
		SELECT cBrandId
        FROM ToyBrand
        WHERE cBrandName = 'Largo'
	)
)

-- 启用外键约束
ALTER TABLE ShoppingCart CHECK CONSTRAINT FK__ShoppingC__cToyI__4CA06362;

-- 删除 Toys 表中与 Largo 品牌关联的记录
DELETE FROM Toys
WHERE cBrandId IN (
    SELECT cBrandId
    FROM ToyBrand
    WHERE cBrandName = 'Largo'
);



