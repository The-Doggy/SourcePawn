#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Doggy", 
	author = "The Doggy", 
	description = "Does shit lol", 
	version = "1.0.0",
	url = "coldcommunity.com"
};

//TODO: Is it possible to create a couple path_track's parented to the player that the train will follow?

int g_iTrain = -1;
bool g_bTrain;

public void OnPluginStart()
{
	RegAdminCmd("sm_movetrain", Command_MoveTrain, ADMFLAG_ROOT, "MOVES THE DAMN TRAIN CJ!");
}

public void OnMapStart()
{
	ServerCommand("ent_remove_all pdrotation");
	ServerCommand("ent_remove_all func_rotating");

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if(StrEqual(sMap, "rp_freemancity_kbm_v1a", false))
		g_iTrain = FindEntityByClassname(-1, "func_tracktrain");
	else
	{
		PrintToServer("Map is not freemancity. Not looking for train entity.");
		return;
	}

	if(g_iTrain < 0)
	{
		PrintToServer("Train cannot be found, does it exist?");
		return;
	}
	else
	{
		PrintToServer("Train found!");

		//Set orientation of train to be fixed to spawn position
		SetEntProp(g_iTrain, Prop_Data, "m_eOrientationType", 0);
	}
}

public Action Command_MoveTrain(int Client, int iArgs)
{
	if(Client <= 0)
	{
		PrintToServer("This command can only be executed in-game.");
		return Plugin_Handled;
	}

	if(g_iTrain <= -1)
	{
		PrintToChat(Client, "Train entity doesn't exist, cannot continue.");
		return Plugin_Handled;
	}

	if(!g_bTrain)
	{
		PrintToChat(Client, "You are now controlling the train, run this command again to stop.");
		g_bTrain = true;
		CreateTimer(0.1, Timer_MoveTrain, Client, TIMER_REPEAT);
	}
	else
	{
		PrintToChat(Client, "You have stopped controlling the train.");
		SetEntityMoveType(Client, MOVETYPE_ISOMETRIC);
		g_bTrain = false;
	}

	return Plugin_Handled;
}

public Action Timer_MoveTrain(Handle hTimer, int Client)
{
	if(!g_bTrain || Client <= 0 || Client > MaxClients)
		return Plugin_Stop;

	float fOrigin[3], fAngles[3];
	GetClientAbsOrigin(Client, fOrigin);
	GetClientAbsAngles(Client, fAngles);

	//Move the train down a bit...
	fOrigin[2] -= 50.0;

	//Experimenting with movetypes...
	if(GetEntityMoveType(Client) != MOVETYPE_FLYGRAVITY)
		SetEntityMoveType(Client, MOVETYPE_FLYGRAVITY);

	TeleportEntity(g_iTrain, fOrigin, fAngles, NULL_VECTOR);

	//Teleport the player up a bit...
	fOrigin[2] += 50.0;
	TeleportEntity(Client, fOrigin, NULL_VECTOR, NULL_VECTOR);

	return Plugin_Continue;
}