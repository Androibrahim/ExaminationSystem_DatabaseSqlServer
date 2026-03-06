USE [ExaminationSystem]
GO

-- ============================================================
--  EXAMINATION SYSTEM  |  STORED PROCEDURES EXECUTION SCRIPT
--  One example call per stored procedure
--  Assumes: Admin UserId = 1 | Instructor UserId = 2 | Student UserId = 3
-- ============================================================


-- ============================================================
--  SECTION 1 – User & Authentication Management
-- ============================================================




-- this creates when admin create instructor or student 

-- ► usp_CreateUserAccount
-- Creates a new user account and assigns a role.
DECLARE @NewUserId INT;
EXEC CoreSystem.usp_CreateUserAccount
    @ExecutingUserId = 1,           -- Admin user
    @Email           = 'john.doe@school.edu',
    @UserName        = 'john.doe',
    @Password        = 'SecurePass@123',
    @RoleId          = 3,           -- 1=Admin | 2=Instructor | 3=Student
    @NewUserId       = @NewUserId OUTPUT;
SELECT @NewUserId AS NewUserId;
GO

-- ► usp_UpdateUserAccount
-- Updates email and/or username for an existing user.
EXEC CoreSystem.usp_UpdateUserAccount
    @ExecutingUserId = 1,
    @UserId          = 5,
    @Email           = 'john.updated@school.edu',
    @UserName        = 'john.updated';
GO

-- ► usp_DeleteUserAccount
-- Deletes a user account by UserId.
EXEC CoreSystem.usp_DeleteUserAccount
    @ExecutingUserId = 1,
    @UserId          = 5;
GO









-- ► usp_LoginUser
-- Returns user info + role if credentials are valid.
EXEC CoreSystem.usp_LoginUser
    @UserName = 'androoo',
    @Password = 'Andro@12';
GO


-- ► usp_ChangePassword
-- Changes password after verifying the old password.
EXEC CoreSystem.usp_ChangePassword
    @UserId      = 1,
    @OldPassword = 'Andro',
    @NewPassword = 'Andro@12';
GO


-- ============================================================
--  SECTION 2 – Instructor Management
-- ============================================================

-- ► usp_AddInstructor
-- Creates an instructor + linked user account (RoleId = 2 auto-assigned).
DECLARE @NewInstructorId INT;
EXEC Academic.usp_AddInstructor
    @ExecutingUserId  = 1,
    @Name             = N'Dr. Sara Ali',
    @Phone            = '01012345678',
    @BirthDate        = '1985-06-15',
    @Email            = 'sara.ali@school.edu',
    @UserName         = 'sara.ali',
    @Password         = 'Instructor@2024',
    @NewInstructorId  = @NewInstructorId OUTPUT;
SELECT @NewInstructorId AS NewInstructorId;
GO

-- ► usp_UpdateInstructor
-- Updates instructor name, phone, or birth date.
EXEC Academic.usp_UpdateInstructor
    @ExecutingUserId = 1,
    @InstructorId    = 2,
    @Name            = N'Dr. Sara Mohamed Ali',
    @Phone           = '01098765432',
    @BirthDate       = NULL;        -- NULL = keep existing value
GO

-- ► usp_DeleteInstructor
-- Deletes an instructor (blocked if they have active/future exams).
EXEC Academic.usp_DeleteInstructor
    @ExecutingUserId = 1,
    @InstructorId    = 2;
GO

-- ► usp_AssignInstructorToCourse
-- Assigns an instructor to a course for a given class & academic year.
-- If assignment already exists it updates it; otherwise inserts.
EXEC Academic.usp_AssignInstructorToCourse
    @ExecutingUserId = 1,
    @InstructorId    = 1,
    @CourseId        = 1,
    @ClassId         = 1,
    @AcademicYear    = 2024;
GO


-- ============================================================
--  SECTION 3 – Student Management
-- ============================================================

-- ► usp_AddStudent
-- Creates a student + linked user account (RoleId = 3 auto-assigned).
DECLARE @NewStudentId INT;
EXEC Academic.usp_AddStudent
    @ExecutingUserId = 1,
    @Name            = N'Ahmed Hassan',
    @BirthDate       = '2002-03-20',
    @ClassId         = 1,
    @Email           = 'ahmed.hassan@school.edu',
    @UserName        = 'ahmed.hassan',
    @Password        = 'Student@2024',
    @NewStudentId    = @NewStudentId OUTPUT;
