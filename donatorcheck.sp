#include <sourcemod>
#include <morecolors>
#include <regex>

new Handle:g_FloatRegex;

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name		= "Test",
	author	  	= "Js41637",
	description = "Check if client is donator or not",
	version	 	= PLUGIN_VERSION,
	url		 	= ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_testcmd", testcmd);
	g_FloatRegex = CompileRegex("^[-+]?([0-9]+\\.[0-9]+|[0-9]+)");
}

public Action:testcmd(client, args)
{
	if (args < 1)
	{
		new String:cmdName[22];
		GetCmdArg(0, cmdName, sizeof(cmdName));
		ReplyToCommand(client, "No args entered");
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "args detected")
		new String:cmdArg[22];
		GetCmdArg(1, cmdArg, sizeof(cmdArg));
		new RegexError:ret = REGEX_ERROR_NONE;
		MatchRegex(g_FloatRegex, cmdArg, ret);
		if(ret != REGEX_ERROR_NONE)
		{
			ReplyToCommand(client, "Invalid size/arg input");
			return Plugin_Handled;
		}
		new Float:fArg = StringToFloat(cmdArg);
		ReplyToCommand(client, "Checking if client is donator");
		if(IsClientDonator(client))
		{
			ReplyToCommand(client, "Client is a donator");
			if(fArg < 0.7 || fArg > 1.3)
			{
				ReplyToCommand(client, "Size is greater than or less than 0.7 or 1.3");
				return Plugin_Handled;
			}
		}
		else if(!IsClientDonator(client))
		{
			ReplyToCommand(client, "client is not donator or has root access");
			if(fArg == 0.0 || fArg > 7.0)
			{
				ReplyToCommand(client, "Size is 0.0 or greater than 7.0");
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Handled;
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