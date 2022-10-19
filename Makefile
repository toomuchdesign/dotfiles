DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
NVM_DIR := $(HOME)/.nvm
export XDG_CONFIG_HOME = $(HOME)/.config

install: sudo core packages link pdf-quartz-filters

sudo:
	sudo -v
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

#
# CORE
#
core: brew zsh git npm

brew:
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

zsh: brew
	brew install zsh
# Make zsh default shell
	chsh -s /usr/local/bin/zsh
# Create zsh config file if necessary
	touch ~/.zshrc
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

git: brew install git git-extras

# Consider swithing to fnm
npm:
	if ! [ -d $(NVM_DIR)/.git ]; then git clone https://github.com/creationix/nvm.git $(NVM_DIR); fi
	. $(NVM_DIR)/nvm.sh; nvm install --lts

#
# PACKAGES
#
packages: brew-packages cask-apps node-packages

brew-packages: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Brewfile --no-upgrade

cask-apps: brew
	brew bundle --file=$(DOTFILES_DIR)/install/Caskfile --no-upgrade

node-packages: npm
	. $(NVM_DIR)/nvm.sh; npm install -g $(shell cat install/npmfile)

#
# LINK
#
stow: brew
	is-executable stow || brew install stow

link: stow
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE -a ! -h $(HOME)/$$FILE ]; then \
		mv -v $(HOME)/$$FILE{,.bak}; fi; done
	mkdir -p $(XDG_CONFIG_HOME)
	stow -t $(HOME) runcom
	stow -t $(XDG_CONFIG_HOME) config

unlink: stow
	stow --delete -t $(HOME) runcom
	stow --delete -t $(XDG_CONFIG_HOME) config
	for FILE in $$(\ls -A runcom); do if [ -f $(HOME)/$$FILE.bak ]; then \
		mv -v $(HOME)/$$FILE.bak $(HOME)/$${FILE%%.bak}; fi; done

# Install PDF filter (should not work)
pdf-quartz-filters:
	sudo mkdir -p /Library/PDF\ Services && sudo ln -sfn $(DOTFILES_DIR)/install/pdf-quartz-filters/ /Library/PDF\ Services/

# Stow test commands:
# stow --adopt -nvSt ~ runcom
# stow --adopt -nvSt ~ config
