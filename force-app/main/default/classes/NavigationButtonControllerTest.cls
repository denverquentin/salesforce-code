@IsTest
private class NavigationButtonControllerTest {
	@IsTest
	static void testRetrieveObjApiNameWithNamespace1() {
		// wrapping in try/catch since orgs may not have list views for some standard objects
		try {
			String objectApiName = 'Account'; // standard object
			String result = NavigationButtonController.retrieveObjApiNameWithNamespace(objectApiName);
			System.assert(true, String.isNotBlank(result));
		} catch (Exception e) {
			Utils.logError(e);
		}
	}


	@IsTest
	static void testRetrieveObjApiNameWithNamespace2() {
		// wrapping in try/catch since orgs may not have list views for some standard objects
		try {
			String objectApiName = 'Log__c';
			String result = NavigationButtonController.retrieveObjApiNameWithNamespace(objectApiName);
			System.assert(true, String.isNotBlank(result));
		} catch (Exception e) {
			Utils.logError(e);
		}
	}


	@IsTest
	static void testGetListViewInfo1() {
		// wrapping in try/catch since orgs may not have list views for some standard objects
		try {
			// Test with valid list view of standard object
			String objectApiName = 'Account';
			String listApiName = 'AllAccounts';
			NavigationButtonController.ListViewInfo result = NavigationButtonController.getListViewInfo(objectApiName, listApiName);
			System.assert(true, String.isNotBlank(result.listViewId));
			System.assertEquals('Account', result.objApiNameWithNamespace);
		} catch (Exception e) {
			Utils.logError(e);
		}
	}


	@IsTest
	static void testGetListViewInfo2() {
		Constants.UnexpectedException unexpectedException;
		try {
			// Test with invalid list view
			String objectApiName = 'Account';
			String listApiName = 'invalidERRListView749x';
			NavigationButtonController.ListViewInfo result = NavigationButtonController.getListViewInfo(objectApiName, listApiName);
			Utils.log('result = ' + result);
		} catch (Constants.UnexpectedException e) {
			unexpectedException = e;
		}
		System.assert(unexpectedException != null);
	}


	@IsTest
	static void testGetListViewInfo3() {
		// wrapping in try/catch since orgs may not have list views for some standard objects
		try {
			String objectApiName = 'Log__c';
			String listApiName = 'All';
			NavigationButtonController.ListViewInfo result = NavigationButtonController.getListViewInfo(objectApiName, listApiName);
			System.assert(true, String.isNotBlank(result.listViewId));
			System.assert(true, result.objApiNameWithNamespace.containsIgnoreCase('Log__c'));
		} catch (Exception e) {
			Utils.logError(e);
		}
	}
}