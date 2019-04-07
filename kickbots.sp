#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

ConVar g_hCVEnabled;

public void OnPluginStart()
{
	g_hCVEnabled = CreateConVar("sm_botkick_enabled", "1", "Enable this plugin? 1 = Enabled, 0 = Disabled");
	g_hCVEnabled.AddChangeHook(ConVar_Changed);
	HookEvent("round_start", Event_RoundStart);
}

public void ConVar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(g_hCVEnabled.BoolValue) ServerCommand("bot_quota 0");
	else ServerCommand("bot_quota 10");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_hCVEnabled.BoolValue) ServerCommand("bot_quota 0");
	else ServerCommand("bot_quota 10");
}