/* here's how to use this service to create log records for exceptions or informational messages

- log an exception
Constants.ValidationException ex = new Constants.ValidationException('error');
LogService.insertLog(new Log(ex, 'ClassName.methodName', 'large field to store addtional debug logic'));

- log a message
LogService.insertLog(new Log('batch job completed', 'ClassName.methodName', 'process x records with these errors: '));

- create multiple log records in one call
List<Log> logs = new List<Log>();
logs.add(new Log(new Constants.ValidationException('error 1'), 'ClassName.methodName', 'large field to store addtional debug logic'));
logs.add(new Log(new Constants.ValidationException('error 2'), 'ClassName.methodName', 'large field to store addtional debug logic'));
logs.add(new Log(new Constants.ValidationException('error 3'), 'ClassName.methodName', 'large field to store addtional debug logic'));
LogService.insertLogs(logs);

- output execution time of a method to a log record
Log timerLog = LogService.startTimer('ClassController.methodName');
... code you want to time
LogService.stopTimer(timerLog);

- keep the 10 most recent days of log records and delete the rest
Integer daysToKeep = 10;
LogService.deleteOldLogRecords(daysToKeep);
*/
global with sharing class LogService {

	// convenience method for when there is only 1 exception to log
	global static void insertLog(Log rec) {
		insertLogs(new List<Log> {rec});
	}

	global static void insertLogs(List<Log> recs) {
		List<Log__c> logs = new List<Log__c>();
		try {
			if (recs != null && recs.size() > 0) {
				for (Log rec : recs) {
					Log__c lo = new Log__c();
					if (rec.excep != null) {
						lo.Message__c = Utils.shortenString(rec.excep.getMessage(), 255);// text 255 - shorten if too long
					} else if (String.isNotBlank(rec.message)) {
						lo.Message__c = Utils.shortenString(rec.message, 255);// text 255 - shorten if too long
					}
					lo.Location__c = Utils.shortenString(rec.location, 255);// text 255 - shorten if too long

					String info = '';

					if (rec.excep != null) {
						info += 'Exception Type = ' + rec.excep.getTypeName() + '\n\n';
						info += 'Full Error Message = ' + rec.excep.getMessage() + '\n\n';
						Utils.logError(rec.excep); // log this to SF log - useful for development
					}
					if (String.isNotBlank(rec.info)) {
						info += rec.info;
					}

					lo.Information__c = Utils.shortenString(info, 131072);// long text area 131,072 - shorten if too long

					logs.add(lo);
				}
				if (logs.size() > 0) {
					List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
						Log__c.Information__c,
						Log__c.Location__c,
						Log__c.Message__c
					};
					Access.checkPermissions(Log__c.SObjectType, logs, AccessType.CREATABLE, fieldsToCheck);

					insert logs;
				}
			}
		} catch (Exception e) {// log to SF debug log and eat it
			Utils.logError(e);
		}
	}

	public static Log startTimer(String location) {
		return new Log(Datetime.now(), location);
	}

	public static void stopTimer(Log lo) {
		// could evaluate if running in a sandbox and only log execution time there
		// that way timer logging wouldn't happen in production to keep it running fast
		try {
			if (lo == null || lo.startTime == null || String.isBlank(lo.location)) {
				throw new Constants.ValidationException('Missing data for LogService.stopTimer');
			}
			Log__c rec = new Log__c();
			rec.Message__c = 'Executed in ' + (Datetime.now().getTime() - lo.startTime.getTime()) + ' milliseconds';
			rec.Location__c = Utils.shortenString(lo.location, 255);// text 255 - shorten if too long

			List<Schema.SObjectField> fieldsToCheck = new List<Schema.SObjectField> {
				Log__c.Location__c,
				Log__c.Message__c
			};
			Access.checkPermissions(Log__c.SObjectType, new List<Log__c> {rec}, AccessType.CREATABLE, fieldsToCheck);
			insert rec;
		} catch (Exception e) {// log to SF debug log and eat it
			Utils.logError(e);
		}
	}

	// deletes up to 10,000 Log__c records at a time - making global in case we need to do it in a customer's org
	// not doing this as a Batch - shouldn't need to delete more than 10,000 on a daily basis
	global static void deleteOldLogRecords(Integer daysToKeep) {
		Access.checkIsDeleteable(Log__c.SObjectType); // throws exception if user does not have delete permission on Log__c
		if (daysToKeep == null) {
			daysToKeep = 30;
		}

		Date d = System.today() - daysToKeep;
		List<Log__c> logs = [select Id from Log__c where SystemModstamp < :d
			with SECURITY_ENFORCED limit 10000];

//		if (logs.size() > 0) {
			delete logs;
//		}
	}
}