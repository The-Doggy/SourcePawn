#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <pugsetup>

#pragma semicolon 1
#pragma newdecls required

Database g_Database = null;

public Plugin myinfo = 
{
	name = "SQL Matches", 
	author = "DN.H | The Doggy", 
	description = "Sends match stats for the current match to a database", 
	version = "1.0.0",
	url = "DistrictNine.Host"
};

public void OnPluginStart()
{
	CreateTimer(1.0, AttemptMySQLConnection);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

public Action AttemptMySQLConnection(Handle timer)
{
	if (g_Database != null)
	{
		delete g_Database;
		g_Database = null;
	}
	
	char sFolder[32];
	GetGameFolderName(sFolder, sizeof(sFolder));
	if (SQL_CheckConfig("sql_matches"))
	{
		PrintToServer("Initalizing Connection to MySQL Database");
		Database.Connect(SQL_InitialConnection, "sql_matches");
	}
	else
		LogError("Database Error: No Database Config Found! (%s/addons/sourcemod/configs/databases.cfg)", sFolder);
}

public void SQL_InitialConnection(Database db, const char[] sError, int data)
{
	if (db == null)
	{
		LogMessage("Database Error: %s", sError);
		CreateTimer(10.0, AttemptMySQLConnection);
		return;
	}
	
	char sDriver[16];
	db.Driver.GetIdentifier(sDriver, sizeof(sDriver));
	if (StrEqual(sDriver, "mysql", false)) LogMessage("MySQL Database: connected");
	
	g_Database = db;
	CreateAndVerifySQLTables();
}

public void CreateAndVerifySQLTables()
{
	char sQuery[1024] = "";
	StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS sql_matches_scoretotal (");
	StrCat(sQuery, 1024, "match_id INTEGER NOT NULL AUTO_INCREMENT, ");
	StrCat(sQuery, 1024, "timestamp timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, ");
	StrCat(sQuery, 1024, "team_t INTEGER NOT NULL, "); // Original plugin had 4 teams listed here but we only want CT/T so I'm just gonna stick with that
	StrCat(sQuery, 1024, "team_ct INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "map VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "PRIMARY KEY(match_id));");
	g_Database.Query(SQL_GenericQuery, sQuery);

	sQuery = "";
	StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS sql_matches (");
	StrCat(sQuery, 1024, "match_id INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "name VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "steamid64 VARCHAR(64) NOT NULL, ");
	StrCat(sQuery, 1024, "team INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "alive INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "ping INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "account INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "kills INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "assists INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "deaths INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "mvps INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "score INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "disconnected INTEGER NOT NULL, ");
	StrCat(sQuery, 1024, "PRIMARY KEY(match_id, steamid64), ");
	StrCat(sQuery, 1024, "FOREIGN KEY(match_id) REFERENCES sql_matches_scoretotal(match_id));");
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public void PugSetup_OnLive()
{
	char sQuery[1024], sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	Format(sQuery, sizeof(sQuery), "INSERT INTO sql_matches_scoretotal (team_t, team_ct, map) VALUES (%i, %i, '%s');", CS_GetTeamScore(CS_TEAM_T), CS_GetTeamScore(CS_TEAM_CT), sMap);
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	char sQuery[1024], sName[64], sSteamID[64];
	int iEnt, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore;

	iEnt = FindEntityByClassname(-1, "cs_player_manager");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i)) continue;

		iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeam", _, i);
		iAlive = GetEntProp(iEnt, Prop_Send, "m_bAlive", _, i);
		iPing = GetEntProp(iEnt, Prop_Send, "m_iPing", _, i);
		iAccount = GetEntProp(iEnt, Prop_Send, "m_iAccount", _, i);
		iKills = GetEntProp(iEnt, Prop_Send, "m_iKills", _, i);
		iAssists = GetEntProp(iEnt, Prop_Send, "m_iAssists", _, i);
		iDeaths = GetEntProp(iEnt, Prop_Send, "m_iDeaths", _, i);
		iMVPs = GetEntProp(iEnt, Prop_Send, "m_iMVPs", _, i);
		iScore = GetEntProp(iEnt, Prop_Send, "m_iScore", _, i);

		GetClientName(i, sName, sizeof(sName));
		g_Database.Escape(sName, sName, sizeof(sName));

		GetClientAuthId(i, AuthId_SteamID64, sSteamID, sizeof(sSteamID));

		int len = 0;
		len += Format(sQuery[len], sizeof(sQuery) - len, "INSERT INTO sql_matches (match_id, name, steamid64, team, alive, ping, account, kills, assists, deaths, mvps, score, disconnected) ");
		len += Format(sQuery[len], sizeof(sQuery) - len, "VALUES (LAST_INSERT_ID(), '%s', '%s', %i, %i, %i, %i, %i, %i, %i, %i, %i, 0) ", sName, sSteamID, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore);
		len += Format(sQuery[len], sizeof(sQuery) - len, "ON DUPLICATE KEY UPDATE name='%s', team=%i, alive=%i, ping=%i, account=%i, kills=%i, assists=%i, deaths=%i, mvps=%i, score=%i, disconnected=0;", sName, iTeam, iAlive, iPing, iAccount, iKills, iAssists, iDeaths, iMVPs, iScore);
		g_Database.Query(SQL_GenericQuery, sQuery);
	}
}

public void PugSetup_OnMatchOver(bool hasDemo, const char[] demoFileName)
{
	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "UPDATE sql_matches_scoretotal SET team_t=%i, team_ct=%i WHERE match_id=LAST_INSERT_ID();", CS_GetTeamScore(CS_TEAM_T), CS_GetTeamScore(CS_TEAM_CT));
	g_Database.Query(SQL_GenericQuery, sQuery);
}

public void OnClientDisconnect(int Client)
{
	if(IsValidClient(Client))
	{
		char sQuery[1024], sSteamID[64];
		GetClientAuthId(Client, AuthId_SteamID64, sSteamID, sizeof(sSteamID));
		Format(sQuery, sizeof(sQuery), "UPDATE sql_matches SET disconnected=1 WHERE match_id=LAST_INSERT_ID() AND steamid64='%s'", sSteamID);
		g_Database.Query(SQL_GenericQuery, sQuery);
	}
}

//generic query handler
public void SQL_GenericQuery(Database db, DBResultSet results, const char[] sError, any data)
{
	if(results == null)
	{
		PrintToServer("MySQL Query Failed: %s", sError);
		LogError("MySQL Query Failed: %s", sError);
	}
}

stock bool IsValidClient(int client)
{
	return client >= 1 && 
	client <= MaxClients && 
	IsClientConnected(client) && 
	IsClientAuthorized(client) && 
	IsClientInGame(client) &&
	!IsClientObserver(client) &&
	!IsFakeClient(client);
}