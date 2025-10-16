#include <stdarg.h>

#include "libtorrent_settings.h"
#include "libtorrent.h"
#include "libtorrent/settings_pack.hpp"


extern "C" {
TORRENT_EXPORT SettingsPack *SettingsPack_Create() {
    auto inner = new lt::settings_pack(lt::default_settings());
    return reinterpret_cast<SettingsPack *>(inner);
}
TORRENT_EXPORT void SettingsPack_Release(SettingsPack *out) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    delete inner;
}
TORRENT_EXPORT void SettingsPack_SetStr(SettingsPack *out, int name, const char *val) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    inner->set_str(name, val);
}
TORRENT_EXPORT void SettingsPack_SetInt(SettingsPack *out, int name, int val) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    inner->set_int(name, val);
}
TORRENT_EXPORT void SettingsPack_SetBool(SettingsPack *out, int name, bool val) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    inner->set_bool(name, val);
}
TORRENT_EXPORT bool SettingsPack_Has(SettingsPack *out, int name) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    return inner->has_val(name);
}
TORRENT_EXPORT const char *SettingsPack_GetStr(SettingsPack *out, int name) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    return inner->get_str(name).c_str();
}
TORRENT_EXPORT int SettingsPack_GetInt(SettingsPack *out, int name) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    return inner->get_int(name);
}
TORRENT_EXPORT bool SettingsPack_GetBool(SettingsPack *out, int name) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    return inner->get_bool(name);
}
TORRENT_EXPORT void SettingsPack_Clear(SettingsPack *out, int name) {
    auto inner = reinterpret_cast<lt::settings_pack *>(out);
    inner->clear(name);
}
}