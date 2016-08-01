/*
  Ring.js - Google Analytics Component

  Sets up Google Analytics and tracks the immediate pageview along with any
  pageviews that occur over a WebSocket connection with Navigator. To use,
  attach the component to the <body> tag and configure the trackingId:

    <body data-ui="ga" data-config="trackingId: yourTrackingIdHere">

  It will automatically ignore pageviews that occur locally.
*/

pw.component.register('ga', function (view, config) {
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
  ga('create', config.trackingId, 'auto');

  this.track = function (uri) {
    if (document.domain.indexOf('local') != -1) {
      return;
    }

    ga('send', 'pageview', uri);
  };

  this.listen('navigator:change', function (payload) {
    this.track(payload.uri);
  });

  // track the current pageview
  this.track(location.pathname);
});
