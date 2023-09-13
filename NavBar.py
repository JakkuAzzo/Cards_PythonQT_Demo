from PyQt6.QtWidgets import QWidget, QHBoxLayout, QPushButton

class NavBar(QWidget):
    def __init__(self, main_window):
        super().__init__()
        layout = QHBoxLayout()
        
        print("initializing nav bar")

        self.main_window = main_window

        self.library_button = QPushButton("Library")
        self.library_button.clicked.connect(self.main_window.show_library)
        layout.addWidget(self.library_button)
        
        self.home_button = QPushButton("Home")
        self.home_button.clicked.connect(self.main_window.show_home)
        layout.addWidget(self.home_button)

        self.shop_button = QPushButton("Shop")
        self.shop_button.clicked.connect(self.main_window.show_shop)
        layout.addWidget(self.shop_button)

        self.setLayout(layout)
