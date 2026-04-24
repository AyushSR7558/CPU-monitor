# Filesystem
Filesystem is used to control how data is stored and retrieved. Without a file system, information placed in a storage medium would be one large body of data with no way to tell where one peiece of information stops and the next begin. Byseparating the data intot pieces and giving each piece a name, the information is easily isolated and identifies. Taking its name from the way paper-based information systemms are named, each group of data is called a "file". The structure and logic rulles used to manage the groups of information and their name is called the "file system".


# Driver
A Driver is a software program that allows the operating system to communicate with a hardware device.
🔹 In your USB example

When you plug in a pen drive:

OS detects device
Loads USB mass storage driver
Now it can access files

👉 The driver makes the device usable


Linux follow the proc file System

## Proc File System
The proc file system is the virtual file system in os that provides information about process and the kernel

It is the interface where the OS exposes internal information as files.

It files created and saved on the ram.

It is used to debug process

This are only the read only files
/proc/memeory


Writeable files
	/proc/sys/net/ipv4/ip_forward
If you run 
	echo 1 > /proc/sys/net/ipv4/ip_forward	// You are telling kernel To forward the IP

What actually Happen
	When we write to the file. The Kernel intercept it. Kernel updates an internal variables or setting. System behavior changes  immediatedly



We can build these project with the help of two virtual filesystem i.e sys and proc
we will be using the proc file syste which is mounted at the position /poc/stat
For man page use "man 5 proc_stat"


head command is used to get only the top 10 line. If you want to get the 16 line you can do it by "head -16 <file_name>"




## Project Decision
- Instead of looking at diff aspects like "how much time you spend on user", "how much time you spen on the i/o" & bla bla bla... 
	We will instead categories it into two whether you are busy or not

