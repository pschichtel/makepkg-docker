FROM ghcr.io/archlinux/archlinux:base-devel@sha256:ea34bcba6d30a9fa7906c9ff8ff7b1f314886af12b7098d68a26c0fd0e7c65f7

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
