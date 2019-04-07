#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGINVERSION	"1.0"

//Plugin Information:
public Plugin myinfo = 
{
	name = "Show Damage", 
	author = "The Doggy", 
	description = "Shows the damage taken/given by a player", 
	version = PLUGINVERSION,
	url = "coldcommunity.com"
};

ArrayList g_DamageGiven[MAXPLAYERS + 1]; //FUCKING ARRAYLISTS NO FUCKING WORK JIOHGDSOIHGJDIOSYHDFS
ArrayList g_DamageTaken[MAXPLAYERS + 1];

public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			g_DamageGiven[i] = new ArrayList();
			g_DamageTaken[i] = new ArrayList();
			SDKHook(i, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
		}
	}

	RegAdminCmd("sm_ch", Command_ShowDamage, ADMFLAG_GENERIC, "[SM] Shows how much damage a player has given/taken.");
	HookEvent("player_spawn", Event_playerSpawn, EventHookMode_Post);

	/*float damage[2] = { 1.0, 20.0 };
	g_DamageGiven[1].SetArray(0, damage);*/
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client))
	{
		g_DamageGiven[client] = new ArrayList();
		SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
	}
}

public void OnClientDisconnect(int client)
{
	if(IsValidClient(client))
	{
		g_DamageGiven[client] = null;
		SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamagePost);
	}
}

public Action Event_playerSpawn(Event hEvent, const char[] eventName, bool bBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if(IsValidClient(client) && g_DamageTaken[client] != INVALID_HANDLE && g_DamageGiven[client] != INVALID_HANDLE)
	{
		g_DamageGiven[client].Clear();
		g_DamageTaken[client].Clear();
	}
	return Plugin_Continue;
}

public Action OnTakeDamagePost(int victim, int& attacker, int& inflictor, float& damage, int& damageType)
{
	if(IsValidClient(victim) && IsValidClient(attacker) && victim != attacker)
	{
		for(int i = 0; i < g_DamageTaken[victim].Length; i++)
		{
			float current[2];
			g_DamageTaken[victim].GetArray(i, current);

			int client = view_as<int>(current[0]);
			if(attacker != client) continue;

			damage += current[1];
		}

		for(int i = 0; i < g_DamageGiven[attacker].Length; i++)
		{
			float current[2];
			g_DamageGiven[attacker].GetArray(i, current);

			int client = view_as<int>(current[0]);
			if(victim != client) continue;

			damage += current[1];
		}

		float damageTaken[2];
		float damageGiven[2];

		damageTaken[0] = view_as<float>(attacker);
		damageTaken[1] = damage;
		damageGiven[0] = view_as<float>(victim);
		damageGiven[1] = damage;

		g_DamageTaken[victim].SetArray(g_DamageTaken[victim].Length - 1, damageTaken);
		g_DamageGiven[attacker].SetArray(g_DamageGiven[attacker].Length - 1, damageGiven);
	}
}

public Action Command_ShowDamage(int client, int args)
{
	if(IsValidClient(client))
	{
		if(args != 1)
		{
			PrintToChat(client, "[SM] Invalid Syntax. Usage: sm_ch <player>");
			return Plugin_Handled;
		}

		char target[64];
		GetCmdArg(1, target, sizeof(target));

		int targetClient = FindTarget(client, target, false, false);
		if(!IsValidClient(targetClient))
		{
			PrintToChat(client, "[SM] Invalid Target: %s", target);
			return Plugin_Handled;
		}

		Menu hMenu = new Menu(ShowDamageMenu);
		hMenu.AddItem("0", "Damage Taken:", ITEMDRAW_RAWLINE);
		for(int i = 0; i < g_DamageTaken[targetClient].Length; i++)
		{
			float current[2];
			g_DamageTaken[targetClient].GetArray(i, current);

			int currentClient = view_as<int>(current[0]);
			if(!IsValidClient(currentClient)) continue;

			float damage = current[1];
			char display[64];
			Format(display, sizeof(display), "%N: %.0f damage taken.", currentClient, damage);
			hMenu.AddItem("1", display, ITEMDRAW_DISABLED);
		}

		hMenu.AddItem("0", "Damage Given:", ITEMDRAW_RAWLINE);
		for(int i = 0; i < g_DamageGiven[targetClient].Length; i++)
		{
			float current[2];
			g_DamageGiven[targetClient].GetArray(i, current);

			int currentClient = view_as<int>(current[0]);
			if(!IsValidClient(currentClient)) continue;

			float damage = current[1];
			char display[64];
			Format(display, sizeof(display), "%N: %.0f damage given.", currentClient, damage);
			hMenu.AddItem("1", display, ITEMDRAW_DISABLED);
		}
		hMenu.Pagination = 9;
		hMenu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int ShowDamageMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
			delete menu;
		}
	}
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}