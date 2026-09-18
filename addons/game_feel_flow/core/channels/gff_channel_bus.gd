class_name GFFChannelBus
extends RefCounted

## Game Feel Flow Channel Bus
##
## Channel-scoped publish/subscribe hub — the Godot counterpart of Feel's
## MMEventManager + MMChannelData broadcast model. Emitters broadcast an
## event on a channel; only listeners subscribed to a matching channel are
## invoked, so unrelated effects never hear each other.
##
## Channel identifiers:
##   int            -> int channel ("i:3")
##   StringName     -> named channel ("s:player_hit")
##   GFFChannel     -> asset channel, matched by resource identity
##   null (listen)  -> wildcard: receives every broadcast of that event
##
## Owned by GameFeelFlow — use GameFeelFlow.broadcast_channel /
## listen_channel / unlisten_channel rather than instantiating directly.

var debug_enabled: bool = false

# channel_key -> { event_name -> Array[Callable] }
var _listeners: Dictionary = {}


static func key_of(channel: Variant) -> String:
	## Normalizes any channel identifier to a dictionary key.
	if channel == null:
		return ""
	if channel is int:
		return "i:" + str(channel)
	if channel is String or channel is StringName:
		return "s:" + str(channel)
	if channel is Resource:
		return "r:" + str(channel.get_instance_id())
	return "u:" + str(channel)


func subscribe(channel: Variant, event: StringName, callback: Callable) -> void:
	## Register `callback(payload)` for `event` on `channel`.
	## Pass channel=null to listen to that event on every channel.
	var key := key_of(channel)
	if not _listeners.has(key):
		_listeners[key] = {}
	var bucket: Dictionary = _listeners[key]
	if not bucket.has(event):
		bucket[event] = []
	if not bucket[event].has(callback):
		bucket[event].append(callback)
	_dbg("subscribe event=" + str(event) + " channel=" + key)


func unsubscribe(channel: Variant, event: StringName, callback: Callable) -> void:
	var key := key_of(channel)
	if not _listeners.has(key):
		return
	var bucket: Dictionary = _listeners[key]
	if bucket.has(event):
		bucket[event].erase(callback)
		if bucket[event].is_empty():
			bucket.erase(event)
	if bucket.is_empty():
		_listeners.erase(key)
	_dbg("unsubscribe event=" + str(event) + " channel=" + key)


func broadcast(channel: Variant, event: StringName, payload: Dictionary = {}) -> int:
	## Deliver `payload` to listeners of `event` on `channel` plus wildcard
	## (null-channel) listeners. Returns how many callbacks were invoked.
	var key := key_of(channel)
	var delivered := _deliver(key, event, payload)
	if key != "":
		delivered += _deliver("", event, payload)
	_dbg("broadcast event=" + str(event) + " channel=" + key + " delivered=" + str(delivered))
	return delivered


func _deliver(key: String, event: StringName, payload: Dictionary) -> int:
	if not _listeners.has(key):
		return 0
	var bucket: Dictionary = _listeners[key]
	if not bucket.has(event):
		return 0
	var count := 0
	# Copy: callbacks may unsubscribe (e.g. queue_free) during delivery.
	for cb: Callable in bucket[event].duplicate():
		if cb.is_valid():
			cb.call(payload)
			count += 1
	return count


func listener_count(channel: Variant, event: StringName) -> int:
	var key := key_of(channel)
	if _listeners.has(key) and _listeners[key].has(event):
		return _listeners[key][event].size()
	return 0


func clear() -> void:
	_listeners.clear()
	_dbg("clear all listeners")


func _dbg(message: String) -> void:
	if debug_enabled:
		print("[GFFChannelBus] ", message)
