#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2items>
#include <tf2itemsinfo>

#define PLUGIN_VERSION "2.15.0"
#define EFFECTSFILE "unusual_list.cfg"
#define PERMISSIONFILE "unusual_permissions.cfg"
#define DATAFILE "unusual_effects.txt"
#define WEBSITE "http://adf.ly/kuBHt"
#define UPDATE_URL "http://bit.ly/1hvGhxA"



new String:ClientSteamID[MAXPLAYERS+1][60];
new String:UnusualEffect[PLATFORM_MAX_PATH];
new String:EffectsList[PLATFORM_MAX_PATH];
new String:PermissionsFile[PLATFORM_MAX_PATH];

new Quality[MAXPLAYERS+1];
new ClientItems[MAXPLAYERS+1];
new ClientControl[MAXPLAYERS+1];

new bool:FirstControl[MAXPLAYERS+1] = {false, ...};

new Permission[22] = {0, ...};
new FlagsList[21] = {ADMFLAG_RESERVATION, ADMFLAG_GENERIC, ADMFLAG_KICK, ADMFLAG_BAN, ADMFLAG_UNBAN, ADMFLAG_SLAY, ADMFLAG_CHANGEMAP, ADMFLAG_CONVARS, ADMFLAG_CONFIG, ADMFLAG_CHAT, ADMFLAG_VOTE, ADMFLAG_PASSWORD, ADMFLAG_RCON, ADMFLAG_CHEATS, ADMFLAG_CUSTOM1, ADMFLAG_CUSTOM2, ADMFLAG_CUSTOM3, ADMFLAG_CUSTOM4, ADMFLAG_CUSTOM5, ADMFLAG_CUSTOM6, ADMFLAG_ROOT};

new Handle:c_Control = INVALID_HANDLE;
new Handle:c_TeamRest = INVALID_HANDLE;
new Handle:c_PanelFlag = INVALID_HANDLE;
new Handle:g_hItem = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "[TF2] Unusual Effects",
    author = "Erreur 500",
    description = "Apply Unusual effects to your weapons",
    version = PLUGIN_VERSION,
    url = "erreur500@hotmail.fr"
};

