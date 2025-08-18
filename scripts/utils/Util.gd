class_name Util
extends Node

# Additional color constants (converted from hex values)
static var COL_HEAD = Color("3399ff40")    # Light blue with alpha
static var COL_CORE = Color("ffcc3340")  # Orange with alpha
static var COL_ARM = Color("ff4d4d40")     # Red with alpha
static var COL_LEGS = Color("4dcc4d40")   # Green with alpha
static var COL_UTILITY = Color("674bcc40")  # Purple with alpha
static var COL_SCRAPPER = Color("cc634b40")   # Brownish-red with alpha

static func get_slot_color(slot_type: String) -> Color:
    match slot_type.to_lower():
        "head":
            return COL_HEAD
        "core":
            return COL_CORE
        "arm":
            return COL_ARM
        "legs":
            return COL_LEGS
        "utility":
            return COL_UTILITY
        "scrapper":
            return COL_SCRAPPER
        _:
            return Color("ffffff40")  # Default to white with alpha