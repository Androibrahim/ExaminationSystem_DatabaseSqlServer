
USE ExaminationSystem
GO

CREATE OR ALTER VIEW dbo.vw_AllStudents
AS
SELECT 
    s.StudentId,
    u.UserName,
    s.Name AS StudentName,
    c.ClassId,
    c.Name AS ClassName,
    i.IntakeId,
    i.Name AS IntakeName,
    t.TrackId,
    t.Name AS TrackName,
    b.BranchId,
    b.Name AS BranchName,
    d.DepartmentId,
    d.Name AS DepartmentName
FROM Academic.Student s
JOIN CoreSystem.[UserAccount] u ON u.UserId = s.UserId
JOIN Academic.Class c ON c.ClassId = s.ClassId
JOIN Academic.Intake i ON i.IntakeId = c.IntakeId
JOIN CoreSystem.Track t ON t.TrackId = i.TrackId
JOIN CoreSystem.Branch b ON b.BranchId = t.BranchId
JOIN CoreSystem.Department d ON d.DepartmentId = b.DepartmentId;
GO


alter schema Academic
transfer dbo.vw_AllStudents



CREATE OR ALTER VIEW ExamSystem.vw_ExamSummary
AS
SELECT 
    e.ExamId,
    e.CourseId,
    c.Name AS CourseName,
    e.InstructorId,
    i.Name AS InstructorName,
    e.StartTime,
    e.EndTime,
    e.TotalDegree,
    -- Optional: total quetion in exam
    ISNULL(q.QuestionCount, 0) AS TotalQuestions
FROM ExamSystem.Exam e
JOIN Academic.Course c       ON c.CourseId = e.CourseId
JOIN Academic.Instructor i   ON i.InstructorId = e.InstructorId
LEFT JOIN (
    SELECT ExamId, COUNT(*) AS QuestionCount
    FROM ExamSystem.ExamQuestions
    GROUP BY ExamId
) q ON q.ExamId = e.ExamId;
GO













-- ============================================================
--  SECTION 1: User & Role Views
-- ============================================================

-- View: Users with their Roles
CREATE OR ALTER VIEW vw_Users
AS
SELECT 
    ua.UserId,
    ua.UserName,
    ua.Email,
    r.Name AS RoleName
FROM CoreSystem.UserAccount ua
LEFT JOIN CoreSystem.UserRole ur ON ua.UserId = ur.UserId
LEFT JOIN CoreSystem.Role r ON ur.RoleId = r.RoleId;
GO

PRINT 'vw_Users';
SELECT * FROM vw_Users;
GO

-- ============================================================
--  SECTION 2: Student & Instructor Views
-- ============================================================

-- View: Students Basic Info
CREATE OR ALTER VIEW vw_Students
AS
SELECT 
    s.StudentId,
    s.Name AS StudentName,
    s.BirthDate,
    s.Age,
    c.Name AS ClassName,
    ua.Email,
    ua.UserName
FROM Academic.Student s
INNER JOIN Academic.Class c ON s.ClassId = c.ClassId
INNER JOIN CoreSystem.UserAccount ua ON s.UserId = ua.UserId;
GO

-- Test View
PRINT 'vw_Students ';
SELECT * FROM vw_Students;
GO

-- View: Instructors Basic Info
CREATE OR ALTER VIEW vw_Instructors
AS
SELECT 
    i.InstructorId,
    i.Name AS InstructorName,
    i.Phone,
    i.Age,
    ua.Email
FROM Academic.Instructor i
INNER JOIN CoreSystem.UserAccount ua ON i.UserId = ua.UserId;
GO

-- Test View
PRINT 'vw_Instructors ';
SELECT * FROM vw_Instructors;
GO

-- ============================================================
--  SECTION 3: Course Views
-- ============================================================

-- View: All Courses
CREATE OR ALTER VIEW vw_Courses
AS
SELECT 
    CourseId,
    Name AS CourseName,
    Description,
    MaxDegree,
    MinDegree
FROM Academic.Course;
GO

-- Test View
PRINT ' vw_Courses ';
SELECT * FROM vw_Courses;
GO

-- View: Course Assignments (من بيدرس إيه)
CREATE OR ALTER VIEW vw_CourseAssignments
AS
SELECT 
    co.InstructorId,
    i.Name AS InstructorName,
    co.CourseId,
    c.Name AS CourseName,
    co.ClassId,
    cl.Name AS ClassName,
    co.AcademicYear
FROM Academic.CourseOffering co
INNER JOIN Academic.Instructor i ON co.InstructorId = i.InstructorId
INNER JOIN Academic.Course c ON co.CourseId = c.CourseId
INNER JOIN Academic.Class cl ON co.ClassId = cl.ClassId;
GO

-- Test View
PRINT ' vw_CourseAssignment';
SELECT * FROM vw_CourseAssignments;
GO

-- ============================================================
--  SECTION 4: Question Pool Views
-- ============================================================

-- View: Questions with Type
CREATE OR ALTER VIEW vw_Questions
AS
SELECT 
    qp.QuestionId,
    qp.Question,
    qt.name AS QuestionType,
    c.Name AS CourseName
FROM ExamSystem.QuestionPool qp
INNER JOIN ExamSystem.QustionType qt ON qp.QustionTypeId = qt.QustionTypeId
INNER JOIN Academic.Course c ON qp.CourseId = c.CourseId;
GO

