extends AlephVault__MMO__Client.Main

const WalletModal = AlephVault__EVM.UI.WalletModal
const Web3Client = AlephVault__EVM.Web3Client
const Siwe = AlephVault__EVM__MMO__Common.Authentication.Siwe
const TimeAuthProtocol = preload("./time-auth-client-protocol.gd")
const PORT := 6778
const RPC_URL := "http://localhost:8545"

var _web3 := Web3Client.new()
var _wallet_modal = null
var _native_lock: Callable = Callable()
var _wallet_ready := false
var _status_label: Label = null
var _log: TextEdit = null

func _ready() -> void:
	super()
	_build_ui()
	client_started.connect(_client_started)
	client_stopped.connect(_client_stopped)
	client_failed.connect(_client_failed)

	var auth := _time_auth()
	if auth != null:
		auth.message_logger = Callable(self, "log_time_message")
		auth.wallet = _web3
		auth.login_ok.connect(_on_auth_login_ok)
		auth.login_failed.connect(_on_auth_login_failed)

	if _web3.manages_wallet():
		_open_wallet_modal()
	else:
		_initialize_web_wallet()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("client_join"):
		join_time_server()
	if Input.is_action_just_pressed("client_leave"):
		_log_line("leave_server() result: %s" % leave_server())

func join_time_server() -> void:
	if not _wallet_ready:
		_log_line("Wallet is not ready yet.")
		if _web3.manages_wallet():
			_open_wallet_modal()
		else:
			_initialize_web_wallet()
		return
	_log_line("join_server() result: %s" % join_server("127.0.0.1", PORT))

func log_time_message(message: String) -> void:
	_log_line("[TIME] %s" % message)

func _client_started() -> void:
	_log_line("TIME client connected")
	var auth := _time_auth()
	if auth == null:
		_log_line("TIME auth protocol is not installed")
		return
	auth.wallet = _web3
	var commands = auth.get_commands()
	if commands == null:
		_log_line("Cannot send SIWE TIME login: auth Commands node is not available.")
		return
	_log_line(
		"Attempting SIWE TIME login via %s (authority: %d, local peer: %d)..."
		% [str(commands.get_path()), commands.get_multiplayer_authority(), multiplayer.get_unique_id()]
	)
	_log_line("Building and signing SIWE TIME payload...")
	var payload := await auth.make_signed_siwe_payload()
	if payload.is_empty():
		_log_line("Could not build or sign SIWE TIME payload.")
		return
	_log_line("SIWE TIME payload signed for %s on chain %s." % [str(payload.get("address", "")), str(payload.get("chainId", ""))])
	_log_line("Sending SIWE TIME login RPC...")
	if auth.login(Siwe.METHOD, payload):
		_log_line("SIWE TIME login request sent. Waiting for server response...")
	else:
		_log_line("Could not send SIWE TIME login")

func _client_stopped() -> void:
	_log_line("TIME client stopped")

func _client_failed() -> void:
	_log_line("TIME client connection failed")

func _time_auth() -> TimeAuthProtocol:
	return protocols.get_protocol(TimeAuthProtocol) as TimeAuthProtocol

func _on_auth_login_ok(payload: Variant = null) -> void:
	_log_line("SIWE TIME login accepted: %s" % str(payload))

func _on_auth_login_failed(payload: Variant = null) -> void:
	_log_line("SIWE TIME login rejected: %s" % str(payload))

func _initialize_web_wallet() -> void:
	_set_status("Requesting browser wallet access...")
	var response: Dictionary = await _web3.initialize()
	if not bool(response.get("ok", false)):
		_set_status("Web wallet initialization failed.")
		_log_line("Web wallet initialization failed: %s" % str(response.get("error", "unknown_error")))
		return
	_wallet_ready = true
	_set_status("Wallet ready. Press client_join to connect.")
	_log_wallet_account()

func _open_wallet_modal() -> void:
	if _wallet_modal == null:
		_wallet_modal = WalletModal.new()
		_wallet_modal.name = "WalletModal"
		_wallet_modal.client = _web3
		_wallet_modal.chain_rpc_url = RPC_URL
		_wallet_modal.started.connect(_on_native_wallet_started)
		add_child(_wallet_modal)
	_set_status("Unlock or create a native wallet.")
	_wallet_modal.show_from_scratch()

func _on_native_wallet_started(lock: Callable) -> void:
	_native_lock = lock
	_wallet_ready = true
	if _wallet_modal != null:
		_wallet_modal.hide()
	_set_status("Wallet ready. Press client_join to connect.")
	_log_wallet_account()

func _log_wallet_account() -> void:
	var accounts: Dictionary = await _web3.get_accounts()
	if not bool(accounts.get("ok", false)):
		_log_line("Account lookup failed: %s" % str(accounts.get("error", "unknown_error")))
		return
	var values: Array = accounts.get("value", [])
	if values.is_empty():
		_log_line("Wallet has no available account.")
		return
	_log_line("Wallet account: %s" % str(values[0]))

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.name = "TimeClientUI"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.offset_left = 16.0
	root.offset_top = 16.0
	root.offset_right = -16.0
	root.offset_bottom = -16.0
	add_child(root)

	_status_label = Label.new()
	_status_label.text = "Starting TIME client..."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_status_label)

	var button_row := HBoxContainer.new()
	root.add_child(button_row)

	var wallet_button := Button.new()
	wallet_button.text = "Wallet"
	wallet_button.pressed.connect(_on_wallet_button_pressed)
	button_row.add_child(wallet_button)

	var join_button := Button.new()
	join_button.text = "Connect"
	join_button.pressed.connect(join_time_server)
	button_row.add_child(join_button)

	var leave_button := Button.new()
	leave_button.text = "Leave"
	leave_button.pressed.connect(func(): _log_line("leave_server() result: %s" % leave_server()))
	button_row.add_child(leave_button)

	_log = TextEdit.new()
	_log.editable = false
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_log)

func _on_wallet_button_pressed() -> void:
	if _web3.manages_wallet():
		if _wallet_ready:
			if _native_lock.is_valid():
				_wallet_ready = false
				_set_status("Wallet locked.")
				_native_lock.call()
			return
		_open_wallet_modal()
	else:
		_initialize_web_wallet()

func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message
	_log_line(message)

func _log_line(message: String) -> void:
	print(message)
	if _log == null:
		return
	_log.text += message + "\n"
	_log.scroll_vertical = _log.get_line_count()
