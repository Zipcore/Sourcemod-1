/* CONFIG STATUS
HLCONFIG:			|	SIXCONFIG:
	0 = Nothing		|		0 = Nothing
	1 = Stopwatch	|		1 = Stopwatch
	2 = Koth		|		2 = Koth
	3 = Standard	|		3 = Standard
	4 = CTF			|		4 = CTF
	5 = DOM			|		5 = Golden
	6 = TugOfWar	|
*/
/* LOCK STATUS
	0 = No Password
	1 = Default Password
	2 = Private Password
	3 = Temporary Password
*/

/*
	Includes
*/
#include <sourcemod>
#include <morecolors>
#include <tf2>
/*
	Defines
*/
#define PLUGIN_VERSION "2.2.2"
#define PRIVATE_PASSWORD "ponehsrule"
#define DEFAULT_PASSWORD "pug"
/*
	Handles
*/
new Handle:g_hLockStatus = INVALID_HANDLE;
new Handle:g_hHLConfig = INVALID_HANDLE;
new Handle:g_hSixConfig = INVALID_HANDLE;
new Handle:TempPassword = INVALID_HANDLE;
new Handle:PlayerTimer = INVALID_HANDLE;
new Handle:svpassword = INVALID_HANDLE;
new Handle:PlayersReq = INVALID_HANDLE;
/*
	New things
*/
new LockStatus;
new HLConfig;
new SixConfig;
/*
	Strings
*/
new String:TempPW[65];

/*
	Plugin Info
*/
public Plugin:myinfo = 
{
	name = "GamAus PUG Tools",
	author = "Js41637",
	description = "Tools for running PUG Server",
	version = PLUGIN_VERSION,
	url = "http://gamingsydney.com"
}

