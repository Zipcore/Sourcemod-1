#include <sourcemod>
#include <morecolors>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.2"

new Handle:tMsgDelay = INVALID_HANDLE;
new Handle:nogunslinger_enabled = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "No Gunslinger",
    author = "Js41637",
    description = "Slows players who equip the gunslinger",
    version = PLUGIN_VERSION,
    url = "http://gamingsydney.com"
};

public OnPluginStart()
{
	
	HookEvent("post_inventory_application", eventSpawn, EventHookMode_Post);
	nogunslinger_enabled = CreateConVar("sm_nogunslinger_enabled", "1", "Reports the status of this plugin (1=enabled, 0=disabled)", FCVAR_PLUGIN);
	RegConsoleCmd("greset", Greset, "Open DP! Steam Group");
}

public Action:Greset(client, args)
{
	TF2Attrib_RemoveByName(client, "wrench_builds_minisentry");
	ReplyToCommand(client, "kdun")
}

public Action:eventSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	if(TF2_GetPlayerClass(client) == TFClass_Engineer && GetConVarBool(nogunslinger_enabled))
	{
		new weapon = GetPlayerWeaponSlot(client, 2);
		if (weapon != -1)
		{
			decl String:wName[32];
			GetEntityClassname(weapon, wName, 32);
			if (StrEqual(wName, "tf_weapon_robot_arm"))
			{
				if(tMsgDelay == INVALID_HANDLE)
				{
					CPrintToChat(client, "{haunted}Gunslinger has been {red}nerfed {haunted} and cannot build mini-sentries.");
					tMsgDelay = CreateTimer(7.0, ResetDelay)
				}
				AddAttribute(weapon, "mod wrench builds minisentry", 0.0);
			}
		}
	}
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