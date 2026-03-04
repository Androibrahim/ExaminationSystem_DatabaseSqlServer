USE [ExaminationSystem]
GO

-- ============================================================
--  EXAMINATION SYSTEM  |  DATABASE OBJECTS IMPLEMENTATION
--  Part 3: Stored Procedures
-- ============================================================

-- ============================================================
--  SECTION 1 – User & Authentication Management
-- ============================================================

-- usp_CreateUserAccount
-- Creates a new UserAccount + assigns a role.
CREATE OR ALTER PROCEDURE CoreSystem.usp_CreateUserAccount
	@ExecutingUserId  int ,
    @Email    VARCHAR(50),
    @UserName VARCHAR(50),
    @Password VARCHAR(100),       -- plain text; hashed inside proc
    @RoleId int ,
	@NewUserId INT OUTPUT
AS 
BEGIN

	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN
		THROW 50001, 'Access Denied', 1;
		RETURN;
	END
    -- Validate role exists
    IF NOT EXISTS ( SELECT 1 FROM CoreSystem.Role WHERE RoleId = @RoleId )
    BEGIN
        THROW 50001, 'Invalid RoleId.', 1;
        RETURN;
    END

	BEGIN TRAN;

    INSERT INTO CoreSystem.UserAccount (Email, UserName, PasswordHashed)
    VALUES (@Email, @UserName, HASHBYTES('SHA2_256', @Password));

	SET @NewUserId = SCOPE_IDENTITY();

    INSERT INTO CoreSystem.UserRole (UserId, RoleId)
    VALUES (@NewUserId,@RoleId);

	COMMIT TRAN;
END
GO




-- usp_UpdateUserAccount
CREATE OR ALTER PROCEDURE CoreSystem.usp_UpdateUserAccount
	@ExecutingUserId  int ,
    @UserId      INT,
    @Email       VARCHAR(50) = NULL,
    @UserName    VARCHAR(50) = NULL
AS
BEGIN
	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN
		THROW 50001, 'Access Denied', 1;
		RETURN;
	END
	
    IF NOT EXISTS (SELECT 1 FROM CoreSystem.UserAccount WHERE UserId = @UserId)
    THROW 50001, 'user Not Found', 1; RETURN;

    UPDATE CoreSystem.UserAccount
    SET    Email    = ISNULL(@Email,    Email),
           UserName = ISNULL(@UserName, UserName)
    WHERE  UserId   = @UserId;
END
GO






-- usp_DeleteUserAccount
CREATE OR ALTER PROCEDURE CoreSystem.usp_DeleteUserAccount
	@ExecutingUserId  int ,
    @UserId INT
AS
BEGIN
	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN
		THROW 50001, 'Access Denied', 1;
		RETURN;
	END
    
    DELETE FROM CoreSystem.UserAccount WHERE UserId = @UserId;
END
GO




-- usp_LoginUser
-- Returns user info + role if credentials match; empty set if not.
CREATE OR ALTER PROCEDURE CoreSystem.usp_LoginUser
    @UserName VARCHAR(50),
    @Password VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        ua.UserId,
        ua.UserName,
        ua.Email,
        r.Name  AS RoleName
    FROM   CoreSystem.UserAccount  ua
    JOIN   CoreSystem.UserRole     ur  ON ur.UserId  = ua.UserId
    JOIN   CoreSystem.Role         r   ON r.RoleId   = ur.RoleId
    WHERE  ua.NormalizedUserName = UPPER(@UserName)
      AND  ua.PasswordHashed     = HASHBYTES('SHA2_256', @Password);
END
GO







-- usp_ChangePassword
CREATE OR ALTER PROCEDURE CoreSystem.usp_ChangePassword
    @UserId      INT,
    @OldPassword VARCHAR(100),
    @NewPassword VARCHAR(100)
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM CoreSystem.UserAccount
        WHERE  UserId = @UserId
          AND  PasswordHashed = HASHBYTES('SHA2_256', @OldPassword)
    )

    BEGIN throw 50001 , 'Not Exist user', 1; RETURN; END

    UPDATE CoreSystem.UserAccount
    SET    PasswordHashed = HASHBYTES('SHA2_256', @NewPassword)
    WHERE  UserId = @UserId;
END
GO







-- ============================================================
--  SECTION 2 – Instructor Management
-- ============================================================

-- usp_AddInstructor
CREATE OR ALTER PROCEDURE Academic.usp_AddInstructor
	@ExecutingUserId int ,
    @Name         NVARCHAR(50),
    @Phone        VARCHAR(50)  = NULL,
    @BirthDate    DATE,
    @Email        VARCHAR(50),
    @UserName     VARCHAR(50),
    @Password     VARCHAR(100),
    @NewInstructorId INT OUTPUT
AS
BEGIN

	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END
		
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @UserId INT;
        EXEC CoreSystem.usp_CreateUserAccount
			@ExecutingUserId = @ExecutingUserId,
            @Email    = @Email,
            @UserName = @UserName,
            @Password = @Password,
            @RoleId = 2,
            @NewUserId = @UserId OUTPUT;

        INSERT INTO Academic.Instructor (Name, Phone, BirthDate, UserId)
        VALUES (@Name, @Phone, @BirthDate, @UserId);

        SET @NewInstructorId = SCOPE_IDENTITY();
        COMMIT;

    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO




