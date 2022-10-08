#!/bin/bash
# Setting up an Amazon Linux 2 Instance with the Deep Learning AMI
set -e -x

setup_dev_tools () {

    echo "(1/8) SETTING UP DEV TOOLS"

    yum update -y
    yum groupinstall "Development Tools" -y
    yum erase openssl-devel -y
    yum install openssl11 openssl11-devel  libffi-devel bzip2-devel wget -y

    # Install htop
    yum -y install htop

}

setup_zsh () {

    echo "(7/8) SETTING UP ZSH..."

    local DIR=/home/ec2-user

    yum -y update && yum -y install zsh

    # Install oh-my-zsh
    wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O $DIR/install.sh
    chown -R ec2-user:ec2-user $DIR/install.sh
    cd $DIR
    echo pwd
    runuser -l ec2-user 'install.sh'

    # Change the default shell to zsh
    yum -y install util-linux-user
    chsh -s /bin/zsh ec2-user

    # Add conda to end of zshrc
    #echo "source ~/.dlamirc" >> $DIR/.zshrc

}


setup_python () {

    echo "(2/8) SETTING UP PYTHON"

    local DIR=/home/ec2-user
    local PYTHON_VERSION=3.10.7

    cd $DIR
    wget https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
    tar -xf Python-$PYTHON_VERSION.tgz
    #chown -R ec2-user:ec2-user Python-$PYTHON_VERSION

    cd Python-$PYTHON_VERSION
    ./configure --enable-optimizations
    make -j $(nproc)
    sudo make altinstall
    cd ..

    sudo yum -y install python3-pip

}

setup_nodejs () {

    echo "(2/8) SETTING UP NODEJS"

    local DIR=/home/ec2-user

    cd $DIR
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    . ~/.nvm/nvm.sh
    nvm install --lts
    cd ..

}

setup_neovim () {

    echo "(4/8) SETTING UP NEOVIM..."

    local DIR=/home/ec2-user

    sudo yum install -y cmake
    sudo python3.10 -m pip install neovim --upgrade
    (
        cd $DIR
        tmpdir="$(mktemp -d)"
        cd $tmpdir
        git clone https://github.com/neovim/neovim.git
        cd neovim
        make CMAKE_BUILD_TYPE=Release
        sudo make install
        cd ../../
        rm -r $tmpdir
    )

}

setup_vim () {

    echo "(5/8) SETTING UP VIM..."
    local DIR=/home/ec2-user


    # Install black for formatting
    pip3 install black

    # Install vim plug for package management
    curl -fLo $DIR/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    chown -R ec2-user:ec2-user $DIR/.vim
    # Install packages
    runuser -l ec2-user -c 'vim +PlugInstall +qall'

}

setup_tmux () {

    echo "(6/8) SETTING UP TMUX..."
    # Install tmux dependencies
    yum -y install ncurses-devel
    yum -y install libevent-devel

    # Get the latest version
    git clone https://github.com/tmux/tmux.git
    cd tmux
    sh autogen.sh
    ./configure && make install
    cd ..

    # Get a simple startup script
    mv /home/ec2-user/dev-env/aws/stm.sh /bin/stm 
    chmod +x /bin/stm

}

get_dotfiles () {

    echo "(3/8): GETTING DOTFILES..."

    local DIR=/home/ec2-user
    git clone https://github.com/parkh/dev-env.git $DIR/dev-env
    ln -s $DIR/dev-env/dotfiles/.quotes $DIR/.quotes
    ln -s $DIR/dev-env/dotfiles/.tmux.conf $DIR/.tmux.conf
    ln -s $DIR/dev-env/dotfiles/.vimrc $DIR/.vimrc
    ln -s $DIR/dev-env/dotfiles/.vimrc $DIR/.config/nvim/init.vim
    chown -R ec2-user:ec2-user \
        $DIR/dev-env \
        $DIR/.tmux.conf \
        $DIR/.vimrc \
        $DIR/.config/nvim/init.vim \
        $DIR/.quotes

}

setup_dev_tools
setup_zsh
setup_python
setup_nodejs
setup_neovim
setup_tmux
get_dotfiles