@isTest
public with sharing class TestData {

	public static Contact getTestContact(Id accountId) {
		Contact c = new Contact();
		c.AccountId = accountId;
		c.FirstName = 'First' + String.valueOf(Math.random() * 10000000).subString(0, 7);
		c.LastName = 'Last' + String.valueOf(Math.random() * 10000000).subString(0, 7);
		c.Email =  'a' + String.valueOf(Math.random() * 10000000).subString(0, 7) + 'b@hi' + String.valueOf(Math.random() * 10000000).subString(0, 5) + '.com';
		c.Phone = String.valueOf(Math.random() * 10000000).subString(0, 10).remove('-');

		// logging because getting dupes on this
		Utils.log('contact = ' + c);
		return c;
	}

	// this doesn't work in test methods where you also need to create test records
	// call it in the TestSetup method by itself
	public static void createUserWithPermissionSet() {
		User user = new User();
		user.FirstName = 'Test';
		user.LastName = 'User';
		user.Email = 'test@github.com';
		user.UserName = 'test@github.com';
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

		/* TODO: assign one of our permission sets to the user once it's defined
		PermissionSet[] ps = [SELECT Id FROM PermissionSet WHERE Name = :Constants.UST_PERM_SET_API_NAME];

		if (ps.size() != 1) {
			throw new Constants.UnexpectedException('Unable to find Permission Set: ' + Constants.UST_PERM_SET_API_NAME);
		} else {
			PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = ps[0].Id, AssigneeId = user.Id);
			Database.SaveResult sr = Database.insert(psa, false);
		}
		*/
	}


	public static User getUserWithPermissionSet() {
		return [select Id from User where UserName = 'test@github.com' limit 1];
	}

	// create a new User that can be used in Tests - not needed yet - would probably want to assign our perm set
	public static User getActiveUserWithStandardProfile() {
		User user = new User();
		user.FirstName = 'Test';
		user.LastName = 'User';
		user.Email = 'test@github.com';
		user.UserName = 'test@github.com';
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

		return user;
	}
}
