extends Node

var client := preload("res://addons/AlephVault.EVM.MMO.Samples/scenes/time/time-client.tscn")
var server := preload("res://addons/AlephVault.EVM.MMO.Samples/scenes/time/time-server.tscn")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("choose_client"):
		get_tree().change_scene_to_packed(client)
	elif Input.is_action_just_pressed("choose_server"):
		get_tree().change_scene_to_packed(server)
