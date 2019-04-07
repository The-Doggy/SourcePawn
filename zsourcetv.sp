#include <sourcemod>
#include <sourcetvmanager>

#define PLUGIN_VERSION		"0.1"

//Plugin Information:
public Plugin myinfo = 
{
	name = "SourceTV Manager", 
	author = "The Doggy", 
	description = "Allows administrators to record demos through SourceTV", 
	version = PLUGIN_VERSION,
	url = "coldcommunity.com"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_record", Command_StartRecording, ADMFLAG_GENERIC, "[SM] Starts recording a demo of specified player(s).");
	RegAdminCmd("sm_stop", Command_StopRecording, ADMFLAG_GENERIC, "[SM] Stops recording the current demo.");
}

public Action Command_StartRecording(int Client, int iArgs)
{
	//add arg checking later

	char sFilename[128]; //add functionality for adding custom specififed name after date string later
	FormatTime(sFilename, sizeof(sFilename), "%F-%H-%M-%S", GetTime());

	if(SourceTV_StartRecording(sFilename)) PrintToChatAll("Recording Successful.");
	else PrintToChatAll("Recording Failed.");

	return Plugin_Handled;
}

public Action Command_StopRecording(int Client, int iArgs)
{
	//add valid/recording checks later

	if(SourceTV_StopRecording()) PrintToChatAll("Recording Stopped Successfully.");
	else PrintToChatAll("Stopping Recording Failed.");
	return Plugin_Handled;
}