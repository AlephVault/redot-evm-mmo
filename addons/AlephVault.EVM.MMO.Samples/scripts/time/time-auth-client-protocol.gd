extends AlephVault__EVM__MMO__Client.Authentication.Protocol

signal time_message_received(message: String)

const SAMPLE_DOMAIN := "main.time.sample.play"
const SAMPLE_CHAIN_ID := 31337

var message_logger: Callable = Callable()

func _ready() -> void:
	siwe_domain = SAMPLE_DOMAIN
	chain_id = SAMPLE_CHAIN_ID

func handle_login_ok(payload: Variant = null) -> void:
	super.handle_login_ok(payload)
	if payload is Dictionary and payload.has("message"):
		log_time_message(str(payload["message"]))

func log_time_message(message: String) -> void:
	time_message_received.emit(message)
	if message_logger.is_valid():
		message_logger.call(message)
	else:
		print(message)
