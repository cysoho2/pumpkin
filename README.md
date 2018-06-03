#What is this?

Pumpkin is a non-profit personal side project aiming at building a powerful education/research-oriented CPU prototype with the following targets:
* super-scalar & out-of-order
* super-pipelined
* parameterized
* synthesizable
* compatible with ARMv8-A ISA

This package includes RTL codes, simulation scripts, an ARMv8 ELF loader, along with a series of cpp source files which can be compiled by a standard ARM compiler. 
Tested can be performed with a RTL simulator or on a real FPGA board. 

#Required Tools

* vivado simulator
* gtkwave

#Cautions 
    
1. simulation performance drastically degrades with -dump or -sim_time option.

#Pumpkin.pl usage

Pumpkin.pl is the major script for nearly all of the tasks. The following options is available: 

1. about the test type that will be performed (optional)
    
- -full indicates full chip simulation, using the testcase from $PUMPKIN_ROOT/verif/full_test
- -unit indicates component simulation, using the testcase from $PUMPKIN_ROOT/verif/unit_test
    
default is -unit.

2. about the test arch (optional)
- -x86 or -64 indicates that the testcase will be compiled and run on a real x86/x64 machine.
- -arm64 or -armv8 indicates that the testcase will be compiled and run on the pumpkin CPU.

default is -armv8

3. about the test mode (optional)

- -behavioral indicates that behavioral simulation will be performed.
- -synth indicates that synthesis will be performed.
- -impl indicates that implementation will be performed.

synthesis will be automatically performed before implementation.

4. about the test type (optional)

- -sim_func indicates that functional simulation will be performed.
- -sim_time indicates that timing simulation will be performed.
- -dump indicates that signals will be dumped out for debugging, simulation will run without signals dumpling if this option is not specified.

default is -sim_func and without dump.

5. about the testcase name (required)
    
001_basic_loop indicates a full chip simulation run with the testcase from $PUMPKIN_ROOT/verif/full_test/001_basic_loop
    
you must not put a hyphen before the testcase name, and that's the only kind of options that can go without hyphen.
the unit test is specified in $PUMPKIN_ROOT/verif/unit_test/unit.cfg, the script will parse that .cfg file to get necessary info.
every subfolder under $PUMPKIN_ROOT/verif/full_test is qualified as a full testcase, no parsing is needed.
if the folder can't be found under the specified path, the script will report an error of unknown parameters.
    
if you wish to run multiple test at once, you can type as the following example: -unit name_x name_y name_z -full name_a name_b name_c
x,y,z will be identified as unit tests; a,b,c will be identified as full tests.

6. example:

-synth -full indicates a pure full-chip synthesis procedure without simulation. One may use this to check whether the codes are synthesizable.
-synth -sim_func -full 001_basic_loop indicates a post-synthesis full-chip functional simulation of testcase 001_basic_loop.
-impl -sim_time -dump -unit fifo_queue indicates a post-implementation timing simulation of unit testcase fifo_queue with signals dumping.

-./pumpkin.pl -impl -sim_time -dump -unit fifo

7. (Probably) Required Packages

- sudo apt-get install gtkwave
- sudo apt-get install iverilog (MacOSX)
