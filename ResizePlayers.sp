#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>
#include <tf2>
#define REQUIRE_EXTENSIONS
#include <tf2_stocks>

#define PLUGIN_VERSION			"1.4.1"
#define SELF_ADMIN_FLAG			ADMFLAG_GENERIC
#define TARGET_ADMIN_FLAG		ADMFLAG_CHEATS
#define JOIN_ADMIN_FLAG			ADMFLAG_CHEATS
#define CHAT_TAG				"\x05[SM]\x01 "
#define CONSOLE_TAG				"[SM] "
#define DEFAULT_FALLBACK		"0.4"
#define DEFAULT_HEAD_FALLBACK	"2.5"

public Plugin:myinfo =
{
    name		=	"Resize Players",
    author		=	"11530",
    description	=	"Tiny!",
    version		=	PLUGIN_VERSION,
    url			=	"http://www.sourcemod.net"
};

new Handle:g_hBounds = INVALID_HANDLE;
new Handle:g_hHeadBounds = INVALID_HANDLE;

new bool:g_bIsTF2 = false;
new bool:g_bLateLoaded = false;
new bool:g_bCustomDmgAvailable = false;
new bool:g_bResizeAvailable = false;
new bool:g_bResizeHeadAvailable = false;
new bool:g_bHitboxAvailable = false;
new bool:g_bBoundsOverrideSet = false;
new bool:g_bHeadBoundsOverrideSet = false;
new Handle:g_hResizeMenu = INVALID_HANDLE;
new Handle:g_hResizeHeadMenu = INVALID_HANDLE;
new Handle:g_hGetMaxHealth = INVALID_HANDLE;

new bool:g_bMenu;
new bool:g_bEnabled;
new Float:g_fDefaultResize;
new Float:g_fDefaultHeadResize;
new String:g_szDefaultResize[16];
new String:g_szDefaultHeadResize[16];
new String:g_szMenuItems[256];
new String:g_szMenuHeadItems[256];
new Float:g_fBoundMin;
new Float:g_fBoundMax;
new Float:g_fBoundHeadMin;
new Float:g_fBoundHeadMax;
new String:g_szBoundMin[16];
new String:g_szBoundMax[16];
new String:g_szBoundHeadMin[16];
new String:g_szBoundHeadMax[16];
new bool:g_bBackstab;
new g_iUnstick;
new g_iVoicesChanged;
new g_iJoinStatus;
new g_iDamage;
new g_iNotify;
new g_iLogging;
new g_iCooldown;

