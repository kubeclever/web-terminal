FROM centos:centos7 


USER root

ARG USERNAME=datanaut
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG HOME_DIR=/home/$USERNAME
# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && yum update -y \
    && yum install -y sudo net-tools iproute iputils util-linux yum-utils vim cpio \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME \
    && mkdir /yum \
    && yum clean all
    
ADD src /usr/bin/

RUN chmod +x /usr/bin/tini && chmod +x /usr/bin/kubectl && chmod +x /usr/bin/ttyd && chmod +x /usr/bin/istioctl \
    && chown $USERNAME:$USERNAME -R  /usr/bin/
    
USER $USERNAME

RUN yumdownloader --destdir ~/rpm --resolve bash-completion \
    && mkdir ~/centos \
    && cd ~/centos && rpm2cpio ~/rpm/$(ls ~/rpm) | cpio -id \
    # rpm2cpio outputs the .rpm file as a .cpio archive on stdout.
    # cpio reads it from from stdin
    # -i means extract (to the current directory)
    # -d means create missing directory
    # -v verbose
    && export PATH="$HOME/centos/usr/sbin:$HOME/centos/usr/bin:$HOME/centos/bin:$PATH" \
    && export MANPATH="$HOME/centos/usr/share/man:$MANPATH" \
    && L='/lib:/lib64:/usr/lib:/usr/lib64' \
    && export LD_LIBRARY_PATH="$HOME/centos/usr/lib:$HOME/centos/usr/lib64:$L" \
    && echo 'source <(kubectl completion bash)' >> ~/.bashrc \
    && echo 'alias k=kubectl' >>~/.bashrc \
    && echo 'complete -o default -F __start_kubectl k' >>~/.bashrc \
    && echo 'source ~/centos/usr/share/bash-completion/bash_completion' >>~/.bashrc \
    && echo 'PS1="\e[0;32m[\u@\h \W]\$ \e[0m"' >>~/.bashrc

EXPOSE 7681
WORKDIR $HOME_DIR

ENTRYPOINT ["tini", "--"]
CMD ["ttyd", "bash"]
