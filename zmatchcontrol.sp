#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[CS:GO] Match Control",
	author = "The Doggy",
	version = "0.7",
	description = "Allows players to pause matches.",
	url = "coldcommunity.com"
};

enum PauseStatus
{
	ROUND_RESTARTED = 0,
	CT_PAUSE,
	CT_UNPAUSE,
	T_PAUSE,
	T_UNPAUSE
};

PauseStatus g_eCTPause;
PauseStatus g_eTPause;

bool g_bCTPause;
bool g_bTPause;
bool g_bMatchPaused;
bool g_bFreezeTime;

public void OnPluginStart()
{
	RegConsoleCmd("sm_pause", Command_Pause, "[SM] Pauses the match next round once both teams have used this.");
	RegConsoleCmd("sm_unpause", Command_Unpause, "[SM] Unpauses the match.");

	AddCommandListener(Listener_Say, "say");
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bBroadcast)
{
	if((g_bTPause || g_bCTPause) && (g_eCTPause == CT_PAUSE || g_eTPause == T_PAUSE))
	{
		ServerCommand("mp_pause_match");
		PrintToChatAll("[SM] Match is paused, use !unpause to restart the match when ready.");
		g_bMatchPaused = true;
	}

	g_eCTPause = ROUND_RESTARTED;
	g_eTPause = ROUND_RESTARTED;
	g_bCTPause = false;
	g_bTPause = false;
	g_bFreezeTime = true;
}

public void OnGameFrame()
{
	if((!g_bCTPause && !g_bTPause) && (g_eCTPause == CT_UNPAUSE && g_eTPause == T_UNPAUSE) && g_bMatchPaused)
	{
		ServerCommand("mp_unpause_match");
		g_bMatchPaused = false;
	}
	else if((g_bTPause || g_bCTPause) && (g_eCTPause == CT_PAUSE || g_eTPause == T_PAUSE) && g_bFreezeTime && !g_bMatchPaused)
	{
		ServerCommand("mp_pause_match");
		PrintToChatAll("[SM] Match is paused, use !unpause to restart the match when ready.");
		g_bMatchPaused = true;
	}
}

public Action Listener_Say(int Client, const char[] sCommand, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Continue;

	char chat[256];
	GetCmdArgString(chat, sizeof(chat));
	TrimString(chat);
	StripQuotes(chat);

	if(StrEqual(chat, ".pause")) Command_Pause(Client, 1);
	else if(StrEqual(chat, ".unpause")) Command_Unpause(Client, 1);

	return Plugin_Continue;
}

public Action Command_Pause(int Client, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Handled;

	if(g_bMatchPaused)
	{
		PrintToChat(Client, "[SM] Match is already paused! Use !unpause to resume the match.");
		return Plugin_Handled;
	}

	if(GetClientTeam(Client) == CS_TEAM_CT)
	{
		if((g_bCTPause && g_eCTPause == CT_PAUSE) || (g_bTPause && g_eTPause == T_PAUSE))
		{
			PrintToChat(Client, "[SM] A team has already used !pause this round!");
			return Plugin_Handled;
		}
		else if(g_bFreezeTime)
			PrintToChatAll("[SM] Counter-Terrorists want to pause. Match will be paused!");
		else
			PrintToChatAll("[SM] Counter-Terrorists want to pause. Match will be paused next round!");

		g_bCTPause = true;
		g_eCTPause = CT_PAUSE;
		return Plugin_Handled;
	}
	else if(GetClientTeam(Client) == CS_TEAM_T)
	{
		if(g_bTPause && g_eTPause == T_PAUSE)
		{
			PrintToChat(Client, "[SM] Your team has already used !pause this round!");
			return Plugin_Handled;
		}
		else if(g_bFreezeTime)
			PrintToChatAll("[SM] Terrorists want to pause. Match will be paused!");
		else
			PrintToChatAll("[SM] Terrorists want to pause. Match will be paused next round!");

		g_bTPause = true;
		g_eTPause = T_PAUSE;
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action Command_Unpause(int Client, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Handled;

	if(GetClientTeam(Client) == CS_TEAM_CT)
	{
		if(!g_bCTPause && g_eCTPause == CT_UNPAUSE)
		{
			PrintToChat(Client, "[SM] Your team has already used !unpause this round!");
			return Plugin_Handled;
		}
		else if(!g_bTPause && (g_eTPause == T_UNPAUSE || g_eTPause == ROUND_RESTARTED) && !g_bMatchPaused)
			PrintToChatAll("[SM] Counter-Terrorists want to unpause. Match will be continued!");
		else
			PrintToChatAll("[SM] Counter-Terrorists want to unpause. Waiting for Terrorists to !unpause.");

		g_bCTPause = false;
		g_eCTPause = CT_UNPAUSE;
		return Plugin_Handled;
	}
	else if(GetClientTeam(Client) == CS_TEAM_T)
	{
		if(!g_bTPause && g_eTPause == T_UNPAUSE)
		{
			PrintToChat(Client, "[SM] Your team has already used !unpause this round!");
			return Plugin_Handled;
		}
		else if(!g_bCTPause && (g_eCTPause == CT_UNPAUSE || g_eCTPause == ROUND_RESTARTED) && !g_bMatchPaused)
			PrintToChatAll("[SM] Terrorists want to unpause. Match will be continued!");
		else
			PrintToChatAll("[SM] Terrorists want to unpause. Waiting for Counter-Terrorists to !unpause.");

		g_bTPause = false;
		g_eTPause = T_UNPAUSE;
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	return client >= 1 &&
	client <= MaxClients &&
	IsClientConnected(client) &&
	IsClientAuthorized(client) &&
	IsClientInGame(client) &&
	IsPlayerAlive(client);
}