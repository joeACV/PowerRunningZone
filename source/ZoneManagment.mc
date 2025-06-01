using Toybox.System as Sys;
using Toybox.Application as App;
using Toybox.Activity as Act;
using Toybox.Math as Math;
using Toybox.Lang as Lang;
using Toybox.UserProfile as UserProfile;


class ZoneManagment
{
    enum
    {
        STOPPED,
        PAUSED,
        RUNNING
    }
    var pe = new RunningPowerEfficiency();
    var powerEff = 0;
    var lapPower = 0.0;
    var lapTime = 0;
    var prevLapPower = 0.0;
    var lapStartTime = 0;
    var lastLapPower = 0.0;
    var prevLapPowerTime = 0.0;
    var lapStepCountStart = 0;
    hidden var mTimerState = STOPPED;
	var label = "Run Power";
    var zoneLow = [0, 0, 50, 100, 150, 0];
    var zoneHigh = [0, 50, 100, 150, 350, 1000];
	var alertZoneChange = false;
	var vibrateZoneChange = false;
	var lapAlertZone = false;
    hidden var prevZone = 0.0;
    hidden var currentPower = 0.0;
	var currentPowerZone = 0.0;
	hidden var powerZone = 0.0;
	hidden var currentZoneCount =0;
	hidden var vibeProf = [new Attention.VibeProfile(50,1000),
							new Attention.VibeProfile(0,2000)];
	hidden var vibrateZoneProfile = 
               [
           new Attention.VibeProfile( 100, 250 ),
           new Attention.VibeProfile(  0, 250 ),
           new Attention.VibeProfile(  100, 250 ),
           new Attention.VibeProfile(  0, 250 ),
               ];
    function Update(info){
        // See Activity.Info in the documentation for available information.
        var lapPowerZone = 0.0;
        var prevLapZone = 0.0;
        powerEff = pe.compute(info);
        if (zoneLow[5]==0){
        	setZones();
        }
        
        if (info.timerTime != null){
            lapTime = info.timerTime - lapStartTime;
        }else{
            lapTime = 0;
        }
       	prevLapPower = lapPower;
        currentPower = info.currentPower;
    	prevLapZone = getZone(prevLapPower);
    	if (lapTime > prevLapPowerTime){
	        lapPower = calculateAvgPower(lapTime,prevLapPowerTime,lapPower,info.currentPower);
	    }
        prevLapPowerTime = lapTime;
    }
    function GetPower(){
        if (currentPower == null){
            currentPower = 0.0;
        }
        return currentPower;
    }
    function calculateAvgPower(time, prevTime, avg, power){
        // time is total time in milliseconds 
        // avg is current average over that time
        // power is new power
        // returns new average
        var newAvg = 0.0;
        var totalTimeInSeconds = time.toFloat() / 1000.0;
        var timeDiffInSeconds = (time.toFloat() - prevTime.toFloat()) / 1000.0;

        if (totalTimeInSeconds > 0){
            if (power != null){
                newAvg = (avg * (prevTime.toFloat() / 1000.0) + power * timeDiffInSeconds) / totalTimeInSeconds;
            } else {
                newAvg = (avg * (prevTime.toFloat() / 1000.0) + avg * timeDiffInSeconds) / totalTimeInSeconds;
            }
        } else {
            newAvg = power;
        }
        return newAvg;
}
    function GetWorkoutZone(){
        
        var step = Act.getCurrentWorkoutStep();
        if (step == null) {
            return null;
        }
        var notes = step.notes;
        if (notes == null) {
            return null;
        }
        var powerZone = 0.0;
        var powerZoneIndex = notes.find("powerzone=");
        if (powerZoneIndex != null) {
            var powerZoneString = notes.substring(powerZoneIndex + 10, notes.length());
            // Convert the power zone string to a float
            powerZone = powerZoneString.toFloat();
            // Use the powerZone variable as needed
        }
        return powerZone;
    }
    function GetTimeLeft(){
        var sysInfo = Sys.getDeviceSettings();
        if (sysInfo.monkeyVersion[0] < 3 || (sysInfo.monkeyVersion[0] == 3 && sysInfo.monkeyVersion[1] < 2))  {
            return lapTime / 1000;
        }
        var workoutStepInfo = Act.getCurrentWorkoutStep();
        if (workoutStepInfo == null) {
            return lapTime / 1000;
        }
        var step = workoutStepInfo.step;
        if (step == null) {
            return lapTime / 1000;
        }
        if (step.durationType != Act.WORKOUT_STEP_DURATION_TIME) {
            return lapTime / 1000;
        }
        var timeLeft = step.durationValue - lapTime / 1000;
        return timeLeft.toLong();
    }
    function GetWorkoutStepIntensity(){
        var step = Act.getCurrentWorkoutStep();
        if (step == null) {
            return null;
        }
        return step.intensity;
    }
    function GetWorkoutRepeatCount(){
        var step = Act.getCurrentWorkoutStep();
         if (step == null) {
            return "";
        }
        var intervalStep = step.step;
        if (intervalStep == null) {
            return "";
        }
        if (!(intervalStep has :repetitionNumber)){
            return "";
        }
        var totalReps = intervalStep.repetitionNumber;
        if (totalReps == null || totalReps <= 0) {
            return "";
        }
        return totalReps.toString();
    }
    function getZone(power) {
        var zone = 0.0;
        for (var i = 1; i < zoneLow.size(); i++) {
            if (power >= zoneLow[i] && power < zoneHigh[i]) {
                zone = i + (power - zoneLow[i].toFloat()) / (zoneHigh[i].toFloat() - zoneLow[i].toFloat());
            }
        }
        if (power >= zoneHigh[zoneLow.size() - 1]) {
            zone = zoneLow.size() - 1 + 0.999999;
        }
        return zone;
    }
    //Retrurns the current zone
    function GetZone(){
        var power = 0.0;
        var zone = 0.0;
        if (GetPower() != null) {
            power = GetPower();
            zone = getZone(power);
        }
        return zone;
    }
    function GetLapZone(){
        var zone = 0.0;
        if (lapPower != null){
            zone = getZone(lapPower);
        }
        return zone;
    }
    function setZones(){
    //Set zones from properties
        var properties = App.Properties;
    	alertZoneChange = properties.getValue("alert_zone_change_p");
    	vibrateZoneChange = properties.getValue("vibrate_zone_change_p");
      	zoneLow[1] = properties.getValue("zone1_low_p");
      	if (zoneLow[1] == 0.0){
      		zoneLow[1] = 1.0;
      	}
      	zoneLow[2] = properties.getValue("zone2_low_p");
      	zoneLow[3] = properties.getValue("zone3_low_p");
      	zoneLow[4] = properties.getValue("zone4_low_p");
      	zoneLow[5] = properties.getValue("zone5_low_p");
        zoneHigh[1] = zoneLow[2];
        zoneHigh[2] = zoneLow[3];
        zoneHigh[3] = zoneLow[4];
        zoneHigh[4] = zoneLow[5];
        zoneHigh[5] = zoneLow[5] + zoneLow[5] * 0.2;
        
    }
    function LapComplete(info){
        //Set last lap power
        //Reset lap time and lappower
        if (lastLapPower > 0){
            lastLapPower = lapPower;
        }
        lapStartTime = info.timerTime;
        lapPower = 0.0;
        lapStepCountStart = lapStepCountStart + 1;
    }
    function Start(){
        //Start the timer
       setZones();
       mTimerState = RUNNING;
    }
    function Stop(){
        //Stop the timer
        mTimerState = STOPPED;
    }
    function GetHeartRateZone(){
        var heartRate = Act.getActivityInfo().currentHeartRate;
        var zones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());
        if (zones == null || heartRate == null) {
            return null;
        }
        for (var i = 1; i < zones.size(); i++) {
            if (heartRate <= zones[i]) {
                return i;
            }
        }
        return null;
    }
}