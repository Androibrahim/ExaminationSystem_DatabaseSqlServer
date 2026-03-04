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
    -- Optional: عدد الأسئلة في الامتحان
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