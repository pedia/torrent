/*

Copyright (c) 2020-2021, Arvid Norberg
All rights reserved.

You may use, distribute and modify this code under the terms of the BSD license,
see LICENSE file.
*/
#include <iostream>
#include <fstream>
#include <vector>

#include <stdarg.h>

#include "libtorrent.h"

#include "libtorrent/session.hpp"
#include "libtorrent/magnet_uri.hpp"
#include "libtorrent/torrent_handle.hpp"
#include "libtorrent/read_resume_data.hpp"
#include "libtorrent/write_resume_data.hpp"
#include "libtorrent/session_stats.hpp"
#include "libtorrent/alert_types.hpp"
#include "libtorrent/hex.hpp"
#include "libtorrent/span.hpp"

#ifdef LIBTORRENT_C_EXPORT
#error "erere"
#endif

namespace {

std::vector<lt::torrent_handle> handles;
std::vector<int> free_handle_slots;

int find_handle(lt::torrent_handle h)
{
	std::vector<lt::torrent_handle>::const_iterator i
		= std::find(handles.begin(), handles.end(), h);
	if (i == handles.end()) return -1;
	return i - handles.begin();
}

lt::torrent_handle get_handle(int i)
{
	if (i < 0 || i >= int(handles.size())) return lt::torrent_handle();
	return handles[i];
}

int add_handle(lt::torrent_handle const& h)
{
	// re-add, find duplicated
	std::vector<lt::torrent_handle>::iterator i = std::find_if(handles.begin()
		, handles.end()
		, [&h](lt::torrent_handle const& v) { return !v.is_valid() && v.id() == h.id(); });
	if (i != handles.end())
	{
		*i = h;
		return i - handles.begin();
	}

	if (free_handle_slots.empty())
	{
		handles.push_back(h);
		return handles.size() - 1;
	}

	int const ret = free_handle_slots.back();
	free_handle_slots.pop_back();
	handles[ret] = h;
	return ret;
}

void remove_handle(int const h)
{
	handles[h] = lt::torrent_handle{};
	if (h == int(handles.size() - 1))
	{
		handles.pop_back();
	}
	else
	{
		auto i = std::find(free_handle_slots.begin(), free_handle_slots.end(), h);
		if (i == free_handle_slots.end())
		{
			free_handle_slots.push_back(h);
		}
	}
}

int set_int_value(void* dst, int* size, int val)
{
	if (*size < int(sizeof(int))) return -2;
	std::memcpy(dst, &val, sizeof(int));
	*size = sizeof(int);
	return 0;
}

int set_str_value(void* dst, int* size, std::string val)
{
	if (*size <= static_cast<int>(val.size())) return -2;
	std::memcpy(dst, val.c_str(), val.size() + 1);
	*size = val.size() + 1;
	return 0;
}

bool load_file(std::string const& filename, std::vector<char>& v
	, int limit = 8000000)
{
	std::fstream f(filename, std::ios_base::in | std::ios_base::binary);
	f.seekg(0, std::ios_base::end);
	auto const s = f.tellg();
	if (s > limit || s < 0) return false;
	f.seekg(0, std::ios_base::beg);
	v.resize(static_cast<std::size_t>(s));
	if (s == std::fstream::pos_type(0)) return !f.fail();
	f.read(v.data(), int(v.size()));
	return !f.fail();
}

int save_file(std::string const& filename, std::vector<char> const& v)
{
	std::fstream f(filename, std::ios_base::trunc | std::ios_base::out | std::ios_base::binary);
	f.write(v.data(), int(v.size()));
	return !f.fail();
}

lt::add_torrent_params make_add_torrent_params(int tag, va_list lp)
{
	lt::add_torrent_params params;

	char const* torrent_data = nullptr;
	int torrent_size = 0;

	char const* resume_data = nullptr;
	int resume_size = 0;

	lt::error_code ec;
	while (tag != TAG_END)
	{
		switch (tag)
		{
			case TOR_FILENAME:
				params.ti = std::make_shared<lt::torrent_info>(va_arg(lp, char const*), ec);
				break;
			case TOR_TORRENT:
				torrent_data = va_arg(lp, char const*);
				break;
			case TOR_TORRENT_SIZE:
				torrent_size = va_arg(lp, int);
				break;
			case TOR_INFOHASH:
				params.info_hashes.v1 = lt::sha1_hash(va_arg(lp, char const*));
				break;
			// TODO: add an info-hash-v2 field too
			case TOR_MAGNETLINK:
				parse_magnet_uri(va_arg(lp, char const*), params, ec);
				break;
			case TOR_TRACKER_URL:
				params.trackers.push_back(va_arg(lp, char const*));
				break;
			case TOR_RESUME_DATA:
				resume_data = va_arg(lp, char const*);
				if (resume_data && resume_size)
					params = lt::read_resume_data({resume_data, resume_size});
				break;
			case TOR_RESUME_DATA_SIZE:
				resume_size = va_arg(lp, int);
				if (resume_data && resume_size)
					params = lt::read_resume_data({resume_data, resume_size});
				break;
			case TOR_SAVE_PATH:
				params.save_path = va_arg(lp, char const*);
				break;
			case TOR_NAME:
				params.name = va_arg(lp, char const*);
				break;
			case TOR_FLAGS:
				params.flags = lt::torrent_flags_t(va_arg(lp, int));
				break;
			case TOR_USER_DATA:
				params.userdata = va_arg(lp, char*);
				break;
			case TOR_STORAGE_MODE:
				params.storage_mode = static_cast<lt::storage_mode_t>(va_arg(lp, int));
				break;
			default:
				// ignore unknown tags
				va_arg(lp, void*);
				break;
		}

		tag = va_arg(lp, int);
	}
	va_end(lp);

	if (!params.ti && torrent_data && torrent_size)
		params.ti = std::make_shared<lt::torrent_info>(lt::span<char const>{torrent_data, torrent_size}, lt::from_span);

	return params;
}
} // unnamed namespace

