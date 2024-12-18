#include "PmodOLED.h"
#include "PmodKYPD.h"
#include "PmodGPIO.h"
#include "xil_printf.h"
#include <stdio.h>
#include <stdlib.h>
#include "sleep.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "xuartps.h"
#include "classes.h" // Include the class definitions

#define DEFAULT_KEYTABLE "0FED789C456B123A"
#define MAX_PLAYERS 8
#define BTN_DEVICE_ID XPAR_AXI_GPIO_0_DEVICE_ID
#define LED_DEVICE_ID XPAR_AXI_GPIO_1_DEVICE_ID

PmodGPIO ledDevice;

// Global Variables
PmodOLED oled;
PmodKYPD kypd;
int current_view = -1; // -1 for dealer, 0-7 for players
int player_pots[MAX_PLAYERS]; // Array for player pots
int current_bets[MAX_PLAYERS]; // Array for current bets
int current_turn = 0; // Current player's turnter
int num_players = 1; // Number of players

// Function Prototypes
void InitializeGame();
void InitializePlayer(Player *player);
Card DrawCard();
void DisplayHand(Player *player, const char *name, int player_index);
void UpdateScore(Player *player);
void PlaceBet(int player_index);
void PlayPlayerTurn(Player *player, int player_index, Player *dealer);
void PlayDealerTurn(Player *dealer);
void ResolveGame(Player players[], Player *dealer);
int GetPlayerInput(int mode);
void CheckForExit();
void UpdateGPIOForWinner(int winners);
void UpdateGPIOForPlayer(int player_index);
void PauseAfterInput();
void DisplayGoodbyeMessage();
int SelectNumberOfPlayers();
void ResetPlayerHands(Player players[], Player *dealer);
void ToggleView(Player players[], Player *dealer);
void SaveDisplayState(const char *display_data);

// Helper Functions
const char suits[] = {'H', 'D', 'S', 'C'}; // Hearts, Diamonds, Spades, Clubs
const char ranks[] = {'A', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K'};
const int values[] = {11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10};
char last_display[128]; // Buffer to store the last displayed data

void EnableCaches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheEnable();
#endif
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheEnable();
#endif
#endif
}

void DisableCaches() {
#ifdef __MICROBLAZE__
#ifdef XPAR_MICROBLAZE_USE_DCACHE
    Xil_DCacheDisable();
#endif
#ifdef XPAR_MICROBLAZE_USE_ICACHE
    Xil_ICacheDisable();
#endif
#endif
}

void InitializeGame() {
    EnableCaches();

    // Initialize OLED
    OLED_Begin(&oled, XPAR_PMODOLED_0_AXI_LITE_GPIO_BASEADDR, XPAR_PMODOLED_0_AXI_LITE_SPI_BASEADDR, 0x0, 0x0);
    OLED_ClearBuffer(&oled);

    // Initialize Keypad
    KYPD_begin(&kypd, XPAR_PMODKYPD_0_AXI_LITE_GPIO_BASEADDR);
    KYPD_loadKeyTable(&kypd, (u8 *)DEFAULT_KEYTABLE);

    // Initialize GPIO for LEDs
    GPIO_begin(&ledDevice, XPAR_PMODGPIO_0_AXI_LITE_GPIO_BASEADDR, 0x00);

    // Initialize player pots
    for (int i = 0; i < MAX_PLAYERS; i++) {
        player_pots[i] = 10000;
    }

    srand(0); // Seed random number generator
}

void InitializePlayer(Player *player) {
    player->card_count = 0;
    player->score = 0;
}

Card DrawCard() {
    Card card;
    card.suit = suits[rand() % 4];
    int rank_index = rand() % 13;
    card.rank = ranks[rank_index];
    card.value = values[rank_index];
    return card;
}

void UpdateScore(Player *player) {
    player->score = 0;
    int ace_count = 0;

    for (int i = 0; i < player->card_count; i++) {
        player->score += player->hand[i].value;
        if (player->hand[i].rank == 'A') {
            ace_count++;
        }
    }

    while (player->score > 21 && ace_count > 0) {
        player->score -= 10;
        ace_count--;
    }
}

