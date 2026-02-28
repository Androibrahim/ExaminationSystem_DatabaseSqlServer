use ExaminationSystem

create schema CoreSystem
create schema Academic
create schema ExamSystem

-- create tables CoreSystem

create table CoreSystem.UserAccount (

UserId int identity(1,1) not null , 
Email varchar(50) not null , 
NormalizedEmail as upper(Email) persisted,
UserName varchar(50) not null , 
NormalizedUserName as upper(UserName) persisted , 
PasswordHashed VARBINARY(32) not null ,

constraint pkUserAccount_UserId primary key(UserId),
constraint uniqueUserAccount_NormalizedEmail unique(NormalizedEmail) ,
constraint uniqueUserAccount_NormalizedUserName unique(NormalizedUserName),
constraint checkUserAccount_MinLengthUserName check(len(LTRIM(RTRIM(UserName))) >= 6 ),
constraint checkUserAccount_MinLengthEmail check(len(LTRIM(RTRIM(Email))) >= 12 ),
constraint checkUserAccount_EmailFormat check (Email LIKE '%_@_%._%')

)

drop Table CoreSystem.UserAccount


insert into CoreSystem.UserAccount
values('andro@gmail.com' , 'andro'  , HASHBYTES('SHA2_256', 'Andro'))


select * from CoreSystem.UserAccount 
where PasswordHashed = HASHBYTES('SHA2_256', 'Andro')

delete from CoreSystem.UserAccount

-- check password on function or stord procedure trigers 
-- check whit space user name not wite spaces and   this '    g    '
-- remove start white space and end 







--Table role 
create table CoreSystem.Role(
RoleId int identity(1,1) not null ,
Name varchar(50) not null , 

constraint pkRole_RoleId primary key (RoleId),
constraint uniqueRole_Name unique(Name), 
constraint checkRole_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) 
)

drop Table CoreSystem.Role




create table CoreSystem.UserRole (

UserId int  not null , 
RoleId int  not null ,

constraint pkUserRole_UserIdRoleId primary key (UserId , RoleId) , 

constraint fkUserRole_UserId foreign key (UserId) references CoreSystem.UserAccount(UserId)
on delete cascade on update cascade , 
constraint fkUserRole_RoleId foreign key (RoleId) references CoreSystem.Role(RoleId)
on delete cascade on update cascade , 

)

drop Table CoreSystem.UserRole



create table CoreSystem.Department(
DepartmentId int identity(1,1) not null , 
Name nvarchar(50) not null , 

constraint pkDepartment_DepartmentId primary key(DepartmentId) , 
constraint checkDepartment_NameNotWhiteSpace check( len(LTRIM(RTRIM(Name))) > 0 )
)
alter table CoreSystem.Department 
add constraint uniqueDepartment_Name unique (name)
drop Table CoreSystem.Department





create table CoreSystem.Branch(
BranchId int identity(1,1) not null , 
Name nvarchar(50) not null , 
DepartmentId int not null , 

constraint pkBranch_BranchId primary key(BranchId),
constraint checkBranch_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) , 
constraint fkBranch_DepartmentId foreign key(DepartmentId) references CoreSystem.Department(DepartmentId)
on delete cascade on update cascade , 

) 
alter table CoreSystem.Branch 
add constraint uniqueBranch_NamePerDepartment unique(Name ,DepartmentId )


drop table CoreSystem.Branch
-- alter phone len by spesfic country 



create table CoreSystem.Track(
TrackId int identity(1,1) not null,
Name nvarchar(50) not null , 
BranchId int not null ,

constraint pkTrack_TrackId primary key(TrackId),
constraint checkTrack_NameNotWhiteSpace check(len(LTRIM(RTRIM(Name))) > 0 ) , 
constraint fkTrack_BranchId foreign key(BranchId) references CoreSystem.Branch(BranchId)
on delete cascade on update cascade , 
)
alter table CoreSystem.Track
add constraint uniqueTrackPerBranch unique (Name , BranchId)


drop table CoreSystem.Track













