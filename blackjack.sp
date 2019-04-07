#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include <morecolors>
#include <bluerp>
#include <bluerp/BluRP>

//Plugin Information:
public Plugin myinfo = 
{
	name = "Blackjack", 
	author = "The Doggy", 
	description = "Allows players to have a game of blackjack", 
	version = "0.1",
	url = "coldcommunity.com"
};

enum GameStatus
{
	Status_None = 0,
	Status_Push,
	Blackjack_Push,
	Player_Win,
	Player_Bust,
	Player_Blackjack,
	Dealer_Win,
	Dealer_Bust,
	Dealer_Blackjack
}

char g_sSuits[4];
char g_sCards[13];

ArrayList g_PlayerHand[MAXPLAYERS + 1];
ArrayList g_DealerHand[MAXPLAYERS + 1];

int g_iBetAmount[MAXPLAYERS + 1];
int g_iRoundNumber[MAXPLAYERS + 1];
int g_iInsuranceBet[MAXPLAYERS + 1];

bool g_bIsInGame[MAXPLAYERS + 1];
bool g_bPlayerStand[MAXPLAYERS + 1];
bool g_bDealerStand[MAXPLAYERS + 1];
bool g_bInsuranceBet[MAXPLAYERS + 1];
bool g_bDoubleBet[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_blackjack", Command_StartBlackjack, "Starts a game of blackjack with the specified bet.");
	RegConsoleCmd("sm_bj", Command_StartBlackjack, "Starts a game of blackjack with the specified bet.");

	AddCommandListener(ChatHook, "say");
	AddCommandListener(ChatHook, "say_team");

	Format(g_sCards[0], sizeof(g_sCards), "2");
	Format(g_sCards[1], sizeof(g_sCards), "3");
	Format(g_sCards[2], sizeof(g_sCards), "4");
	Format(g_sCards[3], sizeof(g_sCards), "5");
	Format(g_sCards[4], sizeof(g_sCards), "6");
	Format(g_sCards[5], sizeof(g_sCards), "7");
	Format(g_sCards[6], sizeof(g_sCards), "8");
	Format(g_sCards[7], sizeof(g_sCards), "9");
	Format(g_sCards[8], sizeof(g_sCards), "10");
	Format(g_sCards[9], sizeof(g_sCards), "J");
	Format(g_sCards[10], sizeof(g_sCards), "Q");
	Format(g_sCards[11], sizeof(g_sCards), "K");
	Format(g_sCards[12], sizeof(g_sCards), "A");

	Format(g_sSuits[0], sizeof(g_sSuits), "S");
	Format(g_sSuits[1], sizeof(g_sSuits), "D");
	Format(g_sSuits[2], sizeof(g_sSuits), "H");
	Format(g_sSuits[3], sizeof(g_sSuits), "C");

	//initalize arraylists
	for(int i = 1; i <= MaxClients; i++)
	{
		g_PlayerHand[i] = new ArrayList();
		g_DealerHand[i] = new ArrayList();
	}
}

public void OnClientConnected(int Client)
{
	g_PlayerHand[Client] = new ArrayList();
	g_DealerHand[Client] = new ArrayList();
	if(g_PlayerHand[Client] == INVALID_HANDLE)
		PrintToServer("FUCKING CUNT");
}

public void OnPlayerDisconnect(int Client)
{
	//reset all player variables
	ResetVariables(Client);
}

void ResetVariables(int Client)
{
	g_PlayerHand[Client].Clear();
	g_DealerHand[Client].Clear();

	g_iBetAmount[Client] = 0;
	g_iRoundNumber[Client] = 0;
	g_iInsuranceBet[Client] = 0;

	g_bIsInGame[Client] = false;
	g_bPlayerStand[Client] = false;
	g_bDealerStand[Client] = false;
	g_bInsuranceBet[Client] = false;
	g_bDoubleBet[Client] = false;
}

