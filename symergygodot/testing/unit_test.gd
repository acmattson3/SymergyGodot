extends Node

var do_unit_tests: bool = false

func _ready():
	if not do_unit_tests:
		var args = OS.get_cmdline_args()
		for i in range(args.size()):
			if args[i] == "--run-tests":
				run_tests()
	else:
		run_tests()

var continue_on_fail: bool = true
func run_tests(continue_on_failure: bool = true) -> void:
	continue_on_fail = continue_on_failure
	var args: Array = []
	
	## get_dict_from_json_string tests
	print("Testing get_dict_from_json_string (util.gd):")
	print("Simple case:")
	args = ["{\"foo\": \"bar\"}"]
	test_equal(Util.get_dict_from_json_string, {"foo": "bar"}, args)
	print()
	
	print("Complex case:")
	args = ["{\"a\":1,\"b\":[2,3],\"c\":{\"d\":\"e\"},\"f\":true,\"g\":null}"]
	test_equal(Util.get_dict_from_json_string, {"a": 1, "b": [2, 3], "c": {"d": "e"}, "f": true, "g": null}, args)
	print()
	
	print("Edge case:")
	args = ["{\"\":\"\",\" \":\" \",\"0\":0,\"False\":false,\"None\":null,\"[]\":[],\"{}\":{}}"]
	test_equal(Util.get_dict_from_json_string, {"":""," ":" ","0":0,"False":false,"None":null,"[]":[],"{}":{}}, args)
	print()
	
	## val_in_interval tests
	print("Testing val_in_interval tests (util.gd):")
	print("Inclusive middle:")
	test_equal(Util.val_in_interval, true, [5, 1, 10])
	print()

	print("Inclusive lower bound:")
	test_equal(Util.val_in_interval, true, [1, 1, 10])
	print()

	print("Inclusive upper bound:")
	test_equal(Util.val_in_interval, true, [10, 1, 10])
	print()

	print("Inclusive out of range low:")
	test_equal(Util.val_in_interval, false, [0, 1, 10])
	print()

	print("Inclusive out of range high:")
	test_equal(Util.val_in_interval, false, [11, 1, 10])
	print()

	print("Exclusive middle:")
	test_equal(Util.val_in_interval, true, [5, 1, 10, false])
	print()

	print("Exclusive lower bound:")
	test_equal(Util.val_in_interval, false, [1, 1, 10, false])
	print()

	print("Exclusive upper bound:")
	test_equal(Util.val_in_interval, false, [10, 1, 10, false])
	print()

	print("Exclusive out of range low:")
	test_equal(Util.val_in_interval, false, [0, 1, 10, false])
	print()

	print("Exclusive out of range high:")
	test_equal(Util.val_in_interval, false, [11, 1, 10, false])
	print()

	print("Equal bounds, inclusive:")
	test_equal(Util.val_in_interval, true, [5, 5, 5])
	print()

	print("Equal bounds, exclusive:")
	test_equal(Util.val_in_interval, false, [5, 5, 5, false])
	print()

	print("Reversed bounds, inclusive:")
	test_equal(Util.val_in_interval, false, [5, 10, 1])
	print()

	print("Reversed bounds, exclusive:")
	test_equal(Util.val_in_interval, false, [5, 10, 1, false])
	print()

func test_equal(callable: Callable, expected, args: Array = []):
	var result = callable.callv(args)
	if deep_equal(result, expected): # Correct result
		print("Pass! (", result, " == ", expected, ")")
	else: # Incorrect result
		print("Failed! (", result, " != ", expected, ")")
		assert(continue_on_fail)

func deep_equal(a, b) -> bool:
	if typeof(a) != typeof(b):
		# Allow ints and floats to be compared
		if !((a is float and b is int) or (a is int and b is float)):
			return false
	
	match typeof(a):
		TYPE_DICTIONARY:
			if a.size() != b.size():
				print("Size mismatch: ", a.size(), " vs ", b.size())
				return false
			for key in a.keys():
				if not b.has(key):
					print("Missing key in b: ", key)
					return false
				if not deep_equal(a[key], b[key]):
					print("Mismatch at key: ", key, " → ", a[key], " vs ", b[key])
					return false
			return true
		TYPE_ARRAY:
			if a.size() != b.size():
				print("Array size mismatch: ", a.size(), " vs ", b.size())
				return false
			for i in range(a.size()):
				if not deep_equal(a[i], b[i]):
					print("Mismatch at index ", i, ": ", a[i], " vs ", b[i])
					return false
			return true
		TYPE_FLOAT:
			# Optional: tolerance check if you expect rounding issues
			return abs(a - b) < 0.0001
		TYPE_INT:
			return a == b
		_:
			if a == null and b == null:
				return true
			return a == b