SELECT @NewStudentId AS NewStudentId;
GO

-- ► usp_UpdateStudent
-- Updates student name, birth date, or class assignment.
EXEC Academic.usp_UpdateStudent
    @ExecutingUserId = 1,
    @StudentId       = 3,
    @Name            = N'Ahmed Hassan Mahmoud',
    @BirthDate       = NULL,        -- NULL = keep existing value
    @ClassId         = 2;
GO

-- ► usp_DeleteStudent
-- Deletes a student record.
EXEC Academic.usp_DeleteStudent
    @ExecutingUserId = 1,
    @StudentId       = 3;
GO

-- ► usp_AssignStudentToExam
-- Allows a student to take a specific exam (IsAllow = 1).
-- Instructor (RoleId = 2) must own the exam.
EXEC Academic.usp_AssignStudentToExam
    @ExecutingUserId = 2,           -- Instructor who owns the exam
    @StudentId       = 1,
    @ExamId          = 1;
GO

--automaitc assignment student 
DECLARE @Students Academic.StudentIdList;

INSERT INTO @Students VALUES (1),(2),(3),(4),(5);

EXEC Academic.usp_AssignStudentsToExam
     @ExecutingUserId = 2,
     @ExamId = 10,
     @Students = @Students;

-- ============================================================
--  SECTION 4 – Course & Academic Structure
-- ============================================================

-- ► usp_AddCourse
-- Adds a new course. MinDegree must be less than MaxDegree.
DECLARE @NewCourseId INT;
EXEC Academic.usp_AddCourse
    @ExecutingUserId = 1,
    @Name            = N'os',
    @Description     = N'c++ programming.',
    @MaxDegree       = 100,
    @MinDegree       = 50,
    @NewCourseId     = @NewCourseId OUTPUT;
SELECT @NewCourseId AS NewCourseId;
GO



select * from Academic.Course




-- ► usp_UpdateCourse
-- Updates course details. NULL params keep existing values.
EXEC Academic.usp_UpdateCourse
    @ExecutingUserId = 1,
    @CourseId        = 1,
    @Name            = N'Advanced Database Systems',
    @Description     = NULL,
    @MaxDegree       = 100,
    @MinDegree       = 60;
GO

-- ► usp_DeleteCourse
-- Deletes a course (blocked if it has active exams).
EXEC Academic.usp_DeleteCourse
    @ExecutingUserId = 1,
    @CourseId        = 1;
GO

-- ► usp_AddDepartment
-- Adds a new department.
DECLARE @NewDepartmentId INT;
EXEC CoreSystem.usp_AddDepartment
    @ExecutingUserId  = 1,
    @Name             = N'Computer Science',
    @NewDepartmentId  = @NewDepartmentId OUTPUT;
SELECT @NewDepartmentId AS NewDepartmentId;
GO

-- ► usp_AddBranch
-- Adds a branch under a department.
DECLARE @NewBranchId INT;
EXEC CoreSystem.usp_AddBranch
    @ExecutingUserId = 1,
    @Name            = N'Cairo Branch',
    @DepartmentId    = 1,
    @NewBranchId     = @NewBranchId OUTPUT;
SELECT @NewBranchId AS NewBranchId;
GO

-- ► usp_AddTrack
-- Adds a track under a branch.
DECLARE @NewTrackId INT;
EXEC CoreSystem.usp_AddTrack
    @ExecutingUserId = 1,
    @Name            = N'Back-End Development',
    @BranchId        = 1,
    @NewTrackId      = @NewTrackId OUTPUT;
SELECT @NewTrackId AS NewTrackId;
GO

-- ► usp_AddIntake
-- Adds an intake (cohort) under a track.
DECLARE @NewIntakeId INT;
EXEC Academic.usp_AddIntake
    @ExecutingUserId = 1,
    @Name            = N'Intake 49',
    @MaxNoStudent    = 60,
    @StartDate       = '2024-09-01',
    @EndDate         = '2025-06-30',
    @TrackId         = 1,
    @NewIntakeId     = @NewIntakeId OUTPUT;