public OnPluginStart()
{ 
  CreateConVar("unusual_version", PLUGIN_VERSION, "Unusual version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
  c_Control = CreateConVar("unusual_controlmod",  "0", "0 = no control, 1 = event spawn, 2 = event inventory", FCVAR_PLUGIN, true, 0.0, true, 2.0); 
  c_TeamRest  = CreateConVar("unusual_team_restriction",  "0", "0 = no restriction, 1 = red, 2 = blue can't have unusual effects", FCVAR_PLUGIN, true, 0.0, true, 2.0);
  c_PanelFlag = CreateConVar("unusual_panel_flag",  "0", "0 = ADMFLAG_ROOT, 1 = ADMFLAG_GENERIC", FCVAR_PLUGIN, true, 0.0, true, 1.0);  

  HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
  HookEvent("post_inventory_application", EventPlayerInventory, EventHookMode_Post);
  
  RegConsoleCmd("unusual", OpenMenu, "Get unusual effect on your weapons");
  RegAdminCmd("unusual_control", ControlPlayer, ADMFLAG_GENERIC);
  RegAdminCmd("unusual_permissions", reloadPermissions, ADMFLAG_GENERIC);
  
  LoadTranslations("unusual.phrases"); 
  AutoExecConfig(true, "unsual_configs");
  BuildPath(Path_SM, EffectsList, sizeof(EffectsList), "configs/%s", EFFECTSFILE);
  BuildPath(Path_SM, UnusualEffect,sizeof(UnusualEffect),"configs/%s", DATAFILE);
  BuildPath(Path_SM, PermissionsFile,sizeof(PermissionsFile),"configs/%s", PERMISSIONFILE);

  g_hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
  TF2Items_SetNumAttributes(g_hItem, 1);
}

public OnMapStart() 
{
  if(LoadPermissions())
  {
    LogMessage("Unusual effects permissions loaded !");
  }
  else
  {
    LogMessage("Error while charging permissions !");
  }
}

public OnClientAuthorized(iClient, const String:auth[])
{
  strcopy(ClientSteamID[iClient], 60, auth);
}

//--------------------------------------------------------------------------------------
//              Control
//--------------------------------------------------------------------------------------

stock bool:IsValidClient(iClient)
{
  if (iClient <= 0) return false;
  if (iClient > MaxClients) return false;
  return IsClientInGame(iClient);
}

public Action:OpenMenu(iClient, Args)
{ 
  FirstMenu(iClient);
}

public Action:ControlPlayer(iClient, Args)
{ 
  for(new i=1; i<MaxClients; i++)
    if(IsClientInGame(i))
      Updating(i);
  
  if(IsValidClient(iClient))
    PrintToChat(iClient,"All Players have been controlled !");
  else
    LogMessage("All Players have been controlled !");
}

public Action:reloadPermissions(iClient, Args)
{
  if(LoadPermissions())
  {
    if(IsValidClient(iClient))
      PrintToChat(iClient,"Unusual effects permissions reloaded !");
    else
      LogMessage("Unusual effects permissions reloaded !");
  }
  else
  {
    if(IsValidClient(iClient))
      PrintToChat(iClient,"Error while recharging permissions !");
    else
      LogMessage("Error while recharging permissions !");
  }
}

bool:LoadPermissions()
{
  new Handle: kv;
  kv = CreateKeyValues("Unusual_permissions");
  if(!FileToKeyValues(kv, PermissionsFile))
  {
    LogError("Can't open %s file",PERMISSIONFILE);
    CloseHandle(kv);
    return false;
  }

  KvGotoFirstSubKey(kv, true);
  Permission[0]  = KvGetNum(kv, "0", 0);
  Permission[1]  = KvGetNum(kv, "a", 0);
  Permission[2]  = KvGetNum(kv, "b", 0);
  Permission[3]  = KvGetNum(kv, "c", 0);
  Permission[4]  = KvGetNum(kv, "d", 0);
  Permission[5]  = KvGetNum(kv, "e", 0);
  Permission[6]  = KvGetNum(kv, "f", 0);
  Permission[7]  = KvGetNum(kv, "g", 0);
  Permission[8]  = KvGetNum(kv, "h", 0);
  Permission[9]  = KvGetNum(kv, "i", 0);
  Permission[10] = KvGetNum(kv, "j", 0);
  Permission[11] = KvGetNum(kv, "k", 0);
  Permission[12] = KvGetNum(kv, "l", 0);
  Permission[13] = KvGetNum(kv, "m", 0);
  Permission[14] = KvGetNum(kv, "n", 0);
  Permission[15] = KvGetNum(kv, "o", 0);
  Permission[16] = KvGetNum(kv, "p", 0);
  Permission[17] = KvGetNum(kv, "q", 0);
  Permission[18] = KvGetNum(kv, "r", 0);
  Permission[19] = KvGetNum(kv, "s", 0);
  Permission[20] = KvGetNum(kv, "t", 0);
  Permission[21] = KvGetNum(kv, "z", 0);
  CloseHandle(kv);
  return true;
}

bool:isAuthorized(Handle:kv, iClient, bool:Strict)
{
  new Count;
  new Limit = GetLimit(GetUserFlagBits(iClient));
  
  KvRewind(kv);
  if(Limit == -1)
    return true;
    
  if(!KvJumpToKey(kv, ClientSteamID[iClient], false))
  {
    Count = 0;
  }
  else
  {
    if(!KvGotoFirstSubKey(kv, true))
    {
      LogError("Invalid file : %s",DATAFILE);
      return false;
    }
    Count++;
      
    while(KvGotoNextKey(kv, true))
      Count++;
  }
  
  if(Strict && Count < Limit)
    return true;
  else if(!Strict && Count <= Limit)
    return true;
  else
    return false;
}

GetLimit(flags)
{
  new Limit   = 0;
  new i     = 0;
  
  if(flags == 0)
    return Limit;
    
  do
  {
    if( (flags & FlagsList[i]) && ((Limit < Permission[i+1]) || (Permission[i+1] == -1)) )
      Limit = Permission[i+1];
    i++;
  }while(Limit != -1 && i<21)
  return Limit;
}

//--------------------------------------------------------------------------------------
//              Update Effects
//--------------------------------------------------------------------------------------


public Action:EventPlayerSpawn(Handle:hEvent, const String:strName[], bool:bHidden)
{
  new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
  if(!IsValidClient(iClient)) return Plugin_Continue;
  if(IsFakeClient(iClient)) return Plugin_Continue;
  
  if(GetConVarInt(c_Control) == 1 || !FirstControl[iClient])
  {
    Updating(iClient);
    
    if(!FirstControl[iClient])
      FirstControl[iClient] = true;
  }
  return Plugin_Continue;
}

public Action:EventPlayerInventory(Handle:hEvent, const String:strName[], bool:bHidden)
{
  new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
  if(GetConVarInt(c_Control) == 2)
  {
    if(!IsValidClient(iClient)) return Plugin_Continue;
    if(!IsPlayerAlive(iClient)) return Plugin_Continue;
    if(IsFakeClient(iClient))   return Plugin_Continue;
    
    Updating(iClient);
  }
  return Plugin_Continue;
}

Updating(iClient)
{
  new Handle: kv;
  kv = CreateKeyValues("Unusual_effects");
  if(!FileToKeyValues(kv, UnusualEffect))
  {
    LogError("Can't open %s file",DATAFILE);
    CloseHandle(kv);
    return;
  }
  
  //LogMessage("Controle en cours!");
    
  if(isAuthorized(kv, iClient, false))
  {
    CloseHandle(kv);
    return;
  }
  
  CPrintToChat(iClient, "%t","Sent6");
  DeleteDatas(kv, iClient);
  
  KvRewind(kv);
  if(!KeyValuesToFile(kv, UnusualEffect))
    LogError("Can't save %s file modifications",DATAFILE);
  CloseHandle(kv);
}

DeleteDatas(Handle:kv, iClient)
{
  new String:PlayerInfo[60];
  
  KvRewind(kv);
  GetClientAuthString(iClient, PlayerInfo, sizeof(PlayerInfo));
  
  if(!KvJumpToKey(kv, PlayerInfo))
    return;
    
  new String:section[7];
  while(KvGotoFirstSubKey(kv, true))
  {
    KvGetSectionName(kv, section, sizeof(section)); 
    KvGoBack(kv);
    KvDeleteKey(kv, section);
  }
  return;
}

public Action:TF2Items_OnGiveNamedItem(iClient, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
  if(!IsValidClient(iClient)) return Plugin_Continue;
  if(IsFakeClient(iClient)) return Plugin_Continue;
  
  new TeamRestriction = GetConVarInt(c_TeamRest); // Team restriction
  if(GetClientTeam(iClient) == TeamRestriction+1)
    return Plugin_Continue;  

  new Handle:kv;
  new String:PlayerInfo[60];  
  new String:str_iItemDefinitionIndex[10];
  new Float:fltEffect;
  new ItemQuality;
  new Effect;
  
  
  kv = CreateKeyValues("Unusual_effects");
  if(!FileToKeyValues(kv, UnusualEffect))
  {
    LogMessage("Can't open %s file",DATAFILE);
    CloseHandle(kv);
    return Plugin_Continue;
  }
  GetClientAuthString(iClient, PlayerInfo, sizeof(PlayerInfo));
  if(!KvJumpToKey(kv, PlayerInfo, false))
  {
    CloseHandle(kv);
    return Plugin_Continue;
  }
  IntToString(iItemDefinitionIndex, str_iItemDefinitionIndex, sizeof(str_iItemDefinitionIndex));
  if(!KvJumpToKey(kv, str_iItemDefinitionIndex, false))
  {
    CloseHandle(kv);
    return Plugin_Continue;
  }
  ItemQuality = KvGetNum(kv, "quality", -1);
  Effect = KvGetNum(kv, "effect", -1);
  if(Effect == -1)
  {
    LogMessage("Invalid effect for %s weapon %i",PlayerInfo, iItemDefinitionIndex);
    CloseHandle(kv);
    return Plugin_Continue;
  }
  fltEffect = Effect * 1.0;
  CloseHandle(kv);
  
  TF2Items_SetAttribute(g_hItem, 0, 134, fltEffect);
  if(ItemQuality > -1)
    TF2Items_SetQuality(g_hItem, ItemQuality);
  hItem = g_hItem;
  //LogMessage("WEAPON %i, with %i for %i",iItemDefinitionIndex,Effect,iClient);
  return Plugin_Changed;
}

UpdateWeapon(iClient)
{
  new TFClassType:Class = TF2_GetPlayerClass(iClient);
  new SlotMax;
  if(Class == TFClassType:8)
    SlotMax = 4;
  else if(Class == TFClassType:9)
    SlotMax = 5;
  else
    SlotMax = 2;
    
  for(new i = 0; i<= SlotMax; i++)
    TF2_RemoveWeaponSlot(iClient,i);

  TF2_RegeneratePlayer(iClient);
}



//--------------------------------------------------------------------------------------
//              Menu selection
//--------------------------------------------------------------------------------------
  
FirstMenu(iClient)
{ 
  if(IsValidClient(iClient))
  {
    new TeamRestriction = GetConVarInt(c_TeamRest);
    if(GetClientTeam(iClient) == TeamRestriction+1)
    {
      if(TeamRestriction == 1)
      {
        CPrintToChat(iClient, "%t", "Sent1", "Red");
        return;
      }
      else if(TeamRestriction == 2)
      {
        CPrintToChat(iClient, "%t", "Sent1", "Blue");
        return;
      }
    }
    
    ClientControl[iClient] = iClient;
    
    new Handle:Menu1 = CreateMenu(Menu1_1);
    SetMenuTitle(Menu1, "What do you want ?");
    AddMenuItem(Menu1, "0", "Add/modify weapons");
    AddMenuItem(Menu1, "1", "Delete effects");
    AddMenuItem(Menu1, "2", "Show effects");
    
    if((GetConVarInt(c_PanelFlag) == 0 && (GetUserFlagBits(iClient) & ADMFLAG_ROOT)) || (GetConVarInt(c_PanelFlag) == 1 && ((GetUserFlagBits(iClient) & ADMFLAG_GENERIC) || (GetUserFlagBits(iClient) & ADMFLAG_ROOT)) ))
      AddMenuItem(Menu1, "3", "Admin tools");
      
    SetMenuExitButton(Menu1, true);
    DisplayMenu(Menu1, iClient, MENU_TIME_FOREVER);
  }
}

public Menu1_1(Handle:menu, MenuAction:action, iClient, args)
{
  if (action == MenuAction_End)
  {
    CloseHandle(menu);
  }
  else if (action == MenuAction_Select)
  {
    if(args == 0)
      QualityMenu(iClient);
    else if(args == 1)
      DeleteWeapPanel(iClient);
    else if(args == 2)
    {
      FirstMenu(iClient);
      ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
    }
    else if(args == 3)
    {
      AdminToolMenu(iClient);
    }
  }
}

//--------------------------------------------------------------------------------------
//              Remove Effect
//--------------------------------------------------------------------------------------

DeleteWeapPanel(iClient)
{
  new Handle: kv;
  kv = CreateKeyValues("Unusual_effects");
  new String:section[7];
  new String:ItemsName[64];
  new Handle:YourItemsMenu = CreateMenu(YourItemsMenuAnswer);
    
  SetMenuTitle(YourItemsMenu, "What items ?");
  FileToKeyValues(kv, UnusualEffect);
    
  if(!KvJumpToKey(kv, ClientSteamID[ClientControl[iClient]], false))
  {
    if(iClient == ClientControl[iClient])
      CPrintToChat(iClient, "%t","Sent3");
    else
      CPrintToChat(iClient, "%t","Sent4", ClientControl[iClient]);
    CloseHandle(kv);
    return;
  }
    
  if(!KvGotoFirstSubKey(kv, true))
  {
    LogError("Invalid file : %s",DATAFILE);
    CloseHandle(kv);
    return;
  }
  KvGetSectionName(kv, section, sizeof(section));
  new SectionID = StringToInt(section); 
  TF2II_GetItemName(SectionID, ItemsName, sizeof(ItemsName));
  AddMenuItem(YourItemsMenu, section, ItemsName);
      
  while(KvGotoNextKey(kv, true))
  { 
    KvGetSectionName(kv, section, sizeof(section)); 
    SectionID = StringToInt(section); 
    TF2II_GetItemName(SectionID, ItemsName, sizeof(ItemsName));
    AddMenuItem(YourItemsMenu, section, ItemsName);
  }
  CloseHandle(kv);
  SetMenuExitButton(YourItemsMenu, true);
  DisplayMenu(YourItemsMenu, iClient, MENU_TIME_FOREVER);
}

public YourItemsMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
  if (action == MenuAction_End)
  {
    CloseHandle(menu);
  }
  else if (action == MenuAction_Select)
  {
    new String:WeapID[7];
    GetMenuItem(menu, args, WeapID, sizeof(WeapID));
    
    if(IsValidClient(ClientControl[iClient]))
      RemoveEffect(iClient, ClientSteamID[ClientControl[iClient]], WeapID);
    else if(ClientControl[iClient] != iClient)
    {
      CPrintToChat(iClient, "%t", "Sent9");
      AdminToolMenu(iClient);
    }
  } 
}

