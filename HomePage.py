from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QSpacerItem, QSizePolicy
from NavBar import NavBar

print("running home page")

class HomePage(QWidget):
    def __init__(self, main_window):  # Pass the main_window argument
        super().__init__()
        self.initUI(main_window)

    def initUI(self, main_window):
        layout = QVBoxLayout()

        # Title Label
        title_label = QLabel("Home Page")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)

        # Add spacer at the top to push the title and navigation bar down
        spacer_top = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
        layout.addItem(spacer_top)

        # Content for Home Page
        content_label = QLabel("Welcome to the Home Page!")
        content_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(content_label)

        self.nav_bar = NavBar(main_window)  # Pass the main_window to NavBar
        layout.addWidget(self.nav_bar)

        self.setLayout(layout)
