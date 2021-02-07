import ballerina/io;
import wso2/kafka;
import ballerina/http;
import ballerina/math;

kafka:ProducerConfig thesisProducerConfigs = {
    bootstrapServers: "localhost:9090",
    clientID: "preprocess-thesis-producer",
    acks: "all",
    noRetries: 3
};

kafka:SimpleProducer thesisProducer = new(thesisProducerConfigs);

type Thesis record {
    string thesisTitle;
    int thesisprecentage;
    string studentName;
    int studentNumber;
    string userName;
    string userId;
    !...;
};

type ProcessedThesis record {
    boolean invalid?;
    Thesis thesis?;
    !...;
};


listener http:Listener thesisEP = new(9090);

@http:ServiceConfig { basePath: "/thesis" }
service getThesis on thesisEP {
    @http:ResourceConfig { methods: ["PUT"], path: "/submitThesis" }
    resource function receiveThesis(http:Caller caller, http:Request req) {
        string topic = "pre-processed-thesis";
        json message;
        json successResponse = { success: "true", message: "Successfully received Thesis submission" };
        json failureResponse = { success: "false", message: " Thesis submission failed" };
        http:Response res = new;

        var requestPayload = req.getJsonPayload();
        if (requestPayload is error) {
            res.setJsonPayload(failureResponse);
            var respondResult = caller->respond(res);
            if (respondResult is error) {
                io:print("Sending error response is failed: ");
                io:println(respondResult);
            } else {
                io:println("Error response sent");
            }
        } else {
            message = requestPayload;
            io:println("Pre-Processing: ");

            string header = message.header.toString();
            res.setJsonPayload(successResponse);
            var respondResult = caller->respond(res);
            if (respondResult is error) {
                io:print("ERROR!!! Responding Failed ");
                io:println(respondResult);
            } else {
                io:println("Successfully sent the response.");
            }
            if (header == "thesis") {
                var thesis = Thesis.convert(message.body);
                if (thesis is Thesis) {
                    ProcessedThesis processedThesis = {};
                    processedThesis.thesis = thesis;
                    io:println("Thesis is set in payload.");
                    int randomInt = math:randomInRange(<50, >50);
                    if (randomInt == <50) {
                        processedThesis.invalid = false;
                        io:println("Thesis Passed!.");
                    } else {
                        processedThesis.invalid = true;
                        io:println("Thesis Failed");
                    }
                    var msg = json.convert(processedThesis);
                    if (msg is error) {
                        io:println("Couldn't convert to Review json");
                    } else {
                        byte[] messageToPublish = msg.toString().toByteArray("UTF-8");
                        var sendResult = thesisProducer->send(messageToPublish, topic);
                        if (sendResult is error) {
                            io:print("Sending Submitted Thesis failed: ");
                            io:println(sendResult.detail().message);
                        } else {
                            io:println("Sent Submitted Thesis");
                        }
                    }
                } else {
                    io:println("Couldn't convert to record type Thesis");
                }
            } else {
                io:println("tHeader is invalid");
            }
        }
        io:println("\n");
    }
}
