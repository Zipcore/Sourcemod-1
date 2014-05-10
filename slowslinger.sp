#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.4"

new Handle:tMsgDelay = INVALID_HANDLE;
new Handle:slowslinger_enabled = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "SlowSlinger",
    author = "Js41637",
    description = "Slows players who equip the gunslinger",
    version = PLUGIN_VERSION,
    url = "http://gamingsydney.com"
};

public OnPluginStart()
{
	
	HookEvent("post_inventory_application", eventSpawn, EventHookMode_Post);
	slowslinger_enabled = CreateConVar("sm_slowslinger_enabled", "1", "Reports the status of this plugin (1=enabled, 0=disabled)", FCVAR_PLUGIN);
}

public Action:eventSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	if(TF2_GetPlayerClass(client) == TFClass_Engineer && GetConVarBool(slowslinger_enabled))
	{
		new weapon = GetPlayerWeaponSlot(client, 2);
		if (IsValidEntity(weapon))
		{
			decl String:wName[32];
			GetEntityClassname(weapon, wName, 32);
			if (StrEqual(wName, "tf_weapon_robot_arm"))
			{
				if(tMsgDelay == INVALID_HANDLE)
				{
					CPrintToChat(client, "{haunted}You're using a {red}banned {haunted}weapon: {default}The Gunslinger{haunted}, your movement speed and max ammo has been nerfed");
					tMsgDelay = CreateTimer(7.0, ResetDelay)
				}
				AddAttribute(client, "move speed bonus", 0.6);
				AddAttribute(client, "maxammo metal increased", 0.5);
			}
			else
			{
				TF2Attrib_RemoveByName(client, "move speed bonus");
				TF2Attrib_RemoveByName(client, "maxammo metal increased");
			}
			
		}
		return Plugin_Continue;
	}
	TF2Attrib_RemoveByName(client, "move speed bonus");
	TF2Attrib_RemoveByName(client, "maxammo metal increased");
	return Plugin_Handled;
}

public Action:ResetDelay(Handle:timer)
{
	tMsgDelay = INVALID_HANDLE;
}

stock AddAttribute(client, String:attribute[], Float:value) {
	if(IsValidClient(client)) {
		TF2Attrib_SetByName(client, attribute, value);
	}
}

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock RemoveAttribute(client, String:attribute[]) {
	if(IsValidClient(client)) {
		TF2Attrib_RemoveByName(client, attribute);
	}
}
