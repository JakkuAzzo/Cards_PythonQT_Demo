from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QLabel, QSpacerItem, QSizePolicy
from NavBar import NavBar
from GameWindow import GameWindow  # Add this import

class LibraryPage(QWidget):
    def __init__(self, main_window, home_page):
        super().__init__()
        self.main_window = main_window
        self.home_page = home_page
        self.initUI()

    def initUI(self):
        layout = QGridLayout()
        self.setLayout(layout)
        self.populate_library()

        title_label = QLabel("Library")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label, 0, 0, 1, 3)

        welcome_label = QLabel("Welcome to the Library!")
        welcome_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(welcome_label, 1, 0, 1, 3)

        self.nav_bar = NavBar(self.main_window)
        layout.addWidget(self.nav_bar, 5, 0, 1, 3)

    def populate_library(self):
        for i in range(3):
            for j in range(3):
                library_item = QPushButton(f'Library Item {i*3 + j + 1}')
                library_item.clicked.connect(self.show_game)
                self.layout().addWidget(library_item, i, j)

    def show_popup(self):
        message_box = QMessageBox()
        message_box.setWindowTitle("Library Item Clicked")
        message_box.setText("Details about the selected library item.")
        message_box.exec()

    def show_game(self):
        selected_deck = "Selected Deck Name"  # You'll need to replace this with actual logic to get the selected deck name
        self.home_page.handle_card_deck_selection(selected_deck)
