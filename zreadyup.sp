#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[CS:GO] Match Control",
	author = "The Doggy",
	version = "0.7",
	description = "Allows players to ready up for matches.",
	url = "coldcommunity.com"
};

bool g_bTReady[MAXPLAYERS + 1];
bool g_bCTReady[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_ready", Command_Ready, "[SM] Signals to everyone else that you are ready.");
	RegConsoleCmd("sm_unready", Command_UnReady, "[SM] Signals to everyone else that you are not ready.");
	RegConsoleCmd("sm_notready", Command_UnReady, "[SM] Signals to everyone else that you are not ready.");
	RegConsoleCmd("sm_noready", Command_UnReady, "[SM] Signals to everyone else that you are not ready.");

	AddCommandListener(Listener_Say, "say");
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public void Event_RoundStart(Event hEvent, const char[] sName, bool bBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_bTReady[i] = false;
		g_bCTReady[i] = false;
	}
}

public Action Listener_Say(int Client, const char[] sCommand, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Continue;

	char chat[256];
	GetCmdArgString(chat, sizeof(chat));
	TrimString(chat);
	StripQuotes(chat);

	if(StrEqual(chat, ".ready")) Command_Ready(Client, 1);
	else if(StrEqual(chat, ".unready") || StrEqual(chat, ".notready") || StrEqual(chat, ".noready")) Command_UnReady(Client, 1);

	return Plugin_Continue;
}

public Action Command_Ready(int Client, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Handled;

	if(GetClientTeam(Client) == CS_TEAM_CT)
	{
		if(g_bCTReady[Client])
		{
			PrintToChat(Client, "[SM] You are already ready!");
			return Plugin_Handled;
		}

		g_bCTReady[Client] = true;
		PrintToChat(Client, "[SM] You are now ready!");

		bool bCTReady = true;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == CS_TEAM_CT)
			{
				if(!g_bCTReady[i])
				{
					bCTReady = false;
					break;
				}
			}
		}

		if(bCTReady) PrintToChatAll("[SM] Counter-Terrorists are now ready.");
	}
	else if(GetClientTeam(Client) == CS_TEAM_T)
	{
		if(g_bTReady[Client])
		{
			PrintToChat(Client, "[SM] You are already ready!");
			return Plugin_Handled;
		}

		g_bTReady[Client] = true;
		PrintToChat(Client, "[SM] You are now ready!");

		bool bTReady = true;
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				if(!g_bTReady[i])
				{
					bTReady = false;
					break;
				}
			}
		}

		if(bTReady) PrintToChatAll("[SM] Terrorists are now ready.");
	}

	bool bAllReady = true;
	int iPlayerCount;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(GetClientTeam(i) == CS_TEAM_T)
			{
				if(!g_bTReady[i])
				{
					bAllReady = false;
					break;
				}
			}
			else if(GetClientTeam(i) == CS_TEAM_CT)
			{
				if(!g_bCTReady[i])
				{
					bAllReady = false;
					break;
				}
			}

			iPlayerCount++;
		}
	}
	if(bAllReady && iPlayerCount > 1) PrintToChatAll("[SM] Both teams are ready!");

	return Plugin_Handled;
}

public Action Command_UnReady(int Client, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Handled;

	if(GetClientTeam(Client) == CS_TEAM_CT)
	{
		if(!g_bCTReady[Client])
		{
			PrintToChat(Client, "[SM] You are already unready!");
			return Plugin_Handled;
		}

		g_bCTReady[Client] = false;
		PrintToChat(Client, "[SM] You are now unready!");
		PrintToChatAll("[SM] Counter-Terrorists are now unready.");
	}
	else if(GetClientTeam(Client) == CS_TEAM_T)
	{
		if(!g_bTReady[Client])
		{
			PrintToChat(Client, "[SM] You are already unready!");
			return Plugin_Handled;
		}

		g_bTReady[Client] = false;
		PrintToChat(Client, "[SM] You are now unready!");
		PrintToChatAll("[SM] Terrorists are now unready.");
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