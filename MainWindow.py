print("running main window")

import sys
from PyQt6.QtWidgets import QApplication, QMainWindow, QStackedWidget
from HomePage import HomePage
from LibraryPage import LibraryPage
from ShopPage import ShopPage
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Cards App")
        self.setGeometry(100, 100, 800, 600)

        self.central_widget = QStackedWidget()
        self.setCentralWidget(self.central_widget)

        self.home_page = HomePage()
        self.library_page = LibraryPage()
        self.shop_page = ShopPage()

        self.central_widget.addWidget(self.home_page)
        self.central_widget.addWidget(self.library_page)
        self.central_widget.addWidget(self.shop_page)

        self.current_page = 0  # 0 for Home, 1 for Library, 2 for Shop
        self.show_current_page()

    def show_current_page(self):
        self.central_widget.setCurrentIndex(self.current_page)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())