-- usp_UpdateInstructor
CREATE OR ALTER PROCEDURE Academic.usp_UpdateInstructor
	@ExecutingUserId int ,
    @InstructorId INT,
    @Name         NVARCHAR(50) = NULL,
    @Phone        VARCHAR(50)  = NULL,
    @BirthDate    DATE         = NULL
AS
BEGIN
	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    IF NOT EXISTS (SELECT 1 FROM Academic.Instructor WHERE InstructorId = @InstructorId)
    BEGIN throw 50001 , 'not found instructo' , 1 ; RETURN; END

    UPDATE Academic.Instructor
    SET    Name      = ISNULL(@Name,      Name),
           Phone     = ISNULL(@Phone,     Phone),
           BirthDate = ISNULL(@BirthDate, BirthDate)
    WHERE  InstructorId = @InstructorId;
END
GO




-- usp_DeleteInstructor
CREATE OR ALTER PROCEDURE Academic.usp_DeleteInstructor
	@ExecutingUserId int ,
    @InstructorId INT
AS
BEGIN
	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    -- Prevent deletion if instructor has active/future exams
    IF EXISTS (
        SELECT 1 FROM ExamSystem.Exam
        WHERE  InstructorId = @InstructorId
          AND  EndTime > GETDATE()
    )
    BEGIN
        throw 50001 , 'Cannot delete instructor: they have active or upcoming exams.', 1;
        RETURN;
    END

    DELETE FROM Academic.Instructor WHERE InstructorId = @InstructorId;
    -- UserAccount cascades via FK
END
GO




-- usp_AssignInstructorToCourse
CREATE OR ALTER PROCEDURE Academic.usp_AssignInstructorToCourse
    @ExecutingUserId int , 
    @InstructorId INT,
    @CourseId     INT,
    @ClassId      INT,
    @AcademicYear INT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    IF EXISTS (
        SELECT 1 FROM Academic.CourseOffering
        WHERE  CourseId = @CourseId AND ClassId = @ClassId AND AcademicYear = @AcademicYear
    )
    BEGIN
        -- Update existing assignment
        UPDATE Academic.CourseOffering
        SET    InstructorId = @InstructorId
        WHERE  CourseId = @CourseId AND ClassId = @ClassId AND AcademicYear = @AcademicYear;
    END
    ELSE
    BEGIN
        INSERT INTO Academic.CourseOffering (InstructorId, CourseId, ClassId, AcademicYear)
        VALUES (@InstructorId, @CourseId, @ClassId, @AcademicYear);
    END
END
GO




-- ============================================================
--  SECTION 3 – Student Management
-- ============================================================

-- usp_AddStudent
CREATE OR ALTER PROCEDURE Academic.usp_AddStudent
	@ExecutingUserId int ,
    @Name         NVARCHAR(50),
    @BirthDate    DATE,
    @ClassId      INT,
    @Email        VARCHAR(50),
    @UserName     VARCHAR(50),
    @Password     VARCHAR(100),
    @NewStudentId INT OUTPUT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @UserId INT;
        EXEC CoreSystem.usp_CreateUserAccount
			@ExecutingUserId = @ExecutingUserId,
            @Email    = @Email,
            @UserName = @UserName,
            @Password = @Password,
            @RoleId = 3,
            @NewUserId = @UserId OUTPUT;

        INSERT INTO Academic.Student (Name, BirthDate, ClassId, UserId)
        VALUES (@Name, @BirthDate, @ClassId, @UserId);

        SET @NewStudentId = SCOPE_IDENTITY();
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END
GO



-- usp_UpdateStudent
CREATE OR ALTER PROCEDURE Academic.usp_UpdateStudent
	@ExecutingUserId int ,
    @StudentId INT,
    @Name      NVARCHAR(50) = NULL,
    @BirthDate DATE         = NULL,
    @ClassId   INT          = NULL
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    IF NOT EXISTS (SELECT 1 FROM Academic.Student WHERE StudentId = @StudentId)
    BEGIN throw 50001,'Student not found.', 1; RETURN; END

    UPDATE Academic.Student
    SET    Name      = ISNULL(@Name,      Name),
           BirthDate = ISNULL(@BirthDate, BirthDate),
           ClassId   = ISNULL(@ClassId,   ClassId)
    WHERE  StudentId = @StudentId;
END
GO




-- usp_DeleteStudent
CREATE OR ALTER PROCEDURE Academic.usp_DeleteStudent
	@ExecutingUserId int ,
    @StudentId INT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    DELETE FROM Academic.Student WHERE StudentId = @StudentId;
END
GO



-- usp_AssignStudentToExam
CREATE OR ALTER PROCEDURE Academic.usp_AssignStudentToExam
	@ExecutingUserId int ,
    @StudentId INT,
    @ExamId    INT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END


	-- Check that Instructor owns the Exam
    IF NOT EXISTS (
        SELECT 1 FROM ExamSystem.Exam
        WHERE ExamId = @ExamId AND InstructorId = @ExecutingUserId )
    BEGIN THROW 50001, 'Access Denied - You do not own this exam.', 1; return; END

    IF NOT EXISTS (
        SELECT 1 FROM ExamSystem.StudentExam
        WHERE  StudentId = @StudentId AND ExamId = @ExamId
    )
    BEGIN
        INSERT INTO ExamSystem.StudentExam (StudentId, ExamId, IsAllow, IsComplete)
        VALUES (@StudentId, @ExamId, 1, 0);
    END
    ELSE
    BEGIN
        UPDATE ExamSystem.StudentExam
        SET    IsAllow = 1
        WHERE  StudentId = @StudentId AND ExamId = @ExamId;
    END
