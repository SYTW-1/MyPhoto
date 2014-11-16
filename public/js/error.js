function error(evt) {
	var error = document.getElementById('error-message');
	if(error != undefined){
		setTimeout(function(){
			error.parentNode.removeChild(error);
		},5000);
	}
}