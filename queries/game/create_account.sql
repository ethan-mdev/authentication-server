INSERT INTO tUser (sUserID, sUserPW, sUserName, bIsBlock, bIsDelete, nAuthID, sUserIP, dDate)
OUTPUT INSERTED.nUserNo
VALUES (@p1, @p2, @p1, 0, 0, 1, '0.0.0.0', GETDATE());