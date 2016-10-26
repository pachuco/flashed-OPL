package 
{
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.utils.setTimeout;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;

import nukedOPL.OPL3emu;
//import uk.msfx.utils.tracing.fp10.Tr;

public class NoteTest 
{
    private var BUFLEN:int = 4096;
    private var SAMPRATE:int = 44100;
    
    private var audioOut:Sound;
    private var sc:SoundChannel;
    
    private var chippy:OPL3emu;
    
    public function NoteTest() 
    {
        chippy = new OPL3emu(SAMPRATE);
        audioOut = new Sound();
        audioOut.addEventListener(SampleDataEvent.SAMPLE_DATA, audioLoop);
        sc = audioOut.play();
        
        play_note();
    }
    
    private function stop_note():void {
        chippy.WriteReg(0xB0, 0x11);
    }
    
    private function play_note():void {
        var i:int;
        var p:Vector.<int> = Vector.<int>([
            0x0020, 0x0003,
            0x0040, 0x0010,
            0x0060, 0x0020,
            0x0080, 0x0075,
            0x00A0, 0x0098,
            0x0023, 0x0001,
            0x0043, 0x0000,
            0x0063, 0x00F0,
            0x0083, 0x0070,
            0x00C0, 0x000A,
            0x00B0, 0x0031,
            
            0x8000, 0x0000
        ]);
        /*
         |     REGISTER     VALUE     DESCRIPTION
         |        20          01      Set the modulator's multiple to 1
         |        40          10      Set the modulator's level to about 40 dB
         |        60          F0      Modulator attack:  quick;   decay:   long
         |        80          77      Modulator sustain: medium;  release: medium
         |        A0          98      Set voice frequency's LSB (it'll be a D#)
         |        23          01      Set the carrier's multiple to 1
         |        43          00      Set the carrier to maximum volume (about 47 dB)
         |        63          F0      Carrier attack:  quick;   decay:   long
         |        83          77      Carrier sustain: medium;  release: medium
         |        B0          31      Turn the voice on; set the octave and freq MSB
        */
        for(i=0;;) {
            var reg:uint = p[i++];
            var dat:uint = p[i++] & 0xFF;
            if(reg&0x8000) break;
            chippy.WriteReg(reg, dat);
        }
        
        setTimeout(stop_note, 1000);
        setTimeout(play_note, 2000);
    }
    
    private function audioLoop(event:SampleDataEvent):void {
        chippy.GenerateStream(event.data, BUFLEN);
    }
        
}

}