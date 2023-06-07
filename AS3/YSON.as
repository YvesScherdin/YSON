package
{
	/**
	 * @version 0.3.9
	 * @author  Yves Scherdin
	 * 
	 * ChangeLog:
	 * 
	 * - 07.08.2023 (0.4.0) - refactorings and preparations for haxe port
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
	public class YSON
	{
		// static fields and mehods
		static private var STRICT_ERROR_REPORT:Boolean = true;
		
		static public var allowVerbose:Boolean;
		
		static private const arr_numbers      : Array = [ "0",  "1",  "2",  "3", "4",  "5", "6", "7", "8", "9" ];
		static private const arr_no_key       : Array = [ " ", "\n", "\r", "\t", ",",  ";", ".", "-", "<", ">", "|", "+" ];
		static private const arr_ignore_key   : Array = [ " ", "\n", "\r",  ",", ";", "\t", "[", "]", "{", "}" ];
		static private const arr_ignore_value : Array = [ " ", "\n", "\r", "\t", "=" ];
		static private const valueTypes       : Array = [ "none", "string", "object", "number", "int", "boolean" ];
		static private const ESCAPE_CHAR   :String = "\\";
		
		static public function parseData( source_str:String ):Object
		{
			return new YSON().parseSource( source_str );
		}
		
		static private function cutCharFrom( char:String,source_str:String ):String
		{
			var a:Array = source_str.split( char );
			return concatStrings( a );
		}
		
		static private function cloneArray( a:Array ):Array
		{
			var b:Array = [];
			for( var i:int=0; i<a.length; i++ )
				b[i] = a[i];
			
			return b;
		}
		
		static private function getAmountIn( pattern_str:String,source_str:String,startIndex:int=0,holder:int=0 ):int
		{
			var i:int = source_str.indexOf( pattern_str,startIndex );
			if( i == -1 )
				return holder;
			else
				return getAmountIn( pattern_str,source_str,++i,++holder )
		}
		
		static private function concatStrings( strArr:Array ):String
		{
			var str:String = "";
			for( var i:int=0; i<strArr.length; i++ )
			{
				str += strArr[i];
			}
			return str;
		}
		
		static private function isOneOfThose( stuff:Object, arr:Array ):Boolean
		{
			for( var i:int=0; i<arr.length; i++ )
				if( stuff == arr[i] )
					return true;
			return false;
		}
		
		static private function isCharNumber( char:String ):Boolean
		{
			return( isOneOfThose( char,["0","1","2","3","4","5","6","7","8","9"] ) )
		}
		
		/**
		 * Error report via tracing.
		 * @param	str
		 */
		static private function report( str:Object ):void
		{
			if( allowVerbose )
				trace( str );
		}
		
		static private function logError(e:Error):void
		{
			if ( STRICT_ERROR_REPORT )
				throw e;
			else
				report(e);
		}
		
		// non-static fields and metods
		
		private var hierarchy           :Array; // objects
		private var arrayHierarchy      :Array; // arrays
		private var hierarchyTypeHistory:Array; // stores booleans, true --> object    false --> array
		
		private var text2parse    :String;
		public function getTextSource():String { return text2parse; }
		
		private var data2parse    :Object;
		
		private var currSlot      :int;
		private var index_1       :int;
		private var index_2       :int;
		
		private var state_key     :Boolean;
		private var currKey       :String;
		private var currValue     :*;
		private var currValueType :String;
		
		private var isComment     :Boolean;
		private var isBlockComment:Boolean;
		
		private var doubleQuoMarks:Boolean;
		private var prevChar:String;
		
		
		// ---- need no constructor ----
		
		
		public function parseSource( source_str:String ):Object
		{
			hierarchy		     = [];
			arrayHierarchy       = [];
			hierarchyTypeHistory = [];
			
			text2parse = source_str;
			data2parse = addObject( new Object() );
			
			if( text2parse == null )
				return data2parse;
			
			currSlot = 0;
			index_1 = index_2 = -1;
			currValueType = "none";
			
			isComment = false;
			state_key = true;
			
			// analyze char by char
			while ( currSlot < text2parse.length )
			{
				analyze();
				currSlot++;
			}
			
			text2parse = null;
			currKey = null;
			
			return data2parse;
		}
		
		private function analyze():void
		{
			var char       :String  = text2parse.charAt( currSlot );
			var isLastChar :Boolean = currSlot == text2parse.length-1;
			var isFirstChar:Boolean = currSlot == 0;
			
			prevChar = isFirstChar ? null : ( (text2parse.length > 0) ? text2parse.charAt( currSlot - 1 ) : null);
			
			var phraseToCheck:String;
			
			
			// check for comment
			if ( !isComment )// check for start
			{
				if ( currValueType != "string" && char == "/" && !isLastChar )// could a comment start here?
				{
					phraseToCheck = text2parse.substr( currSlot, 2 );
					
					if ( phraseToCheck == "//" )      
					{
						// line comment found
						isComment      =  true;
						isBlockComment = false;
					}
					else if ( phraseToCheck == "/*" )
					{
						// block comment found
						isComment      = true;
						isBlockComment = true;
					}
					
					if ( isComment )
					{
						//comment found
						// force value-parsing to end
						if ( analyzesValue() )
							postAddValue();
						
						currSlot++;// one further step
						return;
					}
				}
			}
			else // check for end of current comment
			{
				if ( isBlockComment )
				{
					phraseToCheck = text2parse.substr( currSlot - 1, 2 );
					if ( phraseToCheck == "*/" )  //end of comment found
					{
						isComment = false;
					}
				}
				else if ( char == "\n" || char == "\r" )
				{
					isComment = false;
				}
				
				if ( !isComment )
				{
					// comment has ended
				}
				return;
			}
			
			
			if( !isWrappedInObject() && state_key )
				state_key = false;
			
			if( state_key )// analyze key
			{
				if( index_1 == -1 )// find key start
				{
					//if( !isOneOfThose( char,["\n","\r"] ) )
					//report( "char["+currSlot+"]: " + char );
					if( !isOneOfThose( char,arr_ignore_key ) )
					{
						index_1 = currSlot;
						//report( "index_1 becomes " + currSlot );
					}
				}
				else// find key end
				{
					if( index_2 == -1 )
					{
						if( isOneOfThose( char,[" ","=","\n","\r","\t","]","}","[","{"] ) )
						//if( isOneOfThose( char,arr_ignore_key ) )
							index_2 = currSlot;
							//index_2 = getCharIndexBefore( null,[" ","\r","\n"] )
							
					}
				}
				
				if( index_1 != -1  &&  index_2 != -1 )// finally parse key
				{
					currKey = parseKey();
					state_key = false;
				}
			}
			else// analyze value
			{
				if( index_1 == -1 )// find value start
				{
					if( !isOneOfThose( char, arr_ignore_value ) )
					{
						if( index_1 == -1 )
							index_1 = currSlot;
						
						if( prevChar != ESCAPE_CHAR && (char == "'" ||  char == "\"" ) )
						{
							index_1++;
							currValueType = "string";
							doubleQuoMarks = char == "\"";
						}
						else if( isOneOfThose( char, arr_numbers ) )
						{
							currValueType = "number";
						}
						else if( char == "[" )
						{
							currValue = new Array();
							currValueType = "array";
							addValue();
							// there are no keys in an array!
						}
						else if( char == "{" )
						{
							currValue = new Object();
							currValueType = "object";
							addValue();
						}
						
					}
				}
				else// find value end
				{
					findValueEnd( char );
				}
			}
			
			// check wrapping end
			if( currValueType != "string" )
			{
				if( char == "]" )
					closeArray();
				else if( char == "}" )
					closeObject();
			}
		}
		
		private function analyzesValue():Boolean
		{
			return (index_1 != -1 && !state_key);
		}
		
		private function findValueEnd( char:String ):void
		{
			if( currValueType == "string" )
			{
				if( prevChar != ESCAPE_CHAR && (char == "'" || char == "\"") )
				{
					if( doubleQuoMarks == (char == "\"") )
						postAddValue();
				}
			}
			else
			{
				// check for being negative number
				if (currSlot - index_1 == 1 && prevChar == "-" && isOneOfThose(char, arr_numbers))
				{
					currValueType = "number";
				}
				
				if ( 	 isOneOfThose( char, [" ", "\r", "\n", "[", "{", "]", "}", "\t"] )
					 || (!isWrappedInObject() && isOneOfThose(char,[",","]","}"])))
				{
					postAddValue();
				}
				else if ( currValueType == "number" )
				{
					if ( !isCharNumber( char ) && char != "." )
					{
						currValueType = "none";
					}
				}
				//if(  isOneOfThose( char,[" ","\r","\n"] ) || ( !isWrappedInObject() && isOneOfThose(char,[",","]","}"]) )  )
				//{
					//postAddValue()
				//}
			}
		}
		
		private function postAddValue( offset_2:int=0 ):void
		{
			index_2 = currSlot + offset_2;
			currValue = parseSubString();
			//trace( "postAddValue", currValue );
			addValue();
		}
		
		private function addValue():void
		{
			if( isWrappedInObject() )
			{
				if ( currKey == "" )
					logError( new Error("YSON::addValue() - Tried to add a value with an empty key") );
				else if(CurrObject == null)
					logError( new Error("YSON::addValue() - Cannot add value to an empty object") );
				else
					CurrObject[ currKey ] = currValue;
				
				state_key = true;
			}
			else
			{
				if (CurrArray == null)
				{
					throw new Error("YSON-Parsing-Error: Current Array is null. Last Key: "+ currKey);
				}
				//report( "arr[" + CurrArray.length + "] = " + currValue + "  <" + currValueType + ">" );
				CurrArray.push( currValue );
			}
			
			// update hierarchy if neccessary
			if( currValueType == "array" )
				addArray( currValue );
			else if( currValueType == "object" )
				addObject( currValue );
			
			checkHierarchy();
				
			index_1 = index_2 = -1;
			currValueType = "none";
		}
		
		private function check4End():Boolean
		{
			// WIP < - - - - -
			if( isWrappedInObject() )
			{
				if( text2parse.charAt( currSlot ) == "}" )
				{
				}
			}
			return false;
		}
		
		private function getCharIndexBefore( char:String=null, except:Array=null ):int
		{
			if( (char == null && except == null) || (char != null && except != null) )
				return currSlot;
			
			var i:int;
			if( char )
				for( i= currSlot-1; i>= 0; i-- )
					if( text2parse.charAt(i) == char )
						break;
			if( except )
				for( i= currSlot-1; i>= 0; i-- )
					if( !isOneOfThose( text2parse.charAt(i),except ) )
						break;
			
			return ++i;
		}
		
		private function isWrappedInObject():Boolean
		{
			return hierarchyTypeHistory[ hierarchyTypeHistory.length-1 ];
		}
		
		private function get CurrObject():Object
		{
			return hierarchy[ hierarchy.length-1 ];
		}
		
		private function addObject( o:Object ):Object
		{
			hierarchy.push( o );
			hierarchyTypeHistory.push( true );
			return CurrObject;
		}
		
		private function closeObject():void
		{
			//report( "closeObject" );
			hierarchy.splice( hierarchy.length-1,1 );
			hierarchyTypeHistory.splice( hierarchyTypeHistory.length-1,1 );
			checkHierarchy();
		}
		
		private function get CurrArray():Array
		{
			return arrayHierarchy[ arrayHierarchy.length-1 ];
		}
		
		private function addArray( a:Array ):Array
		{
			arrayHierarchy.push( a );
			hierarchyTypeHistory.push( false );
			return CurrArray;
		}
		
		private function closeArray():void
		{
			//report( "closeArray" );
			arrayHierarchy.splice( arrayHierarchy.length-1,1 );
			hierarchyTypeHistory.splice( hierarchyTypeHistory.length-1,1 );
			checkHierarchy();
			index_1 = index_2 = -1;
		}
		
		private function checkHierarchy():void
		{
			state_key = ( isWrappedInObject() );
			//report( hierarchyTypeHistory, "  | state_key: " + state_key );
		}
		
		private function parseKey():String
		{
			var str:String = text2parse.substring( index_1,index_2 );
			index_1 = index_2 = -1;
			return str;
		}
		
		private function parseSubString():*
		{
			var str:String = text2parse.substring( index_1,index_2 );
			index_1 = index_2 = -1;
			
			if( str == "true" || str == "false" )
				currValueType = "boolean";
			
			if( currValueType == "number" )
			{
				if( currValueType == "number" && str.indexOf(".") == -1 )
					currValueType = "int";
			}
			
			return parseValue( str,currValueType );
		}
		
		static private function parseValue( str:String, type:String ):*
		{
			//trace( "parseValue", str, type );
			switch( type )
			{
				case "int":		return int( str );
				case "number":	return Number( str );
				case "boolean":	return ( str == "true" ) ? true : false;
				case "string":	return parseString( str );
				case "none":	return str;
				default:		return null;
			}
		}
		
		// STRING ANALYZATION POST PROCESS
		static private function parseString( str:String ):Object
		{
			// handle escape chars - tab + newline
			while( str.indexOf( "\\n" ) != -1 )
			{
				str = str.replace( "\\n","\n" );
			}
			
			while( str.indexOf( "\\t" ) != -1 )
			{
				str = str.replace( "\\t","\t" );
			}
			
			// handle escape chars - string identifiers
			while ( str.indexOf(ESCAPE_CHAR + "\"") != -1 )
			{
				str = str.replace( ESCAPE_CHAR + "\"","\"" );
			}
			
			while ( str.indexOf(ESCAPE_CHAR + "'") != -1 )
			{
				str = str.replace( ESCAPE_CHAR + "'","'" );
			}
			
			return str;
		}
		
		static public function parseArray( src:String ):Array
		{
			var arr     :Array    = [];
			var currSlot:int      = -1;
			var index   :int      = -1;
			var isString:Boolean  = false;
			var doubleQM:Boolean  = false;
			
			// get rid of brackets
			if ( src.length >= 2 )
				src = src.substring( 1, src.length-1 );
			
			while ( ++currSlot < src.length )
			{
				var char:String = src.charAt( currSlot );
				var phrase:String;
				
				if ( isString )
				{
					if (  isOneOfThose( char, ["\"", "'"] )  &&  ( doubleQM == (char == "\"") )  )
					{
						phrase = src.substring( index+1, currSlot );
						arr.push( parseString( phrase ) );
						//trace( "addValue[" + phrase + "]:String||YsonTable" );
						index = -1;
						isString = false;
						continue;
					}
				}
				else
				{
					if ( index == -1 )
					{
						// find start of next value
						
						// check 4 stuff 2 ignore
						if ( isOneOfThose( char, [" ", "\t", "\r", "\n"] ) )
						{
							continue;
						}
						
						// check 4 empty argument
						
						// check 4 array
						if ( char == "[" )
						{
							phrase = getPhraseBetween(  src, currSlot, "[", "]", true, true );
							arr.push( parseArray( phrase ) );
							//	trace( "addValue[" + phrase + "]" );
							currSlot += phrase.length;
							continue;
						}
						
						// no array and nothing to ignore, so it must be a value.
						
						// check 4 string
						if ( isOneOfThose( char, ["\"", "'"] ) )
						{
							isString = true;
							doubleQM = char == "\"";
						}
						
						index = currSlot;
						continue;
					}
					else
					{
						// find end of current value
						if ( isOneOfThose( char, [" ", "\t", "\r", "\n", ","] ) )
						{
							phrase = src.substring( index, currSlot );
							index  = -1;
							arr.push( parseValue( phrase, getTypeOfValue( phrase ) ) );
							//trace( "addValue[" + phrase + "]" );
							continue;
						}
					}
				}
			}
			
			if ( index != -1 )
			{
				phrase = src.substring( index, currSlot );
				index  = -1;
				arr.push( parseValue( phrase, getTypeOfValue( phrase ) ) );
				//trace( "addLastValue[" + phrase + "]" );
			}
			
			return arr;
		}
		
		static public function getPhraseBetween( src:String, startIndex:int, start:String, end:String, noticeInterlacing:Boolean=false, including:Boolean=false ):String
		{
			//trace( "phraseBetween", src, including );
			var interlacings:int = 0;
			var i:int;
			var index:int = -1;
			
			for ( i = 0; startIndex + i < src.length; i++ )
			{
				var char:String = src.charAt( startIndex + i );
				
				if ( char == start )
				{
					if ( index == -1 )
						index = startIndex + i;
					
					interlacings++;
				}
				
				if ( index != -1 && char == end )
				{
					interlacings--;
					if ( interlacings <= 0 )
					{
						if ( including )
							return src.substring( index, index + i + 1 );
						else
							return src.substring( index + 1, index + i );
					}
				}
			}
			
			i--;
			if ( including )
				return src.substring( index, index + i + 1 );
			else
				return src.substring( index + 1, index + i );
		}
		
		static private function isBoolean( src:String ):Boolean
		{
			return isOneOfThose( src, ["true", "false"] );
		}
		
		static private function getTypeOfValue( src:String ):String
		{
			// check 4 boolean
			if ( isBoolean( src ) )		return "boolean";
			
			// check 4 number
			var i:int;
			
			var comma:Boolean;
			for ( i = 0; i < src.length; i++ )
			{
				if ( !isOneOfThose( src.charAt(i), arr_numbers ) )
				{
					if ( !comma && src.charAt(i) == "." )
						comma = true;
					else
						break;
				}
			}
			
			if ( i == src.length )// src was trawled to the end
			{
				if ( comma )
					return "number";
				else
					return "int";
			}
			
			return "string";
		}
		
		// write
		static private var enableFormatting:Boolean;
		static private var useSingleQuoMark:Boolean;
		static private var tabs:int;
		static private var strBuffer:String;
		
		/**
		 * Takes only basic data types (Object, Array, Number, int, String). Any other will be coersed to String.
		 * @param	obj					An Object (AMF).
		 * @param	_enableFormatting	False will cause no line breaks and tabs which leads to less readability. Default is true.
		 * @return  					A YSON-parseable String and serialized replica of the param obj.
		 */
		static public function writeData( obj:Object, _enableFormatting:Boolean=true, _useSingleQuoMark:Boolean=false ):String
		{
			enableFormatting = _enableFormatting;
			useSingleQuoMark = _useSingleQuoMark;
			
			writeObject( obj );
			var str:String = strBuffer;
			strBuffer = null;
			return str;
		}
		
		static private function writeValue( val:* ):void
		{
			if ( val == null )
			{
				writeText( "null" );
				return;
			}
			
			var str:String = val.toString();
				 if ( val is Array )						writeArray( val );
			else if ( val.toString() == "[object Object]" )	writeObject( val );
			else											writeText( prepareValue(val) );
		}
		
		static private function prepareValue( val:* ):String
		{
			if ( val is String )
			{
				// TODO: turn " into \" and check for escaped characters in parse-section
				return writwQuotaMark() + val + writwQuotaMark();
			}
			else // number or int (or smthg not really parseable)
			{
				return String( val );
			}
		}
		
		static private function writwQuotaMark():String
		{
			return useSingleQuoMark ? "'" : '"';
		}
		
		static private function isSimpleValue( val:* ):Boolean
		{
			return String(val) != "[object Object]"  &&  val is Array == false;
		}
		
		static private function writeArray( a:Array ):void
		{
			writeText( "[" );
			tabs++;
			for each( var element:* in a )
			{
				writeValue( element );
			}
			tabs--
			writeText( "]" );
		}
		
		static private function writeObject( o:Object ):void
		{
			writeText( "{" );
			tabs++;
			
			for ( var key:String in o )
			{
				if ( isSimpleValue( o[key] ) )
				{
					writeText( key + " = " + prepareValue(o[key]) );
				}
				else
				{
					writeText( key + " = " );
					writeValue( o[ key ] );
				}
			}
			
			tabs--;
			writeText( "}" );
		}
		
		static private function writeText( str:String, addBreak:Boolean=true ):void
		{
			if ( strBuffer == null )
				strBuffer = "";
			
			if ( enableFormatting )
				strBuffer += ( genString( "\t", tabs ) );
			
			strBuffer += String( str );
			strBuffer += " ";
			
			if ( addBreak && enableFormatting )
				strBuffer += "\n";
		}
		
		static private function genString( char:String, amount:int ):String
		{
			var str:String = "";
			for ( ; amount > 0; amount-- )	str += char;
			return str;
		}
	}
}