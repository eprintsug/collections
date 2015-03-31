document.observe("dom:loaded", function() {
	$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
});

document.observe("dom:loaded", function() {
	$$("input.ep_atc_checkbox").each(function(el){el.observe("click", checkbox_atc_Click );});
});

function checkboxClick(e){
	if(this.checked == true){
		$A(document.getElementsByName(this.name)).each(function(el){el.checked=true;});

		var current_time = new Date().getTime();
		var targeteprint = this.name.replace(/_add_/,"");

		var url = eprints_http_cgiroot + "/users/collection_select?action=add&collection_eprintid="+$("collection_eprintid").value + "&target_eprintid=" + targeteprint + "&fieldname=" + $("fieldname").value + "&time=" + current_time;

		new Ajax.Request(url, {
			method: 'get',
			onSuccess: function(transport) {
				$("selected_eprints").replace(transport.responseText);
				$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
			}
		});


	}else{
		$A(document.getElementsByName(this.name)).each(function(el){el.checked=false;});
		
		var current_time = new Date().getTime();
		var targeteprint = this.name.replace(/_add_/,"");
		var url = eprints_http_cgiroot + "/users/collection_select?action=remove&collection_eprintid="+$("collection_eprintid").value + "&target_eprintid=" + targeteprint + "&fieldname=" + $("fieldname").value + "&time=" + current_time;
	
		new Ajax.Request(url, {
			method: 'get',
			onSuccess: function(transport) {
				$("selected_eprints").replace(transport.responseText);
				$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
			}
		});
		
	}
}

function checkbox_atc_Click(e){
	if(this.checked == true){
		$A(document.getElementsByName(this.name)).each(function(el){el.checked=true;});

		var current_time = new Date().getTime();
		var targeteprint = this.name.replace(/_add_/,"");

		var url = eprints_http_cgiroot + "/users/add_to_collection?action=add&target_eprintid="+$("collection_eprintid").value + "&collection_eprintid=" + targeteprint + "&fieldname=" + $("fieldname").value + "&time=" + current_time;
		new Ajax.Request(url, {
			method: 'get',
			onSuccess: function(transport) {
				$("selected_eprints").replace(transport.responseText);
				$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
			}
		});

	}else{
		$A(document.getElementsByName(this.name)).each(function(el){el.checked=false;});
		
		var current_time = new Date().getTime();
		var targeteprint = this.name.replace(/_add_/,"");
		var url = eprints_http_cgiroot + "/users/add_to_collection?action=remove&target_eprintid="+$("collection_eprintid").value + "&collection_eprintid=" + targeteprint + "&fieldname=" + $("fieldname").value + "&time=" + current_time;

		new Ajax.Request(url, {
			method: 'get',
			onSuccess: function(transport) {
				$("selected_eprints").replace(transport.responseText);
				$$("input.ep_cs_checkbox").each(function(el){el.observe("click", checkboxClick );});
			}
		});
	}
}