new g_iLastResize[MAXPLAYERS+1];
new g_iLastHeadResize[MAXPLAYERS+1];
new String:g_szClientLastScale[MAXPLAYERS+1][16];
new String:g_szClientLastHeadScale[MAXPLAYERS+1][16];
new String:g_szClientCurrentScale[MAXPLAYERS+1][16];
new String:g_szClientCurrentHeadScale[MAXPLAYERS+1][16];
new Float:g_fClientLastScale[MAXPLAYERS+1] = {1.0, ... };
new Float:g_fClientLastHeadScale[MAXPLAYERS+1] = {1.0, ... };
new Float:g_fClientCurrentScale[MAXPLAYERS+1] = {1.0, ... };
new Float:g_fClientCurrentHeadScale[MAXPLAYERS+1] = {1.0, ... };
new Handle:g_hClientResizeTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };
new Handle:g_hClientResizeHeadTimers[MAXPLAYERS+1] = { INVALID_HANDLE, ... };

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_resize_version", PLUGIN_VERSION, "\"Resize Players\" version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	new Handle:g_hEnabled = CreateConVar("sm_resize_enabled", "1", "0 = Disable plugin, 1 = Enable plugin.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hEnabled, ConVarEnabledChanged);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	new Handle:g_hDefaultResize = CreateConVar("sm_resize_defaultresize", "0.4", "Default scale of players when resized.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hDefaultResize, ConVarScaleChanged);
	GetConVarString(g_hDefaultResize, g_szDefaultResize, sizeof(g_szDefaultResize));
	g_fDefaultResize = StringToFloat(g_szDefaultResize);
	
	new Handle:g_hDefaultHeadResize = CreateConVar("sm_resize_defaultheadresize", "2.5", "Default scale of players' heads when resized.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hDefaultHeadResize, ConVarHeadScaleChanged);
	GetConVarString(g_hDefaultHeadResize, g_szDefaultHeadResize, sizeof(g_szDefaultHeadResize));
	g_fDefaultHeadResize = StringToFloat(g_szDefaultHeadResize);
	
	new Handle:g_hJoinStatus = CreateConVar("sm_resize_joinstatus", "0", "Resize upon joining: 0 = No one, 1 = Everyone's whole body, 3 = Everyone's head 5 = Everyone's head and whole body (Add 1 to any value for admin only).", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hJoinStatus, ConVarStatusChanged);
	g_iJoinStatus = GetConVarInt(g_hJoinStatus);
	
	new Handle:g_hMenu = CreateConVar("sm_resize_menu", "0", "0 = Disable menus, 1 = Enable menus when no command parameters are given.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hMenu, ConVarMenuChanged);
	g_bMenu = GetConVarBool(g_hMenu);
	
	new Handle:g_hVoices = CreateConVar("sm_resize_voices", "0", "0 = Normal voices, 1 = Voice pitch scales with size, 2 = No low-pitched voices, 3 = No high-pitched voices.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hVoices, ConVarVoicesChanged);
	g_iVoicesChanged = GetConVarInt(g_hVoices);
	
	new Handle:g_hDamage = CreateConVar("sm_resize_damage", "0", "0 = Normal damage, 1 = Damage given scales with size, 2 = No up-scaled damage, 3 = No down-scaled damage.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hDamage, ConVarDamageChanged);
	g_iDamage = GetConVarInt(g_hDamage);
	
	new Handle:g_hNotify = CreateConVar("sm_resize_notify", "1", "0 = No notifications, 1 = Respect sm_show_activity, 2 = Notify everyone.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hNotify, ConVarNotifyChanged);
	g_iNotify = GetConVarInt(g_hNotify);
	
	new Handle:g_hMenuItems = CreateConVar("sm_resize_menuitems", "0.1, Smallest; 0.25, Smaller; 0.50, Small; 1.00, Normal; 1.25, Large; 1.50, Larger; 2.00, Largest", "Resize menu's items.", FCVAR_PLUGIN);
	HookConVarChange(g_hMenuItems, ConVarMenuItemsChanged);
	GetConVarString(g_hMenuItems, g_szMenuItems, sizeof(g_szMenuItems));
	
	new Handle:g_hMenuHeadItems = CreateConVar("sm_resize_headmenuitems", "0.50, Smallest; 0.75, Small; 1.00, Normal; 2.00, Large; 3.00, Largest", "Head resize menu's items.", FCVAR_PLUGIN);
	HookConVarChange(g_hMenuHeadItems, ConVarMenuHeadItemsChanged);
	GetConVarString(g_hMenuHeadItems, g_szMenuHeadItems, sizeof(g_szMenuHeadItems));
	
	new Handle:g_hLogging = CreateConVar("sm_resize_logging", "1", "0 = No logging, 1 = Log self/target resizes, 2 = Log target resizes only.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hLogging, ConVarLoggingChanged);
	g_iLogging = GetConVarInt(g_hLogging);
	
	new Handle:g_hBackstab = CreateConVar("sm_resize_backstab", "0", "0 = Normal backstabs, 1 = Backstab damage scales proportionally with size.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hBackstab, ConVarBackstabChanged);
	g_bBackstab = GetConVarBool(g_hBackstab);
	
	new Handle:g_hUnstick = CreateConVar("sm_resize_unstick", "1", "Revert when stuck: 0 = Never, 1 = Self-resizes only, 2 = Respawns only, 3 = Self-resizes and respawns.", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hUnstick, ConVarUnstickChanged);
	g_iUnstick = GetConVarInt(g_hUnstick);
	
	new Handle:g_hCooldown = CreateConVar("sm_resize_cooldown", "0", "Cooldown duration for those without permission to bypass (in seconds).", FCVAR_PLUGIN, true, 0.0);
	HookConVarChange(g_hCooldown, ConVarCooldownChanged);
	g_iCooldown = GetConVarInt(g_hCooldown);
	
	g_hBounds = CreateConVar("sm_resize_bounds", "0.1, 3.0", "Lower (optional) and upper bounds for resizing, separated with a comma.", FCVAR_PLUGIN);
	HookConVarChange(g_hBounds, ConVarBoundsChanged);
	ParseConVarToLimits(g_hBounds, g_szBoundMin, sizeof(g_szBoundMin), g_fBoundMin, g_szBoundMax, sizeof(g_szBoundMax), g_fBoundMax);
	
	g_hHeadBounds = CreateConVar("sm_resize_headbounds", "0.25, 3.0", "Lower (optional) and upper bounds for head resizing, separated with a comma.", FCVAR_PLUGIN);
	HookConVarChange(g_hHeadBounds, ConVarHeadBoundsChanged);
	ParseConVarToLimits(g_hHeadBounds, g_szBoundHeadMin, sizeof(g_szBoundHeadMin), g_fBoundHeadMin, g_szBoundHeadMax, sizeof(g_szBoundHeadMax), g_fBoundHeadMax);
	
	decl String:szDir[64];
	GetGameFolderName(szDir, sizeof(szDir));
	if (strcmp(szDir, "tf") == 0 || strcmp(szDir, "tf_beta") == 0)
	{
		g_bIsTF2 = true;
	}
	
	new Handle:hConf = LoadGameConfigFile("sdkhooks.games");
	if (hConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "GetMaxHealth");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_hGetMaxHealth = EndPrepSDKCall();
		CloseHandle(hConf);
	}
	
	LoadTranslations("core.phrases.txt");
	LoadTranslations("common.phrases.txt");
	AddNormalSoundHook(SoundCallback);
	
	g_bResizeAvailable = (FindSendPropOffs("CBasePlayer", "m_flModelScale") != -1);
	g_bResizeHeadAvailable = (FindSendPropOffs("CTFPlayer", "m_flHeadScale") != -1); //TF2 Only
	g_bHitboxAvailable = ((FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMins") != -1) && FindSendPropOffs("CBasePlayer", "m_vecSpecifiedSurroundingMaxs") != -1);
	g_bCustomDmgAvailable = (GetFeatureStatus(FeatureType_Capability, "SDKHook_DmgCustomInOTD") == FeatureStatus_Available);
	
	HookEventEx("player_spawn", OnPlayerSpawn);
	
	RegAdminCmd("sm_resize", OnResizeCmd, TARGET_ADMIN_FLAG, "Toggles a client's size.");
	//RegAdminCmd("sm_scale", OnResizeCmd, TARGET_ADMIN_FLAG, "Toggles a client's size.");
	RegAdminCmd("sm_resizeme", OnResizeMeCmd, SELF_ADMIN_FLAG, "Toggles a client's size.");
	//RegAdminCmd("sm_scaleme", OnResizeMeCmd, SELF_ADMIN_FLAG, "Toggles a client's size.");
	RegAdminCmd("sm_resizehead", OnResizeHeadCmd, TARGET_ADMIN_FLAG, "Toggles a client's head size.");
	//RegAdminCmd("sm_scalehead", OnResizeHeadCmd, TARGET_ADMIN_FLAG, "Toggles a client's head size.");
	RegAdminCmd("sm_resizemyhead", OnResizeMyHeadCmd, SELF_ADMIN_FLAG, "Toggles a client's head size.");
	//RegAdminCmd("sm_scalemyhead", OnResizeMyHeadCmd, SELF_ADMIN_FLAG, "Toggles a client's head size.");
	
	if (g_bLateLoaded)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsClientReplay(i) && !IsClientSourceTV(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public OnConfigsExecuted()
{
	CheckDefaultValue(g_fDefaultResize, g_szDefaultResize, sizeof(g_szDefaultResize), "sm_resize_defaultresize", DEFAULT_FALLBACK);
	CheckDefaultValue(g_fDefaultHeadResize, g_szDefaultHeadResize, sizeof(g_szDefaultHeadResize), "sm_resize_defaultheadresize", DEFAULT_HEAD_FALLBACK);
	SetOverridePresence();
	BuildMenus();
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_fClientLastScale[i] = g_fDefaultResize;
		g_fClientLastHeadScale[i] = g_fDefaultHeadResize;
		strcopy(g_szClientCurrentScale[i], sizeof(g_szClientCurrentScale[]), "1.0");
		strcopy(g_szClientCurrentHeadScale[i], sizeof(g_szClientCurrentHeadScale[]), "1.0");
		strcopy(g_szClientLastScale[i], sizeof(g_szClientLastScale[]), g_szDefaultResize);
		strcopy(g_szClientLastHeadScale[i], sizeof(g_szClientLastHeadScale[]), g_szDefaultHeadResize);
		if (IsClientInGame(i) && !IsClientReplay(i) && !IsClientSourceTV(i) && IsClientAuthorized(i))
		{
			ReadjustInitialSize(i);
		}
	}
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	if (part == AdminCache_Overrides)
	{
		SetOverridePresence();
	}
}

public OnClientPutInServer(client)
{
	if (!IsClientReplay(client) && !IsClientSourceTV(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public OnClientPostAdminCheck(client)
{
	if (!IsClientReplay(client) && !IsClientSourceTV(client))
	{
		ReadjustInitialSize(client);
	}
}

stock ReadjustInitialSize(const client, const bool:bResetOnDisable = false)
{
	if (g_bEnabled)
	{
		switch (g_iJoinStatus)
		{
			case 1:
			{
				if (g_bResizeAvailable)
				{
					StopResizeTimer(client);
					ResizePlayer(client, g_szDefaultResize);
				}
			}
			case 2:
			{
				if (g_bResizeAvailable && CheckCommandAccess(client, "sm_resizejoinoverride", JOIN_ADMIN_FLAG, true))
				{
					StopResizeTimer(client);
					ResizePlayer(client, g_szDefaultResize);
				}
			}
			case 3:
			{
				if (g_bResizeHeadAvailable)
				{
					StopResizeHeadTimer(client);
					ResizePlayerHead(client, g_szDefaultHeadResize);
				}
			}
			case 4:
			{
				if (g_bResizeHeadAvailable && CheckCommandAccess(client, "sm_resizeheadjoinoverride", JOIN_ADMIN_FLAG, true))
				{
					StopResizeHeadTimer(client);
					ResizePlayerHead(client, g_szDefaultHeadResize);
				}
			}
			case 5:
			{
				if (g_bResizeAvailable)
				{
					StopResizeTimer(client);
					ResizePlayer(client, g_szDefaultResize);
				}
				if (g_bResizeHeadAvailable)
				{
					StopResizeHeadTimer(client);
					ResizePlayerHead(client, g_szDefaultHeadResize);
				}
			}
			case 6:
			{
				if (g_bResizeAvailable && CheckCommandAccess(client, "sm_resizejoinoverride", JOIN_ADMIN_FLAG, true))
				{
					StopResizeTimer(client);
					ResizePlayer(client, g_szDefaultResize);
				}
				if (g_bResizeHeadAvailable && CheckCommandAccess(client, "sm_resizeheadjoinoverride", JOIN_ADMIN_FLAG, true))
				{
					StopResizeHeadTimer(client);
					ResizePlayerHead(client, g_szDefaultHeadResize);
				}
			}
		}
	}
	else if (bResetOnDisable)
	{
		if (g_bResizeAvailable)
		{
			StopResizeTimer(client);
			ResizePlayer(client, "1.0");
		}
		if (g_bResizeHeadAvailable)
		{
			StopResizeHeadTimer(client);
			ResizePlayerHead(client, "1.0");
		}
	}
}

stock BuildMenus()
{
	ParseStringToMenu(g_hResizeMenu, ResizeMenuHandler, "Choose a Size:", g_szMenuItems);
	ParseStringToMenu(g_hResizeHeadMenu, ResizeHeadMenuHandler, "Choose a Head Size:", g_szMenuHeadItems);
}

stock ParseStringToMenu(&Handle:hMenu, const MenuHandler:hCallback, const String:szTitle[], const String:szItems[])
{
	new Float:fRatio, iSplitResult;
	decl String:szMenuItems[16][32], String:szNum[16], String:szItemLabel[32];
	
	new iExplodeResult = ExplodeString(szItems, ";", szMenuItems, sizeof(szMenuItems), sizeof(szMenuItems[]));
	hMenu = CreateMenu(hCallback);
	SetMenuTitle(hMenu, szTitle);
	
	if (!szItems[0])
	{
		AddMenuItem(hMenu, "1.0", "[NO ITEMS]", ITEMDRAW_DISABLED);
	}
	else
	{
		for (new i = 0; i < iExplodeResult && i < sizeof(szMenuItems); i++)
		{
			if (!szMenuItems[i][0])
			{
				continue;
			}
			if ((iSplitResult = SplitString(szMenuItems[i], ",", szNum, sizeof(szNum))) == -1)
			{
				TrimString(szMenuItems[i]);
				if ((fRatio = StringToFloat(szMenuItems[i])) <= 0.0)
				{					
					strcopy(szItemLabel, sizeof(szItemLabel), "Toggle");
				}
				else
				{
					FormatEx(szItemLabel, sizeof(szItemLabel), "%d%%", RoundToNearest(fRatio * 100.0));
				}
				AddMenuItem(hMenu, szMenuItems[i], szItemLabel);
			}
			else
			{
				TrimString(szNum);
				if ((fRatio = StringToFloat(szNum)) <= 0.0)
				{
					strcopy(szItemLabel, sizeof(szItemLabel), "Toggle");
				}
				else
				{
					TrimString(szMenuItems[i][iSplitResult]);
					FormatEx(szItemLabel, sizeof(szItemLabel), "%d%% - %s", RoundToNearest(fRatio * 100.0), szMenuItems[i][iSplitResult]);
				}
				AddMenuItem(hMenu, szNum, szItemLabel);
			}
		}
	}
	return iExplodeResult;
}

stock ParseConVarToLimits(const Handle:hConvar, String:szMinString[], const iMinStringLength, &Float:fMin, String:szMaxString[], const iMaxStringLength, &Float:fMax)
{
	new iSplitResult;
	decl String:szBounds[256];
	GetConVarString(hConvar, szBounds, sizeof(szBounds));
	
	if ((iSplitResult = SplitString(szBounds, ",", szMinString, iMinStringLength)) != -1 && (fMin = StringToFloat(szMinString)) >= 0.0)
	{
		TrimString(szMinString);
		strcopy(szMaxString, iMaxStringLength, szBounds[iSplitResult]);
	}
	else
	{
		strcopy(szMinString, iMinStringLength, "0.0");
		fMin = 0.0;
		strcopy(szMaxString, iMaxStringLength, szBounds);
	}
	TrimString(szMaxString);
	fMax = StringToFloat(szMaxString);
	
	new iMarkInMin = FindCharInString(szMinString, '.'), iMarkInMax = FindCharInString(szMaxString, '.');
	Format(szMinString, iMinStringLength, "%s%s%s", (iMarkInMin == 0 ? "0" : ""), szMinString, (iMarkInMin == -1 ? ".0" : (iMarkInMin == (strlen(szMinString) - 1) ? "0" : "")));
	Format(szMaxString, iMaxStringLength, "%s%s%s", (iMarkInMax == 0 ? "0" : ""), szMaxString, (iMarkInMax == -1 ? ".0" : (iMarkInMax == (strlen(szMaxString) - 1) ? "0" : "")));
	
	if (fMin > fMax)
	{
		new Float:fTemp = fMax;
		fMax = fMin;
		fMin = fTemp;
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bEnabled)
	{
		new userid = GetEventInt(event, "userid");
		new client = GetClientOfUserId(userid);
		
		if (client < 1)
		{
			return Plugin_Continue;
		}
		
		//Resize back to specified scale on spawn.
		if (IsPlayerAlive(client))
		{
			ResizePlayer(client, g_szClientCurrentScale[client]);
			
			//If server wants to unstick on spawn, then check player is stuck.
			if ((g_iUnstick == 2 || g_iUnstick == 3) && g_fClientCurrentScale[client] != 1.0 && IsPlayerStuck(client))
			{
				StopResizeTimer(client);
				ResizePlayer(client, "1.0");
				PrintToChat(client, "%sYou were \x05resized\x01 to \x051.0\x01 to avoid being stuck.", CHAT_TAG);
			}
		}
	}
	return Plugin_Continue;
}

stock bool:ResizePlayer(const client, const String:szScale[] = "0.0", const bool:bLog = false, const iOrigin = -1, const String:szTime[] = "0.0", const bool:bCheckStuck = false)
{
	new Float:fScale = StringToFloat(szScale), Float:fTime = StringToFloat(szTime);
	decl String:szOriginalScale[16];
	strcopy(szOriginalScale, sizeof(szOriginalScale), g_szClientCurrentScale[client]);
	
	if (fScale == 0.0)
	{
		if (g_fClientCurrentScale[client] != g_fClientLastScale[client])
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fClientLastScale[client]);
			//SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * g_fClientLastScale[client]);
			g_fClientCurrentScale[client] = g_fClientLastScale[client];
			strcopy(g_szClientCurrentScale[client], sizeof(g_szClientCurrentScale[]), g_szClientLastScale[client]);
		}
		else
		{
			SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
			//SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0);
			g_fClientCurrentScale[client] = 1.0;
			strcopy(g_szClientCurrentScale[client], sizeof(g_szClientCurrentScale[]), "1.0");
		}
	}
	else
	{
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", fScale);
		//SetEntPropFloat(client, Prop_Send, "m_flStepSize", 18.0 * fScale);
		g_fClientCurrentScale[client] = fScale;
		strcopy(g_szClientCurrentScale[client], sizeof(g_szClientCurrentScale[]), szScale);
	}
	
	if (g_bHitboxAvailable)
	{
		UpdatePlayerHitbox(client);
	}
	
	if (bCheckStuck && IsPlayerAlive(client) && IsPlayerStuck(client))
	{
		ResizePlayer(client, szOriginalScale);
		return false;
	}
	
	if (fScale != 1.0 && fScale != 0.0)
	{
		g_fClientLastScale[client] = fScale;
		strcopy(g_szClientLastScale[client], sizeof(g_szClientLastScale[]), szScale);
	}
	
	if (fTime > 0.0)
	{
		g_hClientResizeTimers[client] = CreateTimer(fTime, ResizeTimer, GetClientUserId(client));
	}
	
	if (bLog)
	{
		if (iOrigin > -1)
		{
			if (fTime > 0.0)
			{
				LogAction(iOrigin, client, "\"%L\" resized \"%L\" to %s for %s seconds.", iOrigin, client, g_szClientCurrentScale[client], szTime);				
			}
			else
			{
				LogAction(iOrigin, client, "\"%L\" resized \"%L\" to %s.", iOrigin, client, g_szClientCurrentScale[client]);
			}
		}
		else
		{
			LogAction(0, client, "\"%L\" was resized to %s.", client, g_szClientCurrentScale[client]);
		}
	}
	return true;
}

stock ResizePlayerHead(const client, const String:szScale[] = "0.0", const bool:bLog = false, const iOrigin = -1, const String:szTime[] = "0.0")
{
	new Float:fScale = StringToFloat(szScale), Float:fTime = StringToFloat(szTime);
	if (fScale == 0.0)
	{
		if (g_fClientCurrentHeadScale[client] != g_fClientLastHeadScale[client])
		{
			//SetEntPropFloat(client, Prop_Send, "m_flHeadScale", g_fClientLastHeadScale[client]);
			g_fClientCurrentHeadScale[client] = g_fClientLastHeadScale[client];
			strcopy(g_szClientCurrentHeadScale[client], sizeof(g_szClientCurrentHeadScale[]), g_szClientLastHeadScale[client]);
		}
		else
		{
			//SetEntPropFloat(client, Prop_Send, "m_flHeadScale", 1.0);
			g_fClientCurrentHeadScale[client] = 1.0;
			strcopy(g_szClientCurrentHeadScale[client], sizeof(g_szClientCurrentHeadScale[]), "1.0");
		}
	}
	else
	{
		if (fScale != 1.0)
		{
			g_fClientLastHeadScale[client] = fScale;
			strcopy(g_szClientLastHeadScale[client], sizeof(g_szClientLastHeadScale[]), szScale);
		}
		//SetEntPropFloat(client, Prop_Send, "m_flHeadScale", fScale);
		g_fClientCurrentHeadScale[client] = fScale;
		strcopy(g_szClientCurrentHeadScale[client], sizeof(g_szClientCurrentHeadScale[]), szScale);
	}
	
	if (fTime > 0.0)
	{
		g_hClientResizeHeadTimers[client] = CreateTimer(fTime, ResizeHeadTimer, GetClientUserId(client));
	}
	
	if (bLog)
	{
		if (iOrigin > -1)
		{
			if (fTime > 0.0)
			{
				LogAction(iOrigin, client, "\"%L\" resized \"%L\"'s head to %s for %s seconds.", iOrigin, client, g_szClientCurrentHeadScale[client], szTime);
			}
			else
			{
				LogAction(iOrigin, client, "\"%L\" resized \"%L\"'s head to %s.", iOrigin, client, g_szClientCurrentHeadScale[client]);
			}
		}
		else
		{			
			LogAction(0, client, "\"%L\"'s head was resized to %s.", client, g_szClientCurrentHeadScale[client]);
		}
	}
}

stock UpdatePlayerHitbox(const client)
{
	static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };
	static const Float:vecGenericPlayerMin[3] = { -16.5, -16.5, 0.0 }, Float:vecGenericPlayerMax[3] = { 16.5,  16.5, 73.0 };
	decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];
	if (g_bIsTF2)
	{
		vecScaledPlayerMin = vecTF2PlayerMin;
		vecScaledPlayerMax = vecTF2PlayerMax;
	}
	else
	{
		vecScaledPlayerMin = vecGenericPlayerMin;
		vecScaledPlayerMax = vecGenericPlayerMax;
	}
	ScaleVector(vecScaledPlayerMin, g_fClientCurrentScale[client]);
	ScaleVector(vecScaledPlayerMax, g_fClientCurrentScale[client]);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

stock bool:IsPlayerStuck(const client)
{
	decl Float:vecMins[3], Float:vecMaxs[3], Float:vecOrigin[3];
	GetClientMins(client, vecMins);
	GetClientMaxs(client, vecMaxs);
	GetClientAbsOrigin(client, vecOrigin);
	TR_TraceHullFilter(vecOrigin, vecOrigin, vecMins, vecMaxs, MASK_PLAYERSOLID, TraceEntityFilterPlayer, client);
	return TR_DidHit();
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity < 1 || entity > MaxClients);
}

bool:IsClientOnCooldown(const client, const now, const bool:headonly)
{
	if (g_iCooldown > 0 && !CheckCommandAccess(client, "sm_resizecooldownbypass", ADMFLAG_GENERIC))
	{
		new iTimeLeft = (headonly ? g_iLastHeadResize[client] : g_iLastResize[client]) + g_iCooldown - now;
		if (iTimeLeft > 0)
		{
			ReplyToCommand(client, "%sYou must wait another %d second%s.", CHAT_TAG, iTimeLeft, (iTimeLeft != 1 ? "s" : ""));
			return true;
		}
	}
	return false;
}

public Action:OnResizeMeCmd(client, args)
{
	if (g_bEnabled)
	{
		if (!g_bResizeAvailable)
		{
			ReplyToCommand(client, "%sCannot use command in this game.", CHAT_TAG);
			return Plugin_Handled;
		}
		
		new iNow = GetTime();
		if (IsClientOnCooldown(client, iNow, false))
		{
			return Plugin_Handled;
		}
		
		if (client == 0)
		{
			PrintToServer("%s%T", CONSOLE_TAG, "Command is in-game only", LANG_SERVER);
			return Plugin_Handled;
		}
		
		if (args == 0)
		{
			if (g_bMenu)
			{
				DisplayMenuSafely(g_hResizeMenu, client);
				return Plugin_Handled;
			}
			else if (!IsClientAllowedPastBounds(client) && ((g_fClientCurrentScale[client] != g_fClientLastScale[client] && (g_fClientLastScale[client] < g_fBoundMin || g_fClientLastScale[client] > g_fBoundMax)) || (g_fClientCurrentScale[client] == g_fClientLastScale[client] && (1.0 < g_fBoundMin || 1.0 > g_fBoundMax))))
			{
				ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBoundMin, g_szBoundMax);
				return Plugin_Handled;
			}
			else
			{
				StopResizeTimer(client);
				if (ResizePlayer(client, _, g_iLogging == 1, _, _, g_iUnstick == 1 || g_iUnstick == 3))
				{
					g_iLastResize[client] = iNow;
					NotifyPlayers(false, client, g_szClientCurrentScale[client], client);
				}
				else
				{
					ReplyToCommand(client, "%sYou were not resized to avoid being stuck.", CHAT_TAG);
				}
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(client, "%sUsage: sm_resizeme", CHAT_TAG);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:OnResizeMyHeadCmd(client, args)
{
	if (g_bEnabled)
	{
		if (!g_bResizeHeadAvailable)
		{
			ReplyToCommand(client, "%sCannot use command in this game.", CHAT_TAG);
			return Plugin_Handled;
		}
		
		new iNow = GetTime();
		if (IsClientOnCooldown(client, iNow, true))
		{
			return Plugin_Handled;
		}
		
		if (client == 0)
		{
			PrintToServer("%s%T", CONSOLE_TAG, "Command is in-game only", LANG_SERVER);
			return Plugin_Handled;
		}
		
		if (args == 0)
		{
			if (g_bMenu)
			{
				DisplayMenuSafely(g_hResizeHeadMenu, client);
				return Plugin_Handled;
			}
			else if (!IsClientAllowedPastBounds(client, true) && ((g_fClientCurrentHeadScale[client] != g_fClientLastHeadScale[client] && (g_fClientLastHeadScale[client] < g_fBoundHeadMin || g_fClientLastHeadScale[client] > g_fBoundHeadMax)) || (g_fClientCurrentHeadScale[client] == g_fClientLastHeadScale[client] && (1.0 < g_fBoundHeadMin || 1.0 > g_fBoundHeadMax))))
			{
				ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBoundHeadMin, g_szBoundHeadMax);
				return Plugin_Handled;
			}
			else
			{
				StopResizeHeadTimer(client);
				ResizePlayerHead(client, _, g_iLogging == 1);
				g_iLastHeadResize[client] = iNow;
				NotifyPlayers(true, client, g_szClientCurrentHeadScale[client], client);
				return Plugin_Handled;
			}
		}
		else
		{
			ReplyToCommand(client, "%sUsage: sm_resizemyhead", CHAT_TAG);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:OnResizeCmd(client, args)
{
	if (g_bEnabled)
	{
		if (!g_bResizeAvailable)
		{
			ReplyToCommand(client, "%sCannot use command in this game.", CHAT_TAG);
			return Plugin_Handled;
		}
		
		new iNow = GetTime();
		if (IsClientOnCooldown(client, iNow, false))
		{
			return Plugin_Handled;
		}
		
		if (args == 0)
		{
			if (client == 0)
			{
				PrintToServer("%s%T", CONSOLE_TAG, "Command is in-game only", LANG_SERVER);
				return Plugin_Handled;
			}
			
			if (g_bMenu)
			{
				DisplayMenuSafely(g_hResizeMenu, client);
				return Plugin_Handled;
			}
			else if (!IsClientAllowedPastBounds(client) && ((g_fClientCurrentScale[client] != g_fClientLastScale[client] && (g_fClientLastScale[client] < g_fBoundMin || g_fClientLastScale[client] > g_fBoundMax)) || (g_fClientCurrentScale[client] == g_fClientLastScale[client] && (1.0 < g_fBoundMin || 1.0 > g_fBoundMax))))
			{
				ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBoundMin, g_szBoundMax);
				return Plugin_Handled;
			}
			else
			{
				StopResizeTimer(client);
				if (ResizePlayer(client, _, g_iLogging == 1, _, _, g_iUnstick == 1 || g_iUnstick == 3))
				{
					g_iLastResize[client] = iNow;
					NotifyPlayers(false, client, g_szClientCurrentScale[client], client);
				}
				else
				{
					ReplyToCommand(client, "%sYou were not resized to avoid being stuck.", CHAT_TAG);
					return Plugin_Handled;
				}
			}
		}
		else
		{
			new target_count, bool:tn_is_ml, iTargetList[MAXPLAYERS];
			decl String:szTargetName[MAX_TARGET_LENGTH], String:szTarget[MAX_NAME_LENGTH];
			GetCmdArg(1, szTarget, sizeof(szTarget));
			if ((target_count = ProcessTargetString(szTarget, client, iTargetList, MAXPLAYERS, 0, szTargetName, sizeof(szTargetName), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			new String:szScale[16] = "0.0", String:szTime[16] = "0.0";
			new Float:fScale = 0.0, Float:fTime = 0.0;
			if (args > 1)
			{
				GetCmdArg(2, szScale, sizeof(szScale));
				TrimString(szScale);

				fScale = StringToFloat(szScale);
				if (IsClientAllowedPastBounds(client))
				{
					if (fScale <= 0.0)
					{
						ReplyToCommand(client, "%sInvalid size specified.", CHAT_TAG);
						return Plugin_Handled;
					}
				}
				else if (fScale <= 0.0 || (fScale < g_fBoundMin || fScale > g_fBoundMax))
				{
					ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBoundMin, g_szBoundMax);
					return Plugin_Handled;
				}
				
				if (args > 2)
				{					
					GetCmdArg(3, szTime, sizeof(szTime));
					TrimString(szTime);
					fTime = StringToFloat(szTime);
						
					if (fTime <= 0.0)
					{
						ReplyToCommand(client, "%sInvalid duration specified.", CHAT_TAG);
						return Plugin_Handled;
					}	
				}
			}
			new bool:bResult, bool:bIsSelfTarget = ((!tn_is_ml || target_count == 1) && client == iTargetList[0]);
			new bool:bLog = (g_iLogging == 1 || (g_iLogging == 2 && !bIsSelfTarget)), bool:bCheckStuck = (bIsSelfTarget && (g_iUnstick == 1 || g_iUnstick == 3));
			for (new i = 0; i < target_count; i++)
			{
				if (IsClientReplay(iTargetList[i]) || IsClientSourceTV(iTargetList[i]))
				{
					continue;
				}
				StopResizeTimer(iTargetList[i]);
				bResult = ResizePlayer(iTargetList[i], szScale, bLog, client, szTime, bCheckStuck);
			}
			
			if (!bResult)
			{
				ReplyToCommand(client, "%sYou were not resized to avoid being stuck.", CHAT_TAG);
				return Plugin_Handled;
			}
			else if (tn_is_ml)
			{
				NotifyPlayers(false, client, szScale, _, szTargetName, szTime);
			}
			else
			{
				NotifyPlayers(false, client, szScale, iTargetList[0], _, szTime);
			}
			g_iLastResize[client] = iNow;
		}
	}
	return Plugin_Handled;
}

public Action:OnResizeHeadCmd(client, args)
{	
	if (g_bEnabled)
	{
		if (!g_bResizeHeadAvailable)
		{
			ReplyToCommand(client, "%sCannot use command in this game.", CHAT_TAG);
			return Plugin_Handled;
		}
		
		new iNow = GetTime();
		if (IsClientOnCooldown(client, iNow, true))
		{
			return Plugin_Handled;
		}
		
		if (args == 0)
		{
			if (client == 0)
			{
				PrintToServer("%s%T", CONSOLE_TAG, "Command is in-game only", LANG_SERVER);
				return Plugin_Handled;
			}
		
			if (g_bMenu)
			{
				DisplayMenuSafely(g_hResizeHeadMenu, client);
				return Plugin_Handled;
			}
			else if (!IsClientAllowedPastBounds(client, true) && ((g_fClientCurrentHeadScale[client] != g_fClientLastHeadScale[client] && (g_fClientLastHeadScale[client] < g_fBoundHeadMin || g_fClientLastHeadScale[client] > g_fBoundHeadMax)) || (g_fClientCurrentHeadScale[client] == g_fClientLastHeadScale[client] && (1.0 < g_fBoundHeadMin || 1.0 > g_fBoundHeadMax))))
			{
				ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBoundHeadMin, g_szBoundHeadMax);
				return Plugin_Handled;
			}
			else
			{
				StopResizeHeadTimer(client);
				ResizePlayerHead(client, _, g_iLogging == 1);
				g_iLastHeadResize[client] = iNow;
				NotifyPlayers(true, client, g_szClientCurrentHeadScale[client], client);
				return Plugin_Handled;
			}
		}
		else
		{
			new target_count, bool:tn_is_ml, iTargetList[MAXPLAYERS];
			decl String:szTargetName[MAX_TARGET_LENGTH], String:szTarget[MAX_NAME_LENGTH];
			GetCmdArg(1, szTarget, sizeof(szTarget));
			if ((target_count = ProcessTargetString(szTarget, client, iTargetList, MAXPLAYERS, 0, szTargetName, sizeof(szTargetName), tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			new String:szScale[16] = "0.0", String:szTime[16] = "0.0";
			new Float:fScale = 0.0, Float:fTime = 0.0;			
			if (args > 1)
			{
				GetCmdArg(2, szScale, sizeof(szScale));
				TrimString(szScale);
				
				fScale = StringToFloat(szScale);
				if (IsClientAllowedPastBounds(client, true))
				{
					if (fScale <= 0.0)
					{
						ReplyToCommand(client, "%sInvalid size specified.", CHAT_TAG);
						return Plugin_Handled;
					}
				}
				else if (fScale <= 0.0 || (fScale < g_fBoundHeadMin || fScale > g_fBoundHeadMax))
				{
					ReplyToCommand(client, "%sSize must be between \x05%s\x01 and \x05%s\x01.", CHAT_TAG, g_szBoundHeadMin, g_szBoundHeadMax);
					return Plugin_Handled;
				}
				
				if (args > 2)
				{
					GetCmdArg(3, szTime, sizeof(szTime));
					TrimString(szTime);
					fTime = StringToFloat(szTime);
						
					if (fTime <= 0.0)
					{
						ReplyToCommand(client, "%sInvalid duration specified.", CHAT_TAG);
						return Plugin_Handled;
					}
				}
			}
			
			new bool:bIsSelfTarget = ((!tn_is_ml || target_count == 1) && client == iTargetList[0]);
			new bool:bLog = (g_iLogging == 1 || (g_iLogging == 2 && !bIsSelfTarget));
			for (new i = 0; i < target_count; i++)
			{
				if (IsClientReplay(iTargetList[i]) || IsClientSourceTV(iTargetList[i]))
				{
					continue;
				}
				StopResizeHeadTimer(iTargetList[i]);
				ResizePlayerHead(iTargetList[i], szScale, bLog, client, szTime);
			}
			
			if (tn_is_ml)
			{
				NotifyPlayers(true, client, szScale, _, szTargetName, szTime);
			}
			else
			{
				NotifyPlayers(true, client, szScale, iTargetList[0], _, szTime);
			}
			g_iLastHeadResize[client] = iNow;
		}
	}
	return Plugin_Handled;
}

stock bool:NotifyPlayers(const bool:bHead, const iOrigin, const String:szScale[], const iSingleTarget = -1, const String:szMultiTarget[] = "", const String:szTime[] = "0.0")
{
	if (g_iNotify != 1 && g_iNotify != 2) return false;
	
	decl String:szScaleEdited[16], String:szTimeEdited[16];
	new iMarkInScale = FindCharInString(szScale, '.'), iMarkInTime = FindCharInString(szTime, '.');
	FormatEx(szScaleEdited, sizeof(szScaleEdited), "%s%s%s", (iMarkInScale == 0 ? "0" : ""), szScale, (iMarkInScale == -1 ? ".0" : (iMarkInScale == (strlen(szScale) - 1) ? "0" : "")));
	FormatEx(szTimeEdited, sizeof(szTimeEdited), "%s%s%s", (iMarkInTime == 0 ? "0" : ""), szTime, (iMarkInTime == -1 ? ".0" : (iMarkInTime == (strlen(szTime) - 1) ? "0" : "")));
	
	//Bits			IsSingleTarget				SingleCameFromOrgin							ValidScale								ValidTime							ShowActivity2	
	switch ((_:(iSingleTarget != -1) << 4) | (_:(iOrigin == iSingleTarget) << 3) | (_:(StringToFloat(szScale) > 0.0) << 2) | (_:(StringToFloat(szTime) > 0.0) << 1) | _:(g_iNotify == 1))
	{
		//0-7 MultiTargets.
		case 0b00000:	PrintToChatAll("%s%N \x05resized\x01 %t%s!", CHAT_TAG, iOrigin, szMultiTarget, (bHead ? "' heads" : ""));
		case 0b00001:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %t%s!", iOrigin, szMultiTarget, (bHead ? "' heads" : ""));
		case 0b00010:	PrintToChatAll("%s%N \x05resized\x01 %t%s for \x05%s\x01 seconds!", CHAT_TAG, iOrigin, szMultiTarget, (bHead ? "' heads" : ""), szTimeEdited);
		case 0b00011:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %t%s for \x05%s\x01 seconds!", iOrigin, szMultiTarget, (bHead ? "' heads" : ""), szTimeEdited);
		case 0b00100:	PrintToChatAll("%s%N \x05resized\x01 %t%s to \x05%s\x01!", CHAT_TAG, iOrigin, szMultiTarget, (bHead ? "' heads" : ""), szScaleEdited);
		case 0b00101:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %t%s to \x05%s\x01!", iOrigin, szMultiTarget, (bHead ? "' heads" : ""), szScaleEdited);
		case 0b00110:	PrintToChatAll("%s%N \x05resized\x01 %t%s to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, iOrigin, szMultiTarget, (bHead ? "' heads" : ""), szScaleEdited, szTimeEdited);
		case 0b00111:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %t%s to \x05%s\x01 for \x05%s\x01 seconds!", iOrigin, szMultiTarget, (bHead ? "' heads" : ""), szScaleEdited, szTimeEdited);
		
		//16-23 Single Other Target.
		case 0b10000:	PrintToChatAll("%s%N \x05resized\x01 %N%s to \x05%s\x01!", CHAT_TAG, iOrigin, iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget]);
		case 0b10001:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %N%s to \x05%s\x01!", iOrigin, iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget]);
		case 0b10010:	PrintToChatAll("%s%N \x05resized\x01 %N%s to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, iOrigin, iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget], szTimeEdited);
		case 0b10011:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %N%s to \x05%s\x01 for \x05%s\x01 seconds!", iOrigin, iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget], szTimeEdited);
		case 0b10100:	PrintToChatAll("%s%N \x05resized\x01 %N%s to \x05%s\x01!", CHAT_TAG, iOrigin, iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited);
		case 0b10101:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %N%s to \x05%s\x01!", iOrigin, iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited);
		case 0b10110:	PrintToChatAll("%s%N \x05resized\x01 %N%s to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, iOrigin, iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited, szTimeEdited);
		case 0b10111:	ShowActivity2(iOrigin, CHAT_TAG, "%N \x05resized\x01 %N%s to \x05%s\x01 for \x05%s\x01 seconds!", iOrigin, iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited, szTimeEdited);
		
		//24-31 Self Target
		case 0b11000:	PrintToChatAll("%s%N%s was \x05resized\x01 to \x05%s\x01!", CHAT_TAG, iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget]);
		case 0b11001:	ShowActivity2(iOrigin, CHAT_TAG, "%N%s was \x05resized\x01 to \x05%s\x01!", iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget]);
		case 0b11010:	PrintToChatAll("%s%N%s was \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget], szTimeEdited);
		case 0b11011:	ShowActivity2(iOrigin, CHAT_TAG, "%N%s was \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", iSingleTarget, (bHead ? "'s head" : ""), g_szClientCurrentScale[iSingleTarget], szTimeEdited);
		case 0b11100:	PrintToChatAll("%s%N%s was \x05resized\x01 to \x05%s\x01!", CHAT_TAG, iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited);
		case 0b11101:	ShowActivity2(iOrigin, CHAT_TAG, "%N%s was \x05resized\x01 to \x05%s\x01!", iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited);
		case 0b11110:	PrintToChatAll("%s%N%s was \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", CHAT_TAG, iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited, szTimeEdited);
		case 0b11111:	ShowActivity2(iOrigin, CHAT_TAG, "%N%s was \x05resized\x01 to \x05%s\x01 for \x05%s\x01 seconds!", iSingleTarget, (bHead ? "'s head" : ""), szScaleEdited, szTimeEdited);
	}
	return true;
}

public Action:ResizeTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		ResizePlayer(client, (g_fClientCurrentScale[client] == g_fClientLastScale[client] ? "1.0" : "0.0"));
		g_hClientResizeTimers[client] = INVALID_HANDLE;
	}
}

public Action:ResizeHeadTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0)
	{
		ResizePlayerHead(client, (g_fClientCurrentHeadScale[client] == g_fClientLastHeadScale[client] ? "1.0" : "0.0"));
		g_hClientResizeHeadTimers[client] = INVALID_HANDLE;
	}
}

stock DestroyMenus()
{
	CloseHandleSafely(g_hResizeMenu);
	CloseHandleSafely(g_hResizeHeadMenu);
}

public ResizeMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (g_bEnabled && action == MenuAction_Select && IsClientInGame(param1))
	{
		new iNow = GetTime();
		if (IsClientOnCooldown(param1, iNow, false))
		{
			return;
		}
	
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		StopResizeTimer(param1);
		if (ResizePlayer(param1, info, g_iLogging == 1, param1, _, g_iUnstick == 1 || g_iUnstick == 3))
		{
			g_iLastResize[param1] = iNow;
			NotifyPlayers(false, param1, g_szClientCurrentScale[param1], param1);
		}
		else
		{
			ReplyToCommand(param1, "%sYou were not resized to avoid being stuck.", CHAT_TAG);
		}
	}
}

public ResizeHeadMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (g_bEnabled && action == MenuAction_Select && IsClientInGame(param1))
	{
		new iNow = GetTime();
		if (IsClientOnCooldown(param1, iNow, true))
		{
			return;
		}
	
		decl String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		StopResizeHeadTimer(param1);
		ResizePlayerHead(param1, info, g_iLogging == 1, param1);
		g_iLastHeadResize[param1] = iNow;
		NotifyPlayers(true, param1, g_szClientCurrentHeadScale[param1], param1);
	}
}

public ConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (StringToInt(newvalue) != 0);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientAuthorized(i) && !IsClientReplay(i) && !IsClientSourceTV(i))
		{
			ReadjustInitialSize(i, true);
		}
	}
}

public ConVarDamageChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iDamage = StringToInt(newvalue);
}

public ConVarNotifyChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iNotify = StringToInt(newvalue);
}

public ConVarLoggingChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iLogging = StringToInt(newvalue);
}

public ConVarStatusChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iJoinStatus = StringToInt(newvalue);
}

public ConVarVoicesChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iVoicesChanged = StringToInt(newvalue);
}

public ConVarMenuChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bMenu = (StringToInt(newvalue) != 0);
}

public ConVarBackstabChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bBackstab = (StringToInt(newvalue) != 0);
}

public ConVarUnstickChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iUnstick = StringToInt(newvalue);
}

public ConVarCooldownChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_iCooldown = StringToInt(newvalue);
}

public ConVarBoundsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	ParseConVarToLimits(g_hBounds, g_szBoundMin, sizeof(g_szBoundMin), g_fBoundMin, g_szBoundMax, sizeof(g_szBoundMax), g_fBoundMax);
}

public ConVarHeadBoundsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	ParseConVarToLimits(g_hHeadBounds, g_szBoundHeadMin, sizeof(g_szBoundHeadMin), g_fBoundHeadMin, g_szBoundHeadMax, sizeof(g_szBoundHeadMax), g_fBoundHeadMax);
}

public ConVarMenuItemsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	strcopy(g_szMenuItems, sizeof(g_szMenuItems), newvalue);
	DestroyMenus();
	BuildMenus();
}

public ConVarMenuHeadItemsChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	strcopy(g_szMenuHeadItems, sizeof(g_szMenuHeadItems), newvalue);
	DestroyMenus();
	BuildMenus();
}

public ConVarScaleChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	strcopy(g_szDefaultResize, sizeof(g_szDefaultResize), newvalue);
	TrimString(g_szDefaultResize);
	g_fDefaultResize = StringToFloat(g_szDefaultResize);
	CheckDefaultValue(g_fDefaultResize, g_szDefaultResize, sizeof(g_szDefaultResize), "sm_resize_defaultresize", DEFAULT_FALLBACK);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_fClientLastScale[i] = g_fDefaultResize;
		strcopy(g_szClientLastScale[i], sizeof(g_szClientLastScale[]), g_szDefaultResize);
	}
}

public ConVarHeadScaleChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	strcopy(g_szDefaultHeadResize, sizeof(g_szDefaultHeadResize), newvalue);
	TrimString(g_szDefaultHeadResize);
	g_fDefaultHeadResize = StringToFloat(g_szDefaultHeadResize);
	CheckDefaultValue(g_fDefaultHeadResize, g_szDefaultHeadResize, sizeof(g_szDefaultHeadResize), "sm_resize_defaultheadresize", DEFAULT_HEAD_FALLBACK);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_fClientLastHeadScale[i] = g_fDefaultHeadResize;
		strcopy(g_szClientLastHeadScale[i], sizeof(g_szClientLastHeadScale[]), g_szDefaultHeadResize);
	}
}

stock CheckDefaultValue(&Float:fDefault, String:szDefaultStr[], const iDefaultStrLen, const String:szConVarName[], const String:szFallback[])
{
	if (fDefault <= 0.0)
	{
		LogError("Invalid ConVar (%s) value. Falling back to %s.", szConVarName, szFallback);
		strcopy(szDefaultStr, iDefaultStrLen, szFallback);
		fDefault = StringToFloat(szFallback);
	}
}

public OnGameFrame()
{
	if (g_bEnabled && g_bResizeHeadAvailable)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && g_fClientCurrentHeadScale[i] != 1.0 && IsPlayerAlive(i))
			{
				SetEntPropFloat(i, Prop_Send, "m_flHeadScale", g_fClientCurrentHeadScale[i]);
			}
		}
	}
}

