import ballerina/io;
import ballerina/http;
import ballerina/runtime;

type Thesis record {
    string thesisTitle;
    int thesisprecentage;
    string studentName;
    int studentNumber;
    string userName;
    string userId;
};


http:Client clientEndpoint = new("http://localhost:9090");

public function main(string... args) {
    http:Request req = new;
    Thesis thesis = {
        thesisTitle: thesisTitle,
        thesisprecentage: thesisprecentage,
        studentName: studentName,
        studentNumber: studentNumber,
        userName: userName,
        userId: userId
    };

    json msg = {};
    msg.header = "Thesis";
    var thesisJson = json.convert(thesis);
    if (thesisJson is error) {
        msg.body = "";
    } else {
        msg.body = thesisJson;
    }
    req.setJsonPayload(msg);

    while(true) {
        var response = clientEndpoint->put("/thesis/submitThesis", req);
        if (response is error) {
            io:print("Response is invalid: ");
            io:println(response);
        } else {
            io:println("PUT request:");
            var resMsg = response.getJsonPayload();
            if (resMsg is error) {
                io:print("JSON payload is invalid: ");
                io:println(resMsg);
            } else {
                io:print("");
                io:println(resMsg);
            }
        }
        runtime:sleep(2000);
    }
}
