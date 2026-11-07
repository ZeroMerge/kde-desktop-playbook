import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)

class MprisPlayer(dbus.service.Object):
    def __init__(self):
        bus_name = dbus.service.BusName('org.mpris.MediaPlayer2.island_demo', bus=dbus.SessionBus())
        super().__init__(bus_name, '/org/mpris/MediaPlayer2')
        self._playback_status = "Playing"
        self._position = 45000000

    @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='ss', out_signature='v')
    def Get(self, interface, prop):
        props = self.GetAll(interface)
        if prop in props:
            return props[prop]
        raise dbus.exceptions.DBusException(f"Unknown property: {prop}", name="org.freedesktop.DBus.Error.UnknownProperty")

    @dbus.service.method('org.freedesktop.DBus.Properties', in_signature='s', out_signature='a{sv}')
    def GetAll(self, interface):
        if interface == 'org.mpris.MediaPlayer2':
            return {
                'CanQuit': dbus.Boolean(False),
                'CanRaise': dbus.Boolean(False),
                'HasTrackList': dbus.Boolean(False),
                'Identity': dbus.String('Dynamic Island Player'),
                'SupportedUriSchemes': dbus.Array([], signature='s'),
                'SupportedMimeTypes': dbus.Array([], signature='s')
            }
        elif interface == 'org.mpris.MediaPlayer2.Player':
            return {
                'PlaybackStatus': dbus.String(self._playback_status),
                'LoopStatus': dbus.String('None'),
                'Rate': dbus.Double(1.0),
                'Shuffle': dbus.Boolean(False),
                'Metadata': dbus.Dictionary({
                    'mpris:trackid': dbus.ObjectPath('/org/mpris/MediaPlayer2/track/1'),
                    'mpris:length': dbus.Int64(230000000),
                    'mpris:artUrl': dbus.String(''),
                    'xesam:title': dbus.String('Blinding Lights'),
                    'xesam:artist': dbus.Array([dbus.String('The Weeknd')], signature='s'),
                    'xesam:album': dbus.String('After Hours')
                }, signature='sv'),
                'Volume': dbus.Double(0.85),
                'Position': dbus.Int64(self._position),
                'MinimumRate': dbus.Double(1.0),
                'MaximumRate': dbus.Double(1.0),
                'CanControl': dbus.Boolean(True),
                'CanPlay': dbus.Boolean(True),
                'CanPause': dbus.Boolean(True),
                'CanSeek': dbus.Boolean(True),
                'CanGoNext': dbus.Boolean(True),
                'CanGoPrevious': dbus.Boolean(True)
            }
        return {}

    @dbus.service.signal('org.freedesktop.DBus.Properties', signature='sa{sv}as')
    def PropertiesChanged(self, interface_name, changed_properties, invalidated_properties):
        pass

    @dbus.service.method('org.mpris.MediaPlayer2.Player')
    def PlayPause(self):
        self._playback_status = "Paused" if self._playback_status == "Playing" else "Playing"
        self.PropertiesChanged('org.mpris.MediaPlayer2.Player', {'PlaybackStatus': dbus.String(self._playback_status)}, [])
        print("PlayPause toggled to:", self._playback_status)

player = MprisPlayer()
print("MPRIS running successfully")
loop = GLib.MainLoop()
loop.run()
