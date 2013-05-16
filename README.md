netstreamsmart
==============

An extension of the native netstream class that will better handle cache emptying and is backwards compatible with version of flash that had buffer monitoring issues.

Some version of the flash player incorrectly removed buffer notifications which would break applications that relied on this. This class will automate the buffer emptying and notification of the buffer empty.

It will automatically detach any camera or microphone source from the netstream, allow it to empty, then report when it has emptied and close the netstream.

It has an event,BUFFER_EMPTIED, that fires to notify the user of a buffer empty success.

Public properties that can be set:
* buffer_empty_wait_limit: a uint property defining the number of seconds that the class will wait before firing off the buffer empty event. The default is 0 which means it will wait indefinitely for the netstream buffer to empty

USAGE:
It's a simple use case really.. just use it as you would the built in NetStream class. 

To shutdown the netstream you would call the publishClose method to have it shutdown after a buffer empty or the finalizeClose to have it shutdown immediately and clean up the timer.

For example:
```ActionScript
var nc:NetConnection;
var nss:NetStreamSmart = new NetStreamSmart(nc);

to close:
nss.publishClose(); //will let the buffers empty to the server naturally then close
nss.close(); //will immediately disconnect sources and close the netstream
```