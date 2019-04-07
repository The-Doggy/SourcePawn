#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGINVERSION	"1.0"

//Plugin Information:
public Plugin myinfo = 
{
	name = "Play Sound When Knifed", 
	author = "The Doggy", 
	description = "Plays defined sound when a player is knifed", 
	version = PLUGINVERSION,
	url = "coldcommunity.com"
};

ConVar g_hCV_KnifedSound;

char g_sSoundFile[128];

public void OnPluginStart()
{
	HookEvent("player_death", Event_Playerdeath);
	g_hCV_KnifedSound = CreateConVar("dg_knifed_sound", "ui/deathmatch_kill_bonus.wav", "The sound to play when a player is knifed. Default: ui/deathmatch_kill_bonus.wav NOTE: Sound is relative to sound/ directory.");
	AutoExecConfig(true, "knifesound");
}

public void OnMapStart()
{
	char soundPath[128];
	g_hCV_KnifedSound.GetString(g_sSoundFile, sizeof(g_sSoundFile));
	Format(soundPath, sizeof(soundPath), "sound/%s", g_sSoundFile);
	if(!FileExists(soundPath, true))
	{
		LogError("Error loading knife soundfile %s (File does not exist)", soundPath);
		return;
	}

	AddFileToDownloadsTable(soundPath);
	if(!IsSoundPrecached(g_sSoundFile))
		PrecacheSound(g_sSoundFile, true);
}

public void Event_Playerdeath(Event event, const char[] name, bool dontBroadcast)
{
	char weapon[64];
	int victim = event.GetInt("userid");
	int attacker = event.GetInt("attacker");
	event.GetString("weapon", weapon, sizeof(weapon));

	if(IsValidClient(victim) && IsValidClient(attacker) && victim != attacker && StrEqual(weapon, "knife") || StrEqual(weapon, "knife_t"))
	{
		EmitSoundToAll(g_sSoundFile, victim, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
		PrintToChatAll("SOUND PLAYING");
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