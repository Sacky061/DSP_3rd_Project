import wso2/kafka;
import ballerina/internal;
import ballerina/io;


endpoint kafka:SimpleConsumer consumer1 {
  bootstrapServers:"localhost:9297",
    groupId:"presentation",
    topics:["presentation_date"],
    pollingInterval:200,
    autoCommit:false
};

service<kafka:Consumer> kafkaService bind consumer1 {

    onMessage(kafka:ConsumerAction consumerAction, kafka:ConsumerRecord[] records) {
        // Dispatched set of Kafka records to service
        foreach kafkaRecord in records {
            processKafkaRecord(kafkaRecord);
        }
        // Commit offsets returned for returned records, marking them as consumed.
        consumerAction.commit();
    }
}

function processKafkaRecord(kafka:ConsumerRecord kafkaRecord) {
    byte[] serializedMsg = kafkaRecord.value;
    string msg = internal:byteArrayToString(serializedMsg,"UTF-8");
    
    // Print the retrieved Kafka record.
    io:println("Topic: " + kafkaRecord.topic + " Received Message: " + msg);
    
}