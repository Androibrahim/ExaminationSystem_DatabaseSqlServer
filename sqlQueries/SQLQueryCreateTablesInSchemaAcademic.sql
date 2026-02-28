use ExaminationSystem

-- tables in schema Academic :  


create table Academic.Course(
CourseId int identity(1,1) not null , 
Name nvarchar(50) not null , 
Description nvarchar(200)  null , 
MaxDegree int not null , 
MinDegree int not null , 

constraint pkCourse_CourseId primary key(CourseId) , 
constraint checkCourse_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) , 
) 
alter table Academic.Course
add constraint uniqueCourse_Name unique(Name)

drop table Academic.Course




create table Academic.TrackCourse(
TrackId int not null  , 
CourseId int not null ,

constraint pkTrackId_CourseId primary key(TrackId , CourseId), 
constraint fkTrackCourse_TrackId foreign key (TrackId) references CoreSystem.Track (TrackId)
on delete cascade on update cascade , 
constraint fkTrackCourse_CourseId foreign key (CourseId) references Academic.Course(CourseId)
on delete cascade on update cascade , 
)






create table Academic.Intake(
IntakeId int identity(1,1) not null , 
Name nvarchar(50) not null , 
MaxNoStudent int not null , 
StartDate date null , 
EndDate date null , 
TrackId int not null, 

constraint pkIntake_IntakeId primary key (IntakeId),
constraint checkIntake_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) , 
constraint fkIntake_TrackId foreign key (TrackId) references CoreSystem.Track (TrackId)
on delete cascade on update cascade , 

)
alter table Academic.Intake
add constraint uniqueIntake_NamePerTrack unique(Name , TrackId)


create table Academic.Class(
ClassId int identity(1,1) not null , 
Name nvarchar(50) not null , 
IntakeId int  not null ,

constraint pkClass_ClassId primary key(ClassId) , 
constraint checkClass_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) , 
constraint fkClass_IntakeId foreign key (IntakeId) references Academic.Intake(IntakeId)
on delete cascade on update cascade , 
)
alter table Academic.Class
add constraint uniqueClass_NamePerIntake unique(Name , IntakeId)




create table Academic.Student(
StudentId int identity(1,1) not null , 
Name nvarchar(50) not null ,
BirthDate Date not null , 
Age AS DATEDIFF(YEAR, BirthDate, GETDATE()),
ClassId int not null ,
UserId  int not null , 

constraint pkStudent_StudentId primary key (StudentId),
constraint checkStudent_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) ,
constraint uniqueStudent_UserId unique(UserId),

constraint fkStudent_ClassId foreign key (ClassId) references Academic.Class(ClassId)
on delete cascade on update cascade ,

constraint fkStudent_UserId foreign key (UserId) references CoreSystem.UserAccount(UserId)
on delete cascade on update cascade ,
)






create table Academic.Instructor(
InstructorId int identity(1,1) not null , 
Name nvarchar(50) not null , 
Phone varchar(50) null , 
BirthDate Date not null , 
Age AS DATEDIFF(YEAR, BirthDate, GETDATE()),
UserId  int not null , 

constraint pkInstructor_InstructorId primary key (InstructorId),
constraint checkInstructor_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) ,
constraint uniqueInstructor_UserId unique(UserId),

constraint fkInstructor_UserId foreign key (UserId) references CoreSystem.UserAccount(UserId)
on delete cascade on update cascade ,
)



create table Academic.CourseOffering(
InstructorId int not null ,
CourseId int not null ,
ClassId int not null ,
AcademicYear int not null,

constraint pkCourseOffering_InstructorIdCourseIdClassIdAcademicYear primary key(InstructorId ,CourseId,ClassId ,AcademicYear),

constraint fkCourseOffering_InstructorId foreign key(InstructorId) references Academic.Instructor(InstructorId)
on delete cascade on update cascade ,

constraint fkCourseOffering_CourseId foreign key(CourseId) references Academic.Course(CourseId)
on delete cascade on update cascade ,

constraint fkCourseOffering_ClassId foreign key(ClassId) references Academic.Class(ClassId)
on delete cascade on update cascade ,
)







