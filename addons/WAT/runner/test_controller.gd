extends Node

const Log: Script = preload("res://addons/WAT/log.gd")
const Test: Script = preload("res://addons/WAT/test/test.gd")
const Case: Script = preload("res://addons/WAT/test/case.gd")
const Assertions: Script = preload("res://addons/WAT/assertions/assertions.gd")
const Parameters: Script = preload("res://addons/WAT/test/parameters.gd")
const Recorder: Script = preload("res://addons/WAT/test/recorder.gd")
const Watcher: Script = preload("res://addons/WAT/test/watcher.gd")
const Any: Script = preload("res://addons/WAT/test/any.gd")
const Director: Script = preload("res://addons/WAT/double/factory.gd")
const Registry: Script = preload("res://addons/WAT/double/registry.gd")
const Yielder: Script = preload("res://addons/WAT/test/yielder.gd")
const COMPLETED: String = "completed"
signal completed

var _test: Test
var _case: Node
var _cursor: int = -1
var _methods: PoolStringArray = []
var _current_method: String
var _assertions: Assertions
var _parameters: Parameters
var _watcher: Watcher
var _director: Director
var _registry: Registry
var _yielder: Yielder

func _init() -> void:
	_assertions = Assertions.new()
	_parameters = Parameters.new()
	_watcher = Watcher.new()
	_director = Director.new()
	_registry = Registry.new()
	_yielder = Yielder.new()
	_director.registry = _registry
	add_child(_director)
	add_child(_yielder)
#	_yielder.connect("finished", self, "_next")

func run(test: Dictionary) -> void:
	Log.method("run", self)
	_test = test["gdscript"].new()
	_case = Case.new(_test, test)
	_test.asserts = _assertions
	_test.parameters = _parameters
	_test.recorder = Recorder
	_test.watcher = _watcher
	_test.direct = _director
	_test.yielder = _yielder
	_test.any = Any
	if test.has("method"):
		_methods.append(test["method"])
	else:
		_methods = _test.methods()
	if _methods.empty():
		push_warning("No Tests found in " + test["path"] + "")
		call_deferred("_complete")
		return
	_test.connect("cancelled", self, "_on_test_cancelled")
	_test.connect("described", _case, "_on_test_method_described")
	_assertions.connect("asserted", _case, "_on_asserted")
	_assertions.connect("asserted", _test, "_on_last_assertion")
	add_child(_test)
	
	# Core run
	var cursor = -1
	yield(call_function("start"), COMPLETED)
	for function in _methods:
		if not _test.rerun_method:
			cursor += 1
		for hook in ["pre", "execute", "post"]:
			yield(call_function(hook, cursor), COMPLETED)
	yield(call_function("end"), COMPLETED)
	
#	_test = {}
	_test.queue_free()
	return get_results()
	
func call_function(function, cursor = 0):
	var s = _test.call(function) if function != "execute" else execute(cursor)
	call_deferred("emit_signal", COMPLETED)
	yield(s, COMPLETED) if s is GDScriptFunctionState else yield(self, COMPLETED)
	
func execute(cursor: int):
	var _current_method: String = _methods[cursor]
	_case.add_method(_current_method)
	return _test.call(_current_method)

func get_results() -> Dictionary:
	_case.calculate()
	var results: Dictionary = _case.to_dictionary()
	_case.free()
	return results
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_registry.clear()
		_assertions.free()
		_registry.free()
		# _director.free(), This gets freed automatically because it is a child now
		_watcher.clear()
		if is_instance_valid(_case):
			_case.free()