public Action Command_StartBlackjack(int Client, int iArgs)
{
	//client checks
	if(Client == 0)
	{
		PrintToServer("This command can only be run in-game.");
		return Plugin_Handled;
	}

	BClient player = GetPlayerInstance(Client);
	if(!player.IsValid)
		return Plugin_Handled;

	if(g_bIsInGame[Client])
	{
		StartGame(Client);
		return Plugin_Handled;
	}

	//argument checks
	if(iArgs != 1)
	{
		player.Chat("%s Invalid Syntax. Usage: sm_blackjack <bet>", CMDTAG);
		return Plugin_Handled;
	}

	char sArg[16];
	GetCmdArg(1, sArg, sizeof(sArg));
	int bet = StringToInt(sArg);
	if(bet > 50000 || bet <= 0)
	{
		player.Chat("%s You can only bet between $1 - $50,000.", CMDTAG);
		return Plugin_Handled;
	}
	else if(player.Bank < bet)
	{
		player.Chat("%s You do not have enough money in your bank to place this bet.", CMDTAG);
		return Plugin_Handled;
	}
	player.Bank -= bet;
	g_iBetAmount[Client] = bet;
	g_bIsInGame[Client] = true;

	//deal cards to player and dealer
	if(g_PlayerHand[Client] == INVALID_HANDLE || g_DealerHand[Client] == INVALID_HANDLE)
		PrintToChatAll("FUCKING CUNT");

	DealCard(Client);
	DealCard(Client);
	DealCard(Client, true);
	DealCard(Client, true);

	StartGame(Client);
	return Plugin_Handled;
}

public void StartGame(int Client)
{
	BClient player = GetPlayerInstance(Client);
	if(!player.IsValid || !g_bIsInGame[Client])
		return;

	//get player cards
	char playerCards[32];
	for(int i = 0; i < g_PlayerHand[Client].Length; i++)
	{
		char currentCard[2];
		g_PlayerHand[Client].GetString(i, currentCard, sizeof(currentCard))

		Format(playerCards, sizeof(playerCards), "%s %s", playerCards, currentCard);
	}

	//get dealers faceup card
	char dealerCard[2];
	g_DealerHand[Client].GetString(0, dealerCard, sizeof(dealerCard));

	if(g_bPlayerStand[Client] && !g_bDealerStand[Client])
	{
		DealerAction(Client);
		return;
	}
	else if(g_bDealerStand[Client] && g_bPlayerStand[Client])
	{
		GameStatus status = CheckGameStatus(Client);
		if(status == Status_Push) player.Chat("%s Both players have %i, game ends in a push! You win %s from your bet.", CMDTAG, GetHandValue(g_PlayerHand[Client]), NumberFormat(g_iBetAmount[Client]));
		else if(status == Player_Win) player.Chat("%s You have %i and the dealer has %i, You win %s from your bet.", CMDTAG, GetHandValue(g_PlayerHand[Client]), GetHandValue(g_DealerHand[Client]), NumberFormat((g_iBetAmount[Client] * 2)));
	}

	//setup menu
	Menu hGameMenu = new Menu(BlackjackGame);
	hGameMenu.SetTitle("You have %i (%s).\nThe Dealer has a %s showing.\nPick an option:", GetHandValue(g_PlayerHand[Client]), playerCards, dealerCard);
	hGameMenu.AddItem("1", "Hit");
	hGameMenu.AddItem("2", "Stand");
	hGameMenu.AddItem("3", "Double Down");
	if(StrEqual(dealerCard, "A") && g_iRoundNumber[Client] == 0)
		hGameMenu.AddItem("4", "Insurance");
	hGameMenu.ExitButton = false;

	hGameMenu.Display(Client, 9999999);
}

