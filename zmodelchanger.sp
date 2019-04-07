#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart()
{
	RegConsoleCmd("sm_cm", PlayerCommand_VIPModels, "ya");
}

public Action PlayerCommand_VIPModels(int Client, int iArgs)
{	
	if (Client == 0 || !IsValidClient(Client))
	{
		PrintToConsole(Client, "[SM] This command can only be run in game");
		return Plugin_Handled;
	}
	
	Menu menu = CreateMenu(HandleModel);
	menu.AddItem("1", "1");
	menu.AddItem("2", "2");
	menu.AddItem("3", "3");
	menu.AddItem("4", "4");
	menu.AddItem("5", "5");
	menu.AddItem("6", "6");
	menu.AddItem("7", "7");
	menu.AddItem("8", "8");
	menu.AddItem("9", "9");
	menu.AddItem("10", "10");
	menu.AddItem("11", "11");
	menu.AddItem("12", "12");
	menu.AddItem("13", "13");
	menu.AddItem("14", "14");
	menu.AddItem("15", "15");
	menu.AddItem("16", "16");
	menu.AddItem("17", "17");
	menu.AddItem("18", "18");
	menu.AddItem("19", "19");
	menu.AddItem("20", "20");
	menu.AddItem("21", "21");
	menu.AddItem("22", "22");
	menu.AddItem("23", "23");
	menu.SetTitle("VIP Model Menu");
	menu.ExitButton = true;
	menu.Pagination = 7;
	menu.Display(Client, 30);
	return Plugin_Handled;
}

int HandleModel(Menu hModels, MenuAction action, int Client, int selection)
{
	char Buffer[64], model[128];
	GetMenuItem(hModels, selection, Buffer, sizeof(Buffer));
	
	if(!IsValidClient(Client)) return 0;
	
	if (action == MenuAction_Select)
	{
		if (StrEqual(Buffer, "1", false))
			model = "models/humans/group02/player/tale_01.mdl";
		else if (StrEqual(Buffer, "2", false))
			model = "models/humans/group02/player/tale_03.mdl";
		else if (StrEqual(Buffer, "3", false))
			model = "models/humans/group02/player/tale_04.mdl";
		else if (StrEqual(Buffer, "4", false))
			model = "models/humans/group02/player/tale_05.mdl";
		else if (StrEqual(Buffer, "5", false))
			model = "models/humans/group02/player/tale_06.mdl";
		else if (StrEqual(Buffer, "6", false))
			model = "models/humans/group02/player/tale_07.mdl";
		else if (StrEqual(Buffer, "7", false))
			model = "models/humans/group02/player/tale_08.mdl";
		else if (StrEqual(Buffer, "8", false))
			model = "models/humans/group02/player/tale_09.mdl";
		else if (StrEqual(Buffer, "9", false))
			model = "models/humans/group02/player/temale_01.mdl";
		else if (StrEqual(Buffer, "10", false))
			model = "models/humans/group02/player/temale_02.mdl";
		else if (StrEqual(Buffer, "11", false))
			model = "models/humans/group02/player/temale_07.mdl";
		else if (StrEqual(Buffer, "12", false))
			model = "models/humans/nypd1940/male_01.mdl";
		else if (StrEqual(Buffer, "13", false))
			model = "models/humans/nypd1940/male_02.mdl";
		else if (StrEqual(Buffer, "14", false))
			model = "models/humans/nypd1940/male_03.mdl";
		else if (StrEqual(Buffer, "15", false))
			model = "models/humans/nypd1940/male_04.mdl";
		else if (StrEqual(Buffer, "16", false))
			model = "models/humans/nypd1940/male_05.mdl";
		else if (StrEqual(Buffer, "17", false))
			model = "models/humans/nypd1940/male_06.mdl";
		else if (StrEqual(Buffer, "18", false))
			model = "models/humans/nypd1940/male_07.mdl";
		else if (StrEqual(Buffer, "19", false))
			model = "models/humans/nypd1940/male_08.mdl";
		else if (StrEqual(Buffer, "20", false))
			model = "models/humans/nypd1940/male_09.mdl";
		else if (StrEqual(Buffer, "21", false))
			model = "models/miku_g.mdl";
		else if (StrEqual(Buffer, "22", false))
			model = "models/captainbigbutt/vocaloid/npc/kuro_miku_append.mdl";
		else if (StrEqual(Buffer, "23", false))
			model = "models/player/tda_neru/kz_megumin.mdl";
		else
		{
			delete hModels;
			return 0;
		}

		if(!IsModelPrecached(model))
			PrecacheModel(model);

		SetEntityModel(Client, model);
	}
	else if (action == MenuAction_End)
	{
		delete hModels;
		return 0;
	}
	return 1;
}

stock bool IsValidClient(int client)
{
	return client >= 1 &&
	client <= MaxClients &&
	IsClientConnected(client) &&
	IsClientAuthorized(client) &&
	IsClientInGame(client);
}