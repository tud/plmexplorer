function pageload(hash) {
		// hash doesn't contain the first # character.
		if(hash) {
			// restore ajax loaded state
			$j("#load").load(hash + ".html");
		} else {
			// start page
			$j("#load").empty();
		}
	}

jQuery(document).ready(function(){
	// round corners
	jQuery('#topsearch').corner("20px top");
	jQuery('#bottomsearch').corner("20px bottom");
	jQuery('#header').corner("20px");
	jQuery('#content').corner("20px");
	jQuery('#footer').corner("10px");
	jQuery('#record_title').corner("5px");

	// fix png for ie6
	jQuery('img[@src$=png]').ifixpng();
});

// fix for jQuery
jQuery.ajaxSetup({ 
	'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
});
