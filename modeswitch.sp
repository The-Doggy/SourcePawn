#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <morecolors>
#include <mapchooser>

#pragma semicolon 1
#pragma newdecls required

#define CHATTAG		"{royalblue}[DG]{default}"

public Plugin myinfo = 
{
	name = "Gamemode Switcher", 
	author = "The Doggy", 
	description = "Switches between different gamemodes for server owners that don't want to/can't run multiple servers", 
	version = "1.0.0",
	url = "coldcommunity.com" //coldcom branding yet im using DG tag lol...
};

ConVar g_cvDefaultMode;
ConVar g_cvEndMode;
char g_sMode[16];

public void OnPluginStart()
{
	g_cvDefaultMode = CreateConVar("dg_defaultmode", "jb", "Sets which gamemode the server will startup in: jb - Jailbreak, mg - Minigames");
	AutoExecConfig(true);
	g_cvEndMode = CreateConVar("dg_endmode", "", "Sets which gamemode the server will/has switch(ed) to: jb - Jailbreak, mg - Minigames");

	RegConsoleCmd("sm_switchmode", Command_SwitchMode, "Switches the current server gamemode");
}

public void OnMapStart()
{
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if(StrContains(sMap, "mg", false) != -1)
		SetupMinigames();
	else
		SetupJailbreak();
}

public Action Command_SwitchMode(int Client, int iArgs)
{
	//Player specified a gamemode to switch to
	if(iArgs != 0)
	{
		char sArg[8];
		GetCmdArg(1, sArg, sizeof(sArg));
		if(!StrEqual(sArg, "jb", false) && !StrEqual(sArg, "mg", false))
		{
			CPrintToChat(Client, "%s Invalid Gamemode. Valid gamemodes are: {green}mg (Minigames){default} and {green}jb (Jailbreak){default}.", CHATTAG);
			return Plugin_Handled;
		}
		else
		{
			if(StrEqual(sArg, "jb", false) && !StrEqual(g_sMode, "Jailbreak", false))
			{
				Format(g_sMode, sizeof(g_sMode), "Jailbreak");
			}
			else if(StrEqual(sArg, "mg", false) && !StrEqual(g_sMode, "Minigames", false))
			{
				Format(g_sMode, sizeof(g_sMode), "Minigames");
			}
			else
			{
				CPrintToChat(Client, "%s Gamemode {green}%s{default} is already selected, please choose another gamemode. Valid gamemodes are: {green}mg (minigames){default} and {green}jb (jailbreak){default}.", CHATTAG, g_sMode);
				return Plugin_Handled;
			}

			CPrintToChatAll("%s %N has changed the gamemode to {green}%s{default}", CHATTAG, Client, g_sMode);

			OnGameModeChanged();
			return Plugin_Handled;
		}
	}

	//Player has not specified a gamemode to switch to
	if(StrEqual(g_sMode, "", false))
	{
		char sMap[64];
		GetCurrentMap(sMap, sizeof(sMap));

		//Is the current map a jailbreak or minigame map?
		if((StrContains(sMap, "ba_", false) != -1) || (StrContains(sMap, "jb_", false) != -1))
		{
			Format(g_sMode, sizeof(g_sMode), "Minigames");
			CPrintToChatAll("%s %N has changed the gamemode to {green}%s{default}.", CHATTAG, Client, g_sMode);
			OnGameModeChanged();
			return Plugin_Handled;
		}
		else if(StrContains(sMap, "mg_", false) != -1)
		{
			Format(g_sMode, sizeof(g_sMode), "Jailbreak");
			CPrintToChatAll("%s %N has changed the gamemode to {green}%s{default}.", CHATTAG, Client, g_sMode);
			OnGameModeChanged();
			return Plugin_Handled;
		}
		else
		{
			CPrintToChat(Client, "%s Current map is not recognized as a valid gamemode map. Please select a gamemode using {green}sm_switchmode <gamemode>{default} or contact an administrator for help.", CHATTAG);
			return Plugin_Handled;
		}
	}
	else
	{
		if(StrEqual(g_sMode, "Jailbreak"))
		{
			Format(g_sMode, sizeof(g_sMode), "Minigames");
			CPrintToChatAll("%s %N has changed the gamemode to {green}%s{default}.", CHATTAG, Client, g_sMode);
			OnGameModeChanged();
			return Plugin_Handled;
		}
		else
		{
			Format(g_sMode, sizeof(g_sMode), "Jailbreak");
			CPrintToChatAll("%s %N has changed the gamemode to {green}%s{default}.", CHATTAG, Client, g_sMode);
			OnGameModeChanged();
			return Plugin_Handled;
		}
	}
}

