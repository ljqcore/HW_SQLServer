use GlobalToyz
go

drop procedure prcCharges
drop procedure prcHandlingCharges
go

--1.创建一个称为prcCharges的存储过程，它返回某个定单号的装运费用和包装费用
create procedure prcCharges
	@orderNo char(6),@mShippingCharges money output, @mGiftWrapCharges money output
as 
begin
	select mShippingCharges, mGiftWrapCharges
	from Orders
	where @orderNo = Orders.cOrderNo
end
go

--2.创建一个称为prcHandlingCharges的过程，它接收定单号并显示经营费用。PrchandlingCharges过程应使用prcCharges过程来得到装运费和礼品包装费。
--3.提示：经营费用=装运费+礼品包装费
create procedure prcHandlingCharges
	@oNo char(6), @handleCharges money output
as
begin
	declare @shippingCharges money
	declare @giftWrapCharges money

	--调用preCharges存储过程 exec
	exec prcCharges @orderNo = @oNo, @mShippingCharges = @shippingCharges out, @mGiftWrapCharges = @giftWrapCharges out
	set @handleCharges = @shippingCharges + @giftWrapCharges
	--返回参数   
	select @handleCharges as HandlingCharges

end
go

--测试
declare 
	@runcost money
begin 
	exec prcHandlingCharges '000001',@runcost output;
	Print '经营费用：' + convert(char(10), @runcost);
end
go


--4.在OrderDetail上定义一个触发器，当向OrderDetail表中新增一条记录时，自动修改Toys表中玩具的库存数量（siToyQoh）
create trigger OrderDetail_Insert
on OrderDetail
after insert
as 
begin
	update toys
	set siToyQoh = siToyQoh - OrderDetail.siQty  --减去库存玩具数量
	from Toys,OrderDetail
	where Toys.cToyId = OrderDetail.cToyId
end
go

--5.Orders表是GlobalToyz数据库里的一张核心的表，对这张表上做的任何更新动作（增、删、改）都需要记录下来，
--这是数据库审计（Audit）的基本思想。要求设计一张表存储对Orders表的更新操作，
--包括操作者、操作时间、操作类型、更新前的数据、更新后的数据。设计触发器实现对Orders表的审计
--创建表存储信息
drop table OrderAudit
drop trigger Orders_Audit

create table OrderAudit(
	Audit INT IDENTITY(1,1) PRIMARY KEY, --审计记录的唯一标识
	OrderID char(6),  --更新订单的唯一标识
	ActionType varchar(10),  --操作类型
	ActionDate Datetime, --操作时间
	UserID varchar(50),  --操作者的用户标识
	
	old_cOrderNo char(6),
	old_dOrderDate datetime,
	old_cCartId char(6),
    old_cShopperId char(6),
    old_cShippingModeId char(2),
    old_mShippingCharges money,
    old_mGiftWrapCharges money,
    old_cOrderProcessed char,
    old_mTotalCost money,
    old_dExpDelDate DateTime,
	
	new_cOrderNo char(6),
    new_dOrderDate datetime,
    new_cCartId char(6),
    new_cShopperId char(6),
    new_cShippingModeId char(2),
    new_mShippingCharges money,
    new_mGiftWrapCharges money,
    new_cOrderProcessed char,
    new_mTotalCost money,
    new_dExpDelDate DateTime
);
go

