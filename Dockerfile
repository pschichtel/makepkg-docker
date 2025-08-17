FROM ghcr.io/archlinux/archlinux:base-devel@sha256:395a366e7ab832a9a306377b63908685ea5f64145eabe026a8e469baf44474e9

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

USER "root"
RUN mkdir /packages
COPY makepkg.conf /etc/makepkg.conf.d/z-makepkg.conf
USER "$USERNAME"