// defined in src/settings.cpp
extern lt::settings_pack make_settings(int tag, va_list);
extern int settings_key(int tag);

extern "C"
{

struct session_params* read_session_params(const char *filepath)
{
	std::ifstream ifs(filepath, std::ios_base::binary);
	ifs.unsetf(std::ios_base::skipws);
	auto sp = lt::read_session_params(std::vector<char>{std::istream_iterator<char>(ifs), std::istream_iterator<char>()});

	sp.settings.set_int(lt::settings_pack::alert_mask
		, lt::alert_category::error
		| lt::alert_category::storage
		| lt::alert_category::status);
	return reinterpret_cast<struct session_params*>(new (std::nothrow) lt::session_params(std::move(sp)));
}

StdString* StdString_New(std::string const &s) {
	return reinterpret_cast<StdString*>(new std::string(s));
}
void StdString_Release(StdString* out) {
	auto s = reinterpret_cast<std::string*>(out);
	delete s;
}
const char* StdString_String(StdString* out) {
	auto s = reinterpret_cast<std::string*>(out);
	return s->c_str();
}
int StdString_Length(StdString* out) {
	auto s = reinterpret_cast<std::string*>(out);
	return s->size();
}

AddTorrentParams* AddTorrentParams_ParseMagnetURI(const char* uri, const char* savepath) {
	lt::add_torrent_params magnet;
	try {
		magnet = lt::parse_magnet_uri(uri);
	}
	catch(lt::system_error) {} // TODO:

	magnet.save_path = savepath;
	return reinterpret_cast<AddTorrentParams*>(new lt::add_torrent_params(std::move(magnet)));
}

void AddTorrentParams_Release(AddTorrentParams* out) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	delete p;
}

const char* AddTorrentParams_Name(AddTorrentParams* out) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	return p->name.c_str();
}
const char* AddTorrentParams_SavePath(AddTorrentParams* out) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	return p->save_path.c_str();
}
int AddTorrentParams_Trackers(AddTorrentParams* out, const char**) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	return p->trackers.size();
}
uint64_t AddTorrentParams_Flags(AddTorrentParams* out) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	return (uint64_t)p->flags;
}
void AddTorrentParams_SetFlags(AddTorrentParams* out, uint64_t flags) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	p->flags = lt::torrent_flags_t(flags);
}
StdString* AddTorrentParams_InfoHash(AddTorrentParams* out) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	return StdString_New(std::string(lt::aux::to_hex(lt::span<char const>(p->info_hashes.get_best().to_string()))));
}
storage_mode_t AddTorrentParams_StorageMode(AddTorrentParams* out) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	return (storage_mode_t)p->storage_mode;
}
AddTorrentParams* AddTorrentParams_ReadFrom(const char* filepath) {
	try {
		std::ifstream ifs(filepath, std::ios_base::binary);
		ifs.unsetf(std::ios_base::skipws);
		auto p = lt::read_resume_data(std::vector<char>{std::istream_iterator<char>(ifs), std::istream_iterator<char>()});
		return reinterpret_cast<AddTorrentParams*>(new lt::add_torrent_params(std::move(p)));
	}
	catch(...) {
		return nullptr;
	}
}
int AddTorrentParams_Write(AddTorrentParams* out, const char* filepath) {
	auto p = reinterpret_cast<lt::add_torrent_params*>(out);
	auto buf = lt::write_resume_data_buf(*p);
	return save_file(filepath, buf);
}

libtorrent_session* session_create(int tag, ...)
{
	using namespace lt;

	va_list lp;
	va_start(lp, tag);
	lt::settings_pack pack = make_settings(tag, lp);
	va_end(lp);

	return reinterpret_cast<libtorrent_session*>(new (std::nothrow) session(std::move(pack)));
}

void session_close(libtorrent_session* ses)
{
	delete reinterpret_cast<lt::session*>(ses);
}

