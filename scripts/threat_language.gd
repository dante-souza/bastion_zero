class_name ThreatLanguage
extends RefCounted

## Source of truth for the Phase I.4 guide and HUD danger colors.
## Unlike the reference mockup, GREEN RINGS are enemies in Bastion Zero:
## do not mislabel them as friendly loot or invent collectible XP shards.

const WARNING := Color("#FF923D")
const CRITICAL := Color("#F44A60")
const SHIELDED := Color("#F4DE45")
const ELITE := Color("#F66AD9")
const MINT := Color("#6BBD98")
const CYAN := Color("#28D9FF")


static func descriptions() -> Array[Dictionary]:
    return [
        {"id": "guardian", "group": "YOURS", "title": "Guardian", "desc": "The blue core and cyan defensive horizon. Hold the line.", "color": CYAN},
        {"id": "weapon", "group": "YOURS", "title": "Shots & beams", "desc": "Cyan rounds, magenta Prism, amber Comets, blue Arc, jade Nova.", "color": CYAN},
        {"id": "grunt", "group": "HOSTILE", "title": "Grunt · green ring", "desc": "Basic approaching hostile. GREEN RINGS ARE ENEMIES, not XP.", "color": VisualProfile.GRUNT},
        {"id": "runner", "group": "HOSTILE", "title": "Runner · orange wedge", "desc": "Fast attacker with wide side-to-side movement.", "color": VisualProfile.RUNNER},
        {"id": "tank", "group": "HOSTILE", "title": "Tank · yellow square", "desc": "Slow armored enemy. Inner diamond marks its shell.", "color": VisualProfile.TANK},
        {"id": "elite", "group": "HOSTILE", "title": "Elite · magenta core", "desc": "High-HP threat. Orange outer ring; red halo when enraged.", "color": VisualProfile.ELITE},
        {"id": "focus", "group": "SIGNALS", "title": "Target focus", "desc": "Gold outline identifies the enemy you selected.", "color": VisualProfile.TARGET_LOCK},
        {"id": "slow", "group": "SIGNALS", "title": "Slowed", "desc": "Jade ring: this enemy is moving at reduced speed.", "color": VisualProfile.ENEMY_SLOWED},
        {"id": "health", "group": "SIGNALS", "title": "Enemy health", "desc": "Mint bar shows remaining HP on tanks, elites and damaged foes.", "color": VisualProfile.HEALTH_FILL},
        {"id": "breach", "group": "SIGNALS", "title": "Breach alert", "desc": "Red warning: an enemy crossed the line and damaged your hull.", "color": CRITICAL},
        {"id": "xp", "group": "SIGNALS", "title": "XP on defeat", "desc": "Kills grant XP directly. No collectible XP shards exist yet.", "color": MINT},
        {"id": "formation", "group": "SIGNALS", "title": "Wave warning", "desc": "Orange banner names the active formation, not a new enemy type.", "color": WARNING}
    ]


static func color_for_event(event: String, formation: String) -> Color:
    var msg := event.to_upper()
    if msg.contains("BREACH"):
        return CRITICAL
    if msg.contains("ELITE"):
        return ELITE
    if msg.contains("ARMORED") or msg.contains("SIEGE") or formation == "ARMORED":
        return SHIELDED
    return WARNING


static func banner(event: String, formation: String, hostiles: int) -> String:
    if not event.is_empty():
        return "ALERT  •  " + event
    if hostiles <= 0:
        return ""
    var symbol := "▼" if formation == "WEDGE" or formation == "RUSH" else "◆"
    if formation == "ARMORED" or formation == "PHALANX":
        symbol = "■"
    return "%s  INCOMING  •  %s  •  %d HOSTILES" % [
        symbol, formation, hostiles
    ]
