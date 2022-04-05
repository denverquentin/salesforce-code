import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getListViewInfo from '@salesforce/apex/NavigationButtonController.getListViewInfo';
import retrieveObjApiNameWithNamespace from '@salesforce/apex/NavigationButtonController.retrieveObjApiNameWithNamespace';

export default class navigationButton extends NavigationMixin(LightningElement) {
	@api label;
	@api buttonStyle; // base,brand,destructive,inverse,neutral,outline-brand,success,text-destructive
	@api buttonStretch; // Yes, No
	@api target; // navigateToURL,navigateToListView,navigateToObjectHome
	@api objectApiName;
	@api listApiName;
	@api url;

	get divClass() { // bg color of div holding button/link
		var cl = 'slds-m-around_x-small ';
		if (this.buttonStretch === 'No') { // pad a little if no stretch
			cl += 'slds-p-left_xx-small ';
		}
		if (this.buttonStyle === 'base') { // show background for some styles
			cl += 'slds-theme_default';
		} else if (this.buttonStyle === 'inverse') {
			cl += 'slds-theme_inverse';
		}
		return cl;
	}


	get buttonClass() {
		var stretchIt = '';
		if (this.buttonStretch === 'Yes') {
			stretchIt = 'slds-button_stretch ';
		}
		return 'slds-button ' + stretchIt + 'slds-button_' + this.buttonStyle;
	}

	handleClick() {
		if (this.target === 'navigateToListView') {
			this.navigateToListView();
		} else if (this.target === 'navigateToObjectHome') {
			this.navigateToObjectHome();
		} else if (this.target === 'navigateToURL') {
			this.navigateToWebPage();
		}
	}

	navigateToListView() {
		getListViewInfo({
			objectApiName: this.objectApiName,
			listApiName: this.listApiName
		}).then((result) => {
			let { objApiNameWithNamespace, listViewId } = result;
			// Navigate to the object's list view.
			this[NavigationMixin.Navigate]({
				type: 'standard__objectPage',
				attributes: {
					objectApiName: objApiNameWithNamespace,
					actionName: 'list'
				},
				state: {
					filterName: listViewId
				}
			});
		}).catch((error) => {
			console.error(error);
			this.showToast(`${this.label} Error`, error.body.message, 'error');
		});
	}

	navigateToObjectHome() {
		let apiName = this.objectApiName.toLowerCase();
		//If this is custom object, get object API name with namespace
		if (apiName.endsWith('__c')) {
			retrieveObjApiNameWithNamespace({
				objectApiName: this.objectApiName
			}).then((result) => {
				this.doNavigateToObjectHome(result);
			}).catch((error) => {
				console.error(error);
				this.showToast(`${this.label} Error`, error.body.message, 'error');
			});
		} else {
			this.doNavigateToObjectHome(this.objectApiName);
		}
	}

	doNavigateToObjectHome(objApiNameWithNamespace) { // Navigate to the object home
		this[NavigationMixin.Navigate]({
			type: 'standard__objectPage',
			attributes: {
				objectApiName: objApiNameWithNamespace,
				actionName: 'home'
			}
		});
	}

	navigateToWebPage() { // Navigate to a URL
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: this.url
			}
		});
	}

	// todo: put this into common javascript file
	showToast(title, message, variant) {
		const event = new ShowToastEvent({title, message, variant});
		// Dispatch toast event to display toast notification
		this.dispatchEvent(event);
	}
}