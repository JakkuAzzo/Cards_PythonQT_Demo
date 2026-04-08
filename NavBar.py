from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QHBoxLayout, QPushButton, QSizePolicy

class NavBar(QWidget):
    def __init__(self, main_window, parent=None):
        super().__init__(parent)
        self.setObjectName("navBar")
        self.setAttribute(Qt.WidgetAttribute.WA_StyledBackground, True)
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        self.setMinimumHeight(56)
        layout = QHBoxLayout()
        layout.setContentsMargins(8, 8, 8, 8)
        layout.setSpacing(8)
        
        print("initializing nav bar")

        self.main_window = main_window

        self.library_button = QPushButton("Library")
        self.library_button.setProperty("propertyClass", "nav")
        self.library_button.clicked.connect(self.main_window.show_library)
        layout.addWidget(self.library_button)
        
        self.home_button = QPushButton("Home")
        self.home_button.setProperty("propertyClass", "nav")
        self.home_button.clicked.connect(self.main_window.show_home)
        layout.addWidget(self.home_button)

        self.shop_button = QPushButton("Shop")
        self.shop_button.setProperty("propertyClass", "nav")
        self.shop_button.clicked.connect(self.main_window.show_shop)
        layout.addWidget(self.shop_button)

        self.setLayout(layout)
