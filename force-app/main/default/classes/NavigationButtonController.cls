/**
 * @desc Used by NavigationButton LWC
 * to retrive list view info for navigation purposes
 */
public with sharing class NavigationButtonController {
	/**
	 *  @desc Return ListViewInfo data
	 */
	@AuraEnabled
	public static ListViewInfo getListViewInfo(String objectApiName, String listApiName) {
		try {
			String objApiNameWithNamespace = Utils.getObjApiNameWithNamespace(objectApiName);

			String listViewId = [SELECT Id, Name FROM ListView WHERE developerName = :listApiName
			AND sObjectType = :objApiNameWithNamespace with SECURITY_ENFORCED].Id;
			return new ListViewInfo(objApiNameWithNamespace, listViewId);
		} catch (Exception e) {
			Utils.logError(e);
			throw new Constants.UnexpectedException('Unable to find a List View named ' + listApiName + '.');
		}
	}


	/**
	 *  @desc Return object api name with namespace
	 */
	@AuraEnabled
	public static String retrieveObjApiNameWithNamespace(String objectName) {
		return Utils.getObjApiNameWithNamespace(objectName);
	}


	// ListViewInfo Wrapper Class
	public class ListViewInfo {
		public ListViewInfo(String objApiNameWithNamespace, String listViewId) {
			this.objApiNameWithNamespace = objApiNameWithNamespace;
			this.listViewId = listViewId;
		}

		@AuraEnabled
		public String listViewId;

		@AuraEnabled
		public String objApiNameWithNamespace;
	}
}