public int BlackjackGame(Menu hGameMenu, MenuAction action, int Client, int item)
{
	BClient player = GetPlayerInstance(Client);
	if(!player.IsValid || !g_bIsInGame[Client])
		return 0;

	if(action == MenuAction_Select)
	{
		char selection[8];
		hGameMenu.GetItem(item, selection, sizeof(selection));
		switch(StringToInt(selection))
		{
			case 1:
			{
				player.Chat("%s You hit.", CMDTAG);
				DealCard(Client);
				g_iRoundNumber[Client]++;
			}
			case 2:
			{
				player.Chat("%s You stand.", CMDTAG);
				g_bPlayerStand[Client] = true;
				g_iRoundNumber[Client]++;
			}
			case 3:
			{
				g_bDoubleBet[Client] = true;
				player.Chat("%s Type the amount you want to place as your additional bet. (Cannot be greater than your original bet):", CMDTAG);
				g_iRoundNumber[Client]++;
				return 1;
			}
			case 4:
			{
				g_bInsuranceBet[Client] = true;
				player.Chat("%s Type the amount you want to place as your insurance bet. (Must be less than half of original bet):", CMDTAG);
				g_iRoundNumber[Client]++;
				return 1;
			}
		}
	}
	else if(action == MenuAction_End)
		delete hGameMenu;

	GameStatus status = CheckGameStatus(Client);
	if(status == Player_Bust) player.Chat("%s You bust! You lost your bet of $%s.", CMDTAG, NumberFormat(g_iBetAmount[Client]));
	else if(status == Dealer_Blackjack) player.Chat("%s The dealer has a blackjack! You lost your bet of $%s.", CMDTAG, NumberFormat(g_iBetAmount[Client]));
	else if(status == Blackjack_Push) player.Chat("%s Both players have a blackjack! You win $%s from your bet.", CMDTAG, NumberFormat(g_iBetAmount[Client]));
	else if(status == Player_Blackjack) player.Chat("%s You have a blackjack! You win $%s from your bet.", CMDTAG, NumberFormat(RoundFloat(view_as<float>(g_iBetAmount[Client]) + g_iBetAmount[Client] * 1.2)))
	else if(status == Status_None)
	{
		StartGame(Client)
		return 1;
	}

	player.Chat("%s Type !bj to play again!", CMDTAG);
	ResetVariables(Client);
	return 1;
}

