class CardPack:
    def __init__(self, pack_name):
        self.pack_name = pack_name
        self.analyzer = PackAnalyzer()
        self.game_logic = None

    def load(self):
        if self.analyzer.analyze(self.pack_name):
            self.game_logic = GameLogic()  # Assuming you have a GameLogic class

    def unload(self):
        self.game_logic = None
