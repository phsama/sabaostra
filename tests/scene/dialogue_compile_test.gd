extends GdUnitTestSuite

const PROFILES_DIR := "res://content/profiles"


func test_profiles_folder_is_not_empty() -> void:
	assert_array(_profile_paths()).is_not_empty()


func test_every_profile_is_complete() -> void:
	for path in _profile_paths():
		var profile: NpcProfile = load(path)
		var file_id := path.get_file().get_basename()
		assert_str(profile.id).override_failure_message("%s: id must match file name" % path).is_equal(file_id)
		assert_str(profile.display_name).override_failure_message("%s: display_name missing" % path).is_not_empty()
		for level: int in [profile.friendship, profile.trust, profile.fear]:
			assert_int(level).override_failure_message("%s: levels must be 1 to 5" % path).is_between(1, 5)


func _profile_paths() -> Array[String]:
	var paths: Array[String] = []
	for file in DirAccess.get_files_at(PROFILES_DIR):
		if file.get_extension() == "tres":
			paths.append(PROFILES_DIR.path_join(file))
	return paths
