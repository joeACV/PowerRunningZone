using Toybox.WatchUi as Ui;
using Toybox.System as Sys;

class RunningPowerEfficiency {
	
	var avg;
	var pwrdict = new [5];
	var speed = new[5];
	var elevation = new[5];
	var distance = new[5];
	var gapData = new[5];
	var elevchange = 0.0;
	var totalSpeed = 0.0;
	var totalDist = 0.0;
	var avgPoint = 5; 
	var prevElev = 0.0;
	var prevDist = 0.0;
	var totalCalc = 0.0;
	var totalGap = 0.0;
	var totalPower = 0.0;
	

    //! The given info object contains all the current workout
    //! information. Calculate a value and return it in this method.
    function compute(info) {
        // See Activity.Info in the documentation for available information.
        var d = 0.0;
		var hr = 0.0;
		var datapoint = 0;
		var last = 0;
		var curpower = 0;
		var curElev = 0;
		var curSpeed =0;
		var curDist = 0;
		var gap =0;
		var value=0;
		var calc =0;
		
		if (info.elapsedDistance !=null){
			curDist = info.elapsedDistance;
		}
		if(info.altitude != null){
			curElev = info.altitude;
		}
		if(info.currentSpeed!=null){
			curSpeed = info.currentSpeed;
		}
		if (info.elapsedTime != null){
			datapoint = (info.elapsedTime % (avgPoint * 1000)) / 1000;
		} else {
			datapoint = 0;
		}
		if(info.currentPower!=null){
			curpower = info.currentPower;
		}
		//Don't average power as it appears to already being averaged
		totalPower = curpower * avgPoint;
				
		//Get total speed for 30 second time period
		if(speed[datapoint]!=null){
			totalSpeed = totalSpeed - speed[datapoint] + curSpeed;
		} else{
			totalSpeed +=curSpeed;
		}
		speed[datapoint] = curSpeed;
		//Get total elevation for 30 second time period
		if(elevation[datapoint]!=null){
			elevchange = curElev - elevation[datapoint];
		} 
		elevation[datapoint] = curElev;
		//calculate distance
		if(distance[datapoint]!=null){
			totalDist = curDist - distance[datapoint];
		}
		//distance[datapoint] = curDist;
		if((curDist - prevDist)>0){
//			gap = (totalSpeed/avgPoint) / (1+ 9*(elevchange/totalDist));
			gap = (curSpeed * 60)/(1+9*((curElev - prevElev)/(curDist - prevDist)));
			Sys.println("speed:" + curSpeed.toString());
			gapData[datapoint] = gap;
			
		}
		
		totalGap = 0;
		//Calculate total Grade adjusted pace
		for(var i= 0 ; i < avgPoint; i+=1){
    		if (gapData[i]!=null){
    			totalGap += gapData[i];
    		}
    	}
		if(totalGap>0 and totalPower>0){
			//value = gap / (totalPwr / avgPoint) * 100;
			value = totalGap / totalPower * 100;
			Sys.println(totalGap.toString() + " GAP " + totalPower.toString() + "Watts");
		}
		prevElev = curElev;
		prevDist = curDist;
		return value;
	}
	function getGap(){
		return totalGap / avgPoint;
	}
}