int session_add_torrent(libtorrent_session* ses, int tag, ...)
{
	using namespace lt;

	va_list lp;
	va_start(lp, tag);
	lt::add_torrent_params params = make_add_torrent_params(tag, lp);
	va_end(lp);

	auto* s = reinterpret_cast<lt::session*>(ses);
	lt::error_code ec;
	lt::torrent_handle h = s->add_torrent(params, ec);
	if (ec) return -1;

	if (!h.is_valid()) return -1;

	int i = find_handle(h);
	if (i == -1) i = add_handle(h);

	return i;
}

void session_remove_torrent(libtorrent_session* ses, int tor, int flags)
{
	lt::torrent_handle h = get_handle(tor);
	if (!h.is_valid()) return;

	remove_handle(tor);

	auto* s = reinterpret_cast<lt::session*>(ses);
	s->remove_torrent(h, lt::remove_flags_t(flags));
}

int session_pop_alerts(libtorrent_session* ses, libtorrent_alert const** dest, int* len)
{
	auto* s = reinterpret_cast<lt::session*>(ses);
	if (len == nullptr) return -1;
	if (*len < 0) return -1;
	if (*len == 0) return 0;

	std::vector<lt::alert*> ret;
	s->pop_alerts(&ret);

	// TODO: figure out what to do with the alert we may have lost here. Save
	// them to the next call somehow?
	int const to_copy = std::min(int(ret.size()), *len);
	std::copy(ret.begin(), ret.begin() + to_copy, reinterpret_cast<lt::alert const**>(dest));
	*len = to_copy;
	return 0; // for now
}

int session_set_settings(libtorrent_session* ses, int tag, ...)
{
	va_list lp;
	va_start(lp, tag);
	lt::settings_pack pack = make_settings(tag, lp);
	va_end(lp);

	auto* s = reinterpret_cast<lt::session*>(ses);
	s->apply_settings(std::move(pack));

	return 0;
}

int session_get_setting(libtorrent_session* ses, int tag, void* value, int* value_size)
{
	auto* s = reinterpret_cast<lt::session*>(ses);
	lt::settings_pack sett = s->get_settings();

	int const key = settings_key(tag);
	if (key < 0) return key;

	using sp = lt::settings_pack;

	switch (key & lt::settings_pack::type_mask)
	{
		case sp::string_type_base:
			return set_str_value(value, value_size, sett.get_str(key));
		case sp::int_type_base:
			return set_int_value(value, value_size, sett.get_int(key));
		case sp::bool_type_base:
			return set_int_value(value, value_size, sett.get_bool(key));
		default:
			return -1;
	}
}

void session_post_torrent_updates(struct libtorrent_session* ses) {
	auto* s = reinterpret_cast<lt::session*>(ses);
	s->post_torrent_updates();
}
void session_post_session_stats(struct libtorrent_session* ses) {
	auto* s = reinterpret_cast<lt::session*>(ses);
	s->post_session_stats();
}
void session_post_dht_stats(struct libtorrent_session* ses) {
	auto* s = reinterpret_cast<lt::session*>(ses);
	s->post_dht_stats();
}