bool:RemoveEffect(User, String:PlayerSteamID[60], String:WeapID[7])
{
  new iClient = -1;
  
  for(new i=1; i<MaxClients; i++)
    if(IsValidClient(i))
      if(StrEqual(ClientSteamID[i], PlayerSteamID))
      {
        iClient = i;
        continue;
      }
    
  
  new Handle: kv;
  kv = CreateKeyValues("Unusual_effects");
    
  if(!FileToKeyValues(kv, UnusualEffect))
  {
    CloseHandle(kv);
    LogError("Plugin ERROR : Can't open %s file", DATAFILE);
    if(IsValidClient(User))
      CPrintToChat(User, "%t", "error");
    
    return false;
  }
  
  if(StrEqual(WeapID, "-1"))  // remove player from the DB
  {
    if(!KvDeleteKey(kv, PlayerSteamID))
    {
      CloseHandle(kv);
      if(IsValidClient(User))
      {
        CPrintToChat(User, "%t","Sent5");
        if(IsValidClient(iClient))
        {
          if(User == iClient)
            DeleteWeapPanel(User);
          else
            AdminToolMenu(User);
        }
      }
      else
        LogMessage("Can't find player steamID %s !", PlayerSteamID);
        
      return false;
    }
    else if(iClient != -1)
    {
      CPrintToChat(iClient, "%t","Sent10");
      if(iClient != User && IsValidClient(User))
        CPrintToChat(User, "%t","Sent11", iClient);
    }
  }
  else
  {
    KvJumpToKey(kv, PlayerSteamID, true);
    
    if(!KvDeleteKey(kv, WeapID))    // Remove weapon from the DB
    {
      CloseHandle(kv);
      if(IsValidClient(User))
      {
        CPrintToChat(User, "%t","Sent5");
        if(IsValidClient(iClient))
        {
          if(User == iClient)
            DeleteWeapPanel(User);
          else
            AdminToolMenu(User);
        }
      }
      else
        LogMessage("Can't find weapon %d for steamID %s !", WeapID, PlayerSteamID);
        
      return false;
    }
    else if(iClient != -1)
    {
      CPrintToChat(iClient, "%t","Sent12");
      if(iClient != User && IsValidClient(User))
        CPrintToChat(User, "%t","Sent12");
    }
  }
  
  KvRewind(kv);
  if(!KeyValuesToFile(kv, UnusualEffect))
  {
    CloseHandle(kv);
    LogError("Plugin ERROR : Can't save %s modifications !",DATAFILE);
    if(IsValidClient(User))
      CPrintToChat(User, "%t", "error");
    
    return false;
  }
  CloseHandle(kv);
  
  if(iClient != -1)
  {
    if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
      UpdateWeapon(iClient);
      
    if(IsValidClient(User) && IsValidClient(iClient))
      if(User == iClient)
        DeleteWeapPanel(User);
      else
        AdminToolMenu(User);
    
  }
  return true;
}

