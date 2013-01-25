package com.gearsandcogs.utils
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	public class NetStreamSmart extends NetStream
	{
		public static const BUFFER_EMPTIED		:String = "BUFFER_EMPTIED";
		
		private var bufferMonitorTimer			:Timer;
		
		public function NetStreamSmart(connection:NetConnection, peerID:String="connectToFMS")
		{
			initializeListeners();
			super(connection, peerID);
		}
		
		public function publishClose():void
		{
			bufferMonitorTimer.start();
		}
		
		public function finalizeClose():void
		{
			close();
			bufferMonitorTimer.stop();
			dispatchEvent(new Event(BUFFER_EMPTIED));
		}
		
		private function initializeListeners():void
		{
			bufferMonitorTimer = new Timer(100);
			bufferMonitorTimer.addEventListener(TimerEvent.TIMER,function(e:TimerEvent):void
			{
				//to completely freeup the netstream in the case of another instance trying
				//to attach a camera or mic when it's in shutdown mode
				attachAudio(null);
				attachCamera(null);
				try
				{
					if(info.audioBufferByteLength + info.videoBufferByteLength <= 0)
					{
						finalizeClose();
					}
				}catch(e:Error) //netconnection was shutdown incorrectly leaving this improperly instantiated
				{
					finalizeClose();
				}
			});
		}
		
	}
}