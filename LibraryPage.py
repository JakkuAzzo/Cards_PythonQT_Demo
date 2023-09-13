from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QMessageBox, QLabel, QSpacerItem, QSizePolicy
from NavBar import NavBar

print("running library page")

class LibraryPage(QWidget):
    def __init__(self, main_window):
        super().__init__()
        self.initUI(main_window)

    def initUI(self, main_window):
        layout = QGridLayout()
        self.setLayout(layout)
        self.populate_library()

        title_label = QLabel("Library")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label, 0, 0, 1, 3)

        welcome_label = QLabel("Welcome to the Library!")
        welcome_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(welcome_label, 1, 0, 1, 3)

        # Content for Library Page
        for i in range(3):
            for j in range(3):
                library_item = QLabel(f'Library Item {i*3 + j + 1}')
                library_item.setAlignment(Qt.AlignmentFlag.AlignCenter)
                layout.addWidget(library_item, i+2, j)

        self.nav_bar = NavBar(main_window)
        layout.addWidget(self.nav_bar, 5, 0, 1, 3)

    def populate_library(self):
        for i in range(3):
            for j in range(3):
                library_item = QPushButton(f'Library Item {i*3 + j + 1}')
                library_item.clicked.connect(self.show_popup)
                self.layout().addWidget(library_item, i, j)

    def show_popup(self):
        message_box = QMessageBox()
        message_box.setWindowTitle("Library Item Clicked")
        message_box.setText("Details about the selected library item.")
        message_box.exec()