public OnPluginStart()
{
// #----------------------------------------------CVARS CONFIGURATION--------------------------------------------------#
	//Create CVARS
	g_hLockStatus = CreateConVar("pug_lockstatus", "0", "Reports lock status of server", FCVAR_PLUGIN);
	g_hHLConfig = CreateConVar("pug_hlconfig", "0", "Reports hl config status of server", FCVAR_PLUGIN);
	g_hSixConfig = CreateConVar("pug_sixconfig", "0", "Reports 6v config status of server", FCVAR_PLUGIN);
	PlayersReq = CreateConVar("pug_playersreq","0","How many players required to auto UGC OFF", FCVAR_PLUGIN);
	//Set thingys
	LockStatus = GetConVarInt(g_hLockStatus);
	HLConfig = GetConVarInt(g_hHLConfig);
	SixConfig = GetConVarInt(g_hSixConfig);
	//Hook on CVAR change
	HookConVarChange(g_hLockStatus, ConVarChange);
	HookConVarChange(g_hHLConfig, ConVarChange);
	HookConVarChange(g_hSixConfig, ConVarChange);
// #---------------------------------------------------COMMANDS--------------------------------------------------------#
	//Lock Server Commands
	RegAdminCmd("sm_serverl", Command_LockToggle, ADMFLAG_CUSTOM6, "Toggle Server Locking");
	RegAdminCmd("sm_sl", Command_LockToggle, ADMFLAG_CUSTOM6, "Toggle Server Locking");
	RegAdminCmd("sm_lock", Command_LockPrivateServer, ADMFLAG_CUSTOM6, "Lock Server");
	RegAdminCmd("sm_lockp", Command_LockPrivateServer, ADMFLAG_CUSTOM6, "Lock Server");
	RegAdminCmd("sm_unlock", Command_LockDefaultServer, ADMFLAG_CUSTOM6, "Unlock Server");
	RegAdminCmd("sm_lockd", Command_LockDefaultServer, ADMFLAG_CUSTOM6, "Unlock Server");
	RegAdminCmd("sm_removepassword", Command_RemovePW, ADMFLAG_CUSTOM6, "Remove Password");
	RegAdminCmd("sm_removepw", Command_RemovePW, ADMFLAG_CUSTOM6, "Remove Password");
	RegAdminCmd("sm_lockreset", Command_LockReset, ADMFLAG_CUSTOM6, "Reset locks");
	RegAdminCmd("sm_lockt", Command_TempPass, ADMFLAG_CUSTOM6, "Create temporary password");
	RegAdminCmd("sm_password", Command_TempPass, ADMFLAG_CUSTOM6, "Create temporary password");
	RegConsoleCmd("lockstatus", Command_LockStatus, "Retrieve lock status");
	//UGC Commands
	RegAdminCmd("sm_ugc", Command_UGCHLConfig, ADMFLAG_CUSTOM6, "Load UGC config");
	RegAdminCmd("sm_ugc6", Command_UGC6sConfig, ADMFLAG_CUSTOM6, "Load UGC config");
	RegAdminCmd("sm_ugc6s", Command_UGC6sConfig, ADMFLAG_CUSTOM6, "Load UGC config");
	//Auto-run Commands - not to be used by admins
	RegAdminCmd("sm_ugc_hlstart", Command_UGCHLStart, ADMFLAG_ROOT, "Load UGC config");
	RegAdminCmd("sm_ugc_6sstart", Command_UGC6sStart, ADMFLAG_ROOT, "Load UGC config");
	RegAdminCmd("sm_ugc_hlmsg", Command_UGCHLMsg, ADMFLAG_ROOT, "Load UGC config");
	RegAdminCmd("sm_ugc_6smsg", Command_UGC6sMsg, ADMFLAG_ROOT, "Load UGC config");
	RegAdminCmd("sm_ugc_off", Command_UGCOff, ADMFLAG_ROOT, "Unload UGC config");
	//Spectator Commands
	RegAdminCmd("sm_startspec", Command_StartSpec, ADMFLAG_CUSTOM6, "Message clients to enter spectator mode");
	RegAdminCmd("sm_enterspec", Command_StartSpec, ADMFLAG_CUSTOM6, "Message clients to enter spectator mode");
	RegConsoleCmd("stoptimer", Command_StopTimer, "Stops the timer");
// #-----------------------------------------NO NOTIFY ON PASSWORD CHANGE----------------------------------------------#
	svpassword = FindConVar("sv_password");

	new cflags = GetConVarFlags(svpassword);
	cflags &= ~FCVAR_NOTIFY;
	SetConVarFlags(svpassword, cflags);	
}

public OnPluginEnd()
{
	new cflags = GetConVarFlags(svpassword);
	cflags |= FCVAR_NOTIFY;
	SetConVarFlags(svpassword, cflags);
}

/*
	On ConVar Change
*/
public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	LockStatus = GetConVarInt(g_hLockStatus);
	HLConfig = GetConVarInt(g_hHLConfig);
	SixConfig = GetConVarInt(g_hSixConfig);
}
/*
	Change Password Actions
*/
public Action:RemovePassword() // Action to remove password
{
	ServerCommand("sv_password \"\"");
	SetConVarInt(g_hLockStatus, 0);
	CheckTemp();
}

public Action:LockDefault() // Action to lock default
{
	ServerCommand("sv_password %s", DEFAULT_PASSWORD);
	SetConVarInt(g_hLockStatus, 1);
	CheckTemp();
}

public Action:LockPrivate() // Action to lock Private
{
	ServerCommand("sv_password %s", PRIVATE_PASSWORD);
	SetConVarInt(g_hLockStatus, 2);
	CheckTemp();
}

public Action:LockTemp() // Action to lock Temp
{
	ServerCommand("sv_password %s", TempPW);
	SetConVarInt(g_hLockStatus, 3);
}

public Action:CheckTemp() // Action to kill TempPassword timer
{
	if(TempPassword != INVALID_HANDLE)
	{
		KillTimer(TempPassword);
		TempPassword = INVALID_HANDLE;
	}
}

