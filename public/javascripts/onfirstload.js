$(document).ready(function () {
	console.log(">"+$('#cFind').html()+"<");
	if ($('#cFind').html() == "") {
		$('#cFind').load('/rectype/part/find');
		$("#cMenuTabs > ul").tabs('select',0);
	}
});