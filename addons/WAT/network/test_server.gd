tool
extends "res://addons/WAT/network/test_network.gd"

signal network_peer_connected
signal results_received
var _peer_id: int

func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	custom_multiplayer.connect("network_peer_connected", self, "_on_network_peer_connected")
	if _error(_peer.create_server(PORT, MAXCLIENTS)) == OK:
		custom_multiplayer.network_peer = _peer
	
func _on_network_peer_connected(id: int) -> void:
	_peer_id = id
	_peer.set_peer_timeout(id, 59000, 60000, 61000)
	emit_signal("network_peer_connected")
	
func send_tests(testdir: Array, repeat: int, thread_count: int) -> void:
	rpc_id(_peer_id, "_on_tests_received_from_server", testdir, repeat, thread_count)

master func _on_results_received_from_client(results: Array = []) -> void:
	emit_signal("results_received", results)
