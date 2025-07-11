wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&  dpkg -i cloudflared-linux-amd64.deb && rm cloudflared-linux-amd64.deb
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && bash ~/miniconda.sh -b -p $HOME/miniconda && rm ~/miniconda.sh
echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
conda init bash && source ~/.bashrc
