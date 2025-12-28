FROM ghcr.io/archlinux/archlinux:base-devel@sha256:dcf1320fe9cced67d7a5a961fcd48a1a872082813c127e87da701ef8016341ef

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
 && git clone https://aur.archlinux.org/yay.git "$dir" \
 && pushd "$dir" \
 && makepkg --sync --noconfirm \
 && sudo pacman -U --noconfirm yay-*.pkg.tar.zst \
 && popd \
 && rm -Rf "$dir"

ARG OUTPUT_DIR="/packages"
USER "root"
RUN mkdir "$OUTPUT_DIR" \
 && chown "$USERNAME:$USERNAME" "$OUTPUT_DIR"
COPY makepkg.conf /etc/makepkg.conf.d/z-makepkg.conf
USER "$USERNAME"
VOLUME "$OUTPUT_DIR"

