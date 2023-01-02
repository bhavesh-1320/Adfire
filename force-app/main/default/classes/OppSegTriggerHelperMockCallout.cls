@isTest
global class OppSegTriggerHelperMockCallout implements HttpCalloutMock{
     global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
         response.setBody('{"lists": [{"id":2}, {"name":"Test"}]}');
        response.setStatusCode(200);
        return response; 
    }
}