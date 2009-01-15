var pexLayout;
var grid_imgpath='/javascripts/themes/plmexplorer/images';

$(function() {
	// fix for jQuery
	$.ajaxSetup({ 
		'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
	});

	// UI.layout
	pexLayout = $('body').layout({
		applyDefaultStyles: true
	,	north__size: 110
	,	north__spacing_open: 3
	,	west__spacing_open: 3
	,	east__spacing_open: 3
	,	south__spacing_open: 0
	,	west__onresize: function(){
			$('#wNavigation').accordion('resize');
		}
	,	east__onresize: function(){
			$('#eWorkspace').accordion('resize');
		}
	,	center__onresize: function(){
			var centerWidth = pexLayout.cssWidth('center');
			$('#findGrid').setGridWidth(centerWidth-40);
			$('#promotionsGrid').setGridWidth(centerWidth-80);
			$('#revisionsGrid').setGridWidth(centerWidth-80);
			$('#signoffsGrid').setGridWidth(centerWidth-80);
			$('#childrenGrid').setGridWidth(centerWidth-60);
			$('#parentsGrid').setGridWidth(centerWidth-70);
		}
	});

	// prima riga tabs
	$('#cMenuTabs > ul').tabs();

	$('.wNavigation_find').click(function() {
		var rectype = $(this).attr('title');
		$('#cFind').load('/rectype/'+rectype+'/find');
		$("#cMenuTabs > ul").tabs('select',0);
	});

	// gestione history
	$.history.callback = function ( id, cursor ) {
		if (typeof(id) == 'undefined') {
			$("#cMenuTabs > ul").tabs('select',1);
		} else {
			$("#cMenuTabs > ul").tabs('select',2);
			$('#cRecord').load("/brecords/load_record_base",{id:id});
		}
	};
});