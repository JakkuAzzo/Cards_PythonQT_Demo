import json
import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ContractTests(unittest.TestCase):
    def test_bundled_game_has_required_contract(self):
        game = json.loads((ROOT / "games/table-talk.game.json").read_text())

        self.assertEqual(game["schemaVersion"], 1)
        self.assertRegex(game["id"], r"^[a-z0-9][a-z0-9-]{2,63}$")
        self.assertLessEqual(game["players"]["minimum"], game["players"]["maximum"])
        self.assertLessEqual(game["players"]["maximum"], 16)
        self.assertEqual(game["capabilities"]["multiplayer"], game["players"]["maximum"] > 1)
        catalog = json.loads((ROOT / "resources/catalog.json").read_text())
        self.assertIn(game["resources"]["tableDesign"], {item["id"] for item in catalog["tableDesigns"]})
        self.assertIn(game["resources"]["cardBack"], {item["id"] for item in catalog["cardBacks"]})
        self.assertIn(game["resources"]["cardSet"], {item["id"] for item in catalog["cardSets"]})
        self.assertIn(game["deck"]["kind"], {"classic", "prompts"})
        self.assertEqual(len({card["id"] for card in game["deck"]["cards"]}), len(game["deck"]["cards"]))
        self.assertTrue(all(card["text"].strip() for card in game["deck"]["cards"]))
        self.assertGreaterEqual(len(game["deck"]["cards"]), game["rules"]["initialHandSize"] * game["players"]["minimum"])
        self.assertRegex(game["presentation"]["accentStartHex"], r"^[0-9A-Fa-f]{6}$")
        self.assertRegex(game["presentation"]["accentEndHex"], r"^[0-9A-Fa-f]{6}$")

    def test_schema_documents_are_valid_json_and_closed_at_root(self):
        for name in ("game-manifest.schema.json", "protocol.schema.json"):
            schema = json.loads((ROOT / name).read_text())
            self.assertEqual(schema["type"], "object")
            self.assertFalse(schema["additionalProperties"])
            self.assertEqual(schema["$schema"], "https://json-schema.org/draft/2020-12/schema")

    def test_protocol_has_private_and_recovery_messages(self):
        schema = json.loads((ROOT / "protocol.schema.json").read_text())
        message_types = set(schema["properties"]["type"]["enum"])
        self.assertTrue({"snapshot", "private-event", "ack", "error"}.issubset(message_types))


if __name__ == "__main__":
    unittest.main()
