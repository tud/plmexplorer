var pexLayout;
var pexAccordion;

var grid_imgpath='/javascripts/themes/plmexplorer/images';

$(document).ready(function () {
	// fix png for ie6
	$(document).pngFix();
	
	// fix for jQuery
	$.ajaxSetup({ 
		'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
	});

	// UI.layout
	pexLayout = $('body').layout({
		applyDefaultStyles: true
	,	north__size: 110
	,	north__spacing_open: 3
	,	south__spacing_open: 0
	,	west__spacing_open: 3
	,	west__onresize: function(){
			$('#wNavigation').accordion('resize');
		}
	,	center__onresize: function(){
			var centerWidth = pexLayout.cssWidth('center');
			$('#findGrid').setGridWidth(centerWidth -25);
			$('#promotionsGrid').setGridWidth(centerWidth-45);
			$('#revisionsGrid').setGridWidth(centerWidth-45);
			$('#signoffsGrid').setGridWidth(centerWidth-45);
			$('#refsGrid').setGridWidth(centerWidth-45);
		}
	});

	// navigation accordion
	pexAccordion = $('#wNavigation').accordion({
		fillSpace: true
	,	navigation: true
	,	header: "h3"
	});

	// prima riga tabs
	$('#cMenuTabs > ul').tabs();

	$('.wNavigation_find').click(function() {
		var rectype = $(this).attr('title');
		$('#cFind').load('/rectype/'+rectype+'/find');
		$("#cMenuTabs > ul").tabs('select',0);
	});
});