#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <morecolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGINVERSION		"0.1"
#define CMDTAG				"{green}[Pinata]{default}"

//Plugin Information:
public Plugin myinfo = 
{
	name = "dog pinata", 
	author = "The Doggy", 
	description = "woof woof", 
	version = PLUGINVERSION,
	url = "doggaming.ga"
};

int g_iLaser = -1;
int g_iHalo = -1;
int g_iLightning = -1;

float g_fDamageMultiplier[MAXPLAYERS + 1];
float g_fDamageReflection[MAXPLAYERS + 1];

bool g_bChainLightning[MAXPLAYERS + 1];

ArrayList g_Pinatas;
ArrayList g_Ents;

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_createpinata", Command_Pinata, ADMFLAG_ROOT, "pinata ya");

	g_Pinatas = new ArrayList();
	g_Ents = new ArrayList();

	for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	HookEvent("player_death", Event_playerDeath, EventHookMode_Pre);
}

public void OnPluginEnd()
{
	for(int i = 0; i < g_Pinatas.Length; i++)
	{
		if(IsValidEntity(g_Pinatas.Get(i)))
		{
			AcceptEntityInput(g_Pinatas.Get(i), "Kill");
			g_Pinatas.Erase(i);
		}
	}

	for(int i = 0; i < g_Ents.Length; i++)
	{
		if(IsValidEntity(g_Ents.Get(i)))
		{
			AcceptEntityInput(g_Ents.Get(i), "Kill");
			g_Ents.Erase(i);
		}
	}
}

public void OnMapStart()
{
	g_iLaser = PrecacheModel("materials/sprites/laser.vmt", true);
	PrecacheModel("models/infected/boomer.mdl", true);
	PrecacheModel("models/w_models/weapons/w_eq_adrenaline.mdl", true);
	PrecacheSound("mexican.wav", true);
	PrecacheSound("candy_eat.wav", true);
	g_iHalo = PrecacheModel("materials/sprites/halo01.vmt", true);
	g_iLightning = PrecacheModel("materials/sprites/lgtning.vmt", true);

	AddFileToDownloadsTable("models/infected/boomer.mdl");
	AddFileToDownloadsTable("models/infected/boomer.dx90.vtx");
	AddFileToDownloadsTable("models/infected/boomer.phy");
	AddFileToDownloadsTable("models/infected/boomer.vvd");

	AddFileToDownloadsTable("materials/models/infected/boomer/boomer.vmt");
	AddFileToDownloadsTable("materials/models/infected/boomer/boomer_color.vtf");

	AddFileToDownloadsTable("models/w_models/weapons/w_eq_adrenaline.mdl");
	AddFileToDownloadsTable("models/w_models/weapons/w_eq_adrenaline.dx90.vtx");
	AddFileToDownloadsTable("models/w_models/weapons/w_eq_adrenaline.dx80.vtx");
	AddFileToDownloadsTable("models/w_models/weapons/w_eq_adrenaline.vvd");
	AddFileToDownloadsTable("models/w_models/weapons/w_eq_adrenaline.sw.vtx");
	AddFileToDownloadsTable("models/w_models/weapons/w_eq_adrenaline.phy");

	AddFileToDownloadsTable("materials/models/choco_adre/bar_choco.vmt");
	AddFileToDownloadsTable("materials/models/choco_adre/bar_choco_nm.vtf");
	AddFileToDownloadsTable("materials/models/choco_adre/bar_choco.vtf");

	AddFileToDownloadsTable("materials/models/choco_adre/bar_pack_w.vmt");
	AddFileToDownloadsTable("materials/models/choco_adre/bar_pack_nm.vtf");
	AddFileToDownloadsTable("materials/models/choco_adre/bar_pack.vtf");
	AddFileToDownloadsTable("materials/models/choco_adre/bar_pack.vmt");

	AddFileToDownloadsTable("sound/mexican.wav");
	AddFileToDownloadsTable("sound/candy_eat.wav");
}

public void ResetVariables(int Client)
{
	g_fDamageMultiplier[Client] = 0.0;
	g_fDamageReflection[Client] = 0.0;
	g_bChainLightning[Client] = false;
}

public void OnClientConnected(int Client)
{
	ResetVariables(Client);
}

