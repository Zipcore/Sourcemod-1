#include <sourcemod>
#include <tf2>
#include <morecolors>

#define PLUGIN_VERSION "1.0"

new Handle:classr_enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Class Restict Enable/Disable",
	author = "Js41637",
	description = "Toggle Class Restrictions on or off",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_classr", Class_Restrict, ADMFLAG_SLAY, "Toggle Intelligence Protection"); 
	classr_enabled = CreateConVar("sm_classr_enabled", "1", "Reports the status of this plugin (1=enabled, 0=disabled)", FCVAR_PLUGIN);
}


public Action:Class_Restrict(client, args)
{
	if(GetConVarBool(classr_enabled))
	{
		SetConVarBool(classr_enabled, false);
		DisableClassRestrict();
		LogAction(client, -1, "\"%L\" has disabled class restrictions", client);
	}
	else
	{
		//Re-enable Class Restrict
		SetConVarBool(classr_enabled, true);
		EnableClassRestrict();
		LogAction(client, -1, "\"%L\" has enabled class restrictions", client);
	}
	
}
public Action:DisableClassRestrict()
{
	ServerCommand("sm_cvar sm_classrestrict_enabled 0");
	CPrintToChatAll("[{haunted}Class Restrict{default}] {normal}Class Restrictions Disabled");
}

public Action:EnableClassRestrict()
{
	ServerCommand("sm_cvar sm_classrestrict_enabled 1");
	CPrintToChatAll("[{haunted}Class Restrict{default}] {normal}Class Restrictions Re-Enabled");
}