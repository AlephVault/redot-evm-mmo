extends AlephVault__MMO__Server.Main

const PORT := 6778

func _ready() -> void:
	super()
	server_started.connect(_server_started)
	server_stopped.connect(_server_stopped)
	client_entered.connect(_client_entered)
	client_left.connect(_client_left)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("server_start"):
		print("launch() result:", launch(PORT, 32, 0, 0, 0))
	if Input.is_action_just_pressed("server_stop"):
		print("stop() result:", stop())

func _server_started() -> void:
	print("TIME server started on port %d" % PORT)

func _server_stopped() -> void:
	print("TIME server stopped")

func _client_entered(id: int) -> void:
	print("TIME client entered: %s" % id)

func _client_left(id: int) -> void:
	print("TIME client left: %s" % id)
