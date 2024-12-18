

// Classes Implementation

typedef struct {
    char suit;
    char rank;
    int value;
} Card;

typedef struct {
    Card hand[11]; // Max cards in a hand without busting
    int card_count;
    int score;
} Player;
