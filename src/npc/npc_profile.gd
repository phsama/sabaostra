class_name NpcProfile
extends Resource

@export var id: String
@export var display_name: String
@export_range(1, 5) var friendship: int
@export_range(1, 5) var trust: int
@export_range(1, 5) var fear: int
@export var portrait: Texture2D
@export var blip: AudioStream
