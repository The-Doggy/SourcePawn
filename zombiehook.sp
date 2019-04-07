#include <sourcemod>
#include <sdkhooks>
#include <morecolors>
#include <bluerp/BluRP>
#include <bluerp>

#pragma semicolon 1
#pragma newdecls required

#define MAXENTS				2048
#define ZOMBIE_HEALTH		100		//Amount of health zombies should spawn with
#define MONEY_REWARD		1000 	//Max amount of money to give per zombie kill

int g_iNpcDamage[MAXENTS + 1][MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "zombiehook", 
	author = "The Doggy", 
	description = "hook da zombies", 
	version = "1.0", 
	url = "coldcommunity.com"
};

public void OnMapStart()
{
	SetConVarInt(FindConVar("sk_zombie_health"), ZOMBIE_HEALTH);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "npc_zombie", false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
		HookSingleEntityOutput(entity, "OnDeath", Event_NPCDeath);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(attacker > 0 && attacker <= MaxClients)
	{
		char class[32];
		GetEdictClassname(victim, class, sizeof(class));
		if(StrEqual(class, "npc_zombie")) g_iNpcDamage[victim][attacker] += RoundFloat(damage);
	}
	return Plugin_Continue;
}

public void Event_NPCDeath(const char[] output, int caller, int activator, float delay)
{
	char class[32];
	GetEdictClassname(caller, class, sizeof(class));

	if (activator == 0 || !IsValidClient(activator))
		return;
	
	if(StrEqual(class, "npc_zombie", false))
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(g_iNpcDamage[caller][i] > RoundFloat(float(ZOMBIE_HEALTH) / 10.0))
				{
					BClient player = GetPlayerInstance(i);
					if (!player.IsValid)
					{
						//player is not valid
						continue;
					}

					if(g_iNpcDamage[caller][i] > ZOMBIE_HEALTH) g_iNpcDamage[caller][i] = ZOMBIE_HEALTH;
					float dpsPercent = FloatDiv(float(g_iNpcDamage[caller][i]), float(ZOMBIE_HEALTH));
					int playerGain = RoundToCeil(FloatMul(dpsPercent, float(MONEY_REWARD)));
					player.Bank += playerGain;
				}
				else continue;
				g_iNpcDamage[caller][i] = 0;
			}
		}
		UnhookSingleEntityOutput(caller, "OnDeath", Event_NPCDeath);
	}
}

public void SQL_GenericQuery(Database db, DBResultSet results, const char[] sError, any data)
{
	if (results == null) LogError("SQL_GenericQuery: Query failed! %s", sError);
}