END
GO

-- we need to create function  AssignStudentToExam and set allow == false



-- ============================================================
--  SECTION 4 – Course & Academic Structure
-- ============================================================

-- usp_AddCourse
CREATE OR ALTER PROCEDURE Academic.usp_AddCourse
	@ExecutingUserId int ,
    @Name        NVARCHAR(50),
    @Description NVARCHAR(200) = NULL,
    @MaxDegree   INT,
    @MinDegree   INT,
    @NewCourseId INT OUTPUT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    IF @MinDegree >= @MaxDegree
    BEGIN throw 50001 ,'MinDegree must be less than MaxDegree.', 1; RETURN; END

    INSERT INTO Academic.Course (Name, Description, MaxDegree, MinDegree)
    VALUES (@Name, @Description, @MaxDegree, @MinDegree);

    SET @NewCourseId = SCOPE_IDENTITY();
END
GO






-- usp_UpdateCourse
CREATE OR ALTER PROCEDURE Academic.usp_UpdateCourse
	@ExecutingUserId int ,
    @CourseId    INT,
    @Name        NVARCHAR(50)  = NULL,
    @Description NVARCHAR(200) = NULL,
    @MaxDegree   INT           = NULL,
    @MinDegree   INT           = NULL
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    UPDATE Academic.Course
    SET    Name        = ISNULL(@Name,        Name),
           Description = ISNULL(@Description, Description),
           MaxDegree   = ISNULL(@MaxDegree,   MaxDegree),
           MinDegree   = ISNULL(@MinDegree,   MinDegree)
    WHERE  CourseId    = @CourseId;
END
GO





-- usp_DeleteCourse
CREATE OR ALTER PROCEDURE Academic.usp_DeleteCourse
	@ExecutingUserId int ,
    @CourseId INT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    IF EXISTS (SELECT 1 FROM ExamSystem.Exam WHERE CourseId = @CourseId AND EndTime > GETDATE())
    BEGIN throw 50001 , 'Cannot delete course: it has active exams.', 1 ; RETURN; END

    DELETE FROM Academic.Course WHERE CourseId = @CourseId;
END
GO




-- usp_AddBranch
CREATE OR ALTER PROCEDURE CoreSystem.usp_AddBranch
	@ExecutingUserId int ,
    @Name         NVARCHAR(50),
    @DepartmentId INT,
    @NewBranchId  INT OUTPUT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END


    INSERT INTO CoreSystem.Branch (Name, DepartmentId) VALUES (@Name, @DepartmentId);
    SET @NewBranchId = SCOPE_IDENTITY();
END
GO


-- usp_AddDepartment
CREATE OR ALTER PROCEDURE CoreSystem.usp_AddDepartment
	@ExecutingUserId int ,
    @Name              NVARCHAR(50),
    @NewDepartmentId   INT OUTPUT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    INSERT INTO CoreSystem.Department (Name) VALUES (@Name);
    SET @NewDepartmentId = SCOPE_IDENTITY();
END
GO


-- usp_AddTrack
CREATE OR ALTER PROCEDURE CoreSystem.usp_AddTrack
	@ExecutingUserId int ,
    @Name        NVARCHAR(50),
    @BranchId    INT,
    @NewTrackId  INT OUTPUT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    INSERT INTO CoreSystem.Track (Name, BranchId) VALUES (@Name, @BranchId);
    SET @NewTrackId = SCOPE_IDENTITY();
END
GO


-- usp_AddIntake
CREATE OR ALTER PROCEDURE Academic.usp_AddIntake
	@ExecutingUserId int ,
    @Name         NVARCHAR(50),
    @MaxNoStudent INT,
    @StartDate    DATE = NULL,
    @EndDate      DATE = NULL,
    @TrackId      INT,
    @NewIntakeId  INT OUTPUT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 1) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

    INSERT INTO Academic.Intake (Name, MaxNoStudent, StartDate, EndDate, TrackId)
    VALUES (@Name, @MaxNoStudent, @StartDate, @EndDate, @TrackId);
    SET @NewIntakeId = SCOPE_IDENTITY();
END
GO

-- ============================================================
--  SECTION 5 – Question Pool Management
-- ============================================================

-- usp_AddQuestion
CREATE OR ALTER PROCEDURE ExamSystem.usp_AddQuestion
    @ExecutingUserId int ,
    @Question        NVARCHAR(1000),
    @QuestionTypeId  INT,
    @CourseId        INT,
    @NewQuestionId   INT OUTPUT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

	--Check Instructor teaches this Course
    IF NOT EXISTS ( SELECT 1 FROM Academic.CourseOffering as co
        WHERE co.InstructorId = @ExecutingUserId AND co.CourseId = @CourseId )
    BEGIN THROW 50001, 'Access Denied - You do not teach this course.', 1; return;  END
        
    INSERT INTO ExamSystem.QuestionPool (Question, QustionTypeId, CourseId)
    VALUES (@Question, @QuestionTypeId, @CourseId);
    SET @NewQuestionId = SCOPE_IDENTITY();
END
GO


