@tool
@icon("res://addons/locker/icons/encrypted_access_strategy.svg")
## The [LokEncryptedAccessStrategy] is a concrete implementation of
## [LokAccessStrategy] that saves and loads data in an encrypted format.
## 
## This strategy saves data in a secure, non-human-readable format,
## which makes it more secure but harder to debug. If you need to debug
## your save files, consider using [LokJSONAccessStrategy] instead. [br]
## [br]
## [b]Version[/b]: 1.0.0[br]
## [b]Author[/b]: [url]github.com/nadjiel[/url]
class_name LokEncryptedAccessStrategy
extends LokAccessStrategy

## The password used for encryption and decryption.
var _password: String = ""

## Sets the [param new_password] to be used for encryption and decryption.
func set_password(new_password: String) -> void:
	_password = new_password

## Returns the current password used for encryption and decryption.
func get_password() -> String:
	return _password

## Returns a string representation of this access strategy.
func _to_string() -> String:
	return "Encrypted"

## Saves the [param data] in encrypted format to the [param path].
func save(data: Dictionary, path: String) -> Error:
	var file = FileAccess.open_encrypted(path, FileAccess.WRITE, _password.to_utf8_buffer())
	if file == null:
		return FileAccess.get_open_error()
	
	file.store_string(JSON.stringify(data, "  "))
	return OK

## Loads data from the [param path] in encrypted format.
func load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		var result = {}
		result["status"] = ERR_FILE_NOT_FOUND
		result["data"] = {}
		return result
	
	var file = FileAccess.open_encrypted(path, FileAccess.READ, _password.to_utf8_buffer())
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

## The [method _save_partition] method overrides its super counterpart
## [method LokAccessStrategy._save_partition] in order to provide [param data]
## saving in a encrypted format. [br]
## When finished, this method returns a [Dictionary] with the data it
## saved. [br]
## To read more about the parameters of this method, see
## [method LokAccessStrategy._save_partition].
func _save_partition(
	partition_path: String,
	data: Dictionary,
	replace: bool = false
) -> Dictionary:
	var result: Dictionary = create_result()
	
	var error: Error = LokFileSystemUtil.create_encrypted_file_if_not_exists(
		partition_path, _password
	)
	
	# If partition wasn't created, cancel
	if error != Error.OK:
		result["status"] = error
		return result
	
	var load_result: Dictionary = {}
	
	if not replace:
		load_result = _load_partition(partition_path)
	
	# Merge previous and new datas
	result["data"] = data.merged(load_result.get("data", {}))
	
	error = LokFileSystemUtil.write_or_create_encrypted_file(
		partition_path, _password, JSON.stringify(result["data"], "\t")
	)
	
	if error != Error.OK:
		result["status"] = error
	
	return result

## The [method _load_partition] method overrides its super counterpart
## [method LokAccessStrategy._load_partition] in order to provide encrypted data
## loading. [br]
## When finished, this method returns a [Dictionary] with the data it
## loaded. [br]
## To read more about the parameters of this method and the format of
## its return, see [method LokAccessStrategy._load_partition].
func _load_partition(
	partition_path: String
) -> Dictionary:
	var result: Dictionary = create_result()
	
	# Abort if partition doesn't exist
	if not LokFileSystemUtil.file_exists(partition_path):
		result["status"] = Error.ERR_FILE_NOT_FOUND
		return result
	
	var loaded_content: String = LokFileSystemUtil.read_encrypted_file(
		partition_path, _password, true
	)
	var loaded_data: Variant = LokFileSystemUtil.parse_json_from_string(
		loaded_content, true
	)
	
	# Cancel if no data could be parsed
	if loaded_data == {}:
		result["status"] = Error.ERR_FILE_UNRECOGNIZED
	
	result["data"] = loaded_data
	
	return result
