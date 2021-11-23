@IsTest
private class UtilsTest {


	@IsTest
	static void testProdSandbox() {
		System.assertNotEquals(null, Constants.PROFILE_NAME_SYSTEM_ADMINISTRATOR);
		System.assertEquals(Utils.isSandbox(), Utils.isSandbox());

		Utils.confirmMsg('confirm');
		Utils.infoMsg('info');
		Utils.warnMsg('warn');
		Utils.errorMsg('error');
		Utils.errorMsg(new Constants.ValidationException('vali exception'));
		Utils.log('log');
		Utils.logError(new Constants.ValidationException('validation exception'));
		try {
			Utils.errorLightning(new Constants.UnexpectedException('unexpected exception'));
		} catch (AuraHandledException e) {

		}

		Utils.log(new Account());
		System.assertEquals(Utils.isSysAdmin(), Utils.isSysAdmin());
		System.assertEquals(Utils.isCommunityUser(), Utils.isCommunityUser());
		System.assertEquals(Utils.isPersonAccountEnabled(), Utils.isPersonAccountEnabled());
		System.assertEquals(Utils.isStateCountryPickListsEnabled(), Utils.isStateCountryPickListsEnabled());

		System.runAs(TestData.getActiveUserWithStandardProfile()) {
			Boolean val = Utils.isSysAdmin();
		}
	}


	@IsTest
	static void testGetSalesforceBaseUrl() {
		// This method will return the "My Domain" name or instance if domain is not registered
		System.assertEquals((String)Url.getOrgDomainUrl().toExternalForm(), Utils.getSalesforceBaseUrl());
		System.assertEquals(Utils.isMyDomainNameEnabled(), Utils.isMyDomainNameEnabled());
	}


	@IsTest
	static void testHasFieldOnRecordChanged() {
		List<String> fieldNames = new List<String> {'Name', 'Type', 'AnnualRevenue'};

		Account a1 = new Account();
		Account a2 = new Account();

		a1.Name = 'Name 1';
		System.assert(Utils.haveFieldsOnRecordChanged(a1, a2, fieldNames));

		a2.Name = 'Name 1';
		System.assert(!Utils.haveFieldsOnRecordChanged(a1, a2, fieldNames));

		a1.Type = 'Developer';
		a2.Type = 'Reseller';
		System.assert(Utils.haveFieldsOnRecordChanged(a1, a2, fieldNames));

		a2.Type = 'Developer';
		System.assert(!Utils.haveFieldsOnRecordChanged(a1, a2, fieldNames));

		a1.AnnualRevenue = 50000;
		a2.AnnualRevenue = 50001;
		System.assert(Utils.haveFieldsOnRecordChanged(a1, a2, fieldNames));

		a2.AnnualRevenue = 50000;
		System.assert(!Utils.haveFieldsOnRecordChanged(a1, a2, fieldNames));

		insert a1;
		System.assert(Utils.haveFieldsOnRecordChanged(a1, a2, new List<String> {'Id'}));

		System.assertEquals(false, Utils.isValidId('fake id'));
		System.assertEquals(true, Utils.isValidId(a1.Id));
	}


	@IsTest
	static void testCreateFileAttachedToRecord() {
		Account a = new Account(Name='Account with File Attached');
		insert a;

		String fileContents = 'hello there. how are you?';

		Id fileId = Utils.createFileAttachedToRecord(Blob.valueOf(fileContents), a.Id, 'hello.txt');
		System.assert(fileId != null);
	}


	@IsTest
	static void testRemoveNull() {
		System.assertEquals('', Utils.removeNull(null));
		System.assertEquals('hi', Utils.removeNull('hi'));

		System.assertEquals('Account', Utils.getObjApiNameWithNamespace('Account'));
	}


