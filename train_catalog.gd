extends Node
class_name TrainCatalog

const TRAINS := [
	{"id":"wap7","name":"WAP-7","country":"India","type":"Electric Passenger","max_speed":140,"acceleration":0.65,"brake":1.15,"color":Color("#d83232")},
	{"id":"vande_bharat","name":"Vande Bharat","country":"India","type":"High Speed EMU","max_speed":180,"acceleration":1.15,"brake":1.45,"color":Color("#e8e8e8")},
	{"id":"wdg4","name":"WDG-4","country":"India","type":"Diesel Freight","max_speed":105,"acceleration":0.35,"brake":0.8,"color":Color("#267b42")},
	{"id":"shinkansen","name":"Shinkansen N700","country":"Japan","type":"Bullet Train","max_speed":300,"acceleration":1.25,"brake":1.6,"color":Color("#eeeeee")},
	{"id":"e5","name":"Shinkansen E5 Hayabusa","country":"Japan","type":"Bullet Train","max_speed":320,"acceleration":1.35,"brake":1.7,"color":Color("#20a68b")},
	{"id":"jr_diesel","name":"JR Diesel","country":"Japan","type":"Diesel Passenger","max_speed":110,"acceleration":0.55,"brake":1.0,"color":Color("#e6c54a")},
	{"id":"ice3","name":"ICE 3","country":"Germany","type":"High Speed","max_speed":330,"acceleration":1.3,"brake":1.65,"color":Color("#eeeeee")},
	{"id":"br185","name":"TRAXX BR185","country":"Germany","type":"Electric Freight","max_speed":140,"acceleration":0.45,"brake":1.0,"color":Color("#d8a32d")},
	{"id":"tgv","name":"TGV Duplex","country":"France","type":"High Speed","max_speed":320,"acceleration":1.2,"brake":1.55,"color":Color("#eeeeee")},
	{"id":"eurostar","name":"Eurostar e320","country":"Europe","type":"International High Speed","max_speed":320,"acceleration":1.25,"brake":1.6,"color":Color("#222c4e")},
	{"id":"acela","name":"Amtrak Acela","country":"USA","type":"Passenger","max_speed":240,"acceleration":0.85,"brake":1.2,"color":Color("#315b9b")},
	{"id":"sd70","name":"EMD SD70ACe","country":"USA","type":"Diesel Freight","max_speed":110,"acceleration":0.4,"brake":0.9,"color":Color("#b52b24")},
	{"id":"fuxing","name":"CR400 Fuxing","country":"China","type":"High Speed","max_speed":350,"acceleration":1.4,"brake":1.7,"color":Color("#eeeeee")},
	{"id":"hxd3","name":"HXD3","country":"China","type":"Electric Freight","max_speed":120,"acceleration":0.4,"brake":0.95,"color":Color("#b92d2d")},
	{"id":"shanghai_maglev","name":"Shanghai Maglev","country":"China","type":"Maglev","max_speed":430,"acceleration":1.5,"brake":1.8,"color":Color("#eeeeee")},
	{"id":"re460","name":"Re 460","country":"Switzerland","type":"Electric Passenger","max_speed":200,"acceleration":0.8,"brake":1.3,"color":Color("#d42d2d")},
	{"id":"glacier","name":"Glacier Express","country":"Switzerland","type":"Scenic Passenger","max_speed":100,"acceleration":0.35,"brake":0.85,"color":Color("#d72b2b")},
	{"id":"ge4","name":"Ge 4/4 III","country":"Switzerland","type":"Mountain Electric","max_speed":120,"acceleration":0.5,"brake":1.0,"color":Color("#d82d2d")}
]

static func countries() -> Array[String]:
	var result: Array[String] = []
	for train in TRAINS:
		var country: String = train["country"]
		if not result.has(country):
			result.append(country)
	return result

static func get_country_trains(country: String) -> Array:
	var result: Array = []
	for train in TRAINS:
		if train["country"] == country:
			result.append(train)
	return result

static func get_train(id: String) -> Dictionary:
	for train in TRAINS:
		if train["id"] == id:
			return train.duplicate()
	return TRAINS[0].duplicate()
