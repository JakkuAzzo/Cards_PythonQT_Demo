from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QSpacerItem, QSizePolicy, QPushButton, QMessageBox
from NavBar import NavBar
from CardPack import CardPack
from GameWindow import GameWindow  # Add this import

class HomePage(QWidget):
    def __init__(self, main_window):
        super().__init__()
        self.main_window = main_window
        self.selected_deck = "No deck selected"
        self.selected_pack_path = None
        self.loaded_pack_path = None
        self.game_window = None
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout()
        layout.setContentsMargins(28, 24, 28, 24)
        layout.setSpacing(12)

        # Title Label
        title_label = QLabel("Cards Home")
        title_label.setObjectName("pageTitle")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)

        subtitle_label = QLabel("Pick a deck from Library, then jump into a session.")
        subtitle_label.setObjectName("pageSubtitle")
        subtitle_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(subtitle_label)

        # Add spacer at the top to push the title and navigation bar down
        spacer_top = QSpacerItem(20, 16, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Fixed)
        layout.addItem(spacer_top)

        # Content for Home Page
        self.card_deck_label = QLabel("No deck selected")
        self.card_deck_label.setObjectName("deckLabel")
        self.card_deck_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.card_deck_label)

        # Add buttons for Play, Resume, View Stats, Restart, Close Game
        play_button = QPushButton("Play / Resume")
        play_button.clicked.connect(self.show_game_window)

        view_stats_button = QPushButton("View Game Stats")
        view_stats_button.setProperty("propertyClass", "secondary")
        view_stats_button.clicked.connect(self.show_game_stats)

        restart_button = QPushButton("Restart")
        restart_button.setProperty("propertyClass", "secondary")
        restart_button.clicked.connect(self.restart_game)

        close_button = QPushButton("Close Game")
        close_button.setProperty("propertyClass", "danger")
        close_button.clicked.connect(self.close_game)

        self.view_stats_button = view_stats_button
        self.restart_button = restart_button
        self.close_button = close_button

        self.view_stats_button.hide()
        self.restart_button.hide()
        self.close_button.hide()

        layout.addWidget(play_button)
        layout.addWidget(view_stats_button)
        layout.addWidget(restart_button)
        layout.addWidget(close_button)

        self.nav_bar = NavBar(self.main_window)
        layout.addWidget(self.nav_bar)

        self.setLayout(layout)

    def handle_card_deck_selection(self, selected_deck, selected_pack_path=None):
        # Update the card deck logo in the center
        # Show the options (Play / Resume, View Game Stats, Restart, Close Game)
        self.selected_deck = selected_deck
        self.selected_pack_path = selected_pack_path
        self.card_deck_label.setText(selected_deck)
        self.view_stats_button.show()
        self.restart_button.show()
        self.close_button.show()

    def show_game_window(self):
        if self.game_window is not None and self.loaded_pack_path != self.selected_pack_path:
            self.game_window.close()
            self.game_window = None
            self.loaded_pack_path = None

        if self.game_window is None:
            pack_logic = None
            if self.selected_pack_path:
                card_pack = CardPack(self.selected_pack_path)
                card_pack.load()
                pack_logic = card_pack.game_logic
                self.card_pack = card_pack
                self.loaded_pack_path = self.selected_pack_path

            self.game_window = GameWindow(self, self.selected_deck, pack_logic)

        self.game_window.play_game()
        self.game_window.show()
        self.game_window.raise_()
        self.game_window.activateWindow()

    def show_game_stats(self):
        if self.game_window is None:
            QMessageBox.information(self, "Game Stats", "No active game session.")
            return

        self.game_window.show_game_stats()

    def restart_game(self):
        if self.game_window is None:
            self.show_game_window()
            return

        self.game_window.restart_game()
        self.game_window.show()

    def close_game(self):
        if self.game_window is None:
            QMessageBox.information(self, "Close Game", "No active game session.")
            return

        self.game_window.close_game()

    def on_game_closed(self):
        self.game_window = None
        self.loaded_pack_path = None
