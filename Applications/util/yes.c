/*	yes 1.4 - print 'y' or argv[1] continuously.	Author: Kees J. Bot
 *								15 Apr 1989
 */
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    char *yes;
    int n;
    static char y[] = "y";

    yes = argc == 1 ? y : argv[1];

    n = strlen(yes);
		
    yes[n++] = '\n';

    while (write(1, yes, n) != -1)
	/* Do nothing */;

    exit(1);
}
