scirpt_dir=$(dirname "$0")
# save backup of existing .bashrc and .profile files, if they exist
## if the backups already exist, set the current files to the backups
#if [ -f $HOME/.bashrc.bak ]; then
#    cp $HOME/.bashrc.bak $HOME/.bashrc
#else
#    cp $HOME/.bashrc $HOME/.bashrc.bak
#fi

if [ -f $HOME/.profile.bak ]; then
    cp $HOME/.profile.bak $HOME/.profile
else
    cp $HOME/.profile $HOME/.profile.bak
fi


## append our customizations to the existing files
#cat $scirpt_dir/.bashrc >> $HOME/.bashrc
#cat $scirpt_dir/.profile >> $HOME/.profile

# add confirmation prompt for removing .vim directory
if [ -d $HOME/.vim ]; then
    read -p "Remove existing .vim directory? (y/N) " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf $HOME/.vim
    fi
fi

cp -r $scirpt_dir/.vim $HOME/.vim

cp $scirpt_dir/.vimrc $HOME/.vimrc
cp $scirpt_dir/.screenrc $HOME/.screenrc
