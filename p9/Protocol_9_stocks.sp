//native bool:AcceptEntityInput(dest, const String:input[], activator=-1, caller=-1, outputid=0);

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
}

stock bool:makeexplosion(attacker = 0, inflictor = -1, const Float:attackposition[3], const String:weaponname[] = "", magnitude = 100, radiusoverride = 0, Float:damageforce = 0.0, flags = 0){
	
	new explosion = CreateEntityByName("env_explosion");
	
	if(explosion != -1)
	{
		DispatchKeyValueVector(explosion, "Origin", attackposition);
		
		decl String:intbuffer[64];
		IntToString(magnitude, intbuffer, 64);
		DispatchKeyValue(explosion,"iMagnitude", intbuffer);
		if(radiusoverride > 0)
		{
			IntToString(radiusoverride, intbuffer, 64);
			DispatchKeyValue(explosion,"iRadiusOverride", intbuffer);
		}
		
		if(damageforce > 0.0)
			DispatchKeyValueFloat(explosion,"DamageForce", damageforce);

		if(flags != 0)
		{
			IntToString(flags, intbuffer, 64);
			DispatchKeyValue(explosion,"spawnflags", intbuffer);
		}

		if(!StrEqual(weaponname, "", false))
			DispatchKeyValue(explosion,"classname", weaponname);

		DispatchSpawn(explosion);
		if(IsClientConnectedIngame(attacker))
			SetEntPropEnt(explosion, Prop_Send, "m_hOwnerEntity", attacker);

		if(inflictor != -1)
			SetEntPropEnt(explosion, Prop_Data, "m_hInflictor", inflictor);
			
		AcceptEntityInput(explosion, "Explode");
		AcceptEntityInput(explosion, "Kill");
		
		return (true);
	}
	else
		return (false);
}

stock RemoveEntity(entity, Float:time = 0.0)
{
	if (time == 0.0)
	{
		if (IsValidEntity(entity))
		{
			new String:edictname[32];
			GetEdictClassname(entity, edictname, 32);

			if (!StrEqual(edictname, "player"))
				AcceptEntityInput(entity, "kill");
		}
	}
	else
	{
		CreateTimer(time, RemoveEntityTimer, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:RemoveEntityTimer(Handle:Timer, any:entityRef)
{
	new entity = EntRefToEntIndex(entityRef);
	if (entity != INVALID_ENT_REFERENCE)
		RemoveEntity(entity); // RemoveEntity(...) is capable of handling references
	
	return (Plugin_Stop);
}

stock sendfademsg(client, duration, holdtime, fadeflag, r, g, b, a)
{
	new Handle:fademsg;
	
	if (client == 0)
		fademsg = StartMessageAll("Fade");
	else
		fademsg = StartMessageOne("Fade", client);
	
	BfWriteShort(fademsg, duration);
	BfWriteShort(fademsg, holdtime);
	BfWriteShort(fademsg, fadeflag);
	BfWriteByte(fademsg, r);
	BfWriteByte(fademsg, g);
	BfWriteByte(fademsg, b);
	BfWriteByte(fademsg, a);
	EndMessage();
}

stock bool:IsClientConnectedIngame(client)
{
	if(client > 0 && client <= MaxClients)
		if(IsClientInGame(client))
			return (true);

	return (false);
}

stock env_shooter(Float:Angles[3], Float:iGibs, Float:Delay, Float:GibAngles[3], Float:Velocity, Float:Variance, Float:Giblife, Float:Location[3], String:ModelType[])
{
	//decl Ent;

	//Initialize:
	new Ent = CreateEntityByName("env_shooter");
		
	//Spawn:

	if (Ent == -1)
		return;

  	//if (Ent>0 && IsValidEdict(Ent))

	if(Ent>0 && IsValidEntity(Ent) && IsValidEdict(Ent))
  	{

		//Properties:
		//DispatchKeyValue(Ent, "targetname", "flare");

		// Gib Direction (Pitch Yaw Roll) - The direction the gibs will fly. 
		DispatchKeyValueVector(Ent, "angles", Angles);
	
		// Number of Gibs - Total number of gibs to shoot each time it's activated
		DispatchKeyValueFloat(Ent, "m_iGibs", iGibs);

		// Delay between shots - Delay (in seconds) between shooting each gib. If 0, all gibs shoot at once.
		DispatchKeyValueFloat(Ent, "delay", Delay);

		// <angles> Gib Angles (Pitch Yaw Roll) - The orientation of the spawned gibs. 
		DispatchKeyValueVector(Ent, "gibangles", GibAngles);

		// Gib Velocity - Speed of the fired gibs. 
		DispatchKeyValueFloat(Ent, "m_flVelocity", Velocity);

		// Course Variance - How much variance in the direction gibs are fired. 
		DispatchKeyValueFloat(Ent, "m_flVariance", Variance);

		// Gib Life - Time in seconds for gibs to live +/- 5%. 
		DispatchKeyValueFloat(Ent, "m_flGibLife", Giblife);
		
		// <choices> Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
		DispatchKeyValue(Ent, "rendermode", "5");

		// Model - Thing to shoot out. Can be a .mdl (model) or a .vmt (material/sprite). 
		DispatchKeyValue(Ent, "shootmodel", ModelType);

		// <choices> Material Sound
		DispatchKeyValue(Ent, "shootsounds", "-1"); // No sound

		// <choices> Simulate, no idea what it realy does tbh...
		// could find out but to lazy and not worth it...
		//DispatchKeyValue(Ent, "simulation", "1");

		SetVariantString("spawnflags 4");
		AcceptEntityInput(Ent,"AddOutput");

		ActivateEntity(Ent);

		//Input:
		// Shoot!
		AcceptEntityInput(Ent, "Shoot", 0);
			
		//Send:
		TeleportEntity(Ent, Location, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		//AcceptEntityInput(Ent, "kill");
		RemoveEntity(Ent, 1.0);
	}
}

stock env_shake(Float:Origin[3], Float:Amplitude, Float:Radius, Float:Duration, Float:Frequency)
{
	decl Ent;

	//Initialize:
	Ent = CreateEntityByName("env_shake");
		
	//Spawn:
	if(DispatchSpawn(Ent))
	{
		//Properties:
		DispatchKeyValueFloat(Ent, "amplitude", Amplitude);
		DispatchKeyValueFloat(Ent, "radius", Radius);
		DispatchKeyValueFloat(Ent, "duration", Duration);
		DispatchKeyValueFloat(Ent, "frequency", Frequency);

		SetVariantString("spawnflags 8");
		AcceptEntityInput(Ent,"AddOutput");

		//Input:
		AcceptEntityInput(Ent, "StartShake", 0);
		
		//Send:
		TeleportEntity(Ent, Origin, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		RemoveEntity(Ent, 30.0);
	}
}