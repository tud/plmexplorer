jQuery.fn.maxLength = function(max){
	this.each(function(){
		//Get the type of the matched element
		var type = this.tagName.toLowerCase();
		//If the type property exists, save it in lower case
		var inputType = this.type? this.type.toLowerCase() : null;
		//Check if is a input type=text OR type=password
		if(type == "input" && inputType == "text" || inputType == "password"){
			//Apply the standard maxLength
			this.maxLength = max;
		}
		//Check if the element is a textarea
		else if(type == "textarea"){
			//Add the key press event
			this.onkeypress = function(e){
				//Get the event object (for IE)
				var ob = e || event;
				//Get the code of key pressed
				var keyCode = ob.keyCode;
				//Check if it has a selected text
				var hasSelection = document.selection? document.selection.createRange().text.length > 0 : this.selectionStart != this.selectionEnd;
				//return false if can't write more
				return !(this.value.length >= max && (keyCode > 50 || keyCode == 32 || keyCode == 0 || keyCode == 13) && !ob.ctrlKey && !ob.altKey && !hasSelection);
			};
			//Add the key up event
			this.onkeyup = function(){
				//If the keypress fail and allow write more text that required, this event will remove it
				if(this.value.length > max){
					this.value = this.value.substring(0,max);
				}
			};
		}
	});
};