SELECT @NewIntakeId AS NewIntakeId;
GO



-- ► usp_AddClass
-- Adds an intake (cohort) under a track.
DECLARE @NewClassId INT;
EXEC Academic.usp_AddClass
    @ExecutingUserId = 1,
    @Name            = N'Intake 49',
	@IntakeId =1,
    @NewClassId     = @NewClassId OUTPUT;
SELECT @NewClassId AS NewClassId;
GO



-- ============================================================
--  SECTION 5 – Question Pool Management
-- ============================================================

-- ► usp_AddQuestion
-- Instructor adds a question to the pool for their course.
-- QuestionTypeId: 1 = MCQ | 2 = True/False
DECLARE @NewQuestionId INT;
EXEC ExamSystem.usp_AddQuestion
    @ExecutingUserId = 2,           -- Instructor who teaches this course
    @Question        = N'Which SQL clause is used to filter rows after grouping?',
    @QuestionTypeId  = 1,           -- MCQ
    @CourseId        = 1,
    @NewQuestionId   = @NewQuestionId OUTPUT;
SELECT @NewQuestionId AS NewQuestionId;
GO


select * from Academic.CourseOffering


-- ► usp_UpdateQuestion
-- Instructor updates question text or type (blocked if in an active exam).
EXEC ExamSystem.usp_UpdateQuestion
    @ExecutingUserId = 2,
    @QuestionId      = 1,
    @Question        = N'Which SQL clause filters rows after a GROUP BY??',
    @QuestionTypeId  = 1;
GO

-- ► usp_DeleteQuestion
-- Instructor deletes a question (blocked if in an active exam).
EXEC ExamSystem.usp_DeleteQuestion
    @ExecutingUserId = 2,
    @QuestionId      = 1;
GO


-- ► usp_AddChoice
-- Adds an answer choice to an MCQ/TF question.
DECLARE @NewChoiceId INT;
EXEC ExamSystem.usp_AddChoice
    @ExecutingUserId = 2,
    @QuestionId      = 1,
    @ChoiceTxt       = N'where',
    @IsCorrect       = 0,           -- 1 = Correct | 0 = Wrong
    @NewChoiceId     = @NewChoiceId OUTPUT;
SELECT @NewChoiceId AS NewChoiceId;
GO


-- ► usp_UpdateChoice
-- Updates choice text or correctness flag.
EXEC dbo.usp_UpdateChoice
    @ExecutingUserId = 2,
    @ChoiceId        = 1,
    @ChoiceTxt       = N'HAVING (filters after GROUP BY)',
    @IsCorrect       = 1;
GO

-- ► usp_DeleteChoice
-- Deletes a choice from a question.
EXEC ExamSystem.usp_DeleteChoice
    @ExecutingUserId = 2,
    @ChoiceId        = 1;
GO


-- ============================================================
--  SECTION 6 – Exam Management
-- ============================================================

-- ► usp_CreateExam
-- Creates a new exam. TotalDegree cannot exceed Course MaxDegree.
DECLARE @NewExamId INT;
EXEC ExamSystem.usp_CreateExam
    @ExecutingUserId = 2,
    @AcademicYear    = 2024,
    @StartTime       = '2027-12-15 09:00:00',
    @EndTime         = '2027-12-15 11:00:00',
    @TotalTime       = '02:00:00',
    @TotalDegree     = 80,
    @ExamTypeId      = 1,           -- e.g. 1 = Midterm | 2 = Final
    @CourseId        = 1,
    @ClassId         = 1,
    @InstructorId    = 1,
	@ExamTitle = 'midterm ......',
    @NewExamId       = @NewExamId OUTPUT;
SELECT @NewExamId AS NewExamId;
GO

-- ► usp_UpdateExam
-- Updates exam schedule/settings (blocked after exam has started).
EXEC ExamSystem.usp_UpdateExam
    @ExecutingUserId = 2,
    @ExamId          = 3,
    @StartTime       = '2026-3-5 10:00:00',
    @EndTime         = '2027-12-15 12:00:00',
    @TotalTime       = '02:00:00',
    @TotalDegree     = 80,
    @ExamTypeId      = NULL,  
	@ExamTitle = 'midterm ......'; -- NULL = keep existing value
