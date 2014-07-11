// #-----------------------------------------------DOCUMENTATION-------------------------------------------------#
  /*
    In most cases with votes;
      1=enable  or    yes
      0=disable or    no
    RTDStatus;
      0 = RTD Disabled
      1 = RTD Enabled
    SSStatus;
      0 = GunSlinger Enabled (SlowSlinger Disabled)
      1 = GunSlinger Disabled (SlowSlinger Enabled)
      Yes, it's confusing
  */
// #---------------------------------------------END DOCUMENTATION-----------------------------------------------#
#pragma semicolon 1

#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION "1.1.5"

// Class Restrict Defines
#define CR_RED "sm_classrestrict_red"
#define CR_BLU "sm_classrestrict_blu"

//RTD Hook
new Handle:g_hRTDEnabled = INVALID_HANDLE;
new RTDStatus;
//SlowSlinger Hook
new Handle:g_hSSEnabled = INVALID_HANDLE;
new SSStatus;
//Timelimit Hook
new Handle:g_Cvar_TimeLimit = INVALID_HANDLE;

/*
  Vote Cooldowns
*/
//Timer Handles
new Handle:t_Intel = INVALID_HANDLE;    //Timer Intel
new Handle:t_RTD = INVALID_HANDLE;      //Timer RTD
new Handle:t_Class = INVALID_HANDLE;    //Timer Class Restrictions
new Handle:t_SS = INVALID_HANDLE;     //Timer SlowSlinger
new Handle:t_Scramble = INVALID_HANDLE;   //Timer Scramble Teams
//Can Vote Bools
new bool:g_CanVoteIntel = true;
new bool:g_CanVoteRTD = true;
new bool:g_CanVoteClass = true;
new bool:g_CanVoteSS = true;
new bool:g_CanVoteScramble = true;

public Plugin:myinfo = 
{
  name = "More Votes",
  author = "Js41637",
  description = "Additional voting options",
  version = PLUGIN_VERSION,
  url = "http://gamingsydney.com"
}

public OnPluginStart()
{
// #-------------------------------------------------COMMANDS----------------------------------------------------#
//  Misc
  RegAdminCmd("sm_resetcooldowns", Command_ResetCooldowns, ADMFLAG_BAN, "Resets the vote cooldowns");
//  Vote Intel Command
  RegConsoleCmd("sm_voteintel", Command_VoteIntel, "Vote to enable/disable Intel.");
// Class Restrictions Commands
  RegAdminCmd("sm_voteclass", Command_VoteClass, ADMFLAG_BAN, "Vote to enable/disable Class Restrictions.");
  RegAdminCmd("sm_setclasslimit", Command_SetClassLimit, ADMFLAG_BAN, "Sets limit on specified class");
  RegConsoleCmd("sm_validclasses", Command_ListValidClasses, "Displays list of valid class names");
//  RTD Commands
  RegAdminCmd("sm_disablertd", Command_DisableRTD, ADMFLAG_BAN, "Disables RTD.");
  RegAdminCmd("sm_enablertd", Command_EnableRTD, ADMFLAG_BAN, "Enables RTD");
  RegConsoleCmd("sm_votertd", Command_VoteRTD, "Vote to enable/disable RTD.");
//  Gunslinger/SlowSlinger Commands
  RegAdminCmd("sm_disablegunslinger", Command_DisableSS, ADMFLAG_BAN, "Disables GunSlinger.");
  RegAdminCmd("sm_enablegunslinger", Command_EnableSS, ADMFLAG_BAN, "Enables GunSlinger");
  RegAdminCmd("sm_disablegs", Command_DisableSS, ADMFLAG_BAN, "Disables GunSlinger");
  RegAdminCmd("sm_enablegs", Command_EnableSS, ADMFLAG_BAN, "Enables GunSlinger");
  RegConsoleCmd("sm_votegunslinger", Command_VoteSS, "Vote to enable/disable GunSlinger");
  RegConsoleCmd("sm_votegs", Command_VoteSS, "Vote to enable/disable GunSlinger");
//  Scramble Teams Commands
  RegAdminCmd("sm_scrambleteams", Command_ScrambleTeams, ADMFLAG_BAN, "Forces Scramble Team");
  RegConsoleCmd("sm_votescramble", Command_VoteScramble, "Vote to scramble teams");
// #--------------------------------------------LOAD CVAR SETTINGS-----------------------------------------------#
//  Hook RTD Status
  g_hRTDEnabled = FindConVar("sm_rtd_enabled");
  RTDStatus = GetConVarInt(g_hRTDEnabled);
  HookConVarChange(g_hRTDEnabled, ConVarChange);
//  Hook SlowSlinger Status
  g_hSSEnabled = FindConVar("sm_slowslinger_enabled");
  SSStatus = GetConVarInt(g_hSSEnabled);
  HookConVarChange(g_hSSEnabled, ConVarChange);
//  Hook Timelimit
  g_Cvar_TimeLimit = FindConVar("mp_timelimit");
}

