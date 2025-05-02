extends Node

# Called when the node enters the scene tree for the first time.
func _ready():
	$".".request_completed.connect(_on_request_completed)
	$".".request("https://www.wikidata.org/wiki/Special:EntityData/Q16972633.ttl")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func parse_turtle_file(file_content):
	var triples_by_subject = {}
	var prefixes = {}
	
	# First pass: Extract prefixes
	var prefix_regex = RegEx.new()
	prefix_regex.compile("@prefix\\s+(\\S+):\\s+<([^>]+)>\\s*\\.")
	var prefix_results = prefix_regex.search_all(file_content)
	
	for result in prefix_results:
		var prefix = result.get_string(1)
		var uri = result.get_string(2)
		prefixes[prefix] = uri
	
	# Second pass: Extract triples
	var triple_regex = RegEx.new()
	# Match a subject-predicate-object pattern ending with a period
	triple_regex.compile("(\\S+)\\s+([^\\s\\.]+)\\s+([^\\s\\.]+(?:\\s+[^\\s\\.]+)*)\\s*\\.")
	var triple_results = triple_regex.search_all(file_content)
	
	for result in triple_results:
		var subject = expand_uri(result.get_string(1), prefixes)
		var predicate = expand_uri(result.get_string(2), prefixes)
		var object = expand_uri(result.get_string(3), prefixes)
		
		# Create a new array for this subject if it doesn't exist
		if not triples_by_subject.has(subject):
			triples_by_subject[subject] = []
		
		# Add the predicate-object pair to the subject's array
		triples_by_subject[subject].append({
			"predicate": predicate,
			"object": object
		})
	
	# Handle the ; shorthand notation (same subject, different predicates)
	var subject_predicates_regex = RegEx.new()
	subject_predicates_regex.compile("(\\S+)\\s+([^\\s\\.]+)\\s+([^\\s\\.;]+)\\s*;\\s*([^\\s\\.]+)\\s+([^\\s\\.;]+)")
	var subject_predicates_results = subject_predicates_regex.search_all(file_content)
	
	for result in subject_predicates_results:
		var subject = expand_uri(result.get_string(1), prefixes)
		var predicate1 = expand_uri(result.get_string(2), prefixes)
		var object1 = expand_uri(result.get_string(3), prefixes)
		var predicate2 = expand_uri(result.get_string(4), prefixes)
		var object2 = expand_uri(result.get_string(5), prefixes)
		
		if not triples_by_subject.has(subject):
			triples_by_subject[subject] = []
		
		triples_by_subject[subject].append({
			"predicate": predicate1,
			"object": object1
		})
		
		triples_by_subject[subject].append({
			"predicate": predicate2,
			"object": object2
		})
	
	return {
		"prefixes": prefixes,
		"triples_by_subject": triples_by_subject
	}

# Helper function to expand prefixed URIs
func expand_uri(uri_str, prefixes):
	# If it's a full URI (enclosed in <>), return without the brackets
	if uri_str.begins_with("<") and uri_str.ends_with(">"):
		return uri_str.substr(1, uri_str.length() - 2)
	
	# If it's a literal (enclosed in quotes), return as is
	if uri_str.begins_with("\"") or uri_str.begins_with("'"):
		return uri_str
	
	# If it uses a prefix (format: prefix:value)
	var parts = uri_str.split(":", true, 1)
	if parts.size() == 2 and prefixes.has(parts[0]):
		return prefixes[parts[0]] + parts[1]
	
	# Otherwise return as is
	return uri_str

func _on_request_completed(_result, response_code, headers, body):
	var ttl_content = body.get_string_from_utf8()
	var parsed_data = parse_turtle_file(ttl_content)
	
	print("Prefixes:")
	for prefix in parsed_data.prefixes.keys():
		print("  " + prefix + ": " + parsed_data.prefixes[prefix])
	
	print("\nTriples by subject:")
	for subject in parsed_data.triples_by_subject.keys():
		print("Subject: " + subject)
		for triple in parsed_data.triples_by_subject[subject]:
			print("  " + triple.predicate + " → " + triple.object)