/*
	Lock Server Commands
*/
public Action:Command_LockToggle(client, args) // Toggles between Default and Private server locking
{
	if(LockStatus == 0 || LockStatus == 2 || LockStatus == 3)
	{
		//Set DEFAULT password if PRIVATE or NO password is set
		LockDefault();
		CPrintToChatAll("[{haunted}ServerLocker{default}] {normal}Server has been {red}locked{normal} with default password");
		
	}
	else if(LockStatus == 1)
	{
		//Set PRIVATE password if default password is set
		LockPrivate();
		CPrintToChatAll("[{haunted}ServerLocker{default}] {normal}Server is already {red}locked{normal} with private password.");
	}
	else
    {
		//If sumfin goes wrong
		LockPrivate();
		CReplyToCommand(client, "[{haunted}ServerLocker{default}] {red}ERROR: Something has gone wrong, locking server.");
	}
	return Plugin_Handled;
}

public Action:Command_RemovePW(client, args) // Remove password on the server
{
    if(LockStatus == 0)
    {
        //If server already unlocked reply with message
        CReplyToCommand(client, "[{haunted}ServerLocker{default}] {normal}Server already has no password.");
        
    }
	else if(LockStatus == 1 || LockStatus == 2 || LockStatus == 3)
	{
        //UNLOCK server is DEFAULT or PRIVATE password set
        RemovePassword();
        CPrintToChatAll("[{haunted}ServerLocker{default}] {normal}Server has been completely {red}unlocked{normal} (no password)");
    }
	else
    {
        //If sumfin goes wrong
        LockPrivate();
        CReplyToCommand(client, "[{haunted}ServerLocker{default}] {red}ERROR: Something has gone wrong, locking server.");
    }
    return Plugin_Handled;
}

public Action:Command_LockPrivateServer(client, args) // Lock server to private password
{
	if(LockStatus == 2)
	{
        //If server already locked reply with message
		CReplyToCommand(client, "[{haunted}ServerLocker{default}] {normal}Server is already {red}locked{normal} with private password.");
		
	}
	else if(LockStatus == 1 || LockStatus == 0 || LockStatus == 3)
	{
		//Lock server with PRIVATE password if DEFAULT or NO password is set
		LockPrivate();
		CPrintToChatAll("[{haunted}ServerLocker{default}] {normal}Server has been {red}locked{normal} with private password.");
	}
	else
    {
        //If sumfin goes wrong
        LockPrivate();
        CReplyToCommand(client, "[{haunted}ServerLocker{default}] {red}ERROR: Something has gone wrong, locking server.");
    }
	return Plugin_Handled;
}

public Action:Command_LockDefaultServer(client, args) // Lock server to default password
{
	if(LockStatus == 1)
	{
        //If server already locked reply with message
		CReplyToCommand(client, "[{haunted}ServerLocker{default}] {normal}Server is already {red}locked{normal} with default password.");
		
	}
	else if(LockStatus == 0 || LockStatus == 2 || LockStatus == 3)
	{
		//LOCK server with DEFAULT password if NO or PRIVATE password is set
		LockDefault();
		CPrintToChatAll("[{haunted}ServerLocker{default}] {normal}Server has been {red}locked{normal} with default password.");
	}
	else
    {
        //If sumfin goes wrong
        LockPrivate();
        CReplyToCommand(client, "[{haunted}ServerLocker{default}] {red}ERROR: Something has gone wrong, locking server.");
    }
	return Plugin_Handled;
}

public Action:Command_TempPass(client, args) // Command to set temporary password on server
{
// #--------------------Check Command----------------#
	if (args < 1)
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}Usage: {default}sm_lockt <password>");
		return Plugin_Handled;
	}
	GetCmdArg(1, TempPW, sizeof(TempPW));
// #---------------------Lock Server-----------------#
	LockTemp();
// #------------------Message to Server--------------#
	CPrintToChatAll("[{haunted}ServerLocker{default}] {normal}Server has been {red}locked{normal} with temporary password.");
