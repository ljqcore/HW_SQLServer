use GlobalToyz
go

drop procedure prcCharges
drop procedure prcHandlingCharges
go

--1.����һ����ΪprcCharges�Ĵ洢���̣�������ĳ�������ŵ�װ�˷��úͰ�װ����
create procedure prcCharges
	@orderNo char(6),@mShippingCharges money output, @mGiftWrapCharges money output
as 
begin
	select mShippingCharges, mGiftWrapCharges
	from Orders
	where @orderNo = Orders.cOrderNo
end
go

--2.����һ����ΪprcHandlingCharges�Ĺ��̣������ն����Ų���ʾ��Ӫ���á�PrchandlingCharges����Ӧʹ��prcCharges�������õ�װ�˷Ѻ���Ʒ��װ�ѡ�
--3.��ʾ����Ӫ����=װ�˷�+��Ʒ��װ��
create procedure prcHandlingCharges
	@oNo char(6), @handleCharges money output
as
begin
	declare @shippingCharges money
	declare @giftWrapCharges money

	--����preCharges�洢���� exec
	exec prcCharges @orderNo = @oNo, @mShippingCharges = @shippingCharges out, @mGiftWrapCharges = @giftWrapCharges out
	set @handleCharges = @shippingCharges + @giftWrapCharges
	--���ز���   
	select @handleCharges as HandlingCharges

end
go

--����
declare 
	@runcost money
begin 
	exec prcHandlingCharges '000001',@runcost output;
	Print '��Ӫ���ã�' + convert(char(10), @runcost);
end
go


--4.��OrderDetail�϶���һ��������������OrderDetail��������һ����¼ʱ���Զ��޸�Toys������ߵĿ��������siToyQoh��
create trigger OrderDetail_Insert
on OrderDetail
after insert
as 
begin
	update toys
	set siToyQoh = siToyQoh - OrderDetail.siQty  --��ȥ����������
	from Toys,OrderDetail
	where Toys.cToyId = OrderDetail.cToyId
end
go

--5.Orders����GlobalToyz���ݿ����һ�ź��ĵı������ű��������κθ��¶���������ɾ���ģ�����Ҫ��¼������
--�������ݿ���ƣ�Audit���Ļ���˼�롣Ҫ�����һ�ű�洢��Orders��ĸ��²�����
--���������ߡ�����ʱ�䡢�������͡�����ǰ�����ݡ����º�����ݡ���ƴ�����ʵ�ֶ�Orders������
--������洢��Ϣ
drop table OrderAudit
drop trigger Orders_Audit

create table OrderAudit(
	Audit INT IDENTITY(1,1) PRIMARY KEY, --��Ƽ�¼��Ψһ��ʶ
	OrderID char(6),  --���¶�����Ψһ��ʶ
	ActionType varchar(10),  --��������
	ActionDate Datetime, --����ʱ��
	UserID varchar(50),  --�����ߵ��û���ʶ
	
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
	--����
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
	
	--ɾ��
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

	--����
	if exists(select * from deleted)
	begin
		insert into OrderAudit(OrderID, ActionType, ActionDate, UserID, new_cOrderNo,new_dOrderDate,
                                new_cCartId, new_cShopperId, new_cShippingModeId,new_mShippingCharges,new_mGiftWrapCharges,
                                new_cOrderProcessed,new_mTotalCost,new_dExpDelDate)
		select d.cOrderNo,'UPDATE', GETDATE(), CURRENT_USER, d.*, i.*
		from deleted d  --inserted�洢���ɴ����������ĵ�ǰ���ڲ��롢���»�ɾ�����еĸ���
		join inserted i on d.cOrderNo = i.cOrderNo
	end
end
go

--�򻯺�ʹ��xml�������ʹ�Ÿ���ǰ�������
CREATE TABLE OrderAudit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY, -- ��Ƽ�¼��Ψһ��ʶ����������
    OrderID CHAR(6),-- �����µĶ�����Ψһ��ʶ��
    ActionType VARCHAR(10),--�������ͣ�������롢ɾ������¡�
    ActionDate DATETIME,--�������������ں�ʱ�䡣
    UserID VARCHAR(50),--ִ�в������û���ʶ��
    old_data XML,
    new_data XML
);

CREATE TRIGGER trg_OrderAudit
ON Orders
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- �������
	--FOR XML AUTOָ���������ת��ΪXMLʱʹ���Զ�Ԫ������
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO OrderAudit (OrderID, ActionType, ActionDate, UserID, old_data, new_data)
        SELECT i.cOrderNo, 'INSERT', GETDATE(), CURRENT_USER, (SELECT * FROM inserted FOR XML AUTO), NULL
        FROM inserted i;
    END;

    -- ���²���
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO OrderAudit (OrderID, ActionType, ActionDate, UserID, old_data, new_data)
        SELECT d.cOrderNo, 'UPDATE', GETDATE(), CURRENT_USER, (SELECT * FROM deleted FOR XML AUTO), (SELECT * FROM inserted FOR XML AUTO)
        FROM deleted d
        JOIN inserted i ON d.cOrderNo = i.cOrderNo;
    END;

    -- ɾ������
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO OrderAudit (OrderID, ActionType, ActionDate, UserID, old_data, new_data)
        SELECT d.cOrderNo, 'DELETE', GETDATE(), CURRENT_USER, (SELECT * FROM deleted FOR XML AUTO), NULL
        FROM deleted d;
    END;

END;




--python���ӻ�ͼ��
--��������Ĺ�ϵ
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

--���������Ʒ�ƵĹ�ϵ

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
