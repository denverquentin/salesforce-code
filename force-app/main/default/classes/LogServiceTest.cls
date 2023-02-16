@IsTest
private class LogServiceTest {

	@testSetup
	static void setup() {
		TestData.createUserWithPermissionSet();
	}

	@IsTest
	static void testPermissionAndErrorHandling() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			Log l = new Log();
			LogService.insertLog(l);

			// should fail silently because of missing permission
			List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c];
			Assert.areEqual(logs.size(), 0);
		}
	}


	@IsTest
	static void testLogServiceEmptyLog() {
		System.runAs(TestData.getUserWithPermissionSet()) {
			// test that it can handle a null parameter without throwing an exception
			Log nullLog = null;
			LogService.insertLog(nullLog);


			// test all blank values to make sure no issues with nulls
			Log l = new Log();
			LogService.insertLog(l);

			List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c];
			Utils.log('logs.size() = ' + logs.size());

			Assert.areEqual(logs.size(), 1);
			Assert.isNull(logs[0].Message__c);
			Assert.isNull(logs[0].Location__c);
			Assert.isNull(logs[0].Information__c); // nothing written if not logging and exception and field is not set
		}
	}


	@IsTest
	static void testLogGlobalConstructorException() {
		System.runAs(TestData.getUserWithPermissionSet()) {
			Log l = new Log(new Constants.UnexpectedException('Oops I did it again'), 'Class.Method_Location', 'Information');
			LogService.insertLog(l);

			List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c];
			Utils.log('logs.size() = ' + logs.size());

			Assert.areEqual(logs.size(), 1);
			Assert.areEqual('Class.Method_Location', logs[0].Location__c);
			Assert.areEqual('Oops I did it again', logs[0].Message__c);
			Assert.isNotNull(logs[0].Information__c); // something is always written to this field

			LogService.deleteOldLogRecords(null); // code coverage
			// can't test that one was deleted since we can't have a negative integer
		}
	}


	@IsTest
	static void testLogGlobalConstructorMessage() {
		System.runAs(TestData.getUserWithPermissionSet()) {
			Log l = new Log('Oops I did it again', 'Class.Method_Location', 'Information');
			LogService.insertLog(l);

			List<Log__c> logs = [select Id, Message__c, Location__c, Information__c from Log__c];
			Utils.log('logs.size() = ' + logs.size());

			Assert.areEqual(logs.size(), 1);
			Assert.areEqual('Class.Method_Location', logs[0].Location__c);
			Assert.areEqual('Oops I did it again', logs[0].Message__c);
			Assert.isNotNull(logs[0].Information__c); // something is always written to this field when logging an exception
		}
	}


	@IsTest
	static void testLogService() {
		System.runAs(TestData.getUserWithPermissionSet()) {

			List<Log> logRecords = new List<Log>();

			for (Integer x = 0; x < 10; x++) {
				try {
					Constants.UnexpectedException ex = new Constants.UnexpectedException('Oops I did it again');
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

			Assert.areEqual(logs.size(), 10);
			Assert.areEqual(logs[0].Message__c, 'Oops I did it again');
			Assert.areEqual(logs[0].Location__c, 'LogServiceTest.testLogService');
			Assert.isNotNull(logs[0].Information__c); // something is always written to this field when logging an exception
		}
	}
}
