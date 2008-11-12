;(function($){
/*
**
 * jqGrid extension for manipulating Grid Data
 * Tony Tomov tony@trirand.com
 * http://trirand.com/blog/ 
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
**/ 

$.fn.extend({
// Editing
	editRow : function(rowid,keys,oneditfunc,succesfunc, url, extraparam, aftersavefunc,errorfunc) {
		return this.each(function(){
		var $t = this, nm, tmp, editable, cnt=0, focus=null, svr=[];
		if (!$t.grid ) return;
		var sz, ml,hc;
		if( !$t.p.multiselect ) {
			editable = $('#'+rowid,$t.grid.bDiv).attr("editable") || "0";
			if (editable === "0") {
				$('#'+rowid+' td',$t.grid.bDiv).each( function(i) {
					nm = $t.p.colModel[i].name;
					hc = $t.p.colModel[i].hidden===true ? true : false
					tmp = $(this).html().replace(/\&nbsp\;/ig,'');
					svr[nm]=tmp;
					if ( nm !== 'cb' && nm !== 'subgrid' && $t.p.colModel[i].editable===true && !hc) {
						if(focus===null) focus = i;
						$(this).html("");
						var opt = $.extend($t.p.colModel[i].editoptions || {} ,{id:rowid+"_"+nm,name:nm});
						if(!$t.p.colModel[i].edittype) $t.p.colModel[i].edittype = "text";
						var elc = createEl($t.p.colModel[i].edittype,opt,tmp);
						$(elc).addClass("editable");
						$(this).append(elc);						
						cnt++;
					}
				});
				if(cnt > 0) {
					svr['id'] = rowid; $t.p.savedRow.push(svr);
					$('#'+rowid,$t.grid.bDiv).attr("editable","1");
					$('#'+rowid+" td:eq("+focus+") input",$t.grid.bDiv).focus();
					if(keys===true) {
						$('#'+rowid,$t.grid.bDiv).bind("keydown",function(e) {
							if (e.keyCode === 27) $($t).restoreRow(rowid);
							if (e.keyCode === 13) $($t).saveRow(rowid,succesfunc, url, extraparam, aftersavefunc,errorfunc);
							e.stopPropagation();
						});
					}
					if( typeof oneditfunc === "function") oneditfunc(rowid);
				}
			}
		}
		function createEl(eltype,options,vl)
		{
			var elem = "";
			switch (eltype)
			{
				case "textarea" :
					elem = document.createElement("textarea");
					if (!options.rows) options.rows = 1;
					$(elem).attr(options);
					elem.innerHTML = vl;
					break;
				case "checkbox" :
					elem = document.createElement("input");
					elem.type = "checkbox";
					$(elem).attr({id:options.id,name:options.name});
                    if( !options.value) {
                        if(vl=='1') {
                            elem.checked=true;
                            elem.defaultChecked=true;
                        } else {
                            elem.checked=false;
                        }
                    } else if(vl == options.value.split(":")[0]) {
						elem.checked=true;
						elem.defaultChecked=true;
                    }
					break;
				case "select" :
					var so = options.value.split(";"),sv, ov;
					elem = document.createElement("select");
					$(elem).attr({id:options.id,name:options.name});
					for(var i=0; i<so.length;i++){
						sv = so[i].split(":");
						ov = document.createElement("option");
						$(ov).val(sv[0]).text(sv[1]);
						if (sv[1]==vl) ov.selected ="selected";
						elem.appendChild(ov);
					}
					break;
				case "text" :
					elem = document.createElement("input");
					elem.type = "text";
					if (!options.size) options.size = vl.length || 10;
					$(elem).attr(options);
					elem.value = vl;
					break;
				case "image" :
					elem = document.createElement("input");
					elem.type = "image";
					$(elem).attr(options);
					break;
			}
			return elem;
		}
		});
	},

	saveRow : function(rowid, succesfunc, url, extraparam, aftersavefunc,errorfunc) {
		return this.each(function(){
		var $t = this, nm, tmp={}, tmp2, editable, fr;
		if (!$t.grid ) return;
		editable = $('#'+rowid,$t.grid.bDiv).attr("editable");
		url = url ? url : $t.p.editurl;
		if (editable==="1" && url) {
			$('#'+rowid+" td",$t.grid.bDiv).each(function(i) {
				nm = $t.p.colModel[i].name;
				if ( nm !== 'cb' && nm !== 'subgrid' && $t.p.colModel[i].editable===true) {
					if( $t.p.colModel[i].hidden===true) tmp[nm] = $(this).html();
					else if( $t.p.colModel[i].edittype==='checkbox') tmp[nm]=  $("input",this).attr("checked") ? 1 : 0;
					else tmp[nm]= $("input, select>option:selected, textarea",this).val();
				}
			});
			if(tmp) { tmp["id"] = rowid; if(extraparam) $.extend(tmp,extraparam);}
			if(!$t.grid.hDiv.loading) {
				$t.grid.hDiv.loading = true;
				$("div.loading",$t.grid.hDiv).fadeIn("fast");
				$.ajax({url:url,
					data: tmp,
					type: "POST",
					complete: function(res,stat){
						if (stat === "success"){
							var ret;
							if( typeof succesfunc === "function") ret = succesfunc(res);
							else ret = true;
							if (ret===true) {
								$('#'+rowid+" td",$t.grid.bDiv).each(function(i) {
									nm = $t.p.colModel[i].name;
									if ( nm !== 'cb' && nm !== 'subgrid' && $t.p.colModel[i].editable===true) {
										switch ($t.p.colModel[i].edittype) {
											case "select":
												tmp2 = $("select>option:selected", this).text();
												break;
											case "checkbox":
												var cbv = $t.p.colModel[i].editoptions.value.split(":") || ["Yes","No"];
												tmp2 = $("input",this).attr("checked") ? cbv[0] : cbv[1];
												break;
											case "text":
											case "textarea":
												tmp2 = $("input, textarea", this).val();
												break;
										}
										$(this).empty();
										$(this).html(tmp2 || "&nbsp;");
									}
								});
								$('#'+rowid,$t.grid.bDiv).attr("editable","0");
								for( var k=0;k<$t.p.savedRow.length;k++) {
									if( $t.p.savedRow[k].id===rowid) {fr = k; break;}
								};
								if(fr >= 0) $t.p.savedRow.splice(fr,1);
								if( typeof aftersavefunc === "function") aftersavefunc(rowid,res);
							} else $($t).restoreRow(rowid);
						}
					},
					error:function(res,stat){
						if(typeof errorfunc == "function") {
							errorfunc(res,stat)
						} else {
							alert("Error Row: "+rowid+" Result: " +res.status+":"+res.statusText+" Status: "+stat);
						}
					}
				});
				$t.grid.hDiv.loading = false;
				$("div.loading",$t.grid.hDiv).fadeOut("fast");
				$("#"+rowid,$t.grid.bDiv).unbind("keydown");
			}
		}
		});
	},

	restoreRow : function(rowid) {
		return this.each(function(){
			var $t= this, nm, fr;
			if (!$t.grid ) return;
			for( var k=0;k<$t.p.savedRow.length;k++) {
				if( $t.p.savedRow[k].id===rowid) {fr = k; break;}
			};
			if(fr >= 0) {
				$('#'+rowid+" td",$t.grid.bDiv).each(function(i) {
					nm = $t.p.colModel[i].name;
					if ( nm !== 'cb' && nm !== 'subgrid') {
						$(this).empty()
						$(this).html($t.p.savedRow[fr][nm] || "&nbsp;");
					}
				});
				$('#'+rowid,$t.grid.bDiv).attr("editable","0");		
				$t.p.savedRow.splice(fr,1);
			}
		});
	}
/// end editing
});
})(jQuery);