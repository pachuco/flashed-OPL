package 
{
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.events.SampleDataEvent;
import flash.media.Sound;
import flash.media.SoundChannel;

import nukedOPL.OPL3emu;
//import uk.msfx.utils.tracing.fp10.Tr;

public class DRO2Test 
{
    private var BUFLEN:int = 4096;
    private var SAMPRATE:int = 44100;
    
    private var audioOut:Sound;
    private var sc:SoundChannel;
    
    private var songData:ByteArray;
    private var chippy:OPL3emu;
    
    //Header
    public var
        h_id:String,        //char[9]
        h_versionHigh:uint, //uint16
        h_versionLow:uint,  //uint16
        h_commands:int,     //int32
        h_msec:int,         //int32
        h_hardware:uint,    //uint8
        h_format:uint,      //uint8
        h_compression:uint, //uint8
        h_delay257:uint,    //uint8
        h_delayShift:uint,  //uint8
        h_tableSize:uint;   //uint8
        
    private var table:ByteArray;
    private var dataStart:int;
    private var seekpos:int;
    private var seek:int = 0;
    
    public function DRO2Test(data:ByteArray)
    {
        data.endian = Endian.LITTLE_ENDIAN;
        data.position = 0;
        
        //read header
        h_id = data.readMultiByte(8, "us-ascii"); if(h_id != 'DBRAWOPL') return;
        h_versionHigh = data.readUnsignedShort();
        h_versionLow = data.readUnsignedShort();
        h_commands = data.readInt();
        h_msec = data.readInt();
        h_hardware = data.readUnsignedByte();
        h_format = data.readUnsignedByte();
        h_compression = data.readUnsignedByte();
        h_delay257 = data.readUnsignedByte();
        h_delayShift = data.readUnsignedByte();
        h_tableSize = data.readUnsignedByte();
        
        table = new ByteArray();
        data.readBytes(table, 0, h_tableSize);
        songData = data;
        dataStart = data.position;
        seekpos = 9420;
        
        //start the fun
        chippy = new OPL3emu(SAMPRATE);
        audioOut = new Sound();
        audioOut.addEventListener(SampleDataEvent.SAMPLE_DATA, audioLoop);
        sc = audioOut.play();
    }
    
    private var remainder:int = 0;
    private function audioLoop(event:SampleDataEvent):void {
        var sampsDone:Number = 0;
        var delay:int = 0;
        var raw:uint = h_delayShift, val:uint = 1;
        while (sampsDone < BUFLEN) {
            if (remainder) {
                remainder--;
                chippy.GenerateStream(event.data, 44);
                sampsDone += 44;
            } else {
                do {
                    //if (songData.position >= dataStart + 9550 * 2) songData.position = dataStart;
                    if (!songData.bytesAvailable) songData.position = dataStart;
                    raw = songData.readUnsignedByte();
                    val = songData.readUnsignedByte();
                    if ( raw == h_delay257 ) {
                        remainder = val + 1;
                    } else if( raw == h_delayShift ) {
                        remainder = (val + 1) << 8;
                    } else {
                        //----------------------
                        remainder = 0;
                        var index:uint, reg:uint;
                        index = raw>>7;
                        reg = table[raw&127];
                        //----------------------
                        if (index) reg += 0x100;
                        chippy.WriteReg(reg, val);
                    }
                    if (songData.position >= dataStart + seekpos*2) seek = 0;
                } while (seek);
            }
        }
    }
    
    private function audioLoopTest(event:SampleDataEvent):void {
        var sampsDone:Number = 0;
        var delay:Number = 0;
        var raw:uint, val:uint;
        
        while (sampsDone < BUFLEN) {
            if (!songData.bytesAvailable) songData.position = dataStart;
            raw = songData.readUnsignedByte();
            val = songData.readUnsignedByte();
            if ( raw == h_delay257 ) {
                delay = (val +1) * 44.1;
            } else if( raw == h_delayShift ) {
                delay = ((val + 1)<<8) * 44.1;
            } else {
                //----------------------
                delay = 0;
                var index:uint, reg:uint;
                index = raw>>7;
                reg = table[raw&127];
                //----------------------
                if (index) reg += 0x100;
                chippy.WriteReg(reg, val);
            }
            chippy.GenerateStream(event.data, 400);
            sampsDone+= 400;
        }
    }
        
}

}