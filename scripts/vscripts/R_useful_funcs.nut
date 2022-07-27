function GetCurrentMapInfo()
{
	local FILENAME_MAPSINFO = "r_" + ( IsHardcore() ? "hs" : "rs" ) + "_mapratings";
	local maps_info = CleanList( split( FileToString( FILENAME_MAPSINFO ), "|" ) );

	if ( maps_info.len() == 0 )
		return;

	maps_info.remove( 0 );	// remove the comment

	if ( !ValidArray( maps_info, 4 ) )
	{
		LogError( COLOR_RED + "Internal ERROR: MapSpawn: maps_info array has invalid length = " + maps_info.len().tostring(), FILENAME_MAPSINFO );
		return;
	}

	g_fTotalMapCount <- maps_info.len() / 4;
	
	local cur_map = GetMapName().tolower();
	
	for ( local i = 0; i < maps_info.len(); i += 4 )
	{
		if ( cur_map == maps_info[i + 1] )
		{
			g_strCurMap <- maps_info[i];
			g_iMapRating <- maps_info[i+2].tointeger();
			g_iMapPrecision <- maps_info[i+3].tointeger();

			return;
		}
	}
}

// broadcast a message to other servers. second parameter true means map name and game mode will be included in the beginning of the message
// important: if broadcasting trying to broadcast couple messages at the same time, only the last one will be broadcasted. (0.1 second update for broadcasting).
// todo: add a message queue to support multiple message broadcasts at same time? or some hack to parse multiple messages as one
function BroadcastMessage( message, bMissionCompletion = false )
{
	if ( bMissionCompletion )
		message = ( COLOR_YELLOW + "MAP " + COLOR_GREEN + g_strCurMap + COLOR_YELLOW + ", MODE " + ( g_strPrefix == "hs" ? ( COLOR_RED + "HARDCORE: " ) : ( COLOR_GREEN + "RELAXED: " ) ) ) + "\n" + message;

	local file_messagelog = CleanList( split( FileToString( "r_messagelog" ), "|" ) );
	file_messagelog.push( "MessageBroadcast_" + FilterName( g_hPlayer.GetPlayerName() ) );	// someone will use this as their steam name wont they
	file_messagelog.push( FilterName( message ) );

	WriteFile( "r_messagelog", file_messagelog, "|", 2, "" );
}

function IsHardcore()
{
	return Convars.GetStr( "rd_challenge" ) == "R_HS" ? true : false;
}

function GetTotalMapCount( mode )
{
	local FILENAME_MAPSINFO = "r_" + ( mode == "HARDCORE" ? "hs" : "rs" ) + "_mapratings";
	local maps_info = CleanList( split( FileToString( FILENAME_MAPSINFO ), "|" ) );

	return maps_info.len() / 4;
}

function GetKeyFromValue( table, value )
{
	foreach( key, _value in table )
		if ( value == _value )
			return key;
			
	return 0;
}

function BuildPlayerList()
{
	local player_list = CleanList( split( FileToString( FILENAME_PLAYERLIST ), "|" ) );
	if ( player_list.len() != 0 )
	{
		for ( local i = 0; i < player_list.len(); i += 2 )
		{
			g_tPlayerList[ player_list[i] ] <- player_list[i+1];
		}
	}
	
	if ( !ValidArray( player_list, 2 ) )
	{
		LogError( COLOR_RED + "FATAL Internal ERROR: player_list array has invalid length = " + player_list.len().tostring() );
		this["self"].Destroy();
		return;
	}
}

function TruncateFloat( value, precision )
{
	if ( precision < 0 || precision > 5 || typeof( value ) != "float" )	// sanity check
		return value;
	
	return ( value * pow( 10, precision ) ).tointeger().tofloat() / pow( 10, precision );
}

