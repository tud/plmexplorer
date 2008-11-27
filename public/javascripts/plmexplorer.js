var pexLayout;
var pexAccordion;

$(document).ready(function () {
	// fix png for ie6
	jQuery('img[@src$=png]').ifixpng();
	
	// fix for jQuery
	jQuery.ajaxSetup({ 
		'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
	});

	pexLayout = $('body').layout({
		applyDefaultStyles: true
	,	north__size: "auto"
	,	north__spacing_open: 0
	,	west__spacing_closed: 10
	,	onresize: function(){
			jQuery('#wNavigation').accordion('size');
			var centerWidth = pexLayout.cssWidth('center');
			jQuery('#searchGrid').setGridWidth(centerWidth - 50);
			jQuery('#promotionsGrid').setGridWidth(centerWidth - 90);
			jQuery('#revisionsGrid').setGridWidth(centerWidth - 90);
			jQuery('#signoffsGrid').setGridWidth(centerWidth - 90);
			jQuery('#refsGrid').setGridWidth(centerWidth - 90);
		}
	});

	pexAccordion = $('#wNavigation').accordion({
		fillSpace: true
	,	navigation: true
	,	header: "div.header"
	});

	$("#cMenu > ul").tabs();

	$("#cRecord > ul").tabs();
	
	$('.find_rec').click(function() {
		var rectype = $(this).attr('title');
		$('#cFind').load('/rectype/'+rectype+'/find');
		$("#cMenu > ul").tabs("select",0);
	});
});