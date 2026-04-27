FROM ghcr.io/archlinux/archlinux:base-devel@sha256:4b67943a420a1328c160e6bdf700a7ad0c5ceacc1b9f087ca0596734aac9a43f

RUN pacman -Syu --noconfirm
RUN pacman -S --needed --noconfirm sudo curl git
RUN echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel

ARG USERNAME="builder"
ARG HOME="/home/$USERNAME"
RUN useradd -d "$HOME" -m "$USERNAME" \
 && gpasswd -a "$USERNAME" wheel

USER "$USERNAME"
WORKDIR "$HOME"

RUN dir="$(mktemp -d)" \
 && pkg="yay" \
 && git clone "https://aur.archlinux.org/$pkg.git" "$dir" \
 && pushd "$dir" \
 && makepkg --sync --noconfirm \
 && sudo pacman -U --noconfirm "$pkg"-*.pkg.tar.zst \
 && popd \
 && rm -Rf "$dir"

RUN dir="$(mktemp -d)" \
 && pkg="paru" \
 && git clone "https://aur.archlinux.org/$pkg.git" "$dir" \
 && pushd "$dir" \
 && makepkg --sync --noconfirm \
 && sudo pacman -U --noconfirm "$pkg"-*.pkg.tar.zst \
 && popd \
 && rm -Rf "$dir"

ARG OUTPUT_DIR="/packages"
USER "root"
RUN mkdir "$OUTPUT_DIR" \
 && chown "$USERNAME:$USERNAME" "$OUTPUT_DIR"
COPY makepkg.conf /etc/makepkg.conf.d/z-makepkg.conf
USER "$USERNAME"
VOLUME "$OUTPUT_DIR"
