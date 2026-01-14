
project('libtorrent', ['cpp','c'],
    version: '2.0.11', 
    license : 'MIT',
    default_options : [
        'cpp_std=c++14',
        'cpp_args=-ftemplate-depth=512',
    ],
)

# mkdir subprojects && meson wrap install openssl
# meson setup --reconfigure --cross-file android-arm64.ini -Dcrypto=openssl outarm64
# meson setup --reconfigure out && ninja -C out -v -j1
# meson setup --buildtype=release --reconfigure out 


src = files(
    'src/alert.cpp',
    'src/alert_manager.cpp',
    'src/announce_entry.cpp',
    'src/assert.cpp',
    'src/bandwidth_limit.cpp',
    'src/bandwidth_manager.cpp',
    'src/bandwidth_queue_entry.cpp',
    'src/bdecode.cpp',
    'src/bitfield.cpp',
    'src/bloom_filter.cpp',
    'src/chained_buffer.cpp',
    'src/choker.cpp',
    'src/close_reason.cpp',
    'src/copy_file.cpp',
    'src/cpuid.cpp',
    'src/crc32c.cpp',
    'src/create_torrent.cpp',
    'src/directory.cpp',
    'src/disk_buffer_holder.cpp',
    'src/disk_buffer_pool.cpp',
    'src/disk_interface.cpp',
    'src/disk_io_thread_pool.cpp',
    'src/disabled_disk_io.cpp',
    'src/disk_job_fence.cpp',
    'src/disk_job_pool.cpp',
    'src/drive_info.cpp',
    'src/entry.cpp',
    'src/error_code.cpp',
    'src/file_storage.cpp',
    'src/escape_string.cpp',
    'src/string_util.cpp',
    'src/file.cpp',
    'src/path.cpp',
    'src/fingerprint.cpp',
    'src/gzip.cpp',
    'src/hasher.cpp',
    'src/hash_picker.cpp',
    'src/hex.cpp',
    'src/http_connection.cpp',
    'src/http_parser.cpp',
    'src/identify_client.cpp',
    'src/ip_filter.cpp',
    'src/ip_helpers.cpp',
    'src/ip_notifier.cpp',
    'src/ip_voter.cpp',
    'src/listen_socket_handle.cpp',
    'src/merkle.cpp',
    'src/merkle_tree.cpp',
    'src/peer_connection.cpp',
    'src/platform_util.cpp',
    'src/bt_peer_connection.cpp',
    'src/web_connection_base.cpp',
    'src/web_peer_connection.cpp',
    'src/http_seed_connection.cpp',
    'src/peer_connection_handle.cpp',
    'src/i2p_stream.cpp',
    'src/instantiate_connection.cpp',
    'src/natpmp.cpp',
    'src/packet_buffer.cpp',
    'src/piece_picker.cpp',
    'src/peer_list.cpp',
    'src/proxy_base.cpp',
    'src/puff.cpp',
    'src/random.cpp',
    'src/read_resume_data.cpp',
    'src/write_resume_data.cpp',
    'src/receive_buffer.cpp',
    'src/resolve_links.cpp',
    'src/session.cpp',
    'src/session_params.cpp',
    'src/session_handle.cpp',
    'src/session_impl.cpp',
    'src/session_call.cpp',
    'src/settings_pack.cpp',
    'src/sha1.cpp',
    'src/sha1_hash.cpp',
    'src/sha256.cpp',
    'src/socket_io.cpp',
    'src/socket_type.cpp',
    'src/socks5_stream.cpp',
    'src/stat.cpp',
    'src/storage_utils.cpp',
    'src/torrent.cpp',
    'src/torrent_handle.cpp',
    'src/torrent_info.cpp',
    'src/torrent_peer.cpp',
    'src/torrent_peer_allocator.cpp',
    'src/torrent_status.cpp',
    'src/time.cpp',
    'src/tracker_manager.cpp',
    'src/http_tracker_connection.cpp',
    'src/udp_tracker_connection.cpp',
    'src/timestamp_history.cpp',
    'src/udp_socket.cpp',
    'src/upnp.cpp',
    'src/utf8.cpp',
    'src/utp_socket_manager.cpp',
    'src/utp_stream.cpp',
    'src/file_view_pool.cpp',
    'src/lsd.cpp',
    'src/enum_net.cpp',
    'src/magnet_uri.cpp',
    'src/parse_url.cpp',
    'src/xml_parse.cpp',
    'src/version.cpp',
    'src/peer_class.cpp',
    'src/peer_class_set.cpp',
    'src/part_file.cpp',
    'src/stat_cache.cpp',
    'src/request_blocks.cpp',
    'src/session_stats.cpp',
    'src/performance_counters.cpp',
    'src/resolver.cpp',
    'src/session_settings.cpp',
    'src/proxy_settings.cpp',
    'src/file_progress.cpp',
    'src/ffs.cpp',
    'src/add_torrent_params.cpp',
    'src/peer_info.cpp',
    'src/stack_allocator.cpp',
    'src/generate_peer_id.cpp',
    'src/mmap.cpp',
    'src/mmap_disk_io.cpp',
    'src/mmap_disk_job.cpp',
    # 'src/mmap_storage.cpp',
    'src/posix_disk_io.cpp',
    'src/posix_part_file.cpp',
    'src/posix_storage.cpp',
    'src/ssl.cpp',
    'src/truncate.cpp',
    'src/load_torrent.cpp',
    'src/ut_pex.cpp',
    'src/ut_metadata.cpp',
    'src/smart_ban.cpp',
)
kademlia = files(
	'src/kademlia/dht_state.cpp',
	'src/kademlia/dht_storage.cpp',
	'src/kademlia/dht_tracker.cpp',
	'src/kademlia/msg.cpp',
	'src/kademlia/node.cpp',
	'src/kademlia/node_entry.cpp',
	'src/kademlia/refresh.cpp',
	'src/kademlia/rpc_manager.cpp',
	'src/kademlia/find_data.cpp',
	'src/kademlia/node_id.cpp',
	'src/kademlia/routing_table.cpp',
	'src/kademlia/traversal_algorithm.cpp',
	'src/kademlia/dos_blocker.cpp',
	'src/kademlia/get_peers.cpp',
	'src/kademlia/item.cpp',
	'src/kademlia/get_item.cpp',
	'src/kademlia/put_data.cpp',
	'src/kademlia/ed25519.cpp',
	'src/kademlia/sample_infohashes.cpp',
	'src/kademlia/dht_settings.cpp',    
)

