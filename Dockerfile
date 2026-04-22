FROM ghcr.io/archlinux/archlinux:base-devel@sha256:abf71659bfae13a155e3014fe82ae0ead2f3abc9172450934f1d1779cee3304f

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

