using Toybox.WatchUi as Ui;
using Toybox.Activity as Act;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Attention as Attention;
using Toybox.Application as App;


class PowerRunningZoneView extends Ui.DataField {
	const OBSCURE_ALL_SIDES = (OBSCURE_TOP | OBSCURE_BOTTOM | OBSCURE_RIGHT | OBSCURE_LEFT);
	const OBSCURE_TOP_HALF = (OBSCURE_TOP | OBSCURE_RIGHT | OBSCURE_LEFT);
	const OBSCURE_BOTTOM_HALF = (OBSCURE_BOTTOM | OBSCURE_RIGHT | OBSCURE_LEFT);
	enum
    {
        STOPPED,
        PAUSED,
        RUNNING
    }
    enum
    {
    	TopLeft,
    	TopRight,
    	BottomRight,
    	BottomLeft
    }
    var pe = new RunningPowerEfficiency();
    var powerEff = 0;
    var lapPower = 0.0;
    var prevLapPower = 0.0;
    var lapStartTime = 0;
    var lastLapPower = 0.0;
    var prevLapPowerTime = 0.0;
    var lapStepCountStart = 0;
    hidden var mTimerState = STOPPED;
	var label = "Run Power";
	var zone1low = 0;    
	var zone2low = 0;
	var zone3low = 0;
	var zone4low = 0;
	var zone5low = 0;
	var zone6low = 0;
	var zone7low = 0;
	var alertZoneChange = false;
	var vibrateZoneChange = false;
	var lapAlertZone = false;
	hidden var prevZone = 0.0;
	hidden var currentPowerZone = 0.0;
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
    // Set the label of the data field here.
    function initialize() {
        DataField.initialize();
    }
    
    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function onUpdate(dc){
    	var dataColor = Gfx.COLOR_BLACK;
    	var labelDisplay = label;
    	var valueString;
    	var effString = "0";
	   	var obscurity = getObscurityFlags();
    	var app = App.getApp();
    	alertZoneChange = app.getProperty("alert_zone_change_p");
    	vibrateZoneChange = app.getProperty("vibrate_zone_change_p");
	   	lapAlertZone = app.getProperty("alert_lap_p");
		if (obscurity==0){
	    	roundFaceGFX(dc, powerZone, powerEff);
    	}else {
    		roundFaceGFX(dc, powerZone, powerEff);
    	}
    }
    function squareFaceGFX(dc, zone, eff){
    	//If 
    	var valueString;
    	var effString = "0";
    	var labelDisplay = label;
    	var dataColor = Gfx.COLOR_BLACK;
 	    valueString = zone.format("%.1f"); 
    	effString = eff.format("%d") + "%";
    	dc.setColor(Gfx.COLOR_BLACK,setZoneColor(powerZone));
        dc.clear();
        dc.drawText(20,20,Gfx.FONT_SMALL,labelDisplay,(Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_LEFT));
        
        if (dc.getWidth()>110){
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2 - 5,  Gfx.FONT_NUMBER_MEDIUM, effString, (Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_RIGHT));
        	dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_NUMBER_MEDIUM, valueString, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_CENTER));
        }else{
        	dc.drawText(dc.getWidth()-5, 0, Gfx.FONT_SMALL, effString, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_CENTER));
        }
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Gfx.FONT_NUMBER_MEDIUM, valueString, (Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_CENTER));
        
        //dc.drawText((dc.getWidth() + dc.getTextWidthInPixels(pe.getGap().format("%.1f") + " gap", Gfx.FONT_SMALL)) / 2,dc.getFontHeight(Gfx.FONT_SMALL) , Gfx.FONT_SMALL, pe.getGap().format("%.1f") + " gap", (Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_CENTER));
    }
    
    function roundFaceGFX(dc, zone, eff){
    	//If Rouncded face look at obscurity to move
    	var valueString;
    	var effString = "0";
    	var labelDisplay = label;
    	var dataColor = Gfx.COLOR_BLACK;
    	var effWidth = 0;
    	var effHeight = 0;
    	var powerDimensions = [0,0];
    	var lapString = "0";
   		var obscurity = getObscurityFlags();
   		var percentPower = 0;
   		var tempFloat = 0.0;
   		var location = [0,0];
   		var lapPowerZone = 0.0;
 	    valueString = zone.format("%.1f"); 
    	effString = eff.format("%d") + "%";
    	
        powerDimensions = dc.getTextDimensions(valueString, Gfx.FONT_NUMBER_MEDIUM);
    	if (powerZone >0){
			percentPower = 7/powerZone;
		}else{
			percentPower = 7;
		}
		if (dc.getHeight()>150){
			location = [dc.getWidth()/2,
        			dc.getHeight()/2 - powerDimensions[1]/2];
        }else{
        	location = [dc.getWidth()/2,
        			dc.getHeight()/2 - powerDimensions[1]/2];
        }
    	
    	dc.clear();
    	dc.setColor(Gfx.COLOR_BLACK,setZoneColor(powerZone));
    	lapPowerZone = getZone(lapPower);
        lapString = lapPowerZone.format("%.1f");
		
		
        dc.setColor(setZoneColor(powerZone),Gfx.COLOR_TRANSPARENT);
		
        dc.fillRectangle(0,
        				location[1],
        				dc.getWidth()/percentPower,powerDimensions[1]);
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
        dc.drawText(location[0], //Draw Power Zone middle of the window
        			location[1], 
        			Gfx.FONT_NUMBER_MEDIUM , 
        			valueString, 
        			Gfx.TEXT_JUSTIFY_CENTER);

        if (dc.getWidth()>70 | dc.getHeight() < 50){
        	drawValue(dc, "Eff",effString,TopRight,Gfx.COLOR_TRANSPARENT, location[1]*0.95, obscurity); //Draw Efficiency top right
			drawValue(dc, "Lap",lapString ,TopLeft,setZoneColor(lapPowerZone), location[1]*0.95, obscurity);
			drawValue(dc, "GAP", pe.getGap().format("%.0f") , BottomLeft, Gfx.COLOR_TRANSPARENT, location[1]*0.99, obscurity);
        	dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_WHITE);
	        dc.drawText(dc.getWidth()/2,2,Gfx.FONT_TINY,labelDisplay,(Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_CENTER));
	    }else {
	       	dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
	        dc.drawText(dc.getWidth()/2,2,Gfx.FONT_TINY,labelDisplay,(Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_CENTER));        
	    }
