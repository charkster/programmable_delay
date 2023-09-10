# programmable_delay
FPGA design to allow for programmable delay on a single signal. Implemented and tested on CMOD_A7

My CMOD A7 has been modified to have a 100MHz oscillator on the board (stock one is 12MHz)... this should not be a big deal for a stock CMOD A7, as the internal PLL should be able to reach 400MHz from a 12MHz source. My internal clock used for counting is 400MHz (1 count = 2.5ns). Looks like there is 11ns (rise) and 13ns (fall) delay from input to output before any counting is done (see the "zero" rise and fall scope captures). I have a 16bit counter which allow for a 65,535 max count (163us maximum delay). The counter could be modified to be any width... I just chose 2 bytes. The FPGA's UART interface is used to change the programmable delay. There is no clock-crossing for the programmed delay and the high-speed 400MHz clock... just don't change the delay on the fly.


The sample Python code uses the pyftdi module... the generic serial module could be used, but I have better reliability with pyftdi.

I did try this RTL on my Tang Nano 9k, but the implementation had problems... I though it might be the programmable delay clock-crossing, but when I used a static value for the delay it still did not work. Anyways, Gowin's tool gave a bad implementation and I don't want to debug it further when the CMOD A7 works perfectly.

This helped me to resolve a PCB board timing problem, and that was my motivation for building this.
