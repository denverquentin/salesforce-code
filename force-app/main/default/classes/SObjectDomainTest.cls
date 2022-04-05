@IsTest
private class SObjectDomainTest {

	private static Id testLogId;

	@testSetup
	static void setup() {
		TestData.createUserWithPermissionSet();
		System.runAs(TestData.getUserWithPermissionSet()) {
			Log__c l = new Log__c(Location__c = 'Gonna Delete');
			insert l;
			testLogId = l.Id;
			delete l;
		}
	}


	@IsTest
	static void testValidationWithoutDML() {
		SObjectDomain.TestSObjectDomain logs = new SObjectDomain.TestSObjectDomain(new Log__c[] { new Log__c (Location__c = 'Test', Message__c = 'Existing Account') });
		logs.onValidate();
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You must provide Information.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Log__c.Information__c, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
		logs = new SObjectDomain.TestSObjectDomain(new SObject[] { new Log__c (Location__c = 'Test', Message__c = 'Existing Account') }, Log__c.SObjectType);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You must provide Information.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Log__c.Information__c, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
	}

	@IsTest
	static void testInsertValidationFailedWithoutDML() {
		Log__c l = new Log__c( Location__c = 'Test', Message__c = 'Existing Account');
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onInsert(new Log__c[] { l });
		System.assertEquals(true, SObjectDomain.test.database.hasRecords());
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You must provide Information.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Log__c.Information__c, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
	}

	@IsTest
	static void testUpdateValidationFailedWithoutDML() {
		Log__c oldLog = (Log__c)Log__c.sObjectType.newSObject(testLogId);
		oldLog.Location__c = 'Existing rec';
		oldLog.Information__c = 'Test'; 
		Log__c newLog = (Log__c)Log__c.sObjectType.newSObject(testLogId); 
		newLog.Location__c = 'New rec';
		newLog.Information__c = 'Test';
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onUpdate(new Log__c[] { newLog }, new Map<Id, SObject> { newLog.Id => oldLog });
		System.assertEquals(true, SObjectDomain.test.database.hasRecords());
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You cannot change the Log Location once it has been created.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Log__c.Location__c, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
	}

	@IsTest
	static void testOnBeforeDeleteWithoutDML() {
		Log__c l1 = new Log__c(Location__c = 'Gonna Delete');
		insert l1;
		Id testLogId = l1.Id;
		delete l1;

		Log__c l = (Log__c) Log__c.sObjectType.newSObject(testLogId);
		l.Information__c = 'Test';
		l.Message__c = 'Test';
		l.Location__c = 'here';
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onDelete(new Map<ID, Log__c> { l.Id => l });
		System.assertEquals(true, SObjectDomain.test.database.hasRecords());
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You cannot delete this Log.', SObjectDomain.errors.getAll()[0].message);
	}

	@IsTest
	static void testOnAfterUndeleteWithoutDML() {
		Log__c l = (Log__c)Log__c.sObjectType.newSObject(testLogId);
		l.Location__c = 'Test';
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onUndelete(new list<Log__c> { l });
		System.assertEquals(true, SObjectDomain.test.database.hasRecords());
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
	}

	@IsTest
	static void testObjectSecurity() {
		// Create a user which will not have access to the test object type
		User testUser = createChatterExternalUser();
		if (testUser != null) { // only run the test if able to create a user with low enough acess
			System.runAs(testUser) {
				// Test Create object security
				Log__c l = new Log__c(Location__c = 'Test');
				SObjectDomain.test.database.onInsert(new Log__c[] { l });
				try {
					SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
					System.assert(false, 'Expected access denied exception');
				} catch (Exception e) {
					System.assertEquals('You do not have permission to create Log__c records.', e.getMessage());
				}

				// Test Update object security
				Log__c existingLog = (Log__c)Log__c.sObjectType.newSObject(testLogId);
				existingLog.Location__c = 'Test';
				SObjectDomain.test.database.onUpdate(new List<Log__c> { l }, new Map<Id,Log__c> { l.Id => l });
				try {
					SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
					System.assert(false, 'Expected access denied exception');
				} catch (Exception e) {
					System.assertEquals('You do not have permission to update Log__c records.', e.getMessage());
				}

				// Test Delete object security
				SObjectDomain.test.database.onDelete(new Map<Id,Log__c> { l.Id => l });
				try {
					SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
					System.assert(false, 'Expected access denied exception');
				} catch (Exception e) {
					System.assertEquals('You do not have permission to delete Log__c records.', e.getMessage());
				}
			}
		}
	}

 	@IsTest
	static void testErrorLogging() {
		// Test static helpers for raise none domain object instance errors
		Log__c l = new Log__c(Location__c = 'Test', Information__c = 'Existing');
		SObjectDomain.errors.error('Error', l);
		SObjectDomain.errors.error('Error', l, Log__c.Location__c);
		System.assertEquals(2, SObjectDomain.errors.getAll().size());
		System.assertEquals('Error', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals('Error', SObjectDomain.errors.getAll()[1].message);
		System.assertEquals(Log__c.Location__c, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[1]).field);
		SObjectDomain.errors.clearAll();
		System.assertEquals(0, SObjectDomain.errors.getAll().size());
	}

	@IsTest
	static void testTriggerState() {
		Log__c l = new Log__c(Location__c = 'Test', Information__c = 'Existing');
		SObjectDomain.test.database.onInsert(new Log__c[] { l });
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectStatefulDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('Error on Record Test', SObjectDomain.errors.getAll()[0].message);
	}

