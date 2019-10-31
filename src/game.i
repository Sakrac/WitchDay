; definitions for gameplay data

enum ScreenID {
	Field = 0,
	WitchHouse = 1
}

enum SelectorID {
	Ingredients = 1,
	Clothes = 2,
	Library = 3
}

enum IngredientID {
	DogsBreath = 0,
	LarvaeHusk,
	ChickenBits,
	AppleStem,
	FrogFlatus,

	Count
}

enum PotionID {
	Empty = -1,
	Failure = 0,
	AppleGrow,
	BarkEar,

	NumPotions = 2
}

struct ScreenSetup {
	word Graphics
	word LeftStartEdge
	word RightStartEdge
	byte StartHeight
	word LeftEdge
	byte LeftNextScreen
	word LeftEdgeText
	byte LeftEdgeTextLen
	word RightEdge
	byte RightNextScreen
	word RightEdgeText
	byte RightEdgeTextLen
}

STRING FontOrder = " ABCDEFGHIJKLMNOPRSTUVWXYZabcdefghijklmnoprstuvwxyz0123456789:'-./!,"

const ActionScreenYC = 22