void s2s(lt::torrent_status const &ts, torrent_status* s, int struct_size) {
	s->handle = find_handle(ts.handle);
	s->state = (state_t)ts.state;
	s->progress = ts.progress;

	strncpy(s->name, ts.name.c_str(), sizeof(s->name) - 1);
	s->name[sizeof(s->name) - 1] = '\0';

	std::string err_msg = ts.errc.message();
	strncpy(s->error, err_msg.c_str(), sizeof(s->error) - 1);
	s->error[sizeof(s->error) - 1] = '\0';

	strncpy(s->current_tracker, ts.current_tracker.c_str(), sizeof(s->current_tracker)-1);
	s->current_tracker[sizeof(s->current_tracker)-1] = '\0';

	s->next_announce = lt::total_seconds(ts.next_announce);
	s->total_download = ts.total_download;
	s->total_upload = ts.total_upload;
	s->total_payload_download = ts.total_payload_download;
	s->total_payload_upload = ts.total_payload_upload;
	s->total_failed_bytes = ts.total_failed_bytes;
	s->total_redundant_bytes = ts.total_redundant_bytes;

	s->total_done = ts.total_done;
	s->total = ts.total;
	s->total_wanted_done = ts.total_wanted_done;
	s->total_wanted = ts.total_wanted;

	s->all_time_upload = ts.all_time_upload;
	s->all_time_download = ts.all_time_download;
	s->added_time = ts.added_time;
	s->completed_time = ts.completed_time;
	s->last_seen_complete = ts.last_seen_complete;
	s->storage_mode = ts.storage_mode;
	s->progress = ts.progress;
	s->progress_ppm = ts.progress_ppm;

	s->download_rate = ts.download_rate;
	s->upload_rate = ts.upload_rate;

	s->download_payload_rate = ts.download_payload_rate;
	s->upload_payload_rate = ts.upload_payload_rate;

	s->num_seeds = ts.num_seeds;
	s->num_peers = ts.num_peers;
	s->num_complete = ts.num_complete;
	s->num_incomplete = ts.num_incomplete;
	s->list_seeds = ts.list_seeds;
	s->list_peers = ts.list_peers;
	s->connect_candidates = ts.connect_candidates;

	s->num_pieces = ts.num_pieces;
	s->distributed_full_copies = ts.distributed_full_copies;
	s->distributed_fraction = ts.distributed_fraction;
	s->distributed_copies = ts.distributed_copies;
	s->block_size = ts.block_size;

	s->num_uploads = ts.num_uploads;
	s->num_connections = ts.num_connections;
	s->uploads_limit = ts.uploads_limit;
	s->connections_limit = ts.connections_limit;

	s->up_bandwidth_queue = ts.up_bandwidth_queue;
	s->down_bandwidth_queue = ts.down_bandwidth_queue;

	s->seed_rank = ts.seed_rank;
	s->state = (enum state_t)ts.state;

	s->need_save_resume = ts.need_save_resume;
	s->is_seeding = ts.is_seeding;
	s->is_finished = ts.is_finished;
	s->has_metadata = ts.has_metadata;
	s->has_incoming = ts.has_incoming;
	s->moving_storage = ts.moving_storage;
	s->announcing_to_trackers = ts.announcing_to_trackers;
	s->announcing_to_lsd = ts.announcing_to_lsd;
	s->announcing_to_dht = ts.announcing_to_dht;

	s->last_upload = lt::total_seconds(ts.last_upload.time_since_epoch());
	s->last_download = lt::total_seconds(ts.last_download.time_since_epoch());
	s->active_duration = ts.active_duration.count();
	s->finished_duration = ts.finished_duration.count();
	s->seeding_duration = ts.seeding_duration.count();

	s->flags = (std::uint64_t)ts.flags;
}

int torrent_get_status(int tor, torrent_status* s, int struct_size)
{
	lt::torrent_handle h = get_handle(tor);
	if (!h.is_valid()) return -1;

	lt::torrent_status ts = h.status();

	if (struct_size != sizeof(torrent_status)) return -1;
	s2s(ts, s, struct_size);
	return 0;
}

int alert_message(libtorrent_alert const* alert, char* buf, int size)
{
	auto const* a = reinterpret_cast<lt::alert const*>(alert);
	auto const msg = a->message();
	std::strncpy(buf, msg.c_str(), size - 1);
	buf[size - 1] = '\0';
	return 0;
}

int64_t const* alert_stats_counters(struct libtorrent_alert const* alert, int* count)
{
	auto const* a = reinterpret_cast<lt::alert const*>(alert);
	auto const* sa = lt::alert_cast<lt::session_stats_alert>(a);
	if (sa == nullptr) return nullptr;

	lt::span<std::int64_t const> counters = sa->counters();
	*count = int(counters.size());
	return counters.data();
}

std::int64_t alert_timestamp(struct libtorrent_alert const* alert)
{
	auto const* a = reinterpret_cast<lt::alert const*>(alert);
	return std::chrono::duration_cast<std::chrono::microseconds>(
		a->timestamp().time_since_epoch()).count();
}

int alert_type(struct libtorrent_alert const* alert)
{
	auto const* a = reinterpret_cast<lt::alert const*>(alert);
	return a->type();
}

uint32_t alert_category(struct libtorrent_alert const* alert)
{
	auto const* a = reinterpret_cast<lt::alert const*>(alert);
	return static_cast<std::uint32_t>(a->category());
}

