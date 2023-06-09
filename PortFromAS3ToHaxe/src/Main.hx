package;

import flash.Lib;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.net.URLLoader;
import flash.net.URLRequest;
import testunit.BasicTestUnit;
import tools.CustomLogger;

/**
 * ...
 * @author Yves Scherdin
 */
class Main 
{
	
	static function main() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// Entry point
		
		CustomLogger.init(stage, new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
		
		testDataParsing("cfg/data.cfg", testDataCfg);
		testDataParsing("cfg/gui.cfg", testGuiCfg);
		testDataParsing("cfg/integers.cfg", testIntegersCfg);
		testDataParsing("cfg/floats.cfg", testFloatsCfg);
	}
	
	static private function testDataParsing(fileURL:String, testMethod:Dynamic->Void):Void
	{
		var textLoader:URLLoader = new URLLoader(new URLRequest(fileURL));
		textLoader.addEventListener(Event.COMPLETE, function handleLoadingComplete(e:Event):Void 
		{
			//trace(e.target.data);
			var rawData:String = Std.string(e.target.data);
			var data:Dynamic = YSON.parseData(rawData);
			
			testMethod(data);
		});
	}
	
	static private function testDataCfg(data:Dynamic)
	{
		var test:BasicTestUnit = new BasicTestUnit();
		test.loggingMethod = CustomLogger.log;
		
		test.start();
		
		test.assertExists("data.games exists", data, "games");
		test.assertExists("data.games.names exists", data.games, "names");
		test.assertExists("data.games.names.delays exists", data.games.names, "delays");
		test.assertExists("data.games.names.delays.right exists", data.games.names.delays, "right");
		test.assertExists("data.games.names.delays.wrong exists", data.games.names.delays, "wrong");
		test.assertExists("data.games.chunks exists", data.games, "chunks");
		
		test.assertExists("data.alphabet exists", data, "alphabet");
		test.assertEqual("data.alphabet[0] == 'alpha'", data.alphabet[0], "alpha");
		test.assertEqual("data.alphabet[2] == 'gamma'", data.alphabet[2], "gamma");
		test.assertEqual("last element in data.alphabet == 'omega'", data.alphabet[Std.int(data.alphabet.length)-1], "omega");
		test.assertEqual("data.alphabet.length == 24", data.alphabet.length, 24);
		
		test.assertExists("data.confusion exists", data, "confusion");
		test.assertExists("data.confusion.small exists", data.confusion, "small");
		test.assertEqual("data.confusion.small[0][0] == gamma", data.confusion.small[0][0], "gamma");
		test.assertEqual("data.confusion.small[6][1] == xi", data.confusion.small[6][1], "xi");
		test.assertEqual("data.confusion.big[0][1] == omicron", data.confusion.big[0][1], "omicron");
		
		test.finish();
	}
	
