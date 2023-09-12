from PyQt6.QtWidgets import QWidget, QGridLayout, QPushButton, QMessageBox

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
