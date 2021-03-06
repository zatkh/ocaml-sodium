ENCLAVE_TEST ?=1
MAKEFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
CURRENT_DIR := $(dir $(MAKEFILE_PATH))

OCAML_LIB_DIR=$(shell ocamlc -where)
include $(OCAML_LIB_DIR)/Makefile.config

CTYPES_LIB_DIR=$(shell ocamlfind query ctypes)

ENV=CTYPES_LIB_DIR=$(CTYPES_LIB_DIR) OCAML_LIB_DIR=$(OCAML_LIB_DIR)
OCAMLBUILD=$(ENV) ocamlbuild -use-ocamlfind -classic-display -no-hygiene

all:
	$(OCAMLBUILD) lib/sodium.cma lib/sodium.cmxa lib/sodium.cmxs

clean:
	$(OCAMLBUILD) -clean

test: _build/lib_test/nacl_runner
	CAML_LD_LIBRARY_PATH=$(CURRENT_DIR)_build/lib:$(CAML_LD_LIBRARY_PATH) \
		$(OCAMLBUILD) lib_test/test_sodium.byte --
	$(OCAMLBUILD) lib_test/test_sodium.native --

test_enclave: enclave_nacl_runner
	CAML_LD_LIBRARY_PATH=$(CURRENT_DIR)_build/lib:$(CAML_LD_LIBRARY_PATH) \
		$(OCAMLBUILD) lib_test/test_sodium_enclave.byte --
	$(OCAMLBUILD) lib_test/test_sodium_enclave.native --

install:
	ocamlfind install sodium lib/META \
		$(addprefix _build/lib/,sodium.mli sodium.cmi sodium.cmti \
					sodium.cma sodium.cmx sodium.cmxa sodium.cmxs \
		                        sodium$(EXT_LIB) \
					dllsodium_stubs$(EXT_DLL) \
					libsodium_stubs$(EXT_LIB))

uninstall:
	ocamlfind remove sodium

reinstall: uninstall install




.PHONY: all clean test test_enclave install uninstall reinstall 

_build/%: %.c
	mkdir -p $$(dirname $@)
	$(CC) -Wall -g $(CFLAGS) -lsodium -o $@ $^


enclave_nacl_runner:
	$(MAKE) -C ../lib-enclave clean
	$(MAKE) -C ../lib-enclave ENCLAVE_TEST=1 SGX_MODE=SIM
	rm -rf enclave.s*
	cp -r ../lib-enclave/enclave* .
