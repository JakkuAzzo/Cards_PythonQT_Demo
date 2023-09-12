from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QLabel, QVBoxLayout, QFrame, QSpacerItem, QSizePolicy
from NavBar import NavBar

class ShopPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QVBoxLayout()
        
        self.setLayout(layout)
        self.populate_shop()

    def populate_shop(self):
        # Simulate shop content
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
        
    title_label = QLabel("Shop")
    title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
    layout.addWidget(title_label)
    
    # Add spacer at the top to push the title and navigation bar down
    spacer_top = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
    layout.addItem(spacer_top)
    
    # Content for Shop Page
    for i in range(3):
        for j in range(3):
            product_label = QLabel(f'Product {i*3 + j + 1}')
            product_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            layout.addWidget(product_label)
            
    self.nav_bar = NavBar()
    layout.addWidget(self.nav_bar)
    
    self.setLayout(layout)  