public Action:SoundCallback(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if (g_bEnabled && g_iVoicesChanged > 0)
	{
		if (entity > 0 && entity <= MaxClients && channel == SNDCHAN_VOICE)
		{
			new Float:fActualHeadSize = g_fClientCurrentScale[entity] * g_fClientCurrentHeadScale[entity];
			if (fActualHeadSize == 1.0)
			{
				return Plugin_Continue;
			}
			if (g_iVoicesChanged == 1 || (g_iVoicesChanged == 2 && fActualHeadSize < 1.0) || (g_iVoicesChanged == 3 && fActualHeadSize > 1.0))
			{
				//Next expression is ((175/(1+6x))+75) so results stay between 75 and 250 with 100 pitch at normal size.
				pitch = RoundToNearest((175 / (1 + (6 * fActualHeadSize))) + 75);
				flags |= SND_CHANGEPITCH;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if (g_bEnabled && g_iDamage > 0 && attacker > 0 && attacker <= MaxClients && attacker != victim)
	{
		if (g_fClientCurrentScale[attacker] == 1.0 || (g_iDamage == 2 && g_fClientCurrentScale[attacker] >= 1.0) || (g_iDamage == 3 && g_fClientCurrentScale[attacker] <= 1.0))
		{
			return Plugin_Continue;
		}
		
		//Alter backstabs to deal same damage ratio as body size.
		if (g_bIsTF2 && g_bBackstab && g_bCustomDmgAvailable && victim > 0 && victim <= MaxClients && damagecustom == TF_CUSTOM_BACKSTAB)
		{
			new iMaxHealth = (g_hGetMaxHealth != INVALID_HANDLE ? SDKCall(g_hGetMaxHealth, victim) : GetEntProp(victim, Prop_Data, "m_iMaxHealth"));
			damage = RoundToCeil(GetMax(iMaxHealth, GetEntProp(victim, Prop_Data, "m_iHealth")) * g_fClientCurrentScale[attacker]) / 3.0;
			return Plugin_Changed;
		}
		
		if (weapon == -1 && inflictor > MaxClients && IsValidEntity(inflictor))
		{
			decl String:szClassName[64];
			GetEntityClassname(inflictor, szClassName, sizeof(szClassName));
			if ((strcmp(szClassName, "obj_sentrygun") == 0) || (strcmp(szClassName, "tf_projectile_sentryrocket") == 0))
			{
				return Plugin_Continue;
			}
		}
		
		damage *= g_fClientCurrentScale[attacker];
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock GetMax(const iValA, const iValB)
{
	return (iValA < iValB ? iValB : iValA);
}

stock DisplayMenuSafely(const Handle:hMenu, const client)
{
	if (hMenu == INVALID_HANDLE)
	{
		PrintToConsole(client, "%sUnable to open menu.", CONSOLE_TAG);
	}
	else
	{
		DisplayMenu(hMenu, client, MENU_TIME_FOREVER);
	}
}

stock bool:StopResizeTimer(const client)
{
	CloseHandleSafely(g_hClientResizeTimers[client]);
	return true;
}

stock bool:StopResizeHeadTimer(const client)
{
	CloseHandleSafely(g_hClientResizeHeadTimers[client]);
	return true;
}

stock bool:IsClientAllowedPastBounds(const client, const bool:bHead = false)
{
	//So root admins, by default, won't get immediate access past restrictions.
	return (bHead ? (g_bHeadBoundsOverrideSet && CheckCommandAccess(client, "sm_resizeheadboundsoverride", ADMFLAG_ROOT, true)) : (g_bBoundsOverrideSet && CheckCommandAccess(client, "sm_resizeboundsoverride", ADMFLAG_ROOT, true)));
}

stock SetOverridePresence()
{
	new iFlags;
	g_bBoundsOverrideSet = GetCommandOverride("sm_resizeboundsoverride", Override_Command, iFlags);
	g_bHeadBoundsOverrideSet = GetCommandOverride("sm_resizeheadboundsoverride", Override_Command, iFlags);
}

stock CloseHandleSafely(&Handle:hMenu)
{
	if (hMenu != INVALID_HANDLE)
	{
		CloseHandle(hMenu);
		hMenu = INVALID_HANDLE;
	}
}

public OnClientDisconnect_Post(client)
{
	StopResizeTimer(client);
	StopResizeHeadTimer(client);
	
	g_fClientLastScale[client] = g_fDefaultResize;
	g_fClientLastHeadScale[client] = g_fDefaultHeadResize;
	g_fClientCurrentScale[client] = 1.0;
	g_fClientCurrentHeadScale[client] = 1.0;
	g_iLastResize[client] = 0;
	g_iLastHeadResize[client] = 0;
	
	strcopy(g_szClientLastScale[client], sizeof(g_szClientLastScale[]), g_szDefaultResize);
	strcopy(g_szClientLastHeadScale[client], sizeof(g_szClientLastHeadScale[]), g_szDefaultHeadResize);
	strcopy(g_szClientCurrentScale[client], sizeof(g_szClientCurrentScale[]), "1.0");
	strcopy(g_szClientCurrentHeadScale[client], sizeof(g_szClientCurrentHeadScale[]), "1.0");
}

public OnMapEnd()
{
	DestroyMenus();
}

public OnPluginEnd()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientAuthorized(i) && !IsClientReplay(i) && !IsClientSourceTV(i))
		{
			if (g_bResizeAvailable)
			{
				StopResizeTimer(i);
				ResizePlayer(i, "1.0");
			}
			if (g_bResizeHeadAvailable)
			{
				StopResizeHeadTimer(i);
				ResizePlayerHead(i, "1.0");
			}
		}
	}
}

//Written by Steve "11530" Marchant.