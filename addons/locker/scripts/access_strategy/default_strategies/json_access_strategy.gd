@tool
@icon("res://addons/locker/icons/json_access_strategy.svg")
## The [LokJSONAccessStrategy] is a concrete implementation of
## [LokAccessStrategy] that saves and loads data in JSON format.
## 
## This strategy saves data in a human-readable format, which
## makes it easy to debug but not secure. If you need security,
## consider using [LokEncryptedAccessStrategy] instead. [br]
## [br]
## [b]Version[/b]: 1.0.0[br]
## [b]Author[/b]: [url]github.com/nadjiel[/url]
class_name LokJSONAccessStrategy
extends LokAccessStrategy

## Returns a string representation of this access strategy.
func _to_string() -> String:
	return "JSON"

## Saves the [param data] in JSON format to the [param path].
func save(data: Dictionary, path: String) -> Error:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(data, "  "))
	return OK

## Loads data from the [param path] in JSON format.
func load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		var result = {}
		result["status"] = ERR_FILE_NOT_FOUND
		result["data"] = {}
		return result
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		var result = {}
		result["status"] = FileAccess.get_open_error()
		result["data"] = {}
		return result
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		var result = {}
		result["status"] = error
		result["data"] = {}
		return result
	
	var result = {}
	result["status"] = OK
	result["data"] = json.get_data()
	return result
