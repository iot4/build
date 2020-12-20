
SSH_PASSWD ="ncdio"
SSH_TARGET = root@192.168.8.3:/www
#SSH_TARGET = root@192.168.3.1:/www
HOST_DIR = /mnt/shared/ncd/www

.PHONY: host target

host: $(HOST_DIR)
	cp -a index.lua $(HOST_DIR)
	cp -a htdocs/* $(HOST_DIR)/htdocs/
	cp -a css/* $(HOST_DIR)/css/
	cp -a images/* $(HOST_DIR)/images/
	cp -a fonts/* $(HOST_DIR)/fonts/

target:
	sshpass -p $(SSH_PASSWD) scp -r index.lua $(SSH_TARGET)
	sshpass -p $(SSH_PASSWD) scp -r htdocs/* $(SSH_TARGET)/htdocs/
	sshpass -p $(SSH_PASSWD) scp -r css/* $(SSH_TARGET)/css/
	sshpass -p $(SSH_PASSWD) scp -r images/* $(SSH_TARGET)/images/
	sshpass -p $(SSH_PASSWD) scp -r fonts/* $(SSH_TARGET)/fonts/

$(HOST_DIR):
	mkdir -p $(HOST_DIR)/htdocs
	mkdir -p $(HOST_DIR)/css
	mkdir -p $(HOST_DIR)/images
	mkdir -p $(HOST_DIR)/fonts