public Action ChatHook(int Client, const char[] command, int argc)
{
	BClient player = GetPlayerInstance(Client);
	if(!player.IsValid)
		return Plugin_Handled;

	if(g_bInsuranceBet[Client])
	{
		char sBet[16];
		GetCmdArg(1, sBet, sizeof(sBet));
		int bet = StringToInt(sBet);

		if(bet > RoundFloat(view_as<float>(g_iBetAmount[Client]) / 2) || bet <= 0)
		{
			player.Chat("%s Insurance bet must be less than half of your original bet!", CMDTAG);
			return Plugin_Handled;
		}

		player.Bank -= bet;
		g_iInsuranceBet[Client] = bet;
		g_bInsuranceBet[Client] = false;

		//check if dealer has a blackjack
		if(GetHandValue(g_DealerHand[Client]) == 21 && g_DealerHand[Client].Length == 2)
		{
			if(GetHandValue(g_PlayerHand[Client]) == 21 && g_PlayerHand[Client].Length == 2)
			{
				player.Chat("Both players have a blackjack! You win $%s from your bet, and %s from your insurance bet.", CMDTAG, NumberFormat(g_iBetAmount[Client]), NumberFormat(g_iInsuranceBet[Client] * 2));
				player.Bank += (g_iBetAmount[Client] + (g_iInsuranceBet[Client] * 2));
			}
			else
			{
				player.Chat("%s The dealer has a blackjack! You win $%s from your insurance bet.", CMDTAG, NumberFormat(g_iInsuranceBet[Client] * 2));
				player.Bank += g_iInsuranceBet[Client] * 2;
			}

			player.Chat("%s Type !bj to play again!", CMDTAG);
			ResetVariables(Client);
			return Plugin_Handled;
		}

		StartGame(Client);
		return Plugin_Handled;
	}
	else if(g_bDoubleBet[Client])
	{
		char sBet[16];
		GetCmdArg(1, sBet, sizeof(sBet));
		int bet = StringToInt(sBet);

		if(bet > RoundFloat(view_as<float>(g_iBetAmount[Client])) || bet <= 0)
		{
			player.Chat("%s Double down bet cannot be greater than your original bet!", CMDTAG);
			return Plugin_Handled;
		}

		player.Bank -= bet;
		g_iBetAmount[Client] += bet;
		g_bDoubleBet[Client] = false;
		g_bPlayerStand[Client] = true;
		StartGame(Client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void DealerAction(int Client)
{
	BClient player = GetPlayerInstance(Client);
	if(!player.IsValid)
		return;
	
	int handValue = GetHandValue(g_DealerHand[Client]);
	if(handValue == 17 && g_DealerHand[Client].Length == 2)
	{
		DealCard(Client, true);
		player.Chat("%s Dealer hits.", CMDTAG);
	}
	else if(handValue < 17)
	{
		DealCard(Client, true);
		player.Chat("%s Dealer hits.", CMDTAG);
	}
	else
	{
		g_bDealerStand[Client] = true;
		player.Chat("%s Dealer stands.", CMDTAG);
	}
	StartGame(Client);
	return;
}

GameStatus CheckGameStatus(int Client)
{
	int playerValue = GetHandValue(g_PlayerHand[Client]);
	int dealerValue = GetHandValue(g_DealerHand[Client]);

	if(dealerValue == 21 && g_iRoundNumber[Client] == 0)
	{
		if(playerValue == 21)
			return Blackjack_Push;
		else
			return Dealer_Blackjack;
	}
	else if(playerValue == 21 && g_iRoundNumber[Client] == 0)
		return Player_Blackjack;

	//player always loses if they bust, even if dealer busts as well
	if(playerValue > 21)
		return Player_Bust;

	if(dealerValue > 21)
		return Dealer_Bust;

	if(g_bPlayerStand[Client] && g_bDealerStand[Client])
	{
		if(playerValue > dealerValue)
			return Player_Win;
		else if(playerValue == dealerValue)
			return Status_Push;
		else
			return Dealer_Win;
	}

	//if we end up here, nobody has won or lost so just continue the game
	return Status_None;
}

stock void DealCard(int Client, bool dealer = false)
{
	ArrayList hand;
	if(dealer)
		hand = g_DealerHand[Client];
	else
		hand = g_PlayerHand[Client];

	char card[10];
	int value, suit;
	do
	{
		value = GetRandomInt(0, 12);
		suit = GetRandomInt(0, 3);
		PrintToChatAll("DealCard value = %s, suit = %s", g_sCards[value], g_sSuits[suit]);
		Format(card, sizeof(card), "%s%s", g_sCards[value], g_sSuits[suit]);
		PrintToChatAll("DealCard card = %s", card);
	} while(hand.FindString(card) != -1);

	if(dealer)
		g_DealerHand[Client].PushString(card);
	else
		g_PlayerHand[Client].PushString(card);
}

stock int GetHandValue(ArrayList hand)
{
	int value;
	for(int i = 0; i < hand.Length; i++)
	{
		char currentCard[10];
		hand.GetString(i, currentCard, sizeof(currentCard));

		if(StrEqual(currentCard[0], "2")) value += 2;
		else if(StrEqual(currentCard[0], "3")) value += 3;
		else if(StrEqual(currentCard[0], "4")) value += 4;
		else if(StrEqual(currentCard[0], "5")) value += 5;
		else if(StrEqual(currentCard[0], "6")) value += 6;
		else if(StrEqual(currentCard[0], "7")) value += 7;
		else if(StrEqual(currentCard[0], "8")) value += 8;
		else if(StrEqual(currentCard[0], "9")) value += 9;
		else if(StrEqual(currentCard[0], "10")) value += 10;
		else if(StrEqual(currentCard[0], "J")) value += 10;
		else if(StrEqual(currentCard[0], "Q")) value += 10;
		else if(StrEqual(currentCard[0], "K")) value += 10;
		else if(StrEqual(currentCard[0], "A"))
		{
			if((value + 11) > 21) 
				value += 1;
			else 
				value += 11;
		}
		else
		{
			LogError("Error occurred within GetHandValue, hand value out of bounds. (Card = %s, Value = %i)", currentCard[0], value);
			return -1;
		}
	}
	return value;
}

//generic query handler, needed for bclient to do stuff or something
public void SQL_GenericQuery(Database db, DBResultSet results, const char[] sError, any data)
{
	if(results == null)
	{
		PrintToServer("%s MySQL Query Failed (Blackjack.sp): %s", CONSOLETAG, sError);
		LogError("%s MySQL Query Failed (Blackjack.sp): %s", CONSOLETAG, sError);
		FireMySQLError();
	}
	
	//nothing happens here
}