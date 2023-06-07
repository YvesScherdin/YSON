package yves.net;

import flash.errors.Error;

/**
 * @version 0.3.9
 * @author  Yves Scherdin
 * 
 * ChangeLog:
 * 
 * - 21.02.2013 (0.3.9) - bugfix: removed line comment end-parsing error
 * - 07.02.2013 (0.3.8) - bugfix for being numbers parsed as string; also negative numbers suported; outsourced DataTable-Support; 
 * - 26.07.2012  -  better error reporting on addValue();  Last Key is logged in error message
 * - 23.07.2012  -  better error reporting on addValue();  existence of current array is also checked. Throws an error if not.
 * - 21.07.2012  -  better error reporting on addValue();  existence of current object is also checked.
 * - 26.03.2012
 * 
 * 
 * Supports following:
 * - Normal Parsing.
 * - Table-Parsing (yves.data.DataTable).
 * - Writing Objects to YSON-format.
 * - escaping quotes (0.3.7)
 * 
 * KNOWN BUGS:
 * - avoid '//'-commentars when using online - they may cause parsing-errors
 * 	// commentar
 * - avoid multiple properties in one object seperated by tabs ("\t"); use empty_Spaces (" ") instead
 *  property_1="one"<TAB>property_2="two"   <--- errors
 * FOUND BUGS in code:  multiple-line-comments:    "/n" instead of "\n"
 */
class YSON
{
	private var CurrObject(get, never):Dynamic;
	private var CurrArray(get, never):Array<Dynamic>;

	// static fields and mehods
	static private var STRICT_ERROR_REPORT:Bool = true;
	
	static public var allowVerbose:Bool;
	
	
	static private var arr_numbers:Array<Dynamic> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
	static private var arr_no_key:Array<Dynamic> = [" ", "\n", "\r", "\t", ",", ";", ".", "-", "<", ">", "|", "+"];
	static private var arr_ignore_key:Array<Dynamic> = [" ", "\n", "\r", ",", ";", "\t", "[", "]", "{", "}"];
	static private var arr_ignore_value:Array<Dynamic> = [" ", "\n", "\r", "\t", "="];
	static private var valueTypes:Array<Dynamic> = ["none", "string", "object", "number", "int", "boolean"];
	
	
	static inline private var ESCAPE_CHAR:String = "\\";
	
	
	
	
	
	
	static public function parseData(source_str:String):Dynamic
	{
		return new YSON().parseSource(source_str);
	}
	
	
	
	static private function cutCharFrom(char:String, source_str:String):String
	{
		var a:Array<Dynamic> = source_str.split(char);
		return concatStrings(a);
	}
	
	static private function cloneArray(a:Array<Dynamic>):Array<Dynamic>
	{
		var b:Array<Dynamic> = [];
		var i:Int = 0;
		while (i < a.length)
		{
			b[i] = a[i];
			i++;
		}
		
		return b;
	}
	
	static private function getAmountIn(pattern_str:String, source_str:String, startIndex:Int = 0, holder:Int = 0):Int
	{
		var i:Int = source_str.indexOf(pattern_str, startIndex);
		if (i == -1)
		{
			return holder;
		}
		else
		{
			return getAmountIn(pattern_str, source_str, ++i, ++holder);
		}
	}
	
	static private function concatStrings(strArr:Array<Dynamic>):String
	{
		var str:String = "";
		var i:Int = 0;
		while (i < strArr.length)
		{
			str += strArr[i];
			i++;
		}
		return str;
	}
	
	static private function isOneOfThose(stuff:Dynamic, arr:Array<Dynamic>):Bool
	{
		var i:Int = 0;
		while (i < arr.length)
		{
			if (stuff == arr[i])
			{
				return true;
			}
			i++;
		}
		return false;
	}
	
