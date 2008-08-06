jQuery(document).ready(function(){
	jQuery('#topsearch').corner("20px top");
	jQuery('#bottomsearch').corner("20px bottom");
	jQuery('#header').corner("20px");
	jQuery('#content').corner("20px");
	jQuery('#footer').corner("10px");
	
	jQuery('img[@src$=png]').ifixpng();
});