public inherited sharing class Constants {
	public static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR = 'System Administrator';
	public static final String PERM_SET_API_NAME = 'PermSet';

	public class ValidationException extends Exception {}
	public class UnexpectedException extends Exception {}

	@AuraEnabled
	public static String getOrgId() {
		List<Variable__mdt> var = [select Org_Id__c from Variable__mdt where DeveloperName = 'MyOrg' with SECURITY_ENFORCED];
		return var[0].Org_Id__c;
	}


/* useful code for determing namespace
	public static final String NAMESPACE = 'hi';
	public static final String PACKAGED_OBJ = NAMESPACE + '__Only_Exists_In_Package__c';

	// if in namespaced org, will return NAMESPACE__ - else ''
	public static String getFieldObjectNS() {
		// return blank instead of null so we don't have to do a null check
		// we can just prepend it to a custom Object or Field
		return getNameSpacePrefix() == null ? '' : getNameSpacePrefix() + '__';
	}

	// if in namespaced org, will return NAMESPACE. - else ''
	public static String getClassNS() {
		// return blank instead of null so we don't have to do a null check
		// we can just prepend it to a custom Object or Field
		return getNameSpacePrefix() == null ? '' : getNameSpacePrefix() + '.';
	}

	// if in namespaced org, will return just NAMESPACE - else null. useful for lightning out
	public static String getNameSpacePrefix() {
		//check if there is a object with the namespace
		Map<String, Schema.SObjectType> objList = Schema.getGlobalDescribe();
		return objList.get(PACKAGED_OBJ) == null ? null : NAMESPACE;
	}
*/

	/* useful if we start using record types
	private static final Map<String,Schema.RecordTypeInfo> accountRecordTypes = Schema.SObjectType.Account.getRecordTypeInfosByName();

	public static final String REC_TYPE_MERCHANT = 'Merchant';
	public static final String REC_TYPE_PARTNER = 'Partner';

	// record type id constants - format is REC_TYPE_ID_OBJECT_NAME_RECORDTYPENAME
	public static final Id REC_TYPE_ID_ACCOUNT_MERCHANT = accountRecordTypes.get(REC_TYPE_MERCHANT).getRecordTypeId();
	public static final Id REC_TYPE_ID_ACCOUNT_PARTNER = accountRecordTypes.get(REC_TYPE_PARTNER).getRecordTypeId();
	*/
}