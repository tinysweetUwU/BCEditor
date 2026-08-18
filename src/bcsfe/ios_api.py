"""Non-interactive operations used by the native iOS Tools forms."""
from bcsfe import core


def apply(path: str, action: str, value: int = 0) -> bool:
    """Apply one native edit without allowing a backend exception to escape."""
    try:
        _apply(path, action, value)
        return True
    except BaseException:
        return False


def _apply(path: str, action: str, value: int = 0) -> None:
    core.core_data.init_data()
    save_path = core.Path(path)
    save = core.SaveFile(save_path.read())

    if action == "unlock_all_cats":
        for cat in save.cats.cats:
            cat.unlock(save)
    elif action == "max_cats":
        for cat in save.cats.cats:
            cat.unlock(save)
            cat.set_form_true(save, 3)
            cat.upgrade.base = max(cat.upgrade.base, 8)
            cat.upgrade.plus = max(cat.upgrade.plus, 20)
    elif action == "max_talents":
        for cat in save.cats.cats:
            if cat.talents:
                cat.unlock(save)
                for talent in cat.talents:
                    talent.level = max(talent.level, 10)
    elif action == "max_special_skills":
        for skill in save.special_skills.skills:
            skill.seen = 1
            skill.upgrade.base = max(skill.upgrade.base, 10)
            skill.upgrade.plus = max(skill.upgrade.plus, 20)
    elif action == "unlock_cat_guide":
        for cat in save.cats.cats:
            cat.catguide_collected = True
            cat.gatya_seen = max(cat.gatya_seen, 1)
    elif action == "unlock_enemy_guide":
        save.unlock_enemy_guide = 1
        save.enemy_guide = [1 for _ in save.enemy_guide]
    elif action == "clear_enemy_guide":
        save.unlock_enemy_guide = 0
        save.enemy_guide = [0 for _ in save.enemy_guide]
    elif action == "allow_filibuster":
        save.filibuster_stage_enabled = True
        save.filibuster_stage_id = 0
    elif action == "reset_golden_cpus":
        save.golden_cpu_count = 0
    elif action == "fill_cat_storage":
        for item in save.cats.storage_items:
            item.item_type = 0
            item.item_id = 0
        for cat, item in zip((c for c in save.cats.cats if c.unlocked), save.cats.storage_items):
            item.item_type = 1
            item.item_id = cat.id
    elif action == "clear_cat_storage":
        for item in save.cats.storage_items:
            item.item_type = 0
            item.item_id = 0
    elif action == "set_cat_storage_item":
        packed = int(value)
        slot, item_type, item_id = packed & 0xFFFF, (packed >> 16) & 0xFF, (packed >> 24) & 0xFFFF
        if 0 <= slot < len(save.cats.storage_items):
            item = save.cats.storage_items[slot]
            item.item_type, item.item_id = item_type, item_id
    elif action == "set_cat_level":
        cat_id = int(value) >> 16
        level = int(value) & 0xFFFF
        if 0 <= cat_id < len(save.cats.cats):
            cat = save.cats.cats[cat_id]
            cat.unlock(save)
            cat.upgrade.base = max(0, level - 1)
    elif action == "max_items":
        manager = core.core_data.max_value_manager
        for name in ("catfood", "xp", "normal_tickets", "rare_tickets", "platinum_tickets", "platinum_shards", "legend_tickets", "np", "leadership"):
            if hasattr(save, name) and hasattr(manager, name):
                setattr(save, name, getattr(manager, name))
        if hasattr(save, "hundred_million_ticket") and hasattr(manager, "hundred_million_tickets"):
            save.hundred_million_ticket = manager.hundred_million_tickets
    elif action == "max_resources":
        manager = core.core_data.max_value_manager
        for name, limit in (("catfruit", manager.catfruit_new), ("catseyes", manager.catseyes), ("catamins", manager.catamins)):
            values = getattr(save, name, None)
            if isinstance(values, list):
                setattr(save, name, [limit for _ in values])
    elif action == "max_misc_resources":
        manager = core.core_data.max_value_manager
        for name, fallback in (("treasure_chests", 9999), ("labyrinth_medals", 9999), ("lucky_tickets", 9999)):
            values = getattr(save, name, None)
            if isinstance(values, list):
                limit = getattr(manager, name, fallback)
                setattr(save, name, [limit for _ in values])
    elif action == "max_battle_items":
        limit = core.core_data.max_value_manager.battle_items
        for item in save.battle_items.items:
            item.amount = limit
            item.locked = False
    elif action == "set_battle_item":
        packed = int(value)
        index, amount = packed & 0xFFFF, (packed >> 16) & 0xFFFFFFFF
        if 0 <= index < len(save.battle_items.items):
            item = save.battle_items.items[index]
            item.amount, item.locked = amount, False
    elif action == "set_resource":
        packed = int(value)
        resource, index, amount = packed & 0xFF, (packed >> 8) & 0xFF, (packed >> 16) & 0xFFFFFFFF
        names = ("catfruit", "catseyes", "catamins")
        if resource < len(names):
            values = getattr(save, names[resource], None)
            if isinstance(values, list) and 0 <= index < len(values):
                values[index] = amount
    elif action == "set_event_ticket":
        packed = int(value)
        kind, index, amount = packed & 0xFF, (packed >> 8) & 0xFF, (packed >> 16) & 0xFFFFFFFF
        names = ("event_capsules", "lucky_tickets", "event_capsules_2")
        if kind < len(names):
            values = getattr(save, names[kind], None)
            if isinstance(values, list) and 0 <= index < len(values):
                values[index] = amount
    elif action == "clear_all_maps":
        for name in ("story", "event_stages", "ex_stages", "uncanny", "catamin_stages"):
            if hasattr(save, name): _clear_progress(getattr(save, name))
    elif action == "clear_story_stage":
        packed = int(value)
        map_id, star, stage = packed & 0xFF, (packed >> 8) & 0xFF, (packed >> 16) & 0xFFFF
        save.story.clear_stage(map_id, star, stage, 1, True)
    elif action == "unlock_aku_realm":
        for stage_id in (255, 256, 257, 258, 265, 266, 268):
            save.event_stages.clear_map(1, stage_id, 0, False)
    elif action == "fix_gamatoto_crash":
        save.gamatoto.skin = 2
    elif action == "fix_ototo_crash":
        save.ototo.cannons = core.game.gamoto.ototo.Cannons.init(save.game_version)
    elif action == "fix_time_errors":
        import datetime
        now = datetime.datetime.now()
        save.date_3 = now
        save.timestamp = now.timestamp()
        save.energy_penalty_timestamp = now.timestamp()
    elif action == "max_gamatoto":
        save.gamatoto.xp = 2_000_000_000
        save.gamatoto.remaining_seconds = 0
        save.gamatoto.return_flag = True
    elif action == "set_gamatoto_helper":
        packed = int(value)
        index, helper_id = packed & 0xFFFF, (packed >> 16) & 0xFFFF
        helpers = save.gamatoto.helpers.helpers
        if 0 <= index < len(helpers):
            helpers[index].id = helper_id
    elif action == "set_ototo_engineers":
        save.ototo.engineers = max(0, int(value))
    elif action == "max_ototo_cannons":
        if save.ototo.cannons is None:
            save.ototo.cannons = core.game.gamoto.ototo.Cannons.init(save.game_version)
        for cannon in save.ototo.cannons.cannons.values():
            cannon.development = max(cannon.development, 3)
            cannon.levels = [max(10, int(level)) for level in cannon.levels]
    elif action == "set_ototo_cannon":
        packed = int(value)
        cannon_id, development, level = packed & 0xFF, (packed >> 8) & 0xFF, (packed >> 16) & 0xFF
        if save.ototo.cannons is None:
            save.ototo.cannons = core.game.gamoto.ototo.Cannons.init(save.game_version)
        cannon = save.ototo.cannons.cannons.get(cannon_id)
        if cannon is not None:
            cannon.development = development
            cannon.levels = [level for _ in cannon.levels]
    elif action == "max_gamatoto_materials":
        for material in save.ototo.base_materials.materials:
            material.amount = 9999
    elif action == "max_cat_shrine":
        save.cat_shrine.xp_offering = 2_000_000_000
    elif action == "unlock_equip_menu":
        save.unlock_equip_menu()
    elif action == "reset_officer_pass":
        save.officer_pass.reset(save)
    elif action == "set_restart_pack":
        save.restart_pack = 1
    elif action == "clear_tutorial":
        core.StoryChapters.clear_tutorial(save)
    elif action == "complete_missions":
        conditions = core.core_data.get_mission_conditions(save)
        for mission_id in list(save.missions.clear_states):
            save.missions.clear_states[mission_id] = 2
            condition = conditions.get_condition(mission_id) if conditions else None
            if condition:
                save.missions.requirements[mission_id] = condition.progress_count
    elif action == "unlock_medals":
        names = core.core_data.get_medal_names(save)
        if names and names.medal_names:
            for medal_id, medal in enumerate(names.medal_names):
                if medal:
                    save.medals.add_medal(medal_id)

    save.to_data().to_file(save_path)


