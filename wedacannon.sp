#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <smlib>

#define CMDTAG "{green}[Wedacock]{default}"

int g_iLaserSprite;
int g_iHaloSprite;
int g_iExplosionModel;
int g_iSmokeSprite1;
int g_iSmokeSprite2;

int g_iWedaAmmo[MAXPLAYERS + 1] = 0;

float g_fBoomLoc[3];

public Plugin myinfo = 
{
	name = "Wedacock", 
	author = "The Doggy", 
	description = "boom", 
	version = "0.1",
	url = "doggaming.ga"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_giveweda", Command_GiveWeda, ADMFLAG_ROOT, "GIVE WEDA YAAAAAAAAAAAA :)");
}

public void OnMapStart()
{
	PrecacheMaterial("materials/sprites/xfireball3.vtf");
	PrecacheModel("materials/sprites/flare1.vmt",true);
	g_iLaserSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_iExplosionModel = PrecacheModel("materials/sprites/sprite_fire01.vmt");
	g_iSmokeSprite1 = PrecacheModel("materials/effects/fire_cloud1.vmt",true);
	g_iSmokeSprite2 = PrecacheModel("materials/effects/fire_cloud2.vmt",true);
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Player is firing and got an ion cock
	if(buttons & IN_ATTACK2 && g_iWedaAmmo[client] > 0)
	{
		// Player is holding the correct weapon?
		char sWeapon[64];
		int iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(iWeapon != -1
		&& IsValidEntity(iWeapon)
		&& IsValidEdict(iWeapon)
		&& GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon))
		&& StrEqual(sWeapon, "weapon_rpg")) 
		{
			g_iWedaAmmo[client]--;
			float eyeLoc[3], ang[3];
			GetClientEyePosition(client, eyeLoc);
			GetClientEyeAngles(client, ang);
			TR_TraceRayFilter(eyeLoc, ang, MASK_SOLID, RayType_Infinite, TRFilter_AimTarget, client);
			TR_GetEndPosition(g_fBoomLoc);
			CPrintToChat(client, "%s oh.", CMDTAG);
			FIREWEDA(client);
		}
	}	
	return Plugin_Continue;
}

public bool TRFilter_AimTarget(int entity, int mask, int Client)
{
	if (entity == Client)
		return false;
	return true;
}

public Action Command_GiveWeda(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "%s Invalid Syntax. Usage: sm_giveweda <#userid|steamid|name>", CMDTAG);
		return Plugin_Handled;
	}
	
	char sTarget[50];
	GetCmdArg(1, sTarget, sizeof(sTarget));
	
	int iTarget = FindTarget(client, sTarget, false, false);
	if(iTarget == -1)
		return Plugin_Handled;
	
	g_iWedaAmmo[iTarget]++;
	
	CPrintToChat(client, "%s You gave %N a weda cock.", CMDTAG, iTarget);
	CPrintToChat(iTarget, "%s %N gave you a weda cock. Place it with your massive cock.", CMDTAG, client);
	
	return Plugin_Handled;
}