bool is_torrent_alert(int type) {
	switch (type)
	{
		// torrent_alert
#if TORRENT_ABI_VERSION == 1
		case lt::torrent_added_alert::alert_type:
#endif
		case lt::torrent_removed_alert::alert_type:
		case lt::read_piece_alert::alert_type:
		case lt::file_completed_alert::alert_type:
		case lt::file_renamed_alert::alert_type:
		case lt::file_rename_failed_alert::alert_type:
		case lt::performance_alert::alert_type:
		case lt::state_changed_alert::alert_type:
		case lt::hash_failed_alert::alert_type:
		case lt::torrent_finished_alert::alert_type:
		case lt::piece_finished_alert::alert_type:
		case lt::storage_moved_alert::alert_type:
		case lt::storage_moved_failed_alert::alert_type:
		case lt::torrent_deleted_alert::alert_type:
		case lt::torrent_delete_failed_alert::alert_type:
		case lt::save_resume_data_alert::alert_type:
		case lt::save_resume_data_failed_alert::alert_type:
		case lt::torrent_paused_alert::alert_type:
		case lt::torrent_resumed_alert::alert_type:
		case lt::torrent_checked_alert::alert_type:
		case lt::url_seed_alert::alert_type:
		case lt::file_error_alert::alert_type:
		case lt::metadata_failed_alert::alert_type:
		case lt::metadata_received_alert::alert_type:
		case lt::fastresume_rejected_alert::alert_type:
#if TORRENT_ABI_VERSION <= 2
		case lt::stats_alert::alert_type:
#endif
		case lt::cache_flushed_alert::alert_type:
#if TORRENT_ABI_VERSION == 1
		case lt::anonymous_mode_alert::alert_type:
#endif
		case lt::torrent_error_alert::alert_type:
		case lt::torrent_need_cert_alert::alert_type:
		case lt::add_torrent_alert::alert_type:
		case lt::torrent_log_alert::alert_type:
		// peer_alert
		case lt::peer_ban_alert::alert_type:
		case lt::peer_unsnubbed_alert::alert_type:
		case lt::peer_snubbed_alert::alert_type:
		case lt::peer_error_alert::alert_type:
		case lt::peer_connect_alert::alert_type:
		case lt::peer_disconnected_alert::alert_type:
		case lt::invalid_request_alert::alert_type:
		case lt::request_dropped_alert::alert_type:
		case lt::block_timeout_alert::alert_type:
		case lt::block_finished_alert::alert_type:
		case lt::block_downloading_alert::alert_type:
		case lt::unwanted_block_alert::alert_type:
		case lt::peer_blocked_alert::alert_type:
		case lt::lsd_peer_alert::alert_type:
		case lt::peer_log_alert::alert_type:
		case lt::incoming_request_alert::alert_type:
		case lt::picker_log_alert::alert_type:
		case lt::block_uploaded_alert::alert_type:
		// tracker alert
		case lt::tracker_error_alert::alert_type:
		case lt::tracker_warning_alert::alert_type:
		case lt::scrape_reply_alert::alert_type:
		case lt::scrape_failed_alert::alert_type:
		case lt::tracker_reply_alert::alert_type:
		case lt::dht_reply_alert::alert_type:
		case lt::tracker_announce_alert::alert_type:
		case lt::trackerid_alert::alert_type:
		return true;
		default:
		return false;
	}
}

int alert_torrent_handle(struct libtorrent_alert const* alert)
{
	auto const* a = reinterpret_cast<lt::alert const*>(alert);
	int const type = a->type();
	if (is_torrent_alert(type)) {
		lt::torrent_handle h = static_cast<lt::torrent_alert const*>(a)->handle;
		return find_handle(h);
	}
	return -1;
}

int find_metric_idx(char const* name)
{
	return lt::find_metric_idx(name);
}

int torrent_set_settings(int tor, int tag, ...)
{
	lt::torrent_handle h = get_handle(tor);
	if (!h.is_valid()) return -1;

	va_list lp;
	va_start(lp, tag);

	bool flags_set = false;
	std::uint64_t flags = 0;
	std::uint64_t mask = UINT64_MAX;

	while (tag != TAG_END)
	{
		switch (tag)
		{
			case TSET_UPLOAD_RATE_LIMIT:
				h.set_upload_limit(va_arg(lp, int));
				break;
			case TSET_DOWNLOAD_RATE_LIMIT:
				h.set_download_limit(va_arg(lp, int));
				break;
			case TSET_MAX_UPLOAD_SLOTS:
				h.set_max_uploads(va_arg(lp, int));
				break;
			case TSET_MAX_CONNECTIONS:
				h.set_max_connections(va_arg(lp, int));
				break;
			case TSET_FLAGS:
				flags = va_arg(lp, int);
				flags_set = true;
				break;
			case TSET_FLAGS_MASK:
				mask = va_arg(lp, int);
				break;
			default:
				// ignore unknown tags
				va_arg(lp, void*);
				break;
		}

		tag = va_arg(lp, int);
	}
	va_end(lp);

	if (flags_set)
		h.set_flags(lt::torrent_flags_t(flags), lt::torrent_flags_t(mask));
	return 0;
}

int torrent_get_setting(int const tor, int const tag, void* value, int* value_size)
{
	lt::torrent_handle h = get_handle(tor);
	if (!h.is_valid()) return -1;

	switch (tag)
	{
		case TSET_UPLOAD_RATE_LIMIT:
			return set_int_value(value, value_size, h.upload_limit());
		case TSET_DOWNLOAD_RATE_LIMIT:
			return set_int_value(value, value_size, h.download_limit());
		case TSET_MAX_UPLOAD_SLOTS:
			return set_int_value(value, value_size, h.max_uploads());
		case TSET_MAX_CONNECTIONS:
			return set_int_value(value, value_size, h.max_connections());
		case TSET_FLAGS:
			return set_int_value(value, value_size, static_cast<int>(static_cast<std::uint64_t>(h.flags())));
		default:
			return -2;
	}
}

const char* Version() {
	return LIBTORRENT_VERSION;
}

