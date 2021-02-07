import wso2/kafka;
import ballerina/io;
import ballerina/h2;
import ballerina/mysql;

endpoint kafka:PresentationProducer kafkaProducer {
   
    //creating a producer configs with optional parameters client.id - used for broker side logging.
    bootstrapServers:"localhost:9297",
    clientID:"presentationDate",
    acks:"all", // acks - number of acknowledgments for request complete
    noRetries:5 // noRetries - number of retries if record send fails.
};
//Endpoit for Database
endpoint h2:Client testDB {
    path: "./presentation",
    name: "testDB",
    username: "root",
    password: "",
    poolOptions: { maximumPoolSize: 5 }
};
function main (string... args) {
    io:println("The update operation - Creating a table:");
    var ret = testDB->update("CREATE TABLE STUDENT(studentNumber INTEGER,
                     surname VARCHAR(14),presentationDate VARCHAR(30),presentationMode VARCHAR(20), PRIMARY KEY (studentNumber))");
    handleUpdate(ret, "Create student table");

    io:println("\nThe update operation - Inserting data to a table");
    ret = testDB->update("INSERT INTO student(studentNumber, surname,presentationDate,presentationMode)
                          values (215511,'simon','10/5/2021','online'),(210012,'sacky','25/4/2021','online');
    handleUpdate(ret, "Insert to student table with no parameters");
    
    
    //Prompt user for a student details and insert into the student table
    string name = io:readln("Enter Student name:");
    var  st_no = <float>io:readln("Enter Student number:");
    float resST_Num;
    match st_no{
        float resFloat=>{
            resST_Num = resFloat;
        }
        error e=>io:println("error:"+e.message);
    }

    var updateTB = testDB->update("INSERT INTO STUDENT(studentNumber, surname, firstName, presentationDate, presentationResult) values ("+studentNumber+",'"+surname+"', '"+10/28/2021+"', 95)");
     handleUpdate(updateTB, "Create STUDENT table");

    //get items in table and send
    io:println("\nThe select operation - Select data from a table");
    var selectRet = testDB->select("SELECT * FROM STUDENT", ());
    table dt;
    match selectRet {
        table tableReturned => dt = tableReturned;
        error e => io:println("Select data from student table failed: "
                              + e.message);
    }
    //convert table to json and send to consumer
    io:println("\nConvert the table into json");
    var jsonConversionRet = <json>dt;
    json tableMsg;
    match jsonConversionRet {
        json jsonRes => {
            io:print("JSON: ");
            tableMsg = jsonRes;
            io:println(io:sprintf("%s", tableMsg));
        }
        error e => io:println("Error in table to json conversion");
    }
    io:println("TABLE READY FOR SENDING:");
    io:println(io:sprintf("%s", tableMsg));

    json msg = {"presentationDate": "10/28/2021", "presentationMode": "online"};
    byte[] serializedMsg = tableMsg.toString().toByteArray("UTF-8");
    kafkaProducer->send(serializedMsg, "presentation", partition = 0);
    io:println("message sent to kafka...");

}
function handleUpdate(int|error returned, string message) {
    match returned {
        int retInt => io:println(message + " status: " + retInt);
        error e => io:println(message + " failed: " + e.message);
    }
}