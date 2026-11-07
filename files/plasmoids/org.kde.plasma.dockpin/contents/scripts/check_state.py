import dbus
import sys

try:
    bus = dbus.SessionBus()
    obj = bus.get_object("org.kde.plasmashell", "/PlasmaShell")
    iface = dbus.Interface(obj, "org.kde.PlasmaShell")
    res = iface.evaluateScript("print(panelById(80).hiding);")
    sys.stdout.write(res.strip())
except Exception as e:
    sys.stdout.write("dodgewindows")
