extends Control

func _ready():
	# Connect signals
	MQTTHandler.broker_connected.connect(_on_broker_connected)
	MQTTHandler.received_message.connect(_on_received_message)
	MQTTHandler.broker_connection_failed.connect(_on_broker_connection_failed)
	
	# Connect to the broker
	MQTTHandler.connect_to_broker("tcp://test.mosquitto.org:1883")

func _on_broker_connected():
	print("Connected to the MQTT broker.")
	MQTTHandler.subscribe("test/topic")
	MQTTHandler.publish("test/topic", "Hello from Godot!")

func _on_received_message(topic, message):
	print("Message received on topic: ", topic, "; Message: ", message)

func _on_broker_connection_failed():
	print("Failed to connect to the MQTT broker.")
