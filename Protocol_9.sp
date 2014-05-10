/*
	Includes
*/
#include <sourcemod>
#include <sdktools>
#include <tf2items>
//#include <entcontrol>
#include "p9/protocol_9_stocks.sp"
#include <morecolors>

#define FFADE_OUT	0x0002        // Fade out (not in)
#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo = 
{
	name = "Protocol 9",
	author = "Jayess + SleepKiller",
	description = "Executes protocol 9",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	RegAdminCmd("sm_protocol9", Command_Protocol9, ADMFLAG_ROOT, "Initiates Protocol 9!");
	RegAdminCmd("sm_p9", Command_Protocol9, ADMFLAG_ROOT, "Initiates Protocol 9!");
	//RegConsoleCmd("sm_steamid", Command_GetSteamID);
}

/*
	SteamIDs
*/
static g_iSteamID[32];
static g_iSteamIDCount;// = {89697396,
//75598657};

/*
	Global Variables
*/
new gLaser1;
new gSmoke1;
new gGlow1;
new gHalo1;
new gExplosive1;


public OnConfigsExecuted()
{
	new Handle:kv = CreateKeyValues("p8_ids");
	FileToKeyValues(kv, "addons/sourcemod/configs/p8_config.txt");
	
	if (!KvGotoFirstSubKey(kv))
	{
		return;
	}
	
	decl String:buffer[32];	
	do
	{
		KvGetSectionName(kv, buffer, sizeof(buffer));
		g_iSteamID[g_iSteamIDCount] = StringToInt(buffer);
		g_iSteamIDCount++;
		
		//if (StrEqual(buffer, steamid))
		//{
		//	KvGetString(kv, "name", name, maxlength);
		//	CloseHandle(kv);
		//	return true;
		//}
	} while (KvGotoNextKey(kv));
	
	CloseHandle(kv);

}

/*
	Setup Sounds and Models
*/
public OnMapStart() 
{
	gLaser1 = PrecacheModel("materials/sprites/laser.vmt");
	gSmoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt");
	gHalo1 = PrecacheModel("materials/sprites/halo01.vmt");
	gGlow1 = PrecacheModel("sprites/blueglow2.vmt", true);
	gExplosive1 = PrecacheModel("materials/sprites/sprite_fire01.vmt");
	PrecacheModel("models/props_wasteland/rockgranite03b.mdl");
	PrecacheSound("ambient/explosions/citadel_end_explosion2.wav");
	PrecacheSound("ambient/explosions/citadel_end_explosion1.wav");
	PrecacheSound("ambient/energy/weld1.wav");
}

public Action:Command_Protocol9(client, args) //Ion Cannon
{
// #--------------------CHECK STEAMID ACCESS---------------------#	
	new bool:bIsallowed;
	
	for(new i = 0; i < g_iSteamIDCount; i++)
	{
		if(GetSteamAccountID(client) == g_iSteamID[i])
		{
			bIsallowed = true;
			break;
		}
	}
	
	if(!bIsallowed)
	{
		CReplyToCommand(client,"Sorry, you don't have access to initiate {red}PROTOCOL 9!!!");
		return Plugin_Handled;
	}
// #--------------------CHECK IF VALID CLIENT--------------------#
	if(client <= 0)
		return Plugin_Handled;
	
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	if(!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[SM] You must be alive to use this command!");
		return Plugin_Handled;
	}
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vStart[3];
	
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
    	
	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);

		CloseHandle(trace);

		new Handle:data = CreateDataPack();
		WritePackFloat(data, vStart[0]);
		WritePackFloat(data, vStart[1]);
		WritePackFloat(data, vStart[2]);
		WritePackCell(data, 320); // Distance
		WritePackFloat(data, 0.0); // nphi
		ResetPack(data);

		IonAttack(data);
	}
	else
	{
		PrintHintText(client, "%t", "Wrong entity"); 
		CloseHandle(trace);
	}

	return (Plugin_Handled);
}

public DrawIonBeam(Float:startPosition[3])
{
	decl Float:position[3];
	position[0] = startPosition[0];
	position[1] = startPosition[1];
	position[2] = startPosition[2] + 1500.0;	

	TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 0.15, 25.0, 25.0, 0, 1.0, {0, 150, 255, 255}, 3 );
	TE_SendToAll();
	position[2] -= 1490.0;
	TE_SetupSmoke(startPosition, gSmoke1, 10.0, 2);
	TE_SendToAll();
	TE_SetupGlowSprite(startPosition, gGlow1, 1.0, 1.0, 255);
	TE_SendToAll();
}

