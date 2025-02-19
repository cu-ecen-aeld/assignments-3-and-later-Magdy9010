/*

10) Write a shell script finder-app/writer.sh as described below:

- Accepts the following arguments: the first argument is a full path to a file (including filename) on the filesystem, 
  referred to below as writefile; the second argument is a text string which will be written within this file, referred to below as writestr

- Creates a new file with name and path writefile with content writestr, 
  overwriting any existing file and creating the path if it doesn’t exist. 
  Exits with value 1 and error print statement if the file could not be created.

*/

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <syslog.h>
#include <errno.h>

int main(int argc, char *argv[])
{
	setlogmask(LOG_UPTO(LOG_DEBUG));  // Allow all log levels
	openlog("Writer", LOG_PID|LOG_CONS , LOG_USER);
	syslog(LOG_INFO, "Syslog initialized successfully");

	for(int i = 0 ; i < argc ; i++)
	{
		printf("String %d: %s\n",i,argv[i]);
	}

	if(argc < 3)
	{
		syslog(LOG_ERR, "Missing Arguments");
		closelog();
		return 1;
	}

	int fd = open(argv[1],O_WRONLY| O_CREAT| O_TRUNC, 0644);

	if(fd == -1)
	{
		syslog(LOG_ERR, "Failed to open file: %s", strerror(errno));
		perror("open failed");
		closelog();
		return 1;
	}

	ssize_t writtenBytes = 0;
	syslog(LOG_DEBUG, "Writing %s to %s", argv[2],argv[1]);
	writtenBytes =  write(fd, argv[2], strlen(argv[2]));
	printf("Written bytes = %ld\n", writtenBytes);

	if(writtenBytes == -1)
	{
		syslog(LOG_ERR, "Failed to read the writestr to the writefile");
	}
	else
	{
		syslog(LOG_INFO, "Successfully wrote %ld bytes\n", writtenBytes);
	}


	closelog();
	close(fd);


	return 0;
}
