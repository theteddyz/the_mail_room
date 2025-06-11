extends Node

signal package_order_disrupted(package_num: int)
@export var all_packages: Array[int] = []
var last_delivered_package_number: int = 0
var next_package_index = 0

func _ready():
	ScareDirector.package_delivered.connect(verify_package_order)

func verify_package_order(package_num: int):
	if package_num == all_packages[next_package_index]:
		last_delivered_package_number = package_num
		next_package_index += 1
	else:
		package_order_disrupted.emit()
		all_packages.remove_at(all_packages.rfind(package_num))
