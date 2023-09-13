from PyQt6.QtWidgets import QApplication, QMainWindow, QStackedWidget
from HomePage import HomePage
from LibraryPage import LibraryPage
from ShopPage import ShopPage
from NavBar import NavBar

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Cards App")
        self.setGeometry(100, 100, 800, 600)
        
        print("initializing main window")

        self.nav_bar = NavBar(self)

        self.central_widget = QStackedWidget()
        self.setCentralWidget(self.central_widget)

        self.library_page = LibraryPage(self)
        self.home_page = HomePage(self)
        self.shop_page = ShopPage(self)

        self.central_widget.addWidget(self.library_page)
        self.central_widget.addWidget(self.home_page)
        self.central_widget.addWidget(self.shop_page)

        self.current_page = 1

        self.show_current_page()

    def show_current_page(self):
        self.central_widget.setCurrentIndex(self.current_page)

    def show_library(self):
        print("showing library")
        self.current_page = 0
        self.show_current_page()

    def show_shop(self):
        print("showing shop")
        self.current_page = 2
        self.show_current_page()

    def show_home(self):
        print("showing home")
        self.current_page = 1
        self.show_current_page()

if __name__ == "__main__":
    app = QApplication([])
    window = MainWindow()
    window.show()
    app.exec()
