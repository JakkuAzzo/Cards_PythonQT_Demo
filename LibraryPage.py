from PyQt6.QtCore import Qt, QObject, pyqtSignal
from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QLabel, QFileDialog, QProgressBar, QSpacerItem, QSizePolicy, QFrame
from NavBar import NavBar
from GameWindow import GameWindow
import os
import threading
import time

class LibraryPage(QWidget):
    class Scanner(QObject):
        scan_complete = pyqtSignal()

        def scan(self, card_pack_directories):
            for directory in card_pack_directories:
                if os.path.isdir(directory):
                    # Simulate scanning (you will replace this with your actual scanning logic)
                    time.sleep(1)  # Simulated scan time

                    # Update progress bar
                    self.progress_bar.setValue(self.progress_bar.value() + 1)

            # Emit signal when scanning is complete
            self.scan_complete.emit()

        def __init__(self, progress_bar):
            super().__init__()
            self.progress_bar = progress_bar

        def run(self, card_pack_directories):
            self.scan(card_pack_directories)

    def scan_card_packs(self):
        # Load the list of card pack directories
        with open("Packs/card_packs.txt", "r") as file:  # Updated path to "Packs"
            card_pack_directories = file.readlines()
            card_pack_directories = [directory.strip() for directory in card_pack_directories]

        # Set the progress bar maximum value to the number of card packs
        self.progress_bar.setMaximum(len(card_pack_directories))

        scanner = self.Scanner(self.progress_bar)

        # Connect the signal from the Scanner to a slot in this class
        scanner.scan_complete.connect(self.scanning_complete)

        # Define a function for scanning
        def scan():
            scanner.run(card_pack_directories)

        # Create a separate thread for scanning
        scan_thread = threading.Thread(target=scan)
        scan_thread.start()

    def scanning_complete(self):
        # Scanning is complete, hide progress bar
        self.progress_bar.hide()
        self.scan_label.hide()

    def __init__(self, main_window, home_page):
        super().__init__()
        self.main_window = main_window
        self.home_page = home_page
        self.initUI()

    def initUI(self):
        layout = QGridLayout()
        self.setLayout(layout)

        title_label = QLabel("Library")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label, 0, 0, 1, 3)

        welcome_label = QLabel("Welcome to the Library!")
        welcome_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(welcome_label, 1, 0, 1, 3)

        self.nav_bar = NavBar(self.main_window)
        layout.addWidget(self.nav_bar, 7, 0, 1, 3)

        add_to_library_button = QPushButton("Add to Library")
        add_to_library_button.clicked.connect(self.add_to_library)
        layout.addWidget(add_to_library_button, 2, 0, 1, 3)

        # Add a spacer item for gap between Card Packs and NavBar
        spacer = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
        layout.addItem(spacer, 3, 0, 1, 3)

        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 100)
        layout.addWidget(self.progress_bar, 4, 0, 1, 3)

        self.scan_label = QLabel("Scanning...")
        self.scan_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.scan_label, 5, 0, 1, 3)
        
        # Add a separator label with a border
        separator = QLabel()
        separator.setFrameShape(QFrame.Shape.HLine)
        separator.setFrameShadow(QFrame.Shadow.Sunken)
        layout.addWidget(separator, 6, 0, 1, 3)  # Added the separator

        self.scan_card_packs()

        self.load_card_packs()

    def load_card_packs(self):
        with open("Packs/card_packs.txt", "r") as file:  # Updated path to "Packs"
            card_pack_directories = file.readlines()
            card_pack_directories = [directory.strip() for directory in card_pack_directories]

        row = 6
        col = 0

        for directory in card_pack_directories:
            if os.path.isdir(directory):
                library_item = QPushButton(os.path.basename(directory))
                library_item.clicked.connect(self.show_game)
                self.layout().addWidget(library_item, row, col, 1, 3)

                row += 1

    def show_game(self):
        selected_deck = "Selected Deck Name"
        self.home_page.handle_card_deck_selection(selected_deck)

    def add_to_library(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Card Pack Folder")
        if folder:
            with open("Packs\card_packs.txt", "a") as file:  # Updated path to "Packs"
                file.write(folder + "\n")
                self.load_card_packs()
                self.scan_card_packs()