public IonAttack(Handle:data)
{	
	new Float:startPosition[3];
	new Float:position[3];
	
	ResetPack(data);
	startPosition[0] = ReadPackFloat(data);
	startPosition[1] = ReadPackFloat(data);
	startPosition[2] = ReadPackFloat(data);
	new distance = ReadPackCell(data);
	new Float:nphi = ReadPackFloat(data);
	
	if (distance > 0)
	{
		EmitSoundToAll("ambient/energy/weld1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
		
		// Stage 1
		new Float:s=Sine(nphi/360*6.28)*distance;
		new Float:c=Cosine(nphi/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[2] = startPosition[2];
		
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);

		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 2
		s=Sine((nphi+45.0)/360*6.28)*distance;
		c=Cosine((nphi+45.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 3
		s=Sine((nphi+90.0)/360*6.28)*distance;
		c=Cosine((nphi+90.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);
		
		// Stage 4
		s=Sine((nphi+135.0)/360*6.28)*distance;
		c=Cosine((nphi+135.0)/360*6.28)*distance;
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] += s;
		position[1] += c;
		DrawIonBeam(position);
		
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[0] -= s;
		position[1] -= c;
		DrawIonBeam(position);

		if (nphi >= 360)
			nphi = 0.0;
		else
			nphi += 5.0;
	}
	distance -= 5;
	
	if (distance > -50)
	{
		new Handle:ndata;
		CreateDataTimer(0.1, DrawIon, ndata, TIMER_FLAG_NO_MAPCHANGE);	
		WritePackFloat(ndata, startPosition[0]);
		WritePackFloat(ndata, startPosition[1]);
		WritePackFloat(ndata, startPosition[2]);
		WritePackCell(ndata, distance);
		WritePackFloat(ndata, nphi);
	}
	else
	{
		position[0] = startPosition[0];
		position[1] = startPosition[1];
		position[2] += 1500.0;
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 5.0, 30.0, 30.0, 0, 1.0, {255, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 4.0, 50.0, 50.0, 0, 1.0, {200, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 3.0, 80.0, 80.0, 0, 1.0, {100, 255, 255, 255}, 3);
		TE_SendToAll();
		TE_SetupBeamPoints(startPosition, position, gLaser1, 0, 0, 0, 2.0, 100.0, 100.0, 0, 1.0, {0, 255, 255, 255}, 3);
		TE_SendToAll();
		
		TE_SetupSmoke(startPosition, gSmoke1, 350.0, 15);
		TE_SendToAll();
		TE_SetupGlowSprite(startPosition, gGlow1, 3.0, 15.0, 255);
		TE_SendToAll();

		makeexplosion(0, -1, startPosition, "", 500);

		position[2] = startPosition[2] + 50.0;
		new Float:fDirection[3] = {-90.0,0.0,0.0};
		env_shooter(fDirection, 25.0, 0.1, fDirection, 800.0, 120.0, 120.0, position, "models/props_wasteland/rockgranite03b.mdl");

		env_shake(startPosition, 120.0, 10000.0, 15.0, 250.0);

		TE_SetupExplosion(startPosition, gExplosive1, 10.0, 1, 0, 0, 5000);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 0.5, 100.0, 5.0, {150, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 5.0, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 2.5, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();
		TE_SetupBeamRingPoint(position, 0.0, 1500.0, gGlow1, gHalo1, 0, 0, 6.0, 100.0, 5.0, {255, 255, 255, 255}, 0, 0);
		TE_SendToAll();

		// Light
		new ent = CreateEntityByName("light_dynamic");

		DispatchKeyValue(ent, "_light", "255 255 255 255");
		DispatchKeyValue(ent, "brightness", "5");
		DispatchKeyValueFloat(ent, "spotlight_radius", 500.0);
		DispatchKeyValueFloat(ent, "distance", 500.0);
		DispatchKeyValue(ent, "style", "6");

		// SetEntityMoveType(ent, MOVETYPE_NOCLIP); 
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "TurnOn");
	
		TeleportEntity(ent, position, NULL_VECTOR, NULL_VECTOR);
		
		RemoveEntity(ent, 3.0);
		
		// Sound
		EmitSoundToAll("ambient/explosions/citadel_end_explosion1.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);
		EmitSoundToAll("ambient/explosions/citadel_end_explosion2.wav", 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, startPosition);	

		// Blend
		sendfademsg(0, 10, 200, FFADE_OUT, 255, 255, 255, 150);
		
		// Knockback
		new Float:vReturn[3], Float:vClientPosition[3], Float:dist;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
			{	
				GetClientEyePosition(i, vClientPosition);

				dist = GetVectorDistance(vClientPosition, position, false);
				if (dist < 1000.0)
				{
					MakeVectorFromPoints(position, vClientPosition, vReturn);
					NormalizeVector(vReturn, vReturn);
					ScaleVector(vReturn, 10000.0 - dist*10);

					TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, vReturn);
				}
			}
		}
	}
}

public Action:DrawIon(Handle:Timer, any:data)
{
	IonAttack(data);
	
	return (Plugin_Stop);
}