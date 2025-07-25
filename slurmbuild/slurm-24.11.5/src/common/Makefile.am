# Makefile for common library

AUTOMAKE_OPTIONS = foreign

AM_CPPFLAGS     = -I$(top_srcdir) -DSBINDIR=\"$(sbindir)\"

noinst_PROGRAMS = libcommon.o
noinst_LTLIBRARIES = libcommon.la

libcommon_la_SOURCES =				\
	assoc_mgr.c				\
	assoc_mgr.h				\
	bitstring.c				\
	bitstring.h				\
	callerid.c				\
	callerid.h				\
	cbuf.c					\
	cbuf.h					\
	core_array.c				\
	core_array.h				\
	cpu_frequency.c				\
	cpu_frequency.h				\
	cron.c					\
	cron.h					\
	daemonize.c				\
	daemonize.h				\
	data.c					\
	data.h					\
	eio.c					\
	eio.h					\
	env.c					\
	env.h					\
	extra_constraints.c			\
	extra_constraints.h			\
	fd.c					\
	fd.h					\
	fetch_config.c				\
	fetch_config.h				\
	forward.c				\
	forward.h				\
	front_end.h				\
	global_defaults.c			\
	group_cache.c				\
	group_cache.h				\
	half_duplex.c				\
	half_duplex.h				\
	hostlist.c				\
	hostlist.h				\
	http.h					\
	http.c					\
	identity.h				\
	identity.c				\
	id_util.h				\
	id_util.c				\
	io_hdr.c				\
	io_hdr.h				\
	job_features.c				\
	job_features.h				\
	job_options.c				\
	job_options.h				\
	job_record.c				\
	job_record.h				\
	job_resources.c				\
	job_resources.h				\
	job_state_reason.c			\
	job_state_reason.h			\
	list.c					\
	list.h					\
	log.c					\
	log.h					\
	macros.h				\
	msg_type.c				\
	msg_type.h				\
	net.c					\
	net.h					\
	node_conf.c				\
	node_conf.h				\
	node_features.c				\
	node_features.h				\
	oci_config.c				\
	oci_config.h				\
	openapi.c				\
	openapi.h				\
	optz.c					\
	optz.h					\
	pack.c					\
	pack.h					\
	parse_config.c				\
	parse_config.h				\
	parse_time.c				\
	parse_time.h				\
	parse_value.c				\
	parse_value.h				\
	part_record.c				\
	part_record.h				\
	persist_conn.c				\
	persist_conn.h				\
	plugin.c				\
	plugin.h				\
	plugrack.c				\
	plugrack.h				\
	port_mgr.c				\
	port_mgr.h				\
	print_fields.c				\
	print_fields.h				\
	proc_args.c				\
	proc_args.h				\
	read_config.c				\
	read_config.h				\
	ref.h					\
	reverse_tree.c				\
	reverse_tree.h				\
	run_command.c				\
	run_command.h				\
	run_in_daemon.c				\
	run_in_daemon.h				\
	sack_api.c				\
	sack_api.h				\
	setproctitle.c				\
	setproctitle.h				\
	sluid.c					\
	sluid.h					\
	slurm_errno.c				\
	slurm_opt.c				\
	slurm_opt.h				\
	slurm_protocol_api.c			\
	slurm_protocol_api.h			\
	slurm_protocol_common.h			\
	slurm_protocol_defs.c			\
	slurm_protocol_defs.h			\
	slurm_protocol_pack.c			\
	slurm_protocol_pack.h			\
	slurm_protocol_util.c			\
	slurm_protocol_util.h			\
	slurm_protocol_socket.c			\
	slurm_protocol_socket.h			\
	slurm_resolv.c				\
	slurm_resolv.h				\
	slurm_resource_info.c			\
	slurm_resource_info.h			\
	slurm_rlimits_info.c			\
	slurm_rlimits_info.h			\
	slurm_step_layout.c			\
	slurm_step_layout.h			\
	slurm_time.c				\
	slurm_time.h				\
	slurm_xlator.h				\
	slurmdb_defs.c				\
	slurmdb_defs.h				\
	slurmdb_pack.c				\
	slurmdb_pack.h				\
	slurmdbd_defs.c				\
	slurmdbd_defs.h				\
	slurmdbd_pack.c				\
	slurmdbd_pack.h				\
	spank.c					\
	spank.h					\
	state_save.c				\
	state_save.h				\
	stepd_api.c				\
	stepd_api.h				\
	strlcpy.c				\
	strlcpy.h				\
	strnatcmp.c				\
	strnatcmp.h				\
	timers.c				\
	timers.h				\
	track_script.c				\
	track_script.h				\
	tres_bind.c				\
	tres_bind.h				\
	tres_frequency.c			\
	tres_frequency.h			\
	uid.c					\
	uid.h					\
	uthash.h				\
	util-net.c				\
	util-net.h				\
	working_cluster.c			\
	working_cluster.h			\
	write_labelled_message.c		\
	write_labelled_message.h		\
	x11_util.c				\
	x11_util.h				\
	xassert.c				\
	xassert.h				\
	xahash.c				\
	xahash.h				\
	xhash.c					\
	xhash.h					\
	xmalloc.c				\
	xmalloc.h				\
	xregex.c				\
	xregex.h				\
	xsystemd.c				\
	xsystemd.h				\
	xsignal.c				\
	xsignal.h				\
	xstring.c				\
	xstring.h

libcommon_la_LIBADD   = $(libselinux_LIBS)

libcommon_la_LDFLAGS  = $(LIB_LDFLAGS) -module --export-dynamic

# This was made so we could export all symbols from libcommon
# on multiple platforms
libcommon_o_SOURCES =
libcommon.o$(EXEEXT) :  $(libcommon_la_OBJECTS) $(libcommon_la_DEPENDENCIES)
	$(LINK)  $(libcommon_la_OBJECTS)

global_defaults.c : $(top_builddir)/config.h Makefile
	@( echo "/* This file autogenerated by src/common/Makefile */"; \
	   echo	"char *default_plugin_path = \"$(pkglibdir)\";"; \
	   echo \
	   "char *default_slurm_config_file = \"$(sysconfdir)/slurm.conf\";"; \
	 ) > global_defaults.c

force:
$(libcommon_la_LIBADD) : force
	@cd `dirname $@` && $(MAKE) `basename $@`
