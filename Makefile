# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Library metadata
LIB_NAME	:= clog
VERSION		:= 1.0.2
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
LIB_SRCS := $(shell find $(DIR_SRC) -name "*.c" 2> /dev/null)
LIB_OBJS := $(patsubst %.c, $(DIR_BLD)/%.o, $(LIB_SRCS))

ifeq ($(strip $(LIB_SRCS)),)
	MODE := header
else
	MODE := compiled
endif

# Test Sources
TEST_SRCS := $(shell find $(DIR_TEST) -name "*.c" 2> /dev/null)
TEST_OBJS := $(patsubst %.c, $(DIR_BLD)/%.o, $(TEST_SRCS))

ifeq ($(strip $(TEST_SRCS)),)
	HAS_TESTS := no
else
	HAS_TESTS := yes
endif

# Targets
TARGET_LIB_REAL	:= $(DIR_LIB)/lib$(LIB_NAME).so.$(VERSION)
TARGET_LIB_SO	:= $(DIR_LIB)/lib$(LIB_NAME).so.$(MAJOR_VER)
TARGET_LIB_DEV	:= $(DIR_LIB)/lib$(LIB_NAME).so

TARGET_TEST		:= $(DIR_BIN)/test

# Dependencies
DEPS := $(LIB_OBJS:.o=.d) $(TEST_OBJS:.o=.d)

ifeq ($(MODE),compiled)
    TEST_DEPS := $(TARGET_LIB_REAL)
    TEST_LIBS := -L$(DIR_LIB) -l$(LIB_NAME) -Wl,-rpath=$(PWD)/$(DIR_LIB)
else
    TEST_DEPS :=
    TEST_LIBS :=
endif

# -----------------------------------------------------------------------------
# Rules
# -----------------------------------------------------------------------------

.PHONY: all test install uninstall clean clean_full help

all: build_$(MODE)

# --- Build Library ---

build_compiled: $(TARGET_LIB_REAL)

$(TARGET_LIB_REAL): $(LIB_OBJS)
	@$(MKDIR) $(dir $@)
	@echo "[LD] $@"
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	@# Create Symlinks for versioning
	@ln -sf $(notdir $@) $(TARGET_LIB_SO)
	@ln -sf $(notdir $@) $(TARGET_LIB_DEV)

build_header:
	@echo "[INFO] Header only. Skipping build..."

# --- Build Tests ---

ifeq ($(HAS_TESTS),yes)
$(TARGET_TEST): $(TEST_OBJS) $(TEST_DEPS)
	@$(MKDIR) $(dir $@)
	@echo "[LD] $@"
	@$(CC) $(CFLAGS) $(TEST_OBJS) $(TEST_LIBS) -o $@
endif

# --- Compilation ---

$(DIR_BLD)/%.o: %.c
	@$(MKDIR) $(dir $@)
	@echo "[CC] $<"
	@$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# --- Helpers ---

test: test_$(HAS_TESTS)

test_yes: $(TARGET_TEST)
	@./$^

test_no:
	@echo "[INFO] No tests found in $(PWD). Skipping..."

# --- Install / Uninstall ---

install: install_headers install_lib_$(MODE)
	@echo "Installation successful"

install_headers:
	@echo "Installing headers to $(DEST_INC)..."
	@$(INSTALL) -d $(DEST_INC)
	@$(INSTALL) -m 644 $(DIR_INC)/$(LIB_NAME)/*.h $(DEST_INC)

install_lib_compiled:
	@echo "Installing library to $(DEST_LIB)..."
	@$(INSTALL) -d $(DEST_LIB)
	@$(INSTALL) -m 755 $(TARGET_LIB_REAL) $(DEST_LIB)
	@ln -sf lib$(LIB_NAME).so.$(VERSION) $(DEST_LIB)/lib$(LIB_NAME).so.$(MAJOR_VER)
	@ln -sf lib$(LIB_NAME).so.$(VERSION) $(DEST_LIB)/lib$(LIB_NAME).so
	@echo "Updating ldconfig cache..."
	@ldconfig

install_lib_header:
	@echo "[INFO] Header only. Skipping library installation..."

uninstall:
	@echo "Uninstalling $(LIB_NAME)..."
	@$(RM) $(DEST_INC)
	@$(RM) $(DEST_LIB)/lib$(LIB_NAME).so*
	@ldconfig
	@echo "Uninstallation successful"

clean:
	@echo "Cleaning build objects..."
	@$(RM) $(DIR_BLD)

clean_full: clean
	@echo "Cleaning binaries and libraries..."
	@$(RM) $(DIR_LIB) $(DIR_BIN)

help:
	@echo "Targets:"
	@echo "  make              Build the shared library (if applicable)"
	@echo "  make test         Build and run tests (linked locally, if applicable)"
	@echo "  make install      Install headers and libs (requires sudo)"
	@echo "  make uninstall    Remove installed files (requires sudo)"
	@echo "  make clean_full   Remove all artifacts"

-include $(DEPS)