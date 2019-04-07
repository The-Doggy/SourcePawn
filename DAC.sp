#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

//Plugin Information:
public Plugin myinfo = 
{
	name = "DAC (Dog Anti-Cheat)", 
	author = "The Doggy", 
	description = "Dog Anti-Cheat", 
	version = "0.1",
	url = "coldcommunity.com"
};

float g_fLastMenuSelectTime[MAXPLAYERS + 1] = 0.0;
Database g_Database = null;

public void OnPluginStart()
{
	AddCommandListener(MenuSelectListener, "sm_vmenuselect");

	char sFolder[32];
	GetGameFolderName(sFolder, sizeof(sFolder));
	if(SQL_CheckConfig("DAC_Logging"))
		Database.Connect(SQL_Initialize, "DAC_Logging");
	else
		PrintToServer("[DAC] Database config could not be found in: %s/addons/sourcemod/configs/databases.cfg", sFolder);
}

public void SQL_Initialize(Database db, const char[] sError, int data)
{
	if (db == null)
	{
		PrintToServer("[DAC] Database Error: %s", sError);
		return;
	}
	
	char sDriver[16];
	db.Driver.GetIdentifier(sDriver, sizeof(sDriver));
	if (StrEqual(sDriver, "mysql", false)) LogMessage("[DAC] MySQL Database: connected");

	g_Database = db;
	CreateDatabaseTables();
}

void CreateDatabaseTables()
{
	CreateLoggingTable();
}

void CreateLoggingTable()
{
	char sQuery[2048];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS DAC_Logging( username VARCHAR(64) NOT NULL, time FLOAT(3, 2) NOT NULL, steamid VARCHAR(64) NOT NULL );");
	g_Database.Query(SQL_GenericQuery, sQuery);
	PrintToServer("[DAC] Created/Verified Logging Table.");
}

public void SQL_GenericQuery(Database db, DBResultSet results, const char[] sError, any data)
{
	if (db == null || results == null)
	{
		LogError("[DAC] SQL_GenericQuery: Query failed! %s", sError);
		return;
	}
}

public void OnClientDisconnect(int client)
{
	g_fLastMenuSelectTime[client] = 0.0;
}

public Action MenuSelectListener(int client, const char[] command, int argc)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;

	float selectTime = GetGameTime() - g_fLastMenuSelectTime[client];

	//Was the last menu select less than a tenth of a second ago?
	if(selectTime <= 0.1)
	{
		//Print warning to any admins online
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				if(GetAdminFlag(GetUserAdmin(i), Admin_Generic, Access_Effective))
					PrintToChat(i, "[DAC] %N is suspected of using a menu bind.", client);
			}
		}
	}

	//Logging all menu selects that are less than a second apart from each other
	if(selectTime <= 1.0)
	{
		//Get user info
		char username[64], steamid[64];
		GetClientName(client, username, sizeof(username));
		ReplaceString(username, sizeof(username), "'", "''");
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

		//Format and execute query
		char sQuery[255];
		Format(sQuery, sizeof(sQuery), "INSERT INTO DAC_Logging VALUES ('%s', %f, '%s');", username, selectTime, steamid);
		g_Database.Query(SQL_GenericQuery, sQuery);
	}


	//Set last menu time to the current game time
	g_fLastMenuSelectTime[client] = GetGameTime();
	return Plugin_Handled;
}