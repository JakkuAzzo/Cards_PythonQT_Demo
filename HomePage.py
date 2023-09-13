from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QSpacerItem, QSizePolicy, QPushButton
from NavBar import NavBar
from GameWindow import GameWindow  # Add this import

class HomePage(QWidget):
    def __init__(self, main_window):
        super().__init__()
        self.main_window = main_window
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout()

        # Title Label
        title_label = QLabel("Home Page")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)

        # Add spacer at the top to push the title and navigation bar down
        spacer_top = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
        layout.addItem(spacer_top)

        # Content for Home Page
        self.card_deck_label = QLabel("")  # Label to display card deck logo
        layout.addWidget(self.card_deck_label)

        # Add buttons for Play, Resume, View Stats, Restart, Close Game
        play_button = QPushButton("Play / Resume")
        play_button.clicked.connect(self.show_game_window)

        view_stats_button = QPushButton("View Game Stats")
        view_stats_button.clicked.connect(self.show_game_stats)

        restart_button = QPushButton("Restart")
        restart_button.clicked.connect(self.restart_game)

        close_button = QPushButton("Close Game")
        close_button.clicked.connect(self.close_game)

        layout.addWidget(play_button)
        layout.addWidget(view_stats_button)
        layout.addWidget(restart_button)
        layout.addWidget(close_button)

        self.nav_bar = NavBar(self.main_window)
        layout.addWidget(self.nav_bar)

        self.setLayout(layout)

    def handle_card_deck_selection(self, selected_deck):
        # Update the card deck logo in the center
        # Show the options (Play / Resume, View Game Stats, Restart, Close Game)
        self.card_deck_label.setText(selected_deck)

    def show_game_window(self):
        game_window = GameWindow(self)
        game_window.show()

    def show_game_stats(self):
        pass  # Implement this to display game statistics

    def restart_game(self):
        pass  # Implement this to restart the game

    def close_game(self):
        pass  # Implement this to close the game
