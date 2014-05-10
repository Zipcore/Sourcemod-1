/*
	Includes
*/
#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_VERSION "1.0.4"
 /*
	Plugin Info
*/
public Plugin:myinfo =
{
	name = "Protocol 8",
	author = "SleepKiller + Jayess",
	description = "Executes protocol 8",
	version = PLUGIN_VERSION,
	url = ""
};
/*
	SteamIDs
*/
static g_iSteamID[32];
static g_iSteamIDCount;// = {89697396,
//75598657};
 
public OnPluginStart()
{
	RegAdminCmd("sm_protocol8", Command_Protocol8, ADMFLAG_GENERIC, "Initiates Protocol 8!");
	RegAdminCmd("sm_p8", Command_Protocol8, ADMFLAG_GENERIC, "Initiates Protocol 9!");
	RegConsoleCmd("sm_steamid", Command_GetSteamID, "Gets a clients SteamID");
}

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
public Action:Command_GetSteamID(client, args)
{
	decl clientid;
	clientid = GetSteamAccountID(client);
	ReplyToCommand(client, "Your id is: %i", clientid)
}

public Action:Command_Protocol8(client, args) //Give OP Weapon
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
		CReplyToCommand(client,"Sorry, you don't have access to initiate {red}PROTOCOL 8!!!");
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
	
	if(args < 1)
	{
		CReplyToCommand(client, "{normal}Valid Sub-Protocols: {default}rocket, medigun, cannon, rocket-nerfed");
		return Plugin_Handled;
	}
	
	decl String:arg1[32];
	GetCmdArg(1,arg1,sizeof(arg1));
	
	if(StrEqual("rocket",arg1,false))
	{
		GiveRocket(client);
		CReplyToCommand(client,"Executing {red}Protocol 8");
		CReplyToCommand(client,"Sub-Protocol: %s", arg1);
		CReplyToCommand(client,"May god have mercy on your soul.");
	}
	else if (StrEqual("medigun",arg1,false))
	{
		GiveMedigun(client);
		CReplyToCommand(client,"Executing {red}Protocol 8");
		CReplyToCommand(client,"Sub-Protocol: %s", arg1);
		CReplyToCommand(client,"May god have mercy on your soul.");
	}		
	else if (StrEqual("cannon",arg1,false))
	{
		GiveCannon(client);
		CReplyToCommand(client,"Executing {red}Protocol 8");
		CReplyToCommand(client,"Sub-Protocol: %s", arg1);
		CReplyToCommand(client,"May god have mercy on your soul.");
	}
	else if (StrEqual("rocket-nerfed",arg1,false))
	{
		GiveNerfedRocket(client);
		CReplyToCommand(client,"Executing {red}Protocol 8");
		CReplyToCommand(client,"Sub-Protocol: %s", arg1);
		CReplyToCommand(client,"May god have mercy on your soul.");
	}
	else
	{
		ReplyToCommand(client, "Invalid Sub-Protocol specified.")
	}
	
	return Plugin_Handled;	
}
// Most of the code below comes from https://forums.alliedmods.net/showthread.php?p=1353985?p=1353985 originally, thanks to him for giving us a plugin that I could learn from!
GiveMedigun(client)
{
	//Create dat item!
	new Handle:newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	//And flags
	new Flags = 0;

	//--- Set Index - Gotta have this
	TF2Items_SetItemIndex(newItem, 29);
	//PrintToChatAll("Index %i", itemIndex);
	//---
	
	//--- Set Level
	TF2Items_SetLevel(newItem, 100);
	Flags |= OVERRIDE_ITEM_LEVEL;
	//---

	//--- Set Quality
	TF2Items_SetQuality(newItem, 2);
	Flags |= OVERRIDE_ITEM_QUALITY;
	//---
	
	//apply
	TF2Items_SetAttribute(newItem, 0, 8, 101.0);
	TF2Items_SetAttribute(newItem, 1, 11, 101.0);	


	//Set nummber of attributes
	TF2Items_SetNumAttributes(newItem, 2);
	
	Flags |= OVERRIDE_ATTRIBUTES;

	//Set flags
	TF2Items_SetFlags(newItem, Flags);

	//set classname
	TF2Items_SetClassname(newItem, "tf_weapon_medigun");

	
	TF2_RemoveWeaponSlot(client, 1);

	new entity = TF2Items_GiveNamedItem(client, newItem);
	
	if (IsValidEntity(entity))
	{
		EquipPlayerWeapon(client, entity);
	}
	
	CloseHandle(newItem);
}

