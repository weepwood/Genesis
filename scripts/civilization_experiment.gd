extends Node

class_name CivilizationExperiment

signal history_updated(record)

var history: Array[String] = []
var simulator = ExperimentSimulator.new()

func start_experiment():
    for i in range(1000):
        simulator.simulate_year()
        if i % 100 == 0:
            history.append(generate_report())
            history_updated.emit(history.back())

func generate_report() -> String:
    return "第 %d 年：%s，人口 %.0f，科技 %s" % [
        simulator.year,
        simulator.civilization.era,
        simulator.civilization.population,
        simulator.civilization.technology
    ]
