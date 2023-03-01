@isTest
public with sharing class TestData {

	public static Contact getTestContact(Id accountId) {
		Contact c = new Contact();
		c.AccountId = accountId;
		c.FirstName = 'First' + String.valueOf(Math.random() * 10000000).subString(0, 7);
		c.LastName = 'Last' + String.valueOf(Math.random() * 10000000).subString(0, 7);
		c.Email =  'a' + String.valueOf(Math.random() * 10000000).subString(0, 7) + 'b@hi' + String.valueOf(Math.random() * 10000000).subString(0, 5).replaceAll('.', '0') + '.com';
		c.Phone = String.valueOf(Math.random() * 10000000).subString(0, 10).remove('-');

		// logging because getting dupes on this
		Utils.log('contact = ' + c);
		return c;
	}

	// this doesn't work in test methods where you also need to create test records
	// call it in the TestSetup method by itself
	public static void createUserWithPermissionSet() {
		String testEmail = 'a' + String.valueOf(Math.random() * 10000000).subString(0, 7) + 'b@hi' + String.valueOf(Math.random() * 10000000).subString(0, 5).replaceAll('.', '0') + '.com';

		User user = new User();
		user.FirstName = 'Test';
		user.LastName = 'User';
		user.Email = testEmail;
		user.UserName = testEmail;
		user.Alias = 'testuser';
		user.IsActive = true;
		user.EmailEncodingKey = 'UTF-8';
		user.LanguageLocaleKey = 'en_US';
		user.LocaleSidKey = 'en_US';
		user.TimeZoneSidKey = 'America/Los_Angeles';

		List<Profile> p1 = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
		if (p1.size() > 0) {
			user.ProfileId = p1[0].Id;
		} else {
			throw new Constants.UnexpectedException('Unable to find Standard User profile for unit tests.');
		}
		insert user;

		PermissionSet[] ps = [SELECT Id FROM PermissionSet WHERE Name = :Constants.PERM_SET_API_NAME];

		if (ps.size() == 0) {
			throw new Constants.UnexpectedException('Unable to find Permission Set: ' + Constants.PERM_SET_API_NAME);
		} else {
			PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps[0].Id, AssigneeId = user.Id);
			Database.insert(psa, false);
		}
	}


	public static User getUserWithPermissionSet() {
		PermissionSet[] ps = [SELECT Id FROM PermissionSet WHERE Name = :Constants.PERM_SET_API_NAME];
		if (ps.size() == 0) {
			throw new Constants.UnexpectedException('Unable to find Permission Set: ' + Constants.PERM_SET_API_NAME);
		} else {
			PermissionSetAssignment[] psa = [SELECT AssigneeId FROM PermissionSetAssignment where PermissionSetId = :ps[0].Id];
			if (psa.size() == 0) {
				throw new Constants.UnexpectedException('Unable to find User assigned to Permission Set: ' + Constants.PERM_SET_API_NAME);
			} else {
				return [select Id from User where Id = :psa[0].AssigneeId];
			}
		}
	}

	// create a new User that can be used in Tests
	public static User getActiveUserWithStandardProfile() {
		String testEmail = 'y' + String.valueOf(Math.random() * 10000000).subString(0, 7) + 'z@bye' + String.valueOf(Math.random() * 10000000).subString(0, 5).replaceAll('.', '0') + '.com';

		User user = new User();
		user.FirstName = 'Test';
		user.LastName = 'User';
		user.Email = testEmail;
		user.UserName = testEmail;
		user.Alias = 'tuser1';
		user.IsActive = true;
		user.EmailEncodingKey = 'UTF-8';
		user.LanguageLocaleKey = 'en_US';
		user.LocaleSidKey = 'en_US';
		user.TimeZoneSidKey = 'America/Los_Angeles';

		List<Profile> p1 = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
		if (p1.size() > 0) {
			user.ProfileId = p1[0].Id;
		} else {
			throw new Constants.UnexpectedException('Unable to find Standard User profile for unit tests.');
		}

		return user;
	}
}
