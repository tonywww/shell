# shell
This is a group of linux shell script files for VPS installation.

Tested on Debian 9/10 , Ubuntu 18.04/20.04 and Centos 7.

## Usage

 * Download and run the shell script file under **root** :

   (Replace`<file-name>`to the name of shell script file)

````shell
wget https://github.com/tonywww/shell/raw/master/<file-name>.sh
chmod +x <file-name>.sh
./<file-name>.sh
````

 * Run the shell script file under **root** without download :

   (Replace`<file-name>`to the name of shell script file)
````shell
bash <(wget -qO- https://github.com/tonywww/shell/raw/master/<file-name>.sh)
````

## License
[BSD 2-Clause](LICENSE.txt) © tonywww