-- usp_UpdateQuestion
CREATE OR ALTER PROCEDURE ExamSystem.usp_UpdateQuestion
	@ExecutingUserId int ,
    @QuestionId      INT,
    @Question        NVARCHAR(1000) = NULL,
    @QuestionTypeId  INT            = NULL
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

	--Check Instructor teaches this Course when updating question
    IF NOT EXISTS (SELECT 1 FROM ExamSystem.QuestionPool qp
    JOIN Academic.CourseOffering co ON co.CourseId = qp.CourseId
    WHERE qp.QuestionId = @QuestionId AND co.InstructorId = @ExecutingUserId )
    BEGIN THROW 50001, 'Access Denied - You do not teach this course.', 1; return;  END

    -- Prevent update if question is in an active exam
    IF EXISTS (
        SELECT 1 FROM ExamSystem.ExamQuestions eq
        JOIN   ExamSystem.Exam e ON e.ExamId = eq.ExamId
        WHERE  eq.QuestionId = @QuestionId AND e.EndTime > GETDATE()
    )
    BEGIN throw 50001, 'Question is in an active exam and cannot be modified.',  1; RETURN; END

    UPDATE ExamSystem.QuestionPool
    SET    Question      = ISNULL(@Question,       Question),
           QustionTypeId = ISNULL(@QuestionTypeId, QustionTypeId)
    WHERE  QuestionId    = @QuestionId;
END
GO





-- usp_DeleteQuestion
CREATE OR ALTER PROCEDURE ExamSystem.usp_DeleteQuestion
	@ExecutingUserId int ,
    @QuestionId INT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END


	--Check Instructor teaches this Course when deleteting question
    IF NOT EXISTS (SELECT 1 FROM ExamSystem.QuestionPool qp
    JOIN Academic.CourseOffering co ON co.CourseId = qp.CourseId
    WHERE qp.QuestionId = @QuestionId AND co.InstructorId = @ExecutingUserId )
    BEGIN THROW 50001, 'Access Denied - You do not teach this course.', 1; return;  END


    IF EXISTS (
        SELECT 1 FROM ExamSystem.ExamQuestions eq
        JOIN   ExamSystem.Exam e ON e.ExamId = eq.ExamId
        WHERE  eq.QuestionId = @QuestionId AND e.EndTime > GETDATE()
    )
    BEGIN throw 50001 ,'Cannot delete: question is used in an active or upcoming exam.', 1; RETURN; END

    DELETE FROM ExamSystem.QuestionPool WHERE QuestionId = @QuestionId;
END
GO





-- usp_AddChoice
CREATE OR ALTER PROCEDURE ExamSystem.usp_AddChoice
	@ExecutingUserId int ,
    @QuestionId  INT,
    @ChoiceTxt   NVARCHAR(500),
    @IsCorrect   BIT,
    @NewChoiceId INT OUTPUT
AS
BEGIN
    
	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END


	--Check Instructor teaches this Course when adding choice
    IF NOT EXISTS (SELECT 1 FROM ExamSystem.QuestionPool qp
    JOIN Academic.CourseOffering co ON co.CourseId = qp.CourseId
    WHERE qp.QuestionId = @QuestionId AND co.InstructorId = @ExecutingUserId )
    BEGIN THROW 50001, 'Access Denied - You do not teach this course.', 1; return;  END


    INSERT INTO ExamSystem.Choice (ChoiceTxt, IsCorrect, QuestionId)
    VALUES (@ChoiceTxt, @IsCorrect, @QuestionId);
    SET @NewChoiceId = SCOPE_IDENTITY();
END
GO



-- usp_UpdateChoice
CREATE OR ALTER PROCEDURE dbo.usp_UpdateChoice
	@ExecutingUserId int ,
    @ChoiceId   INT,
    @ChoiceTxt  NVARCHAR(500) = NULL,
    @IsCorrect  BIT           = NULL
AS
BEGIN

	IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END


-- Check Instructor teaches the course of this choice
	IF NOT EXISTS (SELECT 1 FROM ExamSystem.Choice c
		JOIN ExamSystem.QuestionPool qp ON qp.QuestionId = c.QuestionId
		JOIN Academic.CourseOffering co ON co.CourseId = qp.CourseId
		WHERE c.ChoiceId = @ChoiceId AND co.InstructorId = @ExecutingUserId )
	BEGIN  THROW 50001, 'Access Denied - You do not teach this course.', 1; RETURN;  END

    UPDATE ExamSystem.Choice
    SET    ChoiceTxt = ISNULL(@ChoiceTxt, ChoiceTxt),
           IsCorrect = ISNULL(@IsCorrect, IsCorrect)
    WHERE  ChoiceId  = @ChoiceId;
END
GO


-- usp_DeleteChoice
CREATE OR ALTER PROCEDURE ExamSystem.usp_DeleteChoice
	@ExecutingUserId int ,
    @ChoiceId INT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END


-- Check Instructor teaches the course of this choice
	IF NOT EXISTS (SELECT 1 FROM ExamSystem.Choice c
		JOIN ExamSystem.QuestionPool qp ON qp.QuestionId = c.QuestionId
		JOIN Academic.CourseOffering co ON co.CourseId = qp.CourseId
		WHERE c.ChoiceId = @ChoiceId AND co.InstructorId = @ExecutingUserId )
	BEGIN  THROW 50001, 'Access Denied - You do not teach this course.', 1; RETURN;  END

    DELETE FROM ExamSystem.Choice WHERE ChoiceId = @ChoiceId;
END
GO