public void OnGameModeChanged()
{
	char sEndMode[8], sDefaultMode[8];
	g_cvEndMode.GetString(sEndMode, sizeof(sEndMode));
	g_cvDefaultMode.GetString(sDefaultMode, sizeof(sDefaultMode));

	//A gamemode has not been set via sm_switchmode but the last map was ended due to a gamemode change
	if(StrEqual(g_sMode, "", false) && !StrEqual(sEndMode, "", false))
	{
		if(StrEqual(sEndMode, "jb", false))
			SetupJailbreak();
		else if(StrEqual(sEndMode, "mg", false))
			SetupMinigames();
		else
			ThrowError("g_cvEndMode gave invalid value for gamemode in OnGameModeChanged().");

		//Reset g_cvEndMode cvar
		g_cvEndMode.RestoreDefault();
		return;
	}

	if(StrEqual(g_sMode, "Jailbreak", false))
	{
		SetConVarString(FindConVar("mapcyclefile"), "jailbreak.txt");
		ServerCommand("sm plugins reload mapchooser");
		ServerCommand("sm plugins reload nominations");
		ServerCommand("sm plugins reload rockthevote");
		g_cvEndMode.SetString("jb");
		CreateTimer(5.0, Timer_RunVote);
		CPrintToChatAll("%s Setting up configs and creating map vote...", CHATTAG);
	}
	else if(StrEqual(g_sMode, "Minigames", false))
	{
		SetConVarString(FindConVar("mapcyclefile"), "minigames.txt");
		ServerCommand("sm plugins reload mapchooser");
		ServerCommand("sm plugins reload nominations");
		ServerCommand("sm plugins reload rockthevote");
		g_cvEndMode.SetString("mg");
		CreateTimer(5.0, Timer_RunVote);
		CPrintToChatAll("%s Setting up configs and creating map vote...", CHATTAG);
	}
}

public Action Timer_RunVote(Handle hTimer)
{
	//Apparently this is all u need for mapchooser vote lol...
	bool bCanStartVote;
	for(int i = 1; i <= 32; i++)
	{
		if(IsClientInGame(i))
			bCanStartVote = true;
		else
			bCanStartVote = false;

		if(!CanMapChooserStartVote() || !EndOfMapVoteEnabled() || HasEndOfMapVoteFinished() || !bCanStartVote)
			continue;

		InitiateMapChooserVote(MapChange_MapEnd);
	}
	return Plugin_Stop;
}

public void SetupJailbreak()
{
	SetConVarString(FindConVar("mapcyclefile"), "jailbreak.txt");
	ServerCommand("sm plugins reload mapchooser");
	ServerCommand("sm plugins reload nominations");
	ServerCommand("sm plugins reload rockthevote");
	SetConVarInt(FindConVar("sv_airaccelerate"), 100);
	ServerCommand("sm plugins unload dice_sm");
	ServerCommand("sm plugins unload infinite-jumping");
	ServerCommand("sm plugins load sm_ctban");
	ServerCommand("sm plugins load sm_hosties");
}

public void SetupMinigames()
{
	SetConVarString(FindConVar("mapcyclefile"), "minigames.txt");
	ServerCommand("sm plugins reload mapchooser");
	ServerCommand("sm plugins reload nominations");
	ServerCommand("sm plugins reload rockthevote");
	SetConVarInt(FindConVar("sv_airaccelerate"), 99999999);
	ServerCommand("sm plugins unload sm_ctban");
	ServerCommand("sm plugins unload sm_hosties");
	ServerCommand("sm plugins load dice_sm");
	ServerCommand("sm plugins load infinite-jumping");
}