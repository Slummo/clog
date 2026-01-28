# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Library metadata
LIB_NAME	:= clog
VERSION		:= 1.0.0
MAJOR_VER	:= $(firstword $(subst ., ,$(VERSION)))

# Directories
DIR_SRC		:= src
DIR_INC		:= include
DIR_TEST	:= test
DIR_BLD		:= build
DIR_LIB		:= lib
DIR_BIN		:= bin

# Install paths
PREFIX		:= /usr/local
DEST_INC	:= $(PREFIX)/include/$(LIB_NAME)
DEST_LIB	:= $(PREFIX)/lib

# Profile: release (default) or debug
PROFILE ?= release

# Tools
CC		:= gcc
MKDIR	:= mkdir -p
RM		:= rm -rf
INSTALL	:= install

# -----------------------------------------------------------------------------
# Flags & Settings
# -----------------------------------------------------------------------------

# Compiler flags
CFLAGS		:= -std=c99 -Wall -Wextra -Werror -Wsign-conversion -fPIC -MMD -MP
INCLUDES	:= -I$(DIR_INC)

# Linker flags
LDFLAGS		:= -shared -Wl,-soname,lib$(LIB_NAME).so.$(MAJOR_VER)

# Profile Specifics
ifeq ($(PROFILE),debug)
	CFLAGS	+= -g -O0 -DDEBUG
	LDFLAGS	+=
else
	CFLAGS	+= -O2 -march=native -flto -DNDEBUG
	LDFLAGS	+= -O2 -march=native -flto
endif

# -----------------------------------------------------------------------------
# File discovery
# -----------------------------------------------------------------------------

# Library Sources
LIB_SRCS := $(shell find $(DIR_SRC) -name "*.c")
LIB_OBJS := $(patsubst %.c, $(DIR_BLD)/%.o, $(LIB_SRCS))

# Test Sources
TEST_SRCS := $(shell find $(DIR_TEST) -name "*.c")
TEST_OBJS := $(patsubst %.c, $(DIR_BLD)/%.o, $(TEST_SRCS))

# Targets
TARGET_LIB_REAL	:= $(DIR_LIB)/lib$(LIB_NAME).so.$(VERSION)
TARGET_LIB_SO	:= $(DIR_LIB)/lib$(LIB_NAME).so.$(MAJOR_VER)
TARGET_LIB_DEV	:= $(DIR_LIB)/lib$(LIB_NAME).so

TARGET_TEST		:= $(DIR_BIN)/test

# Dependencies
DEPS := $(LIB_OBJS:.o=.d) $(TEST_OBJS:.o=.d)

# -----------------------------------------------------------------------------
# Rules
# -----------------------------------------------------------------------------

.PHONY: all test install uninstall clean clean_full help

all: $(TARGET_LIB_REAL)

# --- Build Library ---

$(TARGET_LIB_REAL): $(LIB_OBJS)
	@$(MKDIR) $(dir $@)
	@echo " [LD] Shared Lib: $@"
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	@# Create Symlinks for versioning
	@ln -sf $(notdir $@) $(TARGET_LIB_SO)
	@ln -sf $(notdir $@) $(TARGET_LIB_DEV)

# --- Build Tests ---

$(TARGET_TEST): $(TEST_OBJS) $(TARGET_LIB_REAL)
	@$(MKDIR) $(dir $@)
	@echo " [LD] Test Runner: $@"
	@$(CC) $(CFLAGS) $(TEST_OBJS) -L$(DIR_LIB) -l$(LIB_NAME) -Wl,-rpath=$(PWD)/$(DIR_LIB) -o $@

# --- Compilation ---

$(DIR_BLD)/%.o: %.c
	@$(MKDIR) $(dir $@)
	@echo " [CC] $<"
	@$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# --- Helpers ---

test: $(TARGET_TEST)
	@./$^

# --- Install / Uninstall ---

install: all
	@echo "Installing to $(PREFIX)..."
	
	@# Install headers
	@$(INSTALL) -d $(DEST_INC)
	@$(INSTALL) -m 644 $(DIR_INC)/*.h $(DEST_INC)
	
	@# Install library
	@$(INSTALL) -d $(DEST_LIB)
	@$(INSTALL) -m 755 $(TARGET_LIB_REAL) $(DEST_LIB)
	
	@# Create system symlinks (lib.so.1.0.0 -> lib.so.1 -> lib.so)
	@ln -sf lib$(LIB_NAME).so.$(VERSION) $(DEST_LIB)/lib$(LIB_NAME).so.$(MAJOR_VER)
	@ln -sf lib$(LIB_NAME).so.$(VERSION) $(DEST_LIB)/lib$(LIB_NAME).so
	
	@# Update Cache
	@echo "Updating ldconfig cache..."
	@ldconfig
	@echo "Installation successful."

uninstall:
	@echo "Uninstalling $(LIB_NAME)..."
	@$(RM) $(DEST_INC)
	@$(RM) $(DEST_LIB)/lib$(LIB_NAME).so*
	@ldconfig
	@echo "Uninstallation successful."

clean:
	@echo "Cleaning build objects..."
	@$(RM) $(DIR_BLD)

clean_full: clean
	@echo "Cleaning binaries and libraries..."
	@$(RM) $(DIR_LIB) $(DIR_BIN)

help:
	@echo "Targets:"
	@echo "  make              Build the shared library"
	@echo "  make test         Build and run tests (linked locally)"
	@echo "  make install      Install headers and libs (requires sudo)"
	@echo "  make uninstall    Remove installed files (requires sudo)"
	@echo "  make clean_full   Remove all artifacts"

-include $(DEPS)