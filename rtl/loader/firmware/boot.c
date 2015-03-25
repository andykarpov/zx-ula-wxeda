/*	Firmware for loading files from SD card.
	Part of the ZPUTest project by Alastair M. Robinson.
	SPI and FAT code borrowed from the Minimig project.
*/


#include "stdarg.h"

#include "uart.h"
#include "spi.h"
#include "minfat.h"
#include "small_printf.h"
#include "host.h"
#include "ps2.h"
#include "keyboard.h"
#include "hexdump.h"
#include "osd.h"
#include "menu.h"

fileTYPE file;
static struct menu_entry topmenu[];

void OSD_Puts(char *str)
{
	int c;
	while((c=*str++))
		OSD_Putchar(c);
}


void WaitEnter()
{
	while(1)
	{
		HandlePS2RawCodes();
		if(TestKey(KEY_ENTER)&2)
			return;
	}
}

static int Boot() {

	int result=0;
	int opened;

	OSD_Puts("Initializing SD card\n");

	if(spi_init()) {

		if(!FindDrive())
			return(0);

		if(sd_ishc())
			OSD_Puts("SDHC card detected\n");
		
		if(IsFat32())
			OSD_Puts("Fat32 detected\n");		

		OSD_Puts("Trying 82.ROM\n");
		opened = FileOpen(&file, "82      ROM");
		if(opened) {

			OSD_Puts("Loading 82.ROM\n");
			int filesize = file.size;
			unsigned int c = 0;
			int bits;

			bits = 0;
			c = filesize;
			while(c) {
				++bits;
				c >>= 1;
			}
			bits -= 9;

			while(filesize > 0) {
				OSD_ProgressBar(c,bits);
				if(FileRead(&file,sector_buffer)) {
					int i;
					int *p = (int *)&sector_buffer;
					for(i=0; i<(filesize<512 ? filesize : 512) ;i+=4) {
						int t = *p++;
						int t1 = t&255;
						int t2 = (t>>8)&255;
						int t3 = (t>>16)&255;
						int t4 = (t>>24)&255;
						HW_HOST(HW_HOST_BOOTDATA) = t4;
						HW_HOST(HW_HOST_BOOTDATA) = t3;
						HW_HOST(HW_HOST_BOOTDATA) = t2;
						HW_HOST(HW_HOST_BOOTDATA) = t1;
					}
				}
				else {
					OSD_Puts("Read failed\n");
					return(0);
				}
				FileNextSector(&file);
				filesize -= 512;
				++c;
			}
			return(1);
		}
	}
	return(0);
}

int main(int argc,char **argv)
{
	int i;
	HW_HOST(HW_HOST_CTRL)=HW_HOST_CTRLF_RESET;	// Put OCMS into Reset
	HW_HOST(HW_HOST_CTRL)=HW_HOST_CTRLF_SDCARD;	// Release reset but steal SD card
	HW_HOST(HW_HOST_MOUSEBUTTONS)=3;

	PS2Init();
	EnableInterrupts();
	PS2Wait();
	PS2Wait();
	OSD_Clear();
	OSD_Show(1);	// Figure out sync polarity
	PS2Wait();
	PS2Wait();
	for(i=0;i<128;++i) {
		PS2Wait();
		OSD_Show(1);	// OSD should now show correctly.
	}
	PS2Wait();
	PS2Wait();

	while (1) {
		if(Boot())
		{
			OSD_Puts("Loading BIOS done\n");
		}
		else
		{
			OSD_Puts("Loading BIOS failed\n");
		}
	}

	return(0);
}

