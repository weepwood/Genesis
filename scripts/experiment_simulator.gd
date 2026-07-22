extends Node

class_name ExperimentSimulator

var year: int = 0
var civilization = {
    "population": 100,
    "food": 500,
    "knowledge": 0,
    "technology": [],
    "era": "部落时代"
}

var planet = {
    "temperature": 50,
    "water": 70,
    "resources": 60
}

func simulate_year():
    year += 1
    civilization.food -= civilization.population * 0.02
    civilization.knowledge += planet.resources * 0.01

    if civilization.food < 100:
        civilization.population *= 0.98

    discover_technology()

func discover_technology():
    if civilization.knowledge > 20 and not "火" in civilization.technology:
        civilization.technology.append("火")
        civilization.era = "生存时代"
    elif civilization.knowledge > 80 and not "农业" in civilization.technology:
        civilization.technology.append("农业")
        civilization.era = "农业时代"