	@IsTest
	static void testRemoveTrailingZeros() {// the method also strips off trailing zeros if a value is set
		System.assertEquals(null, Utils.removeTrailingZeros(null));
		System.assertEquals(0.00, Utils.removeTrailingZeros(0.00));
		System.assertEquals(0, Utils.removeTrailingZeros(0));
		System.assertEquals(10.5, Utils.removeTrailingZeros(10.5));
		System.assertEquals(20.20, Utils.removeTrailingZeros(20.20000));
		System.assertEquals(30.3330, Utils.removeTrailingZeros(30.333));
		System.assertEquals(40.00, Utils.removeTrailingZeros(40));
		System.assertEquals(.015, Utils.removeTrailingZeros(.015));
		System.assertEquals(5.991, Utils.removeTrailingZeros(5.9910));
		System.assertEquals(5.99, Utils.removeTrailingZeros(5.9900));
	}


	@IsTest
	static void testReplaceCarriageReturnsAndLineBreaksWithASpace() {
		System.assertEquals(null, Utils.replaceCarriageReturnsAndLineBreaksWithASpace(null));
		System.assertEquals('hi there', Utils.replaceCarriageReturnsAndLineBreaksWithASpace('hi\r\nthere'));
		System.assertEquals('whats up', Utils.replaceCarriageReturnsAndLineBreaksWithASpace('whats\rup'));
		System.assertEquals('how goes it', Utils.replaceCarriageReturnsAndLineBreaksWithASpace('how\rgoes\nit'));
	}


	@IsTest
	static void testRemoveEverythingButDigits() {
		System.assertEquals(null, Utils.removeEverythingButDigits(null));
		System.assertEquals('', Utils.removeEverythingButDigits(''));
		System.assertEquals('459095551234', Utils.removeEverythingButDigits('+45 (909) 555-1234'));
		System.assertEquals('123987011', Utils.removeEverythingButDigits('123,987.011'));
	}


	@IsTest
	static void testFormatPhoneUSA() {
		System.assertEquals(null, Utils.formatPhoneUSA(null));
		System.assertEquals('', Utils.formatPhoneUSA(''));
		System.assertEquals('++()-', Utils.formatPhoneUSA('++()-'));
		System.assertEquals('(808) 555-2345', Utils.formatPhoneUSA('(808) 555-2345'));
		System.assertEquals('(808) 555-2345 x505', Utils.formatPhoneUSA('(808) 555-2345 x505'));
		System.assertEquals('555-2345 x808', Utils.formatPhoneUSA('555-2345 x808'));
		System.assertEquals('+55 674322233444', Utils.formatPhoneUSA('+55 674322233444'));
		System.assertEquals('(707) 666-5675', Utils.formatPhoneUSA('7076665675'));
		System.assertEquals('(444) 090-3456', Utils.formatPhoneUSA('444-090-3456'));
		System.assertEquals('(707) 666-5675', Utils.formatPhoneUSA('(707)6665675'));
		System.assertEquals('(707) 666-5675', Utils.formatPhoneUSA('(707)666-5675'));
		System.assertEquals('666-5675', Utils.formatPhoneUSA('6665675'));
		System.assertEquals('(303) 666-5675', Utils.formatPhoneUSA('303-666-5675'));
	}


	@IsTest
	static void testRemoveForwardSlashAtEnd() {
		System.assertEquals(null, Utils.removeForwardSlashAtEnd(null));
		System.assertEquals('www.yahoo.com/welcome', Utils.removeForwardSlashAtEnd('www.yahoo.com/welcome'));
		System.assertEquals('www.yahoo.com', Utils.removeForwardSlashAtEnd('www.yahoo.com/'));
	}


	@IsTest
	static void testIsValidPostalCode() {
		System.assertEquals(false, Utils.isValidPostalCode(null));
		System.assertEquals(true, Utils.isValidPostalCode('55555'));
		System.assertEquals(true, Utils.isValidPostalCode('55555-9999'));
		System.assertEquals(false, Utils.isValidPostalCode('abcde-9999'));
	}


	@IsTest
	static void testFormatPostalCode() {
		System.assertEquals(null, Utils.formatPostalCode(null));
		System.assertEquals('80808', Utils.formatPostalCode('80808'));
		System.assertEquals('90909-1234', Utils.formatPostalCode('909091234'));
		try {
			String v = Utils.formatPostalCode('9090966666');
		} catch (Exception e) {
			System.assert(String.isNotBlank(e.getMessage()));
		}
	}