public void OnClientPutInServer(int Client)
{
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int Client)
{
	ResetVariables(Client);
	SDKUnhook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action Command_Pinata(int Client, int iArgs)
{
	//client checks
	if(Client <= 0 || Client > MaxClients) return Plugin_Handled;

	//create and setup entity
	int entity = CreateEntityByName("prop_physics_override");
	DispatchKeyValue(entity, "Health", "250");
	DispatchKeyValue(entity, "spawnflags", "520");
	DispatchKeyValue(entity, "Model", "models/infected/boomer.mdl");

	//hook and spawn entity
	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	DispatchSpawn(entity);

	//teleport entity
	float pos[3];
	GetClientAbsOrigin(Client, pos);
	pos[2] += 100.0;
	TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

	g_Pinatas.Push(entity);

	//tell player
	CPrintToChat(Client, "%s Created Pinata at: X: %.2f, Y: %.2f, Z: %.2f", CMDTAG, pos[0], pos[2], pos[1]);
	return Plugin_Handled;
}

public Action Event_playerDeath(Event hEvent, const char[] eventName, bool bBroadcast)
{
	int Client = GetClientOfUserId(hEvent.GetInt("userid")); //Dead Guy
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker")); //Alive Guy

	if(!IsValidClient(Client) || !IsValidClient(iAttacker)) return Plugin_Continue;

	g_bChainLightning[Client] = false;
	g_fDamageReflection[Client] = 0.0;
	g_fDamageMultiplier[Client] = 0.0;

	if(g_bChainLightning[iAttacker] || g_fDamageReflection[iAttacker] > 0.0)
	{
		hEvent.SetString("weapon", "physcannon");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	//validity checks
	if(victim == attacker || attacker <= 0) return Plugin_Continue;

	if(IsValidClient(victim) && IsValidClient(attacker))
	{
		if(g_fDamageMultiplier[attacker] > 0.0) damage *= g_fDamageMultiplier[attacker];

		if(g_bChainLightning[attacker])
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(!IsValidClient(i)) continue;

				float pos[3];
				GetClientAbsOrigin(i, pos);
				pos[2] = damagePosition[2];

				if(GetVectorDistance(damagePosition, pos) <= 500)
				{
					TE_SetupBeamPoints(damagePosition, pos, g_iLightning, 0, 0, 0, 0.2, 10.0, 0.5, 10, 10.0, {255, 0, 125, 255}, 1);
					SDKHooks_TakeDamage(victim, attacker, attacker, damage / 2.0, DMG_SHOCK);
					TE_SendToAll();
				}
			}
		}

		if(g_fDamageReflection[victim] > 0.0)
		{
			float reflectedDamage;
			if(g_fDamageReflection[victim] >= damage) 
			{
				g_fDamageReflection[victim] -= damage;
				reflectedDamage = damage;
				damage = 0.0;
			}
			else
			{
				damage -= g_fDamageReflection[victim];
				g_fDamageReflection[victim] -= damage;
				reflectedDamage = damage;
			}

			if(g_fDamageReflection[victim] < 0.0) g_fDamageReflection[victim] = 0.0;

			float pos[3];
			GetClientAbsOrigin(attacker, pos);
			pos[2] += 10.0;

			TE_SetupBeamPoints(pos, damagePosition, g_iLightning, 0, 0, 0, 0.2, 10.0, 0.5, 10, 10.0, {255, 0, 125, 255}, 1);
			SDKHooks_TakeDamage(attacker, victim, victim, reflectedDamage, DMG_SHOCK);
			TE_SendToAll();

		}
		return Plugin_Changed;
	}
	else if(g_Pinatas.FindValue(victim) != -1 && IsValidEntity(victim) && IsValidClient(attacker))
	{
		//we only want pinata to be broken by crowbar/stunstick
		if(damagetype != DMG_CLUB)
		{
			CPrintToChat(attacker, "%s You can only use a pinata whacking stick to break this!", CMDTAG);
			damage = 0.0;
			return Plugin_Changed;
		}

		//check if pinata will break within next hit
		int health = GetEntProp(victim, Prop_Data, "m_iHealth");
		if(health - damage <= 0)
		{
			EmitSoundToAll("mexican.wav", victim);
			g_Pinatas.Erase(g_Pinatas.FindValue(victim));
			AcceptEntityInput(victim, "Kill");
			int entNum = GetRandomInt(15, 50);

			for(int i = 0; i < entNum; i++)
			{
				int ent = CreateEntityByName("prop_physics_override");
				g_Ents.Push(ent);
				DispatchKeyValue(ent, "Health", "0");
				DispatchKeyValue(ent, "spawnflags", "1048580");
				DispatchKeyValue(ent, "Model", "models/w_models/weapons/w_eq_adrenaline.mdl");
				SetEntProp(ent, Prop_Data, "m_CollisionGroup", 5);

				int rgba[4] = { 255, 255, 255, 255 };
				rgba[0] = GetRandomInt(0, 255);
				rgba[1] = GetRandomInt(0, 255);
				rgba[2] = GetRandomInt(0, 255);
				TE_SetupBeamFollow(ent, g_iLaser, g_iHalo, 10.0, 20.0, 1.0, 10, rgba);
				DispatchSpawn(ent);

				float pos[3], velocity[3];
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos);
				velocity[0] = GetRandomFloat(-250.0, 250.0); // X
				velocity[1] = GetRandomFloat(-250.0, 250.0); // Z
				velocity[2] = GetRandomFloat(0.0, 100.0); 	 // Y
				TeleportEntity(ent, pos, NULL_VECTOR, velocity);
				TE_SendToAll();
			}
		}
	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int Client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_USE)
	{
		int iEnt = GetClientAimTarget2(Client);
		if(g_Ents.FindValue(iEnt) == -1) return Plugin_Continue;
		
		float clientOrigin[3], entOrigin[3];
		GetClientAbsOrigin(Client, clientOrigin);
		GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", entOrigin);
		float distance = GetVectorDistance(clientOrigin, entOrigin);
		if (distance > 100.0) return Plugin_Continue;

		EmitSoundToAll("candy_eat.wav", iEnt);
		g_Ents.Erase(g_Ents.FindValue(iEnt));
		AcceptEntityInput(iEnt, "Kill");
		int rand = GetRandomInt(1, 6);

		switch(rand) /* debate on whether these need to be removed/reset on death lol */
		{
			//disabled cause gay
			/*case 0:
			{
				CPrintToChat(Client, "%s You start to feel lighter on your feet!", CMDTAG);
				float grav = GetEntityGravity(Client);
				SetEntityGravity(Client, grav - 0.2);
			}*/
			case 1:
			{
				CPrintToChat(Client, "%s Zoom Zoom!", CMDTAG);
				float speed = GetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue");
				SetEntPropFloat(Client, Prop_Data, "m_flLaggedMovementValue", speed + 1.0);
			}
			case 2:
			{
				CPrintToChat(Client, "%s Tank Mode Activated!", CMDTAG);
				int hp = GetClientHealth(Client);
				SetEntityHealth(Client, hp + 1000);
			}
			case 3:
			{
				CPrintToChat(Client, "%s Max Armour!", CMDTAG);
				int armour = GetClientArmor(Client);
				SetEntProp(Client, Prop_Data, "m_ArmorValue", armour + 500);
			}
			case 4: //reset after certain time?
			{
				CPrintToChat(Client, "%s UDamage Activated!", CMDTAG);
				g_fDamageMultiplier[Client] += 2.0;
				CreateTimer(120.0, Timer_ResetDamage, Client);
			}
			case 5: //reset after certain time?
			{
				CPrintToChat(Client, "%s Damage Reflection!", CMDTAG);
				g_fDamageReflection[Client] += 100.0;
			}
			case 6:
			{
				CPrintToChat(Client, "%s Chain Lightning!", CMDTAG);
				g_bChainLightning[Client] = true;
			}
			default:
			{
				CPrintToChat(Client, "%s Effect not implemented :(", CMDTAG);
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_ResetDamage(Handle Timer, int Client)
{
	if(!IsValidClient(Client)) return Plugin_Stop;
	g_fDamageMultiplier[Client] = 0.0;
	return Plugin_Stop;
}

public int GetClientAimTarget2(int Client)
{
	float eyeLoc[3], ang[3];
	GetClientEyePosition(Client, eyeLoc);
	GetClientEyeAngles(Client, ang);
	TR_TraceRayFilter(eyeLoc, ang, MASK_SOLID, RayType_Infinite, TRFilter_AimTarget, Client);
	int entity = TR_GetEntityIndex();
	
	if (entity > 0)
		return entity;
	else
		return -1;
}

public bool TRFilter_AimTarget(int entity, int mask, int Client)
{
	if (entity == Client)
		return false;
	return true;
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}