GiveRocket(client)
{
	//Create dat item!
	new Handle:newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	//And flags
	new Flags = 0;

	//--- Set Index - Gotta have this
	TF2Items_SetItemIndex(newItem, 18);
	//PrintToChatAll("Index %i", itemIndex);
	//---
	
	//--- Set Level
	TF2Items_SetLevel(newItem, 100);
	Flags |= OVERRIDE_ITEM_LEVEL;
	//---

	//--- Set Quality
	TF2Items_SetQuality(newItem, 2);
	Flags |= OVERRIDE_ITEM_QUALITY;
	//---
		
//	new iAttributeCount = TF2Items_GetNumAttributes(newItem);
//	new iAttributeIndex = StringToInt("26");
//	new Float:fAttributeValue = StringToFloat(buffer1);
	//apply
	TF2Items_SetAttribute(newItem, 0, 2, 50.0); //Damage Bonus
	TF2Items_SetAttribute(newItem, 1, 4, 91.0); //Clip Size Bonus
	TF2Items_SetAttribute(newItem, 2, 6, 0.04); //Reload Speed
	TF2Items_SetAttribute(newItem, 3, 110, 500.0); //Heal on Hit
	TF2Items_SetAttribute(newItem, 4, 26, 10000.0); //Extra Health
	TF2Items_SetAttribute(newItem, 5, 107, 5.0); //Extra Speed
	TF2Items_SetAttribute(newItem, 6, 97, 0.4); //Decrease Reload Time
	TF2Items_SetAttribute(newItem, 7, 134, 4.0); //Attach Particle Effect (community sparkle)
	TF2Items_SetAttribute(newItem, 8, 99, 1000.0);	//Blast Radius
	TF2Items_SetAttribute(newItem, 9, 31, 10.0);	//Crits On Kill
//	TF2Items_SetAttribute(newItem, 10, 2, 0.0001); //Nerf Damage

	//sm_gi @me 18 1 50 8 0 0 tf_weapon_rocketlauncher  "99 ; 1000";sm_gi Sleep 29 2 99 8 0 0 tf_weapon_medigun "8 ; 101.0" "11 ; 101.0"

	//Set nummber of attributes

	TF2Items_SetNumAttributes(newItem, 10);
	//PrintToChatAll("NumAttribs = %i", NumAttribs);
	Flags |= OVERRIDE_ATTRIBUTES;

	//Set flags
	TF2Items_SetFlags(newItem, Flags);

	//set classname
	TF2Items_SetClassname(newItem, "tf_weapon_rocketlauncher");

	
	TF2_RemoveWeaponSlot(client, 0);

	new entity = TF2Items_GiveNamedItem(client, newItem);
	
	if (IsValidEntity(entity))
	{
		EquipPlayerWeapon(client, entity);
	}
	
	CloseHandle(newItem);
	SetEntityHealth(client,GetClientHealth(client)+10000);
}