//When a server cvar change is detected
public Action:Event_ServerCvar(Handle:event, const String:name[], bool:dontBroadcast) {
  decl String:cvarName[64];
  GetEventString(event, "cvarname", cvarName, sizeof(cvarName));
  //Stop cvar notify if it is about class restrict
  if (StrContains(cvarName, "classrestrict") == 3) {
    return Plugin_Handled;
  }
  return Plugin_Continue; 
}

public OnPluginEnd() // Kill all timers if there are any running
{
  if(t_Intel != INVALID_HANDLE) {
    KillTimer(t_Intel);
  }
  if(t_RTD != INVALID_HANDLE) {
    KillTimer(t_RTD);
  }
  if(t_Class != INVALID_HANDLE) {
    KillTimer(t_Class);
  }
  if(t_SS != INVALID_HANDLE)  {
    KillTimer(t_SS);
  }
  if(t_Scramble != INVALID_HANDLE)  {
    KillTimer(t_Scramble);
  }
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) //Hook on CVar Change
{
  RTDStatus = GetConVarInt(g_hRTDEnabled);
  SSStatus = GetConVarInt(g_hSSEnabled);
}

public Action:ReturnError(client) {
  CReplyToCommand(client, "{red}Error: Something went wrong!");
}

public Action:Command_VoteIntel(client, args) //sm_voteintel - Creates vote to enable/disable intel.
{
  if(IsVoteInProgress())  {
    return Plugin_Handled;
  }
  if(!g_CanVoteIntel) {
    ReplyToCommand(client, "[SM] You cannot vote at this time.");
    return Plugin_Handled;
  }

  new Handle:menu1 = CreateMenu(Handle_IntelVoteMenu);
  SetMenuTitle(menu1, "Disable/Enable Intel?");
  AddMenuItem(menu1, "no", "Disable Intel");
  AddMenuItem(menu1, "yes", "Enable Intel");
  SetMenuExitButton(menu1, false);
  ShowActivity(client,"Initiated vote Disable/Enable Intel");
  VoteMenuToAll(menu1, 20);
  //Start Cooldown
  if(t_Intel != INVALID_HANDLE) { 
    KillTimer(t_Intel); 
    t_Intel = INVALID_HANDLE; 
  }
  t_Intel = CreateTimer(90.0, Timer_IntelVoteCooldown);
  g_CanVoteIntel = false;
  return Plugin_Handled;
}

public Handle_IntelVoteMenu(Handle:menu1, MenuAction:action, param1, param2) //After Intel vote finished
{
  if (action == MenuAction_End) {
    /* This is called after VoteEnd */
    CloseHandle(menu1);
  }
  else if (action == MenuAction_VoteEnd)  {
    /* 1=yes, 0=no */
    if (param1 == 0)  {
      ServerCommand("sm_intelp2 0");
    }
    else  {
      ServerCommand("sm_intelp2 1");
    }
  }
}

public Action:Command_VoteRTD(client, args) //sm_votertd - Creates vote to enable/disable RTD.
{
  if(IsVoteInProgress())  {
    return Plugin_Handled;
  }
  if(!g_CanVoteRTD) {
    ReplyToCommand(client, "[SM] You cannot vote at this time.");
    return Plugin_Handled;
  }
 
  new Handle:menu2 = CreateMenu(Handle_RTDVoteMenu);
  SetMenuTitle(menu2, "Disable/Enable RTD?");
  AddMenuItem(menu2, "no", "Disable RTD");
  AddMenuItem(menu2, "yes", "Enable RTD");
  SetMenuExitButton(menu2, false);
  ShowActivity(client,"Initiated vote Disable/Enable RTD");
  VoteMenuToAll(menu2, 20);
  //Start Cooldown
  if(t_RTD != INVALID_HANDLE) { 
    KillTimer(t_RTD); 
    t_RTD = INVALID_HANDLE; 
  }
  t_RTD = CreateTimer(90.0, Timer_IntelVoteCooldown);
  g_CanVoteRTD = false;
  return Plugin_Handled;
}

