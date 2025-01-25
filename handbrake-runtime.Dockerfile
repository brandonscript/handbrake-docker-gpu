FROM zocker160/handbrake-nvenc:18x

# Copy built binaries from the shared volume
COPY --from=phantom/handbrake/builder /build/gtk/src/ghb /usr/bin/
COPY --from=phantom/handbrake/builder /build/HandBrakeCLI /usr/bin/
COPY --from=phantom/handbrake/builder /build/.cargo /root/
COPY --from=phantom/handbrake/builder /build/.rustup /root/

ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /

# Set up runtime environment
RUN apt-get update && apt-get install -y \
    nvtop locales nano gnupg2 pass \
    libgl1-mesa-dev mesa-common-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgstreamer-plugins-bad1.0-dev \
    gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-alsa \
    libva-dev libdrm-dev appstream desktop-file-utils \
    gettext gstreamer1.0-libav gstreamer1.0-plugins-good libgtk-4-dev \
    mesa-utils dbus dbus-x11 xdg-desktop-portal xdg-desktop-portal-gtk \
    xdg-desktop-portal-gnome x11-xserver-utils xdg-utils xauth sudo mutter-common

RUN dpkg-reconfigure locales

# Clean up
RUN apt-get autoremove -y && apt-get clean -y

# Create user & environment
RUN groupadd -g 1000 app && useradd -u 1000 -g 1000 -s /bin/bash -m app
ENV APP_USER_HOME=/config/home
RUN mkdir -p $APP_USER_HOME && usermod -d $APP_USER_HOME app

# Hardlink /root/.ghb to /config/ghb
RUN ln -s /config/ghb /root/.ghb

RUN rm /var/lib/dpkg/statoverride && rm /var/lib/dpkg/lock
RUN dpkg --configure -a
RUN apt-get -f install

# Fix permissions
RUN mkdir -p $APP_USER_HOME/xdg && echo "export XDG_RUNTIME_DIR=$APP_USER_HOME/xdg" >> $APP_USER_HOME/.bashrc
RUN chown -R app:app $APP_USER_HOME && chmod 777 $APP_USER_HOME

# Adjust the openbox config template (/opt/base/etc/openbox/rc.xml.template)
# - Delete <application %.*?>.*</application> (multiline, non-greedy) using perl
# - Add new content under `<!-- Main window should be maximized and without decoration. -->`:
#   <application %MAIN_APP_WINDOW_MATCH_CRITERIAS%>
#     <decor>yes</decor>
#     <fullscreen>yes</fullscreen>
#     <maximized>true</maximized>
#     <layer>below</layer>
#   </application>
RUN perl -0777 -i -pe 's/<application %.*?>.*?<\/application>//gs' /opt/base/etc/openbox/rc.xml.template
RUN perl -0777 -i -pe 's/(<!-- Main window should be maximized and without decoration. -->)/$1\n  <application %MAIN_APP_WINDOW_MATCH_CRITERIAS%>\n    <decor>no<\/decor>\n    <fullscreen>yes<\/fullscreen>\n    <maximized>true<\/maximized>\n    <layer>below<\/layer>\n  <\/application>/s' /opt/base/etc/openbox/rc.xml.template

# Back up /etc/passwd and /etc/group
RUN cp /etc/passwd /etc/passwd.bak && cp /etc/group /etc/group.bak

# Append restored messagebus user to /etc/cont-init.d/10-init-users.sh
RUN echo "echo 'systemd-network:x:101:102:systemd Network Management,,,:/run/systemd:/usr/sbin/nologin' >> /etc/passwd" >> /etc/cont-init.d/10-init-users.sh
RUN echo "echo 'systemd-resolve:x:102:103:systemd Resolver,,,:/run/systemd:/usr/sbin/nologin' >> /etc/passwd" >> /etc/cont-init.d/10-init-users.sh
RUN echo "echo 'systemd-journal:x:101:' >> /etc/group" >> /etc/cont-init.d/10-init-users.sh
RUN echo "echo 'systemd-network:x:102:' >> /etc/group" >> /etc/cont-init.d/10-init-users.sh
RUN echo "echo 'systemd-resolve:x:103:' >> /etc/group" >> /etc/cont-init.d/10-init-users.sh
RUN echo "echo 'messagebus:x:103:104::/var/run/dbus:/bin/false' >> /etc/passwd" >> /etc/cont-init.d/10-init-users.sh
RUN echo "echo 'messagebus:x:104:' >> /etc/group" >> /etc/cont-init.d/10-init-users.sh

# Set home dir for 'app' user in /etc/passwd to $APP_USER_HOME
RUN echo "sed -i 's|app::1000:1000::/dev/null:/sbin/nologin|app::1000:1000::$APP_USER_HOME:/bin/bash|' /etc/passwd" >> /etc/cont-init.d/10-init-users.sh
RUN mkdir -p /run/dbus && chown messagebus:messagebus /run/dbus

# Symmlink /var/run/dbus to /run/dbus
RUN ln -s /run/dbus /var/run/dbus

# RUN export $(dbus-launch) && echo "export $(dbus-launch)" >> $APP_USER_HOME/.bashrc
RUN gsettings set org.gnome.mutter overlay-key ''

# Add 'app' user to sudo group
RUN usermod -aG sudo app && echo "app ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Add/install Adwaita-dark theme if it doesn't exist
RUN apt-get update && apt-get install -y adwaita-icon-theme-full \
    gnome-session ubuntu-session yaru-* gnome-themes-extra

# Copy ./startapp.sh to /startapp.sh
COPY ./startapp.sh /startapp.sh
COPY ./54-ghb-custom.sh /etc/cont-init.d/54-ghb-custom.sh

# Make startapp.sh executable
RUN chmod +x /startapp.sh

# Set container GTK environment variables
RUN set-cont-env XDG_RUNTIME_DIR $APP_USER_HOME/xdg
RUN set-cont-env DBUS_SESSION_BUS_ADDRESS $(dbus-launch | sed "s/DBUS_SESSION_BUS_ADDRESS=//")
RUN mkdir -p /root/.dbus && chown -R root:root /root/.dbus && chmod -R 777 /root/.dbus

WORKDIR /
