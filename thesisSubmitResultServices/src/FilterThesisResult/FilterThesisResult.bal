import ballerina/io;
import wso2/kafka;
import ballerina/encoding;
import ballerina/docker;

@docker:Config {
	name: "cfilterService",
	tag: "v1.0"
}

@kubernetes:Deployment {
    image:"filter-service",
    name:"kafka-filterService"
}

string topicVerifiedThesis = "pre-verified-thesis";
string topicFailedThesis = "failed-thesis";
string topicPassedThesis = "passed-thesis";

kafka:ConsumerConfig consumerConfigs = {
    bootstrapServers: "localhost:9090",
    groupId: "verification-thesis-consumer",
    topics: [topicVerifiedThesis]
};

listener kafka:SimpleConsumer thesisConsumer = new(consumerConfigs);

kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9090",
    clientID: "verification-thesis-producer",
    noRetries: 3
};

kafka:SimpleProducer filteredThesisProducer = new(producerConfigs);

type Thesis record {
    string thesisTitle;
    int thesisprecentage;
    string studentName;
    int studentNumber;
    string userName;
    string userId;
};

type ProcessedThesis record {
    boolean invalid;
    Thesis thesis;
};

service filterVerificationService on thesisConsumer {
    resource function onMessage (kafka:SimpleConsumer simpleConsumer, kafka:ConsumerRecord[] records) {
        foreach var entry in records {
            byte[] serializedMsg = entry.value;
            string msg = encoding:byteArrayToString(serializedMsg);

            io:StringReader receivedString = new(msg);
            var receivedThesisJson = receivedString.readJson();

            if (receivedThesisJson is error) {
                io:print("Filter Thesis\nERROR!!!!!!!\nError Parsing Json: ");
                io:println(receivedThesisJson);
            } else {
                string topicSendStudent = "";
                var receivedThesis = ProcessedThesis.convert(receivedThesisJson);
                if (receivedThesis is error) {

                    io:print("Filter Thesis\nERROR!!!!!!! \nCouldn't convert recevied thesis json file to Record type - ReceivedThesis: ");
                    io:println(receivedThesis);

                } else {
                    if (receivedThesis.invalid) {

                        topicSendStudent = topicFailedThesis;
                        io:println("Filter Thesis\nINFO!!!!\nInvalid Thesis found");

                    } else if (!receivedThesis.invalid) {

                        topicSendStudent = topicPassedThesis;
                        io:println("Filter Thesis\nINFO!!!!!\nThesis is fine. Sending to student");
                    }

                    byte[] thesisToSend = receivedThesisJson.thesis.toString().toByteArray("UTF-8");
                    io:println("[Filter Thesis]\n[INFO]\nTry to send thesis to the topic: " + topicSendStudent);
                    var sendResult = filteredThesisProducer->send(thesisToSend, topicSendStudent);
                    io:println("[Filter Thesis]\n[INFO]\nThesis sent.");

                    if (sendResult is error) {
                        io:print("Filter Thesis\nERROR!!!\nSending the thesis failed: ");
                        io:println(sendResult);
                    } else {
                        io:println("Filter Thesis\nINFO!!!\nThesis Published to: \"" + topicSendStudent + "\"");
                    }
                }
            }
            io:println("Filter Thesis\nINFO!!!!!!\nReceived Message:\n" + msg + "\n\n");
        }
    }
}
