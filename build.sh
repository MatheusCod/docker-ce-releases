set -e
ftp_path="ftp://oplab9.parqtec.unicamp.br/ppc64el/docker"
ftp_repo1="ftp://oplab9.parqtec.unicamp.br/repository/debian/ppc64el/docker"
ftp_repo2="ftp://oplab9.parqtec.unicamp.br/repository/rpm/ppc64le/docker"
url="https://oplab9.parqtec.unicamp.br/pub/ppc64el/docker"

home_dir=$(pwd)
git_ver=$(cat github_version.txt)
ftp_ver=$(cat ftp_version.txt)
# del_version=$(cat delete_version.txt)

echo "=========> [CHECKING IF BUILD EXISTS] >>> "
if [ $git_ver != $ftp_ver ]
then

    echo "=========> [CLONNING <$git_ver> AND PATCHING] >>>"

    git clone https://github.com/docker/cli.git
    git clone https://github.com/moby/moby
    git clone https://github.com/docker/scan-cli-plugin
    git clone https://github.com/docker/docker-ce-packaging.git
    
    cd cli
    git checkout v$git_ver
    git config --global user.name "Your Name"
    git config --global user.email "user@example.com"
    git add . && git commit -m "using community containerd versions"
    cd ..
    
    python3 ../patch.py
    mkdir -p docker-ce-packaging/src/github.com/docker/cli
    mkdir -p docker-ce-packaging/src/github.com//docker/docker
    mkdir -p docker-ce-packaging/src/github.com/docker/scan-cli-plugin
    sudo cp -r cli/* docker-ce-packaging/src/github.com/docker/cli
    sudo cp -r moby/* docker-ce-packaging/src/github.com/docker/docker
    sudo cp -r scan-cli-plugin/* docker-ce-packaging/src/github.com/docker/scan-cli-plugin
    
    echo "=========> [BUILDING <$sys> PACKAGES] >>>"
    
    if [ ${distro} == "debian" ]
    then
      cd docker-ce-packaging/deb
      sudo VERSION=$git_ver make $sys
      cd debbuild/$sys
      
      echo "=========> [CREATING FTP FOLDER] >>> "
      lftp -c "open -u $USER,$PASS $ftp_path; mkdir -p version-$git_ver/$sys"

      echo "=========> [SENDING PACKAGES TO FTP] >>>"
      cd $home_dir/$bin_dir
      lftp -c "open -u $USER,$PASS $ftp_path/version-$git_ver/$sys; mirror -R ./ ./"
      sudo rm -rf $home_dir/$bin_dir
      
      echo "=========> [SENDING PACKAGES TO REPOSITORY <$sys>] >>>"
      cd $home_dir
      mkdir upload
      cd upload
      wget https://oplab9.parqtec.unicamp.br/pub/ppc64el/docker/version-$git_ver/ubuntu-bionic/docker-ce-cli_$git_ver~3-0~ubuntu-bionic_ppc64el.deb
      wget https://oplab9.parqtec.unicamp.br/pub/ppc64el/docker/version-$git_ver/ubuntu-bionic/docker-ce_$git_ver~3-0~ubuntu-bionic_ppc64el.deb
      lftp -c "open -u $USER,$PASS $ftp_repo1; mirror -R ./ ./"
      cd ..
      rm -rf upload/
    fi

fi

echo "=========> [DONE]"
