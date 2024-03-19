To use the --jobs option with bats, you need to have either GNU parallel or shenwei356/rush installed on your system. Here's how you can install them:

## GNU parallel:
```shell
sudo apt-get install parallel
```

## shenwei356/rush:

### First, download the latest release from the GitHub releases page:
```shell
wget https://github.com/shenwei356/rush/releases/download/v0.3.2/rush_linux_amd64.tar.gz
```
### Then, extract the downloaded file:
```shell
tar -xvf rush_linux_amd64.tar.gz
```
### Finally, move the rush binary to a directory in your PATH:
```shell
sudo mv rush /usr/local/bin/
```
Please replace the URL in the wget command with the URL of the latest release. You can find this URL on the GitHub releases page for rush.

After installing either parallel or rush, you should be able to use the --jobs option with bats.