_SCALARS = ("catfood", "xp", "normal_tickets", "rare_tickets", "platinum_tickets",
            "legend_tickets", "platinum_shards", "np", "leadership",
            "hundred_million_ticket", "rare_seed", "normal_seed", "event_seed")

def _get_field(save, field):
    return getattr(save.gatya, field) if field.endswith("_seed") else getattr(save, field)

def _set_field(save, field, value):
    if field.endswith("_seed"):
        setattr(save.gatya, field, value)
    else:
        setattr(save, field, value)

def _clear_progress(obj, seen=None):
    if seen is None: seen = set()
    if id(obj) in seen or obj is None or isinstance(obj, (str, bytes, int, float, bool)): return
    seen.add(id(obj))
    if hasattr(obj, "clear_times"): obj.clear_times = max(1, int(getattr(obj, "clear_times", 0)))
    if hasattr(obj, "clear_amount"): obj.clear_amount = max(1, int(getattr(obj, "clear_amount", 0)))
    if isinstance(obj, dict):
        for value in obj.values(): _clear_progress(value, seen)
    elif isinstance(obj, (list, tuple)):
        for value in obj: _clear_progress(value, seen)
    elif hasattr(obj, "__dict__"):
        for value in vars(obj).values(): _clear_progress(value, seen)


def read_value(path: str, field: str) -> int:
    core.core_data.init_data()
    save = core.SaveFile(core.Path(path).read())
    if field not in _SCALARS:
        raise ValueError(field)
    return int(_get_field(save, field))


def write_value(path: str, field: str, value: int) -> None:
    core.core_data.init_data()
    if field not in _SCALARS:
        raise ValueError(field)
    save_path = core.Path(path)
    save = core.SaveFile(save_path.read())
    _set_field(save, field, max(0, int(value)))
    save.to_data().to_file(save_path)
