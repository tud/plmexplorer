jQuery.fn.checkboxToggle = function(opt,label){
	var check;
	var img;
	if (label) {
		check = jQuery(this).prev();
		img = check.prev();
	} else {
		check = jQuery(this).next();
		img = this;
	}
	var checkVal = check[0].checked == true;
	img.attr({ src: checkVal ? opt.unchecked : opt.checked })
	check[0].checked = !checkVal;
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
					jQuery(this).checkboxToggle(opt, false);
				})
				// Attach image
				.insertBefore(this);
			jQuery(this).next().click(function() {
					jQuery(this).checkboxToggle(opt, true);
				});
		});
}

jQuery.fn.radioToggle = function(opt, checks, label){
	var check;
	if (label) {
		check = jQuery(this).prev();
	} else {
		check = jQuery(this).next();
	}
	check[0].checked = true;
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
					jQuery(this).radioToggle(opt, checks, false);
				})
				// Attach image	
				.insertBefore(this);
			jQuery(this).next().click(function() {
					jQuery(this).radioToggle(opt, checks, true);
				});
		});
}