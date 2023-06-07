package testunit;

/**
 * ...
 * @author Yves Scherdin
 */
class BasicTestUnit
{
	private var numTests:Int = 0;
	private var numFails:Int = 0;
	
	public var loggingMethod(default, default):Dynamic->Void;
	
	public function new() 
	{
		
	}
	
	public function start():Void
	{
		numTests = 0;
		numFails = 0;
	}
	
	public function finish():Void
	{
		log("-----------------------------------");
		log("FINISHED " + (numFails > 0 ? " ... with " + numFails + " error/s." : " ... ALL FINE!"));
		//log("OKAY : " + (numTests-numFails) + "/" + numTests);
		//log("FAILS: " + numFails + "/" + numTests);
	}
	
	public function assertExists(note:String, node:Dynamic, valueName:String):Bool
	{
		if (Reflect.hasField(node, valueName))
			return noteSuccess(note);
		else
			return noteError(note);
	}
	
	public function assertNonExistence(note:String, node:Dynamic, valueName:String):Bool
	{
		if (!Reflect.hasField(node, valueName))
			return noteSuccess(note);
		else
			return noteError(note);
	}
	
	public function assertType(note:String, node:Dynamic, type:Class<Dynamic>):Bool
	{
		if (Type.getClassName(node) == Type.getClassName(type))
			return noteSuccess(note);
		else
			return noteError(note);
	}
	
	public function assertEqual(note:String, actualValue:Dynamic, expectedValue:Dynamic):Bool
	{
		if (actualValue == expectedValue)
			return noteSuccess(note);
		else
			return noteError(note);
	}
	
	private function noteSuccess(note:String):Bool
	{
		numTests++;
		log(numTests +". " + note + ": ... " + "OKAY");
		return true;
	}
	
	private function noteError(note:String):Bool
	{
		numTests++;
		numFails++;
		log(numTests +". " + note + ": ... " + "FAILED");
		return false;
	}
	
	
	private function log(text:String):Void
	{
		if (loggingMethod != null)
			loggingMethod(text);
			
		trace(text);
	}
	
}