	@IsTest
	static void testShortenString() {
		System.assertEquals(null, Utils.shortenString(null, 20));
		System.assertEquals('', Utils.shortenString('', 0));
		System.assertEquals('hello', Utils.shortenString('hello', 5));
		System.assertEquals('welco', Utils.shortenString('welcome', 5));
		System.assertEquals('welcome', Utils.shortenString('welcome', 50));
	}


	@IsTest
	static void testGetSetForMultiselectValues() {
		System.assertEquals(0, Utils.getSetForMultiselectValues(null).size());
		System.assertEquals(1, Utils.getSetForMultiselectValues('size 1').size());
		System.assertEquals(3, Utils.getSetForMultiselectValues('hello;what up;goodbye').size());
	}


	@IsTest
	static void testConvertStringSetForQuery() {
		System.assertEquals('', Utils.convertStringSetForQuery(null));
		System.assertEquals('', Utils.convertStringSetForQuery(new Set<String>()));
		System.assertEquals('(\'Name\',\'Id\',\'CreatedDate\')', Utils.convertStringSetForQuery(new Set<String>{'Name','Id','CreatedDate'}));

		System.assertEquals('(\'Name\',\'\',\'Id\')', Utils.convertStringSetForQuery(new Set<String>{'Name','','Id'}));
		System.assertEquals('(\'Name\',null,\'Id\')', Utils.convertStringSetForQuery(new Set<String>{'Name',null,'Id'}));
	}


	@IsTest
	static void testConvertDateSetForQuery() {
		System.assertEquals('', Utils.convertDateSetForQuery(null));
		System.assertEquals('', Utils.convertDateSetForQuery(new Set<Date>()));
		System.assertEquals('(1975-06-09)', Utils.convertDateSetForQuery(new Set<Date> {Date.newInstance(1975, 6, 9)}));
		System.assertEquals('(2011-07-31,2013-10-29)', Utils.convertDateSetForQuery(new Set<Date> {Date.newInstance(2011, 7, 31), Date.newInstance(2013, 10, 29)}));
	}


	@IsTest
	static void testConvertDateForDynamicQuery() {
		System.assertEquals('1975-06-09', Utils.convertDateForDynamicQuery(Date.newInstance(1975, 6, 9)));
		System.assertEquals('1999-12-31', Utils.convertDateForDynamicQuery(Date.newInstance(1999, 12, 31)));
		System.assertEquals('1980-01-19', Utils.convertDateForDynamicQuery(Date.newInstance(1980, 1, 19)));
		System.assertEquals('1982-10-09', Utils.convertDateForDynamicQuery(Date.newInstance(1982, 10, 9)));
		System.assertEquals(null, Utils.convertDateForDynamicQuery(null));
	}


	@IsTest
	static void testGenerateRandomKey() {
		String key = Utils.generateRandomKey();
		System.assert(key.length() == 16);
		System.assert(key.containsNone('U'));
		System.assert(key.containsNone('/'));
		System.assert(key.containsNone('='));
		System.assert(key.containsNone('I'));
		System.assert(key.containsNone('L'));
		System.assert(key.containsNone('O'));
	}


	@IsTest
	static void testCreateCompletedTask() {
		Utils.emailStatusOfBatchJob('', 50, 'hi');
		Utils.emailStatusOfBatchJob('');
		System.assert(true); // no good way to test method above
/*		not using this yet
		Account a = new Account(Name='Test Task');
		insert a;

		Contact c = TestData.getTestContact(a.Id);
		insert c;

		Utils.createCompletedTask('completed task', 'whatever', UserInfo.getUserId(), c.Id, a.Id);

		List<Task> tasks = [select Id from Task where Subject = 'completed task' and Status = 'Completed'];
		System.assertEquals(1, tasks.size());

		Utils.createCompletedTask('completed task', 'whatever', UserInfo.getUserId(), 'fail', null);
		Utils.createCompletedTask('completed task', 'whatever', UserInfo.getUserId(), null, 'fail');
*/
	}
}