//--------------------------------------------------------------------------------------
//              Quality + Effect
//--------------------------------------------------------------------------------------

QualityMenu(iClient)
{
  new Handle: kv;
  kv = CreateKeyValues("Unusual_effects");
  if(!FileToKeyValues(kv, UnusualEffect))
  {
    LogError("Can't open %s file",DATAFILE);
    CloseHandle(kv);
    return;
  }
  if(!isAuthorized(kv, ClientControl[iClient], true))
  {
    CPrintToChat(iClient, "%t", "Sent7");
    CloseHandle(kv);
    return;
  }
  CloseHandle(kv);
  new EntitiesID = GetEntPropEnt(ClientControl[iClient], Prop_Data, "m_hActiveWeapon");
  if(EntitiesID < 0)
    return;
  ClientItems[iClient] = GetEntProp(EntitiesID, Prop_Send, "m_iItemDefinitionIndex");
  
  decl String:Title[64];
  decl String:WeapName[64];
  new Handle:Qltymenu = CreateMenu(QltymenuAnswer);
  
  TF2II_GetItemName(ClientItems[iClient], WeapName, sizeof(WeapName)); 
  Format(Title, sizeof(Title), "Select a quality: %s",WeapName);
  SetMenuTitle(Qltymenu, Title);
  
  AddMenuItem(Qltymenu, "0", "normal");
  AddMenuItem(Qltymenu, "1", "rarity1");
  AddMenuItem(Qltymenu, "2", "rarity2");
  AddMenuItem(Qltymenu, "3", "vintage");
  AddMenuItem(Qltymenu, "4", "rarity3");
  AddMenuItem(Qltymenu, "5", "rarity4");
  AddMenuItem(Qltymenu, "6", "unique");
  AddMenuItem(Qltymenu, "7", "community");
  AddMenuItem(Qltymenu, "8", "developer");
  AddMenuItem(Qltymenu, "9", "selfmade");
  AddMenuItem(Qltymenu, "10", "customized");
  AddMenuItem(Qltymenu, "11", "strange");
  AddMenuItem(Qltymenu, "12", "completed");
  AddMenuItem(Qltymenu, "13", "haunted");
  
  SetMenuExitButton(Qltymenu, true);
  DisplayMenu(Qltymenu, iClient, MENU_TIME_FOREVER);
}

public QltymenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
  if (action == MenuAction_End)
  {
    CloseHandle(menu);
  }
  else if (action == MenuAction_Select)
  {
    Quality[iClient] = args;
    PanelEffect(iClient);
  }
}

PanelEffect(iClient)
{
  new String:EffectID[8];
  new String:EffectName[128];
  new String:Line[255];
  new Len = 0, NameLen = 0, IDLen = 0;
  new i,j,data,count = 0;

  new Handle:UnusualMenu = CreateMenu(UnusualMenuAnswer);
  SetMenuTitle(UnusualMenu, "Select an unusual effect:");
  AddMenuItem(UnusualMenu, "0", "Show effects");
  
  new Handle:file = OpenFile(EffectsList, "rt");
  if (file == INVALID_HANDLE)
  {
    LogError("[UNUSUAL] Could not open file %s", EFFECTSFILE);
    CloseHandle(file);
    return;
  }
  
  while (!IsEndOfFile(file))
  {
    count++;
    ReadFileLine(file, Line, sizeof(Line));
    Len = strlen(Line);
    data = 0;
    TrimString(Line);
    if(Line[0] == '"')
    {
      for (i=0; i<Len; i++)
      {
        if (Line[i] == '"')
        {
          i++;
          data++;
          j = i;
          while(Line[j] != '"' && j < Len)
          {
            if(data == 1)
            {
              EffectName[j-i] = Line[j];
              NameLen = j-i;
            }
            else
            {
              EffectID[j-i] = Line[j];
              IDLen = j-i;
            }
            j++;
          }
          i = j;
        } 
      } 
    }
    if(data != 0 && j <= Len)
      AddMenuItem(UnusualMenu, EffectID, EffectName);
    else if(Line[0] != '*' && Line[0] != '/')
      LogError("[UNUSUAL] %s can't read line : %i ",EFFECTSFILE, count);
      
    for(i = 0; i <= NameLen; i++)
      EffectName[i] = '\0';
    for(i = 0; i <= IDLen; i++)
      EffectID[i] = '\0';
  }
  CloseHandle(file);

  SetMenuExitButton(UnusualMenu, true);
  DisplayMenu(UnusualMenu, iClient, MENU_TIME_FOREVER);
}

