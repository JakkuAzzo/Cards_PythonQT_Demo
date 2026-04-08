from PyQt6.QtCore import Qt, QObject, pyqtSignal
from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QLabel, QFileDialog, QProgressBar, QSpacerItem, QSizePolicy, QFrame
from NavBar import NavBar
from GameWindow import GameWindow
import os
import threading
import time


PACKS_FILE = os.path.join("Packs", "card_packs.txt")
LEGACY_PACKS_FILE = "Packs\\card_packs.txt"

class LibraryPage(QWidget):
    class Scanner(QObject):
        scan_progress = pyqtSignal(int)
        scan_complete = pyqtSignal()

        def scan(self, card_pack_directories):
            scanned_count = 0
            for directory in card_pack_directories:
                if os.path.isdir(directory):
                    # Simulate scanning (you will replace this with your actual scanning logic)
                    time.sleep(1)  # Simulated scan time
                    scanned_count += 1
                    self.scan_progress.emit(scanned_count)

            # Emit signal when scanning is complete
            self.scan_complete.emit()

        def __init__(self):
            super().__init__()

        def run(self, card_pack_directories):
            self.scan(card_pack_directories)

    def scan_card_packs(self):
        if self.scan_thread is not None and self.scan_thread.is_alive():
            return

        # Load the list of card pack directories
        card_pack_directories = self.read_card_pack_directories()

        # Set the progress bar maximum value to the number of card packs
        self.progress_bar.setMaximum(len(card_pack_directories))
        self.progress_bar.setValue(0)
        self.progress_bar.show()
        self.scan_label.show()

        self.scanner = self.Scanner()

        # Connect the signal from the Scanner to a slot in this class
        self.scanner.scan_progress.connect(self.on_scan_progress)
        self.scanner.scan_complete.connect(self.scanning_complete)

        # Define a function for scanning
        def scan():
            self.scanner.run(card_pack_directories)

        # Create a separate thread for scanning
        self.scan_thread = threading.Thread(target=scan, daemon=True)
        self.scan_thread.start()

    def on_scan_progress(self, value):
        self.progress_bar.setValue(value)

    def scanning_complete(self):
        # Scanning is complete, hide progress bar
        self.progress_bar.hide()
        self.scan_label.hide()

    def __init__(self, main_window, home_page):
        super().__init__()
        self.main_window = main_window
        self.home_page = home_page
        self.library_items = []
        self.pack_name_by_button = {}
        self.pack_path_by_button = {}
        self.scanner = None
        self.scan_thread = None
        self.initUI()

    def initUI(self):
        layout = QGridLayout()
        layout.setContentsMargins(28, 24, 28, 24)
        layout.setHorizontalSpacing(12)
        layout.setVerticalSpacing(10)
        self.setLayout(layout)

        title_label = QLabel("Deck Library")
        title_label.setObjectName("pageTitle")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label, 0, 0, 1, 3)

        welcome_label = QLabel("Manage your local packs and choose what to play.")
        welcome_label.setObjectName("pageSubtitle")
        welcome_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(welcome_label, 1, 0, 1, 3)

        add_to_library_button = QPushButton("Add to Library")
        add_to_library_button.setProperty("propertyClass", "secondary")
        add_to_library_button.clicked.connect(self.add_to_library)
        layout.addWidget(add_to_library_button, 2, 0, 1, 3)

        packs_label = QLabel("Available Packs")
        packs_label.setObjectName("pageSubtitle")
        packs_label.setAlignment(Qt.AlignmentFlag.AlignLeft)
        layout.addWidget(packs_label, 3, 0, 1, 3)

        self.nav_bar = NavBar(self.main_window)

        self.progress_bar = QProgressBar()
        self.progress_bar.setRange(0, 100)
        layout.addWidget(self.progress_bar, 5, 0, 1, 3)

        self.scan_label = QLabel("Scanning...")
        self.scan_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(self.scan_label, 6, 0, 1, 3)
        
        # Add a separator label with a border
        separator = QLabel()
        separator.setFrameShape(QFrame.Shape.HLine)
        separator.setFrameShadow(QFrame.Shadow.Sunken)
        layout.addWidget(separator, 7, 0, 1, 3)  # Added the separator

        layout.addWidget(self.nav_bar, 8, 0, 1, 3)

        self.migrate_legacy_card_pack_file()
        self.scan_card_packs()

        self.load_card_packs()

    def migrate_legacy_card_pack_file(self):
        if not os.path.exists(LEGACY_PACKS_FILE):
            return

        legacy_dirs = self.read_card_pack_directories(LEGACY_PACKS_FILE)
        if not legacy_dirs:
            return

        current_dirs = set(self.read_card_pack_directories(PACKS_FILE))
        missing = [directory for directory in legacy_dirs if directory not in current_dirs]
        if not missing:
            return

        with open(PACKS_FILE, "a") as file:
            for directory in missing:
                file.write(directory + "\n")

    def read_card_pack_directories(self, path=PACKS_FILE):
        if not os.path.exists(path):
            return []

        with open(path, "r") as file:
            directories = [directory.strip() for directory in file.readlines()]

        return [directory for directory in directories if directory]

    def load_card_packs(self):
        for item in self.library_items:
            self.layout().removeWidget(item)
            item.deleteLater()
        self.library_items.clear()
        self.pack_name_by_button.clear()
        self.pack_path_by_button.clear()

        card_pack_directories = self.read_card_pack_directories()

        row = 4
        col = 0

        for directory in card_pack_directories:
            if os.path.isdir(directory):
                library_item = QPushButton(os.path.basename(directory))
                library_item.setProperty("propertyClass", "secondary")
                library_item.clicked.connect(self.show_game)
                self.layout().addWidget(library_item, row, col, 1, 3)
                self.library_items.append(library_item)
                self.pack_name_by_button[library_item] = os.path.basename(directory)
                self.pack_path_by_button[library_item] = directory

                row += 1

    def show_game(self):
        button = self.sender()
        selected_deck = self.pack_name_by_button.get(button, "Selected Deck")
        selected_pack_path = self.pack_path_by_button.get(button)
        if self.home_page is not None:
            self.home_page.handle_card_deck_selection(selected_deck, selected_pack_path)
            self.main_window.show_home()

    def add_to_library(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Card Pack Folder")
        if folder:
            existing = set(self.read_card_pack_directories())
            if folder not in existing:
                with open(PACKS_FILE, "a") as file:
                    file.write(folder + "\n")

            self.load_card_packs()
            self.scan_card_packs()