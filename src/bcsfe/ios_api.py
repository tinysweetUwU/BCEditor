"""Non-interactive operations used by the native iOS Tools forms."""
from bcsfe import core


def apply(path: str, action: str, value: int = 0) -> None:
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
    elif action == "set_cat_level":
        cat_id = int(value) >> 16
        level = int(value) & 0xFFFF
        if 0 <= cat_id < len(save.cats.cats):
            cat = save.cats.cats[cat_id]
            cat.unlock(save)
            cat.upgrade.base = max(0, level - 1)
    elif action == "max_items":
        manager = core.core_data.max_value_manager
        for name in ("catfood", "xp", "normal_tickets", "rare_tickets", "platinum_tickets", "np", "leadership"):
            if hasattr(save, name) and hasattr(manager, name):
                setattr(save, name, getattr(manager, name))
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
    elif action == "unlock_equip_menu":
        save.unlock_equip_menu()
    elif action == "reset_officer_pass":
        save.officer_pass.reset(save)

    save.to_data().to_file(save_path)


_SCALARS = ("catfood", "xp", "normal_tickets", "rare_tickets", "platinum_tickets",
            "legend_tickets", "platinum_shards", "np", "leadership",
            "rare_seed", "normal_seed", "event_seed")

def _get_field(save, field):
    return getattr(save.gatya, field) if field.endswith("_seed") else getattr(save, field)

def _set_field(save, field, value):
    if field.endswith("_seed"):
        setattr(save.gatya, field, value)
    else:
        setattr(save, field, value)


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
