package com.gearsandcogs.utils
{
	/**
	 * @author jhilton
	 */
	public class TimeCalculator
	{
		public static function getTimeOut(timeIn:Number,separator:String=":"):String
		{
			var timer:Number=timeIn;
			var d:Number=0;
			var h:Number=0;
			var m:Number=0;
			var s:Number=isNaN(timer)?0:timer;
			if (timer>59){
				if(timer/86399 > 1){
					d=Math.floor(timer/86400);
					timer=timer-(d*86400);
				}
				if (timer/3599 > 1){
					h=Math.floor(timer/3600);
					timer=timer-(h*3600);
				}
				m=Math.floor(timer/60);
				s=timer-(m*60);
			}
			var s_pass:String=(s<10?separator+"0":separator)+s;
			var m_pass:String=m==0?h>0?"00":"00":(m<10 ? h>0?"0":"0" : "")+m;
			var h_pass:String=h==0?d>0?"00":"":(h<10 ? d>0?"0":"0" : "")+h+separator;
			var d_pass:String=d==0 ? "" : d+separator
	
			return d_pass+h_pass+m_pass+s_pass;
		}
		// 
		public static function getSecondsOut(timeIn:String):Number
		{
			var time_split:Array = timeIn.split(":");
			var secondsOut:Number = 0;
			if(time_split.length==4) 
                secondsOut = Number(time_split[0])*86400 + Number(time_split[1])*3600 + Number(time_split[2])*60
			if(time_split.length==3) 
                secondsOut = Number(time_split[0])*3600 + Number(time_split[1])*60
			if(time_split.length==2) 
                secondsOut = Number(time_split[0])*60
			secondsOut += Number(time_split[time_split.length-1])
			return secondsOut;
		}
	}
}