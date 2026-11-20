FROM ghcr.io/archlinux/archlinux:base-devel@sha256:27cb43629f86710c95b41983fe326195f685cc2bdbd34d9516b39b8afc1c6bd2

RUN pacman -Syu --noconfirm \
 && pacman -S --needed --noconfirm sudo curl git \
 && pacman -Sccc --noconfirm

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
 && makepkg --sync --rmdeps --noconfirm \
 && sudo pacman -U --noconfirm "$pkg"-*.pkg.tar.zst \
 && popd \
 && rm -Rf "$dir" "$HOME/.cache" \
 && sudo pacman -Sccc

RUN dir="$(mktemp -d)" \
 && pkg="paru" \
 && git clone "https://aur.archlinux.org/$pkg.git" "$dir" \
 && pushd "$dir" \
 && makepkg --sync --rmdeps --noconfirm \
 && sudo pacman -U --noconfirm "$pkg"-*.pkg.tar.zst \
 && popd \
 && rm -Rf "$dir" "$HOME/.cache" \
 && sudo pacman -Sccc

ARG OUTPUT_DIR="/packages"
USER "root"
RUN mkdir "$OUTPUT_DIR" \
 && chown "$USERNAME:$USERNAME" "$OUTPUT_DIR"
COPY makepkg.conf /etc/makepkg.conf.d/z-makepkg.conf
USER "$USERNAME"
VOLUME "$OUTPUT_DIR"
