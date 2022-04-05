public inherited sharing class Utils {
	// use this to determine if we're in a sandbox from a managed package - else use the code above
	public static Boolean isSandbox() {
		List<Organization> orgs = [select Id, IsSandbox from Organization with SECURITY_ENFORCED limit 1];
		return (orgs.size() > 0 && orgs[0].IsSandbox) ? true : false;
	}


	public static String getSalesforceBaseUrl() {
		// This method will return the "My Domain" name or instance if domain is not registered
		return Url.getOrgDomainUrl().toExternalForm();
	}


	public static Boolean isMyDomainNameEnabled() {
		return Url.getOrgDomainUrl().toExternalForm().contains('.my.salesforce') ? true : false;
	}


	public static Boolean isSysAdmin() {
		List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User where Id = :UserInfo.getUserId()
			AND Profile.Name = :Constants.PROFILE_NAME_SYSTEM_ADMINISTRATOR with SECURITY_ENFORCED];
		return (users.size() > 0) ? true : false;
	}


	public static Boolean isCommunityUser() {
		return UserInfo.getUserType() != 'Standard';
	}


	public static Boolean isPersonAccountEnabled() {
		return Schema.sObjectType.Account.fields.getMap().containsKey('isPersonAccount');
	}


	public static Boolean isStateCountryPickListsEnabled() {
		// if enabled on Contact, assume picklists are enabled for all objects
		Map<String,Schema.SObjectField> m = Schema.SObjectType.Contact.fields.getMap();
		return m.containsKey('MailingStateCode');
	}


	/**
	 * @description        Creates a file and links it to a given record
	 * @param fileContents the binary blob of the files contents
	 * @param attachedTo   the record to link this file to, initially
	 * @param fileName     the name of the file. Note that the system determines
	 *  the filetype from the file extension here
	 * @return            `Database.SaveResult`
	 * @example
	 * Blob fileContents = Blob.valueOf('Hello World 2');
	 * Account acct = [SELECT id FROM Account LIMIT 1];
	 *  FilesRecipes.createFileAttachedToRecord(
	 *      fileContents,
	 *      firstLocation,
	 *      'FileName.json'
	 *  );
	 */
	public static Id createFileAttachedToRecord(Blob fileContents, Id attachedTo, String fileName) {
		ContentVersion fileToUpload = new ContentVersion();
		// S = Salesforce. The other options are: 'E' (external) and 'L' (social customer service)
		fileToUpload.ContentLocation = 'S';
		fileToUpload.PathOnClient = fileName;
		fileToUpload.Title = fileName;
		fileToUpload.VersionData = fileContents;
		// we could enhance this to relate it to multiple records if needed
		fileToUpload.FirstPublishLocationId = attachedTo;

		List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
			ContentVersion.ContentLocation,
			ContentVersion.PathOnClient,
			ContentVersion.Title,
			ContentVersion.VersionData,
			ContentVersion.FirstPublishLocationId
		};
		// security check - throws exception if no access to create object/fields
		Access.checkPermissions(ContentVersion.SObjectType, new List<SObject> {fileToUpload}, AccessType.CREATABLE, fieldsToCheck);

		// false positive - scanner isn't picking up security check above
		insert fileToUpload;
		return fileToUpload.Id;
	}


	public static Boolean isValidId(String id) {
		try {
			Id x = (Id) id;
		} catch (Exception e) {
			return false;
		}
		return true;
	}


	// look at the fieldNames passed in to see if the value is different between the old and new record - return true if any are different
	public static Boolean haveFieldsOnRecordChanged(SObject oldRecord, sObject newRecord, List<String> fieldNames) {
		for (String fieldName : fieldNames) {
			//Utils.log('oldRecord.get(fieldName) = ' + oldRecord.get(fieldName));
			//Utils.log('newRecord.get(fieldName) = ' + newRecord.get(fieldName));
			if (oldRecord.get(fieldName) != newRecord.get(fieldName)) {
				return true;
			}
		}
		return false;
	}


	// returns the object name with the namespace prefix if the object has a namespace (is in managed package)
	public static String getObjApiNameWithNamespace(String objectName) {
		Schema.SObjectType obj = Schema.getGlobalDescribe().get(objectName.toLowerCase());
		return obj.getDescribe().getName();
	}


	public static String removeNull(String val) {
		if (val == null) {
			return '';
		} else {
			return val;
		}
	}


	public static Decimal removeTrailingZeros(Decimal val) {
		if (val != null) {
			// let's clean up the decimals - main purpose is to get trailing zeros removed but also keep 2 decimal places unless more decimals are needed
			if (val.stripTrailingZeros() == val.setscale(2)) { // make sure setting scale to 2 doesn't round up or down - no bueno
				return val.setscale(2); // if not - return it
			}
			return val.stripTrailingZeros(); // otherwise strip trailing zeros
		}
		return val;
	}


	public static String replaceCarriageReturnsAndLineBreaksWithASpace(String val) {
		if (String.isNotBlank(val)) {
			val = val.replaceAll('\r\n', ' ');
			val = val.replaceAll('\n', ' ');
			val = val.replaceAll('\r', ' ');
		}
		return val;
	}


	public static String removeEverythingButDigits(String val) { // including spaces
		if (String.isNotBlank(val)) {
			// strip out all non-digit chars
			return val.replaceAll('[\\D]', '');
		}
		return val;
	}


	public static String formatPhoneUSA(String phone) {
		// make sure phone isn't null and isn't already formatted
		if (String.isNotBlank(phone) && !Pattern.matches('(\\(\\d{3}\\) )?\\d{3}-\\d{4}', phone)) {
			if (!phone.startsWith('+') && !phone.startsWith('0') && !phone.startsWith('1')
				&& !phone.containsIgnoreCase('x')) { // ignore these - probably international
				String onlyDigits = removeEverythingButDigits(phone);
				if (String.isNotBlank(onlyDigits)) {
					if (onlyDigits.length() == 7) {
						return onlyDigits.substring(0, 3) + '-' + onlyDigits.substring(3, 7);
					} else if (onlyDigits.length() == 10) {
						return '(' + onlyDigits.substring(0, 3) + ') ' + onlyDigits.substring(3, 6) + '-' + onlyDigits.substring(6, 10);
					}
				}
			}
		}
		return phone;
	}


	public static String removeForwardSlashAtEnd(String val) {
		if (String.isNotBlank(val)) {
			return val.removeEnd('/'); // remove forward slash if it's at the end of the string
		}
		return val;
	}


	public static Boolean isValidPostalCode(String val) {
		if (String.isBlank(val)) {
			return false;
		} else {
			// strip out all non-digit chars
			String cleanZip = val.replaceAll('[\\D]', '');
			if (cleanZip.length() == 5 || cleanZip.length() == 9) { // allow 5 or 9 digits
				return true;
			} else {
				return false;
			}
		}
	}


	public static String formatPostalCode(String val) {
		if (String.isNotBlank(val)) {
			// strip out all non-digit chars
			String cleanZip = val.replaceAll('[\\D]', '');
			if (cleanZip.length() == 5) {
				return cleanZip;
			} else if (cleanZip.length() == 9) {
				return cleanZip.substring(0,5) + '-' + cleanZip.substring(5,9);
			} else {
				throw new Constants.ValidationException('Invalid Postal Code.');
			}
		}
		return val;
	}


	public static String shortenString(String val, Integer maxLength) {
		if (val == null) {
			return null;
		} else if (val.length() >= maxLength) {
			return val.substring(0, maxLength);
		} else {
			return val;
		}
	}


	public static Set<String> getSetForMultiselectValues(String val) {
		Set<String> vals = new Set<String>();
		if (String.isNotBlank(val)) {
			for (String v : val.split(';', 0)) {
				vals.add(v);
			}
		}
		return vals;
	}


	public static String convertStringSetForQuery(Set<String> vals) {
		String returnVal = '';
		if (vals != null && vals.size() > 0) {
			returnVal = '(';
			for (String val : vals) {
				if (String.isNotBlank(val)) {
					returnVal += '\'' + val + '\',';
				} else if (val == '') {
					returnVal += '\'\',';
				} else {
					returnVal += 'null,';
				}
			}
			returnVal = returnVal.removeEnd(',');
			returnVal += ')';
		}
		return returnVal;
	}


	// can't use method above - Date's don't have quotes around them in dynamic queries
	public static String convertDateSetForQuery(Set<Date> vals) {
		String returnVal = '';
		if (vals != null && vals.size() > 0) {
			returnVal = '(';
			for (Date val : vals) {
				returnVal += convertDateForDynamicQuery(val) + ',';
			}
			returnVal = returnVal.removeEnd(',');
			returnVal += ')';
		}
		return returnVal;
	}


	public static String convertDateForDynamicQuery(Date val) {
		if (val != null) {
			String month = String.valueOf(val.month());
			if (month.length () == 1) {
				month = '0' + month;
			}
			String day = String.valueOf(val.day());
			if (day.length () == 1) {
				day = '0' + day;
			}
			return val.year() + '-' + month + '-' + day;
		}
		return null;
	}


	// Generate a random base 32 key that's 16 characters long - also removes some confusing characters - https://www.crockford.com/wrmg/base32.html
	public static String generateRandomKey() {
		String key = EncodingUtil.base64Encode(Crypto.generateAesKey(128));
		//Utils.log('key = ' + key);
		// to ensure a better distribution of numbers & letters we're replacing some letters we don't want to use with numbers
		key = key.replaceAll('U', '0');
		key = key.replaceAll('u', '1');
		key = key.replaceAll('I', '2');
		key = key.replaceAll('i', '3');
		key = key.replaceAll('l', '4');
		key = key.replaceAll('L', '5');
		key = key.replaceAll('O', '6');
		key = key.replaceAll('o', '7');
		key = key.replaceAll('\\+', '8');
		key = key.replaceAll('/', '9');
		key = key.replaceAll('=', '');
		return key.toUpperCase().subString(0, 16); // only use 16 characters
	}


	public static void emailStatusOfBatchJob(String jobId, Integer recordCount, String msg) {
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setTargetObjectId(UserInfo.getUserId()); // the user that created the job

		List<AsyncApexJob> jobs = [select TotalJobItems, Status, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id, ExtendedStatus, CreatedDate, CompletedDate, ApexClass.Name, CreatedById, CreatedBy.Email from AsyncApexJob where Id = :jobId with SECURITY_ENFORCED];
		String subject = 'Processing for ';
		String body = '';
		if (jobs.size() > 0) {
			mail.setTargetObjectId(jobs[0].CreatedById); // the user that created the job
			subject += jobs[0].ApexClass.Name + ' is complete';
			body = jobs[0].ApexClass.Name + ' - ' + jobs[0].JobType + '\nStarted: ' + jobs[0].CreatedDate.format('EEE, MMM d, yyyy @ hh:mm:ss a, z') + '\nFinished: ' + jobs[0].CompletedDate.format('EEE, MMM d, yyyy @ hh:mm:ss a, z') + '\n' + '\nBatches Processed: ' + jobs[0].TotalJobItems + '\nErrors: ' + jobs[0].NumberOfErrors + '\nExtended Status: ' + Utils.removeNull(jobs[0].ExtendedStatus);
		}

		if (recordCount != null) {
			body += '\nRecords Processed: ' + recordCount;
		}
		if (String.isNotBlank(msg)) {
			body += '\nMessage: ' + msg;
		}

		mail.setSaveAsActivity(false);
		mail.setSubject(subject);
		mail.setPlainTextBody(body);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}


	public static void emailStatusOfBatchJob(String jobId) {
		emailStatusOfBatchJob(jobId, null, null);
	}


	public static void confirmMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, message));
	}

	public static void infoMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, message));
	}

	public static void warnMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, message));
	}

	public static void errorMsg(String message) {
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, message));
	}

	public static void errorMsg(Exception e) {
		ApexPages.addMessages(e);
		logError(e);// also log it to save line in controller
	}

	public static void errorLightning(Exception e) {
		logError(e);// also log it to save line in controller
		AuraHandledException ahe = new AuraHandledException(e.getMessage());
		ahe.setMessage(e.getMessage());
		throw ahe;
	}

	public static void log(String msg) {
		System.debug(LoggingLevel.INFO, msg);
	}

	public static void log(SObject obj) {
		System.debug(LoggingLevel.INFO, obj);
	}

	public static void logError(Exception e) {
		System.debug(LoggingLevel.ERROR, e.getMessage());
		System.debug(LoggingLevel.ERROR, e.getStackTraceString());
	}

