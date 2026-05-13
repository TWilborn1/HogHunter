extends Node

var udp := PacketPeerUDP.new()
onready var crosshair = $"../Crosshair"

const CAMERA_WIDTH = 640

func _ready():
	udp.listen(4242)

func _process(delta):
	if udp.get_available_packet_count() > 0:
		var msg = udp.get_packet().get_string_from_utf8()
		var parts = msg.split(",")

		if parts.size() == 2:
			var x = float(parts[0])
			var y = float(parts[1])

			# Flip horizontal axis
			x = CAMERA_WIDTH - x

			crosshair.set_target(Vector2(x, y))
