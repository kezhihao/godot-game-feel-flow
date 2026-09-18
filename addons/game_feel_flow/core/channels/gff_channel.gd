@tool
class_name GFFChannel
extends Resource

## Game Feel Flow Channel
##
## Named channel asset used to route events between emitters and receivers.
## Create .tres instances (e.g. "ChanPlayerHit.tres") so channel identities are
## readable and refactor-safe. Equivalent of Feel's MMChannel scriptable object.
##
## A channel is matched by resource identity — two listeners referencing the
## same .tres share the channel. Plain ints and StringNames also work as
## channel identifiers via GFFChannelBus.

@export var description: String = ""
