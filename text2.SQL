--3����Orders��������1000�ʶ������ݣ�ע����������֮��Ĺ�ϵ--
use GlobalToyz
go

--�²���1000������--
DECLARE @i int = 11, @cOrderNo as char(6), @cToyId as char(6), @dOrderDate as datetime, @cShopperId as char(6), @cCartId as char(6),
@cShippingModeId as char(2), @mShippingCharges as money, @mGiftWrapCharges as money, @cOrderProcessed as char(1), @mTotalCost as money, @dExpDelDate as datetime, @siQty as smallint, @cWrapperId as char(3), @vMessage as varchar(256), @toycost as money, @minTotalCost as money, @sum as money, @shippingRate as money,
@coutryID as char(3), @wrapperRate as money, @GiftWrapper as char(1), @cToyRate as money, @iMaxDelay int;
WHILE (@i<=1011)
BEGIN
	--������
	--RIGHT:��ȡ���ַ������Ҳಿ�֣�Ҳ����ĩβ�����������������0��ֱ���ܳ���Ϊ6λ
	set @cOrderNo = (RIGHT('000000' + CAST(@i AS VARCHAR(6)), 6))

	--������������
	set @dOrderDate = DATEADD(hour, @i, '2023-05-19 00:00:00')

	--�ӱ���ѡ��һ�����ﳵid
	select @cCartId = cCartId
	from ShoppingCart
	order by newid()

	--�ӱ���ѡ��һ�����id����ߵ���
    select @cToyId = cToyId, @cToyRate = mToyRate
    from Toys
    order by newid()

	--�ӱ���ѡ��һ��������id
	select @cShopperId = cShopperId
	from Shopper
	order by newid()

	--�ӱ���ѡ��һ�������������
	select @cShippingModeId = cModeId
	from ShippingMode
	order by newid()

	--�ӱ����ҵ��������
	select @siQty = ShoppingCart.siQty
	from ShoppingCart
	where ShoppingCart.cToyId = @cToyId and ShoppingCart.cCartId = @cCartId 
	--set @siQty = CAST(rand() * 5 as int)

	--�����߼����Id�ɹ�����Idȷ��
	select @coutryID = Shopper.cCountryId
	from Shopper
	where Shopper.cShopperId = @cShopperId

	--ÿ����ߵ�ÿ������ĵ���
	select @shippingRate = mRatePerPound
	from ShippingRate
	where ShippingRate.cModeId = @cShippingModeId and ShippingRate.cCountryID = @coutryID

	--�����ܼ�=ÿ������ĵ���*�������
	set @mShippingCharges = @shippingRate * @siQty

	--����orderDetail��,�����ȡ����װ���ۺͰ�װ����Id
	select @wrapperRate = mWrapperRate, @cWrapperId = cWrapperId
	from Wrapper
	order by newid() 

	--�����Ƿ񱻴�����Y-�Ѵ���
	set @cOrderProcessed = 'Y' 
	
	--��ʶ����Ƿ���Ҫ��װ����  Y-��Ҫ   N-����Ҫ
	set @GiftWrapper = (SELECT CASE WHEN RAND() < 0.5 THEN 'Y' ELSE 'N' END)

	--��ߵİ�װ����Id
	set @cWrapperId = 
		case 
			when @GiftWrapper = 'Y' then @cWrapperId
			when @GiftWrapper = 'N' then NULL
		end

	--��ߵİ�װ��=��ߵ�����װ����*����
	set @mGiftWrapCharges =
        case
			when @GiftWrapper = 'Y' then @wrapperRate * @siQty
			when @GiftWrapper = 'N' then 0
        end
	
	--��߼�ֵ=��ߵ���*����
	--����������һ��һ��ֻ��Ҫ����һ��
	set @ToyCost = @cToyRate * @siQty

	--����ܷ���=��߼�ֵ+�������+��װ����
    set @mTotalCost = @ToyCost+ @mShippingCharges + @mGiftWrapCharges  

	--����ʱ�䣺����ӳ�ʱ����ShippingModeѰ��
	select @iMaxDelay
	from ShippingMode
	where @cShippingModeId = ShippingMode.iMaxDelDays
	set @dExpDelDate =  DATEADD(day, @iMaxDelay, '2023-05-19 00:00:00') --Ԥ�ƽ�������
	
	--�������ݵ�Orders��
	INSERT INTO Orders
	VALUES (@cOrderNo, @dOrderDate, @cCartId, @cShopperId, @cShippingModeId, @mShippingCharges,
	    @mGiftWrapCharges, @cOrderProcessed, @mTotalCost, @dExpDelDate)

	set @vMessage = NULL
	
	--�������ݵ�OrderDetail��
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

--ɾ�����ݿ�--
set nocount    on
USE master

SELECT session_id, login_name, host_name, program_name
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID('GlobalToyz');
ALTER DATABASE GlobalToyz SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
drop database GlobalToyz
go


--4.��Orders������������֮�󣬸���PickofMonth��--
INSERT INTO PickOfMonth(cToyId, siMonth, iYear, iTotalSold)
SELECT cToyId, MONTH(dOrderDate), YEAR(dOrderDate),sum(mToyCost)
FROM OrderDetail
JOIN Orders ON OrderDetail.cOrderNo = Orders.cOrderNo
GROUP BY cToyId, MONTH(dOrderDate), YEAR(dOrderDate)
GO


