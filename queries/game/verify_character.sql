SELECT nCharNo
FROM dbo.tCharacter 
WHERE sID = @p1 
  AND nUserNo = @p2 
  AND bDeleted = 0