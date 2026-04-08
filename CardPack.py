from GameLogic import GameLogic
from PackAnalyzer import PackAnalyzer


class CardPack:
    def __init__(self, pack_path):
        self.pack_path = pack_path
        self.analyzer = PackAnalyzer()
        self.game_logic = None
        self.metadata = None

    def load(self):
        self.metadata = self.analyzer.analyze(self.pack_path)
        self.game_logic = GameLogic(self.metadata)

    def unload(self):
        self.game_logic = None
        self.metadata = None
