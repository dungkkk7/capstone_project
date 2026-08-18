// Deterministic program-level Ghidra export for the B0 baseline.
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Data;
import ghidra.program.model.listing.DataIterator;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.Symbol;

import java.io.File;
import java.io.PrintWriter;

public class ExportProgramDecomp extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length != 1) {
            throw new Exception("expected exactly one output path");
        }

        PrintWriter out = new PrintWriter(new File(args[0]), "UTF-8");
        out.println("/* Deterministic Ghidra program-level decompiler export. */");
        out.println("/* Image base: " + currentProgram.getImageBase() + " */");
        out.println();

        out.println("/* Defined global/data objects (address, label, value). */");
        DataIterator dataIterator = currentProgram.getListing().getDefinedData(true);
        while (dataIterator.hasNext() && !monitor.isCancelled()) {
            Data data = dataIterator.next();
            MemoryBlock block = currentProgram.getMemory().getBlock(data.getAddress());
            if (block == null) {
                continue;
            }
            String blockName = block.getName();
            if (!(blockName.equals(".rodata") || blockName.equals(".data") ||
                  blockName.equals(".bss") || blockName.equals(".got") ||
                  blockName.equals(".got.plt"))) {
                continue;
            }
            Symbol symbol = data.getPrimarySymbol();
            String label = symbol == null ? "<unnamed>" : symbol.getName();
            out.println("/* GLOBAL " + data.getAddress() + " " + label + " = " +
                        data.getDefaultValueRepresentation() + " */");
        }
        out.println();

        DecompInterface decompiler = new DecompInterface();
        decompiler.openProgram(currentProgram);
        FunctionIterator functions =
            currentProgram.getFunctionManager().getFunctions(true);
        while (functions.hasNext() && !monitor.isCancelled()) {
            Function function = functions.next();
            if (function.isExternal()) {
                continue;
            }
            out.println("// Function: " + function.getName() + " @ " +
                        function.getEntryPoint());
            MemoryBlock functionBlock =
                currentProgram.getMemory().getBlock(function.getEntryPoint());
            if (function.isThunk() ||
                (functionBlock != null &&
                 functionBlock.getName().toUpperCase().contains("EXTERNAL"))) {
                out.println(function.getPrototypeString(false, false) + ";");
                out.println();
                continue;
            }
            DecompileResults result =
                decompiler.decompileFunction(function, 120, monitor);
            if (!result.decompileCompleted() ||
                result.getDecompiledFunction() == null) {
                out.println("/* GHIDRA_DECOMPILE_FAILED: " +
                            result.getErrorMessage() + " */");
            } else {
                out.println(result.getDecompiledFunction().getC());
            }
            out.println();
        }
        decompiler.dispose();
        out.flush();
        out.close();
    }
}
