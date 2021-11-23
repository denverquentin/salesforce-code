/*
making this global so our customer's can use it if they want
have this as it's own class since the name is short
*/
global with sharing class Log {
	global String message {get;set;}
	global Exception excep {get;set;}
	global String location {get;set;}
	global String info {get;set;}

	global Log() {}

	global Log(String message, String location, String info) {
		this.message = message;
		this.location = location;
		this.info = info;
	}

	global Log(Exception excep, String location, String info) {
		this.excep = excep;
		this.location = location;
		this.info = info;
	}
}