/*	THESE METHODS MAY BE USEFUL IN THE FUTURE

	public static Task createCompletedTask(String subject, String description, Id ownerId, String whoId, String whatId) {
		Task t = new Task();
		t.Subject = subject; // length = 255
		t.Description = description; // length = 32,000
		t.OwnerId = ownerId;
		t.ActivityDate = Date.today();
		t.Status = 'Completed';
		t.Type = 'Other';
		if (String.isNotBlank(whoId)) {
			try { // make sure we don't cause an exception with a bad id
				Id sobjId1 = Id.valueOf(whoId);
				t.WhoId = whoId;
			} catch (Exception e) {
				Utils.logError(e);
			}
		}
		if (String.isNotBlank(whatId)) {
			try { // make sure we don't cause an exception with a bad id
				Id sobjId1 = Id.valueOf(whatId);
				t.WhatId = whatId;
			} catch (Exception e) {
				Utils.logError(e);
			}
		}
		insert t;
		return t;
	}


	// not using method now - may come back though
	public static Decimal replaceZeroWithNull(Decimal val) {
		if (val == 0) {
			return null;
		}
		if (val != null) {
			// let's clean up the decimals - main purpose is to get trailing zeros removed but also keep 2 decimal places unless more decimals are needed
			if (val.stripTrailingZeros() == val.setscale(2)) { // make sure setting scale to 2 doesn't round up or down - no bueno
				return val.setscale(2); // if not - return it
			}
			return val.stripTrailingZeros(); // otherwise strip trailing zeros
		}
		return val;
	}


	public static String removeCommas(Integer val) {
		// SF puts a comma in Integers when they're converted to a String
		if (val == null) {
			return null;
		}
		// convert Integer to a String
		String stringVal = val.format();

		// strip out all non-digit chars
		return stringVal.replaceAll('[\\D]', '');
	}


	public static String convertSetToCommaSeparatedString(Set<String> vals) {
		String returnVal = '';
		if (vals != null && vals.size() > 0) {
			for (String val : vals) {
				if (String.isNotBlank(val)) {
					returnVal += val + ',';
				}
			}
			returnVal = returnVal.removeEnd(',');
		}
		return returnVal;
	}


	public static String setFieldValue(String field, String value) {
		String returnVal = '';
		if (String.isNotBlank(field)) {
			returnVal = field;
		}

		if (String.isNotBlank(returnVal)) {
			if (String.isNotBlank(value)) {
				returnVal += '\n' + value;
			}
		} else {
			returnVal = removeNull(value);
		}
		return returnVal;
	}

	public static Set<String> getQuerySelectFields(Map<String,Schema.SObjectField> fieldMap, Set<String> additionalFields, Set<String> excludedFields) {
		Set<String> selectFields = new Set<String>();
		System.debug(LoggingLevel.INFO, 'There are ' + fieldMap.size() + ' total fields for object');
		for (String key : fieldMap.keySet()) {
			Schema.SObjectField value = fieldMap.get(key);
			//System.debug(LoggingLevel.INFO, 'Schema.SObjectField = ' + value);
			Schema.DescribeFieldResult field = null;
			try {
				field = value.getDescribe();
			} catch (Exception e) {
				System.debug(LoggingLevel.ERROR, 'cannot access DescribeFieldResult for' + value);
			}

			// use to have a field.isAccessible() check in the if stmt below but caused to bugs since there UMNTC and UMN deal with different sets of fields on Contact
			if (field != null) { // this will return formula fields and auto numbers - developers are responsible for not setting these values since it will fail
				selectFields.add(field.getName());
			} else {
				System.debug(LoggingLevel.INFO, value + ' is null');
			}
		}
		System.debug(LoggingLevel.INFO, 'Found ' + selectFields.size() + ' fields for object');
		if (additionalFields != null && additionalFields.size() > 0) {
			selectFields.addAll(additionalFields);
		}
		if (excludedFields != null && excludedFields.size() > 0) {
			selectFields.removeAll(excludedFields);
		}
		// SF is failing on these fields for some stupid reason and we don't need them - exclude from all queries
		Set<String> excludedFieldsThatCauseQueryExceptions = new Set<String> {'Description', 'LastViewedDate'
				, 'LastReferencedDate', 'IsEmailBounced', 'PhotoUrl', 'OtherLongitude', 'OtherLatitude'
				, 'MailingLongitude', 'MailingLatitude', 'MailingAddress', 'OtherAddress'};
		selectFields.removeAll(excludedFieldsThatCauseQueryExceptions);
		return selectFields;
	}


	public static String buildSelectStatement(Schema.sObjectType sObjType, Set<String> fields, String whereClause) {
		String queryStr = 'select ';
		for (String field : fields) {
			queryStr += field + ',';
		}
		return queryStr.removeEnd(',') + ' from ' + sObjType.getDescribe().getName() + ' ' + removeNull(whereClause);
	}


	public static void postToChatter(String chatterGroupName, String chatterPostTitle, String chatterPostBody) {
		if (String.isNotBlank(chatterGroupName)) {
			List<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where name = :chatterGroupName];
			if (chatterGroups.size() > 0) {
				FeedItem post = new FeedItem();
				post.Title = chatterPostTitle;
				post.Body = chatterPostBody;
				post.ParentId = chatterGroups[0].Id;

				// security check before insert
				List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
					FeedItem.Title,
					FeedItem.Body,
					FeedItem.ParentId
				};
				Access.checkPermissions(AccessType.CREATABLE, new List<SObject> {post}, fieldsToCheck);

				insert post;
			}
		}
	}
*/
}