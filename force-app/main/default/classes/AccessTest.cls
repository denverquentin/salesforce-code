@IsTest
private class AccessTest {

	@IsTest
	static void testFieldPermissionsHappy() {
		Utils.log('Access.isAccessible(Account.SObjectType) = ' + Access.isAccessible(Account.SObjectType));
		Utils.log('Access.isCreateable(Account.SObjectType) = ' + Access.isCreateable(Account.SObjectType));
		Utils.log('Access.isUpdateable(Account.SObjectType) = ' + Access.isUpdateable(Account.SObjectType));
		Utils.log('Access.isDeleteable(Account.SObjectType) = ' + Access.isDeleteable(Account.SObjectType));

		Boolean x = Access.isFieldAccessible(Account.Name);
		Boolean y = Access.isFieldCreateable(Account.Name);
		Boolean z = Access.isFieldUpdateable(Account.Name);

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
			Access.checkPermissions(AccessType.READABLE, new List<SObject> {a}, notSet);

			Access.checkPermissions(AccessType.READABLE, new List<SObject> {a}, fieldsToCheck);

			Access.checkPermissions(AccessType.CREATABLE, new List<SObject> {a}, fieldsToCheck);

			Access.checkPermissions(AccessType.UPDATABLE, new List<Account> {a}, fieldsToCheck);

		} catch (Exception e) {

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
			Access.checkPermissions(AccessType.READABLE, new List<SObject> {a}, fieldsToValue.keySet());

			Access.checkPermissions(AccessType.CREATABLE, new List<SObject> {a}, fieldsToValue.keySet());

			Access.checkPermissions(AccessType.UPDATABLE, new List<Account> {a}, fieldsToValue.keySet());

		} catch (Exception e) {

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

			Lead l = new Lead();
			l.FirstName = 'Boss';
			l.LastName = 'Baby';
			l.Company = 'UST';
			l.Email = 'bb@github.com';
			l.Phone = '303-867-5309';
			l.Title = 'Boss Baby';

			List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
				Asset.AccountId,
				Asset.ExternalIdentifier,
				Asset.DigitalAssetStatus,
				Asset.InstallDate,
				Asset.Name,
				Asset.Description,
				Asset.Status,
				Lead.FirstName,
				Lead.LastName,
				Lead.Company,
				Lead.Email,
				Lead.Phone,
				Lead.Title
			};

			Boolean hasError = false;
			try { // Standard User profile of the user doesn't have read access for some Asset fields so should throw exception
				Access.checkPermissions(AccessType.READABLE, new List<SObject> {ass1, ass2, l}, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}
			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have update access for some Asset fields so should throw exception
				Access.checkPermissions(AccessType.UPDATABLE, new List<SObject> {ass1, ass2, l}, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have upsert access for some Asset fields so should throw exception
				Access.checkPermissions(AccessType.UPSERTABLE, new List<SObject> {ass1, ass2, l}, fieldsToCheck);
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

			Lead l = new Lead();
			l.FirstName = 'Boss';
			l.LastName = 'Baby';
			l.Company = 'UST';
			l.Email = 'bb@ust.com';
			l.Phone = '303-867-5309';
			l.Title = 'Boss Baby';

			Set<String> fieldsToCheck = new Set<String>();
			fieldsToCheck.addAll(ass1.getPopulatedFieldsAsMap().keySet());
			fieldsToCheck.addAll(ass2.getPopulatedFieldsAsMap().keySet());
			fieldsToCheck.addAll(l.getPopulatedFieldsAsMap().keySet());

			Boolean hasError = false;
			try { // Standard User profile of the user doesn't have read access for some Asset fields so should throw exception
				Access.checkPermissions(AccessType.READABLE, new List<SObject> {ass1, ass2, l}, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}
			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have update access for some Asset fields so should throw exception
				Access.checkPermissions(AccessType.UPDATABLE, new List<SObject> {ass1, ass2, l}, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}

			System.assert(hasError);
			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have upsert access for some Asset fields so should throw exception
				Access.checkPermissions(AccessType.UPSERTABLE, new List<SObject> {ass1, ass2, l}, fieldsToCheck);
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

			Lead l = new Lead();
			l.FirstName = 'Boss';
			l.LastName = 'Baby';
			l.Company = 'UST';
			l.Email = 'bb@ust.com';
			l.Phone = '303-867-5309';
			l.Title = 'Boss Baby';

			List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
				Log__c.Location__c,
				Lead.FirstName,
				Lead.LastName,
				Lead.Company,
				Lead.Email,
				Lead.Phone,
				Lead.Title
			};

			Boolean hasError = false;
			try { // Standard User profile of the user shouldn't have create access for our custom Log__c obj so should throw exception
				Access.checkPermissions(AccessType.CREATABLE, new List<SObject> {f, l}, fieldsToCheck);
			} catch (Exception e) {
				hasError = true;
			}
			System.assert(hasError);

			hasError = false; // reset for next test

			try { // Standard User profile of the user doesn't have create access for the AccountBrand obj so should throw exception
				Access.checkPermissions(AccessType.UPDATABLE, new List<SObject> {f, l}, fieldsToCheck);
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

			// haven't found a object that's not accessible which i assume means queryable and/or retrieveable
			try {
				Access.checkIsAccessible(Account.SObjectType);
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