SessionParams* SessionParams_ReadFrom(const char* filename) {
	std::vector<char> in;
	if (load_file(filename, in)) {
		lt::session_params params = read_session_params(in, lt::session_handle::save_dht_state);
		return reinterpret_cast<SessionParams*>(new lt::session_params(std::move(params)));
	}
	return reinterpret_cast<SessionParams*>(new lt::session_params());
}
SessionParams* SessionParams_Default() {
	return reinterpret_cast<SessionParams*>(new lt::session_params());
}
void SessionParams_Release(SessionParams* out) {
	auto inner = reinterpret_cast<lt::session_params*>(out);
	delete inner;
}
int SessionParams_Write(SessionParams* out, const char* filepath) {
	auto params = reinterpret_cast<lt::session_params*>(out);
	auto buf = lt::write_session_params_buf(*params);
	return save_file(filepath, buf);
}
SettingsPack* SessionParams_SettingsPack(SessionParams* out) {
	auto params = reinterpret_cast<lt::session_params*>(out);
	return reinterpret_cast<SettingsPack *>(new lt::settings_pack(params->settings));
}
void SessionParams_SetSettingsPack(SessionParams* out, SettingsPack* in) {
	auto params = reinterpret_cast<lt::session_params*>(out);
	auto sp = reinterpret_cast<lt::settings_pack*>(in);
	params->settings = *sp;
}

// for flutter reload
#ifndef NDEBUG
static lt::session* g_ = nullptr;
Session* Session_Create(SessionParams* out) {
	if (g_ == nullptr) {
		auto params = reinterpret_cast<lt::session_params*>(out);
		auto p = new lt::session(*params);
		g_ = p;
	}
	return reinterpret_cast<Session*>(g_);
}
void Session_Release(Session* out) {
	// auto inner = reinterpret_cast<lt::session*>(out);
	// delete inner;
	// g_ = nullptr;
}
#else
Session* Session_Create(SessionParams* out) {
	auto params = reinterpret_cast<lt::session_params*>(out);
	auto p = new lt::session(*params);
	return reinterpret_cast<Session*>(p);
}
void Session_Release(Session* out) {
	auto inner = reinterpret_cast<lt::session*>(out);
	delete inner;
}
#endif

SettingsPack* Session_SettingsPack(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	return reinterpret_cast<SettingsPack *>(new lt::settings_pack(s->get_settings()));
}
void Session_Apply(Session* out, SettingsPack* sp) {
	auto* s = reinterpret_cast<lt::session*>(out);
	lt::settings_pack* pack = reinterpret_cast<lt::settings_pack*>(sp);
	s->apply_settings(*pack);
}
int Session_Add(Session* out, AddTorrentParams* atp) {
	auto* s = reinterpret_cast<lt::session*>(out);
	lt::add_torrent_params* p = reinterpret_cast<lt::add_torrent_params*>(atp);
	lt::error_code ec;
	auto h = s->add_torrent(*p, ec);
	if (ec) {
		return -1;
	}
	if (!h.is_valid()) {
		return -1;
	}
	int i = find_handle(h);
	if (i == -1) {
		i = add_handle(h);
	}
	return i;
}
void Session_AddAsync(Session* out, AddTorrentParams* atp) {
	auto* s = reinterpret_cast<lt::session*>(out);
	lt::add_torrent_params* p = reinterpret_cast<lt::add_torrent_params*>(atp);
	s->async_add_torrent(*p);
}
void Session_Remove(Session* out, int tor, int flags) {
	auto* s = reinterpret_cast<lt::session*>(out);

	lt::torrent_handle h = get_handle(tor);
	if (!h.is_valid()) return;

	remove_handle(tor);

	s->remove_torrent(h, lt::remove_flags_t(flags));
}
bool Session_IsPaused(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	return s->is_paused();
}
void Session_Pause(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	s->pause();
}
void Session_Resume(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	s->resume();
}
SessionParams* Session_State(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	return reinterpret_cast<SessionParams*>(new lt::session_params(
		s->session_state()
	));
}

typedef std::vector<lt::alert*> alerts;

Alerts* Session_Alerts(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);

	std::vector<lt::alert*> ret;
	s->pop_alerts(&ret);

    // fix handles
	for (auto a : ret) {
		if (a->type() == lt::add_torrent_alert::alert_type) {
			auto* ata = lt::alert_cast<lt::add_torrent_alert>(a);
			int i = find_handle(ata->handle);
			if (i == -1) {
				i = add_handle(ata->handle);
				// printf("vvv add_handle %d %d\n", i, !ata->error);
			}
		}
	}
	// printf("c %zu ", ret.size());

	return reinterpret_cast<Alerts*>(new alerts(std::move(
		ret
	)));
}
void Session_SetAlertNotify(Session* out, void(*f)()) {
	auto* s = reinterpret_cast<lt::session*>(out);
	s->set_alert_notify(f);
}
// post_session_stats => session_stats_alert
// post_torrent_updates => state_update_alert
void Session_PostStats(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	s->post_session_stats();
}
void Session_PostTorrentUpdates(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	s->post_torrent_updates();
}
void Session_PostDHTStats(Session* out) {
	auto* s = reinterpret_cast<lt::session*>(out);
	s->post_dht_stats();
}

