function archivo(evt) {
	var files = evt.target.files;

	for (var i = 0, f; f = files[i]; i++) {
		if (!f.type.match('image.*')) {
			continue;
		}
		var reader = new FileReader(), urlBase64;
		reader.onload = (function(theFile) {
			return function(e) {
				$('#list').html(['<img class="thumbnail" src="', e.target.result,'" title="', escape(theFile.name), '"/>'].join(''));
			};
		})(f);
	reader.readAsDataURL(f);
	}
	$('#save').show();
	$('#cancel').show();
}
if(document.getElementById('file') != undefined)
	document.getElementById('file').addEventListener('change', archivo, false);

function save(){
	$('#loading').show();
	document.getElementById("saveform").submit();
}
