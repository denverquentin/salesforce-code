import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrgId from "@salesforce/apex/Constants.getOrgId";

export default class LeadCreateForm extends LightningElement {
	formSubmitted = false;
	first = null;
	last = null;
	company = null;
	email = '';
	phone = '';
	country = '';
	orgId;

	connectedCallback() {
		this.formSubmitted = false;
		getOrgId().then(response => {
			this.orgId = response;
			//console.log('this.orgId = ' + this.orgId);
		}).catch(error => {
			console.log(error);
		});
	}

	handleSubmit() {
		if (this.allFieldsValid()) { // make sure required fields are set
			// https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch
			fetch('https://webto.salesforce.com/servlet/servlet.WebToLead',
			{
				method:'POST',
				mode: 'no-cors',
				headers: {
					'Content-Type': 'text/html; charset=UTF-8'
				},
				body: new URLSearchParams({
					'encoding': 'UTF-8',
					'oid': this.orgId,
					'retURL': '',
					'lead_source': 'Salesforce App',
					'first_name' : this.first,
					'last_name': this.last,
					'company': this.company,
					'email': this.email,
					'phone': this.phone,
					//'debug': '1',
					//'debugEmail': 'quentinf@gmail.com',
					'country': this.country
				})
			}).then(response => {
				this.formSubmitted = true; // hides the form and shows a "we'll be in touch" message
				this.dispatchEvent(new ShowToastEvent({
					title: 'Thanks!',
					variant: 'success',
					message: 'We\'ll be in touch soon.',
					mode: 'sticky'
				}));
			}).catch(error => {
				console.log('callout error ===> '+ JSON.stringify(error));
				this.dispatchEvent(new ShowToastEvent({
					title: 'Error',
					variant: 'error',
					message: error,
					mode: 'sticky'
				}));
			})
		}
	}

	handleOnChange(event) {
		this[event.target.name] = event.target.value;
	}

	handleEnterKey(component) {
		if (component.which === 13 && this.allFieldsValid()) { // if enter key and valid
			this.handleSubmit();
		}
	}

	allFieldsValid() {
		let valid = true;
		this.template.querySelectorAll('lightning-input').forEach(element => {
			if (valid) {
				valid = element.reportValidity(); // returns false if required field is blank
			}
		});
		return valid;
	}
}