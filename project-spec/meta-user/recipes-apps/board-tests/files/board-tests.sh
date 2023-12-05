#!/bin/sh

usb_info()
{
    printf "USB Device Tree\n"
    lsusb -t
}

xfer_speed()
{
    if [ "$1" = "" ]; then
        DEV=/dev/sda
    else
        DEV=$1
    fi

    printf "Running transfer test on %s\n" $DEV
    hdparm -t $DEV
}

eeprom_num2path()
{
    if [ "$1" = "1" ]; then
        ret=/sys/bus/i2c/devices/0-0050/eeprom
    elif [ "$1" = "2" ]; then
        ret=/sys/bus/i2c/devices/0-0051/eeprom
    else
        ret="-1"
    fi
}

write_eeprom()
{
    if [[ "$1" = "" || $2 = "" ]]; then
        return
    fi

    eeprom_num2path $1
    E=$ret

    if [ "$ret" = "-1" ]; then
        return
    fi

    printf "" > .ewr

    # Gather all args
       for i in "${@:2}"
       do printf "%s" "$i " >> .ewr
    done

    # Trim the extra space
    sed -i '$ s/.$//' .ewr

    # Write to the EEPROM
    cat .ewr > $E

    rm .ewr
}

read_eeprom()
{
    if [ "$1" = "" ]; then
        return
    fi

    eeprom_num2path $1
    E=$ret

    printf "EEPROM contents of %s:\n" $E
    hexdump -C $E
}

write_flash()
{
    if [ "$1" = "" ]; then
        return
    fi

    # Erase first block of flash
    flash_erase /dev/mtd0 0 1

    printf "" > .fwr

    # Gather all args
       for i in "${@:1}"
       do printf "%s" "$i " >> .fwr
    done

    # Trim the extra space
    sed -i '$ s/.$//' .fwr

    # Write to the flash
    flashcp .fwr /dev/mtd0

    rm .fwr
}

read_flash()
{
    printf "Flash Contents:\n"
    hexdump -C /dev/mtd0 -n 131072
}

led_flash()
{
    printf "Flashing LEDs...\n"

    LEDPATH=$(printf "/sys/class/leds/psled1-d6/brightness" $i)
    echo 1 > ${LEDPATH}
    usleep 250000
    echo 0 > ${LEDPATH}
    usleep 250000

    for i in {0..7}; do
        LEDPATH=$(printf "/sys/class/leds/led%d*/brightness" $i)
        LEDPATH=$(echo $LEDPATH)
        echo 1 > ${LEDPATH}
        usleep 250000
        echo 0 > ${LEDPATH}
        usleep 250000
    done
}

read_pb()
{
    printf "Pushbutton Values:\n"
    for i in {0..2}; do
        VAL=$(gpioget 6 ${i})
        printf "SW%d: %s\n" $i $VAL 
    done
}

read_dipsw()
{
    printf "DIP Switch Values:\n"
    for i in {0..7}; do
        VAL=$(gpioget 8 ${i})
        printf "SW5.%d: %s\n" $i $VAL 
    done
}

ethernet_test()
{
    ping -c 1 google.com

    if [ "$?" = "0" ]; then
        printf "Success reaching google.com\n"
    else
        printf "Failure reaching google.com\n"
    fi
}

uart1_console()
{
    printf "Console is Open at 115200 (10 second timeout):\n"

    microcom /dev/ttyPS1 -t 10000 -s 115200
}

macaddr_check()
{
    printf "Checking eth MAC matches EEPROM...\n"
    ETHMAC=$(ip address show eth0 | grep link/ether | awk  '{print $2}')
    EEMAC=$(dd if=/sys/bus/i2c/devices/0-0051/eeprom skip=250 bs=1 count=6 \
    | hexdump -e '6/1 "%02x:""\n"' | sed 's/.$//')

    printf "\nEthernet MAC: %s\n" $ETHMAC
    printf "EEPROM MAC: %s\n" $EEMAC

    if [ "$ETHMAC" = "$EEMAC" ]; then
        printf "\nSuccess, MAC addresses match!\n"
    else
        printf "\nFailure, MAC addresses do not match!\n"
    fi
}

display_help()
{
    printf "Test Script For Various Board Peripherals\n\n"
    printf "Usage:\n\n"
    printf "%s <arguments>\n\n" $1

    printf "Arguments (<> mandatory [] optional)\n\n"

    printf "eeprom-read <devnum>\n"
    printf "\tRead EEPROM data\n"
    printf "\t1=SIP EEPROM\n"
    printf "\t2=MAC ID EEPROM\n\n"

    printf "eeprom-write <devnum> <data string to write>\n"
    printf "\tWrite EEPROM with data\n"
    printf "\t1=SIP EEPROM\n"
    printf "\t2=MAC ID EEPROM\n\n"

    printf "ethernet-test\n"
    printf "\tAttempt to ping google.com\n\n"

    printf "flash-read\n"
    printf "\tRead NAND flash data\n\n"

    printf "flash-write <data string to write>\n"
    printf "\tWrite NAND flash with data (first block only)\n\n"

    printf "led-flash\n"
    printf "\tFlash each LED once\n\n"

    printf "macaddr-check\n"
    printf "\tCheck that eth mac matches EEPROM stored address\n\n"

    printf "read-dipsw\n"
    printf "\tRead and display values of DIP Switches\n\n"

    printf "read-pb\n"
    printf "\tRead and display values of SW1-3\n\n"

    printf "uart1-console\n"
    printf "\tOpen UART at 115200 on secondary port\n\n"

    printf "usb-info\n"
    printf "\tShow USB devices connected\n\n"

    printf "xfer-speed [device-path] \n"
    printf "\tTest transfer speed to a device, defaults to /dev/sda\n\n"
}


if [ "$1" = "eeprom-read" ]; then
    read_eeprom $2
elif [ "$1" = "eeprom-write" ]; then
    write_eeprom ${@:2}
elif [ "$1" = "ethernet-test" ]; then
    ethernet_test
elif [ "$1" = "flash-read" ]; then
    read_flash $2
elif [ "$1" = "flash-write" ]; then
    write_flash ${@:2}
elif [ "$1" = "led-flash" ]; then
    led_flash
elif [ "$1" = "macaddr-check" ]; then
    macaddr_check
elif [ "$1" = "read-dipsw" ]; then
    read_dipsw
elif [ "$1" = "read-pb" ]; then
    read_pb
elif [ "$1" = "uart1-console" ]; then
    uart1_console
elif [ "$1" = "usb-info" ]; then
    usb_info
elif [ "$1" = "xfer-speed" ]; then
    xfer_speed $2
else
    display_help $0
fi
