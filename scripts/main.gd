extends Node2D

var year := 0
var civilization = {
    "population": 100,
    "food": 500,
    "knowledge": 0,
    "technology": "部落时代"
}

func _ready():
    print("Genesis 文明模拟开始")

func _process(delta):
    if Engine.get_process_frames() % 60 == 0:
        simulate_year()

func simulate_year():
    year += 1
    civilization.food -= civilization.population / 10
    civilization.knowledge += randi_range(0, 5)

    if civilization.knowledge > 100:
        civilization.technology = "农业时代"
    if civilization.knowledge > 300:
        civilization.technology = "工业时代"

    print("年份:", year, " 科技:", civilization.technology, " 人口:", civilization.population)