GO

-- ► usp_DeleteExam
-- Deletes an exam (blocked if any student has already completed it).
EXEC ExamSystem.usp_DeleteExam
    @ExecutingUserId = 2,
    @ExamId          = 1;
GO

-- ► usp_GenerateExamQuestions_Random
-- Randomly picks N MCQ and/or N T&F questions from the course pool.
EXEC ExamSystem.usp_GenerateExamQuestions_Random
    @ExecutingUserId = 2,
    @ExamId          = 1,
    @MCQ_Count       = 1,
    @TF_Count        = 0,
	@DegreeMCQ       = 3, 
	@DegreeTF        = 0 ;
GO


delete from ExamSystem.ExamQuestions 
select * from ExamSystem.ExamQuestions

-- ► usp_GenerateExamQuestions_Manual
-- Instructor manually selects specific questions by ID list.
EXEC ExamSystem.usp_GenerateExamQuestions_Manual
    @ExecutingUserId = 2,
    @ExamId          = 1,
    @QuestionIdList  = '1,2,3,4,5,6,7,8,9,10';
GO

-- ► usp_SetQuestionDegree
-- Sets marks for a single question in an exam.
-- Sum of all question degrees must not exceed Course MaxDegree.
EXEC ExamSystem.usp_SetQuestionDegree
    @ExecutingUserId = 2,
    @ExamId          = 1,
    @QuestionId      = 1,
    @QuestionDegree  = 1;
GO


-- ============================================================
--  SECTION 7 – Exam Taking & Grading
-- ============================================================

-- ► usp_SubmitStudentAnswer
-- Student submits an answer for one question during an active exam.
-- @ChoiceId is required for MCQ/TF questions.
EXEC ExamSystem.usp_SubmitStudentAnswer
    @ExecutingUserId = 3,           -- Student user
    @StudentExamId   = 1,           -- From ExamSystem.StudentExam table
    @QuestionId      = 1,
    @ChoiceId        = 2;           -- The choice the student selected
GO

select *from ExamSystem.Choice

-- ► usp_AutoGradeExam
-- Admin re-grades all MCQ & T/F answers for an exam.
-- Recalculates IsCorrect and GivinMark for every student answer.
EXEC ExamSystem.usp_AutoGradeExam
    @ExecutingUserId = 1,
    @ExamId          = 1;
GO

-- ► usp_CalculateExamResults
-- Sums each student's GivinMark, stores in StudentExam.TotalDegree,
-- and marks all StudentExam rows as complete (IsComplete = 1).
EXEC ExamSystem.usp_CalculateExamResults
    @ExecutingUserId = 1,
    @ExamId          = 3;
GO

select * from ExamSystem.StudentExam
-- ============================================================
--  SECTION 8 – Search & Display
-- ============================================================

-- ► usp_SearchStudents
-- Flexible student search – all filter params are optional (NULL = ignore).
EXEC Academic.usp_SearchStudents
    @ExecutingUserId = 1,
    @DepartmentId    = 1,           -- Filter by department (NULL = all)
    @BranchId        = NULL,
    @TrackId         = NULL,
    @IntakeId        = NULL,
    @ClassId         = NULL,
    @Name            = N'Ahmed';    -- Partial name search
GO


-- ► usp_SearchExamsByInstructor
-- Returns all exams for an instructor, optionally filtered by course.
EXEC ExamSystem.usp_SearchExamsByInstructor
    @ExecutingUserId = 1,
    @InstructorId    = 1,
    @CourseId        = null;        -- NULL = return all courses
GO


-- ► usp_GetCourseQuestionPool
-- Returns all questions (+ choices) for a course.
-- Filter by question type is optional.
EXEC ExamSystem.usp_GetCourseQuestionPool
    @ExecutingUserId = 2,
    @CourseId       = 1,
    @QuestionTypeId = NULL;         -- NULL = all types | 1 = MCQ | 2 = T/F
GO

-- ► usp_GetExamResults
-- Returns all student results for an exam, ordered by score descending.
EXEC ExamSystem.usp_GetExamResults
    @ExecutingUserId = 1,
    @ExamId = 1;
GO





