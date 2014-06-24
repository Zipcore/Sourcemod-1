/* 
	Some defines
*/
#define SStringsDS 1024
/*
	Variables
*/
new DSCountScout;
new DSCountSniper;
new DSCountSoldier;
new DSCountDemoMan;
new DSCountMedic;
new DSCountHeavy;
new DSCountPyro;
new DSCountSpy;
new DSCountEngineer;
/*
	Strings
*/
new String:DSScout[SStringsDS][PLATFORM_MAX_PATH];
new String:DSSniper[SStringsDS][PLATFORM_MAX_PATH];
new String:DSSoldier[SStringsDS][PLATFORM_MAX_PATH];
new String:DSDemoMan[SStringsDS][PLATFORM_MAX_PATH];
new String:DSMedic[SStringsDS][PLATFORM_MAX_PATH];
new String:DSHeavy[SStringsDS][PLATFORM_MAX_PATH];
new String:DSPyro[SStringsDS][PLATFORM_MAX_PATH];
new String:DSSpy[SStringsDS][PLATFORM_MAX_PATH];
new String:DSEngineer[SStringsDS][PLATFORM_MAX_PATH];

MDS(const String:DSF[])
{
	new Handle:DS = CreateKeyValues("Disguise_Sounds");
	FileToKeyValues(DS, DSF);

	if (KvJumpToKey(DS, "Scout"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSScout[DSCountScout], sizeof(DSScout[]), sound);

				DSCountScout++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Scout\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "Sniper"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSSniper[DSCountSniper], sizeof(DSSniper[]), sound);

				DSCountSniper++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Sniper\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "Soldier"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSSoldier[DSCountSoldier], sizeof(DSSoldier[]), sound);

				DSCountSoldier++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Soldier\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "DemoMan"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSDemoMan[DSCountDemoMan], sizeof(DSDemoMan[]), sound);

				DSCountDemoMan++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"DemoMan\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "Medic"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSMedic[DSCountMedic], sizeof(DSMedic[]), sound);

				DSCountMedic++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Medic\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "Heavy"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSHeavy[DSCountHeavy], sizeof(DSHeavy[]), sound);

				DSCountHeavy++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Heavy\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "Pyro"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSPyro[DSCountPyro], sizeof(DSPyro[]), sound);

				DSCountPyro++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Pyro\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "Spy"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSSpy[DSCountSpy], sizeof(DSSpy[]), sound);

				DSCountSpy++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Spy\" section!");

	KvRewind(DS);

	if (KvJumpToKey(DS, "Engineer"))
	{
		decl String:section[SStringsDS], String:sound[SStringsDS];

		KvGotoFirstSubKey(DS);

		do
		{
			KvGetSectionName(DS, section, sizeof(section));

			if (KvGetString(DS, "sound", sound, sizeof(sound)))
			{
				strcopy(DSEngineer[DSCountEngineer], sizeof(DSEngineer[]), sound);

				DSCountEngineer++;

				PrecacheSound(sound, true);
			}

			else LogError("Sound for \"%s\" is incorrect!", section);
		}
		while (KvGotoNextKey(DS));
	}
	else SetFailState("Fatal error: Missing \"Engineer\" section!");

	KvRewind(DS);

	CloseHandle(DS);
}