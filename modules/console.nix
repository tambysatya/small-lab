/* Allows the connection to the machine using virsh console */

{
 boot.kernelParams = ["console=tty1" "console=ttyS0,115200"];
}
