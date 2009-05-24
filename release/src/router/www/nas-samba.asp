<!DOCTYPE HTML PUBLIC '-//W3C//DTD HTML 4.0//EN'>
<!--
	Tomato GUI
	Samba Server - !!TB

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv='content-type' content='text/html;charset=utf-8'>
<meta name='robots' content='noindex,nofollow'>
<title>[<% ident(); %>] NAS: File Sharing</title>
<link rel='stylesheet' type='text/css' href='tomato.css'>
<link rel='stylesheet' type='text/css' href='color.css'>
<script type='text/javascript' src='tomato.js'></script>

<!-- / / / -->
<style tyle='text/css'>
#ss-grid {
	width: 99%;
}
#ss-grid .co1, #ss-grid .co2, #ss-grid .co3 {
	width: 25%;
}
#ss-grid .co4 {
	width: 16%;
}
#ss-grid .co5 {
	width: 9%;
}
</style>
<style type='text/css'>
textarea {
	width: 98%;
	height: 6em;
}
</style>

<script type='text/javascript' src='debug.js'></script>

<script type='text/javascript'>

//	<% nvram("smbd_enable,smbd_wgroup,smbd_cpage,smbd_custom,smbd_loglevel,smbd_shares"); %>

function v_nodelim(e, quiet, name)
{
	e.value = e.value.trim().replace(/>/g, '_');
	if (e.value.indexOf('<') != -1) {
		ferror.set(e, 'Invalid ' + name, quiet);
		return 0;
	}
	ferror.clear(e);
	return 1;
}

var ssg = new TomatoGrid();

ssg.exist = function(f, v)
{
	var data = this.getAllData();
	for (var i = 0; i < data.length; ++i) {
		if (data[i][f] == v) return true;
	}
	return false;
}

ssg.existName = function(name)
{
	return this.exist(0, name);
}

ssg.sortCompare = function(a, b) {
	var col = this.sortColumn;
	var da = a.getRowData();
	var db = b.getRowData();
	var r = cmpText(da[col], db[col]);
	return this.sortAscending ? r : -r;
}

ssg.dataToView = function(data) {
	return [data[0], data[1], data[2], ['Read Only', 'Read/Write'][data[3]], ['No', 'Yes'][data[4]]];
}

ssg.fieldValuesToData = function(row) {
	var f = fields.getAll(row);
	return [f[0].value, f[1].value, f[2].value, f[3].value, f[4].value];
}

ssg.verifyFields = function(row, quiet)
{
	var f, s;
	f = fields.getAll(row);

	s = f[0].value.trim().replace(/\s+/g, ' ');
	if (s.length > 0) {
		if (s.search(/^[ a-zA-Z0-9_\-\$]+$/) == -1) {
			ferror.set(f[0], 'Invalid share name. Only characters "$ A-Z 0-9 - _" and spaces are allowed.', quiet);
			return 0;
		}
		if (this.existName(s)) {
			ferror.set(f[0], 'Duplicate share name.', quiet);
			return 0;
		}
		f[0].value = s;
	}
	else {
		ferror.set(f[0], 'Empty share name is not allowed.', quiet);
		return 0;
	}

	if ((!v_nodelim(f[1], quiet, 'Directory')) || (!v_nodelim(f[2], quiet, 'Description')))
		return 0;

	if (f[1].value.length <= 0) {
		ferror.set(f[1], 'Directory must not be empty.', quiet);
		return 0;
	}

	return 1;
}

ssg.resetNewEditor = function()
{
	var f;

	f = fields.getAll(this.newEditor);
	ferror.clearAll(f);

	f[0].value = '';
	f[1].value = '';
	f[2].value = '';
	f[3].selectedIndex = 0;
	f[4].selectedIndex = 0;
}

ssg.setup = function()
{
	this.init('ss-grid', 'sort', 50, [
		{ type: 'text', maxlen: 32 },
		{ type: 'text', maxlen: 256 },
		{ type: 'text', maxlen: 64 },
		{ type: 'select', options: [[0, 'Read Only'],[1, 'Read/Write']] },
		{ type: 'select', options: [[0, 'No'],[1, 'Yes']] }
	]);
	this.headerSet(['Share Name', 'Directory', 'Description', 'Access Level', 'Hidden']);

	var s = nvram.smbd_shares.split('>');
	for (var i = 0; i < s.length; ++i) {
		var t = s[i].split('<');
		if (t.length == 5) {
			this.insertData(-1, t);
		}
	}

	this.sort(0);
	this.showNewEditor();
	this.resetNewEditor();
}