//      	dc.drawText((dc.getWidth() + dc.getTextWidthInPixels(eff.format("%.1f") + " gap", Gfx.FONT_SMALL)) / 2,dc.getFontHeight(Gfx.FONT_SMALL) , Gfx.FONT_SMALL, eff.format("%.1f") + " gap", (Gfx.TEXT_JUSTIFY_LEFT | Gfx.TEXT_JUSTIFY_CENTER));
    }
   
    function drawValue(dc, label, value, position,bkColor, height, obscurity){
    	//Draw based on position
    	var dimensions = [0,0];
    	var baseLocation = [0,0];
    	var location = [0,0];
    	var labelLocation = [0,0];
    	var fontSize = Gfx.FONT_NUMBER_MEDIUM;
	   	var valueString = "0.0";
    	var valueFont = Gfx.FONT_NUMBER_MEDIUM;
    	var drawLabel = 1;
    	var labelDimensions = [0,0];
    	var labelFont = Gfx.FONT_TINY;
    	var valueDimensions = [0,0];
    	var textAlign = Gfx.TEXT_JUSTIFY_CENTER;
    	
    	valueDimensions = dc.getTextDimensions(value, valueFont);
    	dimensions = [dc.getWidth()/2, height];
    	labelDimensions = dc.getTextDimensions(label, labelFont);
       	dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
       	if (valueDimensions[1] + labelDimensions[1] > dimensions[1]){
       		valueFont = Gfx.FONT_SMALL;
	    	valueDimensions = dc.getTextDimensions(value, valueFont);
	    }
       	switch (position) {
       		case TopLeft: {
       			baseLocation = [0,0];
       			}
				break;
       			
       		case TopRight:{
       			baseLocation = [dc.getWidth()/2,0];}
       			break;
       			
       		case BottomLeft:{
       			baseLocation = [0,dc.getHeight()-height];}
       			break;
       			
       		case BottomRight:{
       			baseLocation = [dc.getWidth()/2, dc.getHeight()-height];}
       			break;
       			
       		default:
       			break;
       			
       	}
       	if (obscurity & OBSCURE_LEFT and position == TopLeft){     		
	       	location = [baseLocation[0] + dimensions[0] *0.5,  //Position of value
	       				baseLocation[1] + dimensions[1] - valueDimensions[1]*1.1];
	    }
	    else if (obscurity & OBSCURE_RIGHT and position == TopRight){     		
	       	location = [baseLocation[0] + dimensions[0] - valueDimensions[0],  //Position of value
	       				baseLocation[1] + dimensions[1] - valueDimensions[1]*1.1];
    	}else if (obscurity & OBSCURE_LEFT and position == BottomLeft){     		
	       	location = [baseLocation[0] + dimensions[0] - valueDimensions[0],  //Position of value
	       				baseLocation[1] + labelDimensions[1]*1.1];
    	}
    	labelLocation = [location[0],
    					location[1] - labelDimensions[1]*1.01];
   		dc.setColor(bkColor, Gfx.COLOR_BLUE);
         dc.fillRectangle(baseLocation[0], baseLocation[1], 
         					dimensions[0], dimensions[1]);
         dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
         dc.drawRectangle(baseLocation[0], baseLocation[1], 
         					dimensions[0], dimensions[1]);
         dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
		 dc.drawText(location[0], 			
					location[1],  
					valueFont, 
					value , 
					textAlign);
		 dc.drawText(labelLocation[0], //Draw Label
	    			labelLocation[1],
	    			labelFont,
	    			label,
	    			textAlign);
}
     
    
    function compute(info) {
        // See Activity.Info in the documentation for available information.
        var lapTime = 0;
        var lapPowerZone = 0.0;
        var prevLapZone = 0.0;
        powerEff = pe.compute(info);
        if (zone7low==0){
        	setZones();
        }
        lapTime = info.elapsedTime - lapStartTime;
       	prevLapPower = lapPower;
    	prevLapZone = getZone(prevLapPower);
    	if (lapTime > prevLapPowerTime){
	        lapPower = calculateAvgPower(lapTime,prevLapPowerTime,lapPower,info.currentPower);
	    }
        prevLapPowerTime = lapTime;
	    
        powerZone = getZone(info.currentPower);
        lapPowerZone = getZone(lapPower);
		if(lapAlertZone and mTimerState == RUNNING){
			if(prevLapZone.toNumber() != lapPowerZone.toNumber()){
				System.println("Prev Lap zone:" + prevLapZone.toNumber().toString());
				System.println("Lap Power Zone:" + lapPowerZone.toNumber().toString());
				alertZoneTone(prevLapZone.toNumber()<lapPowerZone.toNumber());
			}
		}

        if ((alertZoneChange or vibrateZoneChange) and mTimerState == RUNNING){
        	if(powerZone.toNumber() != currentPowerZone.toNumber()){
        		if (lapAlertZone){
	        		
	        	}
        		currentPowerZone = powerZone;
        		if (currentPowerZone.toNumber() != prevZone.toNumber()){
        			currentZoneCount = 0;
        		}
        	} else if (currentZoneCount<3){
        		currentZoneCount+=1;
        	} else if (currentZoneCount==3 or currentZoneCount==4 and (powerZone != prevZone)){
        		if (currentZoneCount == 4){
        			prevZone = currentPowerZone;
        		}
        	   	alertZone(currentPowerZone);
        	   	currentZoneCount+=1;
        	}
        }
        prevZone = powerZone;
        return powerZone;
    }
    function setZoneColor(zone){
    	//Set colors based on zone
    	var colorSet = Gfx.COLOR_WHITE;
    	if (zone<=1.0){
    		colorSet = Gfx.COLOR_WHITE;
    	} else if (zone<2.0){
    		colorSet = Gfx.COLOR_LT_GRAY;
    	} else if (zone<3.0){
    		colorSet = Gfx.COLOR_GREEN;
    	} else if (zone<4.0){ 
    		colorSet = Gfx.COLOR_ORANGE;
    	} else if (zone<5.0){ 
    		colorSet = Gfx.COLOR_PINK;
    	} else if (zone<6.0){ 
    		colorSet = Gfx.COLOR_RED;
    	} else if (zone<7.0){ 
    		colorSet = Gfx.COLOR_PURPLE;
    	} else if (zone>=7.0){
    		colorSet = Gfx.COLOR_DK_RED;
    	}
    	return colorSet;
    }
    function alertZoneTone(direction){
    	if (alertZoneChange){
    		if (direction){
	    		Attention.playTone(Attention.TONE_ALERT_HI );
	    		
	    	}else{
	    		Attention.playTone(Attention.TONE_ALERT_LO);
	    	}
	    	if (Attention has :backlight) {
			    Attention.backlight(true);
			}
	    }
    }
    
    function alertZone(powerZone){
    	//Play Tone and/or vibrate when zone changes
    	if (alertZoneChange){
        	Attention.playTone(Attention.TONE_KEY);
        }
        if (vibrateZoneChange){
        	vibrateZone(powerZone);
        }
        
    }
    function vibrateZone(zone){
//    	var vibeProfile =  new [zone.toNumber()];
//    	for(var i= 0 ; i < zone.toNumber(); i+=1){
//    		vibeProfile[i] = vibrateZoneProfile[i];
//    	}
    	Attention.vibrate(vibeProf);
    }
    function setZones(){
    //Set zones from properties
    	var app = App.getApp();
    	alertZoneChange = app.getProperty("alert_zone_change_p");
    	vibrateZoneChange = app.getProperty("vibrate_zone_change_p");
      	zone1low = app.getProperty("zone1_low_p");
      	if (zone1low == 0.0){
      		zone1low = 1.0;
      	}
      	zone2low = app.getProperty("zone2_low_p");
      	zone3low = app.getProperty("zone3_low_p");
      	zone4low = app.getProperty("zone4_low_p");
      	zone5low = app.getProperty("zone5_low_p");
      	zone6low = app.getProperty("zone6_low_p");
      	zone7low = app.getProperty("zone7_low_p");
    }
    function getZone(power){
    //Send power returns zone as float
   		var zone = 0.0;
   		
   		if (power == null){
   			return 0.0;
   		}
    	if (power<zone1low){
    		zone = power / (zone1low.toFloat());
    	} else if (power<zone2low){
    		zone = 1.0 + ((power - zone1low.toFloat()) / (zone2low.toFloat() - zone1low.toFloat()));
    	} else if (power<zone3low){
    		zone = 2.0 + ((power - zone2low.toFloat()) / (zone3low.toFloat() - zone2low.toFloat()));
    	} else if (power<zone4low){ 
    		zone = 3.0 + ((power - zone3low.toFloat()) / (zone4low.toFloat() - zone3low.toFloat()));
    	} else if (power<zone5low){ 
    		zone = 4.0 + ((power - zone4low.toFloat()) / (zone5low.toFloat() - zone4low.toFloat()));
    	} else if (power<zone6low){ 
    		zone = 5.0 + ((power - zone5low.toFloat()) / (zone6low.toFloat() - zone5low.toFloat()));
    	} else if (power<zone7low){ 
    		zone = 6.0 + ((power - zone6low.toFloat()) / (zone7low.toFloat() - zone6low.toFloat()));
    	} else if (power>=zone7low){
    		zone = 7.0;
    	}
    	return zone;
	}
	function calculateAvgPower(time, prevTime, avg, power){
	//time is total time in seconds 
	//avg is current average over that time
	//power is new power
	//returns new average
		var newAvg = 0.0;
		var timeF = 0.0;
		var math = "";
		var timeDiff = 0.0;
		timeF = time.toFloat()/1000.0;
		timeDiff = (time.toFloat() - prevTime.toFloat()) / 1000.0;
		//math = avg.toString() + "avg " + timeF.toString() + "lap time " + power.toString() + "power";

		if(timeF >0){
			if (power!=null){
				newAvg = (avg*(prevTime.toFloat()/1000.0) + power*timeDiff) / timeF;
			}else{
				newAvg = (avg*(prevTime.toFloat()/1000.0) + 0) / timeF;
			}
		} else {
			newAvg = 0.0;
		}
		return newAvg;
	}
	function onTimerStart(){
		setZones();
		mTimerState = RUNNING;
	}
	function onTimerStop(){
		mTimerState = STOPPED;
	}
	function onTimerLap(){
		lapComplete();
	}
	function onWorkoutStepComplete(){
		lapComplete();
	}
	function lapComplete(){
		//Set last lap power
		//Reset lap time and lappower
		var info = Act.getActivityInfo();
		if (lastLapPower>0){
			lastLapPower = lapPower;
		}
		lapStartTime = info.elapsedTime;
		lapPower = 0.0;
		lapStepCountStart = lapStepCountStart + 1;
	}
}
	
