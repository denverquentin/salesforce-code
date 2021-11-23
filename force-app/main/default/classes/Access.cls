public inherited sharing class Access {
	// easy way to check object and field accessibility before CRUD calls
	// we'll use the checkIsAccessible methods to for our objects and fields we expect to be accessible/createable/updateable
	// and we'll use the isAccessible methods to check standard objects and fields that may not be accessible/createable/updateable
	// so we know if they should be queried or upserted

	public virtual class AccessException extends Exception { }

	private static final String FIX_MSG = ' You can fix this error by assigning the correct Permission Set to the User or updating their Profile.';

	/*
	throws exception if the user doesn't have the right access on the object OR if the fields passed into the method don't have access.
	this methods throws an exception if ANY of the fields passed in	aren't accessible on any of the records passed in

	Supported AccessType values: AccessType.READABLE
								 AccessType.CREATABLE
								 AccessType.UPDATABLE
								 AccessType.UPSERTABLE
	 */
	public static void checkPermissions(AccessType aType, List<SObject> records, List<Schema.SObjectField> fieldsToCheck) {
		//Datetime startTime = Datetime.now();
		Utils.log('checkPermissions.aType = ' + aType);
		//Utils.log('records = ' + records);

		SObjectAccessDecision decision = Security.stripInaccessible(aType, records); // also checks that object is accessible
		//Utils.log('decision = ' + decision);

		// line below can throw exception if the user doesn't have the permission on the object
		Map<String,Set<String>> res = decision.getRemovedFields();
		//Utils.log('res = ' + res);

		// for AccessType.READABLE, we could return an error if there are ANY removed fields
		// but it's not safe if we're checking any of the other AccessType's because a read-only field
		// like a formula or auto-number Name could be removed if the field is queried but is not removed
		// before calling this method. a SF DML call will ignore these read-only fields and not throw an exception

		Utils.log('fieldsToCheck = ' + fieldsToCheck);
		// only need to continue if fieldsToCheck has values
		if (fieldsToCheck != null && fieldsToCheck.size() > 0) {
			Map<String,Schema.SObjectType> objs = Schema.getGlobalDescribe();
			Map<Schema.SObjectType,Map<String,SObjectField>> fieldsForObj = new Map<Schema.SObjectType,Map<String,SObjectField>>();

			Set<Schema.SObjectField> allFieldsRemoved = new Set<Schema.SObjectField>();

			for (String obj : res.keySet()) {
				//Utils.log('obj = ' + obj);
				Schema.SObjectType objName = objs.get(obj.toLowerCase());
				if (!fieldsForObj.containsKey(objName)) { // add it
					fieldsForObj.put(objName, objName.getDescribe().fields.getMap());
				}
				Map<String,SObjectField> fields = fieldsForObj.get(objName);

				for (String f : res.get(obj)) {
					allFieldsRemoved.add(fields.get(f.toLowerCase()));
				}
			}

			Utils.log('all fields removed = ' + allFieldsRemoved);

			for (Schema.SObjectField f : fieldsToCheck) {
				//Utils.log('f = ' + f);
				if (allFieldsRemoved.contains(f)) {
					throw new AccessException('You do not have permission to ' + getEnglishForAccessType(aType) + ' the ' + f + ' field.' + FIX_MSG);
				}
			}
		}
		//Utils.log('Executed in ' + (Datetime.now().getTime() - startTime.getTime()) + ' milliseconds');
	}


	/* identical to method above except that the fieldsToCheck is a List<String> instead of List<Schema.SObjectField> which makes the code below easier
	   we'll probably call this a lot because SObject has a nice Map<String, Object> fieldsToValue = rec.getPopulatedFieldsAsMap(); method that returns
	   fields as a String
	   WARNING: THIS SHOULDN'T BE CALLED WITH MULTIPLE SObject types at once! I don't think the fieldsToCheck include the object reference like Schema.SObjectField does
	   that could lead to the scenario where a field named Custom__c is removed from on one SObject type but not another causes a false positive
	*/
	public static void checkPermissions(AccessType aType, List<SObject> records, Set<String> fieldsToCheck) {
		//Datetime startTime = Datetime.now();
		Utils.log('checkPermissions.aType = ' + aType);
		//Utils.log('records = ' + records);

		SObjectAccessDecision decision = Security.stripInaccessible(aType, records); // also checks that object is accessible
		//Utils.log('decision = ' + decision);

		// line below can throw exception if the user doesn't have the permission on the object
		Map<String,Set<String>> res = decision.getRemovedFields();
		//Utils.log('res = ' + res);

		// for AccessType.READABLE, we could return an error if there are ANY removed fields
		// but it's not safe if we're checking any of the other AccessType's because a read-only field
		// like a formula or auto-number Name could be removed if the field is queried but is not removed
		// before calling this method. a SF DML call will ignore these read-only fields and not throw an exception

		Utils.log('fieldsToCheck = ' + fieldsToCheck);
		// only need to continue if fieldsToCheck has values
		if (fieldsToCheck != null && fieldsToCheck.size() > 0) {
			Set<String> allFieldsRemoved = new Set<String>();

			for (Set<String> allFields : res.values()) {
				// todo: will this work multiple objects? does the string contain the object name and field name?
				// haven't tested it yet - could work but added warning to not use with multiple SObject types until we test
				allFieldsRemoved.addAll(allFields);
			}
	
			Utils.log('all fields removed = ' + allFieldsRemoved);

			for (String f : fieldsToCheck) {
				//Utils.log('f = ' + f);
				if (allFieldsRemoved.contains(f)) {
					throw new AccessException('You do not have permission to ' + getEnglishForAccessType(aType) + ' the ' + f + ' field.' + FIX_MSG);
				}
			}
		}
		//Utils.log('Executed in ' + (Datetime.now().getTime() - startTime.getTime()) + ' milliseconds');
	}


	@TestVisible
	private static String getEnglishForAccessType(AccessType at) {
		if (at == AccessType.READABLE) {
			return 'Read';
		} else if (at == AccessType.CREATABLE) {
			return 'Create';
		} else if (at == AccessType.UPDATABLE) {
			return 'Update';
		} else if (at == AccessType.UPSERTABLE) {
			return 'Upsert';
		}
		return '';
	}

	// the methods below may also be useful for simple permission checks but the above method handles both object and field permissions in one call
	public static Boolean isAccessible(Schema.SObjectType obj) {
		return obj.getDescribe().isAccessible();
	}

	public static void checkIsAccessible(Schema.SObjectType obj) {
		if (!isAccessible(obj)) {
			throw new AccessException('You do not have permission to Read ' + obj + ' records.' + FIX_MSG);
		}
	}

	public static void checkIsAccessible(List<Schema.SObjectType> objs) {
		for (Schema.SObjectType obj : objs) {
			checkIsAccessible(obj);
		}
	}


	public static Boolean isCreateable(Schema.SObjectType obj) {
		return obj.getDescribe().isCreateable();
	}

	public static void checkIsCreateable(Schema.SObjectType obj) {
		if (!isCreateable(obj)) {
			throw new AccessException('You do not have permission to Create ' + obj + ' records.' + FIX_MSG);
		}
	}

	public static void checkIsCreateable(List<Schema.SObjectType> objs) {
		for (Schema.SObjectType obj : objs) {
			checkIsCreateable(obj);
		}
	}


	public static Boolean isUpdateable(Schema.SObjectType obj) {
		return obj.getDescribe().isUpdateable();
	}

	public static void checkIsUpdateable(Schema.SObjectType obj) {
		if (!isUpdateable(obj)) {
			throw new AccessException('You do not have permission to Update ' + obj + ' records.' + FIX_MSG);
		}
	}

	public static void checkIsUpdateable(List<Schema.SObjectType> objs) {
		for (Schema.SObjectType obj : objs) {
			checkIsUpdateable(obj);
		}
	}


	public static Boolean isDeleteable(Schema.SObjectType obj) {
		return obj.getDescribe().isDeletable();
	}

	public static void checkIsDeleteable(Schema.SObjectType obj) {
		if (!isDeleteable(obj)) {
			throw new AccessException('You do not have permission to Delete ' + obj + ' records.' + FIX_MSG);
		}
	}

	public static void checkIsDeleteable(List<Schema.SObjectType> objs) {
		for (Schema.SObjectType obj : objs) {
			checkIsDeleteable(obj);
		}
	}


	public static Boolean isFieldAccessible(Schema.SObjectField fld) {
		return fld.getDescribe().isAccessible();
	}

	public static Boolean isFieldCreateable(Schema.SObjectField fld) {
		return fld.getDescribe().isCreateable();
	}

	public static Boolean isFieldUpdateable(Schema.SObjectField fld) {
		return fld.getDescribe().isUpdateable();
	}
}