public inherited sharing class Access {
	// easy way to check object and field accessibility before CRUD calls
	// we'll use the checkIsAccessible methods to for our objects and fields we expect to be accessible/createable/updateable
	// and we'll use the isAccessible methods to check standard objects and fields that may not be accessible/createable/updateable
	// so we know if they should be queried or upserted

	private static final String FIX_MSG = ' You can fix this error by assigning the correct Permission Set to the User or updating their Profile.';

	public virtual class AccessException extends Exception { }

	/*
	throws exception if the user doesn't have the right access on the object OR if the fields passed into the method don't have access.
	this methods throws an exception if ANY of the fields passed in	aren't accessible on any of the records passed in

	Supported AccessType values: AccessType.READABLE
								 AccessType.CREATABLE
								 AccessType.UPDATABLE
								 AccessType.UPSERTABLE
	 */
	public static void checkPermissions(SObjectType recType, List<SObject> records, AccessType aType, List<Schema.SObjectField> fieldsToCheck) {
		Log timer = LogService.startTimer('Access.checkPermissions - Schema.SObjectField');
		Utils.log('checkPermissions.aType = ' + aType);

		for (SObject rec : records) { // check that the recType matches the SObjectType of each record passed in
			//Utils.log('rec = ' + rec);
			if (rec.getSObjectType() != recType) {
				throw new AccessException('recType ' + recType + ' does not match rec.SObjectType ' + rec.getSObjectType());
			}
		}

		Boolean enforceRootObjectCRUD = true;
		SObjectAccessDecision decision = Security.stripInaccessible(aType, records, enforceRootObjectCRUD);
		//Utils.log('decision = ' + decision);

		// line below throws an exception if the user doesn't have the permission on the object! this lets us call 1 method instead of 2
		Set<String> removedFields = decision.getRemovedFields().get(recType.getDescribe().getName());
		//Utils.log('removedFields = ' + removedFields);

		// for AccessType.READABLE, we could return an error if there are ANY removed fields
		// but it's not safe if we're checking any of the other AccessType's because a read-only field
		// like a formula or auto-number Name could be removed if the field is queried but is not removed
		// before calling this method. a SF DML call will ignore these read-only fields and not throw an exception

//		Utils.log('fieldsToCheck = ' + fieldsToCheck);
		// only need to continue if fieldsToCheck and removedFields have values
		if (fieldsToCheck != null && fieldsToCheck.size() > 0 && removedFields != null && removedFields.size() > 0) {
			Set<Schema.SObjectField> fieldsRemoved = new Set<Schema.SObjectField>();
			Map<String,SObjectField> fieldsForObj = recType.getDescribe().fields.getMap();
			for (String removedField : removedFields) {
				fieldsRemoved.add(fieldsForObj.get(removedField.toLowerCase()));
			}

			for (Schema.SObjectField f : fieldsToCheck) {
				//Utils.log('f = ' + f);
				if (fieldsRemoved.contains(f)) {
					throw new AccessException('You do not have permission to ' + getEnglishForAccessType(aType) + ' the ' + f + ' field.' + FIX_MSG);
				}
			}
		}
		LogService.stopTimer(timer);
	}


	/* identical to method above except that the fieldsToCheck is a List<String> instead of List<Schema.SObjectField>
	   which makes the code below easier we'll probably call this a lot because SObject has a nice
	   Map<String,Object> fieldsToValue = rec.getPopulatedFieldsAsMap(); method that returns fields as a String
	*/
	public static void checkPermissions(SObjectType recType, List<SObject> records, AccessType aType, Set<String> fieldsToCheck) {
		Log timer = LogService.startTimer('Access.checkPermissions - String');
		Utils.log('checkPermissions.aType = ' + aType);

		for (SObject rec : records) { // check that the recType matches the SObjectType of each record passed in
			//Utils.log('rec = ' + rec);
			if (rec.getSObjectType() != recType) {
				throw new AccessException('recType ' + recType + ' does not match rec.SObjectType ' + rec.getSObjectType());
			}
		}

		Boolean enforceRootObjectCRUD = true;
		SObjectAccessDecision decision = Security.stripInaccessible(aType, records, enforceRootObjectCRUD);
		//Utils.log('decision = ' + decision);

		// line below throws an exception if the user doesn't have the permission on the object! this lets us call 1 method instead of 2
		Set<String> removedFields = decision.getRemovedFields().get(recType.getDescribe().getName());
		//Utils.log('removedFields = ' + removedFields);

		// for AccessType.READABLE, we could return an error if there are ANY removed fields
		// but it's not safe if we're checking any of the other AccessType's because a read-only field
		// like a formula or auto-number Name could be removed if the field is queried but is not removed
		// before calling this method. a SF DML call will ignore these read-only fields and not throw an exception

		Utils.log('fieldsToCheck = ' + fieldsToCheck);
		// only need to continue if fieldsToCheck and removedFields have values
		if (fieldsToCheck != null && fieldsToCheck.size() > 0 && removedFields != null && removedFields.size() > 0) {
			for (String f : fieldsToCheck) {
				//Utils.log('f = ' + f);
				if (removedFields.contains(f)) {
					throw new AccessException('You do not have permission to ' + getEnglishForAccessType(aType) + ' the ' + f + ' field.' + FIX_MSG);
				}
			}
		}
		LogService.stopTimer(timer);
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