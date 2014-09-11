/*
  Includes
*/
#include <sourcemod>
/*
  Defines
*/
#define PLUGIN_VERSION "0.1"
/*
  Strings
*/
new String:ReloadMsgBeg[100] = "Map will reload in:";
new String:ReloadMsgEnd[100] = "seconds";
new String:currentmap[65];
/*
  Handles
*/
new Handle:ReloadTimer = INVALID_HANDLE;
new Handle:ReloadCntrMsg = INVALID_HANDLE;
/*
  New things
*/
new ReloadTime;
/*
  Plugin Info
*/
public Plugin:myinfo = 
{
  name = "Reload Map",
  author = "Js41637",
  description = "Reloads a map",
  version = PLUGIN_VERSION,
  url = "http://gamingsydney.com"
}

public OnPluginStart()
{
// #----------------------------------------------CVARS CONFIGURATION------------------------------------------------#
  ReloadCntrMsg = CreateConVar("reload_cntr_msg","10","Seconds left until centre message", FCVAR_PLUGIN);
// #---------------------------------------------------COMMANDS------------------------------------------------------#
  RegAdminCmd("sm_reloadmap", Command_ReloadMap, ADMFLAG_SLAY, "Toggle Server Locking");
}

public Action:Command_ReloadMap(client, args)
{
  GetCurrentMap(currentmap, 65);
  ReloadTime = 15;
  if(ReloadTimer == INVALID_HANDLE)
  {
    ReloadTimer = CreateTimer(1.0, tReloadMap, INVALID_HANDLE, TIMER_REPEAT);
  }
}
  
public Action:tReloadMap(Handle:timer)
{
// #------------------PRINT COUNTDOWN TIMER------------------#
  PrintHintTextToAll("%s %i %s", ReloadMsgBeg, ReloadTime, ReloadMsgEnd);
  if(ReloadTime <= GetConVarFloat(ReloadCntrMsg))
  {
    PrintCenterTextAll("%s %i %s", ReloadMsgBeg, ReloadTime, ReloadMsgEnd);
    PrintToServer("%s %i %s", ReloadMsgBeg, ReloadTime, ReloadMsgEnd);
  }
  ReloadTime--;
  if(ReloadTime <= -1)
  {
// #-----------------------RELOAD MAP------------------------#
    KillTimer(ReloadTimer);
    PrintToChatAll("Reloading Map");
    ServerCommand("sm_map %s", currentmap);
  }
}