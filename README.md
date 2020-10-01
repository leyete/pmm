<h1 align="center">
    Personal Module Manager
</h1>
<h4 align="center">Manage and deploy configurations and tools like a package manager.</h4>

<p align="center">
    <a href="http://www.wtfpl.net/"><img src="https://img.shields.io/badge/license-WTFPL-black" alt="WTFPL" /></a>
    <a href="http://zsh.sourceforge.net/"><img src="https://img.shields.io/badge/zsh-5.8-blue" alt="Zsh version" /></a>
</p>

Personal Module Manager is a simple *work-in-progress* tool I've developed
to make it easier to deploy system configurations and install tools on new
systems and keep them synchronize across all your machines. As a person who
likes to tweak and try new configurations and setups, I felt the need of
something like this and while I was at it, learn more about ZSH scripting.

The idea is to bundle dotfiles and required tools/scripts ("targets") in
modules and keep those modules inside a git repository so they can be fetched
from any system. After adding the desired repositories, the modules can be
installed and updated using this tool.

This tool has been developed and tested with ZSH >= v5.8 altough it may
work on previous versions.

## Installation

Install the pre-built latest stable verison from the repository:

    curl -L https://raw.githubusercontent.com/leyete/pmm/master/bin/pmm > pmm
    # Put the downloaded file somewhere in your $PATH and you should be ready to go.

Or alternatively, clone the repository and build it yourself:

    git clone --depth=1 https://github.com/leyete/pmm.git
    cd pmm
    make build
    sudo make install
    # If you don't want pmm to be installed in the default /usr/local prefix,
    # specify an alternative one with the PREFIX variable.

## Usage

PMM has been developed with [pacman](https://wiki.archlinux.org/index.php/Pacman)
in mind, so if you are familiar with Arch Linux's package manager, this will be
straight forward:

    $ pmm -S module1
    # Looks for 'module1' in the local repositories and installs it.

    $ pmm -S leyete/modules/python
    # Installs the 'python' module from the repository leyete/modules.

    $ pmm -Sy
    # Updates the local repositories.

    $ pmm -Su
    # Upgrades all installed targets, you can specify targets to upgrade just
    # the desired ones.

    $ pmm -h
    # See more help about the command, if I ever have time to do it, I would
    # like to write a wiki page with a more in-depth look at the available
    # options and operations.

## Motivation

I decided to dive in ZSH scripting, so I figured it was a good idea to start
a new project to put in practice the things I've been learing. Since I like
to tweak my systems and try new setups and configurations, the need for a tool
that automated the process of installing my scripts/tools and configurations
drove me into writing this.

If this project reaches and interests someone, please feel free to tell me your
thoughts, any feedback is very welcome.

## Disclaimer

PMM is currently heavily unstable as it is still in a very early developement
stage. Some functionality might not work propertly or at all. Use it with
caution and at your own risk.
