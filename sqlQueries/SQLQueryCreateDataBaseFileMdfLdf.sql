create database ExaminationSystem
on PRIMARY
(
	NAME = 'ExaminationSystemMDF',
    FILENAME = 'F:\develop\ITI dotNet Full Stack\prjects\sql Project\databaseFile\ExaminationSystem.mdf',
    SIZE = 8,
    MAXSIZE = unlimited ,
    FILEGROWTH = 50 MB
)

LOG on
(
	NAME = 'ExaminationSystemLDF',
    FILENAME = 'F:\develop\ITI dotNet Full Stack\prjects\sql Project\databaseFile\ExaminationSystem.ldf',
    SIZE = 8,
    MAXSIZE = 1 GB,
    FILEGROWTH = 20 MB
)

