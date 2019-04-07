#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define MATERIAL_PATH		"overlays/material.vmt"				// File location of overlay vmt relative to materials folder
#define TEXTURE_PATH		"overlays/texture.vtf"				// File location of overlay vtf relative to materials folder
#define OVERLAY_TIME		10.0								// Time to display overlay

public Plugin myinfo = 
{
    name = "PUG Overlay", 
    author = "The Doggy", 
    description = "Displays overlay to all players on match end", 
    version = "0.0.1",
    url = "coldcommunity.com"
};

public void OnPluginStart()
{
	HookEvent("cs_win_panel_match", Event_MatchEnd);
}

public void OnMapStart()
{
	AddFileToDownloadsTableEx("materials/%s", MATERIAL_PATH);
	AddFileToDownloadsTableEx("materials/%s", TEXTURE_PATH);
}

public void Event_MatchEnd(Event event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i)) ShowOverlay(i, MATERIAL_PATH, OVERLAY_TIME);
}

/*
----------------------------------
			STOCKS
----------------------------------
*/
stock void ShowOverlay(int client, const char[] overlay, float duration = 0.0)
{
	if(!IsValidClient(client)) return;

	int iFlags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", iFlags & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", iFlags);

	if (duration > 0.0)
		CreateTimer(duration, __Timer_ResetOverlay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	else
		KickClient(client, "Thanks for playing!");
}

public Action __Timer_ResetOverlay(Handle timer, any data)
{
	ShowOverlay(GetClientOfUserId(data), "0", 0.0);
}

stock bool AddFileToDownloadsTableEx(const char[] format, any ...)
{
	if (strlen(format) == 0)
		return false;

	char sBuffer[PLATFORM_MAX_PATH];
	VFormat(sBuffer, sizeof(sBuffer), format, 2);

	AddFileToDownloadsTable(sBuffer);
	return true;
}

stock bool IsValidClient(int client) 
{ 
    if (client >= 1 &&  
    client <= MaxClients &&  
    IsClientInGame(client) && 
    !IsFakeClient(client)) 
        return true; 
    return false; 
}  