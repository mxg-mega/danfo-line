## Driver roster for Danfo Line. Bios are the writer's own voice; keep them as written.
## Stats (fight_power, top_speed, lane_switch, full_handling) are roster flavour data —
## not yet mapped to BusBase physics. Perks/flaws are displayed on the select screen only.
class_name Drivers
extends RefCounted

const ROSTER: Array[Dictionary] = [
	{
		"id": "tunde",
		"name": "Tunde",
		"accent": Color("2EF2FF"),
		"bio": "Father of five. Lives in Lagos Island. His wife sells ewa agoyin. Owns his bus. A bus in his own right. Needs money to pay his kids' fees and faaji on Friday nights. Didn't go to formal school, but has graduated from the streets.",
		"fight_power": 6, "top_speed": 6, "lane_switch": 5, "full_handling": 4,
		"perk": "My bus, my money: no daily remittance, keeps 100% of fare.",
		"flaw": "Old faithful: slow acceleration once the bus is over half full.",
		"remittance": 0,
		"portrait": "res://src/assets/characters/tunde_portrait.png",
	},
	{
		"id": "omo_igbo",
		"name": "Omo Igbo",
		"accent": Color("7CFF4F"),
		"bio": "Young man. Agile and lives in Mowe. Likes only Igbo women, but hasn't married any yet. Still has to remit daily to the bus's owner. Has plans to own a fleet so he's always driving.",
		"fight_power": 8, "top_speed": 7, "lane_switch": 9, "full_handling": 6,
		"perk": "Agile: fastest lane switch in the game.",
		"flaw": "Oga's money first: the first 5,000 naira goes to remittance.",
		"remittance": 5000,
		"portrait": "res://src/assets/characters/omo_igbo_portrait.png",
	},
	{
		"id": "ble_ble",
		"name": "Ble-Ble",
		"accent": Color("FF3DB8"),
		"bio": "Short for Blessings from Benin. The famous danfo driver known across Ikeja. Her mantra? What a man can do a woman can do better. Lives in Mile 12, is the first daughter and provides for everyone except herself.",
		"fight_power": 7, "top_speed": 7, "lane_switch": 7, "full_handling": 7,
		"perk": "Known across Ikeja: fare-skippers appear half as often.",
		"flaw": "Them no like am: rival drivers cut her off more often.",
		"remittance": 0,
		"portrait": "res://src/assets/characters/ble_ble_portrait.png",
	},
	{
		"id": "mo",
		"name": "Mo",
		"accent": Color("B66BFF"),
		"bio": "Proper Lagos boy. Everyone knows Mo and Mo knows everything. If you're ever in a jam, a phone call to Mo and you're out in no time. Lives everywhere and has no last known address.",
		"fight_power": 9, "top_speed": 8, "lane_switch": 7, "full_handling": 3,
		"perk": "Call Mo: once per run, clear a checkpoint or agbero instantly.",
		"flaw": "Rented rickety: worst handling when the bus is full.",
		"remittance": 0,
		"portrait": "res://src/assets/characters/mo_portrait.png",
	},
]

static func by_id(id: String) -> Dictionary:
	for d: Dictionary in ROSTER:
		if d.id == id:
			return d
	return {}