public Handle_RTDVoteMenu(Handle:menu2, MenuAction:action, param1, param2) //After RTD vote finished
{
  if (action == MenuAction_End) {
    CloseHandle(menu2);
  }
  else if (action == MenuAction_VoteEnd)  {
    /* 1=enable (yes), 0=disable (no) */
    if (param1 == 0)  {
      ServerCommand("sm_cvar sm_rtd_enabled 0");
      CPrintToChatAll("{haunted}RTD Disabled");
    }
    else  {
      ServerCommand("sm_cvar sm_rtd_enabled 1");
      CPrintToChatAll("{haunted}RTD Enabled");
    }
  }
}

public Action:Command_VoteClass(client, args) //sm_voteclass - Creates vote to enable/disable Class Restrictions.
{
  if(IsVoteInProgress())  {
    return Plugin_Handled;
  }
  if(!g_CanVoteClass) {
    ReplyToCommand(client, "[SM] You cannot vote at this time.");
    return Plugin_Handled;
  }
 
  new Handle:menu3 = CreateMenu(Handle_ClassVoteMenu);
  SetMenuTitle(menu3, "Disable/Enable Class Restrictions?");
  AddMenuItem(menu3, "no", "Disable Class Restrictions");
  AddMenuItem(menu3, "yes", "Enable Class Restrictions");
  SetMenuExitButton(menu3, false);
  ShowActivity(client,"Initiated vote Disable/Enable Class Restrictions");
  VoteMenuToAll(menu3, 20);
  //Start Cooldown
  if(t_Class != INVALID_HANDLE) { 
    KillTimer(t_Class); 
    t_Class = INVALID_HANDLE; 
  }
  t_Class = CreateTimer(90.0, Timer_IntelVoteCooldown);
  g_CanVoteClass = false;
  return Plugin_Handled;
}

public Handle_ClassVoteMenu(Handle:menu3, MenuAction:action, param1, param2) //After Class vote finished
{
  if (action == MenuAction_End) {
    CloseHandle(menu3);
  }
  else if (action == MenuAction_VoteEnd)  {
    /* 1=enable (yes), 0=disable (no) */
    if (param1 == 0)  {
      ServerCommand("sm_cvar sm_classrestrict_enabled 0");
      CPrintToChatAll("{haunted}Class Restrictions Disabled");
    }
    else  {
      ServerCommand("sm_cvar sm_classrestrict_enabled 1");
      CPrintToChatAll("{haunted}Class Restrictions Enabled");
    }
  }
}

public Action:Command_VoteSS(client, args) //sm_gunslinger- Creates vote to enable/disable Gunslinger.
{
  if(IsVoteInProgress())  {
    return Plugin_Handled;
  }
  if(!g_CanVoteSS)  {
    ReplyToCommand(client, "[SM] You cannot vote at this time.");
    return Plugin_Handled;
  }
 
  new Handle:menu4 = CreateMenu(Handle_SSVoteMenu);
  SetMenuTitle(menu4, "Disable/Enable GunSlinger");
  AddMenuItem(menu4, "no", "Disable GunSlinger");
  AddMenuItem(menu4, "yes", "Enable GunSlinger");
  SetMenuExitButton(menu4, false);
  ShowActivity(client,"Initiated vote Disable/Enable Gunslinger");
  VoteMenuToAll(menu4, 20);
  //Start Cooldown
  if(t_SS != INVALID_HANDLE)  { 
    KillTimer(t_SS); 
    t_SS = INVALID_HANDLE; 
  }
  t_SS = CreateTimer(90.0, Timer_SSVoteCooldown);
  g_CanVoteSS = false;
  return Plugin_Handled;
}

public Handle_SSVoteMenu(Handle:menu4, MenuAction:action, param1, param2) //After Gunslinger vote finished
{
  if (action == MenuAction_End) {
    CloseHandle(menu4);
  }
  else if (action == MenuAction_VoteEnd)  {
    /* 1=enable (yes), 0=disable (no) */
    if (param1 == 0)  {
      ServerCommand("sm_cvar sm_slowslinger_enabled 1");
      CPrintToChatAll("{haunted}GunSlinger Disabled");
    }
    else  {
      ServerCommand("sm_cvar sm_slowslinger_enabled 0");
      CPrintToChatAll("{haunted}GunSlinger Enabled");
    }
  }
}

