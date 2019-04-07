#include <sourcemod>
#include <pugsetup>
#include <sourcebanspp>

#pragma semicolon 1
#pragma newdecls required

ConVar g_hCVBanTime;
ConVar g_hCVBanReason;
ConVar g_hCVDisconnectWindow;
ConVar g_hCVMinPlayers;

bool g_bSourcebans = false;
bool g_bPugSetup = false;

Database g_Database = null;

public Plugin myinfo = 
{
    name = "Disconnect Ban", 
    author = "The Doggy", 
    description = "Bans players who disconnect during a match", 
    version = "1.2.0",
    url = "DistrictNine.Host"
};

public void OnPluginStart()
{
    g_hCVBanTime = CreateConVar("sm_disconnectban_time", "0", "Amount of time to ban a player who disconnects during a match");
    g_hCVBanReason = CreateConVar("sm_disconnectban_reason", "Disconnected from match", "Reason to tell user why they were banned.");
    g_hCVDisconnectWindow = CreateConVar("sm_disconnectban_window", "5", "Amount of time a player has to reconnect before they are banned.");
    g_hCVMinPlayers = CreateConVar("sm_disconnectban_minplayers", "3", "Min amount of players to force end the current pug.");

    CreateTimer(1.0, AttemptMySQLConnection);
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
    if (SQL_CheckConfig("disconnectban"))
    {
        PrintToServer("Initalizing Connection to MySQL Database");
        Database.Connect(SQL_InitialConnection, "disconnectban");
    }
    else
        LogError("Database Error: No Database Config Found! (%s/addons/sourcemod/configs/databases.cfg)", sFolder);

    return Plugin_Handled;
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
    CreateTimer(1.0, UpdateBanStatus, _, TIMER_REPEAT);
}

public void CreateAndVerifySQLTables()
{
    char sQuery[1024] = "";
    StrCat(sQuery, 1024, "CREATE TABLE IF NOT EXISTS dc_ban (");
    StrCat(sQuery, 1024, "steamid VARCHAR(64) NOT NULL, ");
    StrCat(sQuery, 1024, "name VARCHAR(64) NOT NULL, ");
    StrCat(sQuery, 1024, "ip VARCHAR(64) NOT NULL, ");
    StrCat(sQuery, 1024, "seconds INTEGER NOT NULL, ");
    StrCat(sQuery, 1024, "PRIMARY KEY(steamid));");
    g_Database.Query(SQL_GenericQuery, sQuery);
}

public Action UpdateBanStatus(Handle timer)
{
    if(!g_bSourcebans || !g_bPugSetup) return Plugin_Continue;

    if(g_Database == null) return Plugin_Continue;

    int iCount;
    for(int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i) && PugSetup_IsMatchLive() && PugSetup_PlayerAtStart(i)) iCount++;

    if(iCount <= g_hCVMinPlayers.IntValue && PugSetup_IsMatchLive()) ServerCommand("sm_forceend");

    char sQuery[1024] = "UPDATE dc_ban SET seconds=seconds+1;";
    g_Database.Query(SQL_UpdateQuery, sQuery);
    return Plugin_Continue;
}

public void SQL_UpdateQuery(Database db, DBResultSet results, const char[] sError, any data)
{
    if(results == null)
    {
        PrintToServer("MySQL Query Failed: %s", sError);
        LogError("MySQL Query Failed: %s", sError);
        return;
    }

    char sQuery[1024];
    Format(sQuery, sizeof(sQuery), "SELECT * FROM dc_ban WHERE seconds >= %i;", g_hCVDisconnectWindow.IntValue * 60);
    g_Database.Query(SQL_SelectSeconds, sQuery);
}

public void SQL_SelectSeconds(Database db, DBResultSet results, const char[] sError, any data)
{
    if(results == null)
    {
        PrintToServer("MySQL Query Failed: %s", sError);
        LogError("MySQL Query Failed: %s", sError);
        return;
    }

    if(!results.FetchRow()) return;

    int secCol, steamCol, nameCol, ipCol;
    char sSteam[64], sName[64], sIp[64];
    results.FieldNameToNum("seconds", secCol);
    results.FieldNameToNum("steamid", steamCol);
    results.FieldNameToNum("name", nameCol);
    results.FieldNameToNum("ip", ipCol);

    int seconds = results.FetchInt(secCol);
    results.FetchString(steamCol, sSteam, sizeof(sSteam));
    results.FetchString(nameCol, sName, sizeof(sName));
    results.FetchString(ipCol, sIp, sizeof(sIp));

    if(RoundFloat(seconds / 60.0) >= g_hCVDisconnectWindow.IntValue)
    {
        char sReason[128];
        g_hCVBanReason.GetString(sReason, sizeof(sReason));

        int Client = -1;
        for(int i = 1; i <= MaxClients; i++)
        {
            if(!IsValidClient(i)) continue;
            char steam[64];
            GetClientAuthId(i, AuthId_Steam2, steam, sizeof(steam));
            if(StrEqual(steam, sSteam, false))
            {
                Client = i;
                break;
            }
        }
        if(Client != -1)
            SBPP_BanPlayer(0, Client, g_hCVBanTime.IntValue, sReason);
        else
        {
            SBPP_BanPlayer(0, 0, g_hCVBanTime.IntValue, sReason, sSteam, sName, sIp);
        }
    }

    char sQuery[1024];
    Format(sQuery, sizeof(sQuery), "DELETE FROM dc_ban WHERE steamid='%s';", sSteam);
    g_Database.Query(SQL_GenericQuery, sQuery);
}

public void OnClientAuthorized(int Client, const char[] auth)
{
    char sQuery[1024];
    Format(sQuery, sizeof(sQuery), "DELETE FROM dc_ban WHERE steamid='%s';", auth);
    g_Database.Query(SQL_GenericQuery, sQuery);
}

public void OnAllPluginsLoaded()
{
    if(LibraryExists("sourcebans++"))
        g_bSourcebans = true;
    else
        LogError("Sourcebans++ is not loaded, this plugin will not work without it.");

    if(LibraryExists("pugsetup"))
        g_bPugSetup = true;
    else
        LogError("PugSetup is not loaded, this plugin will not work without it.");
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "sourcebans++"))
        g_bSourcebans = true;
    if(StrEqual(name, "pugsetup"))
        g_bPugSetup = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if(StrEqual(name, "sourcebans++"))
    {
        g_bSourcebans = false;
        LogError("Sourcebans++ has been unloaded, this plugin will not work without it.");
    }
    if(StrEqual(name, "pugsetup"))
    {
        g_bPugSetup = false;
        LogError("PugSetup has been unloaded, this plugin will not work without it.");
    }
}

public void OnClientDisconnect(int Client)
{
    if(!g_bSourcebans || !g_bPugSetup) return;

    if(!CheckCommandAccess(Client, "sm_disconnectban_immune", ADMFLAG_GENERIC) && PugSetup_IsMatchLive() && PugSetup_PlayerAtStart(Client))
    {
        char sQuery[2048], sSteam[64], sName[64], sEscapedName[64], sIp[64];
        GetClientAuthId(Client, AuthId_Steam2, sSteam, sizeof(sSteam));
        GetClientName(Client, sName, sizeof(sName));
        g_Database.Escape(sName, sEscapedName, sizeof(sEscapedName));
        GetClientIP(Client, sIp, sizeof(sIp));
        Format(sQuery, sizeof(sQuery), "INSERT INTO dc_ban (steamid, name, ip, seconds) VALUES ('%s', '%s', '%s', 0);", sSteam, sName, sIp);
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
    !IsFakeClient(client);
}