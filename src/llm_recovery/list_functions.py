import idaapi
import idautils
import idc
import json

idaapi.auto_wait()
funcs = []
for func_ea in idautils.Functions():
    func_name = idc.get_func_name(func_ea)
    func = idaapi.get_func(func_ea)
    is_lib = bool(func.flags & idaapi.FUNC_LIB) if func else False
    funcs.append({
        "name": func_name,
        "ea": func_ea,
        "is_lib": is_lib
    })

with open(idc.ARGV[1], "w") as f:
    json.dump(funcs, f)

idc.qexit(0)
