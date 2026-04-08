import time
from PyQt6.QtGui import QCloseEvent
from PyQt6.QtWidgets import QMainWindow, QLabel, QWidget, QVBoxLayout, QMessageBox

class GameWindow(QMainWindow):
    def __init__(self, home_page, selected_deck="No deck selected", pack_logic_widget=None):
        super().__init__()
        self.home_page = home_page
        self.selected_deck = selected_deck
        self.pack_logic_widget = pack_logic_widget
        self.is_paused = False
        self.started_at = time.time()
        self.resume_count = 0
        self.initUI()

    def initUI(self):
        container = QWidget()
        layout = QVBoxLayout()

        self.deck_label = QLabel(f"Deck: {self.selected_deck}")
        self.status_label = QLabel("Status: Running")
        self.resume_label = QLabel("Resumes: 0")

        layout.addWidget(self.deck_label)
        layout.addWidget(self.status_label)
        layout.addWidget(self.resume_label)

        if self.pack_logic_widget is not None:
            self.pack_logic_widget.setParent(container)
            layout.addWidget(self.pack_logic_widget)

        container.setLayout(layout)
        self.setCentralWidget(container)
        self.setWindowTitle("Game Window")

    def pause_game(self):
        self.is_paused = True
        self.status_label.setText("Status: Paused")

    def play_game(self):
        if self.is_paused:
            self.resume_count += 1
            self.resume_label.setText(f"Resumes: {self.resume_count}")
        self.is_paused = False
        self.status_label.setText("Status: Running")

    def close_game(self):
        self.close()

    def restart_game(self):
        self.started_at = time.time()
        self.is_paused = False
        self.resume_count = 0
        self.status_label.setText("Status: Running")
        self.resume_label.setText("Resumes: 0")

    def show_game_stats(self):
        elapsed = int(time.time() - self.started_at)
        state = "Paused" if self.is_paused else "Running"
        QMessageBox.information(
            self,
            "Game Stats",
            f"Deck: {self.selected_deck}\nState: {state}\nResumes: {self.resume_count}\nElapsed: {elapsed}s",
        )

    def closeEvent(self, event: QCloseEvent):
        self.home_page.on_game_closed()
        super().closeEvent(event)
