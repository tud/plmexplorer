var pexLayout;
var pexAccordion;

$(document).ready(function () {
	// fix png for ie6
	$(document).pngFix();
	
	// fix for jQuery
	jQuery.ajaxSetup({ 
		'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
	});

	pexLayout = $('body').layout({
		applyDefaultStyles: true
	,	north__size: "auto"
	,	north__spacing_open: 0
	,	west__spacing_closed: 10
	,	west__onresize: function(){
			jQuery('#wNavigation').accordion('resize');
		}
	,	center__onresize: function(){
			var centerWidth = pexLayout.cssWidth('center');
			jQuery('#searchGrid').setGridWidth(centerWidth -25);
			jQuery('#promotionsGrid').setGridWidth(centerWidth-45);
			jQuery('#revisionsGrid').setGridWidth(centerWidth-45);
			jQuery('#signoffsGrid').setGridWidth(centerWidth-45);
			jQuery('#refsGrid').setGridWidth(centerWidth-45);
		}
	});

	pexAccordion = $('#wNavigation').accordion({
		fillSpace: true
	,	navigation: true
	,	header: "h3"
	});

	$("#cMenu > ul").tabs();

	$("#cRecord > ul").tabs();
	
	$('.find_rec').click(function() {
		var rectype = $(this).attr('title');
		$('#cFind').load('/rectype/'+rectype+'/find');
		$("#cMenu > ul").tabs("select",0);
	});
});