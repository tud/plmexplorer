$(document).ready(function () {
	if ($('#cFind').html() == "") {
		$('#cFind').load('/rectype/part/find');
		$("#cMenuTabs > ul").tabs('select',0);
	}
});