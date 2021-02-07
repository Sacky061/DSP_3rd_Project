import ballerinax/kafka;
import ballerina/log;
import ballerina/mysql;
import ballerina/sql;

// initialising MySQL connector
string dbUser = "root";
string dbPassword = "Sacky@20";

kafka:ConsumerConfiguration consumerConfigs = {
    bootstrapServers: "localhost:9090",
    groupId: "proposal",
    topics: ["submit_proposal-get_proposal_result"],
    pollingInterval: 200,
    autoCommit: false
};

//Docker containerisation
@docker:Config {
	name: "submitProposal_getProposalRresult",
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
        
        log:print("submit proposal: " + messageContent.toString());

       sql:ParameterizedQuery query = `SELECT * FROM STUDENT
                                WHERE studentNumber == ${messageContent.studentNumber}`;

        stream<messageContent, sql:Error> resultStream = 
        <stream<messageContent, sql:Error>> dbClient->query(query, messageContent);

        //checking the length of the returned table
        int numberOfEntries = 'SELECT COUNT(*) FROM query';

        if(numberOfEntries == 0){
            sql:ParameterizedQuery insertQuery = `INSERT INTO STUDENT(studentNumber, surname,
                firstName, idNumber, Course, studyLevel, proposal, proposalResult)
                                values (${messageContent.studentNumber}, ${messageContent.surname},${messageContent.firstName},
                                ${messageContent.idNumber}, ${messageContent.Course}, ${messageContent.studyLevel}, ${messageContent.proposal},${messageContent.proposalResult})`;
            var ret = dbClient->execute(insertQuery);
            if (ret is sql:ExecutionResult) {
            //io:println("Inserted row count to Students table: ", ret.affectedRowCount);
            string responseMessage = "proposal Successfully Submitted!!";

            } else {
                    error err = ret;
                    responseMessage = "proposal: " + err.message();
            }
        }

}


endpoint kafka:KafukaProducer kafkaproducer{

    bootstrapServers: "localhost:9090",
    clientId: "submitProposal_getProposalRresult",
    acks: "all",
    noRetries: 3
};

kafka:Producer kafkaProducer = checkpanic new (producerConfiguration);

public function main() returns error? {
    string returnMessage = responseMessage;

    check kafkaProducer->sendProducerRecord({
                                topic: "submit_proposal-get_proposal_result",
                                value: message.toBytes() });

    check kafkaProducer->flushRecords();
}