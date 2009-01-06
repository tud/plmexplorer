jQuery.fn.checkboxToggle = function(opt){
	var check = jQuery(this).next()[0].checked == true;
	jQuery(this)
		.attr({ src: check ? opt.unchecked : opt.checked })
		.next()[0].checked = !check;
}

jQuery.fn.checkbox = function(opt){
   jQuery(":checkbox", this)
	   // Hide each native checkbox
	   .hide()
	   // Iterate through checkboxes and do all the magical stuff
	   .each(function (){
		   jQuery("<img>")
			   // Set image attributes
			   .attr({src: this.checked ? opt.checked : opt.unchecked, alt: "" })
			   //
			   .click(function() {
				   jQuery(this).checkboxToggle(opt);
			   })
			   // Attach image
			   .insertBefore(this);
	   });
}

jQuery.fn.radioToggle = function(opt, checks){

	var check = jQuery(this).next();
	jQuery(this).next()[0].checked = true;

	checks.each(function(){
		var isChecked = this.checked;
		jQuery(this).prev()[0].src = isChecked ? opt.checked : opt.unchecked;
	});
	check.change();
}

jQuery.fn.radio = function(opt){
	var checks = jQuery(":radio", this);
	jQuery(":radio", this)
		// Hide each native checkbox
		.hide()
		// Iterate through checkboxes and do all the magical stuff
		.each(function (){
			jQuery("<img>")
				// Set image attributes
				.attr({src: this.checked ? opt.checked : opt.unchecked, alt: "" })
				//
				.click(function() {
					jQuery(this).radioToggle(opt, checks);
				})
				// Attach image	
				.insertBefore(this);
		});
}