	static private function isCharNumber(char:String):Bool
	{
		return (isOneOfThose(char, ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]));
	}
	
	
	/**
	 * Error report via tracing.
	 * @param	str
	 */
	static private function zui(str:Dynamic):Void
	{
		if (allowVerbose)
		{
			trace(str);
		}
	}
	
	
	
	static private function logError(e:Error):Void
	{
		if (STRICT_ERROR_REPORT)
		{
			throw e;
		}
		else
		{
			zui(e);
		}
	}
	
	
	
	
	// non-static fields and metods
	
	private var hierarchy:Array<Dynamic>;  // objects  
	private var arrayHierarchy:Array<Dynamic>;  // arrays  
	private var hierarchyTypeHistory:Array<Dynamic>;  // stores booleans, true --> object    false --> array  
	
	private var text2parse:String;
	public function getTextSource():String
	{
		return text2parse;
	}
	
	private var data2parse:Dynamic;
	
	private var currSlot:Int;
	private var index_1:Int;
	private var index_2:Int;
	
	private var state_key:Bool;
	private var currKey:String;
	private var currValue:Dynamic;
	private var currValueType:String;
	
	private var isComment:Bool;
	private var isBlockComment:Bool;
	
	private var doubleQuoMarks:Bool;
	private var prevChar:String;

	public function new()
	{
	}
	
	
	// ---- need no constructor ----
	
	
	
	
	public function parseSource(source_str:String):Dynamic
	{
		hierarchy = [];
		arrayHierarchy = [];
		hierarchyTypeHistory = [];
		
		text2parse = source_str;
		data2parse = addObject({});
		
		if (text2parse == null)
		{
			return data2parse;
		}
		
		currSlot = 0;
		index_1 = index_2 = -1;
		currValueType = "none";
		
		isComment = false;
		state_key = true;
		
		// analyze char by char
		while (currSlot < text2parse.length)
		{
			analyze();
			currSlot++;
		}
		
		text2parse = null;
		currKey = null;
		
		return data2parse;
	}
	
	
	
	
	
	private function analyze():Void
	{
		var char:String = text2parse.charAt(currSlot);
		var isLastChar:Bool = currSlot == text2parse.length - 1;
		var isFirstChar:Bool = currSlot == 0;
		
		prevChar = (isFirstChar) ? null:(((text2parse.length > 0)) ? text2parse.charAt(currSlot - 1):null);
		
		var phraseToCheck:String;
		
		
		// check for comment
		if (!isComment)
		// check for start
		{
			
			{
				if (currValueType != "string" && char == "/" && !isLastChar)
				// could a comment start here?
				{
					
					{
						phraseToCheck = text2parse.substr(currSlot, 2);
						
						if (phraseToCheck == "//")
						// line comment found
						{
							
							isComment = true;
							isBlockComment = false;
						}
						else if (phraseToCheck == "/*")
						// block comment found
						{
							
							isComment = true;
							isBlockComment = true;
						}
						
						if (isComment)
						//comment found
						{
							
							// force value-parsing to end
							if (analyzesValue())
							{
								postAddValue();
							}
							
							currSlot++;  // one further step  
							return;
						}
					}
				}
			}
		}// check for end of current comment
		
		else
		{
			
			{
				if (isBlockComment)
				{
					phraseToCheck = text2parse.substr(currSlot - 1, 2);
					if (phraseToCheck == "*/")
					//end of comment found
					{
						
						{
							isComment = false;
						}
					}
				}
				else if (char == "\n" || char == "\r")
				{
					isComment = false;
				}
				
				if (!isComment)
				{  // comment has ended  
					
				}
				return;
			}
		}
		
		
		if (!isWrappedInObject() && state_key)
		{
			state_key = false;
		}
		
		if (state_key)
		// analyze key
		{
			
			{
				if (index_1 == -1)
				// find key start
				{
					
					{
						//if( !isOneOfThose( char,["\n","\r"] ) )
						//zui( "char["+currSlot+"]: " + char );
						if (!isOneOfThose(char, arr_ignore_key))
						{
							index_1 = currSlot;
						}
					}
				}// find key end
				
				else
				{
					
					{
						if (index_2 == -1)
						{
							if (isOneOfThose(char, [" ", "=", "\n", "\r", "\t", "]", "}", "[", "{"]))
							//if( isOneOfThose( char,arr_ignore_key ) )
							{
								
								index_2 = currSlot;
							}
						}
					}
				}
				
				if (index_1 != -1 && index_2 != -1)
				// finally parse key
				{
					
					{
						currKey = parseKey();
						state_key = false;
					}
				}
			}
		}// analyze value
		
		else
		{
			
			{
				if (index_1 == -1)
				// find value start
				{
					
					{
						if (!isOneOfThose(char, arr_ignore_value))
						{
							if (index_1 == -1)
							{
								index_1 = currSlot;
							}
							
							if (prevChar != ESCAPE_CHAR && (char == "'" || char == "\""))
							{
								index_1++;
								currValueType = "string";
								doubleQuoMarks = char == "\"";
							}
							else if (isOneOfThose(char, arr_numbers))
							{
								currValueType = "number";
							}
							else if (char == "[")
							{
								currValue = new Array<Dynamic>();
								currValueType = "array";
								addValue();
							}
							else if (char == "{")
							{
								currValue = {};
								currValueType = "object";
								addValue();
							}
						}
					}
				}// find value end
				
				else
				{
					
					{
						findValueEnd(char);
					}
				}
			}
		}
		
		// check wrapping end
		if (currValueType != "string")
		{
			if (char == "]")
			{
				closeArray();
			}
			else if (char == "}")
			{
				closeObject();
			}
		}
	}
	
	
	
	
	private function analyzesValue():Bool
	{
		return (index_1 != -1 && !state_key);
	}
	
	private function findValueEnd(char:String):Void
	{
		if (currValueType == "string")
		{
			if (prevChar != ESCAPE_CHAR && (char == "'" || char == "\""))
			{
				if (doubleQuoMarks == (char == "\""))
				{
					postAddValue();
				}
			}
		}// check for being negative number
		
		else
		{
			
			if (currSlot - index_1 == 1 && prevChar == "-" && isOneOfThose(char, arr_numbers))
			{
				currValueType = "number";
			}
			
			if (isOneOfThose(char, [" ", "\r", "\n", "[", "{", "]", "}", "\t"])
				|| (!isWrappedInObject() && isOneOfThose(char, [",", "]", "}"])))
			{
				postAddValue();
			}
			else if (currValueType == "number")
			{
				if (!isCharNumber(char) && char != ".")
				{
					currValueType = "none";
				}
			}
		}
	}
	
	private function postAddValue(offset_2:Int = 0):Void
	{
		index_2 = as3hx.Compat.parseInt(currSlot + offset_2);
		currValue = parseSubString();
		//trace( "postAddValue", currValue );
		addValue();
	}
	
	private function addValue():Void
	{
		if (isWrappedInObject())
		{
			if (currKey == "")
			{
				logError(new Error("YSON::addValue() - Tried to add a value with an empty key"));
			}
			else if (CurrObject == null)
			{
				logError(new Error("YSON::addValue() - Cannot add value to an empty object"));
			}
			else
			{
				Reflect.setField(CurrObject, currKey, currValue);
			}
			
			state_key = true;
		}
		else
		{
			if (CurrArray == null)
			{
				throw new Error("YSON-Parsing-Error: Current Array is null. Last Key: " + currKey);
			}
			zui("arr[" + CurrArray.length + "] = " + currValue + "  <" + currValueType + ">");
			CurrArray.push(currValue);
		}
		
		// update hierarchy if neccessary
		if (currValueType == "array")
		{
			addArray(currValue);
		}
		else if (currValueType == "object")
		{
			addObject(currValue);
		}
		
		checkHierarchy();
		
		index_1 = index_2 = -1;
		currValueType = "none";
	}
	
	
	private function check4End():Bool// WIP < - - - - -
	
	{
		
		if (isWrappedInObject())
		{
			if (text2parse.charAt(currSlot) == "}")
			{
			}
		}
		return false;
	}
	
	
	private function getCharIndexBefore(char:String = null, except:Array<Dynamic> = null):Int
	{
		if ((char == null && except == null) || (char != null && except != null))
		{
			return currSlot;
		}
		
		var i:Int;
		if (char != null)
		{
			i = as3hx.Compat.parseInt(currSlot - 1);
			while (i >= 0)
			{
				if (text2parse.charAt(i) == char)
				{
					break;
				}
				i--;
			}
		}
		if (except != null)
		{
			i = as3hx.Compat.parseInt(currSlot - 1);
			while (i >= 0)
			{
				if (!isOneOfThose(text2parse.charAt(i), except))
				{
					break;
				}
				i--;
			}
		}
		
		return ++i;
	}
	
	
	private function isWrappedInObject():Bool
	{
		return hierarchyTypeHistory[hierarchyTypeHistory.length - 1];
	}
	
	private function get_CurrObject():Dynamic
	{
		return hierarchy[hierarchy.length - 1];
	}
	
	private function addObject(o:Dynamic):Dynamic
	{
		hierarchy.push(o);
		hierarchyTypeHistory.push(true);
		return CurrObject;
	}
	
	private function closeObject():Void
	{
		zui("closeObject");
		hierarchy.splice(hierarchy.length - 1, 1);
		hierarchyTypeHistory.splice(hierarchyTypeHistory.length - 1, 1);
		checkHierarchy();
	}
	
	private function get_CurrArray():Array<Dynamic>
	{
		return arrayHierarchy[arrayHierarchy.length - 1];
	}
	
	private function addArray(a:Array<Dynamic>):Array<Dynamic>
	{
		arrayHierarchy.push(a);
		hierarchyTypeHistory.push(false);
		return CurrArray;
	}
	
	private function closeArray():Void
	{
		zui("closeArray");
		arrayHierarchy.splice(arrayHierarchy.length - 1, 1);
		hierarchyTypeHistory.splice(hierarchyTypeHistory.length - 1, 1);
		checkHierarchy();
		index_1 = index_2 = -1;
	}
	
	private function checkHierarchy():Void
	{
		state_key = (isWrappedInObject());
	}
	
	
	
	
	
	
	private function parseKey():String
	{
		var str:String = text2parse.substring(index_1, index_2);
		index_1 = index_2 = -1;
		return str;
	}
	
	private function parseSubString():Dynamic
	{
		var str:String = text2parse.substring(index_1, index_2);
		index_1 = index_2 = -1;
		
		if (str == "true" || str == "false")
		{
			currValueType = "boolean";
		}
		
		if (currValueType == "number")
		{
			if (currValueType == "number" && str.indexOf(".") == -1)
			{
				currValueType = "int";
			}
		}
		
		return parseValue(str, currValueType);
	}
	
	static private function parseValue(str:String, type:String):Dynamic//trace( "parseValue", str, type );
	
	{
		
		switch (type)
		{
			case "int":return as3hx.Compat.parseInt(str);
			case "number":return as3hx.Compat.parseFloat(str);
			case "boolean":return ((str == "true")) ? true:false;
			case "string":return parseString(str);
			case "none":return str;
			default:return null;
		}
	}
	
	
	
	// STRING ANALYZATION POST PROCESS
	static private function parseString(str:String):Dynamic// handle escape chars - tab + newline
	
	{
		
		while (str.indexOf("\\n") != -1)
		{
			str = StringTools.replace(str, "\\n", "\n");
		}
		
		while (str.indexOf("\\t") != -1)
		{
			str = StringTools.replace(str, "\\t", "\t");
		}
		
		// handle escape chars - string identifiers
		while (str.indexOf(ESCAPE_CHAR + "\"") != -1)
		{
			str = str.replace(ESCAPE_CHAR + "\"", "\"");
		}
		
		while (str.indexOf(ESCAPE_CHAR + "'") != -1)
		{
			str = str.replace(ESCAPE_CHAR + "'", "'");
		}
		
		return str;
	}
	
	static public function parseArray(src:String):Array<Dynamic>
	{
		var arr:Array<Dynamic> = [];
		var currSlot:Int = -1;
		var index:Int = -1;
		var isString:Bool = false;
		var doubleQM:Bool = false;
		
		
		
		// get rid of brackets
		if (src.length >= 2)
		{
			src = src.substring(1, src.length - 1);
		}
		
		while (++currSlot < src.length)
		{
			var char:String = src.charAt(currSlot);
			var phrase:String;
			
			if (isString)
			{
				if (isOneOfThose(char, ["\"", "'"]) && (doubleQM == (char == "\"")))
				{
					phrase = src.substring(index + 1, currSlot);
					arr.push(parseString(phrase));
					//trace( "addValue[" + phrase + "]:String||YsonTable" );
					index = -1;
					isString = false;
					continue;
				}
			}
			else if (index == -1)
			// find start of next value
			{
				
				
				// check 4 stuff 2 ignore
				if (isOneOfThose(char, [" ", "\t", "\r", "\n"]))
				{
					continue;
				}
				
				// check 4 empty argument
				
				// check 4 array
				if (char == "[")
				{
					phrase = getPhraseBetween(src, currSlot, "[", "]", true, true);
					arr.push(parseArray(phrase));
					//	trace( "addValue[" + phrase + "]" );
					currSlot += phrase.length;
					continue;
				}
				
				// no array and nothing to ignore, so it must be a value.
				
				// check 4 string
				if (isOneOfThose(char, ["\"", "'"]))
				{
					isString = true;
					doubleQM = char == "\"";
				}
				
				index = currSlot;
				continue;
			}// find end of current value
			
			else
			{
				
				if (isOneOfThose(char, [" ", "\t", "\r", "\n", ","]))
				{
					phrase = src.substring(index, currSlot);
					index = -1;
					arr.push(parseValue(phrase, getTypeOfValue(phrase)));
					//trace( "addValue[" + phrase + "]" );
					continue;
				}
			}
		}
		
		if (index != -1)
		{
			phrase = src.substring(index, currSlot);
			index = -1;
			arr.push(parseValue(phrase, getTypeOfValue(phrase)));
		}
		
		return arr;
	}
	
	static public function getPhraseBetween(src:String, startIndex:Int, start:String, end:String, noticeInterlacing:Bool = false, including:Bool = false):String//trace( "phraseBetween", src, including );
	
	{
		
		var interlacings:Int = 0;
		var i:Int;
		var index:Int = -1;
		
		i = 0;
		while (startIndex + i < src.length)
		{
			var char:String = src.charAt(startIndex + i);
			
			if (char == start)
			{
				if (index == -1)
				{
					index = as3hx.Compat.parseInt(startIndex + i);
				}
				
				interlacings++;
			}
			
			if (index != -1 && char == end)
			{
				interlacings--;
				if (interlacings <= 0)
				{
					if (including)
					{
						return src.substring(index, index + i + 1);
					}
					else
					{
						return src.substring(index + 1, index + i);
					}
				}
			}
			i++;
		}
		
		i--;
		if (including)
		{
			return src.substring(index, index + i + 1);
		}
		else
		{
			return src.substring(index + 1, index + i);
		}
	}
	
	static private function isBoolean(src:String):Bool
	{
		return isOneOfThose(src, ["true", "false"]);
	}
	
	
	
	static private function getTypeOfValue(src:String):String// check 4 boolean
	
	{
		
		if (isBoolean(src))
		{
			return "boolean";
		}
		
		// check 4 number
		var i:Int;
		
		var comma:Bool;
		i = 0;
		while (i < src.length)
		{
			if (!isOneOfThose(src.charAt(i), arr_numbers))
			{
				if (!comma && src.charAt(i) == ".")
				{
					comma = true;
				}
				else
				{
					break;
				}
			}
			i++;
		}
		
		if (i == src.length)
		// src was trawled to the end
		{
			
			{
				if (comma)
				{
					return "number";
				}
				else
				{
					return "int";
				}
			}
		}
		
		return "string";
	}
	
	
	
	// write
	static private var enableFormatting:Bool;
	static private var useSingleQuoMark:Bool;
	static private var tabs:Int;
	static private var strBuffer:String;
	
	/**
	 * Takes only basic data types (Object, Array, Number, int, String). Any other will be coersed to String.
	 * @param	obj					An Object (AMF).
	 * @param	_enableFormatting	False will cause no line breaks and tabs which leads to less readability. Default is true.
	 * @return  					A YSON-parseable String and serialized replica of the param obj.
	 */
	static public function writeData(obj:Dynamic, _enableFormatting:Bool = true, _useSingleQuoMark:Bool = false):String
	{
		enableFormatting = _enableFormatting;
		useSingleQuoMark = _useSingleQuoMark;
		
		writeObject(obj);
		var str:String = strBuffer;
		strBuffer = null;
		return str;
	}
	
	
	
	static private function writeValue(val:Dynamic):Void
	{
		if (val == null)
		{
			writeText("null");
			return;
		}
		
		var str:String = Std.string(val);
		if (Std.is(val, Array))
		{
			writeArray(val);
		}
		else if (Std.string(val) == "[object Object]")
		{
			writeObject(val);
		}
		else
		{
			writeText(prepareValue(val));
		}
	}
	
	static private function prepareValue(val:Dynamic):String
	{
		if (Std.is(val, String))
		// TODO: turn " into \" and check for escaped characters in parse-section
		{
			
			return writwQuotaMark() + val + writwQuotaMark();
		}// number or int (or smthg not really parseable)
		
		else
		{
			
			{
				return Std.string(val);
			}
		}
	}
	
	static private function writwQuotaMark():String
	{
		return (useSingleQuoMark) ? "'":"\"";
	}
	
	static private function isSimpleValue(val:Dynamic):Bool
	{
		return Std.string(val) != "[object Object]" && Std.is(val, Array) == false;
	}
	
	static private function writeArray(a:Array<Dynamic>):Void
	{
		writeText("[");
		tabs++;
		for (element in a)
		{
			writeValue(element);
		}
		tabs--;
		writeText("]");
	}
	
	static private function writeObject(o:Dynamic):Void
	{
		writeText("{");
		tabs++;
		
		for (key in Reflect.fields(o))
		{
			if (isSimpleValue(Reflect.field(o, key)))
			{
				writeText(key + " = " + prepareValue(Reflect.field(o, key)));
			}
			else
			{
				writeText(key + " = ");
				writeValue(Reflect.field(o, key));
			}
		}
		
		tabs--;
		writeText("}");
	}
	
	
	
	static private function writeText(str:String, addBreak:Bool = true):Void
	{
		if (strBuffer == null)
		{
			strBuffer = "";
		}
		
		if (enableFormatting)
		{
			strBuffer += (genString("\t", tabs));
		}
		
		strBuffer += str;
		strBuffer += " ";
		
		if (addBreak && enableFormatting)
		{
			strBuffer += "\n";
		}
	}
	
	
	static private function genString(char:String, amount:Int):String
	{
		var str:String = "";
		while (amount > 0)
		{
			str += char;
			amount--;
		}
		return str;
	}
}
