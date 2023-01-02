@isTest
global class campaignFolderCreateClsMockCallout implements HttpCalloutMock{
     global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
         response.setBody('{"files": [{"id":"2"}, {"name":"Test"}]}');
        response.setStatusCode(200);
        return response; 
    }
}