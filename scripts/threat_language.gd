class_name ThreatLanguage
extends RefCounted

## Source of truth for the threat guide and HUD danger colors.
## Phase I.5 rule: cool = yours, warm = hostile, green = XP (growth) only.
## Severity comes from the event KIND emitted by Arena, never from its copy,
## so rewording a message can no longer change its color.

const KIND_INFO := "info"
const KIND_FORMATION := "formation"
const KIND_ELITE := "elite"
const KIND_BREACH := "breach"

const WARNING := Color("#FF923D")
const CRITICAL := VisualProfile.BREACH
const SHIELDED := Color("#F4DE45")
const ELITE := VisualProfile.ELITE
const MINT := VisualProfile.XP_GREEN
const CYAN := Color("#28D9FF")

const ARMORED_FORMATIONS := ["ARMORED", "PHALANX", "SIEGE"]


static func descriptions() -> Array[Dictionary]:
    return [
        {"id": "guardian", "group": "YOURS", "title": "Guardian", "desc": "The blue core and cyan defensive horizon. Hold the line.", "color": CYAN},
        {"id": "weapon", "group": "YOURS", "title": "Shots & beams", "desc": "All cool: cyan rounds, violet Prism, white Comets, blue Arc, teal Nova.", "color": CYAN},
        {"id": "focus", "group": "YOURS", "title": "Target focus", "desc": "Ice outline marks the enemy you selected.", "color": VisualProfile.TARGET_LOCK},
        {"id": "slow", "group": "YOURS", "title": "Slowed", "desc": "Teal ring: Nova Field has slowed this enemy.", "color": VisualProfile.ENEMY_SLOWED},
        {"id": "grunt", "group": "HOSTILE", "title": "Grunt · rose ring", "desc": "Basic approaching hostile. Comes in numbers.", "color": VisualProfile.GRUNT},
        {"id": "runner", "group": "HOSTILE", "title": "Runner · orange wedge", "desc": "Fast attacker with wide side-to-side movement.", "color": VisualProfile.RUNNER},
        {"id": "tank", "group": "HOSTILE", "title": "Tank · yellow square", "desc": "Slow armored enemy. Inner diamond marks its shell.", "color": VisualProfile.TANK},
        {"id": "elite", "group": "HOSTILE", "title": "Elite · crimson core", "desc": "High-HP threat. Pale rim; white halo when enraged.", "color": VisualProfile.ELITE},
        {"id": "health", "group": "SIGNALS", "title": "Enemy health", "desc": "Ivory bar shows remaining HP on tanks, elites and damaged foes.", "color": VisualProfile.HEALTH_FILL},
        {"id": "breach", "group": "SIGNALS", "title": "Breach alert", "desc": "Red warning: an enemy crossed the line and damaged your hull.", "color": CRITICAL},
        {"id": "xp", "group": "SIGNALS", "title": "XP · green", "desc": "Green only ever means growth. Kills grant XP directly.", "color": MINT},
        {"id": "formation", "group": "SIGNALS", "title": "Wave warning", "desc": "Orange banner names the active formation; yellow when armored.", "color": WARNING}
    ]


static func color_for(kind: String, formation: String) -> Color:
    match kind:
        KIND_BREACH:
            return CRITICAL
        KIND_ELITE:
            return ELITE
        KIND_INFO:
            return CYAN
    if ARMORED_FORMATIONS.has(formation):
        return SHIELDED
    return WARNING


static func banner(event: String, kind: String, formation: String, hostiles: int) -> String:
    if not event.is_empty():
        # Friendly status lines are not alerts.
        return event if kind == KIND_INFO else "ALERT  •  " + event
    if hostiles <= 0:
        return ""
    return "INCOMING  •  %s  •  %d HOSTILES" % [formation, hostiles]
