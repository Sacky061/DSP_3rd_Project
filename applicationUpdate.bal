//This service is for receiving application form from user and sending back application status

import ballerinax/kafka;
import ballerina/log;
import ballerina/mysql;
import ballerina/sql;

// initialising MySQL connector
string dbUser = "root";
string dbPassword = "Sacky@20";

kafka:ConsumerConfiguration consumerConfigs = {

    bootstrapServers: "localhost:9092",

    groupId: "microservices",

    topics: ["application-status"],

    pollingIntervalInMillis: 1000,

    autoCommit: false
};

//Docker containerisation
@docker:Config {
	name: "application-update",
	tag: "v1.0"
}

listener kafka:Listener kafkaListener = new (consumerConfigs);

service kafka:Service on kafkaListener {
    remote function onConsumerRecord(kafka:Caller caller,
                                kafka:ConsumerRecord[] records) {

        foreach var kafkaRecord in records {
            processKafkaRecord(kafkaRecord);
        }

        var commitResult = caller->commit();

        if (commitResult is error) {
            log:printError("Error occurred while committing the " +
                "offsets for the consumer ", err = commitResult);
        }
    }
}

function processKafkaRecord(kafka:ConsumerRecord kafkaRecord) {
    byte[] value = kafkaRecord.value;

    json|error messageContent = json:fromBytes(value);
    if (messageContent is json) {
        
        log:print("Received Application: " + messageContent.toString());

       sql:ParameterizedQuery query = `SELECT * FROM STUDENT
                                WHERE studentNumber == ${messageContent.studentNumber}`;

        stream<messageContent, sql:Error> resultStream = 
        <stream<messageContent, sql:Error>> dbClient->query(query, messageContent);

        //checking the length of the returned table
         sql:ParameterizedQuery insertQuery = `INSERT INTO STUDENT(applicationStatus)
                                values (${messageContent.applicationStatus)`;
            var ret = dbClient->execute(insertQuery);
            if (ret is sql:ExecutionResult) {
            //io:println("Inserted row count to Students table: ", ret.affectedRowCount);
            string responseMessage = "Application Sttaus Successfully Submitted!!";

            } else {
                    error err = ret;
                    responseMessage = "Application Update Failed: " + err.message();
            }

}


kafka:ProducerConfiguration producerConfiguration = {

    bootstrapServers: "localhost:9092",

    clientId: "application-update",
    acks: "all",
    retryCount: 3
};


kafka:Producer kafkaProducer = checkpanic new (producerConfiguration);

public function main() returns error? {
    string returnMessage = responseMessage;

    check kafkaProducer->sendProducerRecord({
                                topic: "application-status",
                                value: returnedMessage.toBytes() });

    check kafkaProducer->flushRecords();
}