import ballerinax/kafka;
//This kafka producer is used to store the application Form
kafka:ProducerConfiguration producerConfiguration = {

    bootstrapServers: "localhost:9092",

    clientId: "application-producer",
    acks: "all",
    retryCount: 3
};

//Docker containerisation
@docker:Config {
	name: "application-form",
	tag: "v1.0"
}


kafka:Producer kafkaProducer = checkpanic new (producerConfiguration);

public function main() returns error? {
    json message = {
        Surname: "Surname",
        firstName: "First Name",
        studentNumber: "Student Number",
        idNo: "Identification Number",
        dob: "Date of Birth",
        studyLevel: " Study Level",
        topic: "Research Topic"
    }

    check kafkaProducer->sendProducerRecord({
                                topic: "application-form",
                                value: message.toBytes() });

    check kafkaProducer->flushRecords();
}