/*	The 99 Bottles of Beer Linux Kernel Module v1.1
 *	(supports multiple driver instances)
 *
 *	by Stefan Scheler <sts[at]synflood[dot]de>
 *	August 2nd, 2005 - Ernstthal, Germany
 *
 *	Usage:
 *	1) compile the module
 *	2) create the device: mknod /dev/bottles c 240 0
 *	3) load the module: insmod bottles.ko
 *	4) print the song with: cat /dev/bottles
 */

#include <linux/fs.h>
#include <linux/version.h>
#include <linux/module.h>
#include <linux/init.h>
#include <asm/uaccess.h>

#define DRIVER_MAJOR 240
#define BUFFERSIZE 160
#define PLURALS(b) (b>1)?"s":""

MODULE_AUTHOR("Stefan Scheler <sts[at]synflood[dot]de>");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("The 99 Bottles of Beer Linux Kernel Module");
MODULE_SUPPORTED_DEVICE("Bottle of Beer");

struct _instance_data {
	int bytes_avail, bytes_sent, bottles;
	char buf[BUFFERSIZE];
};

static void fill_buffer(char *buf, int b) {
	char line[BUFFERSIZE/2];
	if (b>0) {
		sprintf(buf, "%d bottle%s of beer on the wall, %d bottle%s of beer.\n" \
				"Take one down and pass it around, ", b, PLURALS(b), b, PLURALS(b));
		if (b==1)
			strcat(buf, "no more bottles of beer on the wall.\n");
		else {
			sprintf(line, "%d bottle%s of beer on the wall.\n", b-1, PLURALS(b-1));
			strcat(buf, line);
		}
	} else {
		sprintf(buf, "No more bottles of beer on the wall, no more bottles of beer.\n" \
				"Go to the store and buy some more, 99 bottles of beer on the wall.\n");
	}
}

static ssize_t driver_read(struct file *instance, char *userbuffer, size_t count, loff_t *offset) {
	struct _instance_data *iptr = (struct _instance_data *)instance->private_data;

	int to_copy;
	int not_copied;

refillbuffer:
	fill_buffer(iptr->buf, iptr->bottles);
	iptr->bytes_avail = strlen(iptr->buf)+1;
	to_copy = iptr->bytes_avail-iptr->bytes_sent;

	if (to_copy>0) {
		if (to_copy> count) to_copy=count;
		not_copied=copy_to_user(userbuffer, iptr->buf+iptr->bytes_sent, to_copy);
		iptr->bytes_sent += to_copy-not_copied;
		return (to_copy-not_copied);
	}

	if ((to_copy==0) && (iptr->bottles>0)) {
		iptr->bytes_sent=0;
		iptr->bottles--;
		goto refillbuffer;
	}

	return 0;
}

int driver_open(struct inode *devicefile, struct file *instance)  {
	struct _instance_data *iptr;
	iptr = (struct _instance_data *)kmalloc(sizeof(struct _instance_data), GFP_KERNEL);

	if (!iptr)
		return -1;

	iptr->bytes_sent = 0;
	iptr->bottles = 99;
	instance->private_data = iptr;

	return 0;
}

int driver_close(struct inode *devicefile, struct file *instance)  {
	if (instance->private_data)
		kfree(instance->private_data);
	return 0;
}

static struct file_operations fops = {
	.owner	 = THIS_MODULE,
	.open	 = driver_open,
	.release = driver_close,
	.read	 = driver_read,
};

static int __init __init_module(void) {
	if(register_chrdev(DRIVER_MAJOR, "99 Bottles of Beer", &fops) == 0)
		return 0;
	return -EIO;
}

static void __exit __cleanup_module(void) {
	unregister_chrdev(DRIVER_MAJOR, "99 Bottles of Beer");
}

module_init(__init_module);
module_exit(__cleanup_module);
