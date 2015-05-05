#
#       !!!! Do NOT edit this makefile with an editor which replace tabs by spaces !!!!
#
##############################################################################################
#
# On command line:
#
# make all = Create project
#
# make clean = Clean project files.
#
# To rebuild project do "make clean" and "make all".
#

##############################################################################################
# Start of default section
#
TOOLCHAIN = arm-none-eabi

CXX  = $(TOOLCHAIN)-g++
LD   = $(TOOLCHAIN)-g++
CC   = $(TOOLCHAIN)-gcc
CP   = $(TOOLCHAIN)-objcopy
AS   = $(TOOLCHAIN)-as
AR   = $(TOOLCHAIN)-ar
AP   = $(TOOLCHAIN)-gcc -x assembler-with-cpp
HEX  = $(CP) -O ihex
BIN  = $(CP) -O binary

MCU  = cortex-m3 -mcpu=cortex-m3 -mthumb -mthumb-interwork

# List all default C defines here, like -D_DEBUG=1
#does the usb lib want  -DARCH=ARCH_LPC ??
DDEFS = -D__LPC177X_8X__=1 -DCORE_M3=1 -D__BUILD_WITH_EXAMPLE__=1 -DNO_LIMITED_CONTROLLER_CONNECT=1

# List all default ASM defines here, like -D_DEBUG=1
DADEFS = 

# List all default directories to look for include files here
DINCDIR = 

# List the default directory to look for the libraries here
DLIBDIR =

# List all default libraries here
DLIBS = 

#
# End of default section
##############################################################################################

##############################################################################################
# Start of user section
#


# List all user C define here, like -D_DEBUG=1
UDEFS = 

# Define ASM defines here
UADEFS = 

# Make does not offer a recursive wildcard function, so here's one:
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

SPECIAL_LIBS =../lpc177x_8x/
GENERAL_LIBS =../Libraries/

# List C source files here
SRC  =  $(call rwildcard,./src/,*.c) \

# List CPP source files here
CPPSRC = \
        $(call rwildcard,./src/,*.cpp)


# List ASM source files here
ASRC = \
        $(call rwildcard,src/,*.s)

# List all user directories here
UINCDIR = ./inc \
          ./hardware\
          ../lpc1788x_8x/Drivers/include \
          ../lpc177x_8x/Core/Device/NXP/LPC177x_8x/Include \
          $(dir $(call rwildcard,./,*))

#This modification stops the errors that look like cc1plus.exe: warning: ../libraries/general/GP-Lib/src/GP.c: not a directory [enabled by default]
UINCDIR += $(filter %/, $(call rwildcard,$(GENERAL_LIBS),*/))

# List the user directory to look for the libraries here
ULIBDIR = ./lib

INCDIRS_T           += $(dir $(wildcard $(addsuffix Core/Device/NXP/*/Include/, $(SPECIAL_LIBS))))
INCDIRS_T           += $(dir $(addsuffix Core/CMSIS/Include/, $(SPECIAL_LIBS)))
INCDIRS_T           += $(dir $(addsuffix Drivers/include/, $(SPECIAL_LIBS)))
INCDIRS             = $(sort $(INCDIRS_T))
        
IFLAGS              = $(patsubst %,-I%,$(INCDIRS)) -I.



# Define optimisation level here
OPT ?= -O3

#
# End of user defines
##############################################################################################

# Fix, so clean does not kill our .s source files:
ASRCTEMP = $(ASRC:.s=.o)

AOBJS    = $(ASRCTEMP:.S=.o)
COBJS    = $(SRC:.c=.o)
CPPOBJS  = $(CPPSRC:.cpp=.o)

OBJS     = $(AOBJS) $(COBJS) $(CPPOBJS)
SOURCES  = $(ASRCTEMP) $(SRC) $(CPPSRC)
LISTINGS = $(addsuffix .lst, $(SOURCES))
BAK      = $(addsuffix .bak, $(SOURCES))


INCDIR  = $(patsubst %,-I%,$(sort $(DINCDIR) $(UINCDIR)))
LIBDIR  = $(patsubst %,-L%,$(sort $(DLIBDIR) $(ULIBDIR)))

DEFS    = $(DDEFS) $(UDEFS) -DRUN_FROM_FLASH=1

ADEFS   = $(DADEFS) $(UADEFS)
LIBS    = $(DLIBS) $(ULIBS)
MCFLAGS = -mcpu=$(MCU) 

#add the heap size calculated in linker file to here
CFLAGS              = $(SFLAGS) $(CC_MODE_SW) $(OPTIMIZATION) $(IFLAGS)
CFLAGS              += -DHEAP_START=\(\(uint32_t\)MALLOC_BASE\) -DHEAP_SIZE=\(\(uint32_t\)MALLOC_LENGTH\) -DTESTING
AFLAGS              = $(SFLAGS) $(AS_MODE_SW) $(IFLAGS)

ASFLAGS = $(MCFLAGS) -g -gdwarf-2 -Wa,-amhls=$(<:.s=.s.lst) $(ADEFS) 
CPFLAGS = $(MCFLAGS) $(OPT) -gdwarf-2 -mthumb -fomit-frame-pointer -Wall -Wstrict-prototypes -fverbose-asm -Wa,-ahlms=$(<:.c=.c.lst) $(DEFS) -std=c99
CXXFLAGS = $(MCFLAGS) $(OPT) -gdwarf-2 -mthumb -fomit-frame-pointer -Wall -fverbose-asm -Wa,-ahlms=$(<:.cpp=.cpp.lst) $(DEFS)
LDFLAGS = $(MCFLAGS) -mthumb -nostartfiles -T$(LDSCRIPT) -Wl,-Map=$(FULL_PRJ).map,--cref,--no-warn-mismatch $(LIBDIR)

ASFLAGS += $(AFLAGS)
CPFLAGS += $(CFLAGS)
CXXFLAGS += $(CFLAGS)

# Generate dependency information
CPFLAGS += -MD -MP -MF .dep/$(@F).d
CXXFLAGS += -MD -MP -MF .dep/$(@F).d


ARFLAGS = ruv
#
# makefile rules
#

all: $(OBJS) $(FULL_PRJ).a

$(OBJS) : Makefile

%.o : %.c
	$(CC) -c $(CPFLAGS) -I. $(INCDIR) $< -o $@

%.o : %.cpp
	$(CXX) -c $(CXXFLAGS) -I. $(INCDIR) $< -o $@

%.o : %.s
	$(AP) -c $(ASFLAGS) $< -o $@
# Replace the above line with the following, once this Makefile works:
#	$(AS) -c $(ASFLAGS) $< -o $@

%a: $(OBJS)
	$(AR) $(ARFLAGS) lpcusblib.a $(OBJS)


%hex: %elf
	$(HEX) $< $@

%bin: %elf
	$(BIN) $< $@

clean:
	-rm -f $(OBJS)
	-rm -f $(LISTINGS)
	-rm -f $(BAK)
	-rm -f $(FULL_PRJ).a
	-rm -fR .dep
	echo Cleaned.



#
# Include the dependency files, should be the last of the makefile
#
.SECONDARY:
-include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)

    
# *** EOF ***
