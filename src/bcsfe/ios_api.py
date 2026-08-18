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

    save.to_data().to_file(save_path)
