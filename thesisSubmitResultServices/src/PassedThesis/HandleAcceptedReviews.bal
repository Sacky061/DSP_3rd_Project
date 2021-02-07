import ballerina/io;
import wso2/kafka;
import ballerina/encoding;

string topicPassedThesis = "passed-thesis";

kafka:ConsumerConfig passedThesisConsumerConfigs = {
    bootstrapServers: "localhost:9090",
    groupId: "PassedThesisConsumers",
    topics: [topicPassedThesis]
};

listener kafka:SimpleConsumer passedThesisConsumer = new(passedThesisConsumerConfigs);

service handlePassedThesisService on passedThesisConsumer {
    resource function onMessage(kafka:SimpleConsumer simpleConsumer, kafka:ConsumerRecord[] records) {
        foreach var entry in records {
            io:println("Passed Thesis Received");
            byte[] serializedMsg = entry.value;
            string msg = encoding:byteArrayToString(serializedMsg);

            io:println("Passed Thesis: ");
            io:println("[HandleFiltered]\n[INFO]\n" + msg + "\n\n");

            kafka:TopicPartition topicPartition = {topic: entry.topic, partition: entry.partition};
            kafka:PartitionOffset offset = {partition: topicPartition, offset: entry.offset};
            var commitAcceptedResult = passedThesisConsumer->commitOffset([offset], duration = 10000);
        }
    }
}
