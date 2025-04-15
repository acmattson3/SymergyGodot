extends Control

@export var SENSITIVITYSLIDER : HSlider
@export var SENSITVITYNUMBER : Label
@export var FOVSLIDER : HSlider
@export var FOVNUMBER : Label

func _ready() -> void:
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	MQTTHandler.broker_disconnected.connect(_on_broker_disconnected)

func _on_exit_settings_pressed() -> void:
	hide()

func _on_sensitivity_slider_value_changed(value: float) -> void:
	SENSITVITYNUMBER.text = str(SENSITIVITYSLIDER.value)

func _on_fov_slider_value_changed(value: float) -> void:
	FOVNUMBER.text = str(FOVSLIDER.value)

func send_mqtt_message(message: String) -> void:
	%MQTTMessagesLabel.text += message+"\n"

func _on_broker_connected(mqtt_host):
	send_mqtt_message("Connected to "+mqtt_host+"!")

func _on_broker_connection_failed(mqtt_host):
	send_mqtt_message("Connection to "+mqtt_host+" failed!")

func _on_broker_disconnected(mqtt_host):
	send_mqtt_message("Disconnected from "+mqtt_host+".")

func _on_test_connect_button_pressed() -> void:
	send_mqtt_message("Attempting to connect to broker...")
	MQTTHandler.disconnect_from_server()
	
	var mqtt_user = %UsernameLineEdit.text
	var mqtt_pass = %PasswordLineEdit.text
	
	MQTTHandler.set_user_pass(mqtt_user, mqtt_pass)
	
	var broker_url: String = %BrokerHostnameLineEdit.text
	if not MQTTHandler.connect_to_broker(broker_url):
		print(broker_url)
		var url_string = "No URL provided." if broker_url=="" else broker_url
		send_mqtt_message("Invalid MQTT URL: "+url_string)
		return
	
