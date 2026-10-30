extends RefCounted
class_name RouteCatalog

const ROUTES := [
    {"id":"mumbai_delhi","country":"India","name":"Mumbai - Delhi Express","distance":1384,"type":"Mainline","terrain":"Plains, towns and hills","weather":"Clear"},
    {"id":"kashmir","country":"India","name":"Kashmir Mountain Railway","distance":120,"type":"Mountain","terrain":"Mountains, tunnels and valleys","weather":"Snow"},
    {"id":"tokyo_osaka","country":"Japan","name":"Tokyo - Osaka Shinkansen","distance":515,"type":"High Speed","terrain":"Coastal plains and mountains","weather":"Clear"},
    {"id":"hokkaido","country":"Japan","name":"Hokkaido Scenic Line","distance":180,"type":"Scenic","terrain":"Forests and snowy mountains","weather":"Snow"},
    {"id":"berlin_munich","country":"Germany","name":"Berlin - Munich ICE","distance":585,"type":"High Speed","terrain":"European countryside","weather":"Cloudy"},
    {"id":"rhine_valley","country":"Germany","name":"Rhine Valley Railway","distance":150,"type":"Scenic","terrain":"River, villages and hills","weather":"Rain"},
    {"id":"glacier_route","country":"Switzerland","name":"Glacier Express Route","distance":291,"type":"Mountain","terrain":"Alpine mountains and bridges","weather":"Snow"},
    {"id":"bernina","country":"Switzerland","name":"Bernina Mountain Line","distance":61,"type":"Mountain","terrain":"High alpine railway","weather":"Snow"},
    {"id":"california","country":"USA","name":"California Coast Route","distance":350,"type":"Passenger","terrain":"Coast, hills and cities","weather":"Clear"},
    {"id":"desert_freight","country":"USA","name":"American Desert Freight","distance":600,"type":"Freight","terrain":"Desert and open plains","weather":"Clear"},
    {"id":"beijing_shanghai","country":"China","name":"Beijing - Shanghai HSR","distance":1318,"type":"High Speed","terrain":"Modern cities and plains","weather":"Clear"},
    {"id":"mountain_china","country":"China","name":"China Mountain Railway","distance":220,"type":"Scenic","terrain":"Mountains and deep valleys","weather":"Rain"}
]

static func get_countries() -> Array[String]:
    var result: Array[String] = []
    for route in ROUTES:
        var country: String = route["country"]
        if not result.has(country):
            result.append(country)
    return result

static func get_routes(country: String) -> Array:
    var result: Array = []
    for route in ROUTES:
        if route["country"] == country:
            result.append(route.duplicate())
    return result

static func get_route(id: String) -> Dictionary:
    for route in ROUTES:
        if route["id"] == id:
            return route.duplicate()
    return ROUTES[0].duplicate()
