@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("BlurHash", "res://addons/godot-blurhash/BlurHash.gd")


func _exit_tree():
	remove_autoload_singleton("BlurHash")