-- Test View
PRINT 'vw_Questions ';
SELECT * FROM vw_Questions;
GO

-- View: Question Choices
CREATE OR ALTER VIEW vw_QuestionChoices
AS
SELECT 
    ch.ChoiceId,
    ch.QuestionId,
    ch.ChoiceTxt,
    ch.IsCorrect
FROM ExamSystem.Choice ch;
GO

-- Test View
PRINT 'vw_QuestionChoices';
SELECT * FROM vw_QuestionChoices;
GO

-- ============================================================
--  SECTION 5: Exam Views
-- ============================================================

-- View: All Exams
CREATE OR ALTER VIEW vw_Exams
AS
SELECT 
    e.ExamId,
    c.Name AS CourseName,
    et.Name AS ExamType,
    cl.Name AS ClassName,
    i.Name AS InstructorName,
    e.ExamDate,
    e.StartTime,
    e.EndTime,
    e.TotalDegree,
    CASE 
        WHEN GETDATE() < e.StartTime THEN 'Upcoming'
        WHEN GETDATE() BETWEEN e.StartTime AND e.EndTime THEN 'Active'
        ELSE 'Completed'
    END AS Status
FROM ExamSystem.Exam e
INNER JOIN Academic.Course c ON e.CourseId = c.CourseId
INNER JOIN ExamSystem.ExamType et ON e.ExamTypeId = et.ExamTypeId
INNER JOIN Academic.Class cl ON e.ClassId = cl.ClassId
INNER JOIN Academic.Instructor i ON e.InstructorId = i.InstructorId;
GO

-- Test View
PRINT 'vw_Exams';
SELECT * FROM vw_Exams;
GO

-- View: Exam Questions
CREATE OR ALTER VIEW vw_ExamQuestions
AS
SELECT 
    eq.ExamId,
    eq.QuestionId,
    qp.Question,
    qt.name AS QuestionType,
    eq.QuestionDegree
FROM ExamSystem.ExamQuestions eq
INNER JOIN ExamSystem.QuestionPool qp ON eq.QuestionId = qp.QuestionId
INNER JOIN ExamSystem.QustionType qt ON qp.QustionTypeId = qt.QustionTypeId;
GO

-- Test View
PRINT 'vw_ExamQuestions ';
SELECT * FROM vw_ExamQuestions;
GO

-- ============================================================
--  SECTION 6: Student Results Views
-- ============================================================

-- View: Student Results
CREATE OR ALTER VIEW vw_StudentResults
AS
SELECT 
    s.StudentId,
    s.Name AS StudentName,
    e.ExamId,
    c.Name AS CourseName,
    se.TotalDegree AS StudentScore,
    e.TotalDegree AS ExamTotal,
    c.MinDegree AS PassMark,
    CASE 
        WHEN se.TotalDegree >= c.MinDegree THEN 'Pass'
        WHEN se.TotalDegree < c.MinDegree THEN 'Fail'
        ELSE 'Pending'
    END AS Result
FROM ExamSystem.StudentExam se
INNER JOIN Academic.Student s ON se.StudentId = s.StudentId
INNER JOIN ExamSystem.Exam e ON se.ExamId = e.ExamId
INNER JOIN Academic.Course c ON e.CourseId = c.CourseId
WHERE se.IsComplete = 1;
GO

-- Test View
PRINT 'vw_StudentResults ';
SELECT * FROM vw_StudentResults;
GO

-- View: Student Answers
CREATE OR ALTER VIEW vw_StudentAnswers
AS
SELECT 
    sa.StudentAnswerId,
    s.StudentId,
    s.Name AS StudentName,
    e.ExamId,
    qp.Question,
    ch.ChoiceTxt AS Answer,
    sa.IsCorrect,
    sa.GivinMark
FROM ExamSystem.StudentAnswer sa
INNER JOIN ExamSystem.StudentExam se ON sa.StudentExamId = se.StudentExamId
INNER JOIN Academic.Student s ON se.StudentId = s.StudentId
INNER JOIN ExamSystem.Exam e ON se.ExamId = e.ExamId
INNER JOIN ExamSystem.QuestionPool qp ON sa.QuestionId = qp.QuestionId
INNER JOIN ExamSystem.Choice ch ON sa.ChoiceId = ch.ChoiceId;
GO

-- Test View
PRINT 'vw_StudentAnswers ';
SELECT * FROM vw_StudentAnswers;
GO

-- ============================================================
--  SECTION 7: Simple Reports
-- ============================================================


-- View: Upcoming Exams
CREATE OR ALTER VIEW vw_UpcomingExams
AS
SELECT 
    e.ExamId,
    c.Name AS CourseName,
    cl.Name AS ClassName,
    e.ExamDate,
    e.StartTime,
    DATEDIFF(DAY, GETDATE(), e.StartTime) AS DaysLeft
FROM ExamSystem.Exam e
INNER JOIN Academic.Course c ON e.CourseId = c.CourseId
INNER JOIN Academic.Class cl ON e.ClassId = cl.ClassId
WHERE e.StartTime > GETDATE();
GO

-- Test View
PRINT 'vw_UpcomingExams ';
SELECT * FROM vw_UpcomingExams;
GO