-- ============================================================
--  SECTION 6 – Exam Management
-- ============================================================

-- usp_CreateExam
CREATE OR ALTER PROCEDURE ExamSystem.usp_CreateExam
	@ExecutingUserId int ,
    @AcademicYear INT,
    @StartTime    DATETIME2,
    @EndTime      DATETIME2,
    @TotalTime    TIME,
    @TotalDegree  INT,
    @ExamTypeId   INT,
    @CourseId     INT,
    @ClassId      INT,
    @InstructorId INT,
    @NewExamId    INT OUTPUT
AS
BEGIN

    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END


	--Check Instructor teaches this Course
    IF NOT EXISTS ( SELECT 1 FROM Academic.CourseOffering as co
        WHERE co.InstructorId = @ExecutingUserId AND co.CourseId = @CourseId )
    BEGIN THROW 50001, 'Access Denied - You do not teach this course.', 1; return;  END


    -- Validate TotalDegree vs Course MaxDegree
    DECLARE @MaxDeg INT;
    SELECT @MaxDeg = MaxDegree FROM Academic.Course WHERE CourseId = @CourseId;
    IF @TotalDegree > @MaxDeg
    BEGIN throw 50001 , 'TotalDegree (%d) exceeds Course MaxDegree (%d).', 1; RETURN;  END

    INSERT INTO ExamSystem.Exam
        (AcademicYear, StartTime, EndTime, TotalTime, TotalDegree, ExamTypeId, CourseId, ClassId, InstructorId)
    VALUES
        (@AcademicYear, @StartTime, @EndTime, @TotalTime, @TotalDegree, @ExamTypeId, @CourseId, @ClassId, @InstructorId);

    SET @NewExamId = SCOPE_IDENTITY();
END
GO




-- usp_UpdateExam
CREATE OR ALTER PROCEDURE ExamSystem.usp_UpdateExam
	@ExecutingUserId int ,
    @ExamId      INT,
    @StartTime   DATETIME2 = NULL,
    @EndTime     DATETIME2 = NULL,
    @TotalTime   TIME      = NULL,
    @TotalDegree INT       = NULL,
    @ExamTypeId  INT       = NULL
AS
BEGIN

    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

	-- check if executing instructor who pu exam
	if not exists (select 1 from ExamSystem.Exam as e 
	where e.ExamId =@ExamId and e.InstructorId =@ExecutingUserId  )
	begin throw 50001 , 'this instructor not put this exam' ,1 ; return ; end


    -- Cannot modify after exam has started
    IF EXISTS (SELECT 1 FROM ExamSystem.Exam WHERE ExamId = @ExamId AND StartTime <= GETDATE())
    BEGIN throw 50001 , 'Exam has already started and cannot be modified.', 1; RETURN; END

    UPDATE ExamSystem.Exam
    SET    StartTime   = ISNULL(@StartTime,   StartTime),
           EndTime     = ISNULL(@EndTime,     EndTime),
           TotalTime   = ISNULL(@TotalTime,   TotalTime),
           TotalDegree = ISNULL(@TotalDegree, TotalDegree),
           ExamTypeId  = ISNULL(@ExamTypeId,  ExamTypeId)
    WHERE  ExamId = @ExamId;
END
GO

-- usp_DeleteExam
CREATE OR ALTER PROCEDURE ExamSystem.usp_DeleteExam
	@ExecutingUserId int ,
    @ExamId INT
AS
BEGIN
    IF [CoreSystem].[fn_CheckUserRole](@ExecutingUserId, 2) = 0
	BEGIN THROW 50001, 'Access Denied', 1; RETURN; 	END

	-- check if executing instructor who pu exam
	if not exists (select 1 from ExamSystem.Exam as e 
	where e.ExamId =@ExamId and e.InstructorId =@ExecutingUserId  )
	begin throw 50001 , 'this instructor not put this exam' ,1 ; return ; end

    IF EXISTS (
        SELECT 1 FROM ExamSystem.StudentExam
        WHERE  ExamId = @ExamId AND IsComplete = 1
    )
    BEGIN throw 50001 , 'Cannot delete: students have already completed this exam.',  1; RETURN; END

    DELETE FROM ExamSystem.Exam WHERE ExamId = @ExamId;
END
GO



-- usp_GenerateExamQuestions_Random
-- Randomly selects N questions of each type and inserts into ExamQuestions.
-- Instructor must still set degrees via usp_SetQuestionDegree.

CREATE OR ALTER PROCEDURE ExamSystem.usp_GenerateExamQuestions_Random
    @ExecutingUserId INT,
    @ExamId          INT,
    @MCQ_Count       INT = 0,
    @TF_Count        INT = 0