function verifyFields(focused, quiet)
{
	var a;

	a = !E('_f_smbd_enable').checked;

	E('_smbd_wgroup').disabled = a;
	E('_smbd_cpage').disabled = a;
	E('_smbd_custom').disabled = a;
	E('_smbd_loglevel').disabled = a;

	if (!a) {
		if (!v_range('_smbd_loglevel', quiet, 0, 100)) return 0;
		if (!v_length('_smbd_custom', quiet, 0, 2048)) return 0;
		if (!v_length('_smbd_wgroup', quiet, 1, 20)) return 0;
	}

	return 1;
}

function save()
{
	if (ssg.isEditing()) return;
	if (!verifyFields(null, 0)) return;

	var fom = E('_fom');

	var data = ssg.getAllData();
	var r = [];
	for (var i = 0; i < data.length; ++i) r.push(data[i].join('<'));
	fom.smbd_shares.value = r.join('>');

	fom.smbd_enable.value = E('_f_smbd_enable').checked ? 1 : 0;

	form.submit(fom, 1);
}
</script>

</head>
<body>
<form id='_fom' method='post' action='tomato.cgi'>
<table id='container' cellspacing=0>
<tr><td colspan=2 id='header'>
	<div class='title'>Tomato</div>
	<div class='version'>Version <% version(); %></div>
</td></tr>
<tr id='body'><td id='navi'><script type='text/javascript'>navi()</script></td>
<td id='content'>
<div id='ident'><% ident(); %></div>

<!-- / / / -->

<input type='hidden' name='_nextpage' value='nas-samba.asp'>
<input type='hidden' name='_service' value='samba-restart'>

<input type='hidden' name='smbd_enable'>
<input type='hidden' name='smbd_shares'>

<div class='section-title'>Samba File Sharing</div>
<div class='section'>
<script type='text/javascript'>
createFieldTable('', [
	{ title: 'Enable File Sharing', name: 'f_smbd_enable', type: 'checkbox',
		value: nvram.smbd_enable == 1 },
	null,
	{ title: 'Workgroup Name', name: 'smbd_wgroup', type: 'text', maxlen: 20, size: 32,
		value: nvram.smbd_wgroup },
	{ title: 'Client Codepage', name: 'smbd_cpage', type: 'select',
		options: [['', 'Unspecified'],['437', '437 (United States, Canada)'],['850', '850 (Western Europe)'],['852', '852 (Central / Eastern Europe)'],['866', '866 (Cyrillic / Russian)']],
		suffix: ' <small> (start cmd.exe and type chcp to see the current code page)</small>',
		value: nvram.smbd_cpage },
	{ title: 'Samba<br>Custom Configuration', name: 'smbd_custom', type: 'textarea', value: nvram.smbd_custom },
	{ title: 'Samba Log Level', name: 'smbd_loglevel', type: 'select',
		options: [['0', '0'],['1', '1'],['2', '2'],['3', '3'],['4', '4'],['5', '5'],['6', '6'],['7', '7'],['8', '8'],['9', '9'],['10', '10'],['50', '50'],['100', '100']],
		value: nvram.smbd_loglevel }
]);
</script>
</div>
<br>

<div class='section-title'>Network Shares List</div>
<div class='section'>
	<table class='tomato-grid' cellspacing=1 id='ss-grid'></table>
	<script type='text/javascript'>ssg.setup();</script>
<br>
<small>When no shares are specified, <i>/mnt</i> directory is shared in Read Only mode.</small>
</div>

<!-- / / / -->

</td></tr>
<tr><td id='footer' colspan=2>
	<span id='footer-msg'></span>
	<input type='button' value='Save' id='save-button' onclick='save()'>
	<input type='button' value='Cancel' id='cancel-button' onclick='javascript:reloadPage();'>
</td></tr>
</table>
</form>
<script type='text/javascript'>verifyFields(null, 1);</script>
</body>
</html>
