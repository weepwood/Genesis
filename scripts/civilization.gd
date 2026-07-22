class_name Civilization

var population: int = 100
var intelligence: float = 0.5
var cooperation: float = 0.5
var aggression: float = 0.5
var technology_level: int = 0

func evolve():
    technology_level += 1
    population += 10
