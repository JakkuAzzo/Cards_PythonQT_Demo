from PyQt6.QtWidgets import QWidget, QHBoxLayout, QPushButton

print("running nav bar")
class NavBar(QWidget):
    def __init__(self):
        super().__init__()
        layout = QHBoxLayout()
        left_arrow_button = QPushButton("← Library")
        center_button = QPushButton("Home")
        right_arrow_button = QPushButton("Shop →")
        layout.addWidget(left_arrow_button)
        layout.addWidget(center_button)
        layout.addWidget(right_arrow_button)
        self.setLayout(layout)
