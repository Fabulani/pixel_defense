class_name CurrencyManager extends Resource

# TODO: connect this signal to HUD indicating amount of coins
signal currency_changed(new_amount: int)

var coins := 0:
	set(value):
		coins = value
		print_debug("Coins: %d" % coins)
		currency_changed.emit(coins)

func can_afford(amount: int) -> bool:
	return coins >= amount

func spend(amount: int) -> bool:
	if not can_afford(amount):
		return false
	coins -= amount
	return true

func earn(amount: int) -> void:
	coins += amount
