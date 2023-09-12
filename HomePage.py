from PyQt6.QtWidgets import QWidget, QVBoxLayout, QSpacerItem, QSizePolicy
from NavBar import NavBar

class HomePage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        spacer_top = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
        layout.addItem(spacer_top)
        self.nav_bar = NavBar()
        layout.addWidget(self.nav_bar)
        
        self.setLayout(layout)
