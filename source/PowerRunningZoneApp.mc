using Toybox.Application as App;

class PowerRunningZoneApp extends App.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new CircularZoneView() ];
        // return [ new PowerRunningZoneView() ];
    }

}