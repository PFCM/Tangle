# Tangle

Tangle is a suite of software allowing musical instruments to be accessed over a network. For more details, see the docs folder. Tangle was initiated in 2014 by Paul Mathews at Victoria Univesity of Wellington.

### To run the server:
(from the root project directory)
	`%> chuck src/Master.ck`
   

### To run the client (you only need Client.ck on the client machine)
  
	%> chuck Client.ck:server=XXX.XXX.XXX.XXX:self=YYY.YYY.YYY.YYY
  

There are a bunch of other arguments you can give ``Client.ck`` to specify MIDI input (``midi=``),
send/receive ports (``out=,in=``), whether to send some test patterns (``test=comma,separated,list``)
or whether to initiate latency calibration (``delay=on,off,or,list,of,names``).

### To add new instruments:
if it just needs MIDI, generic MIDI instruments can be defined in simple text files, examples are in `$root/Instruments` or `$root/Instruments/Unconnected`. Also see InstrumentFileSpec.pdf in docs for an outrageously long- winded explanation.
      
Essentially all you need is 
`type=MIDI`
`name=SomeName`

and an instrument will be made listening to note on and control change.

### if it needs more complex logic
* subclass `Instrument` or one of its descendants (`MidiInstrument`, `MultiStringInstrument`).

* Override `init()`. Make sure it returns true if successful. Make sure it calls `_init()` with a list of any special OSC patterns you want to listen for.
       
* Override `handleMessage( OscEvent, string )` - this gets called by the OSC listeners whenever they receive a message. You get the message pattern to see what it was and the event to get the values.

If you make a new `.ck` with an instrument in it, as long as it is in the Instruments folder or any subdirectory, `Master.ck` will find it and add it. The only changes to make are to  `Server.ck` so it knows about the new kind of instrument. Should be commented enough to find (I hope). 