AS
BEGIN
    SET XACT_ABORT ON;

    -- Role Check
    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 2) = 0
    BEGIN  THROW 50001, 'Access Denied', 1; return;  END

    DECLARE @CourseId INT;
    -- Ownership + get CourseId
    SELECT @CourseId = CourseId FROM ExamSystem.Exam
    WHERE ExamId = @ExamId AND InstructorId = @ExecutingUserId;

    IF @CourseId IS NULL
    BEGIN THROW 50002, 'Access Denied - You do not own this exam.', 1; return ; END;


	DECLARE @Available TABLE ( QustionTypeId INT PRIMARY KEY, AvailableCount INT );

	INSERT INTO @Available (QustionTypeId, AvailableCount)
	SELECT qp.QustionTypeId ,COUNT(*) AS AvailableCount
	FROM ExamSystem.QuestionPool qp
	WHERE qp.CourseId = @CourseId
	  AND NOT EXISTS (SELECT 1 FROM ExamSystem.ExamQuestions eq
					  WHERE eq.ExamId = @ExamId AND eq.QuestionId = qp.QuestionId )
	GROUP BY qp.QustionTypeId;

	DECLARE @AvailableMCQ   INT = ISNULL((SELECT AvailableCount FROM @Available WHERE QustionTypeId = 1), 0);
	DECLARE @AvailableTF    INT = ISNULL((SELECT AvailableCount FROM @Available WHERE QustionTypeId = 2), 0);

	IF @AvailableMCQ < @MCQ_Count
		THROW 50001, 'Not enough MCQ questions available.', 1;

	IF @AvailableTF < @TF_Count
		THROW 50001, 'Not enough T&F questions available.', 1;



    BEGIN TRAN;

    -- MCQ
    INSERT INTO ExamSystem.ExamQuestions (ExamId, QuestionId, QuestionDegree)
    SELECT TOP (@MCQ_Count) @ExamId, qp.QuestionId, 0
    FROM ExamSystem.QuestionPool qp
    WHERE qp.CourseId = @CourseId
      AND qp.QustionTypeId = 1   -- MCQ TypeId
      AND NOT EXISTS ( SELECT 1 FROM ExamSystem.ExamQuestions eq
                       WHERE eq.ExamId = @ExamId AND eq.QuestionId = qp.QuestionId )    
    ORDER BY NEWID();

    -- TF
    INSERT INTO ExamSystem.ExamQuestions (ExamId, QuestionId, QuestionDegree)
    SELECT TOP (@TF_Count) @ExamId, qp.QuestionId, 0
    FROM ExamSystem.QuestionPool qp
    WHERE qp.CourseId = @CourseId
      AND qp.QustionTypeId = 2   -- TF TypeId
      AND NOT EXISTS (SELECT 1 FROM ExamSystem.ExamQuestions eq
                      WHERE eq.ExamId = @ExamId AND eq.QuestionId = qp.QuestionId )
    ORDER BY NEWID();

    COMMIT;
END
GO







-- usp_GenerateExamQuestions_Manual
-- Instructor passes a comma-separated list of QuestionIds.
-- Uses a STRING_SPLIT approach.

CREATE OR ALTER PROCEDURE ExamSystem.usp_GenerateExamQuestions_Manual
    @ExecutingUserId INT,
    @ExamId          INT,
    @QuestionIdList  NVARCHAR(MAX)   -- e.g. '1,2,3,4'
AS
BEGIN
    SET XACT_ABORT ON;
    -- 1️⃣ Role Check (Instructor = 2)
    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 2) = 0
    BEGIN THROW 50001, 'Access Denied', 1; END

    DECLARE @CourseId INT;
    -- Ownership + Get CourseId
    SELECT @CourseId = CourseId FROM ExamSystem.Exam
    WHERE ExamId = @ExamId AND InstructorId = @ExecutingUserId;

    IF @CourseId IS NULL
    BEGIN  THROW 50002, 'Access Denied - You do not own this exam.', 1; END

    --  Convert list safely into table
    DECLARE @InputQuestions TABLE( QuestionId INT PRIMARY KEY );
    INSERT INTO @InputQuestions (QuestionId)
    SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
    FROM STRING_SPLIT(@QuestionIdList, ',')
    WHERE TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;


    -- Validate all questions belong to course
    IF EXISTS (SELECT 1 FROM @InputQuestions iq
        LEFT JOIN ExamSystem.QuestionPool qp ON qp.QuestionId = iq.QuestionId
        WHERE qp.QuestionId IS NULL OR qp.CourseId <> @CourseId )
    BEGIN THROW 50003, 'One or more questions are invalid or not in this course.', 1;END

    BEGIN TRAN;

    -- Insert only non-existing questions
    INSERT INTO ExamSystem.ExamQuestions (ExamId, QuestionId, QuestionDegree)
    SELECT @ExamId, iq.QuestionId, 0 FROM @InputQuestions iq
    WHERE NOT EXISTS ( SELECT 1 FROM ExamSystem.ExamQuestions eq
                       WHERE eq.ExamId = @ExamId AND eq.QuestionId = iq.QuestionId
    );

    COMMIT;
END
GO





-- usp_SetQuestionDegree
-- Sets the marks for a single question in an exam.
-- Validates cumulative total does not exceed Course MaxDegree.
CREATE OR ALTER PROCEDURE ExamSystem.usp_SetQuestionDegree
    @ExecutingUserId INT,
    @ExamId          INT,
    @QuestionId      INT,
    @QuestionDegree  INT
