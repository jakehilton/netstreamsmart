/*
 <AUTHOR: Jake Hilton, jake@gearsandcogs.com
 Copyright (C) 2014, Gears and Cogs.

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

 VERSION: 1.1.0
 DATE: 08/25/2014
 ACTIONSCRIPT VERSION: 3.0
 DESCRIPTION:
 An extension of the native netstream class that will better handle cache emptying and is backwards compatible with version of flash that had buffer monitoring issues.

 Some version of the flash player incorrectly removed buffer notifications which would break applications that relied on this. This class will automate the buffer emptying and notification of the buffer empty.

 It will automatically detach any camera or microphone source from the netstream, allow it to empty, then report when it has emptied and close the netstream.

 It has an event,BUFFER_EMPTIED, that fires to notify the user of a buffer empty success.

 Public properties that can be set:
 buffer_empty_wait_limit: a uint property defining the number of seconds that the class will wait before firing off the buffer empty event. The default is 0 which means it will wait indefinitely for the netstream buffer to empty
 disable_time_update: by default a timer will be initialized to report back when the time value updates. The default is false and so the timer will start and report.
 enable_info_update: enable a timer will be initialized to report back netstream.info at a set interval. The default is false and so the timer will not start and report.
 ns_info_rate: the rate at which the info updates are reported out. The default is 2000 (2 seconds)
 format_netstream_info: it will format the netstream info into a JSON compatible dataset instead of the default netstream info object which doesn't support iterations

 USAGE:
 It's a simple use case really.. just use it as you would the built in NetStream class.

 To shutdown the netstream you would call the publishClose method to have it shutdown after a buffer empty or the finalizeClose to have it shutdown immediately and clean up the timer.

 For example:
 var nc:NetConnection;
 var nss:NetStreamSmart = new NetStreamSmart(nc);

 //to close:
 nss.publishClose(); //will let the buffers empty to the server naturally then close the netstream
 or
 nss.publishDispose(); //will let the buffers empty to the server naturally then dispose of the netstream
 or
 nss.close(); //will immediately disconnect sources and close the netstream
 or
 nss.dispose(); //will immediately disconnect sources and dispose the netstream

 */