--ʵ�����������--

--1.��������California��Florida�ݵĹ˿͵������պ�emailID--
select vFirstName, vLastName, vEmailId
from Shopper
where Shopper.cState ='California' or Shopper.cState='Florida'

---2.���Ҷ������롢�˿�ID���������ܼ�ֵ�����Զ������ܼ�ֵ����������-
select cOrderNo,cShopperId, mTotalCost
from Orders
Order by Orders.mTotalCost

--3.������orderDetail����vMessageΪ��ֵ����--
select *
from OrderDetail
where OrderDetail.vMessage is NULL

--4.��������������С�Racer��������������ߵĻ�������--
select *
from Toys
where Toys.vToyName like '%Racer%'

--5.����2016�������������������ҡ�Pick of the Month����ߵ�ǰ������ߵ�ID--
select top 5 cToyId
from PickOfMonth
where PickOfMonth.iYear = '2016'
group by PickOfMonth.cToyId
order by sum(PickOfMonth.iTotalSold) desc

--6.����OrderDetail������������ܼ�ֵ���ڣ�50�Ķ����ĺ��������ܼ�ֵ--
select cOrderNo, SUM(mToyCost) as ToyCost
from OrderDetail
group by cOrderNo
having SUM(mToyCost) > 50

--7.����һ�ݰ�������װ����Ϣ�ı���
--������Order Number, Shipment Date, Actual Delivery Date��shipment��, Days in Transit. 
--(��ʾ��Days in Transit = Actual Delivery Date �C Shipment Date)
select cOrderNo, dShipmentDate, dActualDeliveryDate, (dActualDeliveryDate-dShipmentDate) as Days_in_Transit 
from Shipment

--8.����������ߵ����ơ��̱�����ࣨToy Name, Brand, Category��
select vToyName,cBrandName,cCategory   
from Toys, ToyBrand, Category
where Toys.cBrandId = ToyBrand.cBrandId and Toys.cCategoryId = Category.cCategoryId

--9.������ߵ����ƺ�������ߵĹ��ﳵID�������߲��ڹ��ﳵ�У�Ҳ���ڽ���г���
select vToyName, cCartId
from Toys left join ShoppingCart
on Toys.cToyId = ShoppingCart.cToyId

--10.�����и�ʽ�������й����ߵ����ֺ����ǵļ�ƣ���Initials, vFirstName, vLastName��
--����Angela Smith��InitialsΪA.S
select SUBSTRING(vFirstName,1,1)+'.' +SUBSTRING(vLastName,1,1)as Initials, vFirstName, vLastName
from Shopper

--11.����������ߵ�ƽ���۸񣬲����뵽����
--castת����������   round()��ȡ
select cast(ROUND(AVG(mToyRate),0)as int)
from Toys

--12.�������й����ߺ��ջ��˵������ա���ַ�����ڳ��У�Ҫ��������е��ظ���¼
--all���������ظ��ļ�¼
select ALL s.vFirstName, s.vLastName, s.vAddress, s.cCity, r.vFirstName, r.vLastName, r.vAddress, r.cCity 
from Orders o, Shopper s, Recipient r
where o.cShopperId = s.cShopperId and o.cOrderNo = r.cOrderNo

--13.����û�а�װ��������ߵ����ơ���Ҫ�����Ӳ�ѯʵ�֣�
select vToyName
from Toys
where cToyId in (
select cToyId
from OrderDetail
where OrderDetail.cWrapperId is NULL
)

--14.�������ջ������Ķ��������Լ��¶�����ʱ�䣨Ҫ�����Ӳ�ѯʵ�֣�
select cOrderNo, dOrderDate
from Orders
where cOrderNo in(
	select cOrderNo
	from Orders
	where Orders.cOrderProcessed = 'Y'
) 

--15.����һ�ݻ���Orderdetail�ı���������cOrderNo,cToyId��mToyCost
--��¼��cOrderNo�������У�������ÿһ�ʶ���������ܼ�ֵ
select cOrderNo, cToyId
from OrderDetail
order by cOrderNo

select cOrderNo, sum(mToyCost) as ToyCost
from OrderDetail
group by cOrderNo
order by cOrderNo

--16.���Ҵ���û���¹������Ĺ˿�
select cShopperId
from Shopper
where cShopperId not in(
	select cShopperId
	from Orders
)

--17.ɾ����Largo���Ƶ��������
--�ر����Լ��
-- �������Լ��
ALTER TABLE ShoppingCart NOCHECK CONSTRAINT FK__ShoppingC__cToyI__4CA06362;

-- ɾ�� ShoppingCart ������ Largo Ʒ�ƹ����ļ�¼
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
--ɾ��OrderDetail������Largo��ؼ�¼
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
--ɾ��PickOfMonth������Largo��ؼ�¼
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

-- �������Լ��
ALTER TABLE ShoppingCart CHECK CONSTRAINT FK__ShoppingC__cToyI__4CA06362;

-- ɾ�� Toys ������ Largo Ʒ�ƹ����ļ�¼
DELETE FROM Toys
WHERE cBrandId IN (
    SELECT cBrandId
    FROM ToyBrand
    WHERE cBrandName = 'Largo'
);