AS
BEGIN
    SET XACT_ABORT ON;

    -- Role Check (Instructor = 2)
    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 2) = 0
    BEGIN THROW 50001, 'Access Denied', 1;   END

    DECLARE @CourseId INT , @MaxDeg INT ,@CurrentTotal INT ;

    --Ownership + Get CourseId
    SELECT @CourseId = CourseId FROM ExamSystem.Exam
    WHERE ExamId = @ExamId AND InstructorId = @ExecutingUserId;

    IF @CourseId IS NULL
    BEGIN THROW 50002, 'Access Denied - You do not own this exam.', 1;  END

    --Validate question exists in exam
    IF NOT EXISTS (SELECT 1 FROM ExamSystem.ExamQuestions
        WHERE ExamId = @ExamId AND QuestionId = @QuestionId )
    BEGIN THROW 50003, 'Question is not assigned to this exam.', 1;  END

    -- 4️⃣ Prevent negative degree
    IF @QuestionDegree < 0
    BEGIN  THROW 50004, 'Question degree cannot be negative.', 1; END
       
    --Get Course MaxDegree
    SELECT @MaxDeg = MaxDegree FROM Academic.Course WHERE CourseId = @CourseId;

    --Calculate current total excluding this question
    SELECT @CurrentTotal = ISNULL(SUM(QuestionDegree), 0)
    FROM ExamSystem.ExamQuestions
    WHERE ExamId = @ExamId AND QuestionId <> @QuestionId;

    --Validate total does not exceed course max
    IF (@CurrentTotal + @QuestionDegree) > @MaxDeg
    BEGIN THROW 50005,'Total exam degree would exceed Course MaxDegree.', 1; END

    BEGIN TRAN;
    UPDATE ExamSystem.ExamQuestions
    SET QuestionDegree = @QuestionDegree
    WHERE ExamId = @ExamId AND QuestionId = @QuestionId;
    COMMIT;
END
GO


-- ============================================================
--  SECTION 7 – Exam Taking & Grading
-- ============================================================


-- usp_SubmitStudentAnswer
-- Records a student's answer for one question.
-- Validates exam is active, student is allowed, and not already answered.

CREATE OR ALTER PROCEDURE ExamSystem.usp_SubmitStudentAnswer
	@ExecutingUserId INT,
    @StudentExamId INT,
    @QuestionId    INT,
    @ChoiceId      INT = NULL   
AS
BEGIN

    -- Role Check (Instructor = 2)
    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 3) = 0
    BEGIN THROW 50001, 'Access Denied', 1;   END

    SET XACT_ABORT ON;

    DECLARE @ExamId INT;
    DECLARE @IsCorrect BIT = NULL;
    DECLARE @GivinMark INT = NULL;
    DECLARE @QuestionDegree INT;
    DECLARE @QuestionTypeId INT;

    --Get ExamId + Check Student Allowed
    SELECT @ExamId = ExamId FROM ExamSystem.StudentExam
    WHERE StudentExamId = @StudentExamId AND IsAllow = 1;

    IF @ExamId IS NULL
        THROW 50001, 'Student is not authorised to take this exam.', 1;

    --Check Exam Active
    IF ExamSystem.fn_IsExamActive(@ExamId) = 0
        THROW 50002, 'The exam is not currently active.', 1;

    --Ensure Question belongs to this Exam
    IF NOT EXISTS (SELECT 1 FROM ExamSystem.ExamQuestions
        WHERE ExamId = @ExamId AND QuestionId = @QuestionId )
    THROW 50003, 'Question is not part of this exam.', 1;

    --Prevent duplicate answer
    IF EXISTS (SELECT 1 FROM ExamSystem.StudentAnswer
        WHERE StudentExamId = @StudentExamId AND QuestionId = @QuestionId )
    THROW 50004, 'Answer already submitted for this question.', 1;

    --Get Question Type + Degree
    SELECT 
        @QuestionTypeId = qp.QustionTypeId,
        @QuestionDegree = eq.QuestionDegree
    FROM ExamSystem.QuestionPool qp
    JOIN ExamSystem.ExamQuestions eq 
        ON eq.QuestionId = qp.QuestionId
    WHERE qp.QuestionId = @QuestionId
      AND eq.ExamId = @ExamId;

    BEGIN TRAN;

    -- Auto-grading for MCQ / TF
    IF @QuestionTypeId IN (1,2)  -- MCQ / T&F
    BEGIN
        -- Validate choice belongs to question
        IF NOT EXISTS ( SELECT 1 FROM ExamSystem.Choice
            WHERE ChoiceId = @ChoiceId AND QuestionId = @QuestionId )
        THROW 50005, 'Invalid choice for this question.', 1;

        SELECT @IsCorrect = IsCorrect
        FROM ExamSystem.Choice
        WHERE ChoiceId = @ChoiceId;

        IF @IsCorrect = 1
            SET @GivinMark = @QuestionDegree;
        ELSE
            SET @GivinMark = 0;
    END

    --Insert Answer
    INSERT INTO ExamSystem.StudentAnswer
        (IsCorrect, GivinMark, StudentExamId, QuestionId, ChoiceId)
    VALUES
        (@IsCorrect, @GivinMark, @StudentExamId, @QuestionId, @ChoiceId);

    COMMIT;
END
GO



-- usp_AutoGradeExam
-- Marks all MCQ/T&F answers for a completed exam.
-- Sets GivinMark = QuestionDegree for correct, 0 for wrong.
CREATE OR ALTER PROCEDURE ExamSystem.usp_AutoGradeExam
	@ExecutingUserId INT,
    @ExamId INT
