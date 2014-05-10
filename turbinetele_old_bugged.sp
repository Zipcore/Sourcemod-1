#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION	"1.4"

new Handle:kv;
new Float:telepoint[5][3];
new String:telepointName[5][40];
new bool:IsTaunting[MAXPLAYERS+1];
new TurbineTelepoint[MAXPLAYERS+1] = 0;
new ParticleIndex[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "[TF2]Turbine Teleports!",
	author = "Js41637",
	description = "Teleport!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_turbinetele_version", PLUGIN_VERSION, "Turbine Teleports Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	RegAdminCmd("sm_teleport_menu", Command_TeleportMenu, ADMFLAG_SLAY);
}

public OnConfigsExecuted() 
{
	kv = CreateKeyValues("teleports");
	decl String:file[512];
	GetCurrentMap(file, sizeof(file));
	BuildPath(Path_SM, file, sizeof(file), "configs/turbinetele.cfg", file);
	if(FileExists(file, false))
	{
		FileToKeyValues(kv, file);
		BuildTelepoints();
		BuildTelepointsNames();
	}
	else
	{
		PrintToServer("[SM] Turbine Teleports unable to find config file: \"configs/turbinetele.cfg\"", file);
		LogMessage("Turbine Teleports unable to find config file: \"configs/turbinetele.cfg\"", file);
	}
}
BuildTelepoints()
{
	if (!KvJumpToKey(kv, "Telepoints")) return;
	if (!KvGotoFirstSubKey(kv, false)) return;
	decl String:key[10];
	decl String:value[64];
	new String:floatstrings[3][8];
	new i = 0;
	do
	{
		KvGetSectionName(kv, key, sizeof(key));
		KvGetString(kv, NULL_STRING, value, sizeof(value));
		ExplodeString(value, ",", floatstrings, 3, 8, false);
		telepoint[i][0] = StringToFloat(floatstrings[0]);
		telepoint[i][1] = StringToFloat(floatstrings[1]);
		telepoint[i][2] = StringToFloat(floatstrings[2]);
		i++;
	} while (KvGotoNextKey(kv, false) && i<5);

	KvRewind(kv);
}
BuildTelepointsNames()
{
	if (!KvJumpToKey(kv, "TelepointsNames")) return;
	if (!KvGotoFirstSubKey(kv, false)) return;
	decl String:key[10];
	decl String:value[64];
	new i = 0;
	do
	{
		KvGetSectionName(kv, key, sizeof(key));
		KvGetString(kv, NULL_STRING, value, sizeof(value));
		strcopy(telepointName[StringToInt(key)], 40, value);
		i++;
	} while (KvGotoNextKey(kv, false) && i<5);

	KvRewind(kv);
}

public Action:Command_TeleportMenu(client, args) 
{
	if (IsValidClient(client) && IsTaunting[client] != true)
	{
		new Handle:mastertelemenu = CreateMenu(MasterTeleMenuCallback);
		SetMenuTitle(mastertelemenu, "Master Teleport Menu");
		AddMenuItem(mastertelemenu, "teleport", "Teleports...");
		DisplayMenu(mastertelemenu, client, MENU_TIME_FOREVER);
	}
	else
	{
		ReplyToCommand(client, "[SM]Error: Wut did you do? You broke it, try again.");
		PrintToChatAll("[SM]Error: Wut did you do? You broke it, try again.");
	}
	return Plugin_Handled;
}
public MasterTeleMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:act[20];
		GetMenuItem(menu, param2, act, sizeof(act));
		if(StrEqual(act, "teleport"))
		{
			new Handle:telemenu = CreateMenu(TeleMenuCallback);
			SetMenuTitle(telemenu, "Select Dest:");
			AddMenuItem(telemenu, "dest0", telepointName[0]);
			AddMenuItem(telemenu, "dest1", telepointName[1]);
			AddMenuItem(telemenu, "dest2", telepointName[2]);
			AddMenuItem(telemenu, "dest3", telepointName[3]);
			AddMenuItem(telemenu, "dest4", telepointName[4]);
			DisplayMenu(telemenu, client, MENU_TIME_FOREVER);
		}
		else
		{
			ReplyToCommand(client, "[SM]Error: Wut did you do? You broke it, try again.");
			CloseHandle(menu);
		}
	}
	//IsTaunting[client] = false;
	//CloseHandle(menu);
}

public TeleMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:act[20];
		GetMenuItem(menu, param2, act, sizeof(act));
		if(GetEntityFlags(client) & FL_ONGROUND)
		{	
			if(StrEqual(act, "dest0"))
			{
				TurbineTelepoint[client] = 0;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest1"))
			{
				TurbineTelepoint[client] = 1;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest2"))
			{
				TurbineTelepoint[client] = 2;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest3"))
			{
				TurbineTelepoint[client] = 3;
				TeleOut(client);
			}
			else if(StrEqual(act, "dest4"))
			{
				TurbineTelepoint[client] = 4;
				TeleOut(client);
			}
		}
	}
	CloseHandle(menu);
}
public TeleOut(client)
{
	TF2_StunPlayer(client, Float:2.0, Float:1.0, TF_STUNFLAGS_LOSERSTATE);
	MakePlayerInvisible(client, 0);
	new Model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(Model))
	{
		IsTaunting[client] = true;
		new Float:pos[3], Float:ang[3];
		decl String:ClientModel[256];
		
		GetClientModel(client, ClientModel, sizeof(ClientModel));
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(Model, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, ang);
		ang[0] = 0.0;
		ang[2] = 0.0;

		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", "teleport_out");	
		DispatchKeyValueVector(Model, "angles", ang);
		
		DispatchSpawn(Model);
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(Model, "AddOutput");
		
		SetEntityMoveType(client, MOVETYPE_NONE);
		CreateTimer(Float:1.1, TeleIn, client);
		TimedParticle(client, "merasmus_tp", Float:1.5);
	}
}	
public Action:TeleIn(Handle:timer, any:client)
{
	new Model = CreateEntityByName("prop_dynamic");
	if (IsValidEdict(Model))
	{
		IsTaunting[client] = true;
		new Float:ang[3];
		decl String:ClientModel[256];
		GetClientModel(client, ClientModel, sizeof(ClientModel));
		TeleportEntity(Model, telepoint[TurbineTelepoint[client]], NULL_VECTOR, NULL_VECTOR);
		TeleportEntity(client, telepoint[TurbineTelepoint[client]], NULL_VECTOR, NULL_VECTOR);
		GetClientEyeAngles(client, ang);
		ang[0] = 0.0;
		ang[2] = 0.0;

		DispatchKeyValue(Model, "model", ClientModel);
		DispatchKeyValue(Model, "DefaultAnim", "teleport_in");	
		DispatchKeyValueVector(Model, "angles", ang);
		
		DispatchSpawn(Model);
		
		SetVariantString("OnAnimationDone !self:KillHierarchy::0.0:1");
		AcceptEntityInput(Model, "AddOutput");
		
		SetEntityMoveType(client, MOVETYPE_NONE);
		CreateTimer(Float:1.5, ResetTaunt, client);
		TimedParticle(client, "merasmus_tp", Float:1.5);
	}
}
public Action:ResetTaunt(Handle:timer, any:client)
{
	IsTaunting[client] = false;
	MakePlayerInvisible(client, 255);
	SetEntityMoveType(client, MOVETYPE_ISOMETRIC);
}
stock MakePlayerInvisible(client, alpha)
{
	SetWeaponsAlpha(client, alpha);
	SetWearablesAlpha(client, alpha);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 255, 255, alpha);
}

stock SetWeaponsAlpha (client, alpha){
	decl String:classname[64];
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");
	for(new i = 0, weapon; i < 189; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		if(weapon > -1 && IsValidEdict(weapon))
		{
			GetEdictClassname(weapon, classname, sizeof(classname));
			if(StrContains(classname, "tf_weapon", false) != -1 || StrContains(classname, "tf_wearable", false) != -1)
			{
				SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
				SetEntityRenderColor(weapon, 255, 255, 255, alpha);
			}
		}
	}
}
stock SetWearablesAlpha (client, alpha)
{
	if(IsPlayerAlive(client))
	{
		new Float:pos[3], Float:wearablepos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		new wearable= -1;
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos);
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
		while ((wearable= FindEntityByClassname(wearable, "tf_wearable_item_demoshield")) != -1)
		{
			GetEntPropVector(wearable, Prop_Data, "m_vecAbsOrigin", wearablepos); 
			if (GetVectorDistance(pos, wearablepos, true) < 2)
			{
				SetEntityRenderMode(wearable, RENDER_TRANSCOLOR);
				SetEntityRenderColor(wearable, 255, 255, 255, alpha);
			}
		}
	}
}
public BuildParticle(client, const String:path[32])
{
	new TParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(TParticle))
	{
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		
		TeleportEntity(TParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(TParticle, "effect_name", path);
		
		DispatchKeyValue(TParticle, "targetname", "particle");
		
		SetVariantString("!activator");
		AcceptEntityInput(TParticle, "SetParent", client, TParticle, 0);
		
		SetVariantString("effect_robe");
		AcceptEntityInput(TParticle, "SetParentAttachment", TParticle, TParticle, 0);
		
		DispatchSpawn(TParticle);
		ActivateEntity(TParticle);
		AcceptEntityInput(TParticle, "Start");
		
		ParticleIndex[client] = TParticle;
	}
}
public Action:KPart(Handle:timer, any:particle)
{
	if (IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Kill");
	}
}
public RemoveParticle(client)
{
	if (IsValidEntity(ParticleIndex[client]))
	{
		AcceptEntityInput(ParticleIndex[client], "Kill");
	}	
}
stock bool:IsValidClient(client) 
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	return IsClientInGame(client);
}
public TimedParticle(client, const String:path[32], Float:FTime)
{
	new TParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(TParticle))
	{
		new Float:pos[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		
		TeleportEntity(TParticle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(TParticle, "effect_name", path);
		
		DispatchKeyValue(TParticle, "targetname", "particle");
		
		SetVariantString("!activator");
		AcceptEntityInput(TParticle, "SetParent", client, TParticle, 0);
		
		DispatchSpawn(TParticle);
		ActivateEntity(TParticle);
		AcceptEntityInput(TParticle, "Start");
		CreateTimer(FTime, KillTParticle, TParticle);
		
	}
}
public Action:KillTParticle(Handle:timer, any:index)
{
	if (IsValidEntity(index))
	{
		AcceptEntityInput(index, "Kill");
	}
}