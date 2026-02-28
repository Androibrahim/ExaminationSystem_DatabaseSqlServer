use ExaminationSystem

-- create table in exam system schema 
 
create table ExamSystem.QustionType(
QustionTypeId int identity(1,1) not null, 
name nvarchar(100) not null , 

constraint pkQustionType_QustionTypeId primary key(QustionTypeId) , 
constraint checkQustionType_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) , 
)
alter table ExamSystem.QustionType 
add constraint uniqueQustionType_name unique(name)


create table ExamSystem.QuestionPool(
QuestionId int identity(1,1) not null , 
Question nvarchar(1000) not null , 
QustionTypeId int not null , 
CourseId int  not null , 

constraint pkQuestionPool_QuestionId primary key (QuestionId),
constraint checkQuestionPool_QuestionNotWhiteSpace check(len(LTRIM(RTRIM(Question))) > 0 ) , 

constraint fkQuestionPool_QustionTypeId foreign key (QustionTypeId) references ExamSystem.QustionType(QustionTypeId)
on delete cascade on update cascade ,

constraint fkQuestionPool_CourseId foreign key (CourseId) references  Academic.Course(CourseId)
on delete cascade on update cascade ,

)




create table ExamSystem.Choice(
ChoiceId int identity(1,1) not null ,
ChoiceTxt nvarchar(500) not null, 
IsCorrect bit not null ,
QuestionId int not null , 

constraint pkChoice_ChoiceId primary key(ChoiceId ),
constraint uniqueChoice_ChoiceIdQuestionId unique(QuestionId, ChoiceId),

constraint checkChoice_ChoiceTxtNotWhiteSpace check(len(LTRIM(RTRIM(ChoiceTxt))) > 0 ) ,

constraint fkChoice_QuestionId foreign key (QuestionId) references ExamSystem.QuestionPool(QuestionId)
on delete cascade on update cascade ,
)

drop table  ExamSystem.Choice







create table ExamSystem.ExamType(
ExamTypeId int identity(1,1) not null ,
Name nvarchar(100) not null , 

constraint pkExamType_ExamTypeId primary key (ExamTypeId),
constraint uniqueExamType_Name unique (Name),
constraint checkExamType_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) ,

)



create table ExamSystem.Exam(
ExamId int identity(1,1) not null , 
AcademicYear int not null , 
StartTime datetime2 not null , 
EndTime datetime2 not null , 
ExamDate as CAST(StartTime AS date) PERSISTED, 
TotalTime time not null , 
TotalDegree int not null ,  -- must minimum course degree implement this in insert into trigger 
ExamTypeId int not null ,
CourseId int  not null ,
ClassId int  not null ,
InstructorId int  not null , 

constraint pkExam_ExamId primary key(ExamId) , 
constraint checkExam_ExamDate check (ExamDate > getdate()) , 
constraint checkExam_EndTimeGreaterStartTime check( EndTime > StartTime ) , 

constraint fkExam_ExamTypeId foreign key (ExamTypeId) references ExamSystem.ExamType(ExamTypeId)
on delete cascade on update cascade ,

constraint fkExam_CourseId foreign key (CourseId) references Academic.Course(CourseId)
on delete cascade on update cascade ,

constraint fkExam_ClassId foreign key (ClassId) references Academic.Class(ClassId)
on delete cascade on update cascade ,

constraint fkExam_InstructorId foreign key(InstructorId) references Academic.Instructor(InstructorId)
on delete cascade on update cascade 
)





create table ExamSystem.ExamQuestions(
ExamId int  not null ,
QuestionId int  not null ,
QuestionDegree int not null , 

constraint pkExamQuestions_ExamIdQuestionId primary key (ExamId, QuestionId), 

constraint fkExamQuestions_ExamId foreign key (ExamId) references ExamSystem.Exam(ExamId)
on delete cascade on update cascade , 

constraint fkExamQuestions_QuestionId foreign key (QuestionId) references ExamSystem.QuestionPool(QuestionId)
on delete no action on update no action , 

)




create table ExamSystem.StudentExam(
StudentExamId int identity(1,1) not null , 
StudentId int  not null , 
ExamId int  not null , 
IsAllow bit null,
IsComplete bit null ,
TotalDegree int null ,       -- if complete create function to calculate 

constraint pkStudentExam_StudentExamId primary key(StudentExamId),
constraint uniqueStudentExam_StudentIdExamId unique (StudentId ,ExamId),
constraint fkStudentExam_StudentId foreign key (StudentId) references Academic.Student(StudentId)
on delete cascade on update cascade , 
constraint fkStudentExam_ExamId foreign key (ExamId) references ExamSystem.Exam(ExamId)
on delete no action on update no action , 
)

drop table ExamSystem.StudentExam

create table ExamSystem.StudentAnswer(
StudentAnswerId int identity(1,1) not null , 
IsCorrect bit null , 
GivinMark int null , 
StudentExamId int not null , 
QuestionId int not null , 
ChoiceId int not null , 

constraint pkStudentAnswer_StudentAnswerId primary key (StudentAnswerId) , 

constraint uniqueStudentAnswer_StudentExam_Question unique (StudentExamId, QuestionId),

constraint fkStudentAnswer_StudentExamId foreign key (StudentExamId) references ExamSystem.StudentExam(StudentExamId)
on delete cascade on update cascade , 

constraint fkStudentAnswer_QuestionChoice foreign key (QuestionId, ChoiceId) references ExamSystem.Choice(QuestionId, ChoiceId)
on delete no action on update no action , 

)