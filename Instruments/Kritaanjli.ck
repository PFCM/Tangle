//type=KRITAANJLI
// ^^^^ this is key
/***********************************************************************
Code for Robot Network -- needs a cool name

by Paul Mathews
indebted to code by Ness Morris and Bruce Lott


Victoria University Wellington, 
School of Engineering and Computer Science

***********************************************************************
File: Kritaanjli.ck
Desc: specific code for Kritaanjli, the harmonium. Requires that the
motor for the bellows be shut off when no notes are playing.
Essentially a wrapper around Jim Murphy and Ajay Kapur's Harmonium_v02 code

Adds a partially-realised staccato mode.
***********************************************************************/

// contains very much code from Ajay Kapur and Jim Murphy 2012
public class Kritaanjli extends MidiInstrument
{
    false => do_delay;
    0 => int _polyphony; // how many notes are on 
    Event noteOff;       // notify other shreds if noteoff
    0 => int _doMotor;   // used to stop explicit setting of motor speed when it shouldn't go
    1::second => dur _motorDelay; // max time we can wait
    0 => int staccato;
    
    [45,44,30,31,29,32,38,43,33,37,35,34,28,27,26,25,24,36,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0] @=> int actualNotes[];
    
    MidiMsg msg; 
    
    // override the init so MidiInstrument doesn't try read this file
    // it now our responsibility to ensure transform_table gets
    // something for the default messages or we might crash stuff
    fun int init( OscRecv recv, FileIO file )
    {
        "Kritaanjli" => name;
        
        // add nonstandard staus byte so that noteoff gets set up in client
        128 => nonstandard_statusbytes["/Kritaanjli/noteoff,ii"];
        
        // set MIDI port — use chuck ——probe to find the right one (can be a string)
        // need to check if this succeeds - if it fails then we are in trouble and should return false
        
        if ( !setMidiPort( "KarmetiK_Kritaanjli" ) )
            return false;
        //setMidiPort(1);
        ["/Kritaanjli/note,ii", "/Kritaanjli/control,ii", "/Kritaanjli/noteoff,ii"] @=> string names[];
        return _init( recv, names);
    }
    
    // called when a note comes in
    fun void handleMessage( OscEvent event, string addrPat )
    { 
        //chout <= "[Kritaanjli] " <= addrPat <= IO.nl();
        // unpack the data
        // if it isn't ii it will complain here
        event.getInt() => int d1;
        event.getInt() => int d2;
        if ( addrPat == "/Kritaanjli/note,ii" )
        {
            // turn on solenoid
            // double check range
            if ( (d1 >= 48) && (d1 <= 48 + actualNotes.cap()-1))
            {
                if(staccato == 0){
                    _outputMidi( 144, actualNotes[d1-48], d2 );
                    _polyphony++;
                    1 => _doMotor; // can do motor with > 0 notes
                }
                if(staccato == 1){
                    spork ~ _staccatoPlayer();
                }
            }
        }
        else if ( addrPat == "/Kritaanjli/noteoff,ii" )
        {
            // turn off solenoid
            // double check range
            if ( (d1 >= 48) && (d1 <= 48 + actualNotes.cap()-1) )
            {
                _outputMidi( 144, actualNotes[d1-48], 0 );
                if (_polyphony > 0)
                    _polyphony--;
                
                // separate check so that it actually works
                if (_polyphony <= 0)
                    spork~_watchdog();
            }
        }
        else if ( addrPat == "/Kritaanjli/control,ii" )
        {
            // motor control cc7
            if ( d1 == 7 )
            {
                if ( _doMotor )
                {
                    _outputMidi(145,0,d2);
                }
                else
                {
                    _outputMidi(145,0,0); // make sure
                }
            }   
            else if ( d1 == 123 )
            {
                chout <= "stop" <= IO.nl();
                // stop message
                0 => _doMotor;
                0 => _polyphony;
                _outputMidi(145,0,0);
            }
            
            //If a CC 10 arrives, do a staccato note.
            else if (d1 == 10)
            {
                if (d2 > 100){
                    1 => staccato;
                }
                else{
                    0 => _doMotor;
                    0 => staccato;
                }
            }
        }
        else
            cherr <= "[Kritaanjli] Unkown message: " <= addrPat <= IO.nl();
        
        chout <= _polyphony <= " : " <= _doMotor <= IO.nl();
    }
    
    fun void _outputMidi( int a, int b, int c )
    {
        a => msg.data1;
        b => msg.data2;
        c => msg.data3;
        mout.send(msg);
    }
    
    //This pre-charges the bellows before actuating key
    fun void _stacattoPlayer(){
        _outputMidi(145,0,127);
        400::ms => now;
        _outputMidi( 144, actualNotes[d1-48], d2 );
    }
    
    fun void _watchdog()
    {
        now => time start;
        
        while ( now - start < _motorDelay )
        {
            if ( _polyphony > 0 )
                me.exit();
            1::samp => now;
            <<<"still alive">>>;
        }
        // if we make it here without exiting, bellows need to stop
        0 => _doMotor;
        _outputMidi(145,0,0);
        chout <= "watchdog stop" <= IO.nl();
    }
}