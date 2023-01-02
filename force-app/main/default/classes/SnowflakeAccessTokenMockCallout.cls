@isTest
global class SnowflakeAccessTokenMockCallout implements HttpCalloutMock {
   global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('[{"Value":{"TT":{"value":"test"}}}]');
        response.setStatusCode(200);
        return response; 
    } 
}