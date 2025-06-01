using Toybox.Graphics;
using Toybox.WatchUi as ui;
using Toybox.System;
using Toybox.Math;
using Toybox.Activity as Act;


class CircularZoneView extends ui.DataField {
    
    var pe = new ZoneManagment();
    var zoneColors = [ Graphics.COLOR_LT_GRAY ,Graphics.COLOR_BLUE, Graphics.COLOR_GREEN, Graphics.COLOR_ORANGE, Graphics.COLOR_RED];
    var zoneThresholds = [ 50, 100, 150, 200, 250];
    var value = 125;
    var textBackgroundColor = Graphics.COLOR_TRANSPARENT;
    var textForegroundColor = Graphics.COLOR_BLACK;
    var currentPowerColor = Graphics.COLOR_BLACK;
    var lapPowerColor = Graphics.COLOR_DK_BLUE;

    function initialize() {
        DataField.initialize();
    }

    function onDraw(dc) {
        var screenWidth = dc.getWidth();
        var screenHeight = dc.getHeight();
        try{
            drawLargeScreen(screenWidth, screenHeight, dc,pe.GetPower(), pe.GetZone(), pe.GetLapZone());
        }catch(e){
            System.println("Error in drawLargeScreen: " + e);
        }
    }
    function compute(info){
        if (getBackgroundColor() == Graphics.COLOR_WHITE) { // updated condition
            textForegroundColor = Graphics.COLOR_BLACK;
            currentPowerColor = Graphics.COLOR_BLACK;
        } else {
            textForegroundColor = Graphics.COLOR_WHITE;
            currentPowerColor = Graphics.COLOR_WHITE;
        }
        pe.Update(info);
        value = pe.GetPower();
    }
    function onValueChanged(newValue) {
        value = newValue;
        // invalidate();
    }
    function onUpdate(dc) {
        onDraw(dc);
    }
    function onTimerStart(){
		pe.Start();
	}
	function onTimerStop(){
		pe.Stop();
	}
	function onTimerLap(){
        var info = Act.getActivityInfo();
        pe.LapComplete(info);
	}
	function onWorkoutStepComplete(){
        var info = Act.getActivityInfo();	
		pe.LapComplete(info);
	}
	

