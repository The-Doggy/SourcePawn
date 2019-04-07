#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public void OnClientPostAdminCheck(int Client)
{
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int Client)
{
	SDKUnhook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int iVictim, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType)
{
	if (iAttacker == 0 || iAttacker > MaxClients)
		return Plugin_Continue;

	PrintToServer("%i", iDamageType);
	return Plugin_Continue;
}