// #--------------------Create Timer-----------------#
	TempPassword = CreateTimer(40.0, tPassMsg);
	
	return Plugin_Continue;
}


public Action:Command_LockReset(client, args) // Resets lock function to default state
{
    RemovePassword();
    return Plugin_Handled;
}

public Action:Command_LockStatus(client, args) // Show information about current lock status
{
	if(LockStatus == 0)
	{
		CReplyToCommand(client, "[{haunted}ServerLocker{default}] {normal}Server currently has no password on it.");
	}
	else if(LockStatus == 1)
	{
		CReplyToCommand(client, "[{haunted}ServerLocker{default}] {normal}Server currently {red}locked{normal} with default password: pug");
	}
	else if(LockStatus == 2)
	{
		CReplyToCommand(client, "[{haunted}ServerLocker{default}] {normal}Server currently {red}locked{normal} with private password");
	}
	else if(LockStatus == 3)
	{
		CReplyToCommand(client, "[{haunted}ServerLocker{default}] {normal}Server currently {red}locked{normal} with temporary password");
	}
	else
	{
		CReplyToCommand(client, "[{haunted}Server Locker{default}] {red}Error retrieving password!");
		
	}
	return Plugin_Handled;
}
/*
	UGC Commands
*/
public Action:Command_UGCHLConfig(client, args) // Command to pick what UGC HL Config to execute
{
	decl String:config[65];
	if (args < 1)
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}Usage: {default}sm_ugc <config>");
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}Valid Configs: {default}stopwatch , koth , standard , ctf , dom , tugofwar , off")
		return Plugin_Handled;
	}
	
	GetCmdArg(1, config, sizeof(config));
	if(StrEqual("off", config, false))
	{
		if(HLConfig == 0)
		{
			CReplyToCommand(client, "[{haunted}PUG{default}] {normal}No HL Config Loaded")
		}
		else
		{
			CPrintToChatAll("[{haunted}PUG{default}] {normal}Disabling UGC HL Config");
			ServerCommand("exec \"ugc_off.cfg\"");
			return Plugin_Handled;
		}
	}
	else if(HLConfig != 0 || SixConfig != 0)
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {red}Config already loaded{normal}, /ugc off to unload current config")
		return Plugin_Handled;
	}
	else if(StrEqual("stopwatch", config, false))
	{
		SetConVarInt(g_hHLConfig, 1);
		CPrintToChatAll("[{haunted}PUG{default}] {normal}Executing UGC Stopwatch Config");
		ServerCommand("exec \"ugc_HL_stopwatch.cfg\"");
	}
	else if(StrEqual("koth", config, false))
	{
		SetConVarInt(g_hHLConfig, 2);
		CPrintToChatAll("[{haunted}PUG{default}] {normal}Executing UGC Koth Config");
		ServerCommand("exec \"ugc_HL_koth.cfg\"");
	}
	else if(StrEqual("standard", config, false))
	{
		SetConVarInt(g_hHLConfig, 3);
		CPrintToChatAll("[{haunted}PUG{default}] {normal}Executing UGC Standard Config");
		ServerCommand("exec \"ugc_HL_standard.cfg\"");
	}
	else if(StrEqual("ctf", config, false))
	{
		SetConVarInt(g_hHLConfig, 4);
		CPrintToChatAll("[{haunted}PUG{default}] {normal}Executing UGC CTF Config");
		ServerCommand("exec \"ugc_HL_ctf.cfg\"");
	}
	else if(StrEqual("dom", config, false))
	{
		SetConVarInt(g_hHLConfig, 5);
		CPrintToChatAll("[{haunted}PUG{default}] {normal}Executing UGC DOM Config");
		ServerCommand("exec \"ugc_HL_dom.cfg\"");
	}
	else if(StrEqual("tugofwar", config, false))
	{
		SetConVarInt(g_hHLConfig, 6);
		CPrintToChatAll("[{haunted}PUG{default}] {normal}Executing UGC TUGOFWAR Config");
		ServerCommand("exec \"ugc_HL_tugofwar.cfg\"");
	}
	else
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}Invalid config specified.");
	}
	return Plugin_Handled;
}
/*
	UGC 6s Commands
*/
public Action:Command_UGC6sConfig(client, args) // Command to pick what UGC 6v Config to execute
{
	decl String:config[65];
	if (args < 1)
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}Usage: {default}sm_ugc6s <config>");
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}Valid Configs: {default}stopwatch , koth , standard , ctf , golden , off")
		return Plugin_Handled;
	}
	
	GetCmdArg(1, config, sizeof(config));
	if(StrEqual("off", config, false))
	{
		if(SixConfig == 0)
		{
			CReplyToCommand(client, "[{haunted}PUG{default}] {normal}No 6v6 Config Loaded")
		}
		else
		{
			CPrintToChatAll("[{haunted}PUG{default}] {normal} Disabling UGC 6v Config");
			ServerCommand("exec \"ugc_off.cfg\"");
			return Plugin_Handled;
		}
	}
	else if(SixConfig != 0 || HLConfig != 0)
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {red}Config already loaded{normal}, /ugc off to unload current config")
		return Plugin_Handled;
	}
	else if(StrEqual("stopwatch", config, false))
	{
		SetConVarInt(g_hSixConfig, 1);
		CPrintToChatAll("[{haunted}PUG{default}] {normal} Executing UGC Stopwatch Config");
		ServerCommand("exec \"ugc_6v_stopwatch.cfg\"");
	}
	else if(StrEqual("koth", config, false))
	{
		SetConVarInt(g_hSixConfig, 2);
		CPrintToChatAll("[{haunted}PUG{default}] {normal} Executing UGC Koth Config");
		ServerCommand("exec \"ugc_6v_koth.cfg\"");
	}
	else if(StrEqual("standard", config, false))
	{
		SetConVarInt(g_hSixConfig, 3);
		CPrintToChatAll("[{haunted}PUG{default}] {normal} Executing UGC Standard Config");
		ServerCommand("exec \"ugc_6v_standard.cfg\"");
	}
	else if(StrEqual("ctf", config, false))
	{
		SetConVarInt(g_hSixConfig, 4);
		CPrintToChatAll("[{haunted}PUG{default}] {normal} Executing UGC CTF Config");
		ServerCommand("exec \"ugc_6v_ctf.cfg\"");
	}
	else if(StrEqual("golden", config, false))
	{
		SetConVarInt(g_hSixConfig, 5);
		CPrintToChatAll("[{haunted}PUG{default}] {normal} Executing UGC Golden Config");
		ServerCommand("exec \"ugc_6v_golden.cfg\"");
	}
	else
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}Invalid config specified.");
	}
	return Plugin_Handled;
}
/*
	Auto-Run commands
*/
public Action:Command_UGCOff(client, args) // Command automatically run at end of UGC match
{
	SetConVarInt(g_hHLConfig, 0);
	SetConVarInt(g_hSixConfig, 0);
	SetConVarInt(g_hLockStatus, 0);
	ServerCommand("exec \"sourcemod/sm_warmode_off.cfg\"");
	ServerCommand("mp_restartgame 1");
	CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC Config Successfully Un-Loaded");
	if(PlayerTimer != INVALID_HANDLE)
	{
		KillTimer(PlayerTimer); 
		PlayerTimer = INVALID_HANDLE;
	}
}

