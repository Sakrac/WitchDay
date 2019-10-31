const MAX_INVENTORY = 6

enum InventoryArt {
	Broom=0,
	EmptyBottle,
	FullBottle,
	Apple,
	Cake,
	Key
}

enum InventoryItem {
	Broom=0
	EmptyBottle,
	FullBottleGrow,
	FullBottleBarkEar,
	Apple,
	Cake,
	Key
}

const InventoryScreenXC = 40 - MAX_INVENTORY*3
const InventoryScreenYC = 22
const InventoryScreenOffs = InventoryScreenYC * 40 + InventoryScreenXC
