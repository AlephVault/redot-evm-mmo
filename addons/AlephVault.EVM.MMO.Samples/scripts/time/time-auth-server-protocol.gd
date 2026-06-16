extends AlephVault__EVM__MMO__Server.Authentication.Protocol

const SAMPLE_DOMAIN := "main.time.sample.play"
const SAMPLE_CHAIN_ID := 31337

func _ready() -> void:
	siwe_domain = SAMPLE_DOMAIN
	chain_id = SAMPLE_CHAIN_ID

func _authenticate(connection_id: int, method: String, payload: Variant) -> Dictionary:
	var result: Dictionary = await super._authenticate(connection_id, method, payload)
	if AlephVault__MMO__Common.Protocols.Authentication.LoginResult.is_accepted(result):
		var address := str(result.get("account_id", ""))
		result["ok"] = {
			"address": address,
			"message": make_time_message(address),
		}
	return result

func make_time_message(address: String) -> String:
	var now := Time.get_datetime_dict_from_system(false)
	var timestamp := "%04d-%02d-%02d %02d:%02d:%02d" % [
		int(now["year"]),
		int(now["month"]),
		int(now["day"]),
		int(now["hour"]),
		int(now["minute"]),
		int(now["second"]),
	]
	return "Hello %s, the current time is %s" % [address, timestamp]
