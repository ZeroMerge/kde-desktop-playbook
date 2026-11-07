#!/usr/bin/env python3
import sys
import os
import subprocess
from datetime import datetime
from PyQt6.QtCore import Qt, QTimer, QRectF, QPointF, pyqtSlot
from PyQt6.QtGui import QPainter, QColor, QPen, QBrush, QFont, QPainterPath, QIcon, QPixmap
from PyQt6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QPushButton, QSlider
)
from PyQt6.QtDBus import QDBusConnection, QDBusAbstractAdaptor

def create_monochrome_pixmap(svg_path, size=16, color=QColor(220, 220, 220)):
    if not svg_path or not os.path.exists(svg_path):
        pix = QPixmap(size, size)
        pix.fill(Qt.GlobalColor.transparent)
        return pix
    base_pix = QIcon(svg_path).pixmap(size, size)
    colored_pix = QPixmap(size, size)
    colored_pix.fill(Qt.GlobalColor.transparent)
    p = QPainter(colored_pix)
    p.drawPixmap(0, 0, base_pix)
    p.setCompositionMode(QPainter.CompositionMode.CompositionMode_SourceIn)
    p.fillRect(colored_pix.rect(), color)
    p.end()
    return colored_pix


class QuickPopupCard(QWidget):
    """Floating quick-settings card with 0px corners, dock dark mode, and auto-close on mouse leave."""
    def __init__(self, parent=None):
        super().__init__(None)
        self.setObjectName("modern_popup_card")
        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.Tool
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setMouseTracking(True)
        
        self.auto_close_timer = QTimer(self)
        self.auto_close_timer.setSingleShot(True)
        self.auto_close_timer.timeout.connect(self.hide)

        self.layout = QVBoxLayout(self)
        self.layout.setContentsMargins(12, 10, 12, 10)
        self.layout.setSpacing(8)
        
        self.title_lbl = QLabel("")
        title_font = QFont("Inter", 10, QFont.Weight.Bold)
        self.title_lbl.setFont(title_font)
        self.title_lbl.setStyleSheet("color: #FFFFFF; background: transparent;")
        self.layout.addWidget(self.title_lbl)

        self.content_container = QWidget()
        self.content_layout = QVBoxLayout(self.content_container)
        self.content_layout.setContentsMargins(0, 0, 0, 0)
        self.content_layout.setSpacing(8)
        self.layout.addWidget(self.content_container)

    def enterEvent(self, event):
        self.auto_close_timer.stop()

    def leaveEvent(self, event):
        self.auto_close_timer.start(400)

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        w = self.width()
        h = self.height()

        # Pure 0px sharp rectangular frame conforming to dock dark mode (#202224)
        painter.setBrush(QBrush(QColor(32, 34, 36, 252)))
        painter.setPen(QPen(QColor(255, 255, 255, 38), 1.0))
        painter.drawRect(QRectF(0.5, 0.5, w - 1, h - 1))


class SquareIconButton(QPushButton):
    """Square icon button matching dock styling (0px corners, compact 26x26, top rectangular highlight)."""
    def __init__(self, svg_path, tooltip_text, callback=None, parent=None):
        super().__init__(parent)
        self.setFixedSize(26, 26)
        self.setCursor(Qt.CursorShape.PointingHandCursor)
        self.setToolTip(tooltip_text)
        self.svg_path = svg_path
        self.callback = callback
        if callback:
            self.clicked.connect(callback)
            
        self.reload_pixmap()

    def reload_pixmap(self):
        if self.svg_path and os.path.exists(self.svg_path):
            self.pix_normal = create_monochrome_pixmap(self.svg_path, 16, QColor(220, 220, 220))
            self.pix_hover = create_monochrome_pixmap(self.svg_path, 16, QColor(255, 255, 255))
        else:
            self.pix_normal = QPixmap(16, 16)
            self.pix_hover = QPixmap(16, 16)

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        painter.setRenderHint(QPainter.RenderHint.SmoothPixmapTransform)

        w = self.width()
        h = self.height()

        if self.underMouse():
            # 0px body highlight wrap
            body_rect = QRectF(1, 1, w - 2, h - 2)
            painter.setBrush(QBrush(QColor(255, 255, 255, 32)))
            painter.setPen(Qt.PenStyle.NoPen)
            painter.drawRect(body_rect)

            # Top rectangular accent strip (just like dock selected icon indicator)
            strip_rect = QRectF(2, 0.5, w - 4, 2.0)
            painter.setBrush(QBrush(QColor(255, 255, 255, 220)))
            painter.drawRect(strip_rect)
            pix = self.pix_hover
        else:
            pix = self.pix_normal

        px = int((w - pix.width()) / 2)
        py = int((h - pix.height()) / 2)
        painter.drawPixmap(px, py, pix)