AS
BEGIN
    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 1) = 0
    BEGIN THROW 50001, 'Access Denied', 1;   END

    -- Recalculate all MCQ & T/F answers for this exam

    UPDATE sa
    SET
        sa.IsCorrect =
            CASE 
                WHEN ch.IsCorrect = 1 THEN 1
                WHEN ch.IsCorrect = 0 THEN 0
                ELSE NULL
            END,

        sa.GivinMark =
            CASE 
                WHEN ch.IsCorrect = 1 THEN eq.QuestionDegree
                WHEN ch.IsCorrect = 0 THEN 0
                ELSE NULL
            END

    FROM   ExamSystem.StudentAnswer   sa
    JOIN   ExamSystem.StudentExam     se  ON se.StudentExamId = sa.StudentExamId
    JOIN   ExamSystem.Choice          ch  ON ch.ChoiceId      = sa.ChoiceId
                                         AND ch.QuestionId    = sa.QuestionId
    JOIN   ExamSystem.QuestionPool    qp  ON qp.QuestionId    = sa.QuestionId
    JOIN   ExamSystem.QustionType     qt  ON qt.QustionTypeId = qp.QustionTypeId
    JOIN   ExamSystem.ExamQuestions   eq  ON eq.ExamId        = se.ExamId
                                         AND eq.QuestionId    = sa.QuestionId
    WHERE  se.ExamId = @ExamId
       AND qt.QustionTypeId IN (1, 2);

END
GO

-- usp_CalculateStudentResult
-- Sums all GivinMark values for a student's exam, stores in StudentExam.TotalDegree,
-- and marks the exam as complete.
CREATE OR ALTER PROCEDURE ExamSystem.usp_CalculateExamResults
    @ExecutingUserId INT,
    @ExamId INT
AS
BEGIN

    -- Authorization Check
    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 1) = 0
    BEGIN THROW 50001, 'Access Denied', 1; END

    ;WITH StudentTotals AS
    (
        SELECT 
            se.StudentExamId,
            ISNULL(SUM(sa.GivinMark), 0) AS Total
        FROM   ExamSystem.StudentExam se
        LEFT JOIN ExamSystem.StudentAnswer sa
               ON sa.StudentExamId = se.StudentExamId
        WHERE  se.ExamId = @ExamId
        GROUP BY se.StudentExamId
    )

    UPDATE se
    SET    se.TotalDegree = st.Total,
           se.IsComplete  = 1
    FROM   ExamSystem.StudentExam se
    JOIN   StudentTotals st 
           ON st.StudentExamId = se.StudentExamId;

END
GO

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- ============================================================
--  SECTION 8 – Search & Display
-- ============================================================

-- usp_SearchStudents
-- Flexible search with optional filters.
CREATE OR ALTER PROCEDURE Academic.usp_SearchStudents
	@ExecutingUserId INT,
    @DepartmentId INT = NULL,
    @BranchId     INT = NULL,
    @TrackId      INT = NULL,
    @IntakeId     INT = NULL,
    @ClassId      INT = NULL,
    @Name         NVARCHAR(50) = NULL
AS
BEGIN

    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 1) = 0
    BEGIN THROW 50001, 'Access Denied', 1; END


    SELECT *
    FROM Academic.vw_AllStudents
    WHERE  (@DepartmentId IS NULL OR DepartmentId = @DepartmentId)
      AND  (@BranchId     IS NULL OR BranchId = @BranchId)
      AND  (@TrackId      IS NULL OR TrackId = @TrackId)
      AND  (@IntakeId     IS NULL OR IntakeId = @IntakeId)
      AND  (@ClassId      IS NULL OR ClassId = @ClassId)
      AND  (@Name         IS NULL OR StudentName LIKE '%' + @Name + '%');
END
GO

-- usp_SearchExamsByInstructor
CREATE OR ALTER PROCEDURE ExamSystem.usp_SearchExamsByInstructor
	@ExecutingUserId INT,
    @InstructorId INT,
    @CourseId     INT  = NULL
AS
BEGIN
    IF CoreSystem.fn_CheckUserRole(@ExecutingUserId, 1) = 0
    BEGIN THROW 50001, 'Access Denied', 1; END

    SELECT *
    FROM dbo.vw_ExamSummary
    WHERE InstructorId = @InstructorId
      AND (@CourseId IS NULL OR CourseId = @CourseId);
END
GO


-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

-- usp_GetStudentExamHistory
CREATE OR ALTER PROCEDURE dbo.usp_GetStudentExamHistory
    @StudentId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM   dbo.vw_StudentExamResults
    WHERE  StudentId = @StudentId
    ORDER BY ExamId DESC;
END
GO

-- usp_GetCourseQuestionPool
CREATE OR ALTER PROCEDURE dbo.usp_GetCourseQuestionPool
    @CourseId       INT,
    @QuestionTypeId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        qp.QuestionId,
        qp.Question,
        qt.[name]   AS QuestionType,
        ch.ChoiceId,
        ch.ChoiceTxt,
        ch.IsCorrect
    FROM   ExamSystem.QuestionPool  qp
    JOIN   ExamSystem.QustionType   qt  ON qt.QustionTypeId = qp.QustionTypeId
    LEFT JOIN ExamSystem.Choice     ch  ON ch.QuestionId    = qp.QuestionId
    WHERE  qp.CourseId = @CourseId
      AND  (@QuestionTypeId IS NULL OR qp.QustionTypeId = @QuestionTypeId)
    ORDER BY qp.QuestionId, ch.ChoiceId;
END
GO

-- usp_GetExamResults
CREATE OR ALTER PROCEDURE dbo.usp_GetExamResults
    @ExamId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT *
    FROM   dbo.vw_StudentExamResults
    WHERE  ExamId = @ExamId
    ORDER BY StudentScore DESC;
END
GO