public Action:Command_VoteScramble(client, args) //Creates vote to scramble teams.
{
  if(IsVoteInProgress()) {
    return Plugin_Handled;
  }
  if(!g_CanVoteScramble) {
    ReplyToCommand(client, "[SM] You cannot vote at this time.");
    return Plugin_Handled;
  }
 
  new Handle:menu5 = CreateMenu(Handle_ScrambleVoteMenu);
  SetMenuTitle(menu5, "Scramble Teams?");
  AddMenuItem(menu5, "yes", "Yes");
  AddMenuItem(menu5, "no", "No");
  SetMenuExitButton(menu5, false);
  ShowActivity(client,"Initiated vote Scramble Teams");
  VoteMenuToAll(menu5, 20);
  //Start Cooldown
  if(t_Scramble != INVALID_HANDLE)  { 
    KillTimer(t_Scramble); 
    t_Scramble = INVALID_HANDLE; 
  }
  t_Scramble = CreateTimer(90.0, Timer_ScrambleVoteCooldown);
  g_CanVoteScramble = false;
  return Plugin_Handled;
}

public Handle_ScrambleVoteMenu(Handle:menu5, MenuAction:action, param1, param2) //After Scramble vote finished
{
  if (action == MenuAction_End) {
    CloseHandle(menu5);
  }
  else if (action == MenuAction_VoteEnd)  {
    /* 1=no, 0=yes */
    if (param1 == 0)  {
      ServerCommand("mp_scrambleteams 2");
      new timeleft;
      GetMapTimeLeft(timeleft);
      new mins, secs;
      mins = timeleft / 60;
      secs = timeleft % 60; 
      if (secs >= 30) {
        mins = mins+1;
      } 
      CreateTimer(10.0, Timer_DelayRTS, mins);
      CPrintToChatAll("{haunted}Teams are being scrambled!!");
    }
    else  {
      CPrintToChatAll("{haunted}Scramble Teams Failed");
    }
  }
}

public Action:Command_DisableRTD(client, args) //Command to disable RTD.
{
  if(RTDStatus == 1)  {
    ServerCommand("sm_cvar sm_rtd_enabled 0");
    CPrintToChatAll("{haunted}Disabling RTD");
  }
  else  {
    CReplyToCommand(client, "RTD already disabled.");
  }
}

public Action:Command_EnableRTD(client, args) //Command to enable RTD
{
  if(RTDStatus == 0)  {
    ServerCommand("sm_cvar sm_rtd_enabled 1");
    CPrintToChatAll("{haunted}Enabling RTD");
  }
  else  {
    CReplyToCommand(client, "RTD already enabled.");
  }
}

public Action:Command_DisableSS(client, args) //Command to Nerf Gunslinger (enable SlowSlinger).
{
  if(SSStatus == 0) {
    ServerCommand("sm_cvar sm_slowslinger_enabled 1");
    CPrintToChatAll("{haunted}Nerfing GunSlinger");
  }
  else  {
    CReplyToCommand(client, "GunSlinger already Nerfed.");
  }
}

public Action:Command_EnableSS(client, args) //Command to un-nerf GunSlinger (disable SlowSlinger).
{
  if(SSStatus == 1) {
    ServerCommand("sm_cvar sm_slowslinger_enabled 0");
    CPrintToChatAll("{haunted}Un-Nerfing GunSlinger");
  }
  else {
    CReplyToCommand(client, "GunSlinger already Un-Nerfed");
  }
}

public Action:Command_ScrambleTeams(client, args) //Command to Scramble Teams.
{
  CPrintToChatAll("{haunted}Teams are being scrambled!!");
  ServerCommand("mp_scrambleteams 2");
  new timeleft;
  GetMapTimeLeft(timeleft);
  new mins, secs;
  mins = timeleft / 60;
  secs = timeleft % 60; 
  if (secs >= 30) {
    mins = mins+1;
  } 
  CreateTimer(10.0, Timer_DelayRTS, mins);
  return Plugin_Handled;
}

