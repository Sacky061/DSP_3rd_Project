//For staff to view all applications/student records

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

    topics: ["view-students"],

    pollingIntervalInMillis: 1000,

    autoCommit: false
};

//Docker containerisation
@docker:Config {
	name: "view-application",
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

       sql:ParameterizedQuery query = `SELECT * FROM STUDENT`;

        stream<messageContent, sql:Error> resultStream = 
        <stream<messageContent, sql:Error>> dbClient->query(query, messageContent);

        json [] studentTable = [];
        // Iterating the returned table.
        error? e = resultStream.forEach(function(messageContent student) {
           studentTable[i] = student;
           responseMessage = studentTable.toString();
                });
            if (e is error) {
                   io:println("Query execution failed.", e);
                            }

}


kafka:ProducerConfiguration producerConfiguration = {

    bootstrapServers: "localhost:9092",

    clientId: "view-students",
    acks: "all",
    retryCount: 3
};


kafka:Producer kafkaProducer = checkpanic new (producerConfiguration);

public function main() returns error? {
    string returnMessage = responseMessage;

    check kafkaProducer->sendProducerRecord({
                                topic: "view-students",
                                value: returnedMessage.toBytes() });

    check kafkaProducer->flushRecords();
}