extends AlephVault__MMO__Client.Main

const TimeAuthProtocol = preload("./time-auth-client-protocol.gd")
const PORT := 6778

## Assign an unlocked wallet/provider exposing request(method, params)
## before the client connects. Native samples can use AlephVault__EVM.Web3Client.
var wallet = null

func _ready() -> void:
	super()
	client_started.connect(_client_started)
	client_stopped.connect(_client_stopped)
	client_failed.connect(_client_failed)

	var auth := _time_auth()
	if auth != null:
		auth.message_logger = Callable(self, "log_time_message")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("client_join"):
		print("join_server() result:", join_server("127.0.0.1", PORT))
	if Input.is_action_just_pressed("client_leave"):
		print("leave_server() result:", leave_server())

func log_time_message(message: String) -> void:
	print("[TIME] %s" % message)

func _client_started() -> void:
	print("TIME client connected")
	var auth := _time_auth()
	if auth == null:
		print("TIME auth protocol is not installed")
		return
	auth.wallet = wallet
	if wallet == null:
		print("Assign an unlocked EVM wallet to TimeClientMain.wallet before login")
		return
	if not await auth.login_siwe():
		print("Could not send SIWE TIME login")

func _client_stopped() -> void:
	print("TIME client stopped")

func _client_failed() -> void:
	print("TIME client connection failed")

func _time_auth() -> TimeAuthProtocol:
	return protocols.get_protocol(TimeAuthProtocol) as TimeAuthProtocol
