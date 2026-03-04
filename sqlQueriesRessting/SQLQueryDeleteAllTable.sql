	use ExaminationSystem
	-- ====================================================
	-- Cleanup all data safely considering dependencies
	-- ====================================================

	-- 1. Disable all foreign keys temporarily
	EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all";

	-- ================= ExamSystem Cleanup =================

	-- Delete dependent tables first
	DELETE FROM ExamSystem.StudentAnswer;
	DELETE FROM ExamSystem.StudentExam;
	DELETE FROM ExamSystem.ExamQuestions;
	DELETE FROM ExamSystem.Choice;
	DELETE FROM ExamSystem.QuestionPool;
	DELETE FROM ExamSystem.Exam;

	-- ExamSystem lookup tables
	DELETE FROM ExamSystem.ExamType;
	DELETE FROM ExamSystem.QustionType;

	-- Course offerings (depends on Course, Class, Instructor)
	DELETE FROM Academic.CourseOffering;

	-- ================= Academic Cleanup =================

	-- Students depend on Class
	DELETE FROM Academic.Student;

	-- TrackCourse depends on Track and Course
	DELETE FROM Academic.TrackCourse;

	-- Instructor depends on User
	DELETE FROM Academic.Instructor;

	-- Class depends on Intake
	DELETE FROM Academic.Class;

	-- Intake depends on Track
	DELETE FROM Academic.Intake;

	-- ================= CoreSystem Cleanup =================

	-- Track depends on Branch
	DELETE FROM CoreSystem.Track;

	-- Branch depends on Department
	DELETE FROM CoreSystem.Branch;

	-- Departments
	DELETE FROM CoreSystem.Department;

	-- Users and roles (independent tables)
	DELETE FROM CoreSystem.UserRole;
	DELETE FROM CoreSystem.UserAccount;
	DELETE FROM CoreSystem.Role;

	delete  from Academic.Course
	-- ================= Re-enable all foreign keys =================
	EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all";

	PRINT 'All data deleted safely!';
