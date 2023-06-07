package tools;
import flash.display.DisplayObjectContainer;
import flash.display.Stage;
import flash.geom.Rectangle;
import flash.text.TextField;

/**
 * ...
 * @author Yves Scherdin
 */
class CustomLogger
{
	static private var logger:TextField;
	
	static public function init(container:DisplayObjectContainer, location:Rectangle):Void
	{
		logger = new TextField();
		container.addChild(logger);
		
		logger.x = location.x;
		logger.y = location.y;
		logger.width = location.width;
		logger.height = location.height;
	}
	
	static public function log(d:Dynamic):Void
	{
		if (logger.length == 0)
			logger.text = Std.string(d);
		else
			logger.appendText("\n" + d);
	}
}