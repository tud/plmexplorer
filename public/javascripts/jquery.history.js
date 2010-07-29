/*
**  jhistory 0.6 - jQuery plugin allowing simple non-intrusive browser history
**  author: Jim Palmer; released under MIT license
**    collage of ideas from Taku Sano, Mikage Sawatari, david bloom and Klaus Hartl
**  CONFIG -- place in your document.ready function two possible config settings:
**    $.history._cache = 'cache.html'; // REQUIRED - location to your cache response handler (static flat files prefered)
**    $.history.stack = {<old object>}; // OPTIONAL - prefill this with previously saved history stack (i.e. saved with session)
*/
(function($){$.history=function(store){if(!$.history.stack)$.history.stack={};if($.history._locked)return false;$.history.cursor=(new Date()).getTime().toString();$.history.stack[$.history.cursor]=$.extend(true,{},store);if($.browser.msie)
$('.__historyFrame')[0].contentWindow.document.open().close();if($.browser.safari)
$('.__historyFrame').contents()[0].location.href=$('.__historyFrame').contents()[0].location.href.split('?')[0]+'?'+$.history.cursor+'#'+$.history.cursor;else
$('.__historyFrame').contents()[0].location.hash='#'+$.history.cursor;}
$.history.init=function(){$("body").append('<iframe class="__historyFrame" src="'+$.history._cache+'" style="border:0px; width:0px; height:0px; visibility:hidden;" />');$.history.intervalId=$.history.intervalId||window.setInterval(function(){var cursor=$(".__historyFrame").contents().attr($.browser.msie?'URL':'location').toString().split('#')[1];$('#__historyDebug').html('"'+$.history.cursor+'" vs "'+cursor+'" - '+(new Date()).toString());if(parseFloat($.history.cursor)>=0&&parseFloat($.history.cursor)!=(parseFloat(cursor)||0)){$.history.cursor=parseFloat(cursor)||0;if(typeof($.history.callback)=='function'){$.history._locked=true;$.history.callback($.history.stack[cursor],cursor);$.history._locked=false;}}},150);}
$($.history.init);})(jQuery);