public void FIREWEDA(int client)
{	
	float g_fSkyOrigin[MAXPLAYERS + 1][3];
	g_fSkyOrigin[client] = GetDistanceToSky(client);
	// Play effects
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fBoomLoc, g_iLaserSprite, g_iHaloSprite, 0, 10, 15.0, 100.0, 100.0, 10, 4.0, {255, 255, 255, 255}, 0);
	
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fBoomLoc, g_iLaserSprite, g_iHaloSprite, 0, 10, 15.0, 100.0, 100.0, 10, 4.0, {255, 255, 255, 255}, 0);
	TE_SendToAll();
	
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fBoomLoc, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 60.0, 60.0, 10, 5.0, {0, 100, 250, 100}, 20);
	
	TE_SetupBeamPoints(g_fSkyOrigin[client], g_fBoomLoc, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 60.0, 60.0, 10, 5.0, {0, 100, 250, 100}, 20);
	TE_SendToAll();
	
	new Float:fBeamHigh[3];
	fBeamHigh[0] = g_fBoomLoc[0];
	fBeamHigh[1] = g_fBoomLoc[1];
	fBeamHigh[2] = g_fBoomLoc[2]+20.0;
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, 99.0 - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 0, 0);
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, 99.0 - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 10, 0);
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, 99.0 - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 20, 0);
	
	TE_SetupBeamRingPoint(fBeamHigh, 0.0, 99.0 - 1000.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 20.0, 100.0, 2.0, {0, 100, 250, 100}, 30, 0);
	TE_SendToAll();
	
	for(new i=0;i<=300;i+=30)
	{
		TE_SetupBeamRingPoint(fBeamHigh, 0.0, 99.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 100.0, 5.0, {255, 255, 255, 200}, 300-i, 0);
		TE_SendToAll();
	}
	
	fBeamHigh[2] += 80.0;
	
	for(new i=0;i<=300;i+=30)
	{
		TE_SetupBeamRingPoint(fBeamHigh, 0.0, 99.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 100.0, 5.0, {255, 255, 255, 200}, 300-i, 0);
		TE_SendToAll();
	}
	
	fBeamHigh[2] += 80.0;
	
	for(new i=0;i<=300;i+=30)
	{
		TE_SetupBeamRingPoint(fBeamHigh, 0.0, 99.0, g_iLaserSprite, g_iHaloSprite, 0, 30, 10.0, 100.0, 5.0, {200, 255, 255, 200}, 300-i, 0);
		TE_SendToAll();
	}
	
	fBeamHigh[2] -= 160.0;
	
	new Float:fMagnitude = Math_GetRandomFloat(99.0, 999.0);
	
	// Create explosion
	new iExplosion = CreateEntityByName("env_explosion");
	if(iExplosion != -1)
	{
		TeleportEntity(iExplosion, g_fBoomLoc, NULL_VECTOR, NULL_VECTOR);
		//DispatchKeyValue(iExplosion, "fireballsprite", "materials/sprites/xfireball3.vtf");
		SetEntProp(iExplosion, Prop_Data, "m_sFireballSprite", g_iExplosionModel);
		// The amount of damage done by the explosion. 
		SetEntProp(iExplosion, Prop_Data, "m_iMagnitude", RoundToNearest(fMagnitude));
		// If specified, the radius in which the explosion damages entities. If unspecified, the radius will be based on the magnitude. 
		SetEntProp(iExplosion, Prop_Data, "m_iRadiusOverride", RoundToNearest(99.0));
		// Who get's the frag if someone gets killed by the explosion
		SetEntPropEnt(iExplosion, Prop_Data, "m_hOwnerEntity", client);
		// Damagetype
		SetEntProp(iExplosion, Prop_Data, "m_iCustomDamageType", DMG_BLAST);
		SetEntProp(iExplosion, Prop_Data, "m_nRenderMode", 5); // Additive
		DispatchSpawn(iExplosion);
		ActivateEntity(iExplosion);
		AcceptEntityInput(iExplosion, "Explode", client, client);
	}
	
	// Show smoke
	TE_SetupSmoke(fBeamHigh, g_iSmokeSprite1, 350.0, 15);
	TE_SetupSmoke(fBeamHigh, g_iSmokeSprite2, 350.0, 15);
	TE_SetupDust(fBeamHigh, Float:{0.0,0.0,0.0}, 150.0, 15.0);
	TE_SendToAll();
	
	TE_SetupExplosion(g_fBoomLoc, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
	
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
	
	fBeamHigh[2] += 500.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
	
	fBeamHigh[2] -= 100.0;
	fBeamHigh[1] += 600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
	
	fBeamHigh[0] -= 1600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
	
	fBeamHigh[1] += 600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
	
	fBeamHigh[1] -= 600.0;
	fBeamHigh[0] += 600.0;
	TE_SetupExplosion(fBeamHigh, g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
	TE_SendToAll();
	
	for(new Float:i = 0.1;i<=12.0;i+=0.1)
		CreateTimer(i, Timer_ShowExplosions, client, TIMER_FLAG_NO_MAPCHANGE);
	
	
	new Float:fDirection[3] = {-90.0,0.0,0.0};
	new Float:fAmount = 10.0;
	env_shooter(client, fDirection, fAmount, 0.1, fDirection, 1200.0, 5.0, 20.5, g_fBoomLoc, "materials/sprites/flare1.vmt");
	
	env_shooter(client, fDirection, fAmount, 0.1, fDirection, 500.0, 5.0, 15.5, g_fBoomLoc, "materials/sprites/flare1.vmt");
	
	new iFire = CreateEntityByName("env_fire");
	if(iFire != -1)
	{
		TeleportEntity(iFire, g_fBoomLoc, NULL_VECTOR, NULL_VECTOR);
		// Amount of time the fire will burn (in seconds). 
		DispatchKeyValue(iFire, "health", "30");
		// Height (in world units) of the flame. The flame will get proportionally wider as it gets higher. 
		DispatchKeyValue(iFire, "firesize", "1000");
		// Amount of time the fire takes to grow to full strength. Set higher to make the flame build slowly. 
		DispatchKeyValue(iFire, "fireattack", "1");
		// Either Normal or Plasma. Natural is a general all purpose flame, like a wood fire. 
		DispatchKeyValue(iFire, "firetype", "Plasma");
		// Multiplier of the burn damage done by the flame. Flames damage all the time, but can be made to hurt more. This number multiplies damage by 1(so 50 = 50 damage). It hurts every second. 
		DispatchKeyValue(iFire, "damagescale", "100");
		// delete when out
		SetVariantString("spawnflags 128");
		AcceptEntityInput(iFire,"AddOutput");
		
		DispatchSpawn(iFire);
		
		ActivateEntity(iFire);
		AcceptEntityInput(iFire, "StartFire", client);
	}
}

public Action:Timer_ShowExplosions(Handle:timer, any:client)
{
	new Float:fMinDamage = 99.0;
	new Float:fMaxDamage = 99.0;
	
	// The actual magnitude is unimportant, since this is only an effect
	new Float:fMagnitude = Math_GetRandomFloat(fMinDamage, fMaxDamage);
	float g_fBeamOrigin[MAXPLAYERS + 1][8][3];
	for(new x=0;x<=30;x++)
	{
		float g_fBeamDistance[MAXPLAYERS + 1];
		g_fBeamDistance[client] = 350.0;
		g_fBeamDistance[client] += 1.467;
		if(g_fBeamDistance[client] > 350.0)
			g_fBeamDistance[client] = 0.0;
		for(new i=0;i<8;i++)
		{
			// Calculate the alpha
			float g_fBeamDegrees[MAXPLAYERS + 1][8];
			g_fBeamDegrees[client][i] = 45.0 * i;
			g_fBeamDegrees[client][i] += 30.0;
			if(g_fBeamDegrees[client][i] > 360.0)
				g_fBeamDegrees[client][i] -= 360.0;
			
			// Calculate the next origin
			g_fBeamOrigin[client][i][0] = g_fBoomLoc[0] + Sine(g_fBeamDegrees[client][i]) * g_fBeamDistance[client];
			g_fBeamOrigin[client][i][1] = g_fBoomLoc[1] + Cosine(g_fBeamDegrees[client][i]) * g_fBeamDistance[client];
			g_fBeamOrigin[client][i][2] = g_fBoomLoc[2] + 0.0;
			
			TE_SetupExplosion(g_fBeamOrigin[client][i], g_iExplosionModel, 50.0, 30, TE_EXPLFLAG_ROTATE|TE_EXPLFLAG_DRAWALPHA, RoundToNearest(99.0), RoundToNearest(fMagnitude));
			TE_SendToAll();
		}
	}
	return Plugin_Stop;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:data)
{
	if(IsValidEntity(data))
		AcceptEntityInput(data, "Kill");
}

public Action:Timer_StopSound(Handle:timer, any:data)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			StopSound(i, SNDCHAN_AUTO, "ambient/wind/windgust_strong.wav");
			StopSound(i, SNDCHAN_AUTO, "ambient/wind/wasteland_wind.wav");
			StopSound(i, SNDCHAN_AUTO, "ambient/levels/citadel/drone1lp.wav");
		}
	}
}