void DisplayHand(Player *player, const char *name, int player_index) {
    OLED_ClearBuffer(&oled);

    char display_buffer[128] = {0};
    char title[16];

    if (strcmp(name, "Player") == 0) {
        snprintf(title, sizeof(title), "Player %d", player_index + 1);
    } else {
        snprintf(title, sizeof(title), "%s", name);
    }

    OLED_SetCursor(&oled, 0, 0);
    OLED_PutString(&oled, title);
    snprintf(display_buffer, sizeof(display_buffer), "%s\n", title);

    OLED_SetCursor(&oled, 0, 1);
    for (int i = 0; i < player->card_count; i++) {
        char buffer[4];
        snprintf(buffer, sizeof(buffer), "%c%c ", player->hand[i].rank, player->hand[i].suit);
        OLED_PutString(&oled, buffer);
        strncat(display_buffer, buffer, sizeof(display_buffer) - strlen(display_buffer) - 1);
    }

    OLED_SetCursor(&oled, 0, 2);
    char score_buffer[16];
    snprintf(score_buffer, sizeof(score_buffer), "Score: %d", player->score);
    OLED_PutString(&oled, score_buffer);
    strncat(display_buffer, "\n", sizeof(display_buffer) - strlen(display_buffer) - 1);
    strncat(display_buffer, score_buffer, sizeof(display_buffer) - strlen(display_buffer) - 1);

    OLED_SetCursor(&oled, 0, 3);
    char pot_buffer[16];
    snprintf(pot_buffer, sizeof(pot_buffer), "Pot: $%d", player_pots[player_index]);
    OLED_PutString(&oled, pot_buffer);
    strncat(display_buffer, "\n", sizeof(display_buffer) - strlen(display_buffer) - 1);
    strncat(display_buffer, pot_buffer, sizeof(display_buffer) - strlen(display_buffer) - 1);

    OLED_Update(&oled);

    SaveDisplayState(display_buffer);
}

void RestoreDisplayState() {
    OLED_ClearBuffer(&oled);
    OLED_SetCursor(&oled, 0, 0);

    char *line = strtok(last_display, "\n");
    int row = 0;
    while (line && row < 4) {
        OLED_SetCursor(&oled, 0, row);
        OLED_PutString(&oled, line);
        line = strtok(NULL, "\n");
        row++;
    }

    OLED_Update(&oled);
}



void UpdateGPIOForPlayer(int player_index) {
    GPIO_setPins(&ledDevice, 1 << player_index); // Illuminate the LED for the current player
}

void UpdateGPIOForWinner(int winners) {
    GPIO_setPins(&ledDevice, winners); // Illuminate LEDs for winning players
}

void PlaceBet(int player_index) {
    xil_printf("\r\nPlayer %d: Place your bet (1-9 for $100-$900):\r\n", player_index + 1);
    int bet_input = GetPlayerInput(0); // Betting mode
    PauseAfterInput();

    if (bet_input >= 1 && bet_input <= 9) {
        current_bets[player_index] = bet_input * 100;
        if (current_bets[player_index] > player_pots[player_index]) {
            xil_printf("\r\nInsufficient funds! Bet cannot exceed pot.\r\n");
            current_bets[player_index] = 0;
            PlaceBet(player_index);
        } else {
            xil_printf("\r\nPlayer %d bet: $%d\r\n", player_index + 1, current_bets[player_index]);
            player_pots[player_index] -= current_bets[player_index];
        }
    } else {
        xil_printf("\r\nInvalid bet. Please bet again.\r\n");
        PlaceBet(player_index);
    }
}

void ToggleView(Player players[], Player *dealer) {
    if (current_view == -1) {
        // Restore the last saved display data
        RestoreDisplayState();
        current_view = current_turn;
    } else {
        // Switch to the dealer's hand
        current_view = -1;
        if (dealer->card_count > 0) {
            DisplayHand(dealer, "Dealer", 1000);
        } else {
            xil_printf("Dealer has no cards to display.\r\n");
        }
    }
}




