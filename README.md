# runall
An utility to run a command (or a script) in multiple hosts, using ssh (useful for multiple host management)

## Installation

### From packages

Get the appropriate package and install

**Ubuntu**

```
$ wget https://github.com/dealfonso/runall/releases/download/1.0-beta/runall_1.0-beta.0.deb
$ apt update
$ apt install -f ./runall_1.0-beta.0.deb
```

### From sources

Install dependencies

**Ubuntu**

```
$ apt update && apt install -y coreutils grep ssh-client
```

**CenOS**
```
$ yum update && yum install -y openssh-clients grep coreutils
```

Get the code and install

```
$ git clone https://github.com/dealfonso/runall
$ cd runall/src
$ ./INSTALL.sh
```

## Usage

Examples of use

```
root@ramses:~# runall --summarize --hostlist torito0[1-9] --hostlist torito[10-11] -- hostname

SUMMARY:
hosts:
torito01 torito02 torito03 torito04 torito05 torito06 torito07 torito08 torito09 torito10 torito11

command:
export LANG=C
export LC_ALL=C
hostname

press return to continue (CTRL-C aborts) 
torito01
torito02
torito03
torito04
torito05
torito06
torito07
torito08
torito09
torito10
torito11
```

We can make the list of hosts persistent by adding it to the configuration file
```
root@ramses:~# echo "HOSTS=torito0[1-9],torito[10-11]" >> /etc/runall/runall.conf
```

Then you can run commands like the next one:

```
root@ramses:~# runall -X torito0[3-9] -- hostname
torito01
torito02
torito10
torito11
```

Using the flag `-O` the list of hosts in the configuration file will be ignored, and flag `-l` also runs the command in the host (using command `hostname`):

```
root@ramses:~# runall -H torito0[1-2] -O -l -- hostname
torito01
torito02
ramses
```