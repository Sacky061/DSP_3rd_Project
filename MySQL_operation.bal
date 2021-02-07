import ballerina/io;
import ballerina/mysql;
import ballerina/sql;

// initialising MySQL connector
string dbUser = "root";
string dbPassword = "Sacky@20";

// record type to be used
type STUDENT record {|
    int studentNumber;
    string surname;
    string firstName;
    int idNumber;
    string course;
    string studyLevel;
    string researchTopic;
    string applicationStatus;
    string presentationDate;
    string presentationResult;
    byte[] proposal;
    string proposalResult;
    byte[] thesis;
    string thesisResult;
|};

// record type to be used
type SUPERVISOR record {|
    int studentNumber;
    int supervisorID;
    string surname;
    string firstName;
|};

// select the rows within student record based on column name and type of query result
function querySTUDENT(mysql:Client mysqlClient) {

    io:println("------ Query STUDENT -------");
    stream<record{}, error> resultStream =
        mysqlClient->query("Select * from STUDENT");

    io:println("Result 1:");
    error? e = resultStream.forEach(function(record {} result) {
        io:println(result);
    });
    if (e is error) {
        io:println(e);
    }

    resultStream = mysqlClient->query("Select * from STUDENT", STUDENT);
    stream<STUDENT, sql:Error> studentResultStream =
        <stream<STUDENT, sql:Error>>resultStream;

    io:println("Result 2:");
    e = studentResultStream.forEach(function(STUDENT result) {
        io:println(result);
    });
    if (e is error) {
        io:println(e);
    }
    io:println("------ ********* -------");
}

// select the rows within supervisor record based on column name and type of query result
function querySUPERVISOR(mysql:Client mysqlClient) {

    io:println("------ Query SUPERVISOR -------");
    stream<record{}, error> resultStream =
        mysqlClient->query("Select * from SUPERVISOR");

    io:println("Result 1:");
    error? e = resultStream.forEach(function(record {} result) {
        io:println(result);
    });
    if (e is error) {
        io:println(e);
    }

    resultStream = mysqlClient->query("Select * from SUPERVISOR",
        SUPERVISOR);
    stream<SUPERVISOR, sql:Error> supervisorResultStream =
        <stream<SUPERVISOR, sql:Error>>resultStream;

    io:println("Result 2:");
    e = supervisorResultStream.forEach(function(SUPERVISOR result) {
        io:println(result);
    });
    if (e is error) {
        io:println(e);
    }
    io:println("------ ********* -------");
}

//initialise the database tables
function initialiseTable() returns sql:Error? {
    mysql:Client mysqlClient = check new (user = dbUser, password = dbPassword);
    sql:ExecuteResult? result = check
        mysqlClient->execute("CREATE DATABASE IF NOT EXISTS STUDENT_RECORDS");

    result = check mysqlClient->execute("DROP TABLE IF EXISTS " +
        "STUDENT_RECORDS.STUDENT");
    result = check mysqlClient->execute("CREATE TABLE STUDENT_RECORDS.STUDENT"+
        "(studentNumber INT NOT NULL,
          surname VARCHAR(16) NOT NULL, 
          firstName VARCHAR(16) NOT NULL, 
          idNumber INT NOT NULL,
          Course VARCHAR(30) NOT NULL,
          studyLevel VARCHAR(25) NOT NULL,
          researchTopic VARCHAR(50) NOT NULL,
          applicationStatus VARCHAR(11),
          presentationDate VARCHAR (20),
          presentationResult VARCHAR(10),
          proposal BLOB(1024),
          proposalResult VARCHAR(10),
          thesis BLOB(1024),
          thesisResult VARCHAR(10), 
          PRIMARY KEY (studentNumber))");

    result = check mysqlClient->execute("INSERT INTO STUDENT_RECORDS.STUDENT "+
        "(studentNumber, surname, firstName, idNumber, course, studyLevel, 
        researchTopic, applicationStatus, presentationDate, presentationResult, 
        proposal, proposalResult, thesis, thesisResult) VALUES (21001452, 'Simon', 
        'Sacky', 22072522555, 'Computer Science', 'Honours', 'X', 'X', 'X', 'X', 1024, 
        'X', 1024, 'X')");

    result = check mysqlClient->execute("DROP TABLE IF EXISTS " +
        "STUDENT_RECORDS.SUPERVISOR");

    result = check mysqlClient->execute("CREATE TABLE "+
        "STUDENT_RECORDS.SUPERVISOR(studentNumber INTEGER NOT NULL,
        supervisorID INT NOT NULL, surname VARCHAR NOT NULL, firstName VARCHAR NOT NULL, 
        FOREIGN KEY (studentNumber) REFERENCES STUDENT (studentNumber),
        PRIMARY KEY (supervisorID))");

    result = check mysqlClient->execute("Insert into " +
        "STUDENT_RECORDS.SUPERVISOR (studentNumber, supervisorID, surname, 
        firstName) values (21001452, 2,'Bernard',
        'Leo')");
    check mysqlClient.close();
}
public function main() {
    //initialise the MySQL client
    sql:Error? err = initialiseTable();
    if (err is sql:Error) {
        io:println("Students data initialisation failed!", err);
    } else {
        mysql:Client|sql:Error mysqlClient = new (user = dbUser,
            password = dbPassword, database = "STUDENT_RECORDS");
        if (mysqlClient is mysql:Client) {

            //excute data type queries

            querySTUDENT(mysqlClient);
            querySUPERVISOR(mysqlClient);
            io:println("Student executed successfully!");
            
            //close the MySQL client
            sql:Error? e = mysqlClient.close();
        } else {
            io:println("MySQL Client initialisation for querying data" +
            "failed!!", mysqlClient);
        }
    }
}