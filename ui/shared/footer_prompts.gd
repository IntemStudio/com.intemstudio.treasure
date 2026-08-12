class_name FooterPrompts
extends HBoxContainer

signal prompt_activated(action: String)

const PROMPT_SCENE := preload("res://ui/shared/footer_prompt_label.tscn")


func set_prompts(prompts: Array) -> void:
	for child in get_children():
		child.queue_free()
	for prompt in prompts:
		var entry: FooterPromptLabel = PROMPT_SCENE.instantiate()
		add_child(entry)
		entry.setup(str(prompt.get("button", "")), str(prompt.get("label", "")))
		var action: String = str(prompt.get("action", ""))
		if action.is_empty():
			continue
		entry.pressed.connect(_on_prompt_pressed.bind(action))
		entry.mouse_entered.connect(_on_prompt_hovered.bind(entry, true))
		entry.mouse_exited.connect(_on_prompt_hovered.bind(entry, false))


func _on_prompt_pressed(action: String) -> void:
	prompt_activated.emit(action)


func _on_prompt_hovered(entry: FooterPromptLabel, hovered: bool) -> void:
	entry.set_hovered(hovered)