void PlayPlayerTurn(Player *player, int player_index, Player *dealer) {
    current_turn = player_index;
    UpdateGPIOForPlayer(player_index);

    // Ensure the dealer has at least one card
    if (dealer->card_count == 0) {
        xil_printf("\r\nDealer has no cards. Dealing a card to the dealer.\r\n");
        dealer->hand[dealer->card_count++] = DrawCard();
        UpdateScore(dealer);
    }

    // Variables for split hand
    int is_split = 0;           // Flag indicating if the hand has been split
    Card split_hand[10];        // Temporary array for the split hand
    int split_card_count = 0;   // Card count for the split hand
    int split_hand_score = 0;   // Score for the split hand

    xil_printf("\r\n\n\nPlayer %d's turn:\r\n", player_index + 1);
    DisplayHand(player, "Player", player_index, 1); // Save state for player's hand

    // Main gameplay loop
    while (1) {
        int choice = GetPlayerInput(1); // Action mode
        PauseAfterInput();

        if (choice == 0) { // Toggle display
            ToggleView(player, dealer);
        } else if (choice == 1) { // Hit
            if (is_split == 0) {
                xil_printf("\r\nPlayer chose to Hit on Hand 1\r\n");
                player->hand[player->card_count++] = DrawCard();
                UpdateScore(player);
                DisplayHand(player, "Player", player_index, 1);

                if (player->score > 21) {
                    xil_printf("\r\nHand 1 Busts with score: %d\r\n", player->score);
                    if (is_split == 1) {
                        xil_printf("\r\nNow playing Split Hand:\r\n");
                        is_split = 2;
                        continue;
                    }
                    break;
                }
            } else if (is_split == 1) {
                xil_printf("\r\nPlayer chose to Hit on Split Hand\r\n");
                split_hand[split_card_count++] = DrawCard();

                // Calculate score for the split hand
                split_hand_score = 0;
                int ace_count = 0;
                for (int i = 0; i < split_card_count; i++) {
                    split_hand_score += split_hand[i].value;
                    if (split_hand[i].rank == 'A') ace_count++;
                }

                while (split_hand_score > 21 && ace_count > 0) {
                    split_hand_score -= 10;
                    ace_count--;
                }

                // Display split hand
                OLED_ClearBuffer(&oled);
                OLED_SetCursor(&oled, 0, 0);
                OLED_PutString(&oled, "Split Hand");
                OLED_SetCursor(&oled, 0, 1);
                for (int i = 0; i < split_card_count; i++) {
                    char buffer[4];
                    snprintf(buffer, sizeof(buffer), "%c%c ", split_hand[i].rank, split_hand[i].suit);
                    OLED_PutString(&oled, buffer);
                }
                OLED_SetCursor(&oled, 0, 2);
                char score_buf[16];
                snprintf(score_buf, sizeof(score_buf), "Score: %d", split_hand_score);
                OLED_PutString(&oled, score_buf);
                OLED_Update(&oled);

                if (split_hand_score > 21) {
                    xil_printf("\r\nSplit Hand Busts with score: %d\r\n", split_hand_score);
                    break;
                }
            }
        } else if (choice == 2) { // Stand
            xil_printf("\r\nPlayer chose to Stand\r\n");
            if (is_split == 0 && split_card_count > 0) {
                xil_printf("\r\nNow playing Split Hand:\r\n");
                is_split = 1; // Switch to split hand
            } else {
                break;
            }
        } else if (choice == 3) { // Split
            if (player->card_count == 2 && (player->hand[0].value == player->hand[1].value ||
                                            (player->hand[0].value >= 10 && player->hand[1].value >= 10))) {
                xil_printf("\r\nPlayer chose to Split\r\n");
                if (player_pots[player_index] >= current_bets[player_index]) {
                    // Move the second card to the split hand
                    split_hand[split_card_count++] = player->hand[1];
                    player->card_count = 1; // Keep only the first card in the player's hand

                    // Deal a new card to both hands
                    player->hand[player->card_count++] = DrawCard();
                    split_hand[split_card_count++] = DrawCard();

                    // Calculate score for the split hand
                    split_hand_score = 0;
                    int ace_count = 0;
                    for (int i = 0; i < split_card_count; i++) {
                        split_hand_score += split_hand[i].value;
                        if (split_hand[i].rank == 'A') ace_count++;
                    }

                    while (split_hand_score > 21 && ace_count > 0) {
                        split_hand_score -= 10;
                        ace_count--;
                    }

                    // Double the bet for the split hand
                    current_bets[player_index] *= 2;
                    player_pots[player_index] -= current_bets[player_index];

                    is_split = 1; // Indicate split hand is active
                    xil_printf("\r\nSplit successful. Now playing Hand 1:\r\n");
                    DisplayHand(player, "Player", player_index, 1);
                } else {
                    xil_printf("\r\nInsufficient funds to split.\r\n");
                }
            } else {
                xil_printf("Split not allowed. Cards must have the same value or both be 10-value cards.\r\n");
            }
        }
    }

    // Reset view after the player's turn ends
    current_view = -1;
}





void PlayDealerTurn(Player *dealer) {
    xil_printf("\r\n\n\nDealer's turn:\r\n");
    while (dealer->score < 17) {
        dealer->hand[dealer->card_count++] = DrawCard();
        UpdateScore(dealer);
    }
    DisplayHand(dealer, "Dealer", 1000);
}

void ResolveGame(Player players[], Player *dealer) {
    int winners = 0; // Bitmask for winners
    for (int i = 0; i < num_players; i++) {
        xil_printf("\r\nPlayer %d:\r\n", i + 1);
        if (players[i].score > 21) {
            xil_printf("\r\nPlayer Busts! Dealer wins.\r\n");
        } else if (dealer->score > 21 || players[i].score > dealer->score) {
            player_pots[i] += 2 * current_bets[i];
            winners |= (1 << i);
            xil_printf("\r\nPlayer Wins with score: %d. Dealer score: %d\r\n", players[i].score, dealer->score);
        } else if (players[i].score < dealer->score) {
            xil_printf("\r\nDealer Wins with score: %d. Player score: %d\r\n", dealer->score, players[i].score);
        } else {
            player_pots[i] += current_bets[i];
            winners |= (1 << i);
            xil_printf("\r\nIt's a Push! Player score: %d. Dealer score: %d\r\n", players[i].score, dealer->score);
        }
    }
    UpdateGPIOForWinner(winners);
}

