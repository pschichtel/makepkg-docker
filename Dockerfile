FROM ghcr.io/archlinux/archlinux:base-devel@sha256:a1bab30f5e707199a899cc72b7e2e01fa2c997c2cefabfc780c02f26b094607b

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