public Action:Command_ResetCooldowns(client, args) //Command to reset vote cooldowns.
{
  if(t_Intel != INVALID_HANDLE) {
    KillTimer(t_Intel);
    t_Intel = INVALID_HANDLE;
    g_CanVoteIntel = true;
  }
  if(t_RTD != INVALID_HANDLE) {
    KillTimer(t_RTD);
    t_RTD = INVALID_HANDLE;
    g_CanVoteRTD = true;
  }
  if(t_Class != INVALID_HANDLE) {
    KillTimer(t_Class);
    t_Class = INVALID_HANDLE;
    g_CanVoteClass = true;
  }
  if(t_SS != INVALID_HANDLE)  {
    KillTimer(t_SS);
    t_SS = INVALID_HANDLE;
    g_CanVoteSS = true;
  }
  if(t_Scramble != INVALID_HANDLE)  {
    KillTimer(t_Scramble);
    t_Scramble = INVALID_HANDLE;
    g_CanVoteScramble = true;
  }
  CReplyToCommand(client, "{haunted}Cooldowns Reset.");
  return Plugin_Handled;
}

// #---------------------------------------------CLASS RESTRICTIONS----------------------------------------------#
public Action:Command_ListValidClasses(client, args) {
  CReplyToCommand(client, "{normal}Valid Classes:");
  CReplyToCommand(client, "{haunted}scout | soldier | pyro | demoman | demo | heavy | engineer | engy | medic | sniper | spy");
  return Plugin_Handled;
}

public Action:Command_SetClassLimit(client, args)
{
  if (args < 2 || args > 2) {
    CReplyToCommand(client, "{normal}Usage: {default}sm_setclasslimit <class> <limit>");
    CReplyToCommand(client, "{normal}Limit: {default}0 = disabled | -1 = no limit");
    CReplyToCommand(client, "{normal}Use the command {default}/validclasses {normal}to get a list of valid classes");
    return Plugin_Handled;
  }
  new String:class[16], String:limit[16];
  new climit;

  GetCmdArg(1, class, sizeof(class));
  GetCmdArg(2, limit, sizeof(limit));
  TrimString(limit);
  climit = StringToInt(limit);
//  RoundToNearest(climit);
  
  if(climit < -1) {
    CReplyToCommand(client, "Error: {normal}Invalid limit specified");
    CReplyToCommand(client, "{normal}Limit: {default}0 = disabled | -1 = no limit");
    return Plugin_Handled;
  }
  if(StrEqual("scout", class, false)) {
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("soldier", class, false)) {
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("pyro", class, false)) {
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("demoman", class, false) || StrEqual("demo", class, false)) {
    if(StrEqual("demo", class, false)) {
      class = "demoman";
    }
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("heavy", class, false)) {
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("engineer", class, false) || StrEqual("engy", class, false)) {
    if(StrEqual("engy", class, false)) {
      class = "engineer";
    }
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("medic", class, false)) {
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("sniper", class, false)) {
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else if(StrEqual("spy", class, false)) {
    if(climit == -1) {
      ServerCommand("sm_cvar %s_%s -1", CR_RED, class);
      ServerCommand("sm_cvar %s_%s -1", CR_BLU, class);
      CReplyToCommand(client, "{haunted}Disabling class restrictions for: %s", class);
    }
    else if(climit >= 0) {
      ServerCommand("sm_cvar %s_%s %i", CR_RED, class, climit);
      ServerCommand("sm_cvar %s_%s %i", CR_BLU, class, climit);
      CReplyToCommand(client, "{haunted}Setting class restrictions for '%s' to: %i", class, climit);
    }
    else {
      ReturnError(client);
    }
  }
  else {
    CReplyToCommand(client, "Error: {normal}Invalid class specified");
    CReplyToCommand(client, "{normal}Use the command {default}/validclasses {normal}to get a list of valid classes");
  }
  return Plugin_Handled;
}

// #--------------------------------------------------TIMERS-----------------------------------------------------#
public Action:Timer_DelayRTS(Handle:timer, any:mins) //Timer for SrambleTeams to reset timelimit.
{
  SetConVarInt(g_Cvar_TimeLimit, mins);
}

public Action:Timer_IntelVoteCooldown(Handle:timer) {
  g_CanVoteIntel = true;
  t_Intel = INVALID_HANDLE;
}
public Action:Timer_RTDVoteCooldown(Handle:timer) {
  g_CanVoteRTD = true;
  t_RTD = INVALID_HANDLE;
}
public Action:Timer_ClassVoteCooldown(Handle:timer) {
  g_CanVoteClass = true;
  t_Class = INVALID_HANDLE;
}
public Action:Timer_SSVoteCooldown(Handle:timer)  {
  g_CanVoteSS = true;
  t_SS = INVALID_HANDLE;  
}
public Action:Timer_ScrambleVoteCooldown(Handle:timer)  {
  g_CanVoteScramble = true;
  t_Scramble = INVALID_HANDLE;
}