GiveNerfedRocket(client)
{
	//Create dat item!
	new Handle:newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	//And flags
	new Flags = 0;

	//--- Set Index - Gotta have this
	TF2Items_SetItemIndex(newItem, 18);
	//PrintToChatAll("Index %i", itemIndex);
	//---
	
	//--- Set Level
	TF2Items_SetLevel(newItem, 100);
	Flags |= OVERRIDE_ITEM_LEVEL;
	//---

	//--- Set Quality
	TF2Items_SetQuality(newItem, 2);
	Flags |= OVERRIDE_ITEM_QUALITY;
	//---
		
//	new iAttributeCount = TF2Items_GetNumAttributes(newItem);
//	new iAttributeIndex = StringToInt("26");
//	new Float:fAttributeValue = StringToFloat(buffer1);
	//apply
	TF2Items_SetAttribute(newItem, 0, 4, 91.0); //Clip Size Bonus
	TF2Items_SetAttribute(newItem, 1, 6, 0.04); //Fire Speed
	TF2Items_SetAttribute(newItem, 2, 110, 500.0); //Heal on Hit
	TF2Items_SetAttribute(newItem, 3, 26, 10000.0); //Extra Health
	TF2Items_SetAttribute(newItem, 4, 107, 5.0); //Extra Speed
	TF2Items_SetAttribute(newItem, 5, 97, 0.4); //Decrease Reload Time
	TF2Items_SetAttribute(newItem, 6, 134, 4.0); //Attach Particle Effect (community sparkle)
	TF2Items_SetAttribute(newItem, 7, 2, 0.01); //Nerf Damage
	TF2Items_SetAttribute(newItem, 8, 99, 500.0);	//Blast Radius
	TF2Items_SetAttribute(newItem, 9, 97, 0.25); //Reload Time
//	TF2Items_SetAttribute(newItem, 10, 31, 10.0);	//Crits On Kill

	//sm_gi @me 18 1 50 8 0 0 tf_weapon_rocketlauncher  "99 ; 1000";sm_gi Sleep 29 2 99 8 0 0 tf_weapon_medigun "8 ; 101.0" "11 ; 101.0"

	//Set nummber of attributes

	TF2Items_SetNumAttributes(newItem, 10);
	//PrintToChatAll("NumAttribs = %i", NumAttribs);
	Flags |= OVERRIDE_ATTRIBUTES;

	//Set flags
	TF2Items_SetFlags(newItem, Flags);

	//set classname
	TF2Items_SetClassname(newItem, "tf_weapon_rocketlauncher");

	
	TF2_RemoveWeaponSlot(client, 0);

	new entity = TF2Items_GiveNamedItem(client, newItem);
	
	if (IsValidEntity(entity))
	{
		EquipPlayerWeapon(client, entity);
	}
	
	CloseHandle(newItem);
	SetEntityHealth(client,GetClientHealth(client)+10000);
}

GiveCannon(client)
{
	//Create dat item!
	new Handle:newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	//And flags
	new Flags = 0;

	//--- Set Index - Gotta have this
	TF2Items_SetItemIndex(newItem, 996);
	//PrintToChatAll("Index %i", itemIndex);
	//---
	
	//--- Set Level
	TF2Items_SetLevel(newItem, 100);
	Flags |= OVERRIDE_ITEM_LEVEL;
	//---

	//--- Set Quality
	TF2Items_SetQuality(newItem, 2);
	Flags |= OVERRIDE_ITEM_QUALITY;
	//---
	
	//apply
	TF2Items_SetAttribute(newItem, 0, 99, 20.0); //Blast Radius
	TF2Items_SetAttribute(newItem, 1, 58, 30.0); //Push Force on Self
	TF2Items_SetAttribute(newItem, 2, 6, 0.1);	//Fire Speed
	TF2Items_SetAttribute(newItem, 3, 4, 91.0); //Clip Size Bonus
	TF2Items_SetAttribute(newItem, 4, 26, 10000.0); //Extra Health
	TF2Items_SetAttribute(newItem, 5, 97, 0.1); //Reload Time
	
	//Set nummber of attributes
	TF2Items_SetNumAttributes(newItem, 6);
	
	Flags |= OVERRIDE_ATTRIBUTES;

	//Set flags
	TF2Items_SetFlags(newItem, Flags);

	//set classname
	TF2Items_SetClassname(newItem, "tf_weapon_cannon");

	
	TF2_RemoveWeaponSlot(client, 0);

	new entity = TF2Items_GiveNamedItem(client, newItem);
	
	if (IsValidEntity(entity))
	{
		EquipPlayerWeapon(client, entity);
	}
	
	CloseHandle(newItem);
	SetEntityHealth(client,GetClientHealth(client)+10000);	
}