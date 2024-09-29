// by @guyzmo under WTFPL license
// http://i.got.nothing.to/hack/on/run-the-sl030-rfid-reader-on-linux/

#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <time.h>

const char STATUS[][32] = {
    /*0x00*/ "Operation succeed",
    /*0x01*/ "No tag",
    /*0x02*/ "Login succeed",
    /*0x03*/ "Login fail",
    /*0x04*/ "Read fail",
    /*0x05*/ "Write fail",
    /*0x06*/ "Unable to read after write",
    /*0x08*/ "Address overflow",
    /*0x09*/ "Download Key fail",
    /*0x0A*/ "Collision occur",
    /*0x0C*/ "Load key fail",
    /*0x0D*/ "Not authenticate",
    /*0x0E*/ "Not a value block"
};

int main(void) {
    int file;
    char filename[40];
    const char *buffer;
    int addr = 0x50; // Addr of SL030

    sprintf(filename,"/dev/i2c-1");
    if ((file = open(filename,O_RDWR)) < 0) {
        printf("Failed to open the bus.");
        exit(1);
    }

    if (ioctl(file,I2C_SLAVE,addr) < 0) {
        printf("Failed to acquire bus access and/or talk to slave.\n");
        exit(1);
    }
    char buf[128] = {0};
    for (int i=0;i<128;++i) buf[i] = 0;

    // ------------ WRITE COMMAND ------------------
    unsigned char reg = 0x01; // Device register to access
    buf[0] = 1;
    buf[1] = reg;

    if (write(file,buf,2) != 2) {
        // ERROR HANDLING: i2c transaction failed
        printf("Failed to write to the i2c bus.\n");
        buffer = strerror(errno);
        printf("%s\n\n", buffer);
    } else {
        printf("write success\n\n");
    }

    for (int i=0;i<128;++i) buf[i] = 0;

    struct timespec tim, tim2;
    tim.tv_sec = 0;
    tim.tv_nsec = 200000000;  // 0.2 seconds
    nanosleep(&tim, &tim2);

    // ------------ READ CARD STATUS ------------------
    unsigned short len = 0;
    unsigned short cmd = 0;
    unsigned short sta = 0;

    // Using I2C Read
    int bytesRead = read(file, buf, 128);
    if (bytesRead <= 0) {
        // ERROR HANDLING: i2c transaction failed
        printf("Failed to read from the i2c bus.\n");
        buffer = strerror(errno);
        printf("%s\n\n", buffer);
        return 1;
    }

    if (bytesRead < 3) {
        printf("Incomplete data read from device.\n");
        return 1;
    }

    len = (unsigned short)buf[0];
    cmd = (unsigned short)buf[1];
    sta = (unsigned short)buf[2];

    // Check if the status code is within bounds
    if (sta >= sizeof(STATUS) / sizeof(STATUS[0])) {
        printf("Invalid status code: %d\n", sta);
        return 1;
    }

    printf("Length:  %d\n", len);
    printf("Command: 0x%02X\n", cmd);
    printf("Status:  %s\n", STATUS[sta]);
    printf("Data: ");

    for (int i=3; i<len; ++i) {
        printf("%02X;", buf[i]);
    }

    printf("\n\n");

    return 0;
}

