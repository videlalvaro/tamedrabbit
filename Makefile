ERTS_VSN=$(shell erl -noshell -eval 'io:format("~s", [erlang:system_info(version)]), halt().')
ERTS_ROOT_DIR=$(shell erl -noshell -eval 'io:format("~s", [code:root_dir()]), halt().')

VERSION?=0.0.0
TARBALL_NAME=rabbitmq-server-$(VERSION)
RMQ_SOURCE_URL=http://www.rabbitmq.com/releases/rabbitmq-server/v$(VERSION)/rabbitmq-server-$(VERSION).tar.gz

RLS_BUILD_DIR=pre-release/build
RLS_DIR=$(RLS_BUILD_DIR)/$(TARBALL_NAME)
TMP_BUILD_DIR=/tmp/$(TARBALL_NAME)
SRC_TARBALL=/tmp/$(TARBALL_NAME).tar.gz
RABBITMQ=$(TMP_BUILD_DIR)/ebin/rabbit.beam

# used to generate the erlang release
RABBITMQ_HOME=$(RLS_DIR)
RABBITMQ_EBIN_ROOT=$(RABBITMQ_HOME)/ebin
RABBITMQ_ENABLED_PLUGINS_FILE=$(RABBITMQ_HOME)/etc/rabbitmq/enabled_plugins
RABBITMQ_PLUGINS_DIR=$(RABBITMQ_HOME)/plugins
RABBITMQ_PLUGINS_EXPAND_DIR=$(RABBITMQ_PLUGINS_DIR)/expand

PLUGINS?=rabbitmq_management

.PHONY : clean-build-dir
clean-build-dir:
	rm -rf $(TMP_BUILD_DIR)

.PHONY : clean-release-dir
clean-release-dir:
	rm -rf $(RLS_BUILD_DIR)

.PHONY : clean
clean: clean-build-dir clean-release-dir

$(TMP_BUILD_DIR):
	curl -o $(SRC_TARBALL) $(RMQ_SOURCE_URL)
	tar -C /tmp -xzvf $(SRC_TARBALL)

$(RABBITMQ): $(TMP_BUILD_DIR)
	$(MAKE) -C $(TMP_BUILD_DIR)

.PHONY : generate_release
generate_release:
	erl \
	    -pa "$(RABBITMQ_EBIN_ROOT)" \
	    -pa erlang \
	    -noinput \
	    -hidden \
	    -s rabbit_release \
	    -extra "$(RABBITMQ_ENABLED_PLUGINS_FILE)" "$(RABBITMQ_PLUGINS_DIR)" "$(RABBITMQ_PLUGINS_EXPAND_DIR)" "$(RABBITMQ_HOME)"

release: $(RABBITMQ) clean-release-dir
# prepare build directory
	mkdir -p $(RLS_DIR)
# copy server files
	cp -r $(TMP_BUILD_DIR)/ebin $(TMP_BUILD_DIR)/include $(TMP_BUILD_DIR)/plugins $(RLS_DIR)
# prepare sbin folder
	mkdir -p $(RLS_DIR)/sbin
	cp pre-release/templates/rabbit* $(RLS_DIR)/sbin/
	sed 's/%%VSN%%/$(VERSION)/' pre-release/templates/rabbitmq-env > $(RLS_DIR)/sbin/rabbitmq-env
	sed 's/%%ERTS_VSN%%/erts-$(ERTS_VSN)/' pre-release/templates/rabbitmq-defaults > $(RLS_DIR)/sbin/rabbitmq-defaults
	chmod +x $(RLS_DIR)/sbin/*
# copy enabled plugins file
	mkdir -p $(RLS_DIR)/etc/rabbitmq
	echo "[$(PLUGINS)]." > $(RLS_DIR)/etc/rabbitmq/enabled_plugins
	mkdir -p $(RLS_DIR)/plugins/expand
# generate release files
	erlc -I $(RLS_DIR)/include/ -o erlang -Wall -v +debug_info -Duse_specs -Duse_proper_qc -pa $(RLS_DIR)/ebin/ erlang/rabbit_release.erl
	$(MAKE) generate_release
	rm -r $(RLS_DIR)/*
	tar -C $(RLS_DIR) -xzvf pre-release/rabbit.tar.gz
# copy post_install script
	mkdir $(RLS_DIR)/bin
	sed 's/%%ERTS_VSN%%/$(ERTS_VSN)/' pre-release/templates/post_install.sh > $(RLS_DIR)/bin/post_install.sh
# add the start_server command
	sed 's/%%VSN%%/$(VERSION)/' pre-release/templates/start_server > $(RLS_DIR)/bin/start_server.tmp
	sed 's/%%ERTS_VSN%%/erts-$(ERTS_VSN)/' $(RLS_DIR)/bin/start_server.tmp > $(RLS_DIR)/bin/start_server
# add the stop_server command
	sed 's/%%VSN%%/$(VERSION)/' pre-release/templates/stop_server > $(RLS_DIR)/bin/stop_server.tmp
	sed 's/%%ERTS_VSN%%/erts-$(ERTS_VSN)/' $(RLS_DIR)/bin/stop_server.tmp > $(RLS_DIR)/bin/stop_server
	rm $(RLS_DIR)/bin/*.tmp
	chmod +x  $(RLS_DIR)/bin/*
# add minimal boot file
	cp $(ERTS_ROOT_DIR)/bin/start_clean.boot $(RLS_DIR)/releases/$(VERSION)
# add README file
	cp pre-release/templates/README $(RLS_DIR)/README
# add LICENSE files
	cp  $(TMP_BUILD_DIR)/LICENSE* $(RLS_DIR)
# add VERSION file
	echo "$(VERSION)" > $(RLS_DIR)/VERSION
# add etc and var dirs
	mkdir -p $(RLS_DIR)/etc/rabbitmq
	mkdir -p $(RLS_DIR)/var/log/rabbitmq
	mkdir -p $(RLS_DIR)/var/lib/rabbitmq/mnesia
# generate final tar
	(cd $(RLS_BUILD_DIR); tar -zchf $(TARBALL_NAME)u.tar.gz $(TARBALL_NAME))
# clean up
	rm pre-release/rabbit.tar.gz
	rm -rf $(RLS_DIR)
