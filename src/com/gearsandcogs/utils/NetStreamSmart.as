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

VERSION: 0.1.1
DATE: 5/16/2013
ACTIONSCRIPT VERSION: 3.0
DESCRIPTION:
An extension of the native netstream class that will better handle cache emptying and is backwards compatible with version of flash that had buffer monitoring issues.

Some version of the flash player incorrectly removed buffer notifications which would break applications that relied on this. This class will automate the buffer emptying and notification of the buffer empty.

It will automatically detach any camera or microphone source from the netstream, allow it to empty, then report when it has emptied and close the netstream.

It has an event,BUFFER_EMPTIED, that fires to notify the user of a buffer empty success.

Public properties that can be set:
buffer_empty_wait_limit: a uint property defining the number of seconds that the class will wait before firing off the buffer empty event. The default is 0 which means it will wait indefinitely for the netstream buffer to empty

USAGE:
It's a simple use case really.. just use it as you would the built in NetStream class. 

To shutdown the netstream you would call the publishClose method to have it shutdown after a buffer empty or the finalizeClose to have it shutdown immediately and clean up the timer.

For example:
var nc:NetConnection;
var nss:NetStreamSmart = new NetStreamSmart(nc);

//to close:
nss.publishClose(); //will let the buffers empty to the server naturally then close
nss.close(); //will immediately disconnect sources and close the netstream

*/

