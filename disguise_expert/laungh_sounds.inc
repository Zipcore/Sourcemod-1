/* 
	Some defines
*/
#define SStringsLS 1024
/*
	Variables
*/
new LSCountScout;
new LSCountSniper;
new LSCountSoldier;
new LSCountDemoMan;
new LSCountMedic;
new LSCountHeavy;
new LSCountPyro;
new LSCountSpy;
new LSCountEngineer;
/*
	Strings
*/
new String:LSScout[SStringsLS][PLATFORM_MAX_PATH];
new String:LSSniper[SStringsLS][PLATFORM_MAX_PATH];
new String:LSSoldier[SStringsLS][PLATFORM_MAX_PATH];
new String:LSDemoMan[SStringsLS][PLATFORM_MAX_PATH];
new String:LSMedic[SStringsLS][PLATFORM_MAX_PATH];
new String:LSHeavy[SStringsLS][PLATFORM_MAX_PATH];
new String:LSPyro[SStringsLS][PLATFORM_MAX_PATH];
new String:LSSpy[SStringsLS][PLATFORM_MAX_PATH];
new String:LSEngineer[SStringsLS][PLATFORM_MAX_PATH];

MLS(const String:LSF[])
{
	new Handle:LS = CreateKeyValues("Laungh_Sounds");
	FileToKeyValues(LS, LSF);

	if (KvJumpToKey(LS, "Scout"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSScout[LSCountScout], sizeof(LSScout[]), sound);

				LSCountScout++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Scout\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "Sniper"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSSniper[LSCountSniper], sizeof(LSSniper[]), sound);

				LSCountSniper++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Sniper\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "Soldier"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSSoldier[LSCountSoldier], sizeof(LSSoldier[]), sound);

				LSCountSoldier++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Soldier\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "DemoMan"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSDemoMan[LSCountDemoMan], sizeof(LSDemoMan[]), sound);

				LSCountDemoMan++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"DemoMan\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "Medic"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSMedic[LSCountMedic], sizeof(LSMedic[]), sound);

				LSCountMedic++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Medic\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "Heavy"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSHeavy[LSCountHeavy], sizeof(LSHeavy[]), sound);

				LSCountHeavy++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Heavy\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "Pyro"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSPyro[LSCountPyro], sizeof(LSPyro[]), sound);

				LSCountPyro++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Pyro\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "Spy"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSSpy[LSCountSpy], sizeof(LSSpy[]), sound);

				LSCountSpy++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Spy\" section!");

	KvRewind(LS);

	if (KvJumpToKey(LS, "Engineer"))
	{
		decl String:section[SStringsLS], String:sound[SStringsLS];

		KvGotoFirstSubKey(LS);

		do
		{
			KvGetSectionName(LS, section, sizeof(section));

			if (KvGetString(LS, "sound", sound, sizeof(sound)))
			{
				strcopy(LSEngineer[LSCountEngineer], sizeof(LSEngineer[]), sound);

				LSCountEngineer++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(LS));
	}
	else SetFailState("Fatal error: Missing \"Engineer\" section!");

	KvRewind(LS);

	CloseHandle(LS);
}