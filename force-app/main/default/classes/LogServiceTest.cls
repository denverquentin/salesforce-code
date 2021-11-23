@IsTest
private class LogServiceTest {
	@IsTest
	static void testPermissionAndErrorHandling() {
		Log l = new Log();
		LogService.insertLog(l);
		// should fail silently because of missing permission
		List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c];
		System.assert(logs.size() == 0);
	}


	@IsTest
	static void testLogServiceEmptyLog() {
		// test that it can handle a null parameter without throwing an exception
		Log nullLog = null;
		LogService.insertLog(nullLog);

		// test all blank values to make sure no issues with nulls
		Log l = new Log();
		LogService.insertLog(l);

		List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c];
		Utils.log('logs.size() = ' + logs.size());

		System.assert(logs.size() == 1);
		System.assertEquals(logs[0].Message__c, null);
		System.assertEquals(logs[0].Location__c, null);
		System.assert(String.isNotBlank(logs[0].Information__c)); // something is always written to this field

		// TODO: test error handling - can assign a user that doesn't have access to Log__c object
		//LogService.insertLog(l);
	}


	@IsTest
	static void testLogGlobalConstructor() {
		Log l = new Log(new Constants.UstException('Oops I did it again'), 'Class.Method_Location', 'Information');
		LogService.insertLog(l);

		List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c];
		Utils.log('logs.size() = ' + logs.size());

		System.assert(logs.size() == 1);
		System.assertEquals('Location', logs[0].Location__c);
		System.assertEquals('Oops I did it again', logs[0].Message__c);
		System.assert(String.isNotBlank(logs[0].Information__c)); // something is always written to this field

		LogService.deleteOldLogRecords(null); // code coverage
		// can't test that one was deleted since we can't have a negative integer
	}


	@IsTest
	static void testLogService() {
		List<Log> logRecords = new List<Log>();

		for (Integer x = 0; x < 10; x++) {
			try {
				Constants.UstException ex = new Constants.UstException('Oops I did it again');
				throw ex;
			} catch (Exception e) {
				String data = JSON.serializePretty(e);
				logRecords.add(new Log(e, 'LogServiceTest.testLogService', data));
			}
		}
		// this should insert 10 records with almost identical data
		LogService.insertLogs(logRecords);

		List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c WHERE Message__c = 'Oops I did it again'];
		Utils.log('logs.size() = ' + logs.size());

		System.assert(logs.size() == 10);
		System.assertEquals(logs[0].Message__c, 'Oops I did it again');
		System.assertEquals(logs[0].Location__c, 'LogServiceTest.testLogService');
		System.assert(String.isNotBlank(logs[0].Information__c));
	}
}