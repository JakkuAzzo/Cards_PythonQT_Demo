from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QWidget, QPushButton, QLabel, QVBoxLayout, QFrame, QMessageBox, QGridLayout
from NavBar import NavBar

print("running shop page")

class ShopPage(QWidget):
    def __init__(self, main_window):
        super().__init__()
        self.initUI(main_window)

    def initUI(self, main_window):
        layout = QVBoxLayout()
        layout.setContentsMargins(28, 24, 28, 24)
        layout.setSpacing(12)
        self.setLayout(layout)

        title_label = QLabel("Card Shop")
        title_label.setObjectName("pageTitle")
        title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title_label)

        welcome_label = QLabel("Explore featured packs and view details before adding to your collection.")
        welcome_label.setObjectName("pageSubtitle")
        welcome_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(welcome_label)

        self.products_container = QWidget()
        self.products_layout = QGridLayout()
        self.products_layout.setContentsMargins(0, 0, 0, 0)
        self.products_layout.setHorizontalSpacing(12)
        self.products_layout.setVerticalSpacing(12)
        self.products_container.setLayout(self.products_layout)
        layout.addWidget(self.products_container)

        self.populate_shop()

        self.nav_bar = NavBar(main_window)
        layout.addWidget(self.nav_bar)

    def populate_shop(self):
        for i in range(3):
            for j in range(3):
                product_frame = QFrame()
                product_frame.setObjectName("shopCard")
                product_layout = QVBoxLayout()
                product_layout.setContentsMargins(14, 14, 14, 14)
                product_layout.setSpacing(10)

                product_label = QLabel(f'Product {i*3 + j + 1}')
                product_label.setObjectName("shopCardTitle")
                view_details_button = QPushButton("View Details")
                view_details_button.setProperty("propertyClass", "secondary")
                view_details_button.clicked.connect(self.show_popup)

                product_layout.addWidget(product_label)
                product_layout.addWidget(view_details_button)
                product_frame.setLayout(product_layout)

                self.products_layout.addWidget(product_frame, i, j)

    def show_popup(self):
        message_box = QMessageBox()
        message_box.setWindowTitle("Product Clicked")
        message_box.setText("Details about the selected product.")
        message_box.exec()