package com.gearsandcogs.utils
{
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	dynamic public class NetStreamSmart extends NetStream
	{
		public static const VERSION								:String = "NetStreamSmart v 0.1.1";
		
		public static const NETSTREAM_BUFFER_EMPTY				:String = "NetStream.Buffer.Empty";
		public static const NETSTREAM_BUFFER_FULL				:String = "NetStream.Buffer.Full";
		
		public static const NETSTREAM_PAUSE_NOTIFY				:String = "NetStream.Pause.Notify";
		public static const NETSTREAM_PLAY_START				:String = "NetStream.Play.Start";
		public static const NETSTREAM_PLAY_STOP					:String = "NetStream.Play.Stop";
		public static const NETSTREAM_PLAY_STREAMNOTFOUND		:String = "NetStream.Play.StreamNotFound";
		public static const NETSTREAM_PUBLISH_BADNAME			:String = "NetStream.Publish.BadName";
		public static const NETSTREAM_PUBLISH_START				:String = "NetStream.Publish.Start";
		
		public static const NETSTREAM_RECORD_START				:String = "NetStream.Record.Start";
		public static const NETSTREAM_RECORD_STOP				:String = "NetStream.Record.Stop";
		public static const NETSTREAM_UNPUBLISH_SUCCESS			:String = "NetStream.Unpublish.Success";

		public static const ONCUEPOINT							:String = "NetStream.On.CuePoint";
		public static const ONMETADATA							:String = "NetStream.On.MetaData";
		
		public var buffer_empty_wait_limit						:uint = 0;
		
		public var _ext_client									:Object = {};
		
		private var _closed										:Boolean;
		private var _debug										:Boolean;
		private var _listener_initd								:Boolean;
		private var _is_paused									:Boolean;
		private var _is_playing									:Boolean;
		private var _is_publishing								:Boolean;
		
		private var _metaData									:Object;
		
		private var _bufferMonitorTimer							:Timer;
		
		public function NetStreamSmart(connection:NetConnection, peerID:String="connectToFMS")
		{
			initVars();
			initListener();
			super(connection, peerID);
		}
		
		private function initVars():void
		{
			_closed = false;
			_listener_initd = false;
			_is_paused = false;
			_is_playing = false;
			_is_publishing = false;
		}
		
		private function get bufferMonitorTimer():Timer
		{
			if(!_bufferMonitorTimer)
			{
				_bufferMonitorTimer = new Timer(100,buffer_empty_wait_limit*10);
				_bufferMonitorTimer.addEventListener(TimerEvent.TIMER_COMPLETE,function(e:TimerEvent):void
				{
					close();
				});
				_bufferMonitorTimer.addEventListener(TimerEvent.TIMER,function(e:TimerEvent):void
				{
					//to completely freeup the netstream in the case of another instance trying
					//to attach a camera or mic when it's in shutdown mode
					disconnectSources();
					try
					{
						if(info.audioBufferByteLength + info.videoBufferByteLength <= 0)
						{
							close();
						}
					}catch(e:Error) //netconnection was shutdown incorrectly leaving this improperly instantiated
					{
						close();
					}
				});
			}
			
			return _bufferMonitorTimer;
		}
		
		private function killTimer():void
		{
			if(_bufferMonitorTimer)
			{
				_bufferMonitorTimer.stop();
				_bufferMonitorTimer = null;
			}
		}
		
		private function disconnectSources():void
		{
			attachAudio(null);
			attachCamera(null);
		}
		
		private function log(msg:String):void
		{
			trace("NetStreamSmart: "+msg);
		}
		
		private function initListener():void
		{
			if(!_listener_initd)
				addEventListener(NetStatusEvent.NET_STATUS,handleNetstatus);
			_listener_initd = true;
		}
		
		/*
		* Public methods
		*/
		
		override public function attach(nc:NetConnection):void
		{
			_closed = false;
			super.attach(nc);
		}
		
		override public function close():void
		{
			if(_debug)
				log("close hit");
			
			killTimer();
			initVars();
			disconnectSources();
			_closed = true;
			dispatchEvent(new Event(NETSTREAM_BUFFER_EMPTY));
			super.close();
		}
		
		override public function play(...args):void
		{
			if(_debug)
				log("play hit: "+args.join());
			
			super.play.apply(null,args);
		}
		
		override public function set client(obj:Object):void
		{
			_ext_client = obj;
			for(var i:String in obj)
			{
				if(!this[i])
					this[i] = obj[i];
			}
			
			super.client = this;
		}
		

		public function get closed():Boolean
		{
			return _closed;
		}
		
		public function get debug():Boolean
		{
			return _debug;
		}
		
		public function set debug(isdebug:Boolean):void
		{
			_debug = isdebug;
			log(VERSION);
		}
		
		public function publishClose():void
		{
			if(_debug)
				log("publishClose hit");
			
			bufferMonitorTimer.start();
		}
		
		public function get is_paused():Boolean
		{
			return _is_paused;
		}
		
		public function get is_playing():Boolean
		{
			return _is_playing;
		}
		
		public function get is_publishing():Boolean
		{
			return _is_publishing;
		}
		
		public function get metaData():Object
		{
			return _metaData;
		}
		
		protected function handleNetstatus(e:NetStatusEvent):void
		{
			if(_debug)
				log(e.info.code);
			
			switch(e.info.code)
			{
				case NETSTREAM_PAUSE_NOTIFY:
					_is_playing = false;
					_is_paused = true;
					break;
				case NETSTREAM_PLAY_START:
					_is_playing = true;
					_is_paused = false;
					break;
				case NETSTREAM_PLAY_STOP:
					_is_playing = false;
					break;
				case NETSTREAM_PUBLISH_BADNAME:
				case NETSTREAM_UNPUBLISH_SUCCESS:
					_is_publishing = false;
					break;
				case NETSTREAM_PUBLISH_START:
					_is_publishing = true;
					break;
			}
		}
		
		/*
		* Default methods to be supported for callbacks
		*/
		
		public function onCuePoint(info:Object):void
		{
			if(_ext_client["onCuePoint"])
				_ext_client["onCuePoint"](info);
			
			dispatchEvent(new ParamEvent(ONCUEPOINT,false,false,info));
		}
		
		public function onMetaData(info:Object):void
		{
			//used to allow the app to continue to work if a client.onMetaData isn't specified
			_metaData = info;
			
			if(_ext_client["onMetaData"])
				_ext_client["onMetaData"](info);
			
			dispatchEvent(new ParamEvent(ONMETADATA,false,false,info));
		}
	}
}
