var alert_title='Input Restriction';

function limitTextarea(el,maxLines,maxChar){
	
	if(!el.x){
		el.x  =uniqueInt();
		el.onblur = function(){
			clearInterval(window['int'+el.x])
		}
	}
	window['int'+el.x] = setInterval(function(){
		var lines=el.value.replace(/\r/g,'').split('\n'),
		i=lines.length,
		lines_removed,
		char_removed;
		if(maxLines&&i>maxLines){
			alert('You can not enter\nmore than '+maxLines+' lines');
			lines=lines.slice(0,maxLines);
			lines_removed=1
		}
		if(maxChar){
			i=lines.length;
			while(i-->0)if(lines[i].length>maxChar){
				lines[i]=lines[i].slice(0,maxChar);
				char_removed=1
			}
			if(char_removed)alert('You can not enter more\nthan '+maxChar+' characters per line')
		}
		if(char_removed||lines_removed)el.value=lines.join('\n')
		},50);
	}

	function uniqueInt(){
		var num,maxNum=100000;
		if(!uniqueInt.a||maxNum<=uniqueInt.a.length)uniqueInt.a=[];
		do num=Math.ceil(Math.random()*maxNum);
		while(uniqueInt.a.hasMember(num))
		uniqueInt.a[uniqueInt.a.length]=num;
		return num
	}

	Array.prototype.hasMember=function(testItem){
		var i=this.length;
		while(i-->0)if(testItem==this[i])return 1;
		return 0
	}

	function set_ie_alert(){
		window.alert=function(msg_str){
			vb_alert(msg_str)
		}
	}