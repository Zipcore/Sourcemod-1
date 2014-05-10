#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <regex>

#define PLUGIN_VERSION "1.2.0"

new Handle:g_FloatRegex;
new Handle:weaponsize_enabled;

public Plugin:myinfo =
{
	name		= "Change Weapon Size",
	author	  	= "Js41637",
	description = "Change the size of weapons.",
	version	 	= PLUGIN_VERSION,
	url		 	= ""
};

public OnPluginStart()
{
	CreateConVar("sm_weaponsize_version", PLUGIN_VERSION, "Change the Size of Weapons", FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_weaponsize", WeaponSize, ADMFLAG_SLAY, "Change the size of weapons.");
	RegAdminCmd("sm_ws", WeaponSize, ADMFLAG_SLAY, "Change the size of weapons.");
	RegAdminCmd("sm_disableweaponsize", WeaponSToggle, ADMFLAG_SLAY, "Toggle WeaponSize enabled.")
	RegAdminCmd("sm_disablews", WeaponSToggle, ADMFLAG_SLAY, "Toggle WeaponSize enabled.")
	weaponsize_enabled = CreateConVar("sm_weaponsize_enabled", "1", "Reports the status of this plugin (1=enabled, 0=disabled)", FCVAR_PLUGIN);
	//Checks to see if string is: an int, negative int, only one period, if negative then only one dash
	g_FloatRegex = CompileRegex("^[-+]?([0-9]+\\.[0-9]+|[0-9]+)");
}

public Action:WeaponSize(client, args)
{
	if(client <= 0)
		return Plugin_Handled;
	
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}You must be alive to use this command!");
		return Plugin_Handled;
	}
	
	if (args < 1)
	{
		new String:cmdName[22];
		GetCmdArg(0, cmdName, sizeof(cmdName));
		CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Usage: %s <size>", cmdName);
		return Plugin_Handled;
	}
	else
	{
		new String:cmdArg[22];
		GetCmdArg(1, cmdArg, sizeof(cmdArg));
		new RegexError:ret = REGEX_ERROR_NONE;
		MatchRegex(g_FloatRegex, cmdArg, ret);
		if(IsClientDonator(client))
		{
			if(ret != REGEX_ERROR_NONE)
			{
				CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Invalid size input.");
				return Plugin_Handled;
			}
			new Float:fArg = StringToFloat(cmdArg);
			if(fArg < 0.7 || fArg > 1.3)
			{
				CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Value must be between 0.7 & 1.3");
				return Plugin_Handled;
			}
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(!IsValidEntity(ClientWeapon))
			{
				CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Unable to find active weapon.");
				return Plugin_Handled;
			}
			SetEntPropFloat(ClientWeapon, Prop_Send, "m_flModelScale", fArg);
			return Plugin_Handled;
		}
		if(!IsClientDonator(client))
		{
			if(ret != REGEX_ERROR_NONE)
			{
				CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Invalid size input.");
				return Plugin_Handled;
			}
			new Float:fArg = StringToFloat(cmdArg);
			if(fArg == 0.0 || fArg > 7.0)
			{
				CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Value cannot be 0.0 or larger than 7.0");
				return Plugin_Handled;
			}
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(!IsValidEntity(ClientWeapon))
			{
				CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Unable to find active weapon.");
				return Plugin_Handled;
			}
			SetEntPropFloat(ClientWeapon, Prop_Send, "m_flModelScale", fArg);
			return Plugin_Handled;
		}
		else
		{
			CReplyToCommand(client, "[{haunted}WeaponSize{default}] {normal}Something went wrong :(");
		}
		return Plugin_Handled;
	}
}

public Action:WeaponSToggle(client, args)
{
	if(GetConVarBool(weaponsize_enabled))
	{
		SetConVarBool(weaponsize_enabled, false);
		LogAction(client, -1, "\"%L\" has disabled Weapon Resizing", client);
		CPrintToChatAll("[{haunted}WeaponSize{default}] {normal}Weapon Resizing Disabled");
	}
	else
	{
		SetConVarBool(weaponsize_enabled, true);
		LogAction(client, -1, "\"%L\" has enabled Weapon Resizing", client);
		CPrintToChatAll("[{haunted}WeaponSize{default}] {normal}Weapon Resizing Re-Enabled");
	}
}

public IsClientDonator(client) 
{
	if(GetAdminFlag(GetUserAdmin(client), Admin_Slay))
		return false; 
		
	if(GetAdminFlag(GetUserAdmin(client), Admin_Custom2))
		return true; 

	if(GetAdminFlag(GetUserAdmin(client), Admin_Custom3))
		return true; 

	return false; 
}