extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HTTPRequest.request_completed.connect(_on_request_completed)
	$HTTPRequest.request("https://www.wikidata.org/wiki/Special:EntityData/Q16972633.ttl")

func _on_request_completed(result, response_code, headers, body):
	var data = body.get_string_from_utf8()
	print(data)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
