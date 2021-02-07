import ballerina/graphql;
import ballerina/http;

// create an http:Listener
http:Listener httpListener = check new(9090);

//exposes a GraphQL service on HTTP listener
service graphql:Service /graphql on new graphql:Listener(httpListener) {

    resource function get application(int studentNumber) returns STUDENT|error {

        if (studentNumber < students.length()) {
            return students[studentNumber];
        } else {
            return error("STUDENT with studentNumber " + studentNumber.toString() + " not found");
        }
    }
}

// records types to return data

public type STUDENT record {
    int studentNumber;
    string surname;
    string firstName;
    int idNumber;
    string course;
    string studyLevel;
    string researchTopic;
    string applicationStatus;
    string presentationDate;
    string presentationResult;
    byte[] proposal;
    string proposalResult;
    byte[] thesis;
    string thesisResult;
    SUPERVISOR supervisor;
};
public type SUPERVISOR record {
    int supervisorID;
    string surname;
    string firstName;
};

// array of student records

STUDENT student1 = {
    studentNumber: 22440125,
    surname: "Simio",
    firstName: "Sacky",
    idNumber: 20110566421,
    course: "Informatics",
    studyLevel: "honours",
    researchTopic: "mobile applications",
    applicationStatus: "",
    presentationDate: "",
    presentationResult: "",
    proposal: 1024,
    proposalResult: "",
    thesis: 1024,
    thesisResult: "",
    supervisor: {
        supervisorID: 5,
        surname: "Drino",
        firstName: "Shifidi"
    }
};

STUDENT[] students = [student1];