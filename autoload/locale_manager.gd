extends Node

signal locale_changed(locale: String)

const TRANSLATIONS_PATH := "res://locale/ui_strings.csv"
const SUPPORTED_LOCALES: PackedStringArray = ["en", "ko"]
const DEFAULT_LOCALE := "en"

var current_locale: String = DEFAULT_LOCALE


func _ready() -> void:
	_load_translations()
	set_language(SettingsManager.get_locale(), false)


func set_language(code: String, persist: bool = true) -> void:
	if not SUPPORTED_LOCALES.has(code):
		code = DEFAULT_LOCALE
	current_locale = code
	TranslationServer.set_locale(code)
	if persist:
		SettingsManager.set_locale(code, true)
	locale_changed.emit(code)


func _load_translations() -> void:
	var file := FileAccess.open(TRANSLATIONS_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to load UI translations: %s" % TRANSLATIONS_PATH)
		return
	var header := file.get_csv_line()
	if header.is_empty() or header[0] != "keys":
		push_error("Invalid translation CSV header")
		return
	var translations: Dictionary = {}
	for i in range(1, header.size()):
		var translation := Translation.new()
		translation.locale = header[i]
		translations[i] = translation
	while not file.eof_reached():
		var cols := file.get_csv_line()
		if cols.is_empty() or cols[0].is_empty():
			continue
		var key := cols[0]
		for i in translations.keys():
			if i < cols.size():
				translations[i].add_message(key, cols[i])
	for translation in translations.values():
		TranslationServer.add_translation(translation)
