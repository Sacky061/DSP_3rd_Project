//This service is for checking the application Status and sending back the appropriate response

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
	name: "application-status",
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
        
        log:print("Received Querry for application Status: " + messageContent.toString());

       sql:ParameterizedQuery query = `SELECT applicatioStatus FROM STUDENT
                                WHERE studentNumber == ${messageContent.studentNumber}`;

        stream<messageContent, sql:Error> resultStream = 
        <stream<messageContent, sql:Error>> dbClient->query(query, messageContent);

        //checking the status of the application 
        string responseMessage = query;
    }

}


kafka:ProducerConfiguration producerConfiguration = {

    bootstrapServers: "localhost:9092",

    clientId: "application-status",
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