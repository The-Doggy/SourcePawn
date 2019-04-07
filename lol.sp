#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

//Plugin Information:
public Plugin myinfo = 
{
	name = "Set HP", 
	author = "The Doggy", 
	description = "Sets CT HP.", 
	version = PLUGIN_VERSION,
	url = "coldcommunity.com"
};

ConVar CTHealth, enable;

public void OnPluginStart()
{
	CTHealth = CreateConVar("sm_cthp_on_spawn", "1000", "Change CT health");
	enable = CreateConVar("sm_enable_change_hp", "1", "enable/disable plugin");
	AutoExecConfig(true, "sm_cthp");
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	if (enable.BoolValue)
	{
		if (IsValidClient(client) && GetClientTeam(client) == CS_TEAM_CT)
			CreateTimer(2.0, ChangeHP, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action ChangeHP(Handle timer, int client)
{
	if(IsValidClient(client))
	{
		int hp = CTHealth.IntValue;
		SetEntityHealth(client, hp);
	}
	return Plugin_Stop;
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}