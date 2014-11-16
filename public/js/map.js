function loadScript() {
  var script = document.createElement('script');
  script.type = 'text/javascript';
  script.src = 'https://maps.googleapis.com/maps/api/js?v=3.exp&callback=initialize';
  document.body.appendChild(script);
  var navh = document.getElementById('navmenu').clientHeight;
  var footerh = document.getElementById('footer').clientHeight;
  document.getElementById('map-canvas').style.height = window.outerHeight - navh - footerh + "px";
}