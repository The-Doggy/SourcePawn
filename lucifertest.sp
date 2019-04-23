#include <sourcemod>
#include <sdktools>

// Easier than writing "[SM]" every time we want to print something
#define CMDTAG "[SM]"

// Self-explanatory
public Plugin myinfo =
{
	name = "Change Model Skins",
	author = "The Doggy",
	description = "Allows skins of models to be changed without the need of ent_fire.",
	version = "0.0.1",
	url = "http://coldcommunity.com"
};

// The forward that gets called as soon as SM loads the plugin
public void OnPluginStart()
{
	// Registers the command with SM and creates a callback to Command_Skin
	RegConsoleCmd("sm_skin", Command_Skin, "Changes the skin of a model."); 
}

public Action Command_Skin(int Client, int iArgs)
{
	// Making sure the client running the command is valid
	if(Client == 0 || Client > MaxClients || !IsClientConnected(Client))
	{
		// The %s is a format specifier, they can be learnt more about here: https://wiki.alliedmods.net/Format_Class_Functions_(SourceMod_Scripting)
		PrintToServer("%s This command can only be run ingame.", CMDTAG);

		// Stops execution of the command and lets SM know that the command has finished running
		return Plugin_Handled; 
	}

	// Making sure the client only gave one argument to the command
	if(iArgs != 1)  
	{
		PrintToChat(Client, "%s Invalid Syntax: sm_skin <index of skin (0-32)>.", CMDTAG);
		return Plugin_Handled;
	}

	// Creates a char variable with a size of 32
	char sArg[32];

	// Gets the 1st/only argument the player gave to the command and stores it inside of sArg. (sizeof(sArg) is basically the same as saying 32 since the max size of the char we created is 32)
	GetCmdArg(1, sArg, sizeof(sArg));

	// Since the value we want is an integer we need to convert the char above into an integer. Also iArg has nothing to do with iArgs, just my dumb naming conventions :p
	int iArg = StringToInt(sArg);

	// Making sure the skin we're setting is not invalid. (0 is minimum, 32 is maximum)
	if(iArg < 0 || iArg > 32)
	{
		PrintToChat(Client, "%s Invalid Syntax: sm_skin <index of skin (0-32)>.", CMDTAG);
		return Plugin_Handled;
	}

	/* Not using this stuff anymore

	int entity;
	float fOrigin[3];
	float fAngles[3];
	GetClientEyeAngles(Client, fAngles);
	GetClientEyePosition(Client, fOrigin);
	fOrigin[2] -= 20.0;

	TR_TraceRay(fOrigin, fAngles, MASK_SHOT, RayType_Infinite);

	if(TR_DidHit())
	{
		entity = TR_GetEntityIndex();
		PrintToChat(Client, "TraceRay hit entity: %i", entity);
	}

	*/

	// Making sure the entity the client is aiming at is valid
	if(!IsValidEntity(GetClientAimTarget2(Client)))
	{
		PrintToChat(Client, "%s Invalid Entity", CMDTAG);
		return Plugin_Handled;
	}
	

	/* Now that we're finally done checking everything we can actually change the skin */

	// Gets the entity the client is aiming at
	int entity = GetClientAimTarget2(Client);

	// Sets an integer value in the global variant object. (You don't really need to worry about this at this point, just know that whatever is set in here will be applied to AcceptEntityInput() later on.)
	SetVariantInt(iArg);

	// This is what actually sets the skin on the model, it receives the integer value of the skin from SetVariantInt().
	AcceptEntityInput(entity, "skin");

	// Mainly for debugging purposes
	char className[64];
	GetEntityClassname(entity, className, sizeof(className));
	PrintToChat(Client, "%s Changed skin of %s to %i", CMDTAG, className, iArg);

	return Plugin_Handled;
}

// Stocks copied from BluRP since nothing else seemed to be working for getting entity indexes
public int GetClientAimTarget2(int Client)
{
	float eyeLoc[3], ang[3];
	GetClientEyePosition(Client, eyeLoc);
	GetClientEyeAngles(Client, ang);
	TR_TraceRayFilter(eyeLoc, ang, MASK_SOLID, RayType_Infinite, TRFilter_AimTarget, Client);
	int entity = TR_GetEntityIndex();
	
	if (entity > 0)
		return entity;
	else
		return -1;
}

public bool TRFilter_AimTarget(int entity, int mask, int Client)
{
	if (entity == Client)
		return false;
	return true;
}