// nubic selection sort, an array with increment 2
function SortArray2( _array, bDescending = true )
{
    local length = _array.len();
    
    for ( local i = 0; i < length - 2; i += 2 )	
	{
		local _string = _array[i];
		local _value = _array[i+1].tofloat();

		for ( local j = i + 2; j < length; j += 2 )
		{
			if ( bDescending )
            {
                if ( _value < _array[j+1].tofloat() )
                {
                    _array[i] = _array[j];
                    _array[j] = _string;
                    _string = _array[i];

                    _array[i+1] = _array[j+1];
                    _array[j+1] = _value;
                    _value = _array[i+1].tofloat();
                }
            }
            else
            {
                if ( _value > _array[j+1].tofloat() )
                {
                    _array[i] = _array[j];
                    _array[j] = _string;
                    _string = _array[i];

                    _array[i+1] = _array[j+1];
                    _array[j+1] = _value;
                    _value = _array[i+1].tofloat();
                }
            }
		}
	}
}

// remove '|' symbols from player's name or they break the player list file
function FilterName( name )
{
    local split_name = split( name, "|" );
    local filtered_name = "";

    for ( local i = 0; i < split_name.len(); ++i )
        filtered_name += split_name[i];

    return filtered_name == "" ? "weird_name_person" : filtered_name;
}

function UnitsToDecimeters( value )
{
	return ( value * 0.1905 ).tointeger();
}

function CleanList( list, popeof = true )
{
	if ( list.len() == 0 )
		return list;
	
	if ( popeof )
		list.pop();	// pop the end of file
	
	for ( local i = 0; i < list.len(); ++i )
	{
		list[i] = strip( list[i] );
	}

	return list;
}

function WriteFile( file_name, data, str_delimiter, data_per_line, compiled_string_initialize )
{	
	local compiled_string = compiled_string_initialize;
	
	for ( local i = 0; i < data.len(); i += data_per_line )
	{
		for ( local j = i; j < i + data_per_line; ++j )
		{
			compiled_string += data[j] + str_delimiter;
			
			if ( j + 1 == i + data_per_line )	// last piece of data on a line
			{
				compiled_string += "\n";
			}
		}
	}
	
	compiled_string += "eof";

	StringToFile( file_name, compiled_string );
}

function ValidArray( _array, parts )
{
	return !( _array.len() % parts );
}

function TimeToString( _time, bNoSign )
{
	local compiled_string = "";

	if ( _time < 0 )
	{
		_time *= -1;
		compiled_string += "-";
	}
	else
	{
		if ( !bNoSign )
			compiled_string += "+";
	}
	
	local miliseconds = 100 * ( _time - _time.tointeger() );
	miliseconds = miliseconds.tointeger();
	_time = _time.tointeger();

	if ( _time >= 3600 )
	{
		compiled_string += str( _time / 3600 ) + ":";
		_time %= 3600;
	}

	compiled_string += str( ( _time / 60 ) / 10 ) + str( ( _time / 60 ) % 10 ) + ":";
	_time %= 60;
	compiled_string += str( _time / 10 ) + str( _time % 10 ) + "." + str( miliseconds / 10 ) + str( miliseconds % 10 );

	return compiled_string;
}

function str( parameter )
{
	return parameter.tostring();
}

function LogError( str_message, str_info = "" )
{
	PrintToChat( str_message );

	local error_list = CleanList( split( FileToString( "r_errorlog" ), "|" ) );
	error_list.push( str_message + " " + str_info );

	WriteFile( "r_errorlog", error_list, "|", 1, "" );
}

function PrintToChat( str_message )
{
	ClientPrint( null, 3, str_message );
}

function DelayCodeExecution( string_code, delay, str_entity_name = "asw_challenge_thinker" )
{
	DoEntFire( str_entity_name, "RunScriptCode", string_code, delay, null, null );
}

function DelayFunctionCall( function_name, function_params, delay )
{
	if ( !this["self"] )
		return;

	// this[ function_name ]( function_params );
	EntFireByHandle( this["self"], "RunScriptCode", "this[\"" + function_name + "\"](" + function_params + ");", delay, null, null );
}