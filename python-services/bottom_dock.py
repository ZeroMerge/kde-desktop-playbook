#!/usr/bin/env python3
import sys
import os
import subprocess
from PyQt6.QtCore import Qt, QTimer, QRectF, QPointF
from PyQt6.QtGui import QPainter, QColor, QPen, QBrush, QFont, QPainterPath, QIcon, QLinearGradient, QPixmap
from PyQt6.QtWidgets import QApplication, QWidget, QToolTip

class DockItem:
    def __init__(self, name, icon_filename, exec_cmd, check_cmd):
        self.name = name
        self.exec_cmd = exec_cmd
        self.check_cmd = check_cmd
        self.is_running = False
        self.is_focused = False
        
        # Load high-res Papirus icon
        papirus_path = os.path.expanduser(f"~/.local/share/icons/Papirus/48x48/apps/{icon_filename}")
        if os.path.exists(papirus_path):
            self.pixmap = QIcon(papirus_path).pixmap(32, 32)
        else:
            self.pixmap = QIcon.fromTheme(icon_filename.replace('.svg', '')).pixmap(32, 32)

class HorizontalDynamicIslandDock(QWidget):
    def __init__(self):
        super().__init__()
        
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.Tool
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setMouseTracking(True)

        # 7 Core apps using Papirus icons
        self.items = [
            DockItem("App Center", "applications-all.svg", ["krunner"], "krunner"),
            DockItem("Google Chrome", "google-chrome.svg", ["google-chrome-stable"], "chrome"),
            DockItem("Antigravity", "antigravity.svg", ["/opt/antigravity/antigravity"], "antigravity"),
            DockItem("VS Code", "visual-studio-code.svg", ["code"], "code"),
            DockItem("Files", "system-file-manager.svg", ["dolphin"], "dolphin"),
            DockItem("Terminal", "utilities-terminal.svg", ["konsole"], "konsole"),
            DockItem("System Settings", "preferences-system.svg", ["systemsettings"], "systemsettings")
        ]

        # Geometry specs
        self.item_w = 46
        self.item_h = 44
        self.item_padding = 4
        self.dock_padding_h = 8
        self.dock_padding_v = 3

        self.full_w = self.dock_padding_h * 2 + (len(self.items) * self.item_w) + ((len(self.items) - 1) * self.item_padding)
        self.full_h = 50

        self.collapsed_w = 140
        self.collapsed_h = 6

        # State
        self.is_open = True
        self.is_locked = False
        self.hover_index = -1

        # Collapse grace timer (300ms)
        self.collapse_timer = QTimer(self)
        self.collapse_timer.setSingleShot(True)
        self.collapse_timer.timeout.connect(self.do_collapse)

        # Process monitor timer (check running apps every 2s)
        self.proc_timer = QTimer(self)
        self.proc_timer.timeout.connect(self.check_running_processes)
        self.proc_timer.start(2000)
        self.check_running_processes()

        self.apply_size()

    def check_running_processes(self):
        for item in self.items:
            try:
                res = subprocess.run(["pgrep", "-f", item.check_cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                item.is_running = (res.returncode == 0)
            except Exception:
                item.is_running = False
        self.update()

    def apply_size(self):
        w = self.full_w if self.is_open else self.collapsed_w
        h = self.full_h if self.is_open else self.collapsed_h
        self.setFixedSize(w, h)
        self.adjustSize()
        self.update()

    def expand_dock(self):
        self.collapse_timer.stop()
        if not self.is_open:
            self.is_open = True
            self.apply_size()

    def do_collapse(self):
        if not self.is_locked and self.is_open:
            self.is_open = False
            self.hover_index = -1
            self.apply_size()

    def enterEvent(self, event):
        self.expand_dock()

    def leaveEvent(self, event):
        self.hover_index = -1
        self.update()
        if not self.is_locked:
            self.collapse_timer.start(300)

    def mouseMoveEvent(self, event):
        if not self.is_open:
            self.expand_dock()
            return

        pos = event.position()
        x = pos.x()
        y = pos.y()

        new_hover = -1
        cur_x = self.dock_padding_h
        for i, item in enumerate(self.items):
            if cur_x <= x <= (cur_x + self.item_w) and 2 <= y <= (self.height() - 4):
                new_hover = i
                break
            cur_x += self.item_w + self.item_padding

        if new_hover != self.hover_index:
            self.hover_index = new_hover
            if self.hover_index >= 0:
                QToolTip.showText(self.mapToGlobal(event.position().toPoint()), self.items[self.hover_index].name, self)
            else:
                QToolTip.hideText()
            self.update()

    def mousePressEvent(self, event):
        if event.button() != Qt.MouseButton.LeftButton:
            return

        # If clicked while collapsed, expand and lock open
        if not self.is_open:
            self.is_locked = True
            self.expand_dock()
            return

        click_x = event.position().x()
        click_y = event.position().y()

        # Check if clicked on the bottom thin strip handle to toggle lock
        if click_y >= (self.height() - 7):
            self.is_locked = not self.is_locked
            self.update()
            return

        # Check which app was clicked
        cur_x = self.dock_padding_h
        for item in self.items:
            if cur_x <= click_x <= (cur_x + self.item_w) and 2 <= click_y <= (self.height() - 6):
                subprocess.Popen(item.exec_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                break
            cur_x += self.item_w + self.item_padding

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)

        w = self.width()
        h = self.height()

        # 1. Collapsed Mode: Clean Thin Strip at bottom of desktop
        if not self.is_open:
            # Subtle dark glass capsule
            bg_path = QPainterPath()
            bg_path.addRoundedRect(QRectF(0.5, 0.5, w - 1, h - 1), 2.0, 2.0)
            painter.setBrush(QBrush(QColor(20, 22, 28, 230)))
            painter.setPen(QPen(QColor(255, 255, 255, 45), 0.8))
            painter.drawPath(bg_path)

            # Elegant thin strip line
            strip_path = QPainterPath()
            strip_path.addRoundedRect(QRectF(10, 1.5, w - 20, 2.5), 1.0, 1.0)
            painter.setBrush(QBrush(QColor(255, 255, 255, 180)))
            painter.setPen(Qt.PenStyle.NoPen)
            painter.drawPath(strip_path)
            return

        # 2. Open Mode: Horizontal Dynamic Island with 2px Rounded Corners
        dock_path = QPainterPath()
        dock_path.addRoundedRect(QRectF(0.5, 0.5, w - 1, h - 1), 2.0, 2.0)

        # Dark frosted glass gradient
        gradient = QLinearGradient(0, 0, 0, h)
        gradient.setColorAt(0.0, QColor(20, 22, 28, 240))
        gradient.setColorAt(1.0, QColor(14, 15, 19, 248))

        painter.setBrush(QBrush(gradient))
        painter.setPen(QPen(QColor(255, 255, 255, 36), 1.0))
        painter.drawPath(dock_path)

        # 3. Paint Icons with 5px Highlight Wrap, Top Thin Strip, and Dash Line
        cur_x = self.dock_padding_h
        for i, item in enumerate(self.items):
            is_hovered = (i == self.hover_index)
            is_active_highlight = is_hovered or (item.is_running and item.is_focused)

            item_rect = QRectF(cur_x, 3, self.item_w, self.item_h - 2)

            # Highlighted body wrap (4px - 7px, using 5px)
            if is_hovered:
                painter.setBrush(QBrush(QColor(255, 255, 255, 30)))
                painter.setPen(QPen(QColor(255, 255, 255, 40), 0.8))
                painter.drawRoundedRect(item_rect, 5.0, 5.0)

                # Thin strip at the top of the highlighted icon
                top_strip = QRectF(cur_x + 5, 3, self.item_w - 10, 2.0)
                painter.setBrush(QBrush(QColor(255, 255, 255, 210)))
                painter.setPen(Qt.PenStyle.NoPen)
                painter.drawRoundedRect(top_strip, 1.0, 1.0)
            elif item.is_running:
                # Subtle ambient wrap for running apps
                painter.setBrush(QBrush(QColor(255, 255, 255, 14)))
                painter.setPen(Qt.PenStyle.NoPen)
                painter.drawRoundedRect(item_rect, 5.0, 5.0)

            # Draw Papirus Icon (32x32)
            icon_x = cur_x + int((self.item_w - 32) / 2)
            icon_y = 6
            painter.drawPixmap(icon_x, icon_y, item.pixmap)

            # Running indicator: Small dash line underneath (not a circle!)
            if item.is_running:
                dash_w = 16.0
                dash_h = 2.0
                dash_x = cur_x + ((self.item_w - dash_w) / 2.0)
                dash_y = h - 6.0
                dash_rect = QRectF(dash_x, dash_y, dash_w, dash_h)

                painter.setBrush(QBrush(QColor(240, 240, 240, 230)))
                painter.setPen(Qt.PenStyle.NoPen)
                painter.drawRoundedRect(dash_rect, 1.0, 1.0)

            cur_x += self.item_w + self.item_padding

        # 4. Thin Strip Handle at the bottom center of the dock
        strip_w = 46.0
        strip_h = 2.0
        strip_x = (w - strip_w) / 2.0
        strip_y = h - 2.8
        
        # When locked: bright indicator; when unlocked: subtle indicator
        strip_alpha = 180 if self.is_locked else 55
        painter.setBrush(QBrush(QColor(255, 255, 255, strip_alpha)))
        painter.setPen(Qt.PenStyle.NoPen)
        painter.drawRoundedRect(QRectF(strip_x, strip_y, strip_w, strip_h), 1.0, 1.0)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("modern_bottom_dock")
    app.setDesktopFileName("modern_bottom_dock")
    dock = HorizontalDynamicIslandDock()
    dock.setObjectName("modern_bottom_dock")
    dock.show()
    sys.exit(app.exec())
