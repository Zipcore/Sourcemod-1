/*

----------------------------------------------------------------------
*                  INTELLIGENCE PROTECTOR PLUGIN                     *
----------------------------------------------------------------------

* When enabled, this plugin will disable the intelligence and force any
* player carrying it to drop it.

* If a player is carrying the intel when the plugin is activated, he
* will be forced to drop it. The intelligence will get back to its base
*2 1 minutes after being dropped (default value), which should leave you
* enough time to do whatever you want before reactivating the intelligence.
* Upon reactivation, the intelligence timer is reset to its original value.

* Plugin written by Heffebaycay
* http://steamcommunity.com/id/heffebaycay

*/

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <morecolors>

#define PLUGIN_VERSION "1.1.2"

new Handle:intelp_enabled;
new bool:bSavedBluFlag = false;
new bool:bSavedRedFlag = false;
new Float:MaxFlagTime;
new blu_flag_ent = 0;
new red_flag_ent = 0;
new Float:blu_pos[3];
new Float:red_pos[3];

public Plugin:myinfo = 
{
	name = "Intelligence Protector JsFix",
	author = "Heffebaycay",
	description = "Prevent the intel from being taken by a player",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=146309"
}

public OnPluginStart()
{
	HookEvent("teamplay_flag_event", Event_Intel_dropped);
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	RegAdminCmd("sm_intelp", Intel_Protector, ADMFLAG_GENERIC, "Toggle Intelligence Protection");
	RegAdminCmd("sm_intelp2", Intel_Protector2, ADMFLAG_BAN, "Intelligence Protection"); 
	CreateConVar("sm_intelp_version", PLUGIN_VERSION, "Intelligence Protector Version", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	intelp_enabled = CreateConVar("sm_intelp_enabled", "0", "Reports the status of this plugin (1=enabled, 0=disabled)", FCVAR_PLUGIN);
}


public Action:Intel_Protector(client, args)
{
	if(GetConVarBool(intelp_enabled))
	{
		// Re enable intelligence
		CPrintToChatAll("[{haunted}Intel Protector{default}] {normal}Enabling Intelligence");
		SetConVarBool(intelp_enabled, false);
		if(bSavedBluFlag)
		{
			TeleportEntity(blu_flag_ent, blu_pos, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(blu_flag_ent, Prop_Send, "m_nFlagStatus", 2);
			SetEntPropFloat(blu_flag_ent, Prop_Send, "m_flResetTime", GetGameTime() + MaxFlagTime);
			bSavedBluFlag = false;
		}
		
		if (bSavedRedFlag)
		{
			TeleportEntity(red_flag_ent, red_pos, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(red_flag_ent, Prop_Send, "m_nFlagStatus", 2);
			SetEntPropFloat(red_flag_ent, Prop_Send, "m_flResetTime", GetGameTime() + MaxFlagTime);
			bSavedRedFlag = false;			
		}
		ActivateIntel();
		LogAction(client, -1, "\"%L\" has enabled the Intelligence", client);
	}
	else
	{
		// Disable intelligence
		CPrintToChatAll("[{haunted}Intel Protector{default}] {normal}Disabling Intelligence");
		SetConVarBool(intelp_enabled, true);
		DisableIntel();
		LogAction(client, -1, "\"%L\" has disabled the Intelligence", client);
	}
	
}
public Action:ActivateIntel()
{
	new ent = -1
	while( (ent= FindEntityByClassname(ent, "item_teamflag")) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "Enable");
	}
}

public Action:DisableIntel()
{
	new ent = -1
	while( (ent= FindEntityByClassname(ent, "item_teamflag")) != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(ent, "ForceDrop");
		AcceptEntityInput(ent, "ForceReset");
		AcceptEntityInput(ent, "Disable");
	}
}


public FindOtherTeam(team)
{
	if(team == _:TFTeam_Red)
	{
		return _:TFTeam_Blue;
	}
	else if(team == _:TFTeam_Blue)
	{
		return _:TFTeam_Red;
	}
	else
	{
		return 0;
	}
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		FakeClientCommand(client, "dropitem");
	}
}

public Event_Intel_dropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(intelp_enabled))
	{
		new type = GetEventInt(event, "eventtype");
		new client = GetEventInt(event, "player");
		
		if(type == 4)
		{
			// Intel dropped
			PrintCenterText(client, "Intel protection enforced");
			new team = GetClientTeam(client);
			new other_team = FindOtherTeam(team);
			new flag_ent = -1;
			new tmp_team = 0;
			while (tmp_team != other_team)
			{
				flag_ent = FindEntityByClassname(flag_ent, "item_teamflag");
				tmp_team = GetEntProp(flag_ent, Prop_Send, "m_iTeamNum");
			}
			
			// We have the flag entity of the other team
			
			MaxFlagTime = GetEntPropFloat(flag_ent, Prop_Send, "m_flMaxResetTime");

			if(other_team == _:TFTeam_Blue)
			{
				bSavedBluFlag = true;
				blu_flag_ent = flag_ent;
				GetEntPropVector(blu_flag_ent, Prop_Send, "m_vecOrigin", blu_pos);
			}
			else if(other_team == _:TFTeam_Red)
			{
				bSavedRedFlag = true;
				red_flag_ent = flag_ent;
				GetEntPropVector(red_flag_ent, Prop_Send, "m_vecOrigin", red_pos);
			}
		}
	}
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
    SetConVarBool(intelp_enabled, false);
}

public Action:Intel_Protector2(client, args)
{
	decl String:lel[10];
	if (args < 1)
	{
		CReplyToCommand(client, "{normal}Usage: {default}sm_intelp2 <0/1> (off/on)");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, lel, sizeof(lel));
	if(StrEqual("1", lel, false))
	{
		// Re enable intelligence
		CPrintToChatAll("[{haunted}Intel Protector{default}] {normal}Enabling Intelligence");
		SetConVarBool(intelp_enabled, false);
		if(bSavedBluFlag)
		{
			TeleportEntity(blu_flag_ent, blu_pos, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(blu_flag_ent, Prop_Send, "m_nFlagStatus", 2);
			SetEntPropFloat(blu_flag_ent, Prop_Send, "m_flResetTime", GetGameTime() + MaxFlagTime);
			bSavedBluFlag = false;
		}
		
		if (bSavedRedFlag)
		{
			TeleportEntity(red_flag_ent, red_pos, NULL_VECTOR, NULL_VECTOR);
			SetEntProp(red_flag_ent, Prop_Send, "m_nFlagStatus", 2);
			SetEntPropFloat(red_flag_ent, Prop_Send, "m_flResetTime", GetGameTime() + MaxFlagTime);
			bSavedRedFlag = false;			
		}
		ActivateIntel();
		LogAction(client, -1, "\"%L\" has enabled the Intelligence", client);
	}
	else if(StrEqual("0", lel, false))
	{
		// Disable intelligence
		CPrintToChatAll("[{haunted}Intel Protector{default}] {normal}Disabling Intelligence");
		SetConVarBool(intelp_enabled, true);
		DisableIntel();
		LogAction(client, -1, "\"%L\" has disabled the Intelligence", client);
	}
	return Plugin_Handled;
}