	@IsTest
	static void testRecursiveTriggerState() {
		Log__c l = new Log__c(Location__c = 'Test Recursive 1', Information__c = 'Existing');
		SObjectDomain.test.database.onInsert(new Log__c[] { l });
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectStatefulDomainConstructor.class);
		System.assertEquals(2, SObjectDomain.errors.getAll().size());
		System.assertEquals('Error on Record Test Recursive 2', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals('Error on Record Test Recursive 1', SObjectDomain.errors.getAll()[1].message);
	}

	@IsTest
	static void testOnValidateBehaviorDefault() {
		Log__c oldLog = (Log__c) Log__c.sObjectType.newSObject(testLogId);
		oldLog.Location__c = 'Test Default Behavior';
		oldLog.Information__c = 'Existing Account';
		Log__c newLog = (Log__c) Log__c.sObjectType.newSObject(testLogId);
		newLog.Location__c = 'Test Default Behavior';
		newLog.Information__c = 'New Account';
		Boolean hasError = false;
		try {
			SObjectDomain.test.database.onUpdate(new Log__c[] { newLog }, new Map<Id,SObject> { newLog.Id => oldLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectOnValidateBehaviorConstructor.class);
		} catch (Exception e) {
			Utils.logError(e);
			hasError = true;
		}
		System.assertEquals(false, hasError);
	}

	@IsTest
	static void testOnValidateBehaviorOld() {
		Log__c oldLog = (Log__c)Log__c.sObjectType.newSObject(testLogId);
		oldLog.Location__c = 'Test Enable Old Behavior';
		oldLog.Information__c = 'Existing Account';
		Log__c newLog = (Log__c)Log__c.sObjectType.newSObject(testLogId);
		newLog.Location__c = 'Test Enable Old Behavior';
		newLog.Information__c = 'New Account';
		SObjectDomain.test.database.onUpdate(new Log__c[] { newLog }, new Map<Id,SObject> { newLog.Id => oldLog });
		try {
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectOnValidateBehaviorConstructor.class);
			System.assert(false, 'Expected exception');
		} catch (Exception e) {
			Utils.logError(e);
			System.assertEquals('onValidate called', e.getMessage());
		}
	}

	// Create test user
	private static User createChatterExternalUser() {
		// Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
		List<Profile> testProfiles = [Select Id From Profile where UserLicense.Name = 'Chatter External' limit 1];
		if (testProfiles.size() != 1) {
			return null;
		}
		// Can only proceed with test if we can successfully insert a test user
		String testUsername = System.now().format('yyyyMMddhhmmss') + '@testqf.com';
		User testUser = new User(Alias = 'test1', Email='testuser1@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = testProfiles[0].Id, TimeZoneSidKey='America/Los_Angeles', UserName=testUsername);
		try {
			insert testUser;
		} catch (Exception e) {
			return null;
		}
		return testUser;
	}

	@IsTest
	static void testDisableTriggerEventsBehavior() {
		// The following tests that the ability to enable/disable all trigger events works as required
		boolean bError = false;
		String  sErrorMessage = '';
		Log__c oldLog = (Log__c)Log__c.sObjectType.newSObject(testLogId);
		oldLog.Location__c = 'Test';
		oldLog.Information__c = 'Existing';
		Log__c newLog = (Log__c)Log__c.sObjectType.newSObject(testLogId);
		newLog.Location__c = 'Test';
		newLog.Information__c = 'New';
		// these will be called multiple times making sure the correct error message comes back out
		// so... there are alot of tests to do here sadly and remember everything is reversed and you need to run backwards!
		// 1 - all disabled
		try {
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).disableAll();
			SObjectDomain.test.database.onInsert(new Log__c[] { newLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			bError = true;
		}
		System.AssertEquals(false, bError, 'Error - Trigger events have been fired when they are disabled');

		// Insert!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterInsert();
			SObjectDomain.test.database.onInsert(new Log__c[] { newLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
			Utils.log('e.getMessage() = ' + e.getMessage());
		}
		System.AssertEquals('onAfterInsert called', sErrorMessage, 'Error - After Insert Event is enabled but did not run');

		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableBeforeInsert();
			SObjectDomain.test.database.onInsert(new Log__c[] { newLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onBeforeInsert called', sErrorMessage, 'Error - Before Insert Event is enabled but did not run');

		// Update!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterUpdate();
			SObjectDomain.test.database.onUpdate(new Log__c[] { newLog }, new Map<Id, SObject> { newLog.Id => oldLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onAfterUpdate called', sErrorMessage, 'Error - After Update Event is enabled but did not run');

		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableBeforeUpdate();
			SObjectDomain.test.database.onUpdate(new Log__c[] { newLog }, new Map<Id, SObject> { newLog.Id => oldLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage(); 
		}
		System.AssertEquals('onBeforeUpdate called', sErrorMessage, 'Error - Before Update Event is enabled but did not run');

		// Delete!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterDelete();
			SObjectDomain.test.database.onDelete(new Map<Id,Log__c> { newLog.Id => newLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onAfterDelete called', sErrorMessage, 'Error - After Delete Event is enabled but did not run');

		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableBeforeDelete();
			SObjectDomain.test.database.onDelete(new Map<Id,Log__c> { newLog.Id => newLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage(); 
		}
		System.AssertEquals('onBeforeDelete called', sErrorMessage, 'Error - Before Delete Event is enabled but did not run');

		// Undelete!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterUndelete();
			SObjectDomain.test.database.onUndelete(new Log__c[] { newLog });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onAfterUndelete called', sErrorMessage, 'Error - After Undelete Event is enabled but did not run');
	}
}