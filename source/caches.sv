/*
 Eric Villasenor
 evillase@gmail.com

 this block holds the i and d cache
 */


module caches (
	       input logic CLK, nRST,
	       datapath_cache_if dcif,
	       cache_control_if ccif
	       );

   parameter CPUID = 0;
   // icache
   icache #(.CPUID(CPUID)) ICACHE(CLK, nRST, dcif, ccif);
   // dcache
   dcache #(.CPUID(CPUID)) DCACHE(CLK, nRST, dcif, ccif);

   /*
   // dcache invalidate before halt handled by dcache when exists
   assign dcif.flushed = dcif.halt;

   //singlecycle
   assign dcif.ihit = (dcif.imemREN) ? ~ccif.iwait[CPUID] : 0;
   assign dcif.dhit = (dcif.dmemREN|dcif.dmemWEN) ? ~ccif.dwait[CPUID] : 0;
   assign dcif.imemload = ccif.iload[CPUID];
   assign dcif.dmemload = ccif.dload[CPUID];


   assign ccif.iREN[CPUID] = dcif.imemREN;
   assign ccif.dREN[CPUID] = dcif.dmemREN;
   assign ccif.dWEN[CPUID] = dcif.dmemWEN;
   assign ccif.dstore[CPUID] = dcif.dmemstore;
   assign ccif.iaddr[CPUID] = dcif.imemaddr;
   assign ccif.daddr[CPUID] = dcif.dmemaddr;*/

endmodule
