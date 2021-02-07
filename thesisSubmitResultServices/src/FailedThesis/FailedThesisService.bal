import ballerina/io;
import wso2/kafka;
import ballerina/encoding;
import ballerina/docker;

@docker:Config {
	name: "cfailedThesisService",
	tag: "v1.0"
}

@kubernetes:Deployment {
    image:"failed-thesis-service",
    name:"kafka-failedThesisService"
}

string topicFailedThesis = "failed-thesis";

kafka:ConsumerConfig failedThesisConsumerConfigs = {
    bootstrapServers: "localhost:9090",
    groupId: "FailedThesisConsumers",
    topics: [topicFailedThesis]
};

listener kafka:SimpleConsumer failedThesisConsumer = new(failedThesisConsumerConfigs);

service handleFailedThesisService on failedThesisConsumer {
    resource function onMessage(kafka:SimpleConsumer simpleConsumer, kafka:ConsumerRecord[] records) {
        foreach var entry in records {
            io:println("Failed Thesis Received");
            byte[] serializedMsg = entry.value;
            string msg = encoding:byteArrayToString(serializedMsg);

            io:println("Failed Thesis: ");
            io:println("[HandleFiltered]\n[INFO]\n" + msg + "\n\n");

            kafka:TopicPartition topicPartition = {topic: entry.topic, partition: entry.partition};
            kafka:PartitionOffset offset = {partition: topicPartition, offset: entry.offset};
            var commitAcceptedResult = failedThesisConsumer->commitOffset([offset], duration = 10000);
        }
    }
}
