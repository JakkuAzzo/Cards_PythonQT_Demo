from PyQt6.QtWidgets import QWidget, QVBoxLayout, QLabel, QSpacerItem
from NavBar import NavBar

class HomePage(QWidget):
    def __init__(self):
        super().__init__()
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

        self.nav_bar = NavBar()
        layout.addWidget(self.nav_bar)

        self.setLayout(layout)
