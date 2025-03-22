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
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            textForegroundColor = Graphics.COLOR_WHITE;
            currentPowerColor = Graphics.COLOR_WHITE;
        } else {
            textForegroundColor = Graphics.COLOR_BLACK;
            currentPowerColor = Graphics.COLOR_BLACK;
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
        var indicatorAngle = (startAngle - 140) + (lapPowerZone -1) * (totalArc / zoneColors.size()); // Adjust for 0 degrees at 3 o'clock
        var lapPowerWidth = 3;
        if (lapPowerZone == targetPower) {
            lapPowerWidth = 6;
        } else {
            lapPowerWidth = 3;
        }
        drawIndicatorLine(indicatorAngle, centerX, centerY, radius, 30, lapPowerColor, lapPowerWidth, dc);

        // Draw Current power indicator line
        indicatorAngle = (startAngle - 140) + (zone -1) * (totalArc / zoneColors.size()); // Adjust for 0 degrees at 3 o'clock
        drawIndicatorLine(indicatorAngle, centerX, centerY, radius, lineOffset, currentPowerColor, 2, dc);
        var powerPosition = centerY - Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2;
        //draw icon
        var icon = null;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            icon = ui.loadResource(Rez.Drawables.PowerIconWhite);
        } else {
            icon = ui.loadResource(Rez.Drawables.PowerIcon);
        }
        
        var iconWidth = icon.getWidth();
        var iconHeight = icon.getHeight();
        var iconX = centerX - iconWidth / 2;
        var iconY = powerPosition - Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2 ;
        var bitMapOptions = {"tintColor" => Graphics.COLOR_BLACK};
        dc.drawBitmap(iconX, iconY, icon);
        // Draw the value text
        if (zone.toNumber() >= zoneColors.size() || zone.toNumber() < 1) {
            zone = zoneColors.size() - 1;
        }
        dc.setColor(zoneColors[zone.toNumber() - 1], Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, powerPosition, Graphics.FONT_NUMBER_HOT, value.toLong().toString(), Graphics.TEXT_JUSTIFY_CENTER);
        var timeLeft = pe.GetTimeLeft();

        // Draw the time left text
        if (timeLeft == null) {
            return;
        }
        var timeLeftString = "";
        if (timeLeft % 60 < 10) {
            timeLeftString = Math.floor(timeLeft / 60).toString() + ":0" + (timeLeft % 60).toString();
        } else {
            timeLeftString = Math.floor(timeLeft / 60).toString() + ":" + (timeLeft % 60).toString();
        }
        var position = powerPosition + Graphics.getFontHeight(Graphics.FONT_NUMBER_HOT) / 2 + 10 + Graphics.getFontHeight(Graphics.FONT_MEDIUM) / 2;
        dc.setColor(textForegroundColor, textBackgroundColor);
        dc.drawText(centerX, position, Graphics.FONT_MEDIUM, timeLeftString, Graphics.TEXT_JUSTIFY_CENTER);
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
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            heartRateIcon = ui.loadResource(Rez.Drawables.HeartWhite);
        } else {
            heartRateIcon = ui.loadResource(Rez.Drawables.Heart);
        }
        var heartRateIconWidth = heartRateIcon.getWidth();
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
}