public bool:TraceRay_PlayerOnly(entity, contentsMask, any:data)
{
	if (entity == data)
	{
		return true;
	}
	else
	{
		return false;
	}
}

stock Float:GetDistanceToSky(entity)
{
	new Float:TraceEnd[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TraceEnd);

	new Float:f_dest[3];
	f_dest[0] = TraceEnd[0];
	f_dest[1] = TraceEnd[1];
	f_dest[2] = TraceEnd[2] + 8192.0;

	new Float:SkyOrigin[3];
	new Handle:hTrace = TR_TraceRayEx(TraceEnd, f_dest, CONTENTS_WINDOW|CONTENTS_MONSTER, RayType_EndPoint);
	TR_GetEndPosition(SkyOrigin, hTrace);
	CloseHandle(hTrace);

	return SkyOrigin;
}

// Thanks to V0gelz
stock env_shooter(client ,Float:Angles[3], Float:iGibs, Float:Delay, Float:GibAngles[3], Float:Velocity, Float:Variance, Float:Giblife, Float:Location[3], String:ModelType[] )
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
		AcceptEntityInput(Ent, "Shoot", client);
			
		//Send:
		TeleportEntity(Ent, Location, NULL_VECTOR, NULL_VECTOR);

		//Delete:
		//AcceptEntityInput(Ent, "kill");
		CreateTimer(3.0, Timer_KillEnt, Ent);
	}
}


public Action:Timer_KillEnt(Handle:Timer, any:Ent)
{
        if(IsValidEntity(Ent))
        {
                decl String:classname[64];
                GetEdictClassname(Ent, classname, sizeof(classname));
                if (StrEqual(classname, "env_shooter", false) || StrEqual(classname, "gib", false) || StrEqual(classname, "env_sprite", false))
                {
                        RemoveEdict(Ent);
                }
        }
}