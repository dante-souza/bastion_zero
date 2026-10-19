class_name EvolutionProfile
extends RefCounted

## Phase F: UI-only evolution tokens; mechanics and catalog stay authoritative.
static func accent(kind: String) -> Color:
    match kind:
        "gun", "gun_payload", "gun_pierce", "gun_ricochet", "gun_volley":
            return Color("#2BD8FF")
        "beam":
            return VisualProfile.PRISM_BEAM
        "volley":
            return VisualProfile.COMET_BODY
        "arc":
            return VisualProfile.ARC_BOLT
        "nova":
            return VisualProfile.NOVA_FIELD
        "hull":
            return Color("#CFF4FF")
        _:
            return Color("#92CDFF")


static func tactical_role(kind: String) -> String:
    match kind:
        "gun": return "SUSTAINED TARGET FIRE"
        "gun_payload": return "KINETIC DAMAGE"
        "gun_pierce": return "ARMOR PENETRATION"
        "gun_ricochet": return "CHAINING PROJECTILES"
        "gun_volley": return "MULTI-TARGET BURST"
        "beam": return "PRECISE ENERGY LANE"
        "volley": return "EXPLOSIVE AREA PRESSURE"
        "arc": return "CHAIN LIGHTNING / CONTROL"
        "nova": return "CROWD CONTROL / AREA"
        "hull": return "DEFENSE / RECOVERY"
        "rate": return "ALL-WEAPON CADENCE"
        "power": return "ALL-WEAPON DAMAGE"
        "reach": return "ALL-WEAPON RANGE"
    return "SYSTEM EVOLUTION"


static func rank_marks(owned: int, cap: int) -> String:
    var marks := ""
    for i in range(cap):
        marks += "●" if i < owned else "○"
    return marks


static func synergy_summary(levels: Dictionary) -> String:
    var combos: Array[String] = []
    if int(levels.get("beam", 0)) > 0 and int(levels.get("arc", 0)) > 0:
        combos.append("PRISM + ARC")
    if int(levels.get("volley", 0)) > 0 and int(levels.get("nova", 0)) > 0:
        combos.append("COMET + NOVA")
    return "   •   ".join(combos) + " ONLINE" if not combos.is_empty() else "EVOLVE WEAPONS TO UNLOCK SYNERGIES"
