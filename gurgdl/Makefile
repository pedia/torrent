all: macos/Framworks/libtorrentc.dylib

dmg:
	hdiutil create -volname ShawnDownloader \
	-srcfolder build/macos/Build/Products/Debug/shawndown.app \
	-ov -format UDZO shawn.dmg

macos/Framworks/libtorrentc.dylib:
	ln -s ../../../libtorrent/bindings/c/dist/debug/libtorrentc.dylib macos/Framworks/libtorrentc.dylib
