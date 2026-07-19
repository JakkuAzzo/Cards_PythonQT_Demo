import json
import pathlib
import re
import unittest


ROOT = pathlib.Path(__file__).resolve().parents[1]


class ContractTests(unittest.TestCase):
    def test_bundled_games_have_required_contracts(self):
        catalog = json.loads((ROOT / "resources/catalog.json").read_text())
        table_ids = {item["id"] for item in catalog["tableDesigns"]}
        card_back_ids = {item["id"] for item in catalog["cardBacks"]}
        card_set_ids = {item["id"] for item in catalog["cardSets"]}
        for game_file in sorted((ROOT / "games").glob("*.game.json")):
            with self.subTest(game=game_file.name):
                self.assert_bundled_game_contract(json.loads(game_file.read_text()), table_ids, card_back_ids, card_set_ids)

    def assert_bundled_game_contract(self, game, table_ids, card_back_ids, card_set_ids):

        self.assertEqual(game["schemaVersion"], 1)
        self.assertRegex(game["id"], r"^[a-z0-9][a-z0-9-]{2,63}$")
        self.assertLessEqual(game["players"]["minimum"], game["players"]["maximum"])
        self.assertLessEqual(game["players"]["maximum"], 16)
        self.assertEqual(game["capabilities"]["multiplayer"], game["players"]["maximum"] > 1)
        self.assertIn(game["resources"]["tableDesign"], table_ids)
        self.assertIn(game["resources"]["cardBack"], card_back_ids)
        self.assertIn(game["resources"]["cardSet"], card_set_ids)
        self.assertIn(game["deck"]["kind"], {"classic", "prompts", "characters"})
        self.assertEqual(len({card["id"] for card in game["deck"]["cards"]}), len(game["deck"]["cards"]))
        self.assertTrue(all(card["text"].strip() for card in game["deck"]["cards"]))
        effective_deck_count = 52 if game["deck"]["kind"] == "classic" and not game["deck"]["cards"] else len(game["deck"]["cards"])
        self.assertGreaterEqual(effective_deck_count, game["rules"]["initialHandSize"] * game["players"]["minimum"])
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

    def test_classic_pack_assets_and_templates_are_allowlisted(self):
        catalog = json.loads((ROOT / "resources/catalog.json").read_text())
        repository_root = ROOT.parent
        classic_set = next(item for item in catalog["cardSets"] if item["id"] == "classic-pack-52")
        classic_back = next(item for item in catalog["cardBacks"] if item["id"] == "classic-pack-red")
        self.assertTrue((repository_root / classic_set["asset"]).is_dir())
        self.assertTrue((repository_root / classic_back["asset"]).is_file())
        table_ids = {item["id"] for item in catalog["tableDesigns"]}
        self.assertEqual({template["id"] for template in catalog["templates"]}, {"poker-holdem", "guess-who-board", "prompt-table"})
        self.assertTrue(all(template["tableDesign"] in table_ids for template in catalog["templates"]))
        self.assertTrue(all(template["digitalModes"] == ["combined", "table", "deck"] for template in catalog["templates"]))


if __name__ == "__main__":
    unittest.main()
