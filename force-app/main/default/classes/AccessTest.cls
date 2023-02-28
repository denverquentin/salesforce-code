@IsTest
private class AccessTest {

	@IsTest
	static void testFieldPermissionsHappy() {
		System.debug(LoggingLevel.INFO, 'Access.isAccessible(Account.SObjectType) = ' + Access.isAccessible(Account.SObjectType));
		System.debug(LoggingLevel.INFO, 'Access.isCreateable(Account.SObjectType) = ' + Access.isCreateable(Account.SObjectType));
		System.debug(LoggingLevel.INFO, 'Access.isUpdateable(Account.SObjectType) = ' + Access.isUpdateable(Account.SObjectType));
		System.debug(LoggingLevel.INFO, 'Access.isDeleteable(Account.SObjectType) = ' + Access.isDeleteable(Account.SObjectType));

		Access.isFieldAccessible(Account.Name);
		Access.isFieldCreateable(Account.Name);
		Access.isFieldUpdateable(Account.Name);

		Assert.areEqual('', Access.getEnglishForAccessType(null));
		Assert.areEqual('Read', Access.getEnglishForAccessType(AccessType.READABLE));
		Assert.areEqual('Create', Access.getEnglishForAccessType(AccessType.CREATABLE));
		Assert.areEqual('Update', Access.getEnglishForAccessType(AccessType.UPDATABLE));
		Assert.areEqual('Upsert', Access.getEnglishForAccessType(AccessType.UPSERTABLE));

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
			Assert.isNotNull(a.Id);

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
			System.debug(LoggingLevel.ERROR, e.getMessage());
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
			Assert.isNotNull(a.Id);

			Map<String,Object> fieldsToValue = a.getPopulatedFieldsAsMap();

			// make sure it handles nulls ok
			Access.checkPermissions(Account.SObjectType, new List<SObject> {a}, AccessType.READABLE, fieldsToValue.keySet());

			Access.checkPermissions(Account.SObjectType, new List<SObject> {a}, AccessType.CREATABLE, fieldsToValue.keySet());

			Access.checkPermissions(Account.SObjectType, new List<Account> {a}, AccessType.UPDATABLE, fieldsToValue.keySet());

		} catch (Exception e) {
			System.debug(LoggingLevel.ERROR, e.getMessage());
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

			try { // Standard User profile of the user doesn't have read access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.READABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}

			try { // Standard User profile of the user doesn't have update access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPDATABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}

			try { // Standard User profile of the user doesn't have upsert access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}

			try { // test validation that SObjectType does not match SObjectType of records passed in
				Access.checkPermissions(Lead.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}
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

			try { // Standard User profile of the user doesn't have read access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.READABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}

			try { // Standard User profile of the user doesn't have update access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPDATABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}

			try { // Standard User profile of the user doesn't have upsert access for some Asset fields so should throw exception
				Access.checkPermissions(Asset.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}

			try { // test validation that SObjectType does not match SObjectType of records passed in
				Access.checkPermissions(Lead.SObjectType, new List<SObject> {ass1, ass2}, AccessType.UPSERTABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}
		}
	}


	@IsTest
	static void testFieldPermissionsWithBadObjectAccess() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {

			ApexClass ac = new ApexClass();
			ac.Body = 'public class Failing {}';

			List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
				ApexClass.Body
			};

			try {
				Access.checkPermissions(ApexClass.SObjectType, new List<SObject> {ac}, AccessType.CREATABLE, fieldsToCheck);
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}

			try {
				Access.checkPermissions(ApexClass.SObjectType, new List<SObject> {ac}, AccessType.UPDATABLE, ac.getPopulatedFieldsAsMap().keySet());
				Assert.fail('Exception Expected');
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, e.getMessage());
			}
		}
	}


	@IsTest
	static void testSObjectAccessible() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			System.assertEquals(Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFAULT).isAccessible(), Access.isAccessible(Account.SObjectType));

			try {
				Access.checkIsAccessible(Account.SObjectType);
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Read'));
			}

			Schema.SObjectType inaccessibleSO;
			for (Schema.SObjectType so : Schema.getGlobalDescribe().values()) {
				if (!so.getDescribe().isAccessible()) {
					inaccessibleSO = so;
					break;
				}
			}

			try {
				Access.checkIsAccessible(inaccessibleSO);
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Read'));
			}


			try {
				Access.checkIsAccessible(new List<Schema.SObjectType> {Account.SObjectType, Lead.SObjectType, Case.SObjectType, ApexClass.SObjectType});
			} catch (Exception e) {
				System.assert(e.getMessage().startsWith('You do not have permission to Read'));
			}
		}
	}


	@IsTest
	static void testSObjectCreateable() {
		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			System.assertEquals(Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFAULT).isCreateable(), Access.isCreateable(Account.SObjectType));

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
			System.assertEquals(Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFAULT).isUpdateable(), Access.isUpdateable(Account.SObjectType));

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
			System.assertEquals(Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFAULT).isDeletable(), Access.isDeleteable(Account.SObjectType));

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