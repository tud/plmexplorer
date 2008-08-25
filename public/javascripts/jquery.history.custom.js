jQuery.history.callback = function ( reinstate, cursor ) {
	// check to see if were back to the beginning without any stored data
	if (typeof(reinstate) == 'undefined') {
		history.back();
	} else {
		id = parseInt(reinstate) || 0;
		jQuery.ajax({
			type: "POST",
			url: ("/brecords/load_record_base?id="+id.toString()),
			dataType: "script"
		});
	}
};