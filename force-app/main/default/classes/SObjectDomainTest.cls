@IsTest
private class SObjectDomainTest {
	@IsTest
	static void testValidationWithoutDML() {
		SObjectDomain.TestSObjectDomain opps = new SObjectDomain.TestSObjectDomain(new Opportunity[] { new Opportunity (Name = 'Test', Type = 'Existing Account') });
		opps.onValidate();
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You must provide an Account for Opportunities for existing Customers.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Opportunity.AccountId, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
		opps = new SObjectDomain.TestSObjectDomain(new SObject[] { new Opportunity (Name = 'Test', Type = 'Existing Account') }, Opportunity.SObjectType);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You must provide an Account for Opportunities for existing Customers.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Opportunity.AccountId, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
	}

	@IsTest
	static void testInsertValidationFailedWithoutDML() {
		Opportunity opp = new Opportunity( Name = 'Test', Type = 'Existing Account');
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onInsert(new Opportunity[] { opp });
		System.assertEquals(true, SObjectDomain.test.database.hasRecords());
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You must provide an Account for Opportunities for existing Customers.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Opportunity.AccountId, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
	}

	@IsTest
	static void testUpdateValidationFailedWithoutDML() {
		Id oppId = '00' + '6E000000' + '6mkRQ';
		Opportunity oldOpp = (Opportunity)Opportunity.sObjectType.newSObject(oppId);
		oldOpp.Name = 'Test';
		oldOpp.Type = 'Existing Account'; 
		Opportunity newOpp = (Opportunity)Opportunity.sObjectType.newSObject(oppId);
		newOpp.Name = 'Test';
		newOpp.Type = 'New Account';
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp });
		System.assertEquals(true, SObjectDomain.test.database.hasRecords());
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You cannot change the Opportunity type once it has been created.', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals(Opportunity.Type, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[0]).field);
	}

	@IsTest
	static void testOnBeforeDeleteWithoutDML() {
		Id oppId = '00' + '6E000000' + '6mkRQ';
		Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject(oppId);
		opp.Name = 'Test';
		opp.Type = 'Existing Account';
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onDelete(new Map<ID, Opportunity> { opp.Id => opp });
		System.assertEquals(true, SObjectDomain.test.database.hasRecords());
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('You cannot delete this Opportunity.', SObjectDomain.errors.getAll()[0].message);
	}

	@IsTest
	static void testOnAfterUndeleteWithoutDML() {
		Id oppId = '00' + '6E000000' + '6mkRQ';
		Opportunity opp = (Opportunity) Opportunity.sObjectType.newSObject(oppId);
		opp.Name = 'Test';
		opp.Type = 'Existing Account';
		System.assertEquals(false, SObjectDomain.test.database.hasRecords());
		SObjectDomain.test.database.onUndelete(new list<Opportunity> { opp });
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
				Opportunity opp = new Opportunity (Name = 'Test', Type = 'Existing Account');
				SObjectDomain.test.database.onInsert(new Opportunity[] { opp });
				try {
					SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
					System.assert(false, 'Expected access denied exception');
				} catch (Exception e) {
					System.assertEquals('You do not have permission to create Opportunity records.', e.getMessage());
				}

				// Test Update object security
				Id oppId = '00' + '6E000000' + '6mkRQ';
				Opportunity existingOpp = (Opportunity)Opportunity.sObjectType.newSObject(oppId);
				existingOpp.Name = 'Test';
				existingOpp.Type = 'Existing Account';
				SObjectDomain.test.database.onUpdate(new List<Opportunity> { opp }, new Map<Id, Opportunity> { opp.Id => opp });
				try {
					SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
					System.assert(false, 'Expected access denied exception');
				} catch (Exception e) {
					System.assertEquals('You do not have permission to update Opportunity records.', e.getMessage());
				}

				// Test Delete object security
				SObjectDomain.test.database.onDelete(new Map<Id, Opportunity> { opp.Id => opp });
				try {
					SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDomainConstructor.class);
					System.assert(false, 'Expected access denied exception');
				} catch (Exception e) {
					System.assertEquals('You do not have permission to delete Opportunity records.', e.getMessage());
				}
			}
		}
	}

	@IsTest
	static void testErrorLogging() {
		// Test static helpers for raise none domain object instance errors
		Opportunity opp = new Opportunity(Name = 'Test', Type = 'Existing Account');
		SObjectDomain.errors.error('Error', opp);
		SObjectDomain.errors.error('Error', opp, Opportunity.Type);
		System.assertEquals(2, SObjectDomain.errors.getAll().size());
		System.assertEquals('Error', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals('Error', SObjectDomain.errors.getAll()[1].message);
		System.assertEquals(Opportunity.Type, ((SObjectDomain.FieldError)SObjectDomain.errors.getAll()[1]).field);
		SObjectDomain.errors.clearAll();
		System.assertEquals(0, SObjectDomain.errors.getAll().size());
	}

	@IsTest
	static void testTriggerState() {
		Opportunity opp = new Opportunity(Name = 'Test', Type = 'Existing Account');
		SObjectDomain.test.database.onInsert(new Opportunity[] { opp });
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectStatefulDomainConstructor.class);
		System.assertEquals(1, SObjectDomain.errors.getAll().size());
		System.assertEquals('Error on Record Test', SObjectDomain.errors.getAll()[0].message);
	}

	@IsTest
	static void testRecursiveTriggerState() {
		Opportunity opp = new Opportunity(Name = 'Test Recursive 1', Type = 'Existing Account');
		SObjectDomain.test.database.onInsert(new Opportunity[] { opp });
		SObjectDomain.triggerHandler(SObjectDomain.TestSObjectStatefulDomainConstructor.class);
		System.assertEquals(2, SObjectDomain.errors.getAll().size());
		System.assertEquals('Error on Record Test Recursive 2', SObjectDomain.errors.getAll()[0].message);
		System.assertEquals('Error on Record Test Recursive 1', SObjectDomain.errors.getAll()[1].message);
	}

	@IsTest
	static void testOnValidateBehaviorDefault() {
		Id oppId = '00' + '6E000000' + '6mkRQ';
		Opportunity oldOpp = (Opportunity) Opportunity.sObjectType.newSObject(oppId);
		oldOpp.Name = 'Test Default Behavior';
		oldOpp.Type = 'Existing Account';
		Opportunity newOpp = (Opportunity) Opportunity.sObjectType.newSObject(oppId);
		newOpp.Name = 'Test Default Behavior';
		newOpp.Type = 'New Account';
		Boolean hasError = false;
		try {
			SObjectDomain.test.database.onUpdate(new Opportunity[] { newOpp }, new Map<Id,SObject> { newOpp.Id => oldOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectOnValidateBehaviorConstructor.class);
		} catch (Exception e) {
			hasError = true;
		}
		System.assertEquals(false, hasError);
	}

	@IsTest
	static void testOnValidateBehaviorOld() {
		Id oppId = '00' + '6E000000' + '6mkRQ';
		Opportunity oldOpp = (Opportunity)Opportunity.sObjectType.newSObject(oppId);
		oldOpp.Name = 'Test Enable Old Behavior';
		oldOpp.Type = 'Existing Account';
		Opportunity newOpp = (Opportunity)Opportunity.sObjectType.newSObject(oppId);
		newOpp.Name = 'Test Enable Old Behavior';
		newOpp.Type = 'New Account';
		SObjectDomain.test.database.onUpdate(new Opportunity[] { newOpp }, new Map<Id,SObject> { newOpp.Id => oldOpp });
		try {
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectOnValidateBehaviorConstructor.class);
			System.assert(false, 'Expected exception');
		} catch (Exception e) {
			System.assertEquals('onValidate called', e.getMessage());
		}
	}

	// Create test user
	private static User createChatterExternalUser() {
		// Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
		List<Profile> testProfiles = [Select Id From Profile where UserLicense.Name='Chatter External' limit 1];
		if (testProfiles.size() != 1) {
			return null;
		}
		// Can only proceed with test if we can successfully insert a test user
		String testUsername = System.now().format('yyyyMMddhhmmss') + '@testorg.com';
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
		Id oppId = '00' + '6E000000' + '6mkRQ';
		Opportunity oldOpp = (Opportunity)Opportunity.sObjectType.newSObject(oppId);
		oldOpp.Name = 'Test';
		oldOpp.Type = 'Existing';
		Opportunity newOpp = (Opportunity)Opportunity.sObjectType.newSObject(oppId);
		newOpp.Name = 'Test';
		newOpp.Type = 'New';
		// these will be called multiple times making sure the correct error message comes back out
		// so... there are alot of tests to do here sadly and remember everything is reversed and you need to run backwards!
		// 1 - all disabled
		try {
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).disableAll();
			SObjectDomain.test.database.onInsert(new Opportunity[] { newOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			bError = true;
		}
		System.AssertEquals(false, bError, 'Error - Trigger events have been fired when they are disabled');

		// Insert!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterInsert();
			SObjectDomain.test.database.onInsert(new Opportunity[] { newOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
			Utils.log('e.getMessage() = ' + e.getMessage());
		}
		System.AssertEquals('onAfterInsert called', sErrorMessage, 'Error - After Insert Event is enabled but did not run');

		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableBeforeInsert();
			SObjectDomain.test.database.onInsert(new Opportunity[] { newOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onBeforeInsert called', sErrorMessage, 'Error - Before Insert Event is enabled but did not run');

		// Update!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterUpdate();
			SObjectDomain.test.database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onAfterUpdate called', sErrorMessage, 'Error - After Update Event is enabled but did not run');

		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableBeforeUpdate();
			SObjectDomain.test.database.onUpdate(new Opportunity[] { newOpp }, new Map<Id, SObject> { newOpp.Id => oldOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage(); 
		}
		System.AssertEquals('onBeforeUpdate called', sErrorMessage, 'Error - Before Update Event is enabled but did not run');

		// Delete!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterDelete();
			SObjectDomain.test.database.onDelete(new Map<Id, Opportunity> { newOpp.Id => newOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onAfterDelete called', sErrorMessage, 'Error - After Delete Event is enabled but did not run');

		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableBeforeDelete();
			SObjectDomain.test.database.onDelete(new Map<Id, Opportunity> { newOpp.Id => newOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage(); 
		}
		System.AssertEquals('onBeforeDelete called', sErrorMessage, 'Error - Before Delete Event is enabled but did not run');

		// Undelete!
		try {
			// now lets go after insert and then before
			SObjectDomain.getTriggerEvent(SObjectDomain.TestSObjectDisableBehaviorConstructor.class).enableAfterUndelete();
			SObjectDomain.test.database.onUndelete(new Opportunity[] { newOpp });
			SObjectDomain.triggerHandler(SObjectDomain.TestSObjectDisableBehaviorConstructor.class);
		} catch (Exception e) {
			sErrorMessage = e.getMessage();
		}
		System.AssertEquals('onAfterUndelete called', sErrorMessage, 'Error - After Undelete Event is enabled but did not run');
	}
}