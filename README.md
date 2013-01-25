netstreamsmart
==============

An extension of the native netstream class that will better handle cache emptying and is backwards compatible with version of flash that had buffer monitoring issues.

Some version of the flash player incorrectly removed buffer notifications which would break applications that relied on this. This class will automate the buffer emptying and notification of the buffer empty.

It will automatically detach any camera or microphone source from the netstream, allow it to empty, then report when it has emptied and close the netstream.

This class may also grow to encompass more use cases for things that are boiler plate code for a netstream setup, teardown, and monitoring. Please let me know if there is anything that would really help in your everyday useage.