class_name SaveData
extends RefCounted

const FILE_PATH := "user://bastion_zero_save.json"
const SAVE_SCHEMA := 2

static func defaults() -> Dictionary:
    return {
        "schema": SAVE_SCHEMA,
        "bank": 0,
        "meta": {"hull": 0, "damage": 0},
        "runs": 0, "wins": 0, "best_wave": 0, "best_kills": 0,
        "stage_unlocked": 1, "best_stage": 0, "low_fx": true,
        "hard_start": GameCatalog.PLAYTEST_TOOLS
    }

static func validated(data: Variant) -> Dictionary:
    var clean := defaults()
    if typeof(data) != TYPE_DICTIONARY:
        return clean
    clean["bank"] = clampi(int(data.get("bank", 0)), 0, 999999999)
    clean["runs"] = clampi(int(data.get("runs", 0)), 0, 999999999)
    clean["wins"] = clampi(int(data.get("wins", 0)), 0, int(clean["runs"]))
    clean["best_wave"] = clampi(int(data.get("best_wave", 0)), 0, 8)
    clean["best_kills"] = clampi(int(data.get("best_kills", 0)), 0, 999999999)
    clean["stage_unlocked"] = clampi(int(data.get("stage_unlocked", 1)), 1, GameCatalog.TOTAL_STAGES)
    clean["best_stage"] = clampi(int(data.get("best_stage", 0)), 0, GameCatalog.TOTAL_STAGES)
    clean["low_fx"] = bool(data.get("low_fx", true))
    clean["hard_start"] = GameCatalog.PLAYTEST_TOOLS and bool(data.get("hard_start", true))
    var raw_meta: Variant = data.get("meta", {})
    if typeof(raw_meta) == TYPE_DICTIONARY:
        for key in ["hull", "damage"]:
            clean["meta"][key] = clampi(int(raw_meta.get(key, 0)), 0, GameCatalog.META_CAP)
    return clean

static func load_game() -> Dictionary:
    if not FileAccess.file_exists(FILE_PATH):
        return defaults()
    var file := FileAccess.open(FILE_PATH, FileAccess.READ)
    if file == null:
        return defaults()
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    return validated(parsed)

static func write_game(data: Dictionary) -> bool:
    var file := FileAccess.open(FILE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("Cannot save progress: %d" % FileAccess.get_open_error())
        return false
    file.store_string(JSON.stringify(validated(data), "  "))
    file.flush()
    var result: bool = file.get_error() == OK
    file.close()
    return result

static func buy_meta(data: Dictionary, stat: String) -> bool:
    if not data.has("meta") or typeof(data["meta"]) != TYPE_DICTIONARY:
        return false
    var rank: int = int(data["meta"].get(stat, -1))
    var price: int = GameCatalog.meta_cost(stat, rank)
    if price < 0 or int(data.get("bank", 0)) < price:
        return false
    data["bank"] = int(data["bank"]) - price
    data["meta"][stat] = rank + 1
    return true

static func record_run(data: Dictionary, stage: int, victory: bool, report: Dictionary) -> void:
    data["runs"] = int(data["runs"]) + 1
    data["wins"] = int(data["wins"]) + (1 if victory else 0)
    data["bank"] = int(data["bank"]) + int(report["reward"])
    data["best_kills"] = maxi(int(data["best_kills"]), int(report["kills"]))
    if victory:
        data["best_stage"] = maxi(int(data["best_stage"]), stage)
        data["stage_unlocked"] = mini(GameCatalog.TOTAL_STAGES, maxi(int(data["stage_unlocked"]), stage + 1))
