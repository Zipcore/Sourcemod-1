admCMD(i, const String:FLAG)
{
	if(StrEqual(FLAG, "b"))
	{
		RegAdminCmd(commands_disguise[i], CallDisguise, ADMFLAG_GENERIC);
	}
}