public inherited sharing class Constants {
	public class ValidationException extends Exception {}
	public class UnexpectedException extends Exception {}

	public static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR = 'System Administrator';
	public static final String PERM_SET_API_NAME = 'PermSet';

	/* useful if we start using record types
	private static final Map<String,Schema.RecordTypeInfo> accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

	public static final String REC_TYPE_MERCHANT = 'Merchant';
	public static final String REC_TYPE_PARTNER = 'Partner';

	// record type id constants - format is REC_TYPE_ID_OBJECT_NAME_RECORDTYPENAME
	public static final Id REC_TYPE_ID_ACCOUNT_MERCHANT = accountRecordTypes.get(REC_TYPE_MERCHANT).getRecordTypeId();
	public static final Id REC_TYPE_ID_ACCOUNT_PARTNER = accountRecordTypes.get(REC_TYPE_PARTNER).getRecordTypeId();
	*/
}