public UnusualMenuAnswer(Handle:menu, MenuAction:action, iClient, args)
{
  if(action == MenuAction_End)
  {
    CloseHandle(menu);
  }
  else if(action == MenuAction_Select)
  {
    if(args == 0)
    {
      PanelEffect(iClient);
      ShowMOTDPanel(iClient, "Unusual effects", WEBSITE, MOTDPANEL_TYPE_URL );
    }
    
    new String:Effect[3];
    GetMenuItem(menu, args, Effect, sizeof(Effect));
    
    if(IsValidClient(ClientControl[iClient]))
    {
      AddUnusualEffect(iClient, ClientSteamID[ClientControl[iClient]], ClientItems[iClient], Quality[iClient], StringToInt(Effect));
      
      if(IsValidClient(iClient))
      {
        if(ClientControl[iClient] == iClient)
          FirstMenu(iClient);
        else
          AdminToolMenu(iClient);
      }
    }
  } 
}

bool:AddUnusualEffect(User, String:PlayerSteamID[60], WeaponID, WeapQuality, UnusualEffectID)
{
  if(WeaponID < 0)  // Is Valid ID
    return false;
  
  for(new Class=1; Class<=9; Class++) // Check if it's an invalid weapon
    if(TF2II_IsItemUsedByClass(WeaponID, TFClassType:Class))
      if(TF2II_GetItemSlot(WeaponID, TFClassType:Class) >= TF2ItemSlot:5)
        return false;
      
  new iClient = -1;
  for(new i=1; i<MaxClients; i++)
    if(IsValidClient(i))
      if(StrEqual(ClientSteamID[i], PlayerSteamID))
      {
        iClient = i;
        continue;
      }
  
  if(iClient == -1) // Is Invalid Client ?
  {
    if(IsValidClient(User))
      CPrintToChat(User, "%t", "Sent9");
    else
      LogMessage("Invalid Player!");
    return false;
  }
  
  new String:Effect[3];
  new String:strName[5];
  new String:strQuality[3];
  new Handle: kv;
  
  kv = CreateKeyValues("Unusual_effects");
  if(!FileToKeyValues(kv, UnusualEffect))
  {
    CloseHandle(kv);
    LogError("Plugin ERROR : Can't open %s file",DATAFILE);
    if(IsValidClient(User))
      CPrintToChat(User, "%t", "error");
    
    return false;
  }
  

  if(!IsValidClient(User) && !isAuthorized(kv, iClient, true))
  {
    LogMessage("%N can't have more unusual effects!");
    CloseHandle(kv);
    return false;
  }
  
  KvRewind(kv);
  KvJumpToKey(kv, PlayerSteamID, true);
  
  
  Format(strName, sizeof(strName), "%d", WeaponID);
  Format(strQuality, sizeof(strQuality), "%d", WeapQuality);
  Format(Effect, sizeof(Effect), "%d", UnusualEffectID);
  
  KvJumpToKey(kv, strName, true);
  KvSetString(kv, "quality", strQuality); 
  KvSetString(kv, "effect", Effect);
  
  KvRewind(kv);
  if(!KeyValuesToFile(kv, UnusualEffect))
  {
    CloseHandle(kv);
    LogError("Plugin ERROR : Can't save %s modifications !", DATAFILE);
    if(IsValidClient(User))
      CPrintToChat(User, "%t", "error");
    
    return false;
  }
  
  CloseHandle(kv);
  
  if(IsValidClient(User))
    CPrintToChat(User, "%t", "Sent8");
    
  if(GetClientTeam(iClient) == 2 || GetClientTeam(iClient) == 3)
    UpdateWeapon(iClient);
  
  return true;
}


//--------------------------------------------------------------------------------------
//              Admin tool menus
//--------------------------------------------------------------------------------------


AdminToolMenu(iClient)
{
  new Handle:Menu = CreateMenu(AdminToolMenu_ans);
  new String:str_PlayerID[5];
  new String:str_PlayerName[128];
  new count = 0;
  SetMenuTitle(Menu, "Admin Tools: Player selection");
  
  for(new i=0; i<MaxClients; i++)
  {
    if(IsValidClient(i) && i != iClient && IsClientInGame(i) && !IsFakeClient(i))
    {
      Format(str_PlayerID, sizeof(str_PlayerID), "%d",i);
      GetClientName(i, str_PlayerName, sizeof(str_PlayerName));
      AddMenuItem(Menu, str_PlayerID, str_PlayerName);
      count++;
    }
  }
  
  if(count == 0)
    CPrintToChat(iClient, "%t", "Sent2");
  
  SetMenuExitButton(Menu, true);
  DisplayMenu(Menu, iClient, MENU_TIME_FOREVER);
}

public AdminToolMenu_ans(Handle:menu, MenuAction:action, iClient, args)
{
  if(action == MenuAction_End)
  {
    CloseHandle(menu);
  }
  else if(action == MenuAction_Select)
  {
    new String:str_PlayerID[5];
    GetMenuItem(menu, args, str_PlayerID, sizeof(str_PlayerID));
    ClientControl[iClient] = StringToInt(str_PlayerID);
    
    if(!IsValidClient(ClientControl[iClient]))
    {
      CPrintToChat(iClient, "%t", "Sent9");
      AdminToolMenu(iClient);
    }
    else
    {
      new String:Title[128];
      new Handle:Menu1 = CreateMenu(Menu1_1);
      
      Format(Title, sizeof(Title), "Admin Tools: %N", StringToInt(str_PlayerID));
      SetMenuTitle(Menu1, Title);
      AddMenuItem(Menu1, "0", "Add/modify weapons");
      AddMenuItem(Menu1, "1", "Delete effects");
      
      SetMenuExitButton(Menu1, true);
      DisplayMenu(Menu1, iClient, MENU_TIME_FOREVER);
    }
  }
}
