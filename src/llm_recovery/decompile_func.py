import idaapi
import idautils
import idc
import ida_hexrays

idaapi.auto_wait()

if not ida_hexrays.init_hexrays_plugin():
    print("Failed to initialize Hex-Rays")
    idc.qexit(1)

func_name = idc.ARGV[1]
out_path = idc.ARGV[2]

func_ea = idc.get_name_ea_simple(func_name)
if func_ea == idc.BADADDR:
    for ea in idautils.Functions():
        if idc.get_func_name(ea) == func_name:
            func_ea = ea
            break

if func_ea == idc.BADADDR:
    print("Function not found")
    idc.qexit(2)

try:
    cfunc = ida_hexrays.decompile(func_ea)
    if cfunc:
        with open(out_path, "w") as f:
            f.write(str(cfunc))
        print("Successfully decompiled")
        idc.qexit(0)
    else:
        print("No pseudocode")
        idc.qexit(3)
except Exception as e:
    print("Error decompiling: " + str(e))
    idc.qexit(4)
