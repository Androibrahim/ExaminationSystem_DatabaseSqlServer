



-- prevent multi correct choice  in one question
CREATE OR ALTER TRIGGER ExamSystem.trg_OneCorrectChoice
ON ExamSystem.Choice
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT QuestionId
        FROM ExamSystem.Choice
        WHERE IsCorrect = 1
        GROUP BY QuestionId
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50010, 'Only one correct choice is allowed per question.', 1;
        ROLLBACK TRANSACTION;
    END
END
GO



--prevent edit in exam after stating
CREATE OR ALTER TRIGGER ExamSystem.trg_PreventExamUpdateAfterStart
ON ExamSystem.Exam
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE GETDATE() >= i.StartTime
    )
    BEGIN
        THROW 50020, 'Cannot modify exam after it has started.', 1;
        ROLLBACK TRANSACTION;
    END
END
GO



-- prevent delete question related to exam
CREATE OR ALTER TRIGGER ExamSystem.trg_PreventQuestionDelete
ON ExamSystem.QuestionPool
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN ExamSystem.ExamQuestions eq
            ON eq.QuestionId = d.QuestionId
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50030, 'Cannot delete question linked to an exam.', 1;
    END
END
GO