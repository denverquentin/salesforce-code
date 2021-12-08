// query apex test coverage to verify all
// classes have > 85% coverage
// gotta use the Tooling API to get the data
String query = 'select+ApexClassOrTrigger.Name,+NumLinesUncovered,+NumLinesCovered+from+ApexCodeCoverageAggregate+where+ApexClassOrTrigger.Name+!=+NULL+AND+NumLinesCovered+!=+NULL+AND+NumLinesUncovered+!=+NULL+order+by+ApexClassOrTrigger.Name';
HttpRequest req = new HttpRequest();
req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
req.setHeader('Content-Type', 'application/json');
req.setEndpoint(Utils.getSalesforceBaseUrl() + '/services/data/v52.0/tooling/query/?q=' + query);
req.setMethod('GET');
Utils.log('request = ' + req.getBody());

Http h = new Http();
HttpResponse res = h.send(req);
Map<String,Object> payload = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());

for (Object data : (List<Object>)payload.get('records')) {
	Map<String,Object> record = (Map<String,Object>)data;
	//Utils.log('record = ' + record);

	Map<String,Object> classObject = (Map<String,Object>)record.get('ApexClassOrTrigger');
	String className = (String)classObject.get('Name');
	Integer numLinesCovered = (Integer)record.get('NumLinesCovered');
	Integer numLinesUncovered = (Integer)record.get('NumLinesUncovered');

	Utils.log('className = ' + className);
	Utils.log('numLinesCovered = ' + numLinesCovered);
	Utils.log('numLinesUncovered = ' + numLinesUncovered);

	Integer totalLines = numLinesCovered + numLinesUncovered;
	Utils.log('totalLines = ' + totalLines);
	if (totalLines > 0) {
		Integer percentCovered = (numLinesCovered * 100) / totalLines;
		Utils.log('percentCovered = ' + percentCovered + '%');

		if (percentCovered < 85) {
			throw new Constants.ValidationException('Test coverage for ' + className + ' is ' + percentCovered + '%. It must be 85% or higher to continue.');
		}
	}
	Utils.log('---');
}
