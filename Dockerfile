# FROM ubuntu:16.04
FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

MAINTAINER Douglas Holt "dholt@nvidia.com"

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY :1
ENV VNC_PORT 5901
ENV NO_VNC_PORT 6901
EXPOSE $VNC_PORT $NO_VNC_PORT

ENV HOMELESS /headless
ENV STARTUPDIR /dockerstartup
WORKDIR $HOMELESS

### Envrionment config
ENV DEBIAN_FRONTEND noninteractive
ENV NO_VNC_HOME $HOMELESS/noVNC
ENV VNC_COL_DEPTH 24
ENV VNC_RESOLUTION 1280x1024
ENV VNC_PW vncpassword

### Add all install scripts for further steps
ENV INST_SCRIPTS $HOMELESS/install
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/ubuntu/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install firfox and chrome browser
RUN $INST_SCRIPTS/firefox.sh
# for chrome to work run container with --privileged option
# or use --no-sandbox option otherwise error:
#     Failed to move to new namespace: PID namespaces supported,
#     Network namespace supported, but failed: errno = Operation not permitted
# RUN $INST_SCRIPTS/chrome.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOMELESS/

### Install Docker
RUN $INST_SCRIPTS/docker.sh

### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOMELESS

ENV HOME $HOMELESS

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--tail-log"]