ed25519 = files(
	'src/ed25519/add_scalar.cpp',
	'src/ed25519/fe.cpp',
	'src/ed25519/ge.cpp',
	'src/ed25519/key_exchange.cpp',
	'src/ed25519/keypair.cpp',
	'src/ed25519/sc.cpp',
	'src/ed25519/sign.cpp',
	'src/ed25519/verify.cpp',
	'src/ed25519/hasher512.cpp',
	'src/ed25519/sha512.cpp',
)

inc = include_directories('include')

# not work
# subproject('asio-gnutls')
# subproject('json') buildable NO
# subproject('libdatachannel')


defs = [
    '-DBOOST_ASIO_ENABLE_CANCELIO',
    # make sure asio uses std::chrono
	'-DBOOST_ASIO_HAS_STD_CHRONO',
	'-DBOOST_ASIO_NO_DEPRECATED',

    #
    '-DTORRENT_BUILDING_SHARED',
    '-DBOOST_NO_DEPRECATED',

    '-DTORRENT_BUILDING_LIBRARY',
    '-D_FILE_OFFSET_BITS=64',
]

boost_dep = dependency('boost', required: true)
thread_dep = dependency('threads', required: true)
deps = [ thread_dep, boost_dep ]

if not get_option('debug')
    defs += [ '-DNDEBUG' ]
endif

if not get_option('logging')
    defs += [ '-DTORRENT_DISABLE_LOGGING' ]
endif
if not get_option('alert-msg')
    defs += [ '-DTORRENT_DISABLE_ALERT_MSG' ]
endif
if not get_option('dht')
    defs += [ '-DTORRENT_DISABLE_DHT', '-DTORRENT_USE_I2P=1' ]
endif

crypto = get_option('crypto')
message('option crypto:', crypto)
if crypto == 'openssl'
    defs += [ '-DTORRENT_USE_LIBCRYPTO', '-DTORRENT_USE_OPENSSL', '-DTORRENT_SSL_PEERS', '-DOPENSSL_NO_SSL2' ]
    # deps += [ dependency('openssl', required: true) ]
elif crypto == 'built-in'
    # do nothing, only worked in darwin
endif

if host_machine.system() == 'android'
    subproject('openssl')
    deps += dependency('openssl', required: true)
endif

subdir('deps/try_signal')

mmap_storage = static_library('mmap_storage',
    'src/mmap_storage.cpp',
    cpp_args: defs,
    include_directories: [inc, include_directories('deps/try_signal')],
    dependencies: [ thread_dep, boost_dep, try_signal_dep ],
)

if host_machine.system() == 'darwin'
    deps += dependency('appleframeworks', modules: ['CoreFoundation', 'SystemConfiguration'], required: true)
endif

foreach d : deps 
    message('dep for', d.name(), d.version())
endforeach

torrent = static_library('torrent',
    src + kademlia + ed25519 + 'src/pe_crypto.cpp',
    include_directories: inc,
    cpp_args: defs,
    dependencies: deps,
    link_with: [ mmap_storage ],
)

executable('simple_client', [
        'bindings/c2/simple_client.c',
        'bindings/c2/src/alerts.cpp',
        'bindings/c2/src/library.cpp',
        'bindings/c2/src/settings.cpp',
        'bindings/c2/src/settingsc.cpp',
    ],
    include_directories: [
        include_directories('bindings/c2/include'),
        inc,
    ],
    dependencies: deps,
    link_with: [ torrent, mmap_storage ],
)

shared_library('tc', [
        'bindings/c2/src/alerts.cpp',
        'bindings/c2/src/library.cpp',
        'bindings/c2/src/settings.cpp',
        'bindings/c2/src/settingsc.cpp',
    ],
    include_directories: [
        include_directories('bindings/c2/include'),
        inc, 
    ],
    dependencies: deps,
    link_with: [ torrent, mmap_storage ],
)