public Action:Command_UGCHLStart(client, args) // Command automatically run at start of UGC HL match
{
	ServerCommand("exec \"sourcemod/sm_warmode_on.cfg\"");
	ServerCommand("sm_lockd");
	ServerCommand("sm_ugc_hlmsg");
}

public Action:Command_UGC6sStart(client, args) // Command automatically run at start of UGC 6v match
{
	ServerCommand("exec \"sourcemod/sm_warmode_on.cfg\"");
	ServerCommand("sm_lockd");
	ServerCommand("sm_ugc_6smsg");
}

public Action:Command_UGCHLMsg(client, args) // Run after UGCHLStart
{
	PlayerTimer = CreateTimer(90.0, tPlayerCheck ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if(HLConfig == 1) //Stopwatch
	{
		CPrintToChatAll("{normal}UGC HL TF2 Stopwatch cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}PL & AD Map Rules = Winner is best 2/3 Stopwatch Halves");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC HL STOPWATCH Config Successfully Loaded");
	}
	else if(HLConfig == 2) //Koth
	{
		CPrintToChatAll("{normal}UGC TF2-HL KOTH cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}KOTH Rules - Winner is first to reach 4 TOTAL Caps");
		CPrintToChatAll("{normal}KOTH Rules - Max 3 caps allowed in round 1");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC HL KOTH Config Successfully Loaded");
	}
	else if(HLConfig == 3) //Standard
	{
		CPrintToChatAll("{normal}UGC HL TF2 Standard cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}CP Rules - Match Winner is first to reach 5 TOTAL Caps");
		CPrintToChatAll("{normal}CP Rules - Max 4 caps or 30 mins allowed in round 1");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC HL STANDARD Config Successfully Loaded");
	}
	else if(HLConfig == 4) //CTF
	{
		CPrintToChatAll("{normal}UGC HL TF2 CTF cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}CTF Rules - First to 10 total caps wins match, or highest combined score");
		CPrintToChatAll("{normal}CTF Rules - 7 cap limit in each 20 min half");
		CPrintToChatAll("{normal}Intel may be carried & capped past timelimit");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC HL CTF Config Successfully Loaded");
	}
	else if(HLConfig == 5) //DOM
	{
		CPrintToChatAll("{normal}UGC HL Domination cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}DOM Rules - Match Winner is best 2/3 rounds");
		CPrintToChatAll("{normal}DOM Rules - Switch starting colors each round");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC HL DOM Config Successfully Loaded");
	}
	else if(HLConfig == 6) //Tug Of War
	{
		CPrintToChatAll("{normal}UGC HL Tug of War cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}Tug of War Rules - One all cap wins each match half.");
		CPrintToChatAll("{normal}Tug of War Rules - If stalemated, the team with cart on enemy side wins half.");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC HL TUGOFWAR Config Successfully Loaded");
	}
	else //If shit goes wrong
	{
		CPrintToChatAll("[{haunted}PUG{default}] {red}ERROR: Something has gone wrong, configs should still be loaded")
	}
	CPrintToChatAll("{red}A map reload is recommend");
	return Plugin_Handled;
}

public Action:Command_UGC6sMsg(client, args) // Run after UGC6sStart
{
	PlayerTimer = CreateTimer(90.0, tPlayerCheck ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	if(SixConfig == 1) //Stopwatch
	{
		CPrintToChatAll("{normal}UGC 6v6 TF2 Stopwatch cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}AD Map Rules = Winner is best 2 of 3 Stopwatch Rounds");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC 6v STOPWATCH Config Successfully Loaded");
	}
	else if(SixConfig == 2) //Koth
	{
		CPrintToChatAll("{normal}UGC 6v6 TF2  KOTH cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}KOTH Rules - Winner is first to reach 4 TOTAL Caps");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC 6v KOTH Config Successfully Loaded");
	}
	else if(SixConfig == 3) //Standard
	{
		CPrintToChatAll("{normal}UGC 6v6 TF2 Standard cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}CP Rules - Match Winner is first to reach 5 TOTAL Caps");
		CPrintToChatAll("{normal}CP Rules - Max 4 caps or 30 mins allowed in round 1");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC 6v STANDARD Config Successfully Loaded");
	}
	else if(SixConfig == 4) //CTF
	{
		CPrintToChatAll("{normal}UGC 6v6 TF2 CTF cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}CTF Rules - First to 10 total caps or highest score wins");
		CPrintToChatAll("{normal}Intel may be carried & capped past timelimit");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC 6v CTF Config Successfully Loaded");
	}
	else if(SixConfig == 5) //Golden
	{
		CPrintToChatAll("{normal}UGC 6v6 TF2 golden cfg v.12-30-13 executed");
		CPrintToChatAll("{normal}Golden Rules - Max 1 caps or team with mid cap in 10 mins win");
		CPrintToChatAll("[{haunted}PUG{default}] {normal}UGC 6v GOLDEN Config Successfully Loaded");
	}
	else //If shit goes wrong
	{
		CPrintToChatAll("[{haunted}PUG{default}] {red}ERROR: Something has gone wrong, configs should still be loaded")
	}
	CPrintToChatAll("{red}A map reload is recommend");
	return Plugin_Handled;
}
/*
	Spectator Command
*/
public Action:Command_StartSpec(client, args) // Command to start timer for random enter spectator message
{
	CPrintToChatAll("[{haunted}PUG{default}] {normal}Prepare to enter spectator")
	new Float:duration = GetRandomFloat(4.0, 12.0);
	CreateTimer(duration, SpecMessage);  
	return Plugin_Continue;
}

public Action:Command_StopTimer(client, args) // Command to start timer for random enter spectator message
{
	if(PlayerTimer != INVALID_HANDLE)
	{
		KillTimer(PlayerTimer);
		PlayerTimer = INVALID_HANDLE;
		CPrintToChatAll("[{haunted}PUG{default}] {normal}Timer has been stopped")
	}
	else
	{
		CReplyToCommand(client, "[{haunted}PUG{default}] {normal}No timer is running :)");
	}
}

// #-------------------------------------------------------------------------------------------------------------------#
// #-----------------------------------------------------TIMERS--------------------------------------------------------#
// #-------------------------------------------------------------------------------------------------------------------#
public Action:SpecMessage(Handle:timer) // Action automatically run after StartSpec timer is finished to show message
{
	CPrintToChatAll("{default}CONSOLE: ENTER SPECTATOR MODE!!");
	CPrintToChatAll("{default}CONSOLE: ENTER SPECTATOR MODE!!");
	CPrintToChatAll("{default}CONSOLE: ENTER SPECTATOR MODE!!");
	return Plugin_Handled;
}

public Action:tPassMsg(Handle:timer) // Action automatically run after TempPassword timer is finished to reset password
{
	LockPrivate();
	TempPassword = INVALID_HANDLE;
	CPrintToChatAll("[{haunted}ServerLocker{default}] {normal}Temp password expired, locking with private");
	return Plugin_Handled;
}

public Action:tPlayerCheck(Handle:timer) // Action run every 60 seconds to check player count
{
	new pcount;
	new NofClients = GetClientCount(true);
	for (new i = 1; i <= NofClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			pcount++;
		}
	}
	if(pcount > GetConVarFloat(PlayersReq))
	{
		return Plugin_Handled;
	}
	KillTimer(PlayerTimer); 
	PlayerTimer = INVALID_HANDLE;
	PlayerTimer = CreateTimer(180.0, tPlayerCheck2);
	CPrintToChatAll("[{haunted}PUG{default}] {normal}No players detected, PUG mode disabled in 3 minutes");
	CPrintToChatAll("[{haunted}PUG{default}] {normal}Is this an error? Type /stoptimer if it is.");
	return Plugin_Handled;
}

public Action:tPlayerCheck2(Handle:timer) // Command automatically run after TempPassword timer is finished to reset password
{
	new pcount;
	new NofClients = GetClientCount(true);
	for (new i = 1; i <= NofClients ; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			pcount++;
		}
	}
	if(pcount > GetConVarFloat(PlayersReq))
	{
		PlayerTimer = INVALID_HANDLE;
		PlayerTimer = CreateTimer(90.0, tPlayerCheck ,0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	else
	{
		PlayerTimer = INVALID_HANDLE;
		ServerCommand("sm_ugc off");
	}
	return Plugin_Handled;
}