create trigger Orders_Audit
on Orders
after insert, update, delete
as 
begin
	--插入
	if exists(select * from inserted)
	begin
    insert into OrderAudit(OrderID, ActionType, ActionDate, UserID,
                        old_cOrderNo, old_dOrderDate, old_cCartId, old_cShopperId, old_cShippingModeId,
                        old_mShippingCharges, old_mGiftWrapCharges, old_cOrderProcessed, old_mTotalCost, old_dExpDelDate,
                        new_cOrderNo, new_dOrderDate, new_cCartId, new_cShopperId, new_cShippingModeId,
                        new_mShippingCharges, new_mGiftWrapCharges, new_cOrderProcessed, new_mTotalCost, new_dExpDelDate)
			select i.cOrderNo,
				   case when exists(select * from deleted d where d.cOrderNo=i.cOrderNo) then 'UPDATE' else 'INSERT' end as ActionType,
				   GETDATE(),
				   CURRENT_USER,
				   d.cOrderNo, d.dOrderDate, d.cCartId, d.cShopperId, d.cShippingModeId, d.mShippingCharges, d.mGiftWrapCharges, d.cOrderProcessed, d.mTotalCost, d.dExpDelDate,
				   i.cOrderNo, i.dOrderDate, i.cCartId, i.cShopperId, i.cShippingModeId, i.mShippingCharges, i.mGiftWrapCharges, i.cOrderProcessed, i.mTotalCost, i.dExpDelDate
			from inserted i
			left join deleted d on i.cOrderNo = d.cOrderNo
			where not exists (select * from deleted d where d.cOrderNo = i.cOrderNo)
			   or not exists (select * from inserted i where i.cOrderNo = d.cOrderNo)
	end
	
	--删除
	if exists(select * from deleted)
    begin
        insert into OrderAudit(OrderID, ActionType, ActionDate, UserID,
                                old_cOrderNo, old_dOrderDate, old_cCartId, old_cShopperId, old_cShippingModeId,
                                old_mShippingCharges, old_mGiftWrapCharges, old_cOrderProcessed, old_mTotalCost, old_dExpDelDate,
                                new_cOrderNo, new_dOrderDate, new_cCartId, new_cShopperId, new_cShippingModeId,
                                new_mShippingCharges, new_mGiftWrapCharges, new_cOrderProcessed, new_mTotalCost, new_dExpDelDate)
        select d.cOrderNo,'DELETE', GETDATE(), CURRENT_USER,
               d.cOrderNo, d.dOrderDate, d.cCartId, d.cShopperId, d.cShippingModeId, d.mShippingCharges, d.mGiftWrapCharges, d.cOrderProcessed, d.mTotalCost, d.dExpDelDate,
               null, null, null, null, null, null, null, null, null, null
        from deleted d
    end

	--更新
	if exists(select * from deleted)
	begin
		insert into OrderAudit(OrderID, ActionType, ActionDate, UserID, new_cOrderNo,new_dOrderDate,
                                new_cCartId, new_cShopperId, new_cShippingModeId,new_mShippingCharges,new_mGiftWrapCharges,
                                new_cOrderProcessed,new_mTotalCost,new_dExpDelDate)
		select d.cOrderNo,'UPDATE', GETDATE(), CURRENT_USER, d.*, i.*
		from deleted d  --inserted存储了由触发器操作的当前正在插入、更新或删除的行的副本
		join inserted i on d.cOrderNo = i.cOrderNo
	end
end
go

--简化后，使用xml数据类型存放更新前后的数据
CREATE TABLE OrderAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY, -- 审计记录的唯一标识（主键）。
    OrderID CHAR(6),-- 被更新的订单的唯一标识。
    ActionType VARCHAR(10),--操作类型，例如插入、删除或更新。
    ActionDate DATETIME,--操作发生的日期和时间。
    UserID VARCHAR(50),--执行操作的用户标识。
    old_data XML,
    new_data XML
);

CREATE TRIGGER trg_OrderAudit
ON Orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- 插入操作
	--FOR XML AUTO指定将结果集转换为XML时使用自动元素名称
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO OrderAudit (OrderID, ActionType, ActionDate, UserID, old_data, new_data)
        SELECT i.cOrderNo, 'INSERT', GETDATE(), CURRENT_USER, (SELECT * FROM inserted FOR XML AUTO), NULL
        FROM inserted i;
    END;

    -- 更新操作
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO OrderAudit (OrderID, ActionType, ActionDate, UserID, old_data, new_data)
        SELECT d.cOrderNo, 'UPDATE', GETDATE(), CURRENT_USER, (SELECT * FROM deleted FOR XML AUTO), (SELECT * FROM inserted FOR XML AUTO)
        FROM deleted d
        JOIN inserted i ON d.cOrderNo = i.cOrderNo;
    END;

    -- 删除操作
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO OrderAudit (OrderID, ActionType, ActionDate, UserID, old_data, new_data)
        SELECT d.cOrderNo, 'DELETE', GETDATE(), CURRENT_USER, (SELECT * FROM deleted FOR XML AUTO), NULL
        FROM deleted d;
    END;

END;




--python可视化图像
--玩具与地域的关系
CREATE TABLE Toys_City (
	cBrandName char(20),
	cCategory char(20),
    vToyName nchar(20),
    cCity char(15)
);


INSERT INTO Toys_City (cBrandName, cCategory, vToyName, cCity)
SELECT ToyBrand.cBrandName,Category.cCategory ,Toys.vToyName, Shopper.cCity
FROM Orders
JOIN OrderDetail ON Orders.cOrderNo = OrderDetail.cOrderNo
JOIN Shopper ON Orders.cShopperId = Shopper.cShopperId
JOIN Toys ON OrderDetail.cToyId = Toys.cToyId
JOIN ToyBrand ON Toys.cBrandId = ToyBrand.cBrandId
JOIN Category ON Toys.cCategoryId = Category.cCategoryId;

--城市与玩具品牌的关系

CREATE TABLE City_Brand (
  cCity CHAR(15),
  cBrandName CHAR(20),
  num INT,
  PRIMARY KEY (cCity, cBrandName)
);

INSERT INTO City_Brand (cCity, cBrandName, num)
SELECT cCity, cBrandName, COUNT(*) AS num
FROM Toys_City
GROUP BY cCity, cBrandName
ORDER BY cCity, num DESC;
