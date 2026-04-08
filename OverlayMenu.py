from PyQt6.QtWidgets import QWidget, QPushButton, QVBoxLayout

class OverlayMenu(QWidget):
    def __init__(self, game_logic):
        super().__init__()
        self.game_logic = game_logic
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout()
        self.setLayout(layout)

        play_button = QPushButton("Play")
        play_button.clicked.connect(self.play)
        layout.addWidget(play_button)

        # Add more buttons (Pause, Close, Restart) as needed

    def play(self):
        self.game_logic.show()
