/*
<AUTHOR: Jake Hilton, jake@gearsandcogs.com
Copyright (C) 2013, Gears and Cogs.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

VERSION: 0.0.1
DATE: 1/25/2013
ACTIONSCRIPT VERSION: 3.0
DESCRIPTION:
An extension of the native netstream class that will better handle cache emptying and is backwards compatible with version of flash that had buffer monitoring issues.

Some version of the flash player incorrectly removed buffer notifications which would break applications that relied on this. This class will automate the buffer emptying and notification of the buffer empty.

It will automatically detach any camera or microphone source from the netstream, allow it to empty, then report when it has emptied and close the netstream.

It has an event,BUFFER_EMPTIED, that fires to notify the user of a buffer empty success.

USAGE:
It's a simple use case really.. just use it as you would the built in NetStream class. 

To shutdown the netstream you would call the publishClose method to have it shutdown after a buffer empty or the finalizeClose to have it shutdown immediately and clean up the timer.

For example:
var nc:NetConnection;
var nss:NetStreamSmart = new NetStreamSmart(nc);

to close:
nss.publishClose();

*/

package com.gearsandcogs.utils
{
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	public class NetStreamSmart extends NetStream
	{
		public static const BUFFER_EMPTIED		:String = "BUFFER_EMPTIED";
		public static const VERSION				:String = "NetStreamSmart v 0.0.2";
		
		private var _is_paused					:Boolean;
		private var _is_playing					:Boolean;
		
		private var _internal_client			:Object;
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
		
		public function get is_paused():Boolean
		{
			return _is_paused;
		}
		
		public function get is_playing():Boolean
		{
			return _is_playing;
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
			
			addEventListener(NetStatusEvent.NET_STATUS,handleNetstatu);
		}
		
		protected function handleNetstatu(e:NetStatusEvent):void
		{
			trace("NetStreamSmart: "+e.info.code);
			switch(e.info.code)
			{
				case "NetStream.Pause.Notify":
					_is_playing = false;
					_is_paused = true;
					break;
				case "NetStream.Play.Start":
					_is_playing = true;
					_is_paused = false;
					break;
				case "NetStream.Play.Stop":
					_is_playing = false;
					break;
			}
		}
	}
}