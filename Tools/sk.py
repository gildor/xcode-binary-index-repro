#!/usr/bin/env python3
"""Tiny sourcekitd client: sk.py <yaml-request-file>  -> prints the response description."""
import ctypes, sys
lib = ctypes.CDLL("/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/sourcekitdInProc.framework/sourcekitdInProc")
lib.sourcekitd_initialize()
lib.sourcekitd_request_create_from_yaml.restype = ctypes.c_void_p
lib.sourcekitd_request_create_from_yaml.argtypes = [ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p)]
lib.sourcekitd_send_request_sync.restype = ctypes.c_void_p
lib.sourcekitd_send_request_sync.argtypes = [ctypes.c_void_p]
lib.sourcekitd_response_description_copy.restype = ctypes.c_void_p
lib.sourcekitd_response_description_copy.argtypes = [ctypes.c_void_p]
err = ctypes.c_char_p()
req = lib.sourcekitd_request_create_from_yaml(open(sys.argv[1], "rb").read(), ctypes.byref(err))
if not req:
    sys.exit(f"bad yaml: {err.value}")
resp = lib.sourcekitd_send_request_sync(req)
print(ctypes.cast(lib.sourcekitd_response_description_copy(resp), ctypes.c_char_p).value.decode())
