SELECT
    c.nCharNo,
    c.sID,
    c.nLevel,
    c.nPlayMin,
    c.nMoney,
    ISNULL(cs.nClass, 0)
FROM dbo.tCharacter c
LEFT JOIN dbo.tCharacterShape cs ON c.nCharNo = cs.nCharNo
WHERE c.nUserNo = @p1 AND c.bDeleted = 0
ORDER BY c.nLevel DESC