    function drawLargeScreen(screenWidth, screenHeight , dc, value, zone, lapPowerZone ) as Void {
        var centerX = screenWidth / 2;
        var centerY = screenHeight / 2;
        var lineThickness = 10;
        var lineWidth = 2;
        var lineOffset = 20;
        var radius = centerX < centerY ? centerX - lineThickness : centerY - lineThickness;
        var startAngle = 250.0;   // Start angle for the first color band
        var totalArc = 320.0; // Total arc for the gauge 

        // Draw color bands
        var zoneAngle = (totalArc / zoneColors.size());
        var targetPower = pe.GetWorkoutZone();
        for (var i = 0; i < zoneColors.size(); i++) {
            var startZoneAngle = startAngle - zoneAngle * i;
            if (startZoneAngle > 360.0) {
                startZoneAngle = startZoneAngle - 360.0;
            }else if (startZoneAngle < 0.0) {
                startZoneAngle = startZoneAngle + 360.0;
            }
            var endZoneAngle = startAngle - zoneAngle * (i + 1);
            if (endZoneAngle > 360.0) {
                endZoneAngle = endZoneAngle - 360.0;
            }else if (endZoneAngle < 0.0) {
                endZoneAngle = endZoneAngle + 360.0;
            }
            
            dc.setColor(zoneColors[i], zoneColors[i]);
            if (i + 1 == targetPower) {
                dc.setPenWidth(lineThickness * 2);
            } else {
                dc.setPenWidth(lineThickness);
            }
            dc.drawArc(centerX, centerY, radius, Graphics.ARC_CLOCKWISE, startZoneAngle, endZoneAngle); // Draw from end to start
        }
        
        // Draw Lap power indicator line
        if (lapPowerZone < 1) {
            lapPowerZone = 1;
        }
        var indicatorAngle = (startAngle - 140) + (lapPowerZone - 1) * zoneAngle; // Adjust for 0 degrees at 3 o'clock

        var lapPowerWidth = 3;
        if (Math.floor(lapPowerZone) == targetPower) {
            lapPowerWidth = 8;
        } else {
            lapPowerWidth = 3;
        }
        
        drawIndicatorLine(indicatorAngle, centerX, centerY, radius, 30, lapPowerColor, lapPowerWidth, dc);
        if (zone < 1) {
            zone = 1;
        }
        // Draw Current power indicator line
        indicatorAngle = (startAngle - 140) + (zone -1) * (totalArc / zoneColors.size()); // Adjust for 0 degrees at 3 o'clock
        
        var powerWidth = 3;
        if (Math.floor(zone) == targetPower) {
            powerWidth = 8;
        } else {
            powerWidth = 3;
        }
        drawIndicatorLine(indicatorAngle, centerX, centerY, radius, lineOffset, currentPowerColor, powerWidth, dc);
        var powerPosition = centerY - Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2;
        //draw icon
        var icon = null;
        if (getBackgroundColor() == Graphics.COLOR_WHITE) { // updated condition
            icon = ui.loadResource(Rez.Drawables.PowerIcon);
        } else {
            icon = ui.loadResource(Rez.Drawables.PowerIconWhite);
        }
        
        var iconWidth = icon.getWidth();
        // var iconHeight = icon.getHeight();
        var iconX = centerX - iconWidth / 2;
        var iconY = powerPosition - Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2 ;
        // var bitMapOptions = {"tintColor" => Graphics.COLOR_BLACK};
        dc.drawBitmap(iconX, iconY, icon);
        // Draw the value text
        if (Math.floor(zone).toNumber() > zoneColors.size() || zone.toNumber() < 1) {
            zone = zoneColors.size() - 1;
        }
        dc.setColor(zoneColors[Math.floor(zone).toNumber() - 1], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, powerPosition, Graphics.FONT_NUMBER_HOT, value.toLong().toString(), Graphics.TEXT_JUSTIFY_CENTER);
        
        var timeLeft = pe.GetTimeLeft();

        // Draw the time left text
        if (timeLeft == null) {
            return;
        }
        var timeLeftString = "";
        if (timeLeft % 60 < 10) {
            timeLeftString = Math.floor(timeLeft / 60).toString() + ":0" + (timeLeft % 60).toString() + " " + pe.GetWorkoutRepeatCount();
        } else {
            timeLeftString = Math.floor(timeLeft / 60).toString() + ":" + (timeLeft % 60).toString() + " " + pe.GetWorkoutRepeatCount();
        }
        var position = powerPosition + Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2 + 10 + Graphics.getFontHeight(Graphics.FONT_MEDIUM) / 2;
        var timeTextColor = getBackgroundColor() == Graphics.COLOR_WHITE ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE; // updated condition
        dc.setColor(timeTextColor, textBackgroundColor);
        dc.drawText(centerX, position, Graphics.FONT_MEDIUM, timeLeftString, Graphics.TEXT_JUSTIFY_CENTER);
        //Draw the Workout step intensity icon
        var stepType = pe.GetWorkoutStepIntensity();
        icon = getWorkoutIntensityIcon(stepType, getBackgroundColor()); // updated condition
        
        // Position intensity icon to the left of the time-left text
        iconWidth = icon.getWidth();
        var iconHeight = icon.getHeight();
        var timeTextWidth = dc.getTextWidthInPixels(timeLeftString, Graphics.FONT_MEDIUM);
        var timeTextHeight = dc.getFontHeight(Graphics.FONT_MEDIUM);
        var spacing = 5; // gap between icon and text
        iconX = centerX - timeTextWidth/2 - iconWidth - spacing;
        iconY = position + timeTextHeight/2 - iconHeight/2;
        dc.drawBitmap(iconX, iconY, icon);
        // Draw the heart rate text
        var heartRateZone = pe.GetHeartRateZone();
        var heartRatePosition = position + Graphics.getFontHeight(Graphics.FONT_MEDIUM) + 5;
        if (heartRateZone <= 0) {
            heartRateZone = 1;
        }
        dc.setColor(zoneColors[heartRateZone.toNumber() - 1], textBackgroundColor);
        dc.drawText(centerX, heartRatePosition, Graphics.FONT_MEDIUM, Act.getActivityInfo().currentHeartRate.toString(), Graphics.TEXT_JUSTIFY_CENTER);
        var heartRateTextWidth = dc.getTextWidthInPixels(Act.getActivityInfo().currentHeartRate.toString(), Graphics.FONT_MEDIUM);
        // Draw the heart rate icon
        var heartRateIcon = null;
        if (getBackgroundColor() == Graphics.COLOR_WHITE) { // updated condition
            heartRateIcon = ui.loadResource(Rez.Drawables.Heart);
        } else {
            heartRateIcon = ui.loadResource(Rez.Drawables.HeartWhite);
        }
        // var heartRateIconWidth = heartRateIcon.getWidth();
        var heartRateIconHeight = heartRateIcon.getHeight();
        var heartRateIconX = centerX + heartRateTextWidth / 2;
        var heartRateIconY = heartRatePosition + heartRateIconHeight / 2;
        dc.drawBitmap(heartRateIconX, heartRateIconY, heartRateIcon);
        
    }
    function drawIndicatorLine(indicatorAngle, centerX, centerY, radius, length, color, width, dc) as Void {
    // Draw the indicator line
        var indicatorX = centerX + radius * Math.cos(Math.toRadians(indicatorAngle)); 
        var indicatorY = centerY + radius * Math.sin(Math.toRadians(indicatorAngle)); 
        var startX = centerX + (radius - length) * Math.cos(Math.toRadians(indicatorAngle));
        var startY = centerY + (radius - length) * Math.sin(Math.toRadians(indicatorAngle)); 
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(width);
        dc.drawLine(startX, startY, indicatorX, indicatorY);
    }
    function getWorkoutIntensityIcon(stepType, backgroundColor) as ui.BitmapResource {
        if (backgroundColor == Graphics.COLOR_WHITE) { // updated condition
            if (stepType == Act.WORKOUT_INTENSITY_ACTIVE) {
            return ui.loadResource(Rez.Drawables.ActiveIcon);
        } else if (stepType == Act.WORKOUT_INTENSITY_RECOVERY || stepType == Act.WORKOUT_INTENSITY_REST) {
            return ui.loadResource(Rez.Drawables.RecoveryIcon);
        } else if (stepType == Act.WORKOUT_INTENSITY_WARMUP) {
            return ui.loadResource(Rez.Drawables.WarmupIcon);
        } else if (stepType == Act.WORKOUT_INTENSITY_COOLDOWN) {
            return ui.loadResource(Rez.Drawables.CooldownIcon);
        } else {
            return ui.loadResource(Rez.Drawables.ActiveIcon); // Default to active icon if no step type is found
        }
        } else {
            if (stepType == Act.WORKOUT_INTENSITY_ACTIVE) {
                return ui.loadResource(Rez.Drawables.ActiveIconWhite);
            } else if (stepType == Act.WORKOUT_INTENSITY_RECOVERY || stepType == Act.WORKOUT_INTENSITY_REST) {
                return ui.loadResource(Rez.Drawables.RecoveryIconWhite);
            } else if (stepType == Act.WORKOUT_INTENSITY_WARMUP) {
                return ui.loadResource(Rez.Drawables.WarmupIconWhite);
            } else if (stepType == Act.WORKOUT_INTENSITY_COOLDOWN) {
                return ui.loadResource(Rez.Drawables.CooldownIconWhite);
            } else {
                return ui.loadResource(Rez.Drawables.ActiveIconWhite); // Default to active icon if no step type is found
            }
        }
    }
}