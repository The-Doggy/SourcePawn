#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	RegAdminCmd("sm_skin", Command_Skin, ADMFLAG_CUSTOM1, "skin");
}

public Action Command_Skin(int Client, int iArgs)
{
	char sArg[32];
	GetCmdArg(1, sArg, sizeof(sArg));
	int skin = StringToInt(sArg);
	int ent = GetClientAimTarget2(Client);
	SetEntProp(ent, Prop_Send, "m_nSkin", skin);
	return Plugin_Handled;
}

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