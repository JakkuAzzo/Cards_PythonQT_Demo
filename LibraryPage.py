from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QMessageBox, QLabel, QSpacerItem, QSizePolicy
from NavBar import NavBar

class LibraryPage(QWidget):
    def __init__(self):
        super().__init__()
        layout = QGridLayout()
        self.setLayout(layout)
        self.populate_library()
        
    def populate_library(self):
        # Simulate library content
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
        
    title_label = QLabel("Library")
    title_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
    layout.addWidget(title_label, 0, 0, 1, 3)
    # Add spacer at the top to push the title and navigation bar down
    spacer_top = QSpacerItem(20, 40, QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Expanding)
    layout.addItem(spacer_top, 1, 0, 1, 3)
    # Content for Library Page
    for i in range(3):
        for j in range(3):
            library_item = QLabel(f'Library Item {i*3 + j + 1}')
            library_item.setAlignment(Qt.AlignmentFlag.AlignCenter)
            layout.addWidget(library_item, i+2, j)
    self.nav_bar = NavBar()
    layout.addLayout(self.nav_bar, 5, 0, 1, 3)
    self.setLayout(layout)
