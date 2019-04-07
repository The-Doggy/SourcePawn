#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

// Edit/Add to these for your own commands
char g_sCommands[][] = {
	{"sm_command2"},
	{"sm_command3"},
	{"sm_command4"}
};

int g_iCount[MAXPLAYERS + 1] = {0, ...};

public void OnPluginStart()
{
	RegConsoleCmd("sm_command", Command_Command, "[SM] Is a command.");
}

public Action Command_Command(int Client, int iArgs)
{
	if(!IsValidClient(Client)) return Plugin_Handled;

	CreateTimer(1.0, Timer_Command, Client, TIMER_REPEAT);
	return Plugin_Handled;
}

public Action Timer_Command(Handle Timer, int Client)
{
	if(!IsValidClient(Client)) return Plugin_Stop;

	FakeClientCommand(Client, "%s", g_sCommands[g_iCount[Client]]);
	g_iCount[Client]++;

	if(g_iCount[Client] >= sizeof(g_sCommands)) 
	{
		g_iCount[Client] = 0;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client);
}