int Alert_Type(Alert* out) {
	auto* s = reinterpret_cast<lt::alert*>(out);
	return s->type();
}
uint32_t Alert_Category(Alert* out) {
	auto* s = reinterpret_cast<lt::alert*>(out);
	return (uint32_t)s->category();
}
StdString* Alert_Message(Alert* out) {
	auto* s = reinterpret_cast<lt::alert*>(out);
	return StdString_New(s->message());
}
const char* Alert_What(Alert* out) {
	auto* s = reinterpret_cast<lt::alert*>(out);
	return s->what();
}
const char* Alert_TorrentName(Alert* out) {
	auto* s = reinterpret_cast<lt::alert*>(out);
	if (is_torrent_alert(s->type())) {
		auto* a = static_cast<lt::torrent_alert*>(s);
		return a->torrent_name();
	}
	return nullptr;
}
int Alert_Handle(Alert* out) {
	auto* s = reinterpret_cast<lt::alert*>(out);
	if (s && is_torrent_alert(s->type())) {
		auto* a = static_cast<lt::torrent_alert*>(s);
		return find_handle(a->handle);
	}
	return -1;
}


void Alerts_Release(Alerts* out) {
	auto* s = reinterpret_cast<alerts*>(out);
	delete s;
}
int Alerts_Length(Alerts* out) {
	auto* s = reinterpret_cast<alerts*>(out);
	return s->size();
}
Alert* Alerts_Item(Alerts* out, int i) {
	auto* s = reinterpret_cast<alerts*>(out);
	if (i >=0 && i <s->size()) {
		return reinterpret_cast<Alert*>(s->at(i));
	}
	return nullptr;
}

error_code* error_code_new(lt::error_code const & ec) {
	return reinterpret_cast<error_code*>(
		new lt::error_code(ec)
	);
}
int error_code_code(error_code* out) {
	auto* s = reinterpret_cast<lt::error_code*>(out);
	return s->value();
}
StdString* error_code_category(error_code* out) {
	auto* s = reinterpret_cast<lt::error_code*>(out);
	return StdString_New(s->category().name());
}
StdString* error_code_message(error_code* out) {
	auto* s = reinterpret_cast<lt::error_code*>(out);
	return StdString_New(s->message());
}
void error_code_release(error_code* out) {
	auto* s = reinterpret_cast<lt::error_code*>(out);
	delete s;
}

void Status_Release(torrent_status* out) {
	delete out;
}
struct torrent_status* Handle_Status(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		auto* ret = new struct torrent_status;
		lt::torrent_status ts = h.status();
		s2s(ts, ret, sizeof(*ret));
		return ret;
	}
	return nullptr;
}
int Handle_Id(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		return h.id();
	}
	return 0;
}
StdString* Handle_InfoHash(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		return StdString_New(std::string(
			lt::aux::to_hex(lt::span<char const>(h.info_hashes().get_best().to_string()))
			));
	}
	return nullptr;
}
bool Handle_IsValid(int i) {
	auto h = get_handle(i);
	return h.is_valid();
}
bool Handle_InSession(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		return h.in_session();
	}
	return false;
}
void Handle_Pause(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		h.pause();
	}
}
bool Handle_IsPause(int i) {
	auto h = get_handle(i);
	if (h.is_valid() && (h.flags() & lt::torrent_flags::paused)) {
		return true;
	}
	return false;
}
void Handle_Resume(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		h.resume();
	}
}
bool Handle_NeedSaveResumeData(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		return h.need_save_resume_data();
	}
	return false;
}
uint64_t Handle_Flags(int i) {
	auto h = get_handle(i);
	return (uint64_t)h.flags();
}
void Handle_SetFlags(int i, uint64_t flags) {
	auto h = get_handle(i);
	return h.set_flags(lt::torrent_flags_t(flags), lt::torrent_flags_t(flags));
}
void Handle_UnSetFlags(int i, uint64_t flags) {
	auto h = get_handle(i);
	return h.unset_flags(lt::torrent_flags_t(flags));
}
void Handle_Recheck(int i) {
	auto h = get_handle(i);
	return h.force_recheck();
}
void Handle_SetUploadLimit(int i, int limit) {
	auto h = get_handle(i);
	h.set_upload_limit(limit);
}
int Handle_UploadLimit(int i) {
	auto h = get_handle(i);
	return h.upload_limit();
}
void Handle_SetDownloadLimit(int i, int limit) {
	auto h = get_handle(i);
	h.set_download_limit(limit);
}
int Handle_DownloadLimit(int i) {
	auto h = get_handle(i);
	return h.download_limit();
}
void Handle_PostFileProgress(int i) {
	auto h = get_handle(i);
	h.post_file_progress({});
}
int Handle_FileProgress(int i, int64_t* buf) {
	auto h = get_handle(i);
	std::vector<std::int64_t> vec;
	h.file_progress(vec, {});
	std::copy(vec.begin(), vec.end(), buf);
	return vec.size();
}
void Handle_SaveResumeData(int i) {
	auto h = get_handle(i);
	h.save_resume_data(lt::torrent_handle::only_if_modified | lt::torrent_handle::save_info_dict);
}
void Handle_SetFilePriority(int i, int index, int priority) {
	auto h = get_handle(i);
	h.file_priority(lt::file_index_t(index), lt::download_priority_t((uint8_t)priority));
}
int Handle_GetFilePriority(int i, int index) {
	auto h = get_handle(i);
	auto pr = h.file_priority(lt::file_index_t(index));
	return (uint8_t)pr;
}
int Handle_QueuePosition(int i) {
	auto h = get_handle(i);
	auto pr = h.queue_position();
	return (int)pr;
}
void Handle_SetQueuePosition(int i, int p) {
	auto h = get_handle(i);
	h.queue_position_set(lt::queue_position_t(p));
}

