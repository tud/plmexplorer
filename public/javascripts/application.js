var pexLayout;

$(function() {
	// fix for jQuery
	$.ajaxSetup({ 
		'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript");}
	});
	
	$.jgrid.defaults = $.extend($.jgrid.defaults,{loadui:"enable"});

	// UI.layout
	pexLayout = $('body').layout({
		applyDefaultStyles: true
	,	north__size: 110
	,	north__spacing_open: 3
	,	west__spacing_open: 3
	,	east__spacing_open: 3
	,	south__spacing_open: 0
	,	west__showOverflowOnHover: true
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
	$('#cMenuTabs').tabs();

	// gestione tab find
	$('.wNavigation_find').click(function() {
		var rectype = $(this).attr('href');
		$('#cFind').load('/rectype/'+rectype+'/find');
		$("#cMenuTabs").tabs('select',0);
		return false;
	});
	
	// gestione tab new
	$('.wNavigation_new').click(function() {
		var rectype = $(this).attr('href');
		$('#dialog_new_modify').load('/rectype/'+rectype+'/new');
		return false;
	});
	
	// gestione tab report
	$('.wNavigation_report').click(function() {
		var reportname = $(this).attr('href');
		$('#cReport').load('/reports/'+reportname);
		$("#cMenuTabs").tabs('select',3);
		return false;
	});

	// gestione history
	$.history._cache = 'blank.html';
	$.history.callback = function ( rec_id, cursor ) {
		if (typeof(rec_id) == 'undefined') {
			$("#cMenuTabs").tabs('select',1);
		} else {
			$("#cMenuTabs").tabs('select',2);
			$('#cRecord').load("/brecords/load_record_base",{id: rec_id});
		}
	};
});