package com.gearsandcogs.utils
{
    import flash.events.Event;
    import flash.events.NetStatusEvent;
    import flash.events.TimerEvent;
    import flash.media.Camera;
    import flash.media.Microphone;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.NetStreamInfo;
    import flash.utils.Timer;
    import flash.utils.describeType;

    dynamic public class NetStreamSmart extends NetStream
    {
        public static const NETSTREAM_BUFFER_EMPTY:String = "NetStream.Buffer.Empty";
        public static const NETSTREAM_BUFFER_FLUSH:String = "NetStream.Buffer.Flush";
        public static const NETSTREAM_BUFFER_FULL:String = "NetStream.Buffer.Full";
        public static const NETSTREAM_CONNECT_CLOSED:String = "NetStream.Connect.Closed";
        public static const NETSTREAM_CONNECT_FAILED:String = "NetStream.Connect.Failed";
        public static const NETSTREAM_CONNECT_REJECTED:String = "NetStream.Connect.Rejected";
        public static const NETSTREAM_CONNECT_SUCCESS:String = "NetStream.Connect.Success";
        public static const NETSTREAM_DRM_UPDATENEEDED:String = "NetStream.DRM.UpdateNeeded";
        public static const NETSTREAM_FAILED:String = "NetStream.Failed";
        public static const NETSTREAM_INFO_UPDATE:String = "NetStream.Info.Update";
        public static const NETSTREAM_MULTICASTSTREAM_RESET:String = "NetStream.MulticastStream.Reset";
        public static const NETSTREAM_PAUSE_NOTIFY:String = "NetStream.Pause.Notify";
        public static const NETSTREAM_PLAY_FAILED:String = "NetStream.Play.Failed";
        public static const NETSTREAM_PLAY_FILESTRUCTUREINVALID:String = "NetStream.Play.FileStructureInvalid";
        public static const NETSTREAM_PLAY_INSUFFICIENTBW:String = "NetStream.Play.InsufficientBW";
        public static const NETSTREAM_PLAY_NOSUPPORTEDTRACKFOUND:String = "NetStream.Play.NoSupportedTrackFound";
        public static const NETSTREAM_PLAY_PUBLISHNOTIFY:String = "NetStream.Play.PublishNotify";
        public static const NETSTREAM_PLAY_RESET:String = "NetStream.Play.Reset";
        public static const NETSTREAM_PLAY_START:String = "NetStream.Play.Start";
        public static const NETSTREAM_PLAY_STOP:String = "NetStream.Play.Stop";
        public static const NETSTREAM_PLAY_STREAMNOTFOUND:String = "NetStream.Play.StreamNotFound";
        public static const NETSTREAM_PLAY_TRANSITION:String = "NetStream.Play.Transition";
        public static const NETSTREAM_PLAY_UNPUBLISHNOTIFY:String = "NetStream.Play.UnpublishNotify";
        public static const NETSTREAM_PUBLISH_BADNAME:String = "NetStream.Publish.BadName";
        public static const NETSTREAM_PUBLISH_IDLE:String = "NetStream.Publish.Idle";
        public static const NETSTREAM_PUBLISH_START:String = "NetStream.Publish.Start";
        public static const NETSTREAM_RECORD_ALREADYEXISTS:String = "NetStream.Record.AlreadyExists";
        public static const NETSTREAM_RECORD_FAILED:String = "NetStream.Record.Failed";
        public static const NETSTREAM_RECORD_NOACCESS:String = "NetStream.Record.NoAccess";
        public static const NETSTREAM_RECORD_START:String = "NetStream.Record.Start";
        public static const NETSTREAM_RECORD_STOP:String = "NetStream.Record.Stop";
        public static const NETSTREAM_SECONDSCREEN_START:String = "NetStream.SecondScreen.Start";
        public static const NETSTREAM_SECONDSCREEN_STOP:String = "NetStream.SecondScreen.Stop";
        public static const NETSTREAM_SEEK_FAILED:String = "NetStream.Seek.Failed";
        public static const NETSTREAM_SEEK_INVALIDTIME:String = "NetStream.Seek.InvalidTime";
        public static const NETSTREAM_SEEK_NOTIFY:String = "NetStream.Seek.Notify";
        public static const NETSTREAM_STEP_NOTIFY:String = "NetStream.Step.Notify";
        public static const NETSTREAM_TIME_UPDATE:String = "NetStream.Time.Update";
        public static const NETSTREAM_UNPAUSE_NOTIFY:String = "NetStream.Unpause.Notify";
        public static const NETSTREAM_UNPUBLISH_SUCCESS:String = "NetStream.Unpublish.Success";
        public static const NETSTREAM_VIDEO_DIMENTIONCHANGE:String = "NetStream.Video.DimensionChange";

        public static const ONCUEPOINT:String = "NetStream.On.CuePoint";
        public static const ONMETADATA:String = "NetStream.On.MetaData";
        public static const VERSION:String = "NetStreamSmart v 1.1.1";

        public var camera_attached:Boolean;
        public var format_netstream_info:Boolean = true;
        public var audio_attached:Boolean;

        public var buffer_empty_wait_limit:uint = 0;

        private var _closed:Boolean;
        private var _debug:Boolean;
        private var _disable_time_update:Boolean;
        private var _dispose:Boolean;
        private var _enable_info_update:Boolean;
        private var _is_buffering:Boolean;
        private var _is_paused:Boolean;
        private var _is_playing:Boolean;
        private var _is_publishing:Boolean;
        private var _is_recording:Boolean;
        private var _listener_initd:Boolean;

        private var _nc:NetConnection;
        private var _time:Number = 0;

        private var _ext_client:Object = {};
        private var _metaData:Object = {};

        private var _bufferMonitorTimer:Timer;
        private var _timeMonitorTimer:Timer;
        private var _nsInfoTimer:Timer;

        private var _ns_info_rate:uint = 2000;

        public function NetStreamSmart(connection:NetConnection, peerID:String = "connectToFMS") {
            _nc = connection;
            initVars();
            initListeners();
            super(connection, peerID);
        }

        override public function set client(obj:Object):void {
            _ext_client = obj;
            for(var i:String in obj)
                if(!hasOwnProperty(i))
                    this[i] = obj[i];

            super.client = this;
        }

        public function get enable_info_update():Boolean {
            return _enable_info_update;
        }

        public function set enable_info_update(b:Boolean):void {
            _enable_info_update = b;

            if(b)
                setupInfoUpdater();
            else
                killInfoUpdater();
        }

        public function get disable_time_update():Boolean {
            return _disable_time_update;
        }

        public function set disable_time_update(b:Boolean):void {
            _disable_time_update = b;

            if(b)
                setupTimeMonitor();
            else
                killTimeMonitor();
        }

        public function get infoArray():Array {
            var returnData:Array = [];
            var raw_info:Object = formatNetStreamInfo(info);

            for(var i:String in raw_info)
                returnData.push({name: i, value: raw_info[i]});

            returnData.sortOn("name", [Array.CASEINSENSITIVE]);

            return returnData;
        }

        public function get infoFormatted():Object {
            return formatNetStreamInfo(info);
        }

        public function get ns_info_rate():uint {
            return _ns_info_rate;
        }

        public function set ns_info_rate(rate:uint):void {
            _ns_info_rate = rate;

            if(enable_info_update) {
                killInfoUpdater();
                setupInfoUpdater();
            }
        }

        public function get closed():Boolean {
            return _closed;
        }

        public function get debug():Boolean {
            return _debug;
        }

        public function set debug(isdebug:Boolean):void {
            _debug = isdebug;
            log(VERSION);
        }

        /*
         * Public methods
         */

        public function get duration():Number {
            return metaData.duration ? metaData.duration : 0;
        }

        public function get is_buffering():Boolean {
            return _is_buffering;
        }

        public function get is_paused():Boolean {
            return _is_paused;
        }

        public function get is_playing():Boolean {
            return _is_playing;
        }

        public function get is_publishing():Boolean {
            return _is_publishing;
        }

        public function get metaData():Object {
            return _metaData;
        }

        public function get netconnection():NetConnection {
            return _nc;
        }

        public function get is_recording():Boolean {
            return _is_recording;
        }

        public function set is_recording(value:Boolean):void {
            _is_recording = value;
        }

        private function get bufferMonitorTimer():Timer {
            if(!_bufferMonitorTimer) {
                _bufferMonitorTimer = new Timer(100, buffer_empty_wait_limit * 10);
                _bufferMonitorTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function (e:TimerEvent):void {
                    close();
                });
                _bufferMonitorTimer.addEventListener(TimerEvent.TIMER, function (e:TimerEvent):void {
                    //to completely freeup the netstream in the case of another instance trying
                    //to attach a camera or mic when it's in shutdown mode
                    disconnectSources();
                    try {
                        if(info.audioBufferByteLength + info.videoBufferByteLength <= 0) {
                            if(_dispose)
                                dispose();
                            else
                                close();
                        }
                    }
                    catch(e:Error) //netconnection was shutdown incorrectly leaving this improperly instantiated
                    {
                        if(_dispose)
                            dispose();
                        else
                            close();
                    }
                });
            }

            return _bufferMonitorTimer;
        }

        private static function formatNetStreamInfo(ns_info:NetStreamInfo):Object {
            var ns_info_new:Object = new Object();
            var described_item:XML = describeType(ns_info);
            var accessors:XMLList = described_item..accessor;
            for each(var item:XML in accessors)
                ns_info_new[item.@name.toString()] = ns_info[item.@name.toString()];

            return ns_info_new;
        }

        private static function log(msg:String):void {
            trace("NetStreamSmart: " + msg);
        }

        override public function attach(nc:NetConnection):void {
            _nc = nc;
            _closed = false;
            super.attach(nc);
        }

        override public function attachAudio(microphone:Microphone):void {
            audio_attached = microphone is Microphone;
            super.attachAudio(microphone);
        }

        override public function attachCamera(theCamera:Camera, snapshotMilliseconds:int = -1):void {
            camera_attached = theCamera is Camera;
            super.attachCamera(theCamera, snapshotMilliseconds);
        }

        override public function close():void {
            if(_debug)
                log("close hit");

            killTimers();
            initVars();
            disconnectSources();
            _closed = true;
            dispatchEvent(new Event(NETSTREAM_BUFFER_EMPTY));

            if(_dispose)
                super.dispose();
            else
                super.close();
        }

        override public function dispose():void {
            if(_debug)
                log("dispose hit");

            _dispose = true;
            close();
        }

        /**
         * @see flash.net.NetStream.play
         */
        override public function play(...rest):void {
            if(_debug)
                log("play hit: " + rest.join());

            if(!disable_time_update)
                setupTimeMonitor();

            if(enable_info_update)
                setupInfoUpdater();

            super.play.apply(null, rest);
        }

        public function getTimeFormatted(separator:String = ":", display_milliseconds:Boolean = false):String {
            return TimeCalculator.getTimeOut(display_milliseconds ? time : uint(time), separator);
        }

        public function onCuePoint(info:Object):void {
            if(_ext_client["onCuePoint"])
                _ext_client["onCuePoint"](info);

            dispatchEvent(new ParamEvent(ONCUEPOINT, false, false, info));
        }

        public function onMetaData(info:Object):void {
            //used to allow the app to continue to work if a client.onMetaData isn't specified
            _metaData = info;

            if(_ext_client["onMetaData"])
                _ext_client["onMetaData"](info);

            dispatchEvent(new ParamEvent(ONMETADATA, false, false, info));
        }

        public function publishClose():void {
            if(_debug)
                log("publishClose hit");

            _dispose = false;
            bufferMonitorTimer.start();
        }

        public function publishDispose():void {
            if(_debug)
                log("publishDispose hit");

            _dispose = true;
            bufferMonitorTimer.start();
        }

        private function disconnectSources():void {
            attachAudio(null);
            attachCamera(null);
        }

        private function initListeners():void {
            if(_listener_initd)
                return;
            _listener_initd = true;

            addEventListener(NetStatusEvent.NET_STATUS, handleNetstatus);
        }

        private function initVars():void {
            _closed = false;
            _listener_initd = false;
            _is_paused = false;
            _is_playing = false;
            _is_publishing = false;
        }

        private function killInfoUpdater():void {
            if(_nsInfoTimer) {
                _nsInfoTimer.stop();
                _nsInfoTimer = null;
            }
        }

        private function killTimeMonitor():void {
            if(_timeMonitorTimer) {
                _timeMonitorTimer.stop();
                _timeMonitorTimer = null;
            }
        }

        private function killTimers():void {
            if(_bufferMonitorTimer) {
                _bufferMonitorTimer.stop();
                _bufferMonitorTimer = null;
            }

            killInfoUpdater();
            killTimeMonitor();
        }

        private function setupInfoUpdater():void {
            if(_nsInfoTimer)
                return;

            _nsInfoTimer = new Timer(_ns_info_rate);
            _nsInfoTimer.addEventListener(TimerEvent.TIMER, function (e:TimerEvent):void {
                if(!netconnection || !netconnection.connected) {
                    killInfoUpdater();
                    return;
                }

                if(info)
                    dispatchEvent(new ParamEvent(NETSTREAM_INFO_UPDATE, false, false, format_netstream_info ? formatNetStreamInfo(info) : info));
            });
            _nsInfoTimer.start();
        }

        private function setupTimeMonitor():void {
            if(_timeMonitorTimer)
                return;

            _timeMonitorTimer = new Timer(100);
            _timeMonitorTimer.addEventListener(TimerEvent.TIMER, function (e:TimerEvent):void {
                if(_time != time) {
                    _time = time;
                    dispatchEvent(new ParamEvent(NETSTREAM_TIME_UPDATE, false, false, time));
                }
            });
            _timeMonitorTimer.start();
        }

        protected function handleNetstatus(e:NetStatusEvent):void {
            if(_debug)
                log(e.info.code);

            switch(e.info.code) {
                case NETSTREAM_BUFFER_EMPTY:
                    _is_buffering = is_playing || is_publishing || is_paused;
                    break;
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
                    _is_buffering = false;
                    break;
                case NETSTREAM_RECORD_START:
                    _is_recording = true;
                    break;
                case NETSTREAM_RECORD_STOP:
                    _is_recording = false;
                    break;
                case NETSTREAM_PUBLISH_BADNAME:
                case NETSTREAM_UNPUBLISH_SUCCESS:
                    _is_buffering = false;
                    _is_publishing = false;
                    _is_recording = false;
                    break;
                case NETSTREAM_PUBLISH_START:
                    _is_publishing = true;
                    break;
            }
        }
    }
}
