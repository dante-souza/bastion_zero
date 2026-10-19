class_name EvolutionChoiceView
extends ColorRect

## Phase I.2: screenshot-inspired 3-card tactical level-up menu.
## Presentation only: GameCatalog remains the authority for all mechanics.
signal upgrade_chosen(kind: String)

const BG := Color("#020911")
const INK := Color("#E6F0F7")
const SUBTLE := Color("#A5B7C6")
const MINT := Color("#6DC09A")
const GOLD := Color("#EFC187")
const CARD := Color("#0A1721")
const BORDER := Color("#294354")
const CARD_MIN_HEIGHT := 190.0

var offers: Array[String] = []
var owned: Dictionary = {}
var new_level := 1


func configure(valid_offers: Array[String], owned_ranks: Dictionary, level: int) -> void:
    offers = valid_offers.duplicate()
    owned = owned_ranks.duplicate(true)
    new_level = level


func _ready() -> void:
    color = BG
    mouse_filter = Control.MOUSE_FILTER_STOP
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _compose()


func _compose() -> void:
    # Content-driven scrolling instead of nested fixed-height CenterContainers.
    var scroll := ScrollContainer.new()
    scroll.name = "EvolutionScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)

    var margin := MarginContainer.new()
    margin.name = "EvolutionMargins"
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    margin.add_theme_constant_override("margin_left", 26)
    margin.add_theme_constant_override("margin_right", 26)
    margin.add_theme_constant_override("margin_top", 66)
    margin.add_theme_constant_override("margin_bottom", 24)
    scroll.add_child(margin)

    # Phase I.6: the column is at least one screen tall and a spacer pushes
    # the cards into the bottom (thumb) half; taller content still scrolls.
    margin.custom_minimum_size.y = get_viewport_rect().size.y
    var stack := VBoxContainer.new()
    stack.name = "EvolutionStack"
    stack.add_theme_constant_override("separation", 12)
    margin.add_child(stack)

    var level_line := _text("LEVEL %02d  →  %02d" % [maxi(1, new_level - 1), new_level], 19, MINT, true)
    level_line.name = "LevelAdvance"
    stack.add_child(level_line)

    var title := _text("CHOOSE ONE", 39, GOLD, true)
    title.name = "EvolutionTitle"
    stack.add_child(title)
    stack.add_child(_text("COMBAT PAUSED  •  SELECT AN UPGRADE", 17, SUBTLE, true))

    var separator := ColorRect.new()
    separator.color = Color("#1D3B46")
    separator.custom_minimum_size.y = 2
    separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stack.add_child(separator)

    var thumb_spacer := Control.new()
    thumb_spacer.name = "ThumbSpacer"
    thumb_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    thumb_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    stack.add_child(thumb_spacer)

    for kind in offers:
        if GameCatalog.upgrade_available(owned, kind):
            stack.add_child(_card(kind, int(owned.get(kind, 0))))

    var summary := _text(EvolutionProfile.synergy_summary(owned), 19, MINT, true)
    summary.name = "SynergySummary"
    stack.add_child(summary)
    var footer := _text("CHOOSE TO RESUME THE BATTLE", 15, SUBTLE, true)
    footer.name = "EvolutionFooter"
    stack.add_child(footer)


func _card(kind: String, current_rank: int) -> Button:
    var cap: int = GameCatalog.upgrade_cap(kind)
    var next_rank: int = current_rank + 1
    var color_accent: Color = EvolutionProfile.accent(kind)
    var card := Button.new()
    card.name = "Choice" + kind.capitalize()
    card.text = ""
    card.set_meta("upgrade_key", kind)
    card.custom_minimum_size.y = CARD_MIN_HEIGHT
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.tooltip_text = GameCatalog.upgrade_description(kind, next_rank)
    card.focus_mode = Control.FOCUS_ALL
    for variant in ["normal", "hover", "pressed", "focus"]:
        var style := StyleBoxFlat.new()
        style.bg_color = CARD if variant == "normal" else CARD.lightened(0.12)
        style.border_color = color_accent
        style.border_width_left = 6
        style.border_width_right = 2
        style.border_width_top = 2
        style.border_width_bottom = 2
        style.set_corner_radius_all(12)
        style.anti_aliasing = true
        style.content_margin_left = 12
        style.content_margin_right = 12
        style.content_margin_top = 10
        style.content_margin_bottom = 10
        card.add_theme_stylebox_override(variant, style)
    card.pressed.connect(_pick.bind(kind))

    # Labels/icons cannot intercept a tap: the Button remains the one hit target.
    var inset := MarginContainer.new()
    inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
    inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    inset.add_theme_constant_override("margin_left", 22)
    inset.add_theme_constant_override("margin_right", 18)
    inset.add_theme_constant_override("margin_top", 13)
    inset.add_theme_constant_override("margin_bottom", 10)
    card.add_child(inset)
    # A Button does not grow with its children: follow the wrapped content so
    # a two-line description can never push the rank row through the border.
    inset.minimum_size_changed.connect(func() -> void:
        card.custom_minimum_size.y = maxf(CARD_MIN_HEIGHT,
            inset.get_combined_minimum_size().y))
    var content := VBoxContainer.new()
    content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content.add_theme_constant_override("separation", 9)
    inset.add_child(content)

    var upper := HBoxContainer.new()
    upper.mouse_filter = Control.MOUSE_FILTER_IGNORE
    upper.add_theme_constant_override("separation", 15)
    content.add_child(upper)
    var icon := UpgradeEmblem.new()
    icon.name = "UpgradeIcon"
    icon.kind = kind
    icon.tint = color_accent
    icon.custom_minimum_size = Vector2(64, 64)
    icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    upper.add_child(icon)

    var description_stack := VBoxContainer.new()
    description_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
    description_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    description_stack.add_theme_constant_override("separation", 4)
    upper.add_child(description_stack)
    var category := _text(GameCatalog.upgrade_category(kind, current_rank), 16, color_accent)
    category.name = "ChoiceCategory"
    description_stack.add_child(category)
    var title := _text(GameCatalog.upgrade_name(kind), 26, GOLD)
    title.name = "ChoiceName"
    description_stack.add_child(title)

    var description := _text(GameCatalog.upgrade_description(kind, next_rank), 20, SUBTLE)
    description.name = "ChoiceDescription"
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(description)

    var rank := "OWNED %d/%d  →  NEXT %d/%d" % [current_rank, cap, next_rank, cap]
    if next_rank == cap:
        rank += "  •  FINAL"
    var rank_row := HBoxContainer.new()
    rank_row.name = "ChoiceRankRow"
    rank_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rank_row.add_theme_constant_override("separation", 12)
    content.add_child(rank_row)
    var rank_label := _text(rank, 18, GOLD)
    rank_label.name = "ChoiceRank"
    rank_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rank_row.add_child(rank_label)
    var pips := _text(EvolutionProfile.rank_marks(next_rank, cap), 20, color_accent)
    pips.name = "ChoicePips"
    rank_row.add_child(pips)

    return card


func _pick(kind: String) -> void:
    # Idempotence and stale-state safety also checked by Main._apply_upgrade.
    if GameCatalog.upgrade_available(owned, kind) and offers.has(kind):
        upgrade_chosen.emit(kind)


func _text(value: String, pt: int, shade: Color, centered: bool = false) -> Label:
    var l := Label.new()
    l.text = value
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    l.add_theme_font_size_override("font_size", pt)
    l.add_theme_color_override("font_color", shade)
    l.autowrap_mode = TextServer.AUTOWRAP_OFF
    if centered:
        l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    return l
