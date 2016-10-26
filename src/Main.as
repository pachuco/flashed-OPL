package
{
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.display.Sprite;
import flash.events.Event;
//import uk.msfx.utils.tracing.fp10.TrConsole;

/**
 * ...
 * @author 
 */
public class Main extends Sprite 
{
    [Embed(source="mus/test.dro", mimeType="application/octet-stream")]
    private var Song:Class;
    
    public function Main() 
    {
        if (stage) init();
        else addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    private function init(e:Event = null):void 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        // entry point
        //addChild(new TrConsole());
        
        new DRO2Test(new Song() as ByteArray);
        //new NoteTest();
    }
    
}

}