/* 
	Some defines
*/
#define SStringsUDS 1024
/*
	Variables
*/
new UDSCountScout;
new UDSCountSniper;
new UDSCountSoldier;
new UDSCountDemoMan;
new UDSCountMedic;
new UDSCountHeavy;
new UDSCountPyro;
new UDSCountSpy;
new UDSCountEngineer;
/*
	Strings
*/
new String:UDSScout[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSSniper[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSSoldier[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSDemoMan[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSMedic[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSHeavy[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSPyro[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSSpy[SStringsUDS][PLATFORM_MAX_PATH];
new String:UDSEngineer[SStringsUDS][PLATFORM_MAX_PATH];

MUNDS(const String:UDSF[])
{
	new Handle:UDS = CreateKeyValues("Undisguise_Sounds");
	FileToKeyValues(UDS, UDSF);

	if (KvJumpToKey(UDS, "Scout"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSScout[UDSCountScout], sizeof(UDSScout[]), sound);

				UDSCountScout++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Scout\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "Sniper"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSSniper[UDSCountSniper], sizeof(UDSSniper[]), sound);

				UDSCountSniper++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Sniper\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "Soldier"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSSoldier[UDSCountSoldier], sizeof(UDSSoldier[]), sound);

				UDSCountSoldier++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Soldier\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "DemoMan"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSDemoMan[UDSCountDemoMan], sizeof(UDSDemoMan[]), sound);

				UDSCountDemoMan++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"DemoMan\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "Medic"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSMedic[UDSCountMedic], sizeof(UDSMedic[]), sound);

				UDSCountMedic++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Medic\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "Heavy"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSHeavy[UDSCountHeavy], sizeof(UDSHeavy[]), sound);

				UDSCountHeavy++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Heavy\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "Pyro"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSPyro[UDSCountPyro], sizeof(UDSPyro[]), sound);

				UDSCountPyro++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Pyro\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "Spy"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSSpy[UDSCountSpy], sizeof(UDSSpy[]), sound);

				UDSCountSpy++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Spy\" section!");

	KvRewind(UDS);

	if (KvJumpToKey(UDS, "Engineer"))
	{
		decl String:section[SStringsUDS], String:sound[SStringsUDS];

		KvGotoFirstSubKey(UDS);

		do
		{
			KvGetSectionName(UDS, section, sizeof(section));

			if (KvGetString(UDS, "sound", sound, sizeof(sound)))
			{
				strcopy(UDSEngineer[UDSCountEngineer], sizeof(UDSEngineer[]), sound);

				UDSCountEngineer++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(UDS));
	}
	else SetFailState("Fatal error: Missing \"Engineer\" section!");

	KvRewind(UDS);

	CloseHandle(UDS);
}