void ResetPlayerHands(Player players[], Player *dealer) {
    for (int i = 0; i < num_players; i++) {
        players[i].card_count = 0;
    }
    dealer->card_count = 0;
}

int SelectNumberOfPlayers() {
    xil_printf("\r\nEnter number of players (1-8):\r\n");
    while (1) {
        int key = GetPlayerInput(0); // Allow selection of 1-8
        if (key >= 1 && key <= MAX_PLAYERS) {
            xil_printf("\r\nNumber of players selected: %d\r\n", key);
            return key;
        } else {
            xil_printf("\r\nInvalid selection. Please press a number between 1 and 8.\r\n");
        }
    }
}

int GetPlayerInput(int mode) {
    // Modes: 0 = Bet, 1 = Action, 2 = Next Hand
    u16 keystate;
    u8 key;

    while (1) {
        CheckForExit(); // Continuously check for "q" or "Q" from terminal
        keystate = KYPD_getKeyStates(&kypd);
        if (KYPD_getKeyPressed(&kypd, keystate, &key) == KYPD_SINGLE_KEY) {
            if (mode == 0) { // Betting phase
                if (key >= '1' && key <= '9') {
                    return key - '0';
                }
            } else if (mode == 1) { // Action phase
                switch (key) {
                    case 'A': return 1; // Hit
                    case 'B': return 2; // Stand
                    case 'C': return 3; // Double Down
                    case 'D': return 4; // Split
                    case '0': return 0; // Toggle Display
                    default: break; // Ignore other keys
                }
            } else if (mode == 2) { // Next hand phase
                if (key == 'F') {
                    return 5; // Start next hand
                }
            }
        }
        usleep(100000); // Debounce delay
    }
}

void CheckForExit() {
    if (XUartPs_IsReceiveData(XPAR_PS7_UART_1_BASEADDR)) {
        char input = XUartPs_RecvByte(XPAR_PS7_UART_1_BASEADDR);
        if (input == 'q' || input == 'Q') {
            DisplayGoodbyeMessage();
            exit(0);
        }
    }
}

void SaveDisplayState(const char *display_data) {
    strncpy(last_display, display_data, sizeof(last_display) - 1);
    last_display[sizeof(last_display) - 1] = '\0';
}

void DisplayGoodbyeMessage() {
    xil_printf("\r\nExiting Game: Goodbye\n");
	OLED_ClearBuffer(&oled);
    OLED_SetCursor(&oled, 0, 0);
    OLED_PutString(&oled, "Goodbye!");
    OLED_Update(&oled);
    GPIO_setPins(&ledDevice, 0x00); // Turn off all LEDs
    sleep(2);
    OLED_End(&oled); // Turn off the OLED
}

void PauseAfterInput() {
    usleep(300000); // Pause to prevent multiple input registrations
}

int main() {
    InitializeGame();

    // Welcome message and controls
    xil_printf("\r\nWelcome to Blackjack!\r\n");
    xil_printf("Here are the controls:\r\n");
    xil_printf("A: Hit  |  B: Stand  |  C: Split  |  D: Double Down  |  0: Toggle Player/Dealer Hand\r\n");
    xil_printf("\r\nSelect the number of players to continue:\r\n");
    xil_printf("\r\nPress q on the keyboard to exit the game:\r\n");
    num_players = SelectNumberOfPlayers();
    usleep(1000000); // Pause to prevent multiple input registrations
    Player players[MAX_PLAYERS];
    Player dealer;

    InitializePlayer(&dealer);

    for (int i = 0; i < num_players; i++) {
        InitializePlayer(&players[i]);
    }


    while (1) {
        ResetPlayerHands(players, &dealer);

        // Place bets for all players
        for (int i = 0; i < num_players; i++) {
            PlaceBet(i);
        }

        // Deal two cards to each player
        for (int i = 0; i < num_players; i++) {
            players[i].hand[players[i].card_count++] = DrawCard();
            usleep(30000);
            players[i].hand[players[i].card_count++] = DrawCard();
            usleep(30000);
            UpdateScore(&players[i]);
        }

        // Deal one card to the dealer
        dealer.hand[dealer.card_count++] = DrawCard();
        UpdateScore(&dealer);

        // Each player takes their turn
        for (int i = 0; i < num_players; i++) {
            PlayPlayerTurn(&players[i], i, &dealer);
        }

        // Dealer takes their turn
        PlayDealerTurn(&dealer);

        // Resolve the game
        ResolveGame(players, &dealer);
    }

    return 0;
}

