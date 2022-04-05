@IsTest
private class AccessTest {

	@IsTest
	static void testFieldPermissionsHappy() {
		Utils.log('Access.isAccessible(Account.SObjectType) = ' + Access.isAccessible(Account.SObjectType));
		Utils.log('Access.isCreateable(Account.SObjectType) = ' + Access.isCreateable(Account.SObjectType));
		Utils.log('Access.isUpdateable(Account.SObjectType) = ' + Access.isUpdateable(Account.SObjectType));
		Utils.log('Access.isDeleteable(Account.SObjectType) = ' + Access.isDeleteable(Account.SObjectType));

		Access.isFieldAccessible(Account.Name);
		Access.isFieldCreateable(Account.Name);
		Access.isFieldUpdateable(Account.Name);

		System.assertEquals('', Access.getEnglishForAccessType(null));
		System.assertEquals('Read', Access.getEnglishForAccessType(AccessType.READABLE));
		System.assertEquals('Create', Access.getEnglishForAccessType(AccessType.CREATABLE));
		System.assertEquals('Update', Access.getEnglishForAccessType(AccessType.UPDATABLE));
		System.assertEquals('Upsert', Access.getEnglishForAccessType(AccessType.UPSERTABLE));

		try { // wrapping in try catch just in case there's something funky in the customer's org
			Account a = new Account(Name='Test Security');
			a.Phone = '808-555-1234';
			a.Website = 'www.github.com';
			a.AccountSource = 'Web';
			a.AnnualRevenue = 100000000;
			a.BillingStreet = '100 Main St';
			a.BillingCity = 'Durango';
			a.BillingState = 'CO';
			a.BillingPostalCode = '81018';
			a.BillingCountry = 'USA';

			insert a;
			System.assert(a.Id != null);

			List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
				Account.Name,
				Account.Phone,
				Account.Website,
				Account.AccountSource,
				Account.AnnualRevenue,
				Account.BillingStreet,
				Account.BillingCity,
				Account.BillingState,
				Account.BillingPostalCode,
				Account.BillingCountry
			};

			// make sure it handles nulls ok
			List<Schema.SObjectField> notSet;
			Access.checkPermissions(Account.SObjectType, new List<SObject> {a}, AccessType.READABLE, notSet);

			Access.checkPermissions(Account.SObjectType, new List<SObject> {a}, AccessType.READABLE, fieldsToCheck);

			Access.checkPermissions(Account.SObjectType, new List<SObject> {a}, AccessType.CREATABLE, fieldsToCheck);

			Access.checkPermissions(Account.SObjectType, new List<Account> {a}, AccessType.UPDATABLE, fieldsToCheck);

		} catch (Exception e) {
			Utils.logError(e);
		}
	}

	@IsTest
	static void testFieldPermissionsHappyFieldsAsString() {

		try { // wrapping in try catch just in case there's something funky in the customer's org
			Account a = new Account(Name='Test Security');
			a.Phone = '808-555-1234';
			a.Website = 'www.github.com';
			a.AccountSource = 'Web';
			a.AnnualRevenue = 100000000;
			a.BillingStreet = '100 Main St';
			a.BillingCity = 'Durango';
			a.BillingState = 'CO';
			a.BillingPostalCode = '81018';
			a.BillingCountry = 'USA';

			insert a;
			System.assert(a.Id != null);

			Map<String,Object> fieldsToValue = a.getPopulatedFieldsAsMap();

			// make sure it handles nulls ok
			Access.checkPermissions(Account.SObjectType, new List<SObject> {a}, AccessType.READABLE, fieldsToValue.keySet());

			Access.checkPermissions(Account.SObjectType, new List<SObject> {a}, AccessType.CREATABLE, fieldsToValue.keySet());

			Access.checkPermissions(Account.SObjectType, new List<Account> {a}, AccessType.UPDATABLE, fieldsToValue.keySet());

		} catch (Exception e) {
			Utils.logError(e);
		}
	}


	@IsTest
	static void testFieldPermissionsSad() {
		Account a = new Account(Name='Test Security');
		insert a;

		// we'll get a user with the Standard User profile that doesn't have some Asset field access
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			Asset ass1 = new Asset();
			ass1.Name = 'test asset uno';
			ass1.AccountId = a.Id;
			ass1.ExternalIdentifier = 'abc';
			ass1.InstallDate = Date.today().addDays(15);
			ass1.Description = 'hello there';
			ass1.Status = 'Purchased';
			ass1.DigitalAssetStatus = 'On';

			Asset ass2 = new Asset();
			ass2.Name = 'test asset dos';
			ass2.AccountId = a.Id;
			ass2.ExternalIdentifier = 'xyz';
			ass2.InstallDate = Date.today().addDays(25);
			ass2.Description = 'adios';
			ass2.Status = 'Purchased';
			ass2.DigitalAssetStatus = 'Off';

			List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
				Asset.AccountId,
				Asset.ExternalIdentifier,
				Asset.DigitalAssetStatus,
				Asset.InstallDate,
				Asset.Name,
				Asset.Description,
				Asset.Status
			};

			Boolean hasError = false;
			try { // Standard User profile of the user doesn't have read access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.READABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}
			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have update access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPDATABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have upsert access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
			hasError = false; // reset for next test

			try { // test validation that SObjectType does not match SObjectType of records passed in
				Access.checkPermissions(Lead.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
		}
	}


	@IsTest
	static void testFieldPermissionsSadFieldsAsString() {
		Account a = new Account(Name='Test Security');
		insert a;

		// we'll get a user with the Standard User profile that doesn't have some Asset field access
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			Asset ass1 = new Asset();
			ass1.Name = 'test asset uno';
			ass1.AccountId = a.Id;
			ass1.ExternalIdentifier = 'abc';
			ass1.InstallDate = Date.today().addDays(15);
			ass1.Description = 'hello there';
			ass1.Status = 'Purchased';
			ass1.DigitalAssetStatus = 'On';

			Asset ass2 = new Asset();
			ass2.Name = 'test asset dos';
			ass2.AccountId = a.Id;
			ass2.ExternalIdentifier = 'xyz';
			ass2.InstallDate = Date.today().addDays(25);
			ass2.Description = 'adios';
			ass2.Status = 'Purchased';
			ass2.DigitalAssetStatus = 'Off';

			Set<String> fieldsToCheck = new Set<String>();
			fieldsToCheck.addAll(ass1.getPopulatedFieldsAsMap().keySet());
			fieldsToCheck.addAll(ass2.getPopulatedFieldsAsMap().keySet());

			Boolean hasError = false;
			try { // Standard User profile of the user doesn't have read access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.READABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}
			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have update access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPDATABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have upsert access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
			hasError = false; // reset for next test

			try { // test validation that SObjectType does not match SObjectType of records passed in
				Access.checkPermissions(Lead.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
		}
	}


	@IsTest
	static void testFieldPermissionsWithBadObjectAccess() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {

			Log__c f = new Log__c();
			f.Location__c = 'should fail';

			List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
				Log__c.Location__c
			};

			Boolean hasError = false;
			try {
				Access.checkPermissions(Log__c.SObjectType, new List<SObject> {f}, AccessType.CREATABLE, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}
			System.assert(hasError);

			hasError = false; // reset for next test

			try {
				Access.checkPermissions(Log__c.SObjectType, new List<SObject> {f}, AccessType.UPDATABLE, f.getPopulatedFieldsAsMap().keySet());
			} catch (Exception e) {
				hasError = true;
			}
			System.assert(hasError);
		}
	}


	@IsTest
	static void testSObjectAccessible() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			System.assertEquals(Account.SObjectType.getDescribe().isAccessible(), Access.isAccessible(Account.SObjectType));

			try {
				Access.checkIsAccessible(Account.SObjectType);
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Read'));
			}

			try { // shouldn't have access since this is a custom object and the permission set isn't assigned to this standard user
				Access.checkIsAccessible(Log__c.SObjectType);
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Read'));
			}

			try {
				Access.checkIsAccessible(new List<Schema.SObjectType> {Account.SObjectType, Lead.SObjectType, Case.SObjectType});
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Read'));
			}
		}
	}


	@IsTest
	static void testSObjectCreateable() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			System.assertEquals(Account.SObjectType.getDescribe().isCreateable(), Access.isCreateable(Account.SObjectType));

			try {
				Access.checkIsCreateable(Account.SObjectType);
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Create'));
			}

			try {
				Access.checkIsCreateable(new List<Schema.SObjectType> {Account.SObjectType, Lead.SObjectType, Case.SObjectType, ApexClass.SObjectType});
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Create'));
			}
		}
	}


	@IsTest
	static void testSObjectUpdateable() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			System.assertEquals(Account.SObjectType.getDescribe().isUpdateable(), Access.isUpdateable(Account.SObjectType));

			try {
				Access.checkIsUpdateable(Account.SObjectType);
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Update'));
			}

			try {
				Access.checkIsUpdateable(new List<Schema.SObjectType> {Account.SObjectType, Lead.SObjectType, Case.SObjectType, ApexClass.SObjectType});
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Update'));
			}
		}
	}


	@IsTest
	static void testSObjectDeleteable() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			System.assertEquals(Account.SObjectType.getDescribe().isDeletable(), Access.isDeleteable(Account.SObjectType));

			try {
				Access.checkIsDeleteable(Account.SObjectType);
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Delete'));
			}

			try {
				Access.checkIsDeleteable(new List<Schema.SObjectType> {Account.SObjectType, Lead.SObjectType, Case.SObjectType, ApexClass.SObjectType});
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Delete'));
			}
		}
	}
}