class DynamicIslandRightWidget(QWidget):
    def __init__(self):
        super().__init__()
        self.is_expanded = False

        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.Tool
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)

        self.screen_geom = QApplication.primaryScreen().geometry()
        
        # Sized smaller: 32px width, 78px collapsed height, 252px expanded height
        self.island_w = 32
        self.h_collapsed = 78
        self.h_expanded = 252

        self.popup = QuickPopupCard(self)

        self.init_ui()
        self.apply_geometry()

        # D-Bus Registration
        session_bus = QDBusConnection.sessionBus()
        session_bus.registerService("org.modern.DynamicIsland")
        session_bus.registerObject("/Island", self, QDBusConnection.RegisterOption.ExportAllSlots)

        self.update_timer = QTimer(self)
        self.update_timer.timeout.connect(self.update_live_data)
        self.update_timer.start(5000)

    def init_ui(self):
        self.main_layout = QVBoxLayout(self)
        self.main_layout.setContentsMargins(3, 4, 3, 4)
        self.main_layout.setSpacing(3)
        self.main_layout.setAlignment(Qt.AlignmentFlag.AlignBottom | Qt.AlignmentFlag.AlignHCenter)

        icons_dir = "/home/zeromerge/.local/share/icons/Papirus/24x24/symbolic"

        # 1. Expanded Quick Controls Container (Placed on top so drawer grows UPWARD!)
        self.expanded_container = QWidget()
        self.expanded_layout = QVBoxLayout(self.expanded_container)
        self.expanded_layout.setContentsMargins(0, 0, 0, 0)
        self.expanded_layout.setSpacing(3)
        self.expanded_layout.setAlignment(Qt.AlignmentFlag.AlignHCenter)

        settings_path = os.path.join(icons_dir, "categories/preferences-system-symbolic.svg")
        self.settings_btn = SquareIconButton(settings_path, "System Settings", self.open_settings)
        self.expanded_layout.addWidget(self.settings_btn)

        notif_path = os.path.join(icons_dir, "apps/preferences-system-notifications-symbolic.svg")
        self.notif_btn = SquareIconButton(notif_path, "Notifications", self.show_notifications_popup)
        self.expanded_layout.addWidget(self.notif_btn)

        bt_path = os.path.join(icons_dir, "devices/bluetooth-symbolic.svg")
        self.bt_btn = SquareIconButton(bt_path, "Bluetooth", self.show_bluetooth_popup)
        self.expanded_layout.addWidget(self.bt_btn)

        bright_path = os.path.join(icons_dir, "apps/preferences-desktop-display-symbolic.svg")
        self.bright_btn = SquareIconButton(bright_path, "Display Brightness", self.show_brightness_popup)
        self.expanded_layout.addWidget(self.bright_btn)

        vol_path = os.path.join(icons_dir, "apps/multimedia-volume-control-symbolic.svg")
        self.vol_btn = SquareIconButton(vol_path, "Volume Control", self.show_volume_popup)
        self.expanded_layout.addWidget(self.vol_btn)

        time_path = os.path.join(icons_dir, "status/preferences-system-time-symbolic.svg")
        if not os.path.exists(time_path):
            time_path = os.path.join(icons_dir, "apps/preferences-system-time-symbolic.svg")
        self.time_btn = SquareIconButton(time_path, "Date & Time", self.show_time_popup)
        self.expanded_layout.addWidget(self.time_btn)

        self.expanded_container.setVisible(False)
        self.main_layout.addWidget(self.expanded_container)

        # 2. Collapsed Essentials (Wi-Fi and Battery)
        wifi_path = os.path.join(icons_dir, "devices/network-wireless-symbolic.svg")
        self.wifi_btn = SquareIconButton(wifi_path, "Wi-Fi Quick Settings", self.show_wifi_popup)
        self.main_layout.addWidget(self.wifi_btn)

        self.battery_path = os.path.join(icons_dir, "status/battery-100-symbolic.svg")
        self.battery_btn = SquareIconButton(self.battery_path, "Battery & Power", self.show_battery_popup)
        self.main_layout.addWidget(self.battery_btn)

        # 3. Expand / Close Toggle Button (Chevron < when closed, X cancel button when expanded)
        self.toggle_btn = QPushButton()
        self.toggle_btn.setFixedSize(26, 16)
        self.toggle_btn.setCursor(Qt.CursorShape.PointingHandCursor)
        self.toggle_btn.clicked.connect(self.toggle_expanded)
        self.toggle_btn.paintEvent = self.paint_toggle_button
        self.main_layout.addWidget(self.toggle_btn)

        self.update_live_data()

    def paint_toggle_button(self, event):
        painter = QPainter(self.toggle_btn)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        w = self.toggle_btn.width()
        h = self.toggle_btn.height()

        if self.toggle_btn.underMouse():
            painter.setBrush(QBrush(QColor(255, 255, 255, 25)))
            painter.setPen(Qt.PenStyle.NoPen)
            painter.drawRect(QRectF(1, 1, w - 2, h - 2))

        stroke_color = QColor(255, 255, 255, 230 if self.toggle_btn.underMouse() else 170)
        painter.setPen(QPen(stroke_color, 1.4, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap, Qt.PenJoinStyle.RoundJoin))

        cx = w / 2.0
        cy = h / 2.0

        if not self.is_expanded:
            # Simple clean chevron arrow pointing left (<)
            path = QPainterPath()
            path.moveTo(cx + 2.5, cy - 4.0)
            path.lineTo(cx - 2.5, cy)
            path.lineTo(cx + 2.5, cy + 4.0)
            painter.drawPath(path)
        else:
            # Clean X cancel button
            path = QPainterPath()
            path.moveTo(cx - 3.5, cy - 3.5)
            path.lineTo(cx + 3.5, cy + 3.5)
            path.moveTo(cx + 3.5, cy - 3.5)
            path.lineTo(cx - 3.5, cy + 3.5)
            painter.drawPath(path)

    def update_live_data(self):
        try:
            bat_dirs = [d for d in os.listdir('/sys/class/power_supply') if d.startswith('BAT')]
            if bat_dirs:
                bat_dir = os.path.join('/sys/class/power_supply', bat_dirs[0])
                with open(os.path.join(bat_dir, 'capacity')) as f:
                    cap = int(f.read().strip())
                bucket = (cap // 10) * 10
                bucket = max(10, min(100, bucket))
                icons_dir = "/home/zeromerge/.local/share/icons/Papirus/24x24/symbolic/status"
                p = os.path.join(icons_dir, f"battery-level-{bucket}-symbolic.svg")
                if os.path.exists(p):
                    self.battery_btn.svg_path = p
                    self.battery_btn.reload_pixmap()
                    self.battery_btn.setToolTip(f"Battery: {cap}%")
                    self.battery_btn.update()
        except Exception:
            pass

    @pyqtSlot()
    def toggle_expanded(self):
        self.is_expanded = not self.is_expanded
        self.expanded_container.setVisible(self.is_expanded)
        self.toggle_btn.setToolTip("Close (X)" if self.is_expanded else "Expand controls")
        self.toggle_btn.update()
        self.apply_geometry()

    @pyqtSlot()
    def expand(self):
        if not self.is_expanded:
            self.toggle_expanded()

    @pyqtSlot()
    def collapse(self):
        if self.is_expanded:
            self.toggle_expanded()

    def apply_geometry(self):
        h = self.h_expanded if self.is_expanded else self.h_collapsed
        self.setFixedSize(self.island_w, h)
        self.adjustSize()
        self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        w = self.width()
        h = self.height()

        # Strict 0px rectangular frame matching the dock's dark mode surface (#202224)
        painter.setBrush(QBrush(QColor(32, 34, 36, 248)))
        painter.setPen(QPen(QColor(255, 255, 255, 36), 1.0))
        painter.drawRect(QRectF(0.5, 0.5, w - 1, h - 1))

    # Quick Settings Popups
    def position_popup(self, btn):
        btn_pos = btn.mapToGlobal(QPointF(0, 0))
        x = int(btn_pos.x() - self.popup.width() - 8)
        y = int(btn_pos.y() - 10)
        self.popup.move(x, y)
        self.popup.show()
        self.popup.raise_()

    def clear_popup(self):
        while self.popup.content_layout.count():
            item = self.popup.content_layout.takeAt(0)
            widget = item.widget()
            if widget:
                widget.deleteLater()

    def show_volume_popup(self):
        self.clear_popup()
        self.popup.title_lbl.setText("Volume")

        curr_vol = 50
        try:
            res = subprocess.run(["pactl", "get-sink-volume", "@DEFAULT_SINK@"], capture_output=True, text=True)
            for part in res.stdout.split():
                if "%" in part:
                    curr_vol = int(part.replace("%", ""))
                    break
        except Exception:
            pass

        val_lbl = QLabel(f"{curr_vol}%")
        val_lbl.setStyleSheet("color: #EDEDED; font-size: 13px; font-weight: bold;")
        val_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)

        slider = QSlider(Qt.Orientation.Horizontal)
        slider.setRange(0, 100)
        slider.setValue(curr_vol)
        slider.setStyleSheet("""
            QSlider::groove:horizontal { height: 6px; background: rgba(255,255,255,0.2); border-radius: 0px; }
            QSlider::sub-page:horizontal { background: #3DAEE9; border-radius: 0px; }
            QSlider::handle:horizontal { width: 14px; margin-top: -4px; margin-bottom: -4px; background: #FFFFFF; }
        """)

        def set_vol(val):
            val_lbl.setText(f"{val}%")
            subprocess.run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{val}%"], stdout=subprocess.DEVNULL)

        slider.valueChanged.connect(set_vol)

        mute_btn = QPushButton("Mute / Unmute")
        mute_btn.setStyleSheet("background: rgba(255,255,255,0.15); color: #FFF; border-radius: 0px; padding: 4px;")
        mute_btn.clicked.connect(lambda: subprocess.run(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]))

        self.popup.content_layout.addWidget(val_lbl)
        self.popup.content_layout.addWidget(slider)
        self.popup.content_layout.addWidget(mute_btn)
        self.popup.setFixedSize(220, 130)
        self.position_popup(self.vol_btn)

    def show_brightness_popup(self):
        self.clear_popup()
        self.popup.title_lbl.setText("Display Brightness")

        curr_b = 50
        try:
            with open('/sys/class/backlight/intel_backlight/brightness') as f:
                b = int(f.read().strip())
            with open('/sys/class/backlight/intel_backlight/max_brightness') as f:
                mb = int(f.read().strip())
            curr_b = int((b / mb) * 100)
        except Exception:
            pass

        val_lbl = QLabel(f"{curr_b}%")
        val_lbl.setStyleSheet("color: #EDEDED; font-size: 13px; font-weight: bold;")
        val_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)

        slider = QSlider(Qt.Orientation.Horizontal)
        slider.setRange(5, 100)
        slider.setValue(curr_b)
        slider.setStyleSheet("""
            QSlider::groove:horizontal { height: 6px; background: rgba(255,255,255,0.2); border-radius: 0px; }
            QSlider::sub-page:horizontal { background: #F67400; border-radius: 0px; }
            QSlider::handle:horizontal { width: 14px; margin-top: -4px; margin-bottom: -4px; background: #FFFFFF; }
        """)

        def set_bright(val):
            val_lbl.setText(f"{val}%")
            try:
                subprocess.run(["brightnessctl", "set", f"{val}%"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except Exception:
                pass

        slider.valueChanged.connect(set_bright)

        self.popup.content_layout.addWidget(val_lbl)
        self.popup.content_layout.addWidget(slider)
        self.popup.setFixedSize(220, 100)
        self.position_popup(self.bright_btn)

    def show_wifi_popup(self):
        self.clear_popup()
        self.popup.title_lbl.setText("Wi-Fi Networks")

        ssid_lbl = QLabel("Checking connection...")
        ssid_lbl.setStyleSheet("color: #EDEDED; font-size: 11px;")
        self.popup.content_layout.addWidget(ssid_lbl)

        try:
            res = subprocess.run(["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi"], capture_output=True, text=True)
            for line in res.stdout.strip().splitlines()[:4]:
                parts = line.split(":")
                if len(parts) >= 2 and parts[0] == "yes":
                    ssid_lbl.setText(f"Connected: {parts[1]} ({parts[2]}%)")
                    ssid_lbl.setStyleSheet("color: #27AE60; font-size: 11px; font-weight: bold;")
                    break
        except Exception:
            ssid_lbl.setText("Wi-Fi Active")

        toggle_btn = QPushButton("Toggle Wi-Fi")
        toggle_btn.setStyleSheet("background: rgba(255,255,255,0.15); color: #FFF; border-radius: 0px; padding: 4px;")
        toggle_btn.clicked.connect(lambda: subprocess.run(["nmcli", "radio", "wifi"]))
        self.popup.content_layout.addWidget(toggle_btn)

        self.popup.setFixedSize(240, 110)
        self.position_popup(self.wifi_btn)

    def show_bluetooth_popup(self):
        self.clear_popup()
        self.popup.title_lbl.setText("Bluetooth")

        bt_lbl = QLabel("Bluetooth Active")
        bt_lbl.setStyleSheet("color: #EDEDED; font-size: 11px;")
        self.popup.content_layout.addWidget(bt_lbl)

        toggle_btn = QPushButton("Toggle Bluetooth")
        toggle_btn.setStyleSheet("background: rgba(255,255,255,0.15); color: #FFF; border-radius: 0px; padding: 4px;")
        toggle_btn.clicked.connect(lambda: subprocess.run(["bluetoothctl", "power", "toggle"], stdout=subprocess.DEVNULL))
        self.popup.content_layout.addWidget(toggle_btn)

        self.popup.setFixedSize(220, 95)
        self.position_popup(self.bt_btn)

    def show_battery_popup(self):
        self.clear_popup()
        self.popup.title_lbl.setText("Battery & Power")

        cap = 85
        stat = "Discharging"
        try:
            bat_dirs = [d for d in os.listdir('/sys/class/power_supply') if d.startswith('BAT')]
            if bat_dirs:
                bdir = os.path.join('/sys/class/power_supply', bat_dirs[0])
                with open(os.path.join(bdir, 'capacity')) as f:
                    cap = int(f.read().strip())
                with open(os.path.join(bdir, 'status')) as f:
                    stat = f.read().strip()
        except Exception:
            pass

        info_lbl = QLabel(f"{cap}% ({stat})")
        info_lbl.setStyleSheet("color: #27AE60; font-size: 14px; font-weight: bold;")
        info_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.popup.content_layout.addWidget(info_lbl)

        self.popup.setFixedSize(220, 85)
        self.position_popup(self.battery_btn)

    def show_time_popup(self):
        self.clear_popup()
        self.popup.title_lbl.setText("Date & Time")

        now = datetime.now()
        date_lbl = QLabel(now.strftime("%A, %B %d, %Y"))
        date_lbl.setStyleSheet("color: #AAAAAA; font-size: 11px;")
        date_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)

        clock_lbl = QLabel(now.strftime("%H:%M:%S"))
        clock_lbl.setStyleSheet("color: #EDEDED; font-size: 18px; font-weight: bold;")
        clock_lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)

        self.popup.content_layout.addWidget(clock_lbl)
        self.popup.content_layout.addWidget(date_lbl)
        self.popup.setFixedSize(220, 95)
        self.position_popup(self.time_btn)

    def show_notifications_popup(self):
        self.clear_popup()
        self.popup.title_lbl.setText("Notifications")
        lbl = QLabel("No new notifications")
        lbl.setStyleSheet("color: #AAAAAA; font-size: 11px;")
        self.popup.content_layout.addWidget(lbl)
        self.popup.setFixedSize(220, 75)
        self.position_popup(self.notif_btn)

    def open_settings(self):
        subprocess.Popen(["systemsettings"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("modern_dynamic_island")
    app.setDesktopFileName("modern_dynamic_island")
    island = DynamicIslandRightWidget()
    island.setObjectName("modern_dynamic_island")
    island.show()
    sys.exit(app.exec())
