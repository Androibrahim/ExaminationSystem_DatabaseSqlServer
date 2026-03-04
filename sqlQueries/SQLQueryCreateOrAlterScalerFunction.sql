use ExaminationSystem


create function CoreSystem.fn_CheckUserRole (@UserId int  , @RoleId int)
returns bit
as  
begin 
	declare @isInRole bit  = 0 ; 
	
	IF EXISTS (
	select 1 
	from CoreSystem.UserRole as ur  
	where ur.UserId = @UserId AND ur.RoleId = @RoleId )
    begin
	set @isInRole = 1 ; 
	end

	return @isInRole
end



CREATE OR ALTER FUNCTION ExamSystem.fn_IsExamActive (@ExamId INT)
RETURNS BIT
AS
BEGIN
    DECLARE @IsActive BIT = 0;

    IF EXISTS (SELECT 1 FROM ExamSystem.Exam as e
        WHERE e.ExamId = @ExamId
          AND GETDATE() BETWEEN e.StartTime AND e.EndTime
    )
    SET @IsActive = 1;

    RETURN @IsActive;
END
GO
