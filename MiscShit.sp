/*
	Includes
*/
#include <sourcemod>
#include <tf2>
/*
	Defines
*/
#define DPSTEAMGROUP "http://steamcommunity.com/groups/dont_panic_group"
/*
	Handles
*/
new Handle:mumpan
/*
	Plugin Info
*/
public Plugin:myinfo = 
{
	name = "MiscShit",
	author = "Js41637",
	description = "Does stuff",
	version = "1.0",
	url = "http://gamingsydney.com"
}

public OnPluginStart()
{
// #---------------------------------------COMMANDS--------------------------------------------------#
	RegConsoleCmd("mumble", Panel_Mumble, "Open Mumble Server information");
	RegConsoleCmd("dp", Command_DontPanic, "Open DP! Steam Group");
}


public Action:Command_DontPanic(client, args)
{
	if(!IsClientInGame(client))
    {
        return Plugin_Handled;
    }
	ShowMOTDPanel(client, ".Don't Panic! Steam Group", DPSTEAMGROUP, MOTDPANEL_TYPE_URL );
	return Plugin_Handled;
}

public MumblePanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		CloseHandle(mumpan)
	}
}
 
public Action:Panel_Mumble(client, args)
{
	if(!IsClientInGame(client))
    {
        return Plugin_Handled;
    }
	
	mumpan = CreatePanel();
	SetPanelTitle(mumpan, "DP! Mumble Info");
	DrawPanelItem(mumpan, "Label: Don't Panic!", ITEMDRAW_RAWLINE);
	DrawPanelItem(mumpan, "~", ITEMDRAW_RAWLINE);
	DrawPanelItem(mumpan, "IP: 27.50.71.245", ITEMDRAW_RAWLINE);
	DrawPanelItem(mumpan, "Port: 55028", ITEMDRAW_RAWLINE);
	DrawPanelItem(mumpan, "~", ITEMDRAW_RAWLINE);
	DrawPanelItem(mumpan, "EXIT", ITEMDRAW_DEFAULT);
 
	SendPanelToClient(mumpan, client, MumblePanelHandler, 120);
 
	return Plugin_Handled;
}