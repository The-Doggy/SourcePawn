#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

bool g_MenuOpen[MAXPLAYERS + 1];
bool g_DisableSwitch[MAXPLAYERS + 1];
int g_iKnife[MAXPLAYERS + 1];
int g_iWeapon[MAXPLAYERS + 1];
int g_iPistol[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "SwitchKnifes",
	author = "Pyro (Edited by The Doggy)",
	version = "0.26",
	description = "Switch your weapons with another player!"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_switchknife", Command_SwitchKnife, "Send a request to the specified player to switch your knives.");
	RegConsoleCmd("sm_sk", Command_SwitchKnife, "Send a request to the specified player to switch your knives.");
	RegConsoleCmd("sm_switchweapon", Command_SwitchWeapon, "Send a request to the specified player to switch your primary weapons.");
	RegConsoleCmd("sm_sw", Command_SwitchWeapon, "Send a request to the specified player to switch your primary weapons.");
	RegConsoleCmd("sm_switchpistol", Command_SwitchPistol, "Send a request to the specified player to switch your pistols.");
	RegConsoleCmd("sm_sp", Command_SwitchPistol, "Send a request to the specified player to switch your pistols.");
	RegConsoleCmd("sm_disablesk", Command_DisableSwitch, "Disable the requests!");

	LoadTranslations("common.phrases");
}

public void OnClientPutInServer(int client)
{
	g_DisableSwitch[client] = false;
	g_MenuOpen[client] = false;
}

public Action Command_DisableSwitch(int client, int args)
{
	g_DisableSwitch[client] = !g_DisableSwitch[client];
	if(g_DisableSwitch[client])
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] You have \x0Fdisabled\x01 switching!");
	}
	else
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] You have \x06enabled\x01 switching!");
	}
	return Plugin_Handled;
}

public Action Command_SwitchKnife(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] Usage: sm_switchknife <player>");
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));

	int target = FindTarget(client, arg, false, false);
	if (target == -1)
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07Can't find player!");
		return Plugin_Handled;
	}
	else if(target == client)
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07You can't swap knives with yourself!");
		return Plugin_Handled;
	}
	else if(g_DisableSwitch[target])
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07That person has disabled switching!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(target))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07That player is dead!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07You are dead!");
		return Plugin_Handled;
	}
	else if(g_MenuOpen[target])
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07That player already has an open offer!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(client, 2))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07You don't have a knife to switch!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(target, 2))
	{
		PrintToChat(client, "[\x0ESwitchKnife\x01] \x07They don't have a knife to switch!");
		return Plugin_Handled;
	}

	PrintToChat(client, "[\x0ESwitchKnife\x01] Request to switch knives sent to: \x09%N", target);

	DisplayConfirmation(target, client);

	return Plugin_Handled;
}

void DisplayConfirmation(int client, int sender)
{
	Handle menu = CreateMenu(ConfirmationHandler);

	char senderYes[255];
	Format(senderYes, sizeof(senderYes), "yes%d", sender);
	char senderNo[255];
	Format(senderNo, sizeof(senderNo), "no%d", sender);

	SetMenuTitle(menu, "Would you like to switch knives with %N", sender);
	AddMenuItem(menu, senderYes, "Yes");
	AddMenuItem(menu, senderNo, "No");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 10);
}

public int ConfirmationHandler(Handle menu, MenuAction action, int param1, int param2)
{
	//Weird bug caused param1 to be negative
	if(param1 < 0) param1 *= (-1);
	if(action == MenuAction_Start)
	{
		g_MenuOpen[param1] = true;
	}
	else if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		int sender;
		if(info[0] == 'y' && info[1] == 'e' && info[2] == 's')
		{
			strcopy(info, sizeof(info), info[3]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchKnife\x01] \x09%N\x01 \x06accepted\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchKnife\x01] You \x06accepted\x01 \x09%N\x01's request.", sender);
			SwitchPlayerKnives(param1, sender);
		}
		else
		{
			strcopy(info, sizeof(info), info[2]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchKnife\x01] \x09%N\x01 \x0Fdeclined\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchKnife\x01] You \x0Fdeclined\x01 \x09%N\x01's request.", sender);
		}
	}
	else if(action == MenuAction_End)
	{
		g_MenuOpen[param1] = false;
		CloseHandle(menu);
		return 0;
	}
	return 1;
}

void SwitchPlayerKnives(int player1, int player2)
{
	if(!IsPlayerAlive(player1))
	{
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: You are dead!");
		return;
	}
	else if(!IsPlayerAlive(player2))
	{
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: You are dead!");
		return;
	}

	int knife1 = GetPlayerWeaponSlot(player1, 2);
	int knife2 = GetPlayerWeaponSlot(player2, 2);

	if(knife1 == -1)
	{
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: You don't have a knife to switch!");
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: They don't have a knife to switch!");
		return;
	}
	else if(knife2 == -1)
	{
		PrintToChat(player2, "[\x0ESwitchKnife\x01]\x07 Cancelled: You don't have a knife to switch!");
		PrintToChat(player1, "[\x0ESwitchKnife\x01]\x07 Cancelled: They don't have a knife to switch!");
		return;
	}

	CS_DropWeapon(player1, knife1, false, true);
	CS_DropWeapon(player2, knife2, false, true);

	g_iKnife[player1] = knife2;
	g_iKnife[player2] = knife1;

	CreateTimer(0.1, EquipKnife, player1);
	CreateTimer(0.1, EquipKnife, player2);
}

public Action EquipKnife(Handle timer, any client)
{
	if(IsPlayerAlive(client))
	{
		EquipPlayerWeapon(client, g_iKnife[client]);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", g_iKnife[client]);
	}
}

public Action Command_SwitchWeapon(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] Usage: sm_switchweapon <player>");
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));

	int target = FindTarget(client, arg, false, false);
	if (target == -1)
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07Can't find player!");
		return Plugin_Handled;
	}
	else if(target == client)
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07You can't swap weapons with yourself!");
		return Plugin_Handled;
	}
	else if(g_DisableSwitch[target])
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07That person has disabled switching!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(target))
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07That player is dead!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07You are dead!");
		return Plugin_Handled;
	}
	else if(g_MenuOpen[target])
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07That player already has an open offer!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(client, 0))
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07You don't have a weapon to switch!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(target, 0))
	{
		PrintToChat(client, "[\x0ESwitchWeapon\x01] \x07They don't have a weapon to switch!");
		return Plugin_Handled;
	}

	PrintToChat(client, "[\x0ESwitchWeapon\x01] Request to switch weapons sent to: \x09%N", target);

	DisplayConfirmationWeapon(target, client);

	return Plugin_Handled;
}

void DisplayConfirmationWeapon(int client, int sender)
{
	Handle menu = CreateMenu(ConfirmationHandlerWeapon);

	char senderYes[255];
	Format(senderYes, sizeof(senderYes), "yes%d", sender);
	char senderNo[255];
	Format(senderNo, sizeof(senderNo), "no%d", sender);

	SetMenuTitle(menu, "Would you like to switch weapons with %N", sender);
	AddMenuItem(menu, senderYes, "Yes");
	AddMenuItem(menu, senderNo, "No");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 10);
}

public int ConfirmationHandlerWeapon(Handle menu, MenuAction action, int param1, int param2)
{
	//Weird bug caused param1 to be negative
	if(param1 < 0) param1 *= (-1);
	if(action == MenuAction_Start)
	{
		g_MenuOpen[param1] = true;
	}
	else if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		int sender;
		if(info[0] == 'y' && info[1] == 'e' && info[2] == 's')
		{
			strcopy(info, sizeof(info), info[3]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchWeapon\x01] \x09%N\x01 \x06accepted\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchWeapon\x01] You \x06accepted\x01 \x09%N\x01's request.", sender);
			SwitchPlayerWeapons(param1, sender);
		}
		else
		{
			strcopy(info, sizeof(info), info[2]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchWeapon\x01] \x09%N\x01 \x0Fdeclined\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchWeapon\x01] You \x0Fdeclined\x01 \x09%N\x01's request.", sender);
		}
	}
	else if(action == MenuAction_End)
	{
		g_MenuOpen[param1] = false;
		CloseHandle(menu);
		return 0;
	}
	return 1;
}

void SwitchPlayerWeapons(int player1, int player2)
{
	if(!IsPlayerAlive(player1))
	{
		PrintToChat(player2, "[\x0ESwitchWeapon\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player1, "[\x0ESwitchWeapon\x01]\x07 Cancelled: You are dead!");
		return;
	}
	else if(!IsPlayerAlive(player2))
	{
		PrintToChat(player1, "[\x0ESwitchWeapon\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player2, "[\x0ESwitchWeapon\x01]\x07 Cancelled: You are dead!");
		return;
	}

	int weapon1 = GetPlayerWeaponSlot(player1, 0);
	int weapon2 = GetPlayerWeaponSlot(player2, 0);

	if(weapon1 == -1)
	{
		PrintToChat(player1, "[\x0ESwitchWeapon\x01]\x07 Cancelled: You don't have a weapon to switch!");
		PrintToChat(player2, "[\x0ESwitchWeapon\x01]\x07 Cancelled: They don't have a weapon to switch!");
		return;
	}
	else if(weapon2 == -1)
	{
		PrintToChat(player2, "[\x0ESwitchWeapon\x01]\x07 Cancelled: You don't have a weapon to switch!");
		PrintToChat(player1, "[\x0ESwitchWeapon\x01]\x07 Cancelled: They don't have a weapon to switch!");
		return;
	}

	CS_DropWeapon(player1, weapon1, false, true);
	CS_DropWeapon(player2, weapon2, false, true);

	g_iWeapon[player1] = weapon2;
	g_iWeapon[player2] = weapon1;

	CreateTimer(0.1, EquipWeapon, player1);
	CreateTimer(0.1, EquipWeapon, player2);
}

public Action EquipWeapon(Handle timer, any client)
{
	if(IsPlayerAlive(client))
	{
		EquipPlayerWeapon(client, g_iWeapon[client]);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", g_iWeapon[client]);
	}
}

public Action Command_SwitchPistol(int client, int args)
{
	if(args < 1)
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] Usage: sm_switchpistol <player>");
		return Plugin_Handled;
	}
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));

	int target = FindTarget(client, arg, false, false);
	if (target == -1)
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07Can't find player!");
		return Plugin_Handled;
	}
	else if(target == client)
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07You can't swap pistols with yourself!");
		return Plugin_Handled;
	}
	else if(g_DisableSwitch[target])
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07That person has disabled switching!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(target))
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07That player is dead!");
		return Plugin_Handled;
	}
	else if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07You are dead!");
		return Plugin_Handled;
	}
	else if(g_MenuOpen[target])
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07That player already has an open offer!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(client, 2))
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07You don't have a pistol to switch!");
		return Plugin_Handled;
	}
	else if(!GetPlayerWeaponSlot(target, 2))
	{
		PrintToChat(client, "[\x0ESwitchPistol\x01] \x07They don't have a pistol to switch!");
		return Plugin_Handled;
	}

	PrintToChat(client, "[\x0ESwitchPistol\x01] Request to switch pistols sent to: \x09%N", target);

	DisplayConfirmationPistol(target, client);

	return Plugin_Handled;
}

void DisplayConfirmationPistol(int client, int sender)
{
	Handle menu = CreateMenu(ConfirmationHandlerPistol);

	char senderYes[255];
	Format(senderYes, sizeof(senderYes), "yes%d", sender);
	char senderNo[255];
	Format(senderNo, sizeof(senderNo), "no%d", sender);

	SetMenuTitle(menu, "Would you like to switch pistols with %N", sender);
	AddMenuItem(menu, senderYes, "Yes");
	AddMenuItem(menu, senderNo, "No");
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 10);
}

public int ConfirmationHandlerPistol(Handle menu, MenuAction action, int param1, int param2)
{
	//Weird bug caused param1 to be negative
	if(param1 < 0) param1 *= (-1);
	if(action == MenuAction_Start)
	{
		g_MenuOpen[param1] = true;
	}
	else if(action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		int sender;
		if(info[0] == 'y' && info[1] == 'e' && info[2] == 's')
		{
			strcopy(info, sizeof(info), info[3]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchPistol\x01] \x09%N\x01 \x06accepted\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchPistol\x01] You \x06accepted\x01 \x09%N\x01's request.", sender);
			SwitchPlayerPistols(param1, sender);
		}
		else
		{
			strcopy(info, sizeof(info), info[2]);
			sender = StringToInt(info);
			PrintToChat(sender, "[\x0ESwitchPistol\x01] \x09%N\x01 \x0Fdeclined\x01 your request.", param1);
			PrintToChat(param1, "[\x0ESwitchPistol\x01] You \x0Fdeclined\x01 \x09%N\x01's request.", sender);
		}
	}
	else if(action == MenuAction_End)
	{
		g_MenuOpen[param1] = false;
		CloseHandle(menu);
		return 0;
	}
	return 1;
}

void SwitchPlayerPistols(int player1, int player2)
{
	if(!IsPlayerAlive(player1))
	{
		PrintToChat(player2, "[\x0ESwitchPistol\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player1, "[\x0ESwitchPistol\x01]\x07 Cancelled: You are dead!");
		return;
	}
	else if(!IsPlayerAlive(player2))
	{
		PrintToChat(player1, "[\x0ESwitchPistol\x01]\x07 Cancelled: That player is dead!");
		PrintToChat(player2, "[\x0ESwitchPistol\x01]\x07 Cancelled: You are dead!");
		return;
	}

	int pistol1 = GetPlayerWeaponSlot(player1, 1);
	int pistol2 = GetPlayerWeaponSlot(player2, 1);

	if(pistol1 == -1)
	{
		PrintToChat(player1, "[\x0ESwitchPistol\x01]\x07 Cancelled: You don't have a pistol to switch!");
		PrintToChat(player2, "[\x0ESwitchPistol\x01]\x07 Cancelled: They don't have a pistol to switch!");
		return;
	}
	else if(pistol2 == -1)
	{
		PrintToChat(player2, "[\x0ESwitchPistol\x01]\x07 Cancelled: You don't have a pistol to switch!");
		PrintToChat(player1, "[\x0ESwitchPistol\x01]\x07 Cancelled: They don't have a pistol to switch!");
		return;
	}

	CS_DropWeapon(player1, pistol1, false, true);
	CS_DropWeapon(player2, pistol2, false, true);

	g_iPistol[player1] = pistol2;
	g_iPistol[player2] = pistol1;

	CreateTimer(0.1, EquipPistol, player1);
	CreateTimer(0.1, EquipPistol, player2);
}

public Action EquipPistol(Handle timer, any client)
{
	if(IsPlayerAlive(client))
	{
		EquipPlayerWeapon(client, g_iPistol[client]);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", g_iPistol[client]);
	}
}