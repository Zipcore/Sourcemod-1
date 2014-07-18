#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1"

new Handle:g_hEnabled = INVALID_HANDLE;
new isEnabled;

//new String:id_xander = '103216033'
new String:id_xander[16] = "94193226", String:id_js[16] = "75598657";

public Plugin:myinfo = 
{
  name = "xander Season",
  author = "Js41637",
  description = "It's Xander Season!",
  version = PLUGIN_VERSION,
  url = "www.js41637.com"
}

public OnPluginStart()
{
	//RegAdminCmd("sm_xanderseason", xanderseason, ADMFLAG_ROOT);

	g_hEnabled = CreateConVar("sm_xs_enabled", "0", "Is Xander Season enabled?");

	//HookEvent("player_spawn", Event_PlayerSpawn);

	isEnabled = GetConVarInt(g_hEnabled);
	for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
}

/*
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	// Not sure if I need this
}*/

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);

}
public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(isEnabled == 1) {
		new String:clientid[1];
		new String:attackerid[1];

		clientid[1] = GetSteamAccountID(client);
		attackerid[1] = GetSteamAccountID(attacker);
		

		if(StrEqual(clientid, id_xander, false) && StrEqual(attackerid, id_js, false)) {
			PrintToChatAll("Jayess attacked someone");
		}

		return Plugin_Continue;
	}
	return Plugin_Continue;
}
/*
Not relevant, based off another plugin, might have some useful code.
public Action:noself(client,args)
{	
	if (args != 0 && args != 2)
	{
		ReplyToCommand(client, "Usage: sm_noself OR sm_noself [target] [0/1]");
		return Plugin_Handled;
	}
	
	if (args == 0 && IsPlayerAlive(client))
	{
		//Do low-level admin self target
		if (!g_noSelf[client]) //On
		{
			g_noSelf[client] = true;
			LogAction(client, client, "\"%L\" disabled self damage on himself", client);
			ReplyToCommand(client,"\x04[NoSelf]\x01 You disabled self damage on yourself!");
			return Plugin_Handled;
		}
		else if
		(g_noSelf[client]) //Off
		{
			g_noSelf[client] = false;
			LogAction(client, client, "\"%L\" enabled self damage on himself", client);
			ReplyToCommand(client,"\x04[NoSelf]\x01 You enabled self damage on yourself!");
			return Plugin_Handled;
		}
		return Plugin_Handled;
	}
	
	else if (args == 2)
	{
		//Create strings
		decl String:buffer[64];
		decl String:target_name[MAX_NAME_LENGTH];
		decl target_list[MAXPLAYERS];
		decl target_count;
		decl bool:tn_is_ml;
		
		//Get target arg
		GetCmdArg(1, buffer, sizeof(buffer));
		
		//Process
		if ((target_count = ProcessTargetString(
				buffer,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_ALIVE,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		decl String:Enabled[32];
		GetCmdArg(2, Enabled, sizeof(Enabled));
		new iEnabled = StringToInt(Enabled)
		
		if (iEnabled == 1)
		{
			ReplyToCommand(client,"\x04[NoSelf]\x01 You disabled self damage on %s!", target_name);
		}
		else
		{
			ReplyToCommand(client,"\x04[NoSelf]\x01 You enabled self damage on %s!", target_name);
		}
		
		for (new i = 0; i < target_count; i ++)
		{
			if (iEnabled == 1) //Turn on
			{
				g_noSelf[target_list[i]] = true;
				LogAction(client, target_list[i], "[NoSelf] \"%L\" disabled self damage on \"%L\"", client, target_list[i]);
			}
			else //Turn Off
			{
				g_noSelf[target_list[i]] = false;
				LogAction(client, target_list[i], "[NoSelf] \"%L\" enabled self damage on \"%L\"", client, target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}*/