typedef std::weak_ptr<const lt::torrent_info> weakinfo;

Info* Handle_Info(int i) {
	auto h = get_handle(i);
	if (h.is_valid()) {
		auto cloned = new weakinfo(h.torrent_file());
		return reinterpret_cast<Info*>(cloned);
	}
	return nullptr;
}

void Info_Release(Info* out) {
	auto* w = reinterpret_cast<weakinfo*>(out);
	delete w;
}

const char* Info_Name(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->name().c_str();
	}
	return nullptr;
}
uint64_t Info_CreationDate(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->creation_date();
	}
	return 0;
}
const char* Info_Creator(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->creator().c_str();
	}
	return nullptr;
}
const char* Info_Comment(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->comment().c_str();
	}
	return nullptr;
}
int Info_NumFiles(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->num_files();
	}
	return 0;
}
int64_t Info_TotalSize(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->total_size();
	}
	return 0;
}
int Info_PieceLength(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->piece_length();
	}
	return 0;
}
int Info_NumPieces(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->num_pieces();
	}
	return 0;
}
int Info_BlocksPerPiece(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->blocks_per_piece();
	}
	return 0;
}


bool Info_IsI2P(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		return s->is_i2p();
	}
	return false;
}

FileStorage* Info_Files(Info* out) {
	auto s = reinterpret_cast<weakinfo*>(out)->lock();
	if (s) {
		auto p = new lt::file_storage(s->orig_files());
		return reinterpret_cast<FileStorage*>(p);
	}
	return nullptr;
}

void FileStorage_Release(FileStorage* out) {
	auto p = reinterpret_cast<lt::file_storage*>(out);
	delete p;
}
int FileStorage_NumFiles(FileStorage* out) {
	auto p = reinterpret_cast<lt::file_storage*>(out);
	if (p) {
		return p->num_files();
	}
	return 0;
}
int FileStorage_NumPieces(FileStorage* out) {
	auto p = reinterpret_cast<lt::file_storage*>(out);
	if (p) {
		return p->num_pieces();
	}
	return 0;
}
StdString* FileStorage_FileName(FileStorage* out, int i) {
	auto p = reinterpret_cast<lt::file_storage*>(out);
	if (p) {
		auto sv = p->file_name(lt::file_index_t(i));
		return StdString_New(std::string(sv.data(), sv.data()+sv.size()));
	}
	return 0;
}
StdString* FileStorage_FilePath(FileStorage* out, int i) {
	auto p = reinterpret_cast<lt::file_storage*>(out);
	if (p) {
		return StdString_New(p->file_path(lt::file_index_t(i)).data());
	}
	return 0;
}
int64_t FileStorage_FileSize(FileStorage* out, int i) {
	auto p = reinterpret_cast<lt::file_storage*>(out);
	if (p) {
		return p->file_size(lt::file_index_t(i));
	}
	return 0;
}
int FileStorage_FileFlag(FileStorage* out, int i) {
	auto p = reinterpret_cast<lt::file_storage*>(out);
	if (p) {
		return (uint8_t)p->file_flags(lt::file_index_t(i));
	}
	return -1;
}

void dump_handles() {
	printf("free handles: ");
	for (auto h : free_handle_slots) {
		printf("%d ", h);
	}
	printf("\nhandles: ");
	for (int i=0;i< handles.size(); i++) {
		printf("%d %d, ", i, handles[i].is_valid());
	}
	printf("\n");
	#ifndef NDEBUG
	printf("handles: %zu alert mask 0x%x\n", handles.size(), g_->session_state().settings.get_int(lt::settings_pack::alert_mask));
	#endif
}

} // extern "C"
