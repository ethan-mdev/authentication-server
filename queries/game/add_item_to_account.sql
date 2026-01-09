DECLARE @RET INT;

EXEC dbo.usp_Charge_ItemInsert 
    @userNo = @p1,
    @orderNo = @p2,
    @goodsNo = @p3,
    @amount = @p4,
    @RET = @RET OUTPUT;

SELECT @RET AS result;