	static private function testGuiCfg(data:Dynamic)
	{
		var test:BasicTestUnit = new BasicTestUnit();
		test.loggingMethod = CustomLogger.log;
		
		test.start();
		
		test.assertExists("data.specialBarStates exists", data, "specialBarStates");
		test.assertExists("data.barModes exists", data, "barModes");
		test.assertExists("data.fields exists", data, "fields");
		test.assertExists("data.help exists", data, "help");
		test.assertExists("data.dialogs exists", data, "dialogs");
		
		test.assertExists("data.specialBarStates exists", data, "specialBarStates");
		test.assertEqual("data.specialBarStates[0] == 'learn'", data.specialBarStates[0], "learn");
		test.assertEqual("data.specialBarStates[5] == 'none'", data.specialBarStates[5], "none");
		
		test.assertExists("data.barModes.mainMenu exists", data.barModes, "mainMenu");
		test.assertExists("data.barModes.options exists", data.barModes, "options");
		test.assertEqual("data.barModes.gameResult.special == 'alert'", data.barModes.gameResult.special, "alert");
		test.assertEqual("data.barModes.options.top == 'title'", data.barModes.options.top, "title");
		
		test.assertEqual("data.fields.contextMenu.ingame.items[0] == 'options'", data.fields.contextMenu.ingame.items[0], "options");
		test.assertEqual("data.fields.contextMenu.ingame.items.length == 4", data.fields.contextMenu.ingame.items.length, 4);
		
		test.assertEqual("data.help.general.total == 2", data.help.general.total, 2);
		test.assertEqual("data.help.game_names.total == 2", data.help.game_names.total, 2);
		
		test.assertEqual("data.dialogs.restart == 'confirm'", data.dialogs.restart, "confirm");
		test.assertEqual("data.dialogs.length == 'confirmList'", data.dialogs.length, "confirmList");
		test.assertNonExistence("data.dialogs.choose", data.dialogs, "choose");
		
		test.finish();
	}
	
	
	static private function testIntegersCfg(data:Dynamic)
	{
		var test:BasicTestUnit = new BasicTestUnit();
		test.loggingMethod = CustomLogger.log;
		
		test.start();
		
		test.assertTypeInt("is int: simple.value0", data.simple.value0);
		test.assertTypeInt("is int: simple.value1", data.simple.value1);
		test.assertTypeInt("is int: simple.value2", data.simple.value2);
		test.assertTypeInt("is int: simple.value3", data.simple.value3);
		
		test.assertTypeInt("is int: commentA.value0", data.commentA.value0);
		test.assertTypeInt("is int: commentA.value1", data.commentA.value1);
		test.assertTypeInt("is int: commentA.value2", data.commentA.value2);
		test.assertTypeInt("is int: commentA.value3", data.commentA.value3);
		
		test.assertTypeInt("is int: commentB.value0", data.commentB.value0);
		test.assertTypeInt("is int: commentB.value1", data.commentB.value1);
		test.assertTypeInt("is int: commentB.value2", data.commentB.value2);
		test.assertTypeInt("is int: commentB.value3", data.commentB.value3);
		
		test.assertTypeInt("is int: commentC.value0", data.commentC.value0);
		test.assertTypeInt("is int: commentC.value1", data.commentC.value1);
		test.assertTypeInt("is int: commentC.value2", data.commentC.value2);
		test.assertTypeInt("is int: commentC.value3", data.commentC.value3);
		
		test.assertTypeInt("is int: commentD.value0", data.commentD.value0);
		test.assertTypeInt("is int: commentD.value1", data.commentD.value1);
		test.assertTypeInt("is int: commentD.value2", data.commentD.value2);
		test.assertTypeInt("is int: commentD.value3", data.commentD.value3);
		
		test.finish();
	}
	
	static private function testFloatsCfg(data:Dynamic)
	{
		var test:BasicTestUnit = new BasicTestUnit();
		test.loggingMethod = CustomLogger.log;
		
		test.start();
		
		test.assertTypeFloat("is float: simple.value0", data.simple.value0);
		test.assertTypeFloat("is float: simple.value1", data.simple.value1);
		test.assertTypeFloat("is float: simple.value2", data.simple.value2);
		test.assertTypeFloat("is float: simple.value3", data.simple.value3);
		
		test.assertTypeFloat("is float: commentA.value0", data.commentA.value0);
		test.assertTypeFloat("is float: commentA.value1", data.commentA.value1);
		test.assertTypeFloat("is float: commentA.value2", data.commentA.value2);
		test.assertTypeFloat("is float: commentA.value3", data.commentA.value3);
		
		test.assertTypeFloat("is float: commentB.value0", data.commentB.value0);
		test.assertTypeFloat("is float: commentB.value1", data.commentB.value1);
		test.assertTypeFloat("is float: commentB.value2", data.commentB.value2);
		test.assertTypeFloat("is float: commentB.value3", data.commentB.value3);
		
		test.assertTypeFloat("is float: commentC.value0", data.commentC.value0);
		test.assertTypeFloat("is float: commentC.value1", data.commentC.value1);
		test.assertTypeFloat("is float: commentC.value2", data.commentC.value2);
		test.assertTypeFloat("is float: commentC.value3", data.commentC.value3);
		
		test.assertTypeFloat("is float: commentD.value0", data.commentD.value0);
		test.assertTypeFloat("is float: commentD.value1", data.commentD.value1);
		test.assertTypeFloat("is float: commentD.value2", data.commentD.value2);
		test.assertTypeFloat("is float: commentD.value3", data.commentD.value3);
		
		test.finish();
	}
}