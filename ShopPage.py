from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QLabel, QVBoxLayout, QFrame, QSpacerItem, QSizePolicy, QMessageBox
from NavBar import NavBar

print("running shop page")

class ShopPage(QWidget):
    def __init__(self, main_window):
        super().__init__()
        self.initUI(main_window)

    def initUI(self, main_window):
        layout = QVBoxLayout()
        self.setLayout(layout)
        self.populate_shop()

        title_label = QLabel("Shop")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)

        welcome_label = QLabel("Welcome to the Shop!")
        welcome_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(welcome_label)

        self.nav_bar = NavBar(main_window)
        layout.addWidget(self.nav_bar)

    def populate_shop(self):
        for i in range(3):
            for j in range(3):
                product_frame = QFrame()
                product_layout = QVBoxLayout()

                product_label = QLabel(f'Product {i*3 + j + 1}')
                view_details_button = QPushButton("View Details")
                view_details_button.clicked.connect(self.show_popup)

                product_layout.addWidget(product_label)
                product_layout.addWidget(view_details_button)
                product_frame.setLayout(product_layout)

                self.layout().addWidget(product_frame)

    def show_popup(self):
        message_box = QMessageBox()
        message_box.setWindowTitle("Product Clicked")
        message_box.setText("Details about the selected product.")
        message_box.exec()
