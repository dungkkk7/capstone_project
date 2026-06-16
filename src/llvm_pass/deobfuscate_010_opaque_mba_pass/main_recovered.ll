source_filename = "test"
target datalayout = "e-m:e-p:64:64-i64:64-f80:128-n8:16:32:64-S128"

@global_var_1618 = constant [46 x i8] c"/usr/include/llvm-21/llvm/IR/DiagnosticInfo.h\00"
@global_var_1646 = constant [28 x i8] c"unknown SourceMgr::DiagKind\00"
@global_var_1662 = constant [28 x i8] c"deobfuscate-opaque-mba-pass\00"
@global_var_167e = constant [25 x i8] c"DeobfuscateOpaqueMBAPass\00"
@global_var_1697 = constant [6 x i8] c"0.1.0\00"
@global_var_4968 = global i64 0
@global_var_13c8 = constant [75 x i8] c"llvm::SmallPtrSetImplBase::SmallPtrSetImplBase(const void**, unsigned int)\00"
@global_var_1418 = constant [44 x i8] c"/usr/include/llvm-21/llvm/ADT/SmallPtrSet.h\00"
@global_var_1448 = constant [74 x i8] c"llvm::has_single_bit(SmallSize) && \22Initial size must be a power of two!\22\00"
@global_var_3f = local_unnamed_addr constant [3 x i8] c"%(\00"
@global_var_1498 = constant [56 x i8] c"void llvm::SmallPtrSetIteratorImpl::AdvanceIfNotValid()\00"
@global_var_14d0 = constant [14 x i8] c"Bucket <= End\00"
@global_var_14e0 = constant [56 x i8] c"void llvm::SmallPtrSetIteratorImpl::RetreatIfNotValid()\00"
@global_var_1518 = constant [14 x i8] c"Bucket >= End\00"
@global_var_16a0 = constant [309 x i8] c"llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::reference llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::operator*() const [with OptionsT = llvm::ilist_detail::node_options<llvm::DbgRecord, false, false, void, false, void>; bool IsReverse = false; bool IsConst = false; reference = llvm::DbgRecord&]\00"
@global_var_17d8 = constant [47 x i8] c"/usr/include/llvm-21/llvm/ADT/ilist_iterator.h\00"
@global_var_1807 = constant [28 x i8] c"!NodePtr->isKnownSentinel()\00"
@global_var_1828 = constant [26 x i8] c"vector::_M_realloc_insert\00"
@global_var_1986 = constant [50 x i8] c"deobfuscate_opaque_mba::DeobfuscateOpaqueMBAPass]\00"
@global_var_19b8 = constant [7 x i8] c"llvm::\00"
@0 = external global i32
@global_var_40 = constant i128* inttoptr (i64 -556888036579737560 to i128*)

define i64 @_GLOBAL_OFFSET_TABLE_.1(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_0:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !0
  %1 = call i1 @_ZN4llvm3isaINS_17DbgVariableRecordENS_9DbgRecordEEEbRKT0_(i64* %0), !insn.addr !0
  %2 = sext i1 %1 to i64, !insn.addr !0
  ret i64 %2, !insn.addr !1
}

define i64 @_ZN4llvm9map_rangeINS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEZNS_L13filterDbgVarsES9_EUlSA_E0_EEDaOT_T0_(i64* %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_1e:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-120 = alloca i64, align 8
  %stack_var_-88 = alloca i64, align 8
  %stack_var_-152 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !2
  %2 = inttoptr i64 %arg2 to i64**, !insn.addr !3
  %3 = call i64 @_ZN4llvm7adl_endIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEEDTcl8end_implcl7forwardIT_Efp_EEEOSG_(i64* nonnull %stack_var_-152, i64** %2), !insn.addr !3
  %4 = ptrtoint i64* %stack_var_-88 to i64, !insn.addr !4
  %5 = call i64 @_ZN4llvm12map_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_EENS_15mapped_iteratorIT_T0_DTclcl7declvalISH_EEdecl7declvalISG_EEEEEESG_SH_(i64 %4, i64 ptrtoint (i32* @0 to i64)), !insn.addr !5
  %6 = call i64 @_ZN4llvm9adl_beginIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEEDTcl10begin_implcl7forwardIT_Efp_EEEOSG_(i64* nonnull %stack_var_-120, i64** %2), !insn.addr !6
  %7 = ptrtoint i64* %stack_var_-56 to i64, !insn.addr !7
  %8 = call i64 @_ZN4llvm12map_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_EENS_15mapped_iteratorIT_T0_DTclcl7declvalISH_EEdecl7declvalISG_EEEEEESG_SH_(i64 %7, i64 ptrtoint (i32* @0 to i64)), !insn.addr !8
  %9 = call i64 @_ZN4llvm10make_rangeINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS_17DbgVariableRecordEEEEEENS9_IT_EESK_SK_(i64 %0, i64 ptrtoint (i32* @0 to i64)), !insn.addr !9
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !10
  %11 = icmp eq i64 %1, %10, !insn.addr !10
  br i1 %11, label %dec_label_pc_157, label %dec_label_pc_152, !insn.addr !11

dec_label_pc_152:                                 ; preds = %dec_label_pc_1e
  %12 = call i64 @__stack_chk_fail(), !insn.addr !12
  br label %dec_label_pc_157, !insn.addr !12

dec_label_pc_157:                                 ; preds = %dec_label_pc_152, %dec_label_pc_1e
  ret i64 %0, !insn.addr !13

; uselistorder directives
  uselistorder i64 (i64, i64)* @_ZN4llvm12map_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_EENS_15mapped_iteratorIT_T0_DTclcl7declvalISH_EEdecl7declvalISG_EEEEEESG_SH_, { 1, 0 }
}

define i64 @_ZN4llvmL21getDiagnosticSeverityENS_9SourceMgr8DiagKindE(i64 %arg1) local_unnamed_addr {
dec_label_pc_160:
  %rax.0.reg2mem = alloca i64, !insn.addr !14
  %0 = trunc i64 %arg1 to i32, !insn.addr !15
  %1 = icmp eq i32 %0, 3, !insn.addr !15
  store i64 3, i64* %rax.0.reg2mem, !insn.addr !16
  br i1 %1, label %dec_label_pc_1cb, label %dec_label_pc_177, !insn.addr !16

dec_label_pc_177:                                 ; preds = %dec_label_pc_160
  %2 = icmp sgt i32 %0, 3, !insn.addr !17
  br i1 %2, label %dec_label_pc_1ad, label %dec_label_pc_17c, !insn.addr !17

dec_label_pc_17c:                                 ; preds = %dec_label_pc_177
  store i64 2, i64* %rax.0.reg2mem
  switch i32 %0, label %dec_label_pc_1ad [
    i32 2, label %dec_label_pc_1cb
    i32 0, label %dec_label_pc_1cb.fold.split
    i32 1, label %dec_label_pc_198
  ]

dec_label_pc_198:                                 ; preds = %dec_label_pc_17c
  store i64 1, i64* %rax.0.reg2mem, !insn.addr !18
  br label %dec_label_pc_1cb, !insn.addr !18

dec_label_pc_1ad:                                 ; preds = %dec_label_pc_17c, %dec_label_pc_177
  %3 = call i64 @_ZN4llvm25llvm_unreachable_internalEPKcS1_j(i8* getelementptr inbounds ([28 x i8], [28 x i8]* @global_var_1646, i64 0, i64 0), i8* getelementptr inbounds ([46 x i8], [46 x i8]* @global_var_1618, i64 0, i64 0), i32 1138), !insn.addr !19
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !19
  br label %dec_label_pc_1cb, !insn.addr !19

dec_label_pc_1cb.fold.split:                      ; preds = %dec_label_pc_17c
  store i64 0, i64* %rax.0.reg2mem
  br label %dec_label_pc_1cb

dec_label_pc_1cb:                                 ; preds = %dec_label_pc_17c, %dec_label_pc_1cb.fold.split, %dec_label_pc_160, %dec_label_pc_1ad, %dec_label_pc_198
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !20

; uselistorder directives
  uselistorder i64* %rax.0.reg2mem, { 0, 1, 5, 4, 2, 3 }
  uselistorder label %dec_label_pc_1cb, { 1, 3, 4, 0, 2 }
}

define i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass3runERN4llvm6ModuleERNS1_15AnalysisManagerIS2_JEEE(i64* %this, i64* %result, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_1ce:
  %stack_var_-22.010.reg2mem = alloca i8, !insn.addr !21
  %storemerge11.reg2mem = alloca i32, !insn.addr !21
  %0 = ptrtoint i64* %this to i64
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !22
  store i32 0, i32* %storemerge11.reg2mem
  store i8 0, i8* %stack_var_-22.010.reg2mem
  br label %dec_label_pc_209

dec_label_pc_209:                                 ; preds = %dec_label_pc_1ce, %dec_label_pc_2ca
  %stack_var_-22.010.reload = load i8, i8* %stack_var_-22.010.reg2mem
  %2 = call i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass27FoldReadonlyVolatileGlobalsERN4llvm6ModuleE(i64* %arg3), !insn.addr !23
  %3 = urem i64 %2, 256, !insn.addr !24
  %4 = icmp eq i64 %3, 0, !insn.addr !25
  %5 = icmp eq i1 %4, false, !insn.addr !26
  %6 = zext i1 %5 to i64, !insn.addr !27
  %7 = call i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass25ForwardNumericGlobalSeedsERN4llvm6ModuleE(i64* %arg3), !insn.addr !28
  %.masked = urem i64 %7, 256
  %8 = or i64 %.masked, %6, !insn.addr !29
  %9 = icmp eq i64 %8, 0, !insn.addr !30
  %10 = icmp eq i1 %9, false, !insn.addr !31
  %11 = zext i1 %10 to i64, !insn.addr !32
  %12 = call i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass11SimplifyMBAERN4llvm6ModuleE(i64* %arg3), !insn.addr !33
  %.masked6 = urem i64 %12, 256
  %13 = or i64 %.masked6, %11, !insn.addr !34
  %14 = icmp eq i64 %13, 0, !insn.addr !35
  %15 = icmp eq i1 %14, false, !insn.addr !36
  %16 = zext i1 %15 to i64, !insn.addr !37
  %17 = call i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass30CanonicalizeObfuscatedComparesERN4llvm6ModuleE(i64* %arg3), !insn.addr !38
  %.masked7 = urem i64 %17, 256
  %18 = or i64 %.masked7, %16, !insn.addr !39
  %19 = icmp eq i64 %18, 0, !insn.addr !40
  %20 = icmp eq i1 %19, false, !insn.addr !41
  %21 = zext i1 %20 to i64, !insn.addr !42
  %22 = call i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass18EliminateDeadPathsERN4llvm6ModuleE(i64* %arg3), !insn.addr !43
  %.masked8 = urem i64 %22, 256
  %23 = or i64 %.masked8, %21, !insn.addr !44
  %24 = icmp eq i64 %23, 0, !insn.addr !45
  %25 = icmp eq i1 %24, false, !insn.addr !46
  %26 = zext i1 %25 to i64, !insn.addr !47
  %27 = call i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass27FoldReadonlyVolatileGlobalsERN4llvm6ModuleE(i64* %arg3), !insn.addr !48
  %.masked9 = urem i64 %27, 256
  %28 = or i64 %.masked9, %26, !insn.addr !49
  %29 = icmp eq i64 %28, 0, !insn.addr !50
  %30 = icmp eq i1 %29, false, !insn.addr !51
  %31 = zext i1 %30 to i8, !insn.addr !52
  %32 = or i8 %stack_var_-22.010.reload, %31, !insn.addr !53
  %33 = icmp eq i8 %32, 0, !insn.addr !54
  %34 = icmp eq i1 %33, false, !insn.addr !55
  %35 = icmp eq i1 %30, false, !insn.addr !56
  br i1 %35, label %dec_label_pc_2d7, label %dec_label_pc_2ca, !insn.addr !56

dec_label_pc_2ca:                                 ; preds = %dec_label_pc_209
  %storemerge11.reload = load i32, i32* %storemerge11.reg2mem
  %36 = add nuw nsw i32 %storemerge11.reload, 1, !insn.addr !57
  %37 = zext i1 %34 to i8
  %38 = icmp ult i32 %36, 3
  store i32 %36, i32* %storemerge11.reg2mem, !insn.addr !58
  store i8 %37, i8* %stack_var_-22.010.reg2mem, !insn.addr !58
  br i1 %38, label %dec_label_pc_209, label %dec_label_pc_2d7, !insn.addr !58

dec_label_pc_2d7:                                 ; preds = %dec_label_pc_2ca, %dec_label_pc_209
  %39 = icmp eq i1 %34, false, !insn.addr !59
  br i1 %39, label %dec_label_pc_2eb, label %dec_label_pc_2dd, !insn.addr !60

dec_label_pc_2dd:                                 ; preds = %dec_label_pc_2d7
  %40 = call i64 @_ZN4llvm17PreservedAnalyses4noneEv(i64* %this), !insn.addr !61
  br label %dec_label_pc_2f7, !insn.addr !62

dec_label_pc_2eb:                                 ; preds = %dec_label_pc_2d7
  %41 = call i64 @_ZN4llvm17PreservedAnalyses3allEv(i64* %this), !insn.addr !63
  br label %dec_label_pc_2f7, !insn.addr !63

dec_label_pc_2f7:                                 ; preds = %dec_label_pc_2eb, %dec_label_pc_2dd
  %42 = call i64 @__readfsqword(i64 40), !insn.addr !64
  %43 = icmp eq i64 %1, %42, !insn.addr !64
  br i1 %43, label %dec_label_pc_30b, label %dec_label_pc_306, !insn.addr !65

dec_label_pc_306:                                 ; preds = %dec_label_pc_2f7
  %44 = call i64 @__stack_chk_fail(), !insn.addr !66
  br label %dec_label_pc_30b, !insn.addr !66

dec_label_pc_30b:                                 ; preds = %dec_label_pc_306, %dec_label_pc_2f7
  ret i64 %0, !insn.addr !67

; uselistorder directives
  uselistorder i32* %storemerge11.reg2mem, { 1, 0, 2 }
  uselistorder i8* %stack_var_-22.010.reg2mem, { 1, 0, 2 }
  uselistorder i64 (i64*)* @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass27FoldReadonlyVolatileGlobalsERN4llvm6ModuleE, { 1, 0 }
  uselistorder i64* %this, { 1, 0, 2 }
  uselistorder label %dec_label_pc_209, { 1, 0 }
}

define i64 @_ZZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_ENKUlNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS5_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEE_clES3_S9_SC_(i64 %arg1, i64 %arg2, i64 %arg3, i64 %arg4, i64 %arg5, i64 %arg6) local_unnamed_addr {
dec_label_pc_312:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !68
  %storemerge.reg2mem = alloca i64, !insn.addr !68
  %1 = load i64, i64* %0
  %stack_var_-40 = alloca i64, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !69
  %3 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-40, i8* getelementptr inbounds ([28 x i8], [28 x i8]* @global_var_1662, i64 0, i64 0)), !insn.addr !70
  %4 = load i64, i64* %stack_var_-40, align 8, !insn.addr !71
  %5 = inttoptr i64 %arg2 to i64*, !insn.addr !72
  %6 = inttoptr i64 %arg3 to i64*, !insn.addr !72
  %7 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %5, i64* %6, i64 %4, i64 %1), !insn.addr !72
  %8 = trunc i64 %7 to i8, !insn.addr !73
  %9 = icmp eq i8 %8, 0, !insn.addr !73
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !74
  br i1 %9, label %dec_label_pc_39e, label %dec_label_pc_37f, !insn.addr !74

dec_label_pc_37f:                                 ; preds = %dec_label_pc_312
  %10 = inttoptr i64 %arg4 to i64*, !insn.addr !75
  %11 = call i64 @_ZN4llvm11PassManagerINS_6ModuleENS_15AnalysisManagerIS1_JEEEJEE7addPassIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEEENSt9enable_ifIXnt9is_same_vIT_S4_EEvE4typeEOS9_(i64* %10, i64* nonnull %stack_var_-40), !insn.addr !75
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !76
  br label %dec_label_pc_39e, !insn.addr !76

dec_label_pc_39e:                                 ; preds = %dec_label_pc_312, %dec_label_pc_37f
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %12 = call i64 @__readfsqword(i64 40), !insn.addr !77
  %13 = icmp eq i64 %2, %12, !insn.addr !77
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !78
  br i1 %13, label %dec_label_pc_3b2, label %dec_label_pc_3ad, !insn.addr !78

dec_label_pc_3ad:                                 ; preds = %dec_label_pc_39e
  %14 = call i64 @__stack_chk_fail(), !insn.addr !79
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !79
  br label %dec_label_pc_3b2, !insn.addr !79

dec_label_pc_3b2:                                 ; preds = %dec_label_pc_3ad, %dec_label_pc_39e
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !80

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 0, 2, 1 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_39e, { 1, 0 }
}

define i64 @_ZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3b4:
  %rax.0.reg2mem = alloca i64, !insn.addr !81
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-57 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !82
  %1 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1IZZ21llvmGetPassPluginInfoENKUlRS9_E_clESF_EUlS1_S7_SB_E_vEEOT_(i64* nonnull %stack_var_-56, i64* nonnull %stack_var_-57), !insn.addr !83
  %2 = call i64 @_ZN4llvm11PassBuilder31registerPipelineParsingCallbackERKSt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEEE(i64* %arg2, i64* nonnull %stack_var_-56), !insn.addr !84
  %3 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev(i64* nonnull %stack_var_-56), !insn.addr !85
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !86
  %5 = icmp eq i64 %0, %4, !insn.addr !86
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !87
  br i1 %5, label %dec_label_pc_41a, label %dec_label_pc_415, !insn.addr !87

dec_label_pc_415:                                 ; preds = %dec_label_pc_3b4
  %6 = call i64 @__stack_chk_fail(), !insn.addr !88
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !88
  br label %dec_label_pc_41a, !insn.addr !88

dec_label_pc_41a:                                 ; preds = %dec_label_pc_415, %dec_label_pc_3b4
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !89
}

define i64 @_ZZ21llvmGetPassPluginInfoENUlRN4llvm11PassBuilderEE_4_FUNES1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_41c:
  %0 = call i64 @_ZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_(i64* null, i64* %arg1), !insn.addr !90
  ret i64 %0, !insn.addr !91
}

define i64 @llvmGetPassPluginInfo(i64 %arg1) local_unnamed_addr {
dec_label_pc_43f:
  %0 = inttoptr i64 %arg1 to i32*, !insn.addr !92
  store i32 1, i32* %0, align 4, !insn.addr !92
  %1 = add i64 %arg1, 8, !insn.addr !93
  %2 = inttoptr i64 %1 to i64*, !insn.addr !93
  store i64 ptrtoint ([25 x i8]* @global_var_167e to i64), i64* %2, align 8, !insn.addr !93
  %3 = add i64 %arg1, 16, !insn.addr !94
  %4 = inttoptr i64 %3 to i64*, !insn.addr !94
  store i64 ptrtoint ([6 x i8]* @global_var_1697 to i64), i64* %4, align 8, !insn.addr !94
  %5 = add i64 %arg1, 24, !insn.addr !95
  %6 = inttoptr i64 %5 to i64*, !insn.addr !95
  store i64 1052, i64* %6, align 8, !insn.addr !95
  ret i64 %arg1, !insn.addr !96
}

define i64 @_ZN4llvm17make_filter_rangeIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEZNS_L13filterDbgVarsES8_EUlRS5_E_EENS1_INS_20filter_iterator_implIDTcl9adl_begincl7declvalIRT_EEEET0_NS_6detail15fwd_or_bidi_tagISF_E4typeEEEEEOSD_SG_(i64** %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_488:
  %0 = ptrtoint i64** %arg1 to i64
  %stack_var_-72 = alloca i64, align 8
  %stack_var_-40 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !97
  %2 = inttoptr i64 %arg2 to i64**, !insn.addr !98
  %3 = call i64 @_ZN4llvm9adl_beginIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl10begin_implcl7forwardIT_Efp_EEEOSA_(i64** %2), !insn.addr !98
  %4 = call i64 @_ZN4llvm7adl_endIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl8end_implcl7forwardIT_Efp_EEEOSA_(i64** %2), !insn.addr !99
  %5 = ptrtoint i64* %stack_var_-40 to i64, !insn.addr !100
  %6 = call i64 @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_(i64 %5, i64 %4, i64 %4), !insn.addr !101
  %7 = ptrtoint i64* %stack_var_-72 to i64, !insn.addr !102
  %8 = call i64 @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_(i64 %7, i64 %3, i64 %4), !insn.addr !103
  %9 = call i64 @_ZN4llvm10make_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEENS8_IT_EESE_SE_(i64 %0, i64 ptrtoint (i32* @0 to i64)), !insn.addr !104
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !105
  %11 = icmp eq i64 %1, %10, !insn.addr !105
  br i1 %11, label %dec_label_pc_55a, label %dec_label_pc_555, !insn.addr !106

dec_label_pc_555:                                 ; preds = %dec_label_pc_488
  %12 = call i64 @__stack_chk_fail(), !insn.addr !107
  br label %dec_label_pc_55a, !insn.addr !107

dec_label_pc_55a:                                 ; preds = %dec_label_pc_555, %dec_label_pc_488
  ret i64 %0, !insn.addr !108

; uselistorder directives
  uselistorder i64 %4, { 0, 2, 1 }
  uselistorder i64 (i64, i64, i64)* @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_, { 1, 0 }
}

define i64 @_ZN4llvm9adl_beginIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEEDTcl10begin_implcl7forwardIT_Efp_EEEOSG_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_560:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !109
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !110
  %3 = call i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %2), !insn.addr !111
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !112
  %5 = icmp eq i64 %0, %4, !insn.addr !112
  br i1 %5, label %dec_label_pc_5b2, label %dec_label_pc_5ad, !insn.addr !113

dec_label_pc_5ad:                                 ; preds = %dec_label_pc_560
  %6 = call i64 @__stack_chk_fail(), !insn.addr !114
  br label %dec_label_pc_5b2, !insn.addr !114

dec_label_pc_5b2:                                 ; preds = %dec_label_pc_5ad, %dec_label_pc_560
  %7 = ptrtoint i64* %result to i64
  ret i64 %7, !insn.addr !115

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64 @_ZN4llvm12map_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_EENS_15mapped_iteratorIT_T0_DTclcl7declvalISH_EEdecl7declvalISG_EEEEEESG_SH_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_5b8:
  %stack_var_8 = alloca i64, align 8
  %stack_var_-17 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_-17 to i64**, !insn.addr !116
  %1 = call i64* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_(i64** nonnull %0), !insn.addr !116
  %2 = bitcast i64* %stack_var_8 to i64**, !insn.addr !117
  %3 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %2), !insn.addr !117
  %4 = call i64 @_ZN4llvm15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEC1ESD_SE_(i64 %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !118
  ret i64 %arg1, !insn.addr !119
}

define i64 @_ZN4llvm7adl_endIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEEDTcl8end_implcl7forwardIT_Efp_EEEOSG_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_610:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !120
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !121
  %3 = call i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %2), !insn.addr !122
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !123
  %5 = icmp eq i64 %0, %4, !insn.addr !123
  br i1 %5, label %dec_label_pc_662, label %dec_label_pc_65d, !insn.addr !124

dec_label_pc_65d:                                 ; preds = %dec_label_pc_610
  %6 = call i64 @__stack_chk_fail(), !insn.addr !125
  br label %dec_label_pc_662, !insn.addr !125

dec_label_pc_662:                                 ; preds = %dec_label_pc_65d, %dec_label_pc_610
  %7 = ptrtoint i64* %result to i64
  ret i64 %7, !insn.addr !126

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64 @_ZN4llvm10make_rangeINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS_17DbgVariableRecordEEEEEENS9_IT_EESK_SK_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_668:
  %stack_var_8 = alloca i64, align 8
  %stack_var_40 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_40 to i64**, !insn.addr !127
  %1 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %0), !insn.addr !127
  %2 = bitcast i64* %stack_var_8 to i64**, !insn.addr !128
  %3 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %2), !insn.addr !128
  %4 = call i64 @_ZN4llvm14iterator_rangeINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEEEC1ESI_SI_(i64 %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !129
  ret i64 %arg1, !insn.addr !130
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1IZZ21llvmGetPassPluginInfoENKUlRS9_E_clESF_EUlS1_S7_SB_E_vEEOT_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_6f6:
  %0 = alloca i128
  %rax.0.reg2mem = alloca i64, !insn.addr !131
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %result to i64
  %3 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !132
  %4 = bitcast i64* %rdi to i128*
  %5 = load i128, i128* %4, align 8, !insn.addr !133
  call void @__asm_movups(i128 %5, i128 %3), !insn.addr !133
  %6 = add i64 %2, 16, !insn.addr !134
  %7 = inttoptr i64 %6 to i64*, !insn.addr !134
  %8 = load i64, i64* %7, align 8, !insn.addr !134
  call void @__asm_movq(i64 %8, i128 %3), !insn.addr !134
  %9 = call i64 @_ZNSt14_Function_baseC1Ev(i64* %result), !insn.addr !135
  %10 = add i64 %2, 24, !insn.addr !136
  %11 = inttoptr i64 %10 to i64*, !insn.addr !136
  store i64 0, i64* %11, align 8, !insn.addr !136
  %12 = call i1 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E21_M_not_empty_functionISF_EEbRKT_(i64* %arg2), !insn.addr !137
  %13 = icmp eq i1 %12, false, !insn.addr !138
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !139
  br i1 %13, label %dec_label_pc_77a, label %dec_label_pc_73e, !insn.addr !139

dec_label_pc_73e:                                 ; preds = %dec_label_pc_6f6
  %14 = call i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg2), !insn.addr !140
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorISF_EEvRSt9_Any_dataOT_(i64* %result, i64* %14), !insn.addr !141
  store i64 2635, i64* %11, align 8, !insn.addr !142
  store i64 2753, i64* %7, align 8, !insn.addr !143
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !143
  br label %dec_label_pc_77a, !insn.addr !143

dec_label_pc_77a:                                 ; preds = %dec_label_pc_73e, %dec_label_pc_6f6
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !144

; uselistorder directives
  uselistorder i128 %3, { 1, 0 }
}

define i64 @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_(i64 %arg1, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_77e:
  %0 = call i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC2ES6_S6_SA_(i64 %arg1, i64 %arg2, i64 %arg3), !insn.addr !145
  ret i64 %0, !insn.addr !146
}

define i64 @_ZN4llvm10make_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEENS8_IT_EESE_SE_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_7ac:
  %stack_var_8 = alloca i64, align 8
  %stack_var_32 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_32 to i64**, !insn.addr !147
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !147
  %2 = bitcast i64* %stack_var_8 to i64**, !insn.addr !148
  %3 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %2), !insn.addr !148
  %4 = call i64 @_ZN4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEC1ESC_SC_(i64 %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !149
  ret i64 %arg1, !insn.addr !150
}

define i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_829:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !151
  ret i64** %0, !insn.addr !151
}

define i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_837:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !152
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !153
  %3 = bitcast i64** %2 to i64*, !insn.addr !154
  %4 = call i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE5beginEv(i64* %result, i64* %3), !insn.addr !154
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !155
  %6 = icmp eq i64 %0, %5, !insn.addr !155
  br i1 %6, label %dec_label_pc_88f, label %dec_label_pc_88a, !insn.addr !156

dec_label_pc_88a:                                 ; preds = %dec_label_pc_837
  %7 = call i64 @__stack_chk_fail(), !insn.addr !157
  br label %dec_label_pc_88f, !insn.addr !157

dec_label_pc_88f:                                 ; preds = %dec_label_pc_88a, %dec_label_pc_837
  %8 = ptrtoint i64* %result to i64
  ret i64 %8, !insn.addr !158

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** %arg1) local_unnamed_addr {
dec_label_pc_895:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !159
  ret i64* %0, !insn.addr !159
}

define i64* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_(i64** %arg1) local_unnamed_addr {
dec_label_pc_8a3:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !160
  ret i64* %0, !insn.addr !160
}

define i64 @_ZN4llvm15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEC1ESD_SE_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_8b2:
  %stack_var_-33 = alloca i64, align 8
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !161
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !161
  %2 = call i64 @_ZN4llvm21iterator_adaptor_baseINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS_17DbgVariableRecordEEEESE_SD_SI_lPSI_SI_EC2ESE_(i64 %arg1), !insn.addr !162
  %3 = add i64 %arg1, 24, !insn.addr !163
  %4 = bitcast i64* %stack_var_-33 to i64**, !insn.addr !164
  %5 = call i64* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_(i64** nonnull %4), !insn.addr !164
  %6 = inttoptr i64 %3 to i64*, !insn.addr !165
  %7 = call i64 @_ZN4llvm15callable_detail8CallableIZNS_L13filterDbgVarsENS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS6_E0_Lb0EEC1ERKSB_(i64* %6, i64* %5), !insn.addr !165
  ret i64 %7, !insn.addr !166

; uselistorder directives
  uselistorder i64* (i64**)* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_, { 1, 0 }
}

define i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_922:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !167
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !168
  %3 = bitcast i64** %2 to i64*, !insn.addr !169
  %4 = call i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE3endEv(i64* %result, i64* %3), !insn.addr !169
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !170
  %6 = icmp eq i64 %0, %5, !insn.addr !170
  br i1 %6, label %dec_label_pc_97a, label %dec_label_pc_975, !insn.addr !171

dec_label_pc_975:                                 ; preds = %dec_label_pc_922
  %7 = call i64 @__stack_chk_fail(), !insn.addr !172
  br label %dec_label_pc_97a, !insn.addr !172

dec_label_pc_97a:                                 ; preds = %dec_label_pc_975, %dec_label_pc_922
  %8 = ptrtoint i64* %result to i64
  ret i64 %8, !insn.addr !173

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE, { 3, 2, 1, 0 }
  uselistorder i64* %result, { 1, 0 }
}

define i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** %arg1) local_unnamed_addr {
dec_label_pc_980:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !174
  ret i64* %0, !insn.addr !174
}

define i64 @_ZN4llvm14iterator_rangeINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEEEC1ESI_SI_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_98e:
  %stack_var_40 = alloca i64, align 8
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !175
  %1 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %0), !insn.addr !175
  %2 = ptrtoint i64* %1 to i64, !insn.addr !175
  %3 = load i64, i64* %1, align 8, !insn.addr !176
  %4 = add i64 %2, 8, !insn.addr !177
  %5 = inttoptr i64 %4 to i64*, !insn.addr !177
  %6 = load i64, i64* %5, align 8, !insn.addr !177
  %7 = inttoptr i64 %arg1 to i64*, !insn.addr !178
  store i64 %3, i64* %7, align 8, !insn.addr !178
  %8 = add i64 %arg1, 8, !insn.addr !179
  %9 = inttoptr i64 %8 to i64*, !insn.addr !179
  store i64 %6, i64* %9, align 8, !insn.addr !179
  %10 = add i64 %2, 16, !insn.addr !180
  %11 = inttoptr i64 %10 to i64*, !insn.addr !180
  %12 = load i64, i64* %11, align 8, !insn.addr !180
  %13 = add i64 %2, 24, !insn.addr !181
  %14 = inttoptr i64 %13 to i64*, !insn.addr !181
  %15 = load i64, i64* %14, align 8, !insn.addr !181
  %16 = add i64 %arg1, 16, !insn.addr !182
  %17 = inttoptr i64 %16 to i64*, !insn.addr !182
  store i64 %12, i64* %17, align 8, !insn.addr !182
  %18 = add i64 %arg1, 24, !insn.addr !183
  %19 = inttoptr i64 %18 to i64*, !insn.addr !183
  store i64 %15, i64* %19, align 8, !insn.addr !183
  %20 = bitcast i64* %stack_var_40 to i64**, !insn.addr !184
  %21 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %20), !insn.addr !184
  %22 = ptrtoint i64* %21 to i64, !insn.addr !184
  %23 = load i64, i64* %21, align 8, !insn.addr !185
  %24 = add i64 %22, 8, !insn.addr !186
  %25 = inttoptr i64 %24 to i64*, !insn.addr !186
  %26 = load i64, i64* %25, align 8, !insn.addr !186
  %27 = add i64 %arg1, 32, !insn.addr !187
  %28 = inttoptr i64 %27 to i64*, !insn.addr !187
  store i64 %23, i64* %28, align 8, !insn.addr !187
  %29 = add i64 %arg1, 40, !insn.addr !188
  %30 = inttoptr i64 %29 to i64*, !insn.addr !188
  store i64 %26, i64* %30, align 8, !insn.addr !188
  %31 = add i64 %22, 16, !insn.addr !189
  %32 = inttoptr i64 %31 to i64*, !insn.addr !189
  %33 = load i64, i64* %32, align 8, !insn.addr !189
  %34 = add i64 %22, 24, !insn.addr !190
  %35 = inttoptr i64 %34 to i64*, !insn.addr !190
  %36 = load i64, i64* %35, align 8, !insn.addr !190
  %37 = add i64 %arg1, 48, !insn.addr !191
  %38 = inttoptr i64 %37 to i64*, !insn.addr !191
  store i64 %33, i64* %38, align 8, !insn.addr !191
  %39 = add i64 %arg1, 56, !insn.addr !192
  %40 = inttoptr i64 %39 to i64*, !insn.addr !192
  store i64 %36, i64* %40, align 8, !insn.addr !192
  ret i64 %33, !insn.addr !193

; uselistorder directives
  uselistorder i64 %33, { 1, 0 }
  uselistorder i64 %22, { 2, 1, 0 }
  uselistorder i64 %2, { 2, 1, 0 }
  uselistorder i64* (i64**)* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_, { 3, 2, 1, 0 }
}

define i1 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E21_M_not_empty_functionISF_EEbRKT_(i64* %arg1) local_unnamed_addr {
dec_label_pc_9fd:
  ret i1 true, !insn.addr !194
}

define i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a0c:
  ret i64* %arg1, !insn.addr !195
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorISF_EEvRSt9_Any_dataOT_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_a1a:
  %0 = call i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg2), !insn.addr !196
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createISF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64* %0, i64 ptrtoint (i32* @0 to i64)), !insn.addr !197
  ret void, !insn.addr !198
}

define i64 @_ZNSt17_Function_handlerIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEZZ21llvmGetPassPluginInfoENKUlRS9_E_clESD_EUlS1_S7_SB_E_E9_M_invokeERKSt9_Any_dataOS1_S7_OSB_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_a4b:
  %0 = call i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %arg4), !insn.addr !199
  %1 = ptrtoint i64* %0 to i64, !insn.addr !199
  %2 = call i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %arg3), !insn.addr !200
  %3 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %arg2), !insn.addr !201
  %4 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg1), !insn.addr !202
  %5 = inttoptr i64 %4 to i64*, !insn.addr !203
  %6 = call i64 @_ZSt10__invoke_rIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EENSt9enable_ifIX16is_invocable_r_vIT_T0_DpT1_EESH_E4typeEOSI_DpOSJ_(i64* %5, i64* %3, i64** %2, i64 %1), !insn.addr !203
  ret i64 %6, !insn.addr !204
}

define i64 @_ZNSt17_Function_handlerIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEZZ21llvmGetPassPluginInfoENKUlRS9_E_clESD_EUlS1_S7_SB_E_E10_M_managerERSt9_Any_dataRKSH_St18_Manager_operation(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_ac1:
  %0 = trunc i64 %arg3 to i32, !insn.addr !205
  switch i32 %0, label %dec_label_pc_b1f [
    i32 0, label %dec_label_pc_ae7
    i32 1, label %dec_label_pc_aff
  ]

dec_label_pc_ae7:                                 ; preds = %dec_label_pc_ac1
  %1 = call i64** @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v(i64* %arg1), !insn.addr !206
  %2 = bitcast i64** %1 to i64*, !insn.addr !207
  store i64 ptrtoint (i64* @global_var_4968 to i64), i64* %2, align 8, !insn.addr !207
  br label %dec_label_pc_b35, !insn.addr !208

dec_label_pc_aff:                                 ; preds = %dec_label_pc_ac1
  %3 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg2), !insn.addr !209
  %4 = call i64** @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %arg1), !insn.addr !210
  %5 = bitcast i64** %4 to i64*, !insn.addr !211
  store i64 %3, i64* %5, align 8, !insn.addr !211
  br label %dec_label_pc_b35, !insn.addr !212

dec_label_pc_b1f:                                 ; preds = %dec_label_pc_ac1
  %6 = and i64 %arg3, 4294967295
  %7 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_managerERSt9_Any_dataRKSH_St18_Manager_operation(i64* %arg1, i64* %arg2, i64 %6), !insn.addr !213
  br label %dec_label_pc_b35, !insn.addr !213

dec_label_pc_b35:                                 ; preds = %dec_label_pc_b1f, %dec_label_pc_aff, %dec_label_pc_ae7
  ret i64 0, !insn.addr !214

; uselistorder directives
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder i64* %arg1, { 2, 1, 0 }
}

define i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC2ES6_S6_SA_(i64 %arg1, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_b40:
  %0 = inttoptr i64 %arg1 to i64*, !insn.addr !215
  %1 = call i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EC2ES7_(i64* %0, i64 %arg2), !insn.addr !215
  %2 = add i64 %arg1, 8, !insn.addr !216
  %3 = inttoptr i64 %2 to i64*, !insn.addr !216
  store i64 %arg3, i64* %3, align 8, !insn.addr !216
  %4 = call i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagE13findNextValidEv(i64* %0), !insn.addr !217
  ret i64 %4, !insn.addr !218
}

define i64 @_ZN4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEC1ESC_SC_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_b82:
  %stack_var_32 = alloca i64, align 8
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !219
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !219
  %2 = ptrtoint i64* %1 to i64, !insn.addr !219
  %3 = load i64, i64* %1, align 8, !insn.addr !220
  %4 = add i64 %2, 8, !insn.addr !221
  %5 = inttoptr i64 %4 to i64*, !insn.addr !221
  %6 = load i64, i64* %5, align 8, !insn.addr !221
  %7 = inttoptr i64 %arg1 to i64*, !insn.addr !222
  store i64 %3, i64* %7, align 8, !insn.addr !222
  %8 = add i64 %arg1, 8, !insn.addr !223
  %9 = inttoptr i64 %8 to i64*, !insn.addr !223
  store i64 %6, i64* %9, align 8, !insn.addr !223
  %10 = add i64 %2, 16, !insn.addr !224
  %11 = inttoptr i64 %10 to i64*, !insn.addr !224
  %12 = load i64, i64* %11, align 8, !insn.addr !224
  %13 = add i64 %arg1, 16, !insn.addr !225
  %14 = inttoptr i64 %13 to i64*, !insn.addr !225
  store i64 %12, i64* %14, align 8, !insn.addr !225
  %15 = bitcast i64* %stack_var_32 to i64**, !insn.addr !226
  %16 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %15), !insn.addr !226
  %17 = ptrtoint i64* %16 to i64, !insn.addr !226
  %18 = load i64, i64* %16, align 8, !insn.addr !227
  %19 = add i64 %17, 8, !insn.addr !228
  %20 = inttoptr i64 %19 to i64*, !insn.addr !228
  %21 = load i64, i64* %20, align 8, !insn.addr !228
  %22 = add i64 %arg1, 24, !insn.addr !229
  %23 = inttoptr i64 %22 to i64*, !insn.addr !229
  store i64 %18, i64* %23, align 8, !insn.addr !229
  %24 = add i64 %arg1, 32, !insn.addr !230
  %25 = inttoptr i64 %24 to i64*, !insn.addr !230
  store i64 %21, i64* %25, align 8, !insn.addr !230
  %26 = add i64 %17, 16, !insn.addr !231
  %27 = inttoptr i64 %26 to i64*, !insn.addr !231
  %28 = load i64, i64* %27, align 8, !insn.addr !231
  %29 = add i64 %arg1, 40, !insn.addr !232
  %30 = inttoptr i64 %29 to i64*, !insn.addr !232
  store i64 %28, i64* %30, align 8, !insn.addr !232
  ret i64 %28, !insn.addr !233

; uselistorder directives
  uselistorder i64 %28, { 1, 0 }
  uselistorder i64 %17, { 1, 0 }
  uselistorder i64 %2, { 1, 0 }
}

define i64 @_ZN4llvm21iterator_adaptor_baseINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS_17DbgVariableRecordEEEESE_SD_SI_lPSI_SI_EC2ESE_(i64 %arg1) local_unnamed_addr {
dec_label_pc_be2:
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !234
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !234
  %2 = ptrtoint i64* %1 to i64, !insn.addr !234
  %3 = load i64, i64* %1, align 8, !insn.addr !235
  %4 = add i64 %2, 8, !insn.addr !236
  %5 = inttoptr i64 %4 to i64*, !insn.addr !236
  %6 = load i64, i64* %5, align 8, !insn.addr !236
  %7 = inttoptr i64 %arg1 to i64*, !insn.addr !237
  store i64 %3, i64* %7, align 8, !insn.addr !237
  %8 = add i64 %arg1, 8, !insn.addr !238
  %9 = inttoptr i64 %8 to i64*, !insn.addr !238
  store i64 %6, i64* %9, align 8, !insn.addr !238
  %10 = add i64 %2, 16, !insn.addr !239
  %11 = inttoptr i64 %10 to i64*, !insn.addr !239
  %12 = load i64, i64* %11, align 8, !insn.addr !239
  %13 = add i64 %arg1, 16, !insn.addr !240
  %14 = inttoptr i64 %13 to i64*, !insn.addr !240
  store i64 %12, i64* %14, align 8, !insn.addr !240
  ret i64 %12, !insn.addr !241

; uselistorder directives
  uselistorder i64 %12, { 1, 0 }
  uselistorder i64 %2, { 1, 0 }
  uselistorder i64* (i64**)* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_, { 2, 6, 5, 1, 4, 3, 0 }
}

define i64 @_ZN4llvm15callable_detail8CallableIZNS_L13filterDbgVarsENS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS6_E0_Lb0EEC1ERKSB_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_c18:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt8optionalIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC1IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %1, i64 %0), !insn.addr !242
  ret i64 %2, !insn.addr !243
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createISF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_c3e:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %arg1), !insn.addr !244
  %1 = inttoptr i64 %0 to i64*, !insn.addr !245
  %2 = call i64 @_ZnwmPv(i64 1, i64* %1), !insn.addr !245
  %3 = call i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg2), !insn.addr !246
  ret void, !insn.addr !247

; uselistorder directives
  uselistorder i64* (i64*)* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE, { 2, 1, 0 }
}

define i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg1) local_unnamed_addr {
dec_label_pc_c76:
  %0 = call i64* @_ZNKSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERKT_v(i64* %arg1), !insn.addr !248
  %1 = call i64* @_ZSt11__addressofIKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EPT_RSG_(i64* %0), !insn.addr !249
  %2 = ptrtoint i64* %1 to i64, !insn.addr !249
  ret i64 %2, !insn.addr !250
}

define i64 @_ZSt10__invoke_rIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EENSt9enable_ifIX16is_invocable_r_vIT_T0_DpT1_EESH_E4typeEOSI_DpOSJ_(i64* %this, i64* %result, i64** %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_ca0:
  %0 = inttoptr i64 %arg4 to i64*, !insn.addr !251
  %1 = call i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %0), !insn.addr !251
  %2 = ptrtoint i64* %1 to i64, !insn.addr !251
  %3 = bitcast i64** %arg3 to i64*, !insn.addr !252
  %4 = call i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %3), !insn.addr !252
  %5 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %result), !insn.addr !253
  %6 = ptrtoint i64* %5 to i64, !insn.addr !253
  %7 = call i64** @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE(i64* %this), !insn.addr !254
  %8 = bitcast i64** %7 to i64*, !insn.addr !255
  %9 = call i1 @_ZSt13__invoke_implIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EET_St14__invoke_otherOT0_DpOT1_(i64* %8, i64 %6, i64** %4, i64 %2), !insn.addr !255
  %10 = sext i1 %9 to i64, !insn.addr !255
  ret i64 %10, !insn.addr !256
}

define i64** @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %result) local_unnamed_addr {
dec_label_pc_d12:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !257
  %1 = inttoptr i64 %0 to i64**, !insn.addr !258
  ret i64** %1, !insn.addr !258
}

define i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_managerERSt9_Any_dataRKSH_St18_Manager_operation(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_d2c:
  %0 = trunc i64 %arg3 to i32, !insn.addr !259
  %1 = icmp eq i32 %0, 3, !insn.addr !259
  br i1 %1, label %dec_label_pc_dba, label %dec_label_pc_d48, !insn.addr !260

dec_label_pc_d48:                                 ; preds = %dec_label_pc_d2c
  %2 = icmp sgt i32 %0, 3, !insn.addr !261
  br i1 %2, label %dec_label_pc_dc7, label %dec_label_pc_d4d, !insn.addr !261

dec_label_pc_d4d:                                 ; preds = %dec_label_pc_d48
  switch i32 %0, label %dec_label_pc_dc7 [
    i32 2, label %dec_label_pc_d9a
    i32 0, label %dec_label_pc_d62
    i32 1, label %dec_label_pc_d7a
  ]

dec_label_pc_d62:                                 ; preds = %dec_label_pc_d4d
  %3 = call i64** @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v(i64* %arg1), !insn.addr !262
  %4 = bitcast i64** %3 to i64*, !insn.addr !263
  store i64 ptrtoint (i64* @global_var_4968 to i64), i64* %4, align 8, !insn.addr !263
  br label %dec_label_pc_dc7, !insn.addr !264

dec_label_pc_d7a:                                 ; preds = %dec_label_pc_d4d
  %5 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg2), !insn.addr !265
  %6 = call i64** @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %arg1), !insn.addr !266
  %7 = bitcast i64** %6 to i64*, !insn.addr !267
  store i64 %5, i64* %7, align 8, !insn.addr !267
  br label %dec_label_pc_dc7, !insn.addr !268

dec_label_pc_d9a:                                 ; preds = %dec_label_pc_d4d
  %8 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg2), !insn.addr !269
  %9 = inttoptr i64 %8 to i64**, !insn.addr !270
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorIRKSF_EEvRSt9_Any_dataOT_(i64* %arg1, i64** %9), !insn.addr !270
  br label %dec_label_pc_dc7, !insn.addr !271

dec_label_pc_dba:                                 ; preds = %dec_label_pc_d2c
  %10 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_destroyERSt9_Any_dataSt17integral_constantIbLb1EE(i64* %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !272
  br label %dec_label_pc_dc7, !insn.addr !273

dec_label_pc_dc7:                                 ; preds = %dec_label_pc_d4d, %dec_label_pc_dba, %dec_label_pc_d9a, %dec_label_pc_d7a, %dec_label_pc_d62, %dec_label_pc_d48
  ret i64 0, !insn.addr !274

; uselistorder directives
  uselistorder i64** (i64*)* @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data, { 3, 2, 1, 0 }
  uselistorder i64** (i64*)* @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v, { 1, 0 }
  uselistorder i32 3, { 3, 0, 1, 4, 2 }
  uselistorder i64* %arg1, { 0, 1, 3, 2 }
  uselistorder label %dec_label_pc_dc7, { 1, 2, 3, 4, 0, 5 }
}

define i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EC2ES7_(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_dd2:
  %stack_var_-24 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-24, align 8, !insn.addr !275
  %0 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !276
  %1 = call i64* @_ZSt4moveIRN4llvm14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEONSt16remove_referenceIT_E4typeEOS9_(i64** nonnull %0), !insn.addr !276
  %2 = load i64, i64* %1, align 8, !insn.addr !277
  store i64 %2, i64* %result, align 8, !insn.addr !278
  ret i64 %2, !insn.addr !279

; uselistorder directives
  uselistorder i64 %2, { 1, 0 }
}

define i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagE13findNextValidEv(i64* %result) local_unnamed_addr {
dec_label_pc_dfc:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16
  %2 = add i64 %0, 8, !insn.addr !280
  %3 = inttoptr i64 %2 to i64*, !insn.addr !281
  %4 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %result, i64* %3), !insn.addr !281
  %5 = trunc i64 %4 to i8, !insn.addr !282
  %6 = icmp eq i8 %5, 0, !insn.addr !282
  br i1 %6, label %dec_label_pc_e68, label %dec_label_pc_e32, !insn.addr !283

dec_label_pc_e0b:                                 ; preds = %dec_label_pc_e32
  %7 = call i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EppEv(i64* %result), !insn.addr !284
  %8 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %result, i64* %3), !insn.addr !281
  %9 = trunc i64 %8 to i8, !insn.addr !282
  %10 = icmp eq i8 %9, 0, !insn.addr !282
  br i1 %10, label %dec_label_pc_e68, label %dec_label_pc_e32, !insn.addr !283

dec_label_pc_e32:                                 ; preds = %dec_label_pc_dfc, %dec_label_pc_e0b
  %11 = call i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* %result), !insn.addr !285
  %12 = call i64 @_GLOBAL_OFFSET_TABLE_.1(i64 %1, i64 %11), !insn.addr !286
  %13 = trunc i64 %12 to i8
  %14 = icmp eq i8 %13, 1, !insn.addr !287
  br i1 %14, label %dec_label_pc_e68, label %dec_label_pc_e0b, !insn.addr !288

dec_label_pc_e68:                                 ; preds = %dec_label_pc_e0b, %dec_label_pc_e32, %dec_label_pc_dfc
  ret i64 0, !insn.addr !289

; uselistorder directives
  uselistorder i64* %3, { 1, 0 }
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_, { 1, 0 }
  uselistorder i64* %result, { 2, 3, 1, 0, 4 }
  uselistorder label %dec_label_pc_e68, { 1, 0, 2 }
  uselistorder label %dec_label_pc_e32, { 1, 0 }
}

define i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE5beginEv(i64* %this, i64* %result) local_unnamed_addr {
dec_label_pc_e70:
  %0 = ptrtoint i64* %result to i64
  %1 = ptrtoint i64* %this to i64
  %2 = add i64 %0, 8, !insn.addr !290
  %3 = inttoptr i64 %2 to i64*, !insn.addr !290
  %4 = load i64, i64* %3, align 8, !insn.addr !290
  store i64 %0, i64* %this, align 8, !insn.addr !291
  %5 = add i64 %1, 8, !insn.addr !292
  %6 = inttoptr i64 %5 to i64*, !insn.addr !292
  store i64 %4, i64* %6, align 8, !insn.addr !292
  %7 = add i64 %0, 16, !insn.addr !293
  %8 = inttoptr i64 %7 to i64*, !insn.addr !293
  %9 = load i64, i64* %8, align 8, !insn.addr !293
  %10 = add i64 %1, 16, !insn.addr !294
  %11 = inttoptr i64 %10 to i64*, !insn.addr !294
  store i64 %9, i64* %11, align 8, !insn.addr !294
  ret i64 %1, !insn.addr !295

; uselistorder directives
  uselistorder i64 %1, { 0, 2, 1 }
  uselistorder i64 %0, { 2, 0, 1 }
}

define i64 @_ZNSt8optionalIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC1IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_ea0:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !296
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !296
  %2 = ptrtoint i64** %1 to i64, !insn.addr !296
  %3 = call i64 @_ZNSt14_Optional_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb1EEC2IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !297
  ret i64 %3, !insn.addr !298
}

define i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE3endEv(i64* %this, i64* %result) local_unnamed_addr {
dec_label_pc_ed4:
  %0 = ptrtoint i64* %result to i64
  %1 = ptrtoint i64* %this to i64
  %2 = add i64 %0, 24, !insn.addr !299
  %3 = inttoptr i64 %2 to i64*, !insn.addr !299
  %4 = load i64, i64* %3, align 8, !insn.addr !299
  %5 = add i64 %0, 32, !insn.addr !300
  %6 = inttoptr i64 %5 to i64*, !insn.addr !300
  %7 = load i64, i64* %6, align 8, !insn.addr !300
  store i64 %4, i64* %this, align 8, !insn.addr !301
  %8 = add i64 %1, 8, !insn.addr !302
  %9 = inttoptr i64 %8 to i64*, !insn.addr !302
  store i64 %7, i64* %9, align 8, !insn.addr !302
  %10 = add i64 %0, 40, !insn.addr !303
  %11 = inttoptr i64 %10 to i64*, !insn.addr !303
  %12 = load i64, i64* %11, align 8, !insn.addr !303
  %13 = add i64 %1, 16, !insn.addr !304
  %14 = inttoptr i64 %13 to i64*, !insn.addr !304
  store i64 %12, i64* %14, align 8, !insn.addr !304
  ret i64 %1, !insn.addr !305

; uselistorder directives
  uselistorder i64 %1, { 0, 2, 1 }
  uselistorder i64 %0, { 2, 1, 0 }
}

define i64* @_ZNKSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERKT_v(i64* %result) local_unnamed_addr {
dec_label_pc_f06:
  %0 = call i64 @_ZNKSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !306
  %1 = inttoptr i64 %0 to i64*, !insn.addr !307
  ret i64* %1, !insn.addr !307
}

define i64* @_ZSt11__addressofIKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EPT_RSG_(i64* %arg1) local_unnamed_addr {
dec_label_pc_f20:
  ret i64* %arg1, !insn.addr !308
}

define i64** @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_f2e:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !309
  ret i64** %0, !insn.addr !309
}

define i1 @_ZSt13__invoke_implIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EET_St14__invoke_otherOT0_DpOT1_(i64* %result, i64 %arg2, i64** %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_f3c:
  %0 = call i64** @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE(i64* %result), !insn.addr !310
  %1 = ptrtoint i64** %0 to i64, !insn.addr !310
  %2 = inttoptr i64 %arg4 to i64*, !insn.addr !311
  %3 = call i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %2), !insn.addr !311
  %4 = ptrtoint i64* %3 to i64, !insn.addr !311
  %5 = bitcast i64** %arg3 to i64*, !insn.addr !312
  %6 = call i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %5), !insn.addr !312
  %7 = ptrtoint i64** %6 to i64, !insn.addr !312
  %8 = inttoptr i64 %arg2 to i64*, !insn.addr !313
  %9 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %8), !insn.addr !313
  %10 = ptrtoint i64* %9 to i64, !insn.addr !313
  %11 = load i64, i64* %3, align 8, !insn.addr !314
  %12 = add i64 %4, 8, !insn.addr !315
  %13 = inttoptr i64 %12 to i64*, !insn.addr !315
  %14 = load i64, i64* %13, align 8, !insn.addr !315
  %15 = load i64, i64* %9, align 8, !insn.addr !316
  %16 = add i64 %10, 8, !insn.addr !317
  %17 = inttoptr i64 %16 to i64*, !insn.addr !317
  %18 = load i64, i64* %17, align 8, !insn.addr !317
  %19 = call i64 @_ZZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_ENKUlNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS5_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEE_clES3_S9_SC_(i64 %1, i64 %15, i64 %18, i64 %7, i64 %11, i64 %14), !insn.addr !318
  %20 = urem i64 %19, 2
  %21 = icmp ne i64 %20, 0, !insn.addr !319
  ret i1 %21, !insn.addr !319

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE, { 2, 1, 0 }
  uselistorder i64* (i64*)* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE, { 2, 1, 0 }
  uselistorder i64** (i64*)* @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE, { 1, 0 }
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorIRKSF_EEvRSt9_Any_dataOT_(i64* %arg1, i64** %arg2) local_unnamed_addr {
dec_label_pc_fc2:
  %0 = bitcast i64** %arg2 to i64*
  %1 = call i64** @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE(i64* %0), !insn.addr !320
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createIRKSF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64** %1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !321
  ret void, !insn.addr !322
}

define i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_destroyERSt9_Any_dataSt17integral_constantIbLb1EE(i64* %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_ff3:
  %0 = call i64* @_ZNSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %arg1), !insn.addr !323
  %1 = ptrtoint i64* %0 to i64, !insn.addr !323
  ret i64 %1, !insn.addr !324
}

define i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EppEv(i64* %result) local_unnamed_addr {
dec_label_pc_100e:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* %result), !insn.addr !325
  ret i64 %0, !insn.addr !326
}

define i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_102c:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !327
  ret i64** %0, !insn.addr !327
}

define i64 @_ZNSt17_Optional_payloadIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb0ELb0EECI1St22_Optional_payload_baseISA_EIJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_103a:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC2IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2), !insn.addr !328
  ret i64 %0, !insn.addr !329
}

define i64 @_ZNSt14_Optional_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb1EEC2IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_1060:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !330
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !330
  %2 = ptrtoint i64** %1 to i64, !insn.addr !330
  %3 = call i64 @_ZNSt17_Optional_payloadIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb0ELb0EECI1St22_Optional_payload_baseISA_EIJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !331
  ret i64 %3, !insn.addr !332
}

define i64** @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_1093:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !333
  ret i64** %0, !insn.addr !333
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createIRKSF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64** %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_10a1:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %arg1), !insn.addr !334
  %1 = inttoptr i64 %0 to i64*, !insn.addr !335
  %2 = call i64 @_ZnwmPv(i64 1, i64* %1), !insn.addr !335
  %3 = bitcast i64** %arg2 to i64*
  %4 = call i64** @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE(i64* %3), !insn.addr !336
  ret void, !insn.addr !337

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE, { 1, 0 }
}

define i64* @_ZNSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %result) local_unnamed_addr {
dec_label_pc_10da:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !338
  %1 = inttoptr i64 %0 to i64*, !insn.addr !339
  ret i64* %1, !insn.addr !339
}

define i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC2IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_10f4:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !340
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !340
  %2 = ptrtoint i64** %1 to i64, !insn.addr !340
  %3 = call i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_E8_StorageISA_Lb1EEC1IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !341
  %4 = add i64 %arg1, 1, !insn.addr !342
  %5 = inttoptr i64 %4 to i8*, !insn.addr !342
  store i8 1, i8* %5, align 1, !insn.addr !342
  ret i64 %arg1, !insn.addr !343

; uselistorder directives
  uselistorder i64 %arg1, { 1, 0, 2 }
}

define i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_E8_StorageISA_Lb1EEC1IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_1130:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !344
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !344
  %2 = ptrtoint i64** %1 to i64, !insn.addr !344
  ret i64 %2, !insn.addr !345

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE, { 3, 2, 1, 0 }
}

define i64 @_ZSt23__is_constant_evaluatedv() local_unnamed_addr {
dec_label_pc_114f:
  ret i64 0, !insn.addr !346
}

define i64 @_ZNSt11char_traitsIcE6lengthEPKc(i8* %arg1) local_unnamed_addr {
dec_label_pc_115e:
  %storemerge.reg2mem = alloca i64, !insn.addr !347
  %0 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !348
  %1 = trunc i64 %0 to i8, !insn.addr !349
  %2 = icmp eq i8 %1, 0, !insn.addr !349
  br i1 %2, label %dec_label_pc_1185, label %dec_label_pc_1177, !insn.addr !350

dec_label_pc_1177:                                ; preds = %dec_label_pc_115e
  %3 = call i64 @_ZN9__gnu_cxx11char_traitsIcE6lengthEPKc(i8* %arg1), !insn.addr !351
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !352
  br label %dec_label_pc_1192, !insn.addr !352

dec_label_pc_1185:                                ; preds = %dec_label_pc_115e
  %4 = ptrtoint i8* %arg1 to i64, !insn.addr !353
  %5 = call i64 @strlen(i64 %4), !insn.addr !354
  store i64 %5, i64* %storemerge.reg2mem, !insn.addr !355
  br label %dec_label_pc_1192, !insn.addr !355

dec_label_pc_1192:                                ; preds = %dec_label_pc_1185, %dec_label_pc_1177
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !356

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZnwmPv(i64 %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_1194:
  %0 = ptrtoint i64* %arg2 to i64
  ret i64 %0, !insn.addr !357
}

define i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result) local_unnamed_addr {
dec_label_pc_19c0:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !358
}

define i64 @_ZNKSt9_Any_data9_M_accessEv(i64* %result) local_unnamed_addr {
dec_label_pc_19d2:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !359
}

define i64 @_ZNSt14_Function_baseD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_19e4:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !360
  %2 = inttoptr i64 %1 to i64*, !insn.addr !360
  %3 = load i64, i64* %2, align 8, !insn.addr !360
  %4 = icmp eq i64 %3, 0, !insn.addr !361
  %spec.select = select i1 %4, i64 0, i64 %0
  ret i64 %spec.select, !insn.addr !362
}

define i64 @_ZNKSt14_Function_base8_M_emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_1a22:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !363
  %2 = inttoptr i64 %1 to i64*, !insn.addr !363
  %3 = load i64, i64* %2, align 8, !insn.addr !363
  %4 = icmp eq i64 %3, 0, !insn.addr !364
  %5 = zext i1 %4 to i64, !insn.addr !365
  %6 = and i64 %3, -256, !insn.addr !365
  %7 = or i64 %6, %5, !insn.addr !365
  ret i64 %7, !insn.addr !366

; uselistorder directives
  uselistorder i64 %3, { 1, 0 }
}

define i64* @_ZSt3minImERKT_S2_S2_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_1a3e:
  %0 = icmp ult i64* %arg2, %arg1, !insn.addr !367
  %1 = icmp eq i1 %0, false, !insn.addr !368
  %storemerge.v = select i1 %1, i64* %arg1, i64* %arg2
  ret i64* %storemerge.v, !insn.addr !369
}

define i64 @_ZN4llvm14DebugEpochBase14incrementEpochEv(i64* %result) local_unnamed_addr {
dec_label_pc_1a6e:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !370
}

define i64 @_ZN4llvm14DebugEpochBase10HandleBaseC1EPKS0_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_1a7e:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !371
}

define i64 @_ZN4llvm21PointerLikeTypeTraitsIPvE16getAsVoidPointerES1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_1a91:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !372
}

define i64 @_ZN4llvm9StringRef13compareMemoryEPKcS2_m(i8* %arg1, i8* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_1aa3:
  %storemerge.reg2mem = alloca i64, !insn.addr !373
  %0 = icmp eq i64 %arg3, 0, !insn.addr !374
  %1 = icmp eq i1 %0, false, !insn.addr !375
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !375
  br i1 %1, label %dec_label_pc_1ac9, label %dec_label_pc_1ae1, !insn.addr !375

dec_label_pc_1ac9:                                ; preds = %dec_label_pc_1aa3
  %2 = ptrtoint i8* %arg2 to i64, !insn.addr !376
  %3 = ptrtoint i8* %arg1 to i64, !insn.addr !377
  %4 = call i64 @memcmp(i64 %3, i64 %2, i64 %arg3), !insn.addr !378
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !379
  br label %dec_label_pc_1ae1, !insn.addr !379

dec_label_pc_1ae1:                                ; preds = %dec_label_pc_1aa3, %dec_label_pc_1ac9
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !380

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_1ae1, { 1, 0 }
}

define i64 @_ZN4llvm9StringRefC1EPKc(i64* %result, i8* %arg2) local_unnamed_addr {
dec_label_pc_1ae4:
  %storemerge.reg2mem = alloca i64, !insn.addr !381
  %0 = ptrtoint i8* %arg2 to i64, !insn.addr !382
  store i64 %0, i64* %result, align 8, !insn.addr !383
  %1 = icmp eq i8* %arg2, null, !insn.addr !384
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !385
  br i1 %1, label %dec_label_pc_1b1d, label %dec_label_pc_1b0a, !insn.addr !385

dec_label_pc_1b0a:                                ; preds = %dec_label_pc_1ae4
  %2 = call i64 @_ZNSt11char_traitsIcE6lengthEPKc(i8* nonnull %arg2), !insn.addr !386
  store i64 %2, i64* %storemerge.reg2mem, !insn.addr !387
  br label %dec_label_pc_1b1d, !insn.addr !387

dec_label_pc_1b1d:                                ; preds = %dec_label_pc_1ae4, %dec_label_pc_1b0a
  %3 = ptrtoint i64* %result to i64
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %4 = add i64 %3, 8, !insn.addr !388
  %5 = inttoptr i64 %4 to i64*, !insn.addr !388
  store i64 %storemerge.reload, i64* %5, align 8, !insn.addr !388
  ret i64 %storemerge.reload, !insn.addr !389

; uselistorder directives
  uselistorder i64 %storemerge.reload, { 1, 0 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %result, { 1, 0 }
  uselistorder label %dec_label_pc_1b1d, { 1, 0 }
}

define i64 @_ZN4llvm9StringRefC1EPKcm(i64* %result, i8* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_1b28:
  %0 = ptrtoint i8* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !390
  %2 = add i64 %1, 8, !insn.addr !391
  %3 = inttoptr i64 %2 to i64*, !insn.addr !391
  store i64 %arg3, i64* %3, align 8, !insn.addr !391
  ret i64 %1, !insn.addr !392

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef4dataEv(i64* %result) local_unnamed_addr {
dec_label_pc_1b56:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !393
}

define i64 @_ZNK4llvm9StringRef5emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_1b6c:
  %0 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !394
  %1 = icmp eq i64 %0, 0, !insn.addr !395
  %2 = zext i1 %1 to i64, !insn.addr !396
  %3 = and i64 %0, -256, !insn.addr !396
  %4 = or i64 %3, %2, !insn.addr !396
  ret i64 %4, !insn.addr !397

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result) local_unnamed_addr {
dec_label_pc_1b90:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !398
  %2 = inttoptr i64 %1 to i64*, !insn.addr !398
  %3 = load i64, i64* %2, align 8, !insn.addr !398
  ret i64 %3, !insn.addr !399
}

define i64 @_ZNK4llvm9StringRef11starts_withES0_(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_1ba6:
  %storemerge.reg2mem = alloca i64, !insn.addr !400
  %0 = ptrtoint i64* %result to i64
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-56, align 8, !insn.addr !401
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %this), !insn.addr !402
  %2 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !403
  %3 = icmp ult i64 %1, %2, !insn.addr !404
  br i1 %3, label %dec_label_pc_1c30, label %dec_label_pc_1bed, !insn.addr !405

dec_label_pc_1bed:                                ; preds = %dec_label_pc_1ba6
  %4 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !406
  %5 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !407
  %6 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %this), !insn.addr !408
  %7 = inttoptr i64 %6 to i8*, !insn.addr !409
  %8 = inttoptr i64 %5 to i8*, !insn.addr !409
  %9 = call i64 @_ZN4llvm9StringRef13compareMemoryEPKcS2_m(i8* %7, i8* %8, i64 %4), !insn.addr !409
  %10 = trunc i64 %9 to i32, !insn.addr !410
  %11 = icmp eq i32 %10, 0, !insn.addr !410
  %12 = icmp eq i1 %11, false, !insn.addr !411
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !411
  br i1 %12, label %dec_label_pc_1c30, label %dec_label_pc_1c35, !insn.addr !411

dec_label_pc_1c30:                                ; preds = %dec_label_pc_1bed, %dec_label_pc_1ba6
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !412
  br label %dec_label_pc_1c35, !insn.addr !412

dec_label_pc_1c35:                                ; preds = %dec_label_pc_1bed, %dec_label_pc_1c30
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !413

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_1c35, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef6substrEmm(i64* %result, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_1c3e:
  %rax.0.reg2mem = alloca i64, !insn.addr !414
  %stack_var_-64 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-96 = alloca i64, align 8
  %stack_var_-88 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-88, align 8, !insn.addr !415
  store i64 %arg3, i64* %stack_var_-96, align 8, !insn.addr !416
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !417
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !418
  store i64 %1, i64* %stack_var_-56, align 8, !insn.addr !419
  %2 = call i64* @_ZSt3minImERKT_S2_S2_(i64* nonnull %stack_var_-88, i64* nonnull %stack_var_-56), !insn.addr !420
  %3 = load i64, i64* %2, align 8, !insn.addr !421
  store i64 %3, i64* %stack_var_-88, align 8, !insn.addr !422
  %4 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !423
  %5 = load i64, i64* %stack_var_-88, align 8, !insn.addr !424
  %6 = sub i64 %4, %5, !insn.addr !425
  store i64 %6, i64* %stack_var_-64, align 8, !insn.addr !426
  %7 = call i64* @_ZSt3minImERKT_S2_S2_(i64* nonnull %stack_var_-96, i64* nonnull %stack_var_-64), !insn.addr !427
  %8 = load i64, i64* %7, align 8, !insn.addr !428
  %9 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %result), !insn.addr !429
  %10 = load i64, i64* %stack_var_-88, align 8, !insn.addr !430
  %11 = add i64 %10, %9, !insn.addr !431
  %12 = inttoptr i64 %11 to i8*, !insn.addr !432
  %13 = call i64 @_ZN4llvm9StringRefC1EPKcm(i64* nonnull %stack_var_-56, i8* %12, i64 %8), !insn.addr !432
  %14 = load i64, i64* %stack_var_-56, align 8, !insn.addr !433
  %15 = call i64 @__readfsqword(i64 40), !insn.addr !434
  %16 = icmp eq i64 %0, %15, !insn.addr !434
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !435
  br i1 %16, label %dec_label_pc_1d02, label %dec_label_pc_1cfd, !insn.addr !435

dec_label_pc_1cfd:                                ; preds = %dec_label_pc_1c3e
  %17 = call i64 @__stack_chk_fail(), !insn.addr !436
  store i64 %17, i64* %rax.0.reg2mem, !insn.addr !436
  br label %dec_label_pc_1d02, !insn.addr !436

dec_label_pc_1d02:                                ; preds = %dec_label_pc_1cfd, %dec_label_pc_1c3e
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !437

; uselistorder directives
  uselistorder i64* %stack_var_-88, { 1, 2, 3, 0, 4 }
  uselistorder i64* %stack_var_-56, { 2, 0, 1, 3 }
}

define i64 @_ZN4llvm9StringRef13consume_frontES0_(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_1d08:
  %storemerge.reg2mem = alloca i64, !insn.addr !438
  %0 = ptrtoint i64* %result to i64
  %stack_var_-40 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-40, align 8, !insn.addr !439
  %1 = call i64 @_ZNK4llvm9StringRef11starts_withES0_(i64* %this, i64* %result, i64 %arg3), !insn.addr !440
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !441
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !442
  br i1 %3, label %dec_label_pc_1d51, label %dec_label_pc_1d86, !insn.addr !442

dec_label_pc_1d51:                                ; preds = %dec_label_pc_1d08
  %4 = ptrtoint i64* %this to i64
  %5 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-40), !insn.addr !443
  %6 = call i64 @_ZNK4llvm9StringRef6substrEmm(i64* %this, i64 %5, i64 -1), !insn.addr !444
  store i64 %6, i64* %this, align 8, !insn.addr !445
  %7 = add i64 %4, 8, !insn.addr !446
  %8 = inttoptr i64 %7 to i64*, !insn.addr !446
  store i64 -1, i64* %8, align 8, !insn.addr !446
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !447
  br label %dec_label_pc_1d86, !insn.addr !447

dec_label_pc_1d86:                                ; preds = %dec_label_pc_1d08, %dec_label_pc_1d51
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !448

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %this, { 0, 1, 3, 2 }
  uselistorder label %dec_label_pc_1d86, { 1, 0 }
}

define i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %this, i64* %result, i64 %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_1d88:
  %rax.0.reg2mem = alloca i64, !insn.addr !449
  %0 = ptrtoint i64* %this to i64
  %stack_var_-40 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-40, align 8, !insn.addr !450
  store i64 %arg3, i64* %stack_var_-56, align 8, !insn.addr !451
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-40), !insn.addr !452
  %2 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !453
  %3 = icmp eq i64 %1, %2, !insn.addr !454
  %4 = icmp eq i1 %3, false, !insn.addr !455
  %5 = icmp eq i1 %4, false, !insn.addr !456
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !457
  br i1 %5, label %dec_label_pc_1de2, label %dec_label_pc_1e36, !insn.addr !457

dec_label_pc_1de2:                                ; preds = %dec_label_pc_1d88
  %6 = call i64 @_ZNK4llvm9StringRef5emptyEv(i64* nonnull %stack_var_-40), !insn.addr !458
  %7 = trunc i64 %6 to i8, !insn.addr !459
  %8 = icmp eq i8 %7, 0, !insn.addr !459
  store i64 1, i64* %rax.0.reg2mem, !insn.addr !460
  br i1 %8, label %dec_label_pc_1df9, label %dec_label_pc_1e36, !insn.addr !460

dec_label_pc_1df9:                                ; preds = %dec_label_pc_1de2
  %9 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-40), !insn.addr !461
  %10 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !462
  %11 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-40), !insn.addr !463
  %12 = call i64 @memcmp(i64 %11, i64 %10, i64 %9), !insn.addr !464
  %13 = trunc i64 %12 to i32, !insn.addr !465
  %14 = icmp eq i32 %13, 0, !insn.addr !465
  %15 = zext i1 %14 to i64, !insn.addr !466
  %16 = and i64 %12, -256, !insn.addr !466
  %17 = or i64 %16, %15, !insn.addr !466
  store i64 %17, i64* %rax.0.reg2mem, !insn.addr !466
  br label %dec_label_pc_1e36, !insn.addr !466

dec_label_pc_1e36:                                ; preds = %dec_label_pc_1de2, %dec_label_pc_1d88, %dec_label_pc_1df9
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !467

; uselistorder directives
  uselistorder i64 %12, { 1, 0 }
  uselistorder i64* %rax.0.reg2mem, { 0, 3, 1, 2 }
  uselistorder label %dec_label_pc_1e36, { 2, 0, 1 }
}

define i64 @_ZNK4llvm9DbgRecord13getRecordKindEv(i64* %result) local_unnamed_addr {
dec_label_pc_1e40:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !468
  %2 = inttoptr i64 %1 to i8*, !insn.addr !468
  %3 = load i8, i8* %2, align 1, !insn.addr !468
  %4 = zext i8 %3 to i64, !insn.addr !468
  ret i64 %4, !insn.addr !469
}

define i64 @_ZN4llvm17DbgVariableRecord7classofEPKNS_9DbgRecordE(i64* %arg1) local_unnamed_addr {
dec_label_pc_1e56:
  %0 = call i64 @_ZNK4llvm9DbgRecord13getRecordKindEv(i64* %arg1), !insn.addr !470
  %1 = trunc i64 %0 to i8, !insn.addr !471
  %2 = icmp eq i8 %1, 0, !insn.addr !471
  %3 = zext i1 %2 to i64, !insn.addr !472
  %4 = and i64 %0, -256, !insn.addr !472
  %5 = or i64 %4, %3, !insn.addr !472
  ret i64 %5, !insn.addr !473

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm11raw_ostreamlsENS_9StringRefE(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_1e7a:
  %storemerge.reg2mem = alloca i64, !insn.addr !474
  %0 = ptrtoint i64* %result to i64
  %1 = ptrtoint i64* %this to i64
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-56, align 8, !insn.addr !475
  %2 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !476
  %3 = add i64 %1, 24, !insn.addr !477
  %4 = inttoptr i64 %3 to i64*, !insn.addr !477
  %5 = load i64, i64* %4, align 8, !insn.addr !477
  %6 = add i64 %1, 32, !insn.addr !478
  %7 = inttoptr i64 %6 to i64*, !insn.addr !478
  %8 = load i64, i64* %7, align 8, !insn.addr !478
  %9 = sub i64 %5, %8, !insn.addr !479
  %10 = icmp ult i64 %9, %2, !insn.addr !480
  %11 = icmp eq i1 %10, false, !insn.addr !481
  br i1 %11, label %dec_label_pc_1eee, label %dec_label_pc_1eca, !insn.addr !481

dec_label_pc_1eca:                                ; preds = %dec_label_pc_1e7a
  %12 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !482
  %13 = inttoptr i64 %12 to i8*, !insn.addr !483
  %14 = call i64 @_ZN4llvm11raw_ostream5writeEPKcm(i64* %this, i8* %13, i64 %2), !insn.addr !483
  store i64 %14, i64* %storemerge.reg2mem, !insn.addr !484
  br label %dec_label_pc_1f36, !insn.addr !484

dec_label_pc_1eee:                                ; preds = %dec_label_pc_1e7a
  %15 = icmp eq i64 %2, 0, !insn.addr !485
  store i64 %1, i64* %storemerge.reg2mem, !insn.addr !486
  br i1 %15, label %dec_label_pc_1f36, label %dec_label_pc_1ef5, !insn.addr !486

dec_label_pc_1ef5:                                ; preds = %dec_label_pc_1eee
  %16 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !487
  %17 = load i64, i64* %7, align 8, !insn.addr !488
  %18 = call i64 @memcpy(i64 %17, i64 %16, i64 %2), !insn.addr !489
  %19 = load i64, i64* %7, align 8, !insn.addr !490
  %20 = add i64 %19, %2, !insn.addr !491
  store i64 %20, i64* %7, align 8, !insn.addr !492
  store i64 %1, i64* %storemerge.reg2mem, !insn.addr !492
  br label %dec_label_pc_1f36, !insn.addr !492

dec_label_pc_1f36:                                ; preds = %dec_label_pc_1eee, %dec_label_pc_1ef5, %dec_label_pc_1eca
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !493

; uselistorder directives
  uselistorder i64* %7, { 0, 2, 1, 3 }
  uselistorder i64 %2, { 0, 2, 3, 1, 4 }
  uselistorder i64 %1, { 1, 0, 2, 3 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1, 3 }
  uselistorder i64 (i64*)* @_ZNK4llvm9StringRef4dataEv, { 6, 5, 1, 0, 4, 3, 2 }
  uselistorder i64 (i64*)* @_ZNK4llvm9StringRef4sizeEv, { 10, 2, 1, 0, 9, 8, 7, 6, 5, 4, 3 }
  uselistorder label %dec_label_pc_1f36, { 1, 0, 2 }
}

define i64 @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj(i64* %result, i64** %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_1f38:
  %rax.0.reg2mem = alloca i64, !insn.addr !494
  %0 = ptrtoint i64** %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !495
  %2 = add i64 %1, 8, !insn.addr !496
  %3 = inttoptr i64 %2 to i32*, !insn.addr !496
  store i32 %arg3, i32* %3, align 4, !insn.addr !496
  %4 = add i64 %1, 12, !insn.addr !497
  %5 = inttoptr i64 %4 to i32*, !insn.addr !497
  store i32 0, i32* %5, align 4, !insn.addr !497
  %6 = add i64 %1, 16, !insn.addr !498
  %7 = inttoptr i64 %6 to i32*, !insn.addr !498
  store i32 0, i32* %7, align 4, !insn.addr !498
  %8 = add i64 %1, 20, !insn.addr !499
  %9 = inttoptr i64 %8 to i8*, !insn.addr !499
  store i8 1, i8* %9, align 1, !insn.addr !499
  %10 = call i1 @_ZN4llvm14has_single_bitIjvEEbT_(i32 %arg3), !insn.addr !500
  %11 = sext i1 %10 to i64, !insn.addr !500
  %12 = icmp eq i1 %10, false, !insn.addr !501
  %13 = icmp eq i1 %12, false, !insn.addr !502
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !502
  br i1 %13, label %dec_label_pc_1fb8, label %dec_label_pc_1f90, !insn.addr !502

dec_label_pc_1f90:                                ; preds = %dec_label_pc_1f38
  %14 = call i64 @__assert_fail(i64 ptrtoint ([74 x i8]* @global_var_1448 to i64), i64 ptrtoint ([44 x i8]* @global_var_1418 to i64), i64 83, i64 ptrtoint ([75 x i8]* @global_var_13c8 to i64)), !insn.addr !503
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !503
  br label %dec_label_pc_1fb8, !insn.addr !503

dec_label_pc_1fb8:                                ; preds = %dec_label_pc_1f90, %dec_label_pc_1f38
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !504
}

define i64 @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv() local_unnamed_addr {
dec_label_pc_1fbb:
  ret i64 -2, !insn.addr !505
}

define i64 @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv() local_unnamed_addr {
dec_label_pc_1fcc:
  ret i64 -1, !insn.addr !506

; uselistorder directives
  uselistorder i64 -1, { 0, 2, 1 }
}

define i64 @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv(i64* %result) local_unnamed_addr {
dec_label_pc_1fde:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm19SmallPtrSetImplBase7isSmallEv(i64* %result), !insn.addr !507
  %2 = trunc i64 %1 to i8, !insn.addr !508
  %3 = icmp eq i8 %2, 0, !insn.addr !508
  %.pn.in.in.in.in.v = select i1 %3, i64 8, i64 12
  %.pn.in.in.in.in = add i64 %.pn.in.in.in.in.v, %0
  %.pn.in.in.in = inttoptr i64 %.pn.in.in.in.in to i32*
  %.pn.in.in = load i32, i32* %.pn.in.in.in, align 4
  %.pn.in = zext i32 %.pn.in.in to i64
  %.pn = mul i64 %.pn.in, 8
  %storemerge = add i64 %.pn, %0
  ret i64 %storemerge, !insn.addr !509
}

define i64 @_ZN4llvm19SmallPtrSetImplBase10insert_impEPKv(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2030:
  %rax.1.reg2mem = alloca i64, !insn.addr !510
  %rax.0.reg2mem = alloca i64, !insn.addr !510
  %.reg2mem1 = alloca i32, !insn.addr !510
  %.reg2mem = alloca i64, !insn.addr !510
  %stack_var_-40 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-81 = alloca i8, align 1
  %stack_var_-80 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !511
  %1 = call i64 @_ZNK4llvm19SmallPtrSetImplBase7isSmallEv(i64* %result), !insn.addr !512
  %2 = trunc i64 %1 to i8, !insn.addr !513
  %3 = icmp eq i8 %2, 0, !insn.addr !513
  br i1 %3, label %dec_label_pc_219d, label %dec_label_pc_2067, !insn.addr !514

dec_label_pc_2067:                                ; preds = %dec_label_pc_2030
  %4 = ptrtoint i64* %arg2 to i64
  %5 = ptrtoint i64* %result to i64
  store i64 %5, i64* %stack_var_-80, align 8, !insn.addr !515
  %6 = add i64 %5, 12, !insn.addr !516
  %7 = inttoptr i64 %6 to i32*, !insn.addr !516
  %8 = load i32, i32* %7, align 4, !insn.addr !516
  %9 = zext i32 %8 to i64, !insn.addr !517
  %10 = mul i64 %9, 8, !insn.addr !518
  %11 = add i64 %10, %5, !insn.addr !519
  %12 = icmp eq i32 %8, 0, !insn.addr !520
  %13 = icmp eq i1 %12, false, !insn.addr !521
  store i64 %5, i64* %.reg2mem, !insn.addr !521
  store i32 %8, i32* %.reg2mem1, !insn.addr !521
  br i1 %13, label %dec_label_pc_208f, label %dec_label_pc_20f9, !insn.addr !521

dec_label_pc_208f:                                ; preds = %dec_label_pc_2067, %dec_label_pc_20e3
  %.reload = load i64, i64* %.reg2mem
  %14 = inttoptr i64 %.reload to i64*, !insn.addr !522
  %15 = load i64, i64* %14, align 8, !insn.addr !522
  %16 = icmp eq i64 %15, %4, !insn.addr !523
  %17 = icmp eq i1 %16, false, !insn.addr !524
  br i1 %17, label %dec_label_pc_20e3, label %dec_label_pc_20a4, !insn.addr !524

dec_label_pc_20a4:                                ; preds = %dec_label_pc_208f
  store i8 0, i8* %stack_var_-81, align 1, !insn.addr !525
  %18 = bitcast i64* %stack_var_-80 to i64****, !insn.addr !526
  %19 = bitcast i8* %stack_var_-81 to i1*, !insn.addr !526
  %20 = call i64 @_ZSt9make_pairIRPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS5_INS6_IT0_E4typeEE6__typeEEOS7_OSC_(i64**** nonnull %18, i1* nonnull %19), !insn.addr !526
  store i64 %20, i64* %stack_var_-56, align 8, !insn.addr !527
  %21 = call i64 @_ZNSt4pairIPKPKvbEC1IPS1_bLb1EEEOS_IT_T0_E(i64* nonnull %stack_var_-40, i64* nonnull %stack_var_-56), !insn.addr !528
  %22 = load i64, i64* %stack_var_-40, align 8, !insn.addr !529
  store i64 %22, i64* %rax.0.reg2mem, !insn.addr !530
  br label %dec_label_pc_21b1, !insn.addr !530

dec_label_pc_20e3:                                ; preds = %dec_label_pc_208f
  %23 = add i64 %.reload, 8, !insn.addr !531
  store i64 %23, i64* %stack_var_-80, align 8, !insn.addr !532
  %24 = icmp eq i64 %11, %23, !insn.addr !520
  %25 = icmp eq i1 %24, false, !insn.addr !521
  store i64 %23, i64* %.reg2mem, !insn.addr !521
  br i1 %25, label %dec_label_pc_208f, label %dec_label_pc_20ef.dec_label_pc_20f9_crit_edge, !insn.addr !521

dec_label_pc_20ef.dec_label_pc_20f9_crit_edge:    ; preds = %dec_label_pc_20e3
  %.pre = load i32, i32* %7, align 4
  store i32 %.pre, i32* %.reg2mem1
  br label %dec_label_pc_20f9

dec_label_pc_20f9:                                ; preds = %dec_label_pc_20ef.dec_label_pc_20f9_crit_edge, %dec_label_pc_2067
  %.reload2 = load i32, i32* %.reg2mem1, !insn.addr !533
  %26 = add i64 %5, 8, !insn.addr !534
  %27 = inttoptr i64 %26 to i32*, !insn.addr !534
  %28 = load i32, i32* %27, align 4, !insn.addr !534
  %29 = icmp ult i32 %.reload2, %28, !insn.addr !535
  %30 = icmp eq i1 %29, false, !insn.addr !536
  br i1 %30, label %dec_label_pc_219d, label %dec_label_pc_210f, !insn.addr !536

dec_label_pc_210f:                                ; preds = %dec_label_pc_20f9
  %31 = add i32 %.reload2, 1, !insn.addr !537
  store i32 %31, i32* %7, align 4, !insn.addr !538
  %32 = zext i32 %.reload2 to i64, !insn.addr !539
  %33 = mul i64 %32, 8, !insn.addr !540
  %34 = add i64 %33, %5, !insn.addr !541
  %35 = inttoptr i64 %34 to i64*, !insn.addr !542
  store i64 %4, i64* %35, align 8, !insn.addr !542
  %36 = call i64 @_ZN4llvm14DebugEpochBase14incrementEpochEv(i64* %result), !insn.addr !543
  store i8 1, i8* %stack_var_-81, align 1, !insn.addr !544
  %37 = load i32, i32* %7, align 4, !insn.addr !545
  %38 = add i32 %37, -1, !insn.addr !546
  %39 = zext i32 %38 to i64, !insn.addr !547
  %40 = mul i64 %39, 8, !insn.addr !548
  %41 = add i64 %40, %5, !insn.addr !549
  store i64 %41, i64* %stack_var_-80, align 8, !insn.addr !550
  %42 = bitcast i64* %stack_var_-80 to i64***, !insn.addr !551
  %43 = bitcast i8* %stack_var_-81 to i1*, !insn.addr !551
  %44 = call i64 @_ZSt9make_pairIPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS4_INS5_IT0_E4typeEE6__typeEEOS6_OSB_(i64*** nonnull %42, i1* nonnull %43), !insn.addr !551
  store i64 %44, i64* %stack_var_-56, align 8, !insn.addr !552
  %45 = call i64 @_ZNSt4pairIPKPKvbEC1IPS1_bLb1EEEOS_IT_T0_E(i64* nonnull %stack_var_-40, i64* nonnull %stack_var_-56), !insn.addr !553
  %46 = load i64, i64* %stack_var_-40, align 8, !insn.addr !554
  store i64 %46, i64* %rax.0.reg2mem, !insn.addr !555
  br label %dec_label_pc_21b1, !insn.addr !555

dec_label_pc_219d:                                ; preds = %dec_label_pc_20f9, %dec_label_pc_2030
  %47 = call i64 @_ZN4llvm19SmallPtrSetImplBase14insert_imp_bigEPKv(i64* %result, i64* %arg2), !insn.addr !556
  store i64 %47, i64* %rax.0.reg2mem, !insn.addr !557
  br label %dec_label_pc_21b1, !insn.addr !557

dec_label_pc_21b1:                                ; preds = %dec_label_pc_219d, %dec_label_pc_20a4, %dec_label_pc_210f
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %48 = call i64 @__readfsqword(i64 40), !insn.addr !558
  %49 = icmp eq i64 %0, %48, !insn.addr !558
  store i64 %rax.0.reload, i64* %rax.1.reg2mem, !insn.addr !559
  br i1 %49, label %dec_label_pc_21c5, label %dec_label_pc_21c0, !insn.addr !559

dec_label_pc_21c0:                                ; preds = %dec_label_pc_21b1
  %50 = call i64 @__stack_chk_fail(), !insn.addr !560
  store i64 %50, i64* %rax.1.reg2mem, !insn.addr !560
  br label %dec_label_pc_21c5, !insn.addr !560

dec_label_pc_21c5:                                ; preds = %dec_label_pc_21c0, %dec_label_pc_21b1
  %rax.1.reload = load i64, i64* %rax.1.reg2mem
  ret i64 %rax.1.reload, !insn.addr !561

; uselistorder directives
  uselistorder i32 %.reload2, { 1, 0, 2 }
  uselistorder i32* %7, { 1, 2, 0, 3 }
  uselistorder i64 %5, { 1, 2, 4, 0, 3, 5, 6 }
  uselistorder i64* %stack_var_-80, { 0, 2, 3, 1, 4 }
  uselistorder i8* %stack_var_-81, { 0, 2, 1, 3 }
  uselistorder i64* %stack_var_-56, { 0, 2, 1, 3 }
  uselistorder i64* %stack_var_-40, { 2, 0, 3, 1 }
  uselistorder i64* %.reg2mem, { 2, 0, 1 }
  uselistorder i32* %.reg2mem1, { 0, 2, 1 }
  uselistorder i64* %rax.0.reg2mem, { 0, 3, 1, 2 }
  uselistorder i64 12, { 1, 0, 2 }
  uselistorder i64* %result, { 0, 1, 3, 2 }
  uselistorder label %dec_label_pc_21b1, { 0, 2, 1 }
  uselistorder label %dec_label_pc_208f, { 1, 0 }
}

define i64 @_ZNK4llvm19SmallPtrSetImplBase7isSmallEv(i64* %result) local_unnamed_addr {
dec_label_pc_21c8:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 20, !insn.addr !562
  %2 = inttoptr i64 %1 to i8*, !insn.addr !562
  %3 = load i8, i8* %2, align 1, !insn.addr !562
  %4 = zext i8 %3 to i64, !insn.addr !562
  ret i64 %4, !insn.addr !563
}

define i64 @_ZN4llvm23SmallPtrSetIteratorImplC1EPKPKvS4_(i64* %result, i64** %arg2, i64** %arg3) local_unnamed_addr {
dec_label_pc_21de:
  %storemerge.reg2mem = alloca i64, !insn.addr !564
  %0 = ptrtoint i64** %arg3 to i64
  %1 = ptrtoint i64** %arg2 to i64
  %2 = ptrtoint i64* %result to i64
  store i64 %1, i64* %result, align 8, !insn.addr !565
  %3 = add i64 %2, 8, !insn.addr !566
  %4 = inttoptr i64 %3 to i64*, !insn.addr !566
  store i64 %0, i64* %4, align 8, !insn.addr !566
  %5 = call i1 @_ZN4llvm20shouldReverseIterateIPvEEbv(), !insn.addr !567
  %6 = icmp eq i1 %5, false, !insn.addr !568
  br i1 %6, label %dec_label_pc_2224, label %dec_label_pc_2216, !insn.addr !569

dec_label_pc_2216:                                ; preds = %dec_label_pc_21de
  %7 = call i64 @_ZN4llvm23SmallPtrSetIteratorImpl17RetreatIfNotValidEv(i64* nonnull %result), !insn.addr !570
  store i64 %7, i64* %storemerge.reg2mem, !insn.addr !571
  br label %dec_label_pc_2230, !insn.addr !571

dec_label_pc_2224:                                ; preds = %dec_label_pc_21de
  %8 = call i64 @_ZN4llvm23SmallPtrSetIteratorImpl17AdvanceIfNotValidEv(i64* nonnull %result), !insn.addr !572
  store i64 %8, i64* %storemerge.reg2mem, !insn.addr !572
  br label %dec_label_pc_2230, !insn.addr !572

dec_label_pc_2230:                                ; preds = %dec_label_pc_2224, %dec_label_pc_2216
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !573

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %result, { 1, 0, 2, 3 }
}

define i64 @_ZN4llvm23SmallPtrSetIteratorImpl17AdvanceIfNotValidEv(i64* %result) local_unnamed_addr {
dec_label_pc_2232:
  %rdi.1.reg2mem = alloca i64, !insn.addr !574
  %.reg2mem = alloca i64, !insn.addr !574
  %rdi.0.reg2mem = alloca i64, !insn.addr !574
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !575
  %2 = inttoptr i64 %1 to i64*, !insn.addr !575
  %3 = load i64, i64* %2, align 8, !insn.addr !575
  %4 = icmp ult i64 %3, %0, !insn.addr !576
  %5 = icmp eq i1 %4, false, !insn.addr !577
  store i64 %3, i64* %.reg2mem, !insn.addr !577
  store i64 %0, i64* %rdi.1.reg2mem, !insn.addr !577
  br i1 %5, label %dec_label_pc_2291, label %dec_label_pc_2257, !insn.addr !577

dec_label_pc_2257:                                ; preds = %dec_label_pc_2232
  %6 = call i64 @__assert_fail(i64 ptrtoint ([14 x i8]* @global_var_14d0 to i64), i64 ptrtoint ([44 x i8]* @global_var_1418 to i64), i64 298, i64 ptrtoint ([56 x i8]* @global_var_1498 to i64)), !insn.addr !578
  store i64 ptrtoint ([14 x i8]* @global_var_14d0 to i64), i64* %rdi.0.reg2mem, !insn.addr !578
  br label %dec_label_pc_227f, !insn.addr !578

dec_label_pc_227f:                                ; preds = %dec_label_pc_22a5, %dec_label_pc_22b9, %dec_label_pc_2257
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %7 = add i64 %rdi.0.reload, 8, !insn.addr !579
  store i64 %7, i64* %result, align 8, !insn.addr !580
  %.pre = load i64, i64* %2, align 8
  store i64 %.pre, i64* %.reg2mem, !insn.addr !580
  store i64 %rdi.0.reload, i64* %rdi.1.reg2mem, !insn.addr !580
  br label %dec_label_pc_2291, !insn.addr !580

dec_label_pc_2291:                                ; preds = %dec_label_pc_227f, %dec_label_pc_2232
  %rdi.1.reload = load i64, i64* %rdi.1.reg2mem
  %.reload = load i64, i64* %.reg2mem, !insn.addr !581
  %8 = icmp eq i64 %rdi.1.reload, %.reload, !insn.addr !582
  br i1 %8, label %dec_label_pc_22dd, label %dec_label_pc_22a5, !insn.addr !583

dec_label_pc_22a5:                                ; preds = %dec_label_pc_2291
  %9 = call i64 @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv(), !insn.addr !584
  %10 = icmp eq i64 %rdi.1.reload, %9, !insn.addr !585
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !586
  br i1 %10, label %dec_label_pc_227f, label %dec_label_pc_22b9, !insn.addr !586

dec_label_pc_22b9:                                ; preds = %dec_label_pc_22a5
  %11 = call i64 @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv(), !insn.addr !587
  %12 = icmp eq i64 %rdi.1.reload, %11, !insn.addr !588
  %13 = icmp eq i1 %12, false, !insn.addr !589
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !589
  br i1 %13, label %dec_label_pc_22dd, label %dec_label_pc_227f, !insn.addr !589

dec_label_pc_22dd:                                ; preds = %dec_label_pc_22b9, %dec_label_pc_2291
  ret i64 0, !insn.addr !590

; uselistorder directives
  uselistorder i64 %rdi.1.reload, { 3, 2, 4, 0, 1 }
  uselistorder i64 %0, { 0, 2, 1 }
  uselistorder i64* %rdi.0.reg2mem, { 2, 1, 0, 3 }
  uselistorder label %dec_label_pc_227f, { 1, 0, 2 }
}

define i64 @_ZN4llvm23SmallPtrSetIteratorImpl17RetreatIfNotValidEv(i64* %result) local_unnamed_addr {
dec_label_pc_22e6:
  %rdi.1.reg2mem = alloca i64, !insn.addr !591
  %.reg2mem = alloca i64, !insn.addr !591
  %rdi.0.reg2mem = alloca i64, !insn.addr !591
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !592
  %2 = inttoptr i64 %1 to i64*, !insn.addr !592
  %3 = load i64, i64* %2, align 8, !insn.addr !592
  %4 = icmp ugt i64 %3, %0, !insn.addr !593
  %5 = icmp eq i1 %4, false, !insn.addr !594
  store i64 %3, i64* %.reg2mem, !insn.addr !594
  store i64 %0, i64* %rdi.1.reg2mem, !insn.addr !594
  br i1 %5, label %dec_label_pc_2345, label %dec_label_pc_230b, !insn.addr !594

dec_label_pc_230b:                                ; preds = %dec_label_pc_22e6
  %6 = call i64 @__assert_fail(i64 ptrtoint ([14 x i8]* @global_var_1518 to i64), i64 ptrtoint ([44 x i8]* @global_var_1418 to i64), i64 305, i64 ptrtoint ([56 x i8]* @global_var_14e0 to i64)), !insn.addr !595
  store i64 ptrtoint ([14 x i8]* @global_var_1518 to i64), i64* %rdi.0.reg2mem, !insn.addr !595
  br label %dec_label_pc_2333, !insn.addr !595

dec_label_pc_2333:                                ; preds = %dec_label_pc_2359, %dec_label_pc_2371, %dec_label_pc_230b
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %7 = add i64 %rdi.0.reload, -8, !insn.addr !596
  store i64 %7, i64* %result, align 8, !insn.addr !597
  %.pre = load i64, i64* %2, align 8
  store i64 %.pre, i64* %.reg2mem, !insn.addr !597
  store i64 %rdi.0.reload, i64* %rdi.1.reg2mem, !insn.addr !597
  br label %dec_label_pc_2345, !insn.addr !597

dec_label_pc_2345:                                ; preds = %dec_label_pc_2333, %dec_label_pc_22e6
  %rdi.1.reload = load i64, i64* %rdi.1.reg2mem
  %.reload = load i64, i64* %.reg2mem, !insn.addr !598
  %8 = icmp eq i64 %rdi.1.reload, %.reload, !insn.addr !599
  br i1 %8, label %dec_label_pc_2399, label %dec_label_pc_2359, !insn.addr !600

dec_label_pc_2359:                                ; preds = %dec_label_pc_2345
  %9 = add i64 %rdi.1.reload, -8, !insn.addr !601
  %10 = inttoptr i64 %9 to i64*, !insn.addr !602
  %11 = load i64, i64* %10, align 8, !insn.addr !602
  %12 = call i64 @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv(), !insn.addr !603
  %13 = icmp eq i64 %11, %12, !insn.addr !604
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !605
  br i1 %13, label %dec_label_pc_2333, label %dec_label_pc_2371, !insn.addr !605

dec_label_pc_2371:                                ; preds = %dec_label_pc_2359
  %14 = load i64, i64* %10, align 8, !insn.addr !606
  %15 = call i64 @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv(), !insn.addr !607
  %16 = icmp eq i64 %14, %15, !insn.addr !608
  %17 = icmp eq i1 %16, false, !insn.addr !609
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !609
  br i1 %17, label %dec_label_pc_2399, label %dec_label_pc_2333, !insn.addr !609

dec_label_pc_2399:                                ; preds = %dec_label_pc_2371, %dec_label_pc_2345
  ret i64 0, !insn.addr !610

; uselistorder directives
  uselistorder i64 %rdi.1.reload, { 2, 3, 0, 1 }
  uselistorder i64* %rdi.0.reg2mem, { 2, 1, 0, 3 }
  uselistorder i64 ()* @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv, { 1, 0 }
  uselistorder i64 ()* @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv, { 1, 0 }
  uselistorder label %dec_label_pc_2333, { 1, 0, 2 }
}

define i64 @_ZN4llvm17PreservedAnalysesC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_23a2:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm11SmallPtrSetIPvLj2EEC1Ev(i64* %result), !insn.addr !611
  %2 = add i64 %0, 40, !insn.addr !612
  %3 = inttoptr i64 %2 to i64*, !insn.addr !613
  %4 = call i64 @_ZN4llvm11SmallPtrSetIPNS_11AnalysisKeyELj2EEC1Ev(i64* %3), !insn.addr !613
  ret i64 %4, !insn.addr !614
}

define i64 @_ZN4llvm17PreservedAnalyses4noneEv(i64* %result) local_unnamed_addr {
dec_label_pc_23d1:
  %0 = alloca i128
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %result to i64
  %3 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !615
  %4 = bitcast i64* %rdi to i128*
  %5 = load i128, i128* %4, align 8, !insn.addr !616
  call void @__asm_movups(i128 %5, i128 %3), !insn.addr !616
  %6 = add i64 %2, 16, !insn.addr !617
  %7 = inttoptr i64 %6 to i128*, !insn.addr !617
  %8 = load i128, i128* %7, align 8, !insn.addr !617
  call void @__asm_movups(i128 %8, i128 %3), !insn.addr !617
  %9 = add i64 %2, 32, !insn.addr !618
  %10 = inttoptr i64 %9 to i128*, !insn.addr !618
  %11 = load i128, i128* %10, align 8, !insn.addr !618
  call void @__asm_movups(i128 %11, i128 %3), !insn.addr !618
  %12 = add i64 %2, 48, !insn.addr !619
  %13 = inttoptr i64 %12 to i128*, !insn.addr !619
  %14 = load i128, i128* %13, align 8, !insn.addr !619
  call void @__asm_movups(i128 %14, i128 %3), !insn.addr !619
  %15 = add i64 %2, ptrtoint (i128** @global_var_40 to i64), !insn.addr !620
  %16 = inttoptr i64 %15 to i128*, !insn.addr !620
  %17 = load i128, i128* %16, align 8, !insn.addr !620
  call void @__asm_movups(i128 %17, i128 %3), !insn.addr !620
  %18 = call i64 @_ZN4llvm17PreservedAnalysesC1Ev(i64* %result), !insn.addr !621
  ret i64 %2, !insn.addr !622

; uselistorder directives
  uselistorder i128 %3, { 4, 3, 2, 1, 0 }
  uselistorder i64 %2, { 0, 4, 3, 2, 1 }
  uselistorder i128 %1, { 1, 0 }
}

define i64 @_ZN4llvm17PreservedAnalyses3allEv(i64* %result) local_unnamed_addr {
dec_label_pc_240e:
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !623
  %1 = call i64 @_ZN4llvm17PreservedAnalysesC1Ev(i64* %result), !insn.addr !624
  %2 = load i64, i64* inttoptr (i64 9288 to i64*), align 8, !insn.addr !625
  %3 = inttoptr i64 %2 to i64*, !insn.addr !626
  %4 = call i64 @_ZN4llvm15SmallPtrSetImplIPvE6insertES1_(i64* nonnull %stack_var_-40, i64* %result, i64* %3), !insn.addr !626
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !627
  %6 = icmp eq i64 %0, %5, !insn.addr !627
  br i1 %6, label %dec_label_pc_2468, label %dec_label_pc_2463, !insn.addr !628

dec_label_pc_2463:                                ; preds = %dec_label_pc_240e
  %7 = call i64 @__stack_chk_fail(), !insn.addr !629
  br label %dec_label_pc_2468, !insn.addr !629

dec_label_pc_2468:                                ; preds = %dec_label_pc_2463, %dec_label_pc_240e
  %8 = ptrtoint i64* %result to i64
  ret i64 %8, !insn.addr !630

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm17PreservedAnalysesC1Ev, { 1, 0 }
  uselistorder i64* %result, { 2, 0, 1 }
}

define i64 @_ZN9__gnu_cxx11char_traitsIcE6lengthEPKc(i8* %arg1) local_unnamed_addr {
dec_label_pc_246e:
  %rax.0.reg2mem = alloca i64, !insn.addr !631
  %storemerge.reg2mem = alloca i64, !insn.addr !631
  %stack_var_-25 = alloca i8, align 1
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !632
  %1 = ptrtoint i8* %arg1 to i64, !insn.addr !633
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !634
  br label %dec_label_pc_249c, !insn.addr !634

dec_label_pc_249c:                                ; preds = %dec_label_pc_249c, %dec_label_pc_246e
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  store i8 0, i8* %stack_var_-25, align 1, !insn.addr !635
  %2 = add i64 %storemerge.reload, %1, !insn.addr !636
  %3 = inttoptr i64 %2 to i8*, !insn.addr !637
  %4 = call i64 @_ZN9__gnu_cxx11char_traitsIcE2eqERKcS3_(i8* %3, i8* nonnull %stack_var_-25), !insn.addr !637
  %5 = trunc i64 %4 to i8
  %6 = icmp eq i8 %5, 1, !insn.addr !638
  %7 = icmp eq i1 %6, false, !insn.addr !639
  %8 = add i64 %storemerge.reload, 1, !insn.addr !640
  store i64 %8, i64* %storemerge.reg2mem, !insn.addr !639
  br i1 %7, label %dec_label_pc_249c, label %dec_label_pc_24c1, !insn.addr !639

dec_label_pc_24c1:                                ; preds = %dec_label_pc_249c
  %9 = call i64 @__readfsqword(i64 40), !insn.addr !641
  %10 = icmp eq i64 %0, %9, !insn.addr !641
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !642
  br i1 %10, label %dec_label_pc_24d9, label %dec_label_pc_24d4, !insn.addr !642

dec_label_pc_24d4:                                ; preds = %dec_label_pc_24c1
  %11 = call i64 @__stack_chk_fail(), !insn.addr !643
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !643
  br label %dec_label_pc_24d9, !insn.addr !643

dec_label_pc_24d9:                                ; preds = %dec_label_pc_24d4, %dec_label_pc_24c1
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !644

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 2, 0, 1 }
}

define i64 @_ZN9__gnu_cxx11char_traitsIcE2eqERKcS3_(i8* %arg1, i8* %arg2) local_unnamed_addr {
dec_label_pc_24db:
  %0 = alloca i64
  %1 = load i64, i64* %0
  %2 = load i64, i64* %0
  %3 = trunc i64 %1 to i8
  %4 = trunc i64 %2 to i8
  %5 = icmp eq i8 %3, %4, !insn.addr !645
  %6 = zext i1 %5 to i64, !insn.addr !646
  ret i64 %6, !insn.addr !647

; uselistorder directives
  uselistorder i64* %0, { 1, 0 }
}

define i64 @_ZN4llvm11PassBuilder31registerPipelineParsingCallbackERKSt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEEE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2508:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 1328, !insn.addr !648
  %2 = inttoptr i64 %1 to i64*, !insn.addr !649
  %3 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE9push_backERKSE_(i64* %2, i64* %arg2), !insn.addr !649
  ret i64 %3, !insn.addr !650
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_253a:
  %0 = call i64 @_ZNSt14_Function_baseD1Ev(i64* %result), !insn.addr !651
  ret i64 %0, !insn.addr !652
}

define i64* @_ZSt3maxImERKT_S2_S2_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_2559:
  %0 = icmp ult i64* %arg1, %arg2, !insn.addr !653
  %1 = icmp eq i1 %0, false, !insn.addr !654
  %storemerge.v = select i1 %1, i64* %arg1, i64* %arg2
  ret i64* %storemerge.v, !insn.addr !655
}

define i1 @_ZN4llvm14has_single_bitIjvEEbT_(i32 %arg1) local_unnamed_addr {
dec_label_pc_2588:
  %storemerge.reg2mem = alloca i1, !insn.addr !656
  %0 = icmp eq i32 %arg1, 0, !insn.addr !657
  br i1 %0, label %dec_label_pc_25ad, label %dec_label_pc_2599, !insn.addr !658

dec_label_pc_2599:                                ; preds = %dec_label_pc_2588
  %1 = add i32 %arg1, -1, !insn.addr !659
  %2 = and i32 %1, %arg1, !insn.addr !660
  %3 = icmp eq i32 %2, 0, !insn.addr !661
  %4 = icmp eq i1 %3, false, !insn.addr !662
  store i1 true, i1* %storemerge.reg2mem, !insn.addr !662
  br i1 %4, label %dec_label_pc_25ad, label %dec_label_pc_25b2, !insn.addr !662

dec_label_pc_25ad:                                ; preds = %dec_label_pc_2599, %dec_label_pc_2588
  store i1 false, i1* %storemerge.reg2mem, !insn.addr !663
  br label %dec_label_pc_25b2, !insn.addr !663

dec_label_pc_25b2:                                ; preds = %dec_label_pc_2599, %dec_label_pc_25ad
  %storemerge.reload = load i1, i1* %storemerge.reg2mem
  ret i1 %storemerge.reload, !insn.addr !664

; uselistorder directives
  uselistorder i1* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i32 0, { 7, 8, 1, 9, 10, 6, 5, 2, 3, 0, 4 }
  uselistorder label %dec_label_pc_25b2, { 1, 0 }
}

define i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_25b4:
  %rdi.0.reg2mem = alloca i64, !insn.addr !665
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE15isKnownSentinelEv(i64* %result), !insn.addr !666
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !667
  %4 = icmp eq i1 %3, false, !insn.addr !668
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !668
  br i1 %4, label %dec_label_pc_2602, label %dec_label_pc_25da, !insn.addr !668

dec_label_pc_25da:                                ; preds = %dec_label_pc_25b4
  %5 = call i64 @__assert_fail(i64 ptrtoint ([28 x i8]* @global_var_1807 to i64), i64 ptrtoint ([47 x i8]* @global_var_17d8 to i64), i64 168, i64 ptrtoint ([309 x i8]* @global_var_16a0 to i64)), !insn.addr !669
  store i64 ptrtoint ([28 x i8]* @global_var_1807 to i64), i64* %rdi.0.reg2mem, !insn.addr !669
  br label %dec_label_pc_2602, !insn.addr !669

dec_label_pc_2602:                                ; preds = %dec_label_pc_25da, %dec_label_pc_25b4
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %6 = inttoptr i64 %rdi.0.reload to i64*, !insn.addr !670
  %7 = call i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %6), !insn.addr !670
  ret i64 %7, !insn.addr !671

; uselistorder directives
  uselistorder i64 (i64, i64, i64, i64)* @__assert_fail, { 3, 2, 1, 0 }
}

define i1 @_ZN4llvm3isaINS_17DbgVariableRecordENS_9DbgRecordEEEbRKT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_2613:
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_17DbgVariableRecordEKNS_9DbgRecordEvE10isPossibleERS3_(i64* %arg1), !insn.addr !672
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !673
  ret i1 %2, !insn.addr !673
}

define i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_2631:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = icmp eq i64* %arg1, %arg2, !insn.addr !674
  %2 = icmp eq i1 %1, false, !insn.addr !675
  %3 = zext i1 %2 to i64, !insn.addr !675
  %4 = and i64 %0, -256, !insn.addr !675
  %5 = or i64 %4, %3, !insn.addr !675
  ret i64 %5, !insn.addr !676
}

define i64 @_ZSt9make_pairIRPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS5_INS6_IT0_E4typeEE6__typeEEOS7_OSC_(i64**** %arg1, i1* %arg2) local_unnamed_addr {
dec_label_pc_2657:
  %rax.0.reg2mem = alloca i64, !insn.addr !677
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !678
  %1 = bitcast i1* %arg2 to i64*
  %2 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %1), !insn.addr !679
  %3 = bitcast i64**** %arg1 to i64*, !insn.addr !680
  %4 = call i64**** @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE(i64* %3), !insn.addr !680
  %5 = call i64 @_ZNSt4pairIPPKvbEC1IRS2_bLb1EEEOT_OT0_(i64* nonnull %stack_var_-56, i64**** %4, i1* %2), !insn.addr !681
  %6 = load i64, i64* %stack_var_-56, align 8, !insn.addr !682
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !683
  %8 = icmp eq i64 %0, %7, !insn.addr !683
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !684
  br i1 %8, label %dec_label_pc_26c7, label %dec_label_pc_26c2, !insn.addr !684

dec_label_pc_26c2:                                ; preds = %dec_label_pc_2657
  %9 = call i64 @__stack_chk_fail(), !insn.addr !685
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !685
  br label %dec_label_pc_26c7, !insn.addr !685

dec_label_pc_26c7:                                ; preds = %dec_label_pc_26c2, %dec_label_pc_2657
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !686

; uselistorder directives
  uselistorder i64* %stack_var_-56, { 1, 0 }
}

define i64 @_ZNSt4pairIPKPKvbEC1IPS1_bLb1EEEOS_IT_T0_E(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_26ce:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg2), !insn.addr !687
  %3 = load i64**, i64*** %2, align 8, !insn.addr !688
  %4 = ptrtoint i64** %3 to i64, !insn.addr !688
  store i64 %4, i64* %result, align 8, !insn.addr !689
  %5 = add i64 %0, 8, !insn.addr !690
  %6 = inttoptr i64 %5 to i64*, !insn.addr !691
  %7 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %6), !insn.addr !691
  %8 = bitcast i1* %7 to i8*, !insn.addr !692
  %9 = load i8, i8* %8, align 1, !insn.addr !692
  %10 = add i64 %1, 8, !insn.addr !693
  %11 = inttoptr i64 %10 to i8*, !insn.addr !693
  store i8 %9, i8* %11, align 1, !insn.addr !693
  ret i64 %1, !insn.addr !694

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64 @_ZSt9make_pairIPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS4_INS5_IT0_E4typeEE6__typeEEOS6_OSB_(i64*** %arg1, i1* %arg2) local_unnamed_addr {
dec_label_pc_2715:
  %rax.0.reg2mem = alloca i64, !insn.addr !695
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !696
  %1 = bitcast i1* %arg2 to i64*
  %2 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %1), !insn.addr !697
  %3 = bitcast i64*** %arg1 to i64*, !insn.addr !698
  %4 = call i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %3), !insn.addr !698
  %5 = call i64 @_ZNSt4pairIPPKvbEC1IS2_bLb1EEEOT_OT0_(i64* nonnull %stack_var_-56, i64*** %4, i1* %2), !insn.addr !699
  %6 = load i64, i64* %stack_var_-56, align 8, !insn.addr !700
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !701
  %8 = icmp eq i64 %0, %7, !insn.addr !701
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !702
  br i1 %8, label %dec_label_pc_2785, label %dec_label_pc_2780, !insn.addr !702

dec_label_pc_2780:                                ; preds = %dec_label_pc_2715
  %9 = call i64 @__stack_chk_fail(), !insn.addr !703
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !703
  br label %dec_label_pc_2785, !insn.addr !703

dec_label_pc_2785:                                ; preds = %dec_label_pc_2780, %dec_label_pc_2715
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !704

; uselistorder directives
  uselistorder i64* %stack_var_-56, { 1, 0 }
}

define i1 @_ZN4llvm20shouldReverseIterateIPvEEbv() local_unnamed_addr {
dec_label_pc_278b:
  ret i1 false, !insn.addr !705
}

define i64 @_ZN4llvm15SmallPtrSetImplIPvECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_279a:
  %0 = call i64 @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj(i64* %result, i64** %arg2, i32 %arg3), !insn.addr !706
  ret i64 %0, !insn.addr !707
}

define i64 @_ZN4llvm11SmallPtrSetIPvLj2EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_27ca:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 24, !insn.addr !708
  %2 = inttoptr i64 %1 to i64**, !insn.addr !709
  %3 = call i64 @_ZN4llvm15SmallPtrSetImplIPvECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %2, i32 2), !insn.addr !709
  ret i64 %3, !insn.addr !710
}

define i64 @_ZN4llvm15SmallPtrSetImplIPNS_11AnalysisKeyEECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_27fa:
  %0 = call i64 @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj(i64* %result, i64** %arg2, i32 %arg3), !insn.addr !711
  ret i64 %0, !insn.addr !712

; uselistorder directives
  uselistorder i64 (i64*, i64**, i32)* @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj, { 1, 0 }
}

define i64 @_ZN4llvm11SmallPtrSetIPNS_11AnalysisKeyELj2EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_282a:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 24, !insn.addr !713
  %2 = inttoptr i64 %1 to i64**, !insn.addr !714
  %3 = call i64 @_ZN4llvm15SmallPtrSetImplIPNS_11AnalysisKeyEECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %2, i32 2), !insn.addr !714
  ret i64 %3, !insn.addr !715

; uselistorder directives
  uselistorder i32 2, { 2, 3, 0, 1 }
}

define i64 @_ZN4llvm15SmallPtrSetImplIPvE6insertES1_(i64* %this, i64* %result, i64* %arg3) local_unnamed_addr {
dec_label_pc_285a:
  %0 = ptrtoint i64* %arg3 to i64
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-64 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !716
  %2 = call i64 @_ZN4llvm21PointerLikeTypeTraitsIPvE16getAsVoidPointerES1_(i64* %arg3), !insn.addr !717
  %3 = inttoptr i64 %2 to i64*, !insn.addr !718
  %4 = call i64 @_ZN4llvm19SmallPtrSetImplBase10insert_impEPKv(i64* %result, i64* %3), !insn.addr !718
  %5 = inttoptr i64 %4 to i64**, !insn.addr !719
  store i64 %0, i64* %stack_var_-64, align 8, !insn.addr !720
  %6 = call i64 @_ZNK4llvm15SmallPtrSetImplIPvE12makeIteratorEPKPKv(i64* %result, i64** %5), !insn.addr !721
  store i64 %6, i64* %stack_var_-56, align 8, !insn.addr !722
  %7 = bitcast i64* %stack_var_-64 to i1**, !insn.addr !723
  %8 = call i64 @_ZSt9make_pairIN4llvm19SmallPtrSetIteratorIPvEERbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS6_INS7_IT0_E4typeEE6__typeEEOS8_OSD_(i64* %this, i64* nonnull %stack_var_-56, i1** nonnull %7), !insn.addr !723
  %9 = call i64 @__readfsqword(i64 40), !insn.addr !724
  %10 = icmp eq i64 %1, %9, !insn.addr !724
  br i1 %10, label %dec_label_pc_28f0, label %dec_label_pc_28eb, !insn.addr !725

dec_label_pc_28eb:                                ; preds = %dec_label_pc_285a
  %11 = call i64 @__stack_chk_fail(), !insn.addr !726
  br label %dec_label_pc_28f0, !insn.addr !726

dec_label_pc_28f0:                                ; preds = %dec_label_pc_28eb, %dec_label_pc_285a
  %12 = ptrtoint i64* %this to i64
  ret i64 %12, !insn.addr !727

; uselistorder directives
  uselistorder i64* %this, { 1, 0 }
}

define i64 @_ZNSt14_Function_baseC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_28fa:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !728
  %1 = add i64 %0, 8, !insn.addr !729
  %2 = inttoptr i64 %1 to i64*, !insn.addr !729
  store i64 0, i64* %2, align 8, !insn.addr !729
  %3 = add i64 %0, 16, !insn.addr !730
  %4 = inttoptr i64 %3 to i64*, !insn.addr !730
  store i64 0, i64* %4, align 8, !insn.addr !730
  ret i64 %0, !insn.addr !731

; uselistorder directives
  uselistorder i64 %0, { 1, 0, 2 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE9push_backERKSE_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2928:
  %0 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE28reserveForParamAndGetAddressERKSE_m(i64* %result, i64* %arg2, i64 1), !insn.addr !732
  %1 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !733
  %2 = inttoptr i64 %1 to i64*, !insn.addr !734
  %3 = call i64 @_ZnwmPv(i64 32, i64* %2), !insn.addr !734
  %4 = inttoptr i64 %3 to i64*, !insn.addr !735
  %5 = inttoptr i64 %0 to i64*, !insn.addr !735
  %6 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1ERKSD_(i64* %4, i64* %5), !insn.addr !735
  %7 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !736
  %8 = add i64 %7, 1, !insn.addr !737
  %9 = call i64 @_ZN4llvm15SmallVectorBaseIjE8set_sizeEm(i64* %result, i64 %8), !insn.addr !738
  ret i64 %9, !insn.addr !739
}

define i64 @_ZN4llvm11PassManagerINS_6ModuleENS_15AnalysisManagerIS1_JEEEJEE7addPassIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEEENSt9enable_ifIXnt9is_same_vIT_S4_EEvE4typeEOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_29aa:
  %rax.0.reg2mem = alloca i64, !insn.addr !740
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !741
  %1 = call i64 @_Znwm(i64 16), !insn.addr !742
  %2 = call i64* @_ZSt7forwardIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %arg2), !insn.addr !743
  %3 = call i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEEC1ES4_(i64 %1), !insn.addr !744
  %4 = inttoptr i64 %1 to i64*, !insn.addr !745
  %5 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1IS8_vEEPS6_(i64* nonnull %stack_var_-40, i64* %4), !insn.addr !745
  %6 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE9push_backEOSA_(i64* %result, i64* nonnull %stack_var_-40), !insn.addr !746
  %7 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev(i64* nonnull %stack_var_-40), !insn.addr !747
  %8 = call i64 @__readfsqword(i64 40), !insn.addr !748
  %9 = icmp eq i64 %0, %8, !insn.addr !748
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !749
  br i1 %9, label %dec_label_pc_2a34, label %dec_label_pc_2a2f, !insn.addr !749

dec_label_pc_2a2f:                                ; preds = %dec_label_pc_29aa
  %10 = call i64 @__stack_chk_fail(), !insn.addr !750
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !750
  br label %dec_label_pc_2a34, !insn.addr !750

dec_label_pc_2a34:                                ; preds = %dec_label_pc_2a2f, %dec_label_pc_29aa
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !751
}

define i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2a3d:
  %0 = bitcast i64* %arg1 to i1*, !insn.addr !752
  ret i1* %0, !insn.addr !752
}

define i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2a4f:
  ret i64* %arg1, !insn.addr !753
}

define i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE15isKnownSentinelEv(i64* %result) local_unnamed_addr {
dec_label_pc_2a62:
  ret i64 0, !insn.addr !754
}

define i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2a75:
  %0 = call i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1), !insn.addr !755
  ret i64 %0, !insn.addr !756
}

define i64 @_ZN4llvm14CastIsPossibleINS_17DbgVariableRecordEKNS_9DbgRecordEvE10isPossibleERS3_(i64* %arg1) local_unnamed_addr {
dec_label_pc_2a93:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_17DbgVariableRecordEKNS_9DbgRecordES3_E4doitERS3_(i64* %arg1), !insn.addr !757
  ret i64 %0, !insn.addr !758
}

define i64 @_ZN4llvm9adl_beginIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl10begin_implcl7forwardIT_Efp_EEEOSA_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2ab1:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !759
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !759
  %2 = call i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSB_(i64** %1), !insn.addr !760
  ret i64 %2, !insn.addr !761
}

define i64 @_ZN4llvm7adl_endIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl8end_implcl7forwardIT_Efp_EEEOSA_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2ad7:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !762
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !762
  %2 = call i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSB_(i64** %1), !insn.addr !763
  ret i64 %2, !insn.addr !764
}

define i64* @_ZSt4moveIRN4llvm14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEONSt16remove_referenceIT_E4typeEOS9_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2afd:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !765
  ret i64* %0, !insn.addr !765
}

define i64**** @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2b0f:
  %0 = bitcast i64* %arg1 to i64****, !insn.addr !766
  ret i64**** %0, !insn.addr !766
}

define i64 @_ZNSt4pairIPPKvbEC1IRS2_bLb1EEEOT_OT0_(i64* %result, i64**** %arg2, i1* %arg3) local_unnamed_addr {
dec_label_pc_2b22:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i64**** %arg2 to i64*, !insn.addr !767
  %2 = call i64**** @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE(i64* %1), !insn.addr !767
  %3 = load i64***, i64**** %2, align 8, !insn.addr !768
  %4 = ptrtoint i64*** %3 to i64, !insn.addr !768
  store i64 %4, i64* %result, align 8, !insn.addr !769
  %5 = bitcast i1* %arg3 to i64*, !insn.addr !770
  %6 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %5), !insn.addr !770
  %7 = bitcast i1* %6 to i8*, !insn.addr !771
  %8 = load i8, i8* %7, align 1, !insn.addr !771
  %9 = add i64 %0, 8, !insn.addr !772
  %10 = inttoptr i64 %9 to i8*, !insn.addr !772
  store i8 %8, i8* %10, align 1, !insn.addr !772
  ret i64 %0, !insn.addr !773

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64**** (i64*)* @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE, { 1, 0 }
}

define i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2b69:
  %0 = bitcast i64* %arg1 to i64***, !insn.addr !774
  ret i64*** %0, !insn.addr !774
}

define i64 @_ZNSt4pairIPPKvbEC1IS2_bLb1EEEOT_OT0_(i64* %result, i64*** %arg2, i1* %arg3) local_unnamed_addr {
dec_label_pc_2b7c:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i64*** %arg2 to i64*, !insn.addr !775
  %2 = call i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %1), !insn.addr !775
  %3 = load i64**, i64*** %2, align 8, !insn.addr !776
  %4 = ptrtoint i64** %3 to i64, !insn.addr !776
  store i64 %4, i64* %result, align 8, !insn.addr !777
  %5 = bitcast i1* %arg3 to i64*, !insn.addr !778
  %6 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %5), !insn.addr !778
  %7 = bitcast i1* %6 to i8*, !insn.addr !779
  %8 = load i8, i8* %7, align 1, !insn.addr !779
  %9 = add i64 %0, 8, !insn.addr !780
  %10 = inttoptr i64 %9 to i8*, !insn.addr !780
  store i8 %8, i8* %10, align 1, !insn.addr !780
  ret i64 %0, !insn.addr !781

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i1* (i64*)* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE, { 4, 3, 2, 1, 0 }
  uselistorder i64*** (i64*)* @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE, { 2, 1, 0 }
}

define i64 @_ZNK4llvm15SmallPtrSetImplIPvE12makeIteratorEPKPKv(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_2bc4:
  %rax.0.reg2mem = alloca i64, !insn.addr !782
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !783
  %1 = call i1 @_ZN4llvm20shouldReverseIterateIPvEEbv(), !insn.addr !784
  %2 = icmp eq i1 %1, false, !insn.addr !785
  br i1 %2, label %dec_label_pc_2c3b, label %dec_label_pc_2bf1, !insn.addr !786

dec_label_pc_2bf1:                                ; preds = %dec_label_pc_2bc4
  %3 = ptrtoint i64* %result to i64
  %4 = call i64 @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv(i64* %result), !insn.addr !787
  %5 = ptrtoint i64** %arg2 to i64, !insn.addr !788
  %6 = icmp eq i64 %4, %5, !insn.addr !788
  %7 = icmp eq i1 %6, false, !insn.addr !789
  %8 = add i64 %5, 8
  %storemerge = select i1 %7, i64 %8, i64 %3
  %9 = inttoptr i64 %storemerge to i64**, !insn.addr !790
  %10 = bitcast i64* %result to i64**, !insn.addr !790
  %11 = call i64 @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE(i64* nonnull %stack_var_-56, i64** %9, i64** %10, i64* %result), !insn.addr !790
  br label %dec_label_pc_2c6c, !insn.addr !791

dec_label_pc_2c3b:                                ; preds = %dec_label_pc_2bc4
  %12 = call i64 @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv(i64* %result), !insn.addr !792
  %13 = inttoptr i64 %12 to i64**, !insn.addr !793
  %14 = call i64 @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE(i64* nonnull %stack_var_-56, i64** %arg2, i64** %13, i64* %result), !insn.addr !793
  br label %dec_label_pc_2c6c, !insn.addr !794

dec_label_pc_2c6c:                                ; preds = %dec_label_pc_2c3b, %dec_label_pc_2bf1
  %storemerge2 = load i64, i64* %stack_var_-56, align 8
  %15 = call i64 @__readfsqword(i64 40), !insn.addr !795
  %16 = icmp eq i64 %0, %15, !insn.addr !795
  store i64 %storemerge2, i64* %rax.0.reg2mem, !insn.addr !796
  br i1 %16, label %dec_label_pc_2c80, label %dec_label_pc_2c7b, !insn.addr !796

dec_label_pc_2c7b:                                ; preds = %dec_label_pc_2c6c
  %17 = call i64 @__stack_chk_fail(), !insn.addr !797
  store i64 %17, i64* %rax.0.reg2mem, !insn.addr !797
  br label %dec_label_pc_2c80, !insn.addr !797

dec_label_pc_2c80:                                ; preds = %dec_label_pc_2c7b, %dec_label_pc_2c6c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !798

; uselistorder directives
  uselistorder i64 (i64*, i64**, i64**, i64*)* @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv, { 1, 0 }
  uselistorder i64** %arg2, { 1, 0 }
}

define i64 @_ZSt9make_pairIN4llvm19SmallPtrSetIteratorIPvEERbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS6_INS7_IT0_E4typeEE6__typeEEOS8_OSD_(i64* %result, i64* %arg2, i1** %arg3) local_unnamed_addr {
dec_label_pc_2c86:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i1** %arg3 to i64*, !insn.addr !799
  %2 = call i1** @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE(i64* %1), !insn.addr !799
  %3 = call i64* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg2), !insn.addr !800
  %4 = call i64 @_ZNSt4pairIN4llvm19SmallPtrSetIteratorIPvEEbEC1IS3_RbLb1EEEOT_OT0_(i64* %result, i64* %3, i1** %2), !insn.addr !801
  ret i64 %0, !insn.addr !802
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE28reserveForParamAndGetAddressERKSE_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_2cda:
  %0 = call i64* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE32reserveForParamAndGetAddressImplINS_23SmallVectorTemplateBaseISE_Lb0EEEEEPKSE_PT_RSJ_m(i64* %result, i64* %arg2, i64 %arg3), !insn.addr !803
  %1 = ptrtoint i64* %0 to i64, !insn.addr !803
  ret i64 %1, !insn.addr !804
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_2d0c:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !805
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !806
  %2 = mul i64 %1, 32, !insn.addr !807
  %3 = add i64 %2, %0, !insn.addr !808
  ret i64 %3, !insn.addr !809
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1ERKSD_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2d46:
  %0 = alloca i128
  %rax.0.reg2mem = alloca i64, !insn.addr !810
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %result to i64
  %3 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !811
  %4 = bitcast i64* %rdi to i128*
  %5 = load i128, i128* %4, align 8, !insn.addr !812
  call void @__asm_movups(i128 %5, i128 %3), !insn.addr !812
  %6 = add i64 %2, 16, !insn.addr !813
  %7 = inttoptr i64 %6 to i64*, !insn.addr !813
  %8 = load i64, i64* %7, align 8, !insn.addr !813
  call void @__asm_movq(i64 %8, i128 %3), !insn.addr !813
  %9 = call i64 @_ZNSt14_Function_baseC1Ev(i64* %result), !insn.addr !814
  %10 = add i64 %2, 24, !insn.addr !815
  %11 = inttoptr i64 %10 to i64*, !insn.addr !815
  store i64 0, i64* %11, align 8, !insn.addr !815
  %12 = call i64 @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv(i64* %arg2), !insn.addr !816
  %13 = trunc i64 %12 to i8, !insn.addr !817
  %14 = icmp eq i8 %13, 0, !insn.addr !817
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !818
  br i1 %14, label %dec_label_pc_2dd0, label %dec_label_pc_2d92, !insn.addr !818

dec_label_pc_2d92:                                ; preds = %dec_label_pc_2d46
  %15 = ptrtoint i64* %arg2 to i64
  %16 = add i64 %15, 24, !insn.addr !819
  %17 = inttoptr i64 %16 to i64*, !insn.addr !819
  %18 = load i64, i64* %17, align 8, !insn.addr !819
  store i64 %18, i64* %11, align 8, !insn.addr !820
  %19 = add i64 %15, 16, !insn.addr !821
  %20 = inttoptr i64 %19 to i64*, !insn.addr !821
  %21 = load i64, i64* %20, align 8, !insn.addr !821
  store i64 %21, i64* %7, align 8, !insn.addr !822
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !822
  br label %dec_label_pc_2dd0, !insn.addr !822

dec_label_pc_2dd0:                                ; preds = %dec_label_pc_2d92, %dec_label_pc_2d46
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !823

; uselistorder directives
  uselistorder i128 %3, { 1, 0 }
  uselistorder i64* %arg2, { 1, 0 }
}

define i64* @_ZSt7forwardIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2dd3:
  ret i64* %arg1, !insn.addr !824
}

define i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_2de6:
  %0 = ptrtoint i64* %result to i64
  %1 = load i64, i64* inttoptr (i64 11769 to i64*), align 8, !insn.addr !825
  %2 = add i64 %1, 16, !insn.addr !826
  store i64 %2, i64* %result, align 8, !insn.addr !827
  ret i64 %0, !insn.addr !828
}

define i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_2e08:
  %0 = ptrtoint i64* %result to i64
  %1 = load i64, i64* inttoptr (i64 11803 to i64*), align 8, !insn.addr !829
  %2 = add i64 %1, 16, !insn.addr !830
  store i64 %2, i64* %result, align 8, !insn.addr !831
  ret i64 %0, !insn.addr !832
}

define i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED0Ev(i64* %result) local_unnamed_addr {
dec_label_pc_2e2a:
  %0 = call i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result), !insn.addr !833
  %1 = call i64 @_ZdlPvm(i64* %result, i64 8), !insn.addr !834
  ret i64 %1, !insn.addr !835
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEEC1ES4_(i64 %arg1) local_unnamed_addr {
dec_label_pc_2e5a:
  %stack_var_-17 = alloca i64, align 8
  %0 = inttoptr i64 %arg1 to i64*, !insn.addr !836
  %1 = call i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEEC1Ev(i64* %0), !insn.addr !836
  %2 = load i64, i64* inttoptr (i64 11901 to i64*), align 8, !insn.addr !837
  %3 = add i64 %2, 16, !insn.addr !838
  store i64 %3, i64* %0, align 8, !insn.addr !839
  %4 = bitcast i64* %stack_var_-17 to i64**, !insn.addr !840
  %5 = call i64* @_ZSt4moveIRN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEEONSt16remove_referenceIT_E4typeEOS4_(i64** nonnull %4), !insn.addr !840
  %6 = ptrtoint i64* %5 to i64, !insn.addr !840
  ret i64 %6, !insn.addr !841
}

define i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EECI1St15__uniq_ptr_implIS6_S8_EEPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2e98:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EPS6_(i64* %result, i64* %arg2), !insn.addr !842
  ret i64 %0, !insn.addr !843
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1IS8_vEEPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2ec2:
  %0 = call i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EECI1St15__uniq_ptr_implIS6_S8_EEPS6_(i64* %result, i64* %arg2), !insn.addr !844
  ret i64 %0, !insn.addr !845
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_2eec:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %result), !insn.addr !846
  %1 = inttoptr i64 %0 to i64*, !insn.addr !847
  %2 = load i64, i64* %1, align 8, !insn.addr !847
  %3 = icmp eq i64 %2, 0, !insn.addr !848
  br i1 %3, label %dec_label_pc_2f42, label %dec_label_pc_2f19, !insn.addr !849

dec_label_pc_2f19:                                ; preds = %dec_label_pc_2eec
  %4 = inttoptr i64 %0 to i64***, !insn.addr !850
  %5 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE11get_deleterEv(i64* %result), !insn.addr !851
  %6 = call i64* @_ZSt4moveIRPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEONSt16remove_referenceIT_E4typeEOSA_(i64*** %4), !insn.addr !852
  %7 = load i64, i64* %6, align 8, !insn.addr !853
  %8 = inttoptr i64 %5 to i64*, !insn.addr !854
  %9 = inttoptr i64 %7 to i64*, !insn.addr !854
  %10 = call i64 @_ZNKSt14default_deleteIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEclEPS6_(i64* %8, i64* %9), !insn.addr !854
  br label %dec_label_pc_2f42, !insn.addr !854

dec_label_pc_2f42:                                ; preds = %dec_label_pc_2f19, %dec_label_pc_2eec
  store i64 0, i64* %1, align 8, !insn.addr !855
  ret i64 %0, !insn.addr !856
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE9push_backEOSA_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2f54:
  %0 = bitcast i64* %arg2 to i64**, !insn.addr !857
  %1 = call i64* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_(i64** %0), !insn.addr !857
  %2 = ptrtoint i64* %1 to i64, !insn.addr !857
  %3 = call i64* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12emplace_backIJSA_EEERSA_DpOT_(i64* %result, i64 %2), !insn.addr !858
  %4 = ptrtoint i64* %3 to i64, !insn.addr !858
  ret i64 %4, !insn.addr !859
}

define i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2f89:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !860
}

define i64 @_ZN4llvm13isa_impl_wrapINS_17DbgVariableRecordEKNS_9DbgRecordES3_E4doitERS3_(i64* %arg1) local_unnamed_addr {
dec_label_pc_2f9b:
  %0 = call i64 @_ZN4llvm11isa_impl_clINS_17DbgVariableRecordEKNS_9DbgRecordEE4doitERS3_(i64* %arg1), !insn.addr !861
  ret i64 %0, !insn.addr !862
}

define i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2fb9:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !863
  ret i64** %0, !insn.addr !863
}

define i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSB_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2fcb:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !864
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !864
  %2 = bitcast i64** %1 to i64*, !insn.addr !865
  %3 = call i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE5beginEv(i64* %2), !insn.addr !865
  ret i64 %3, !insn.addr !866
}

define i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSB_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2ffa:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !867
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !867
  %2 = bitcast i64** %1 to i64*, !insn.addr !868
  %3 = call i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE3endEv(i64* %2), !insn.addr !868
  ret i64 %3, !insn.addr !869

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE, { 3, 2, 1, 0 }
}

define i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_302a:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !870
  %2 = inttoptr i64 %1 to i64*, !insn.addr !870
  %3 = load i64, i64* %2, align 8, !insn.addr !870
  ret i64 %3, !insn.addr !871
}

define i64 @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE(i64* %result, i64** %arg2, i64** %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_3040:
  %0 = call i64 @_ZN4llvm23SmallPtrSetIteratorImplC1EPKPKvS4_(i64* %result, i64** %arg2, i64** %arg3), !insn.addr !872
  %1 = call i64 @_ZN4llvm14DebugEpochBase10HandleBaseC1EPKS0_(i64* %result, i64* %arg4), !insn.addr !873
  ret i64 %1, !insn.addr !874
}

define i64* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_3089:
  ret i64* %arg1, !insn.addr !875
}

define i1** @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_309b:
  %0 = bitcast i64* %arg1 to i1**, !insn.addr !876
  ret i1** %0, !insn.addr !876
}

define i64 @_ZNSt4pairIN4llvm19SmallPtrSetIteratorIPvEEbEC1IS3_RbLb1EEEOT_OT0_(i64* %result, i64* %arg2, i1** %arg3) local_unnamed_addr {
dec_label_pc_30ae:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg2), !insn.addr !877
  %2 = ptrtoint i64* %1 to i64, !insn.addr !877
  %3 = add i64 %2, 8, !insn.addr !878
  %4 = inttoptr i64 %3 to i64*, !insn.addr !878
  %5 = load i64, i64* %4, align 8, !insn.addr !878
  %6 = load i64, i64* %1, align 8, !insn.addr !879
  store i64 %6, i64* %result, align 8, !insn.addr !880
  %7 = add i64 %0, 8, !insn.addr !881
  %8 = inttoptr i64 %7 to i64*, !insn.addr !881
  store i64 %5, i64* %8, align 8, !insn.addr !881
  %9 = bitcast i1** %arg3 to i64*, !insn.addr !882
  %10 = call i1** @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE(i64* %9), !insn.addr !882
  %11 = bitcast i1** %10 to i8*, !insn.addr !883
  %12 = load i8, i8* %11, align 1, !insn.addr !883
  %13 = add i64 %0, 16, !insn.addr !884
  %14 = inttoptr i64 %13 to i8*, !insn.addr !884
  store i8 %12, i8* %14, align 1, !insn.addr !884
  ret i64 %0, !insn.addr !885

; uselistorder directives
  uselistorder i64 %0, { 1, 0, 2 }
  uselistorder i1** (i64*)* @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE, { 1, 0 }
  uselistorder i64* (i64*)* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE, { 1, 0 }
}

define i64** @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v(i64* %result) local_unnamed_addr {
dec_label_pc_30fe:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !886
  %1 = inttoptr i64 %0 to i64**, !insn.addr !887
  ret i64** %1, !insn.addr !887

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNSt9_Any_data9_M_accessEv, { 4, 3, 2, 1, 0 }
}

define i1 @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_311c:
  %rax.0.reg2mem = alloca i64, !insn.addr !888
  %stack_var_-17 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !889
  %1 = call i64 @_ZNKSt4lessIPKvEclES1_S1_(i64* nonnull %stack_var_-17, i64* %arg2, i64* %arg3), !insn.addr !890
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !891
  %3 = icmp eq i64 %0, %2, !insn.addr !891
  store i64 %1, i64* %rax.0.reg2mem, !insn.addr !892
  br i1 %3, label %dec_label_pc_316e, label %dec_label_pc_3169, !insn.addr !892

dec_label_pc_3169:                                ; preds = %dec_label_pc_311c
  %4 = call i64 @__stack_chk_fail(), !insn.addr !893
  store i64 %4, i64* %rax.0.reg2mem, !insn.addr !893
  br label %dec_label_pc_316e, !insn.addr !893

dec_label_pc_316e:                                ; preds = %dec_label_pc_3169, %dec_label_pc_311c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %5 = urem i64 %rax.0.reload, 2
  %6 = icmp ne i64 %5, 0, !insn.addr !894
  ret i1 %6, !insn.addr !894

; uselistorder directives
  uselistorder i64 2, { 1, 2, 3, 0 }
}

define i64* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE32reserveForParamAndGetAddressImplINS_23SmallVectorTemplateBaseISE_Lb0EEEEEPKSE_PT_RSJ_m(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_3170:
  %storemerge1.reg2mem = alloca i64, !insn.addr !895
  %0 = ptrtoint i64* %arg2 to i64
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %arg1), !insn.addr !896
  %2 = add i64 %1, %arg3, !insn.addr !897
  %3 = call i64 @_ZNK4llvm15SmallVectorBaseIjE8capacityEv(i64* %arg1), !insn.addr !898
  %4 = icmp ult i64 %3, %2, !insn.addr !899
  %5 = icmp eq i1 %4, false, !insn.addr !900
  %6 = icmp eq i1 %5, false, !insn.addr !901
  %7 = icmp eq i1 %6, false, !insn.addr !902
  %8 = icmp eq i1 %7, false, !insn.addr !903
  store i64 %0, i64* %storemerge1.reg2mem, !insn.addr !904
  br i1 %8, label %dec_label_pc_31c8, label %dec_label_pc_324d, !insn.addr !904

dec_label_pc_31c8:                                ; preds = %dec_label_pc_3170
  %9 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE20isReferenceToStorageEPKv(i64* %arg1, i64* %arg2), !insn.addr !905
  %10 = urem i64 %9, 256, !insn.addr !906
  %11 = icmp eq i64 %10, 0, !insn.addr !907
  %12 = icmp eq i1 %11, false, !insn.addr !908
  %13 = icmp eq i1 %12, false, !insn.addr !909
  br i1 %13, label %dec_label_pc_3216.thread, label %dec_label_pc_322f, !insn.addr !910

dec_label_pc_3216.thread:                         ; preds = %dec_label_pc_31c8
  %14 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm(i64* %arg1, i64 %2), !insn.addr !911
  store i64 %0, i64* %storemerge1.reg2mem
  br label %dec_label_pc_324d

dec_label_pc_322f:                                ; preds = %dec_label_pc_31c8
  %15 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %arg1), !insn.addr !912
  %16 = sub i64 %0, %15, !insn.addr !913
  %17 = and i64 %16, -32
  %18 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm(i64* %arg1, i64 %2), !insn.addr !911
  %19 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %arg1), !insn.addr !914
  %20 = add i64 %19, %17, !insn.addr !915
  store i64 %20, i64* %storemerge1.reg2mem, !insn.addr !916
  br label %dec_label_pc_324d, !insn.addr !916

dec_label_pc_324d:                                ; preds = %dec_label_pc_3216.thread, %dec_label_pc_3170, %dec_label_pc_322f
  %storemerge1.reload = load i64, i64* %storemerge1.reg2mem
  %21 = inttoptr i64 %storemerge1.reload to i64*, !insn.addr !917
  ret i64* %21, !insn.addr !917

; uselistorder directives
  uselistorder i64 %2, { 1, 0, 2 }
  uselistorder i64 %0, { 2, 0, 1 }
  uselistorder i64* %storemerge1.reg2mem, { 0, 3, 1, 2 }
  uselistorder i64 (i64*, i64)* @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm, { 1, 0 }
  uselistorder i64* %arg1, { 1, 2, 3, 0, 4, 5, 6 }
  uselistorder label %dec_label_pc_324d, { 2, 0, 1 }
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_3250:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !918
}

define i64 @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv(i64* %result) local_unnamed_addr {
dec_label_pc_3266:
  %0 = call i64 @_ZNKSt14_Function_base8_M_emptyEv(i64* %result), !insn.addr !919
  %1 = and i64 %0, 4294967295, !insn.addr !920
  %2 = xor i64 %1, 1, !insn.addr !920
  ret i64 %2, !insn.addr !921

; uselistorder directives
  uselistorder i64 4294967295, { 1, 0 }
}

define i64* @_ZSt4moveIRN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEEONSt16remove_referenceIT_E4typeEOS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_3287:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !922
  ret i64* %0, !insn.addr !922
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_329a:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = call i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1ILb1ELb1EEEv(i64* %result), !insn.addr !923
  %2 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %result), !insn.addr !924
  %3 = inttoptr i64 %2 to i64*, !insn.addr !925
  store i64 %0, i64* %3, align 8, !insn.addr !925
  ret i64 %2, !insn.addr !926

; uselistorder directives
  uselistorder i64 %2, { 1, 0 }
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %result) local_unnamed_addr {
dec_label_pc_32d6:
  %0 = call i64* @_ZSt3getILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %result), !insn.addr !927
  %1 = ptrtoint i64* %0 to i64, !insn.addr !927
  ret i64 %1, !insn.addr !928
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE11get_deleterEv(i64* %result) local_unnamed_addr {
dec_label_pc_32f4:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE10_M_deleterEv(i64* %result), !insn.addr !929
  ret i64 %0, !insn.addr !930
}

define i64* @_ZSt4moveIRPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEONSt16remove_referenceIT_E4typeEOSA_(i64*** %arg1) local_unnamed_addr {
dec_label_pc_3312:
  %0 = bitcast i64*** %arg1 to i64*, !insn.addr !931
  ret i64* %0, !insn.addr !931
}

define i64 @_ZNKSt14default_deleteIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEclEPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3324:
  %0 = ptrtoint i64* %arg2 to i64
  ret i64 %0, !insn.addr !932
}

define i64* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_(i64** %arg1) local_unnamed_addr {
dec_label_pc_3353:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !933
  ret i64* %0, !insn.addr !933
}

define i64* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12emplace_backIJSA_EEERSA_DpOT_(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_3366:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !934
  %2 = inttoptr i64 %1 to i64*, !insn.addr !934
  %3 = load i64, i64* %2, align 8, !insn.addr !934
  %4 = add i64 %0, 16, !insn.addr !935
  %5 = inttoptr i64 %4 to i64*, !insn.addr !935
  %6 = load i64, i64* %5, align 8, !insn.addr !935
  %7 = icmp eq i64 %3, %6, !insn.addr !936
  %8 = inttoptr i64 %arg2 to i64*
  %9 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %8)
  br i1 %7, label %dec_label_pc_341b, label %dec_label_pc_3394, !insn.addr !937

dec_label_pc_3394:                                ; preds = %dec_label_pc_3366
  %10 = load i64, i64* %2, align 8, !insn.addr !938
  %11 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %9), !insn.addr !939
  %12 = inttoptr i64 %10 to i64*, !insn.addr !940
  %13 = call i64 @_ZnwmPv(i64 8, i64* %12), !insn.addr !940
  %14 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %11), !insn.addr !941
  %15 = inttoptr i64 %13 to i64*, !insn.addr !942
  %16 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %15, i64* %14), !insn.addr !942
  %17 = load i64, i64* %2, align 8, !insn.addr !943
  %18 = add i64 %17, 8, !insn.addr !944
  store i64 %18, i64* %2, align 8, !insn.addr !945
  br label %dec_label_pc_344b, !insn.addr !946

dec_label_pc_341b:                                ; preds = %dec_label_pc_3366
  %19 = ptrtoint i64* %9 to i64, !insn.addr !947
  %20 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv(i64* %result), !insn.addr !948
  call void @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE17_M_realloc_insertIJSA_EEEvN9__gnu_cxx17__normal_iteratorIPSA_SC_EEDpOT_(i64* %result, i64 %20, i64 %19), !insn.addr !949
  br label %dec_label_pc_344b, !insn.addr !949

dec_label_pc_344b:                                ; preds = %dec_label_pc_341b, %dec_label_pc_3394
  %21 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4backEv(i64* %result), !insn.addr !950
  %22 = inttoptr i64 %21 to i64*, !insn.addr !951
  ret i64* %22, !insn.addr !951

; uselistorder directives
  uselistorder i64* %9, { 1, 0 }
  uselistorder i64* %2, { 1, 0, 2, 3 }
  uselistorder i64* %result, { 2, 0, 1, 3 }
}

define i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_345d:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !952
  ret i64** %0, !insn.addr !952
}

define i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_346f:
  ret i64* %arg1, !insn.addr !953
}

define i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* %result) local_unnamed_addr {
dec_label_pc_3482:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE7getNextEv(i64* %result), !insn.addr !954
  store i64 %1, i64* %result, align 8, !insn.addr !955
  ret i64 %0, !insn.addr !956
}

define i64 @_ZN4llvm11isa_impl_clINS_17DbgVariableRecordEKNS_9DbgRecordEE4doitERS3_(i64* %arg1) local_unnamed_addr {
dec_label_pc_34ae:
  %0 = call i64 @_ZN4llvm8isa_implINS_17DbgVariableRecordENS_9DbgRecordEvE4doitERKS2_(i64* %arg1), !insn.addr !957
  ret i64 %0, !insn.addr !958
}

define i64 @_ZNKSt4lessIPKvEclES1_S1_(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_34cc:
  %0 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !959
  %1 = trunc i64 %0 to i8, !insn.addr !960
  %2 = icmp eq i8 %1, 0, !insn.addr !960
  %3 = icmp ult i64* %arg2, %arg3
  %4 = zext i1 %3 to i64
  %storemerge.v.v.v = select i1 %2, i64* %arg3, i64* %arg2
  %storemerge.v.v = ptrtoint i64* %storemerge.v.v.v to i64
  %storemerge.v = and i64 %storemerge.v.v, -256
  %storemerge = or i64 %storemerge.v, %4
  ret i64 %storemerge, !insn.addr !961

; uselistorder directives
  uselistorder i64 ()* @_ZSt23__is_constant_evaluatedv, { 1, 0 }
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE20isReferenceToStorageEPKv(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_350a:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !962
  %1 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !963
  %2 = inttoptr i64 %1 to i64*, !insn.addr !964
  %3 = inttoptr i64 %0 to i64*, !insn.addr !964
  %4 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE18isReferenceToRangeEPKvSH_SH_(i64* %result, i64* %arg2, i64* %2, i64* %3), !insn.addr !964
  ret i64 %4, !insn.addr !965
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_3556:
  %rax.0.reg2mem = alloca i64, !insn.addr !966
  %stack_var_-32 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !967
  %1 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13mallocForGrowEmRm(i64* %result, i64 %arg2, i64* nonnull %stack_var_-32), !insn.addr !968
  %2 = inttoptr i64 %1 to i64*, !insn.addr !969
  %3 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE19moveElementsForGrowEPSE_(i64* %result, i64* %2), !insn.addr !969
  %4 = load i64, i64* %stack_var_-32, align 8, !insn.addr !970
  %5 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE21takeAllocationForGrowEPSE_m(i64* %result, i64* %2, i64 %4), !insn.addr !971
  %6 = call i64 @__readfsqword(i64 40), !insn.addr !972
  %7 = icmp eq i64 %0, %6, !insn.addr !972
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !973
  br i1 %7, label %dec_label_pc_35d3, label %dec_label_pc_35ce, !insn.addr !973

dec_label_pc_35ce:                                ; preds = %dec_label_pc_3556
  %8 = call i64 @__stack_chk_fail(), !insn.addr !974
  store i64 %8, i64* %rax.0.reg2mem, !insn.addr !974
  br label %dec_label_pc_35d3, !insn.addr !974

dec_label_pc_35d3:                                ; preds = %dec_label_pc_35ce, %dec_label_pc_3556
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !975

; uselistorder directives
  uselistorder i64* %stack_var_-32, { 1, 0 }
}

define i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1ILb1ELb1EEEv(i64* %result) local_unnamed_addr {
dec_label_pc_35d6:
  %0 = call i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1Ev(i64* %result), !insn.addr !976
  ret i64 %0, !insn.addr !977
}

define i64* @_ZSt3getILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %arg1) local_unnamed_addr {
dec_label_pc_35f5:
  %0 = call i64** @_ZSt12__get_helperILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEJSt14default_deleteIS6_EEERT0_RSt11_Tuple_implIXT_EJSA_DpT1_EE(i64* %arg1), !insn.addr !978
  %1 = bitcast i64** %0 to i64*, !insn.addr !979
  ret i64* %1, !insn.addr !979
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE10_M_deleterEv(i64* %result) local_unnamed_addr {
dec_label_pc_3614:
  %0 = call i64* @_ZSt3getILm1EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %result), !insn.addr !980
  %1 = ptrtoint i64* %0 to i64, !insn.addr !980
  ret i64 %1, !insn.addr !981
}

define i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_3632:
  ret i64* %arg1, !insn.addr !982
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_3644:
  %rax.0.reg2mem = alloca i64, !insn.addr !983
  %0 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !984
  %2 = add i64 %0, 8, !insn.addr !985
  %3 = inttoptr i64 %2 to i64**, !insn.addr !986
  %4 = call i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* nonnull %stack_var_-24, i64** %3), !insn.addr !986
  %5 = load i64, i64* %stack_var_-24, align 8, !insn.addr !987
  %6 = call i64 @__readfsqword(i64 40), !insn.addr !988
  %7 = icmp eq i64 %1, %6, !insn.addr !988
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !989
  br i1 %7, label %dec_label_pc_3692, label %dec_label_pc_368d, !insn.addr !989

dec_label_pc_368d:                                ; preds = %dec_label_pc_3644
  %8 = call i64 @__stack_chk_fail(), !insn.addr !990
  store i64 %8, i64* %rax.0.reg2mem, !insn.addr !990
  br label %dec_label_pc_3692, !insn.addr !990

dec_label_pc_3692:                                ; preds = %dec_label_pc_368d, %dec_label_pc_3644
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !991

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
}

define void @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE17_M_realloc_insertIJSA_EEEvN9__gnu_cxx17__normal_iteratorIPSA_SC_EEDpOT_(i64* %result, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_3694:
  %0 = ptrtoint i64* %result to i64
  %stack_var_-136 = alloca i64, align 8
  %stack_var_-152 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-152, align 8, !insn.addr !992
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !993
  %2 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12_M_check_lenEmPKc(i64* %result, i64 1, i8* getelementptr inbounds ([26 x i8], [26 x i8]* @global_var_1828, i64 0, i64 0)), !insn.addr !994
  %3 = add i64 %0, 8, !insn.addr !995
  %4 = inttoptr i64 %3 to i64*, !insn.addr !995
  %5 = load i64, i64* %4, align 8, !insn.addr !995
  %6 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE5beginEv(i64* %result), !insn.addr !996
  store i64 %6, i64* %stack_var_-136, align 8, !insn.addr !997
  %7 = call i64 @_ZN9__gnu_cxxmiIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKSJ_SM_(i64* nonnull %stack_var_-152, i64* nonnull %stack_var_-136), !insn.addr !998
  %8 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_M_allocateEm(i64* %result, i64 %2), !insn.addr !999
  %9 = inttoptr i64 %arg3 to i64*, !insn.addr !1000
  %10 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %9), !insn.addr !1000
  %11 = mul i64 %7, 8, !insn.addr !1001
  %12 = add i64 %11, %8, !insn.addr !1002
  %13 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %10), !insn.addr !1003
  %14 = inttoptr i64 %12 to i64*, !insn.addr !1004
  %15 = call i64 @_ZnwmPv(i64 8, i64* %14), !insn.addr !1004
  %16 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %13), !insn.addr !1005
  %17 = inttoptr i64 %15 to i64*, !insn.addr !1006
  %18 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %17, i64* %16), !insn.addr !1006
  %19 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result), !insn.addr !1007
  %20 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* nonnull %stack_var_-152), !insn.addr !1008
  %21 = inttoptr i64 %20 to i64*, !insn.addr !1009
  %22 = load i64, i64* %21, align 8, !insn.addr !1009
  %23 = inttoptr i64 %22 to i64*, !insn.addr !1010
  %24 = inttoptr i64 %8 to i64*, !insn.addr !1010
  %25 = inttoptr i64 %19 to i64*, !insn.addr !1010
  %26 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_(i64* %result, i64* %23, i64* %24, i64* %25), !insn.addr !1010
  %27 = add i64 %26, 8, !insn.addr !1011
  %28 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result), !insn.addr !1012
  %29 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* nonnull %stack_var_-152), !insn.addr !1013
  %30 = inttoptr i64 %29 to i64*, !insn.addr !1014
  %31 = load i64, i64* %30, align 8, !insn.addr !1014
  %32 = inttoptr i64 %31 to i64*, !insn.addr !1015
  %33 = inttoptr i64 %5 to i64*, !insn.addr !1015
  %34 = inttoptr i64 %27 to i64*, !insn.addr !1015
  %35 = inttoptr i64 %28 to i64*, !insn.addr !1015
  %36 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_(i64* %32, i64* %33, i64* %34, i64* %35), !insn.addr !1015
  %37 = add i64 %0, 16, !insn.addr !1016
  %38 = inttoptr i64 %37 to i64*, !insn.addr !1016
  %39 = load i64, i64* %38, align 8, !insn.addr !1016
  %40 = sub i64 %39, %0, !insn.addr !1017
  %41 = ashr i64 %40, 3, !insn.addr !1018
  %42 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE13_M_deallocateEPSA_m(i64* %result, i64* %result, i64 %41), !insn.addr !1019
  store i64 %8, i64* %result, align 8, !insn.addr !1020
  store i64 %36, i64* %4, align 8, !insn.addr !1021
  %43 = mul i64 %2, 8, !insn.addr !1022
  %44 = add i64 %8, %43, !insn.addr !1023
  store i64 %44, i64* %38, align 8, !insn.addr !1024
  %45 = call i64 @__readfsqword(i64 40), !insn.addr !1025
  %46 = icmp eq i64 %1, %45, !insn.addr !1025
  br i1 %46, label %dec_label_pc_38d1, label %dec_label_pc_38cc, !insn.addr !1026

dec_label_pc_38cc:                                ; preds = %dec_label_pc_3694
  %47 = call i64 @__stack_chk_fail(), !insn.addr !1027
  br label %dec_label_pc_38d1, !insn.addr !1027

dec_label_pc_38d1:                                ; preds = %dec_label_pc_38cc, %dec_label_pc_3694
  ret void, !insn.addr !1028

; uselistorder directives
  uselistorder i64 %0, { 2, 0, 1 }
  uselistorder i64 (i64*, i64*, i64*, i64*)* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv, { 1, 0 }
  uselistorder i64 1, { 6, 5, 10, 7, 11, 0, 1, 2, 12, 8, 9, 3, 4 }
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4backEv(i64* %result) local_unnamed_addr {
dec_label_pc_38d8:
  %rax.0.reg2mem = alloca i64, !insn.addr !1029
  %stack_var_-24 = alloca i64, align 8
  %stack_var_-32 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1030
  %1 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv(i64* %result), !insn.addr !1031
  store i64 %1, i64* %stack_var_-32, align 8, !insn.addr !1032
  %2 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEmiEl(i64* nonnull %stack_var_-32, i32 1), !insn.addr !1033
  store i64 %2, i64* %stack_var_-24, align 8, !insn.addr !1034
  %3 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEdeEv(i64* nonnull %stack_var_-24), !insn.addr !1035
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !1036
  %5 = icmp eq i64 %0, %4, !insn.addr !1036
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !1037
  br i1 %5, label %dec_label_pc_393c, label %dec_label_pc_3937, !insn.addr !1037

dec_label_pc_3937:                                ; preds = %dec_label_pc_38d8
  %6 = call i64 @__stack_chk_fail(), !insn.addr !1038
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !1038
  br label %dec_label_pc_393c, !insn.addr !1038

dec_label_pc_393c:                                ; preds = %dec_label_pc_3937, %dec_label_pc_38d8
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1039

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv, { 1, 0 }
}

define i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_393e:
  %0 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getNextEv(i64* %result), !insn.addr !1040
  ret i64 %0, !insn.addr !1041
}

define i64 @_ZN4llvm8isa_implINS_17DbgVariableRecordENS_9DbgRecordEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_395c:
  %0 = call i64 @_ZN4llvm17DbgVariableRecord7classofEPKNS_9DbgRecordE(i64* %arg1), !insn.addr !1042
  ret i64 %0, !insn.addr !1043
}

define i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_397a:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1044
}

define i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_3990:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !1045
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1045
  %3 = load i64, i64* %2, align 8, !insn.addr !1045
  ret i64 %3, !insn.addr !1046
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE18isReferenceToRangeEPKvSH_SH_(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_39a6:
  %rax.0.reg2mem = alloca i64, !insn.addr !1047
  %stack_var_-17 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1048
  %1 = call i1 @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_(i64* nonnull %stack_var_-17, i64* %arg2, i64* %arg3), !insn.addr !1049
  %2 = call i1 @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_(i64* nonnull %stack_var_-17, i64* %arg2, i64* %arg4), !insn.addr !1050
  %storemerge = zext i1 %2 to i64
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !1051
  %4 = icmp eq i64 %0, %3, !insn.addr !1051
  store i64 %storemerge, i64* %rax.0.reg2mem, !insn.addr !1052
  br i1 %4, label %dec_label_pc_3a2a, label %dec_label_pc_3a25, !insn.addr !1052

dec_label_pc_3a25:                                ; preds = %dec_label_pc_39a6
  %5 = call i64 @__stack_chk_fail(), !insn.addr !1053
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !1053
  br label %dec_label_pc_3a2a, !insn.addr !1053

dec_label_pc_3a2a:                                ; preds = %dec_label_pc_3a25, %dec_label_pc_39a6
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1054

; uselistorder directives
  uselistorder i1 (i64*, i64*, i64*)* @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_, { 1, 0 }
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_3a2c:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1055
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_3a42:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !1056
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !1057
  %2 = mul i64 %1, 32, !insn.addr !1058
  %3 = add i64 %2, %0, !insn.addr !1059
  ret i64 %3, !insn.addr !1060

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm15SmallVectorBaseIjE4sizeEv, { 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv, { 1, 0 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13mallocForGrowEmRm(i64* %result, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_3a7c:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv(i64* %result), !insn.addr !1061
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1062
  %2 = call i64 @_ZN4llvm15SmallVectorBaseIjE13mallocForGrowEPvmmRm(i64* %result, i64* %1, i64 %arg2, i64 32, i64* %arg3), !insn.addr !1062
  ret i64 %2, !insn.addr !1063
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE19moveElementsForGrowEPSE_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3aca:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !1064
  %1 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !1065
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1066
  %3 = inttoptr i64 %0 to i64*, !insn.addr !1066
  call void @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE18uninitialized_moveIPSE_SH_EEvT_SI_T0_(i64* %2, i64* %3, i64* %arg2), !insn.addr !1066
  %4 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !1067
  %5 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !1068
  %6 = inttoptr i64 %5 to i64*, !insn.addr !1069
  %7 = inttoptr i64 %4 to i64*, !insn.addr !1069
  %8 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13destroy_rangeEPSE_SG_(i64* %6, i64* %7), !insn.addr !1069
  ret i64 %8, !insn.addr !1070

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv, { 2, 1, 0 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE21takeAllocationForGrowEPSE_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_3b3c:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE7isSmallEv(i64* %result), !insn.addr !1071
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !1072
  br i1 %2, label %dec_label_pc_3b7b, label %dec_label_pc_3b67, !insn.addr !1073

dec_label_pc_3b67:                                ; preds = %dec_label_pc_3b3c
  %3 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !1074
  %4 = call i64 @free(i64 %3), !insn.addr !1075
  br label %dec_label_pc_3b7b, !insn.addr !1075

dec_label_pc_3b7b:                                ; preds = %dec_label_pc_3b67, %dec_label_pc_3b3c
  %5 = call i64 @_ZN4llvm15SmallVectorBaseIjE20set_allocation_rangeEPvm(i64* %result, i64* %arg2, i64 %arg3), !insn.addr !1076
  ret i64 %5, !insn.addr !1077

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv, { 5, 4, 3, 2, 1, 0 }
  uselistorder i8 1, { 0, 1, 2, 5, 6, 3, 7, 4 }
}

define i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_3b96:
  %0 = call i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1Ev(i64* %result), !insn.addr !1078
  %1 = call i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EEC1Ev(i64* %result), !insn.addr !1079
  ret i64 %1, !insn.addr !1080
}

define i64** @_ZSt12__get_helperILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEJSt14default_deleteIS6_EEERT0_RSt11_Tuple_implIXT_EJSA_DpT1_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_3bc1:
  %0 = call i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEE7_M_headERSA_(i64* %arg1), !insn.addr !1081
  %1 = inttoptr i64 %0 to i64**, !insn.addr !1082
  ret i64** %1, !insn.addr !1082
}

define i64* @_ZSt3getILm1EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %arg1) local_unnamed_addr {
dec_label_pc_3bdf:
  %0 = call i64* @_ZSt12__get_helperILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEJEERT0_RSt11_Tuple_implIXT_EJS9_DpT1_EE(i64* %arg1), !insn.addr !1083
  ret i64* %0, !insn.addr !1084
}

define i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3bfe:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %result, i64* %arg2), !insn.addr !1085
  ret i64 %0, !insn.addr !1086
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3c28:
  %0 = call i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EEC1EOS9_(i64* %result, i64* %arg2), !insn.addr !1087
  ret i64 %0, !insn.addr !1088
}

define i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_3c52:
  %0 = ptrtoint i64** %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !1089
  ret i64 %1, !insn.addr !1090
}

define i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12_M_check_lenEmPKc(i64* %result, i64 %arg2, i8* %arg3) local_unnamed_addr {
dec_label_pc_3c74:
  %rax.0.reg2mem = alloca i64, !insn.addr !1091
  %storemerge.reg2mem = alloca i64, !insn.addr !1091
  %stack_var_-48 = alloca i64, align 8
  %stack_var_-72 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-72, align 8, !insn.addr !1092
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1093
  %1 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result), !insn.addr !1094
  %2 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !1095
  %3 = sub i64 %1, %2, !insn.addr !1096
  %4 = icmp ult i64 %3, %arg2, !insn.addr !1097
  %5 = icmp eq i1 %4, false, !insn.addr !1098
  br i1 %5, label %dec_label_pc_3cd7, label %dec_label_pc_3ccb, !insn.addr !1099

dec_label_pc_3ccb:                                ; preds = %dec_label_pc_3c74
  %6 = call i64 @_ZSt20__throw_length_errorPKc(i8* %arg3), !insn.addr !1100
  br label %dec_label_pc_3cd7, !insn.addr !1100

dec_label_pc_3cd7:                                ; preds = %dec_label_pc_3ccb, %dec_label_pc_3c74
  %7 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !1101
  %8 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !1102
  store i64 %8, i64* %stack_var_-48, align 8, !insn.addr !1103
  %9 = call i64* @_ZSt3maxImERKT_S2_S2_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-72), !insn.addr !1104
  %10 = load i64, i64* %9, align 8, !insn.addr !1105
  %11 = add i64 %10, %7, !insn.addr !1106
  %12 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !1107
  %13 = icmp ult i64 %11, %12, !insn.addr !1108
  br i1 %13, label %dec_label_pc_3d37, label %dec_label_pc_3d25, !insn.addr !1109

dec_label_pc_3d25:                                ; preds = %dec_label_pc_3cd7
  %14 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result), !insn.addr !1110
  %15 = icmp ult i64 %14, %11, !insn.addr !1111
  %16 = icmp eq i1 %15, false, !insn.addr !1112
  store i64 %11, i64* %storemerge.reg2mem, !insn.addr !1112
  br i1 %16, label %dec_label_pc_3d49, label %dec_label_pc_3d37, !insn.addr !1112

dec_label_pc_3d37:                                ; preds = %dec_label_pc_3d25, %dec_label_pc_3cd7
  %17 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result), !insn.addr !1113
  store i64 %17, i64* %storemerge.reg2mem, !insn.addr !1114
  br label %dec_label_pc_3d49, !insn.addr !1114

dec_label_pc_3d49:                                ; preds = %dec_label_pc_3d25, %dec_label_pc_3d37
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %18 = call i64 @__readfsqword(i64 40), !insn.addr !1115
  %19 = icmp eq i64 %0, %18, !insn.addr !1115
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !1116
  br i1 %19, label %dec_label_pc_3d5d, label %dec_label_pc_3d58, !insn.addr !1116

dec_label_pc_3d58:                                ; preds = %dec_label_pc_3d49
  %20 = call i64 @__stack_chk_fail(), !insn.addr !1117
  store i64 %20, i64* %rax.0.reg2mem, !insn.addr !1117
  br label %dec_label_pc_3d5d, !insn.addr !1117

dec_label_pc_3d5d:                                ; preds = %dec_label_pc_3d58, %dec_label_pc_3d49
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1118

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*)* @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv, { 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv, { 2, 1, 0 }
  uselistorder label %dec_label_pc_3d49, { 1, 0 }
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_3d64:
  %rax.0.reg2mem = alloca i64, !insn.addr !1119
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1120
  %1 = bitcast i64* %result to i64**, !insn.addr !1121
  %2 = call i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* nonnull %stack_var_-24, i64** %1), !insn.addr !1121
  %3 = load i64, i64* %stack_var_-24, align 8, !insn.addr !1122
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !1123
  %5 = icmp eq i64 %0, %4, !insn.addr !1123
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !1124
  br i1 %5, label %dec_label_pc_3dae, label %dec_label_pc_3da9, !insn.addr !1124

dec_label_pc_3da9:                                ; preds = %dec_label_pc_3d64
  %6 = call i64 @__stack_chk_fail(), !insn.addr !1125
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !1125
  br label %dec_label_pc_3dae, !insn.addr !1125

dec_label_pc_3dae:                                ; preds = %dec_label_pc_3da9, %dec_label_pc_3d64
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1126

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
}

define i64 @_ZN9__gnu_cxxmiIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKSJ_SM_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_3db0:
  %0 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* %arg1), !insn.addr !1127
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1128
  %2 = load i64, i64* %1, align 8, !insn.addr !1128
  %3 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* %arg2), !insn.addr !1129
  %4 = inttoptr i64 %3 to i64*, !insn.addr !1130
  %5 = load i64, i64* %4, align 8, !insn.addr !1130
  %6 = sub i64 %2, %5, !insn.addr !1131
  %7 = ashr i64 %6, 3, !insn.addr !1132
  ret i64 %7, !insn.addr !1133

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv, { 3, 2, 1, 0 }
}

define i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_M_allocateEm(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_3df6:
  %storemerge.reg2mem = alloca i64, !insn.addr !1134
  %0 = icmp eq i64 %arg2, 0, !insn.addr !1135
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1136
  br i1 %0, label %dec_label_pc_3e41, label %dec_label_pc_3e11, !insn.addr !1136

dec_label_pc_3e11:                                ; preds = %dec_label_pc_3df6
  %1 = call i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE8allocateEmPKv(i64* %result, i64 %arg2, i64* null), !insn.addr !1137
  store i64 %1, i64* %storemerge.reg2mem, !insn.addr !1138
  br label %dec_label_pc_3e41, !insn.addr !1138

dec_label_pc_3e41:                                ; preds = %dec_label_pc_3df6, %dec_label_pc_3e11
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1139

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_3e41, { 1, 0 }
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_3e43:
  %0 = call i64* @_ZSt12__relocate_aIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4), !insn.addr !1140
  %1 = ptrtoint i64* %0 to i64, !insn.addr !1140
  ret i64 %1, !insn.addr !1141
}

define i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* %result) local_unnamed_addr {
dec_label_pc_3e7a:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1142
}

define i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result) local_unnamed_addr {
dec_label_pc_3e8c:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1143
}

define i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE13_M_deallocateEPSA_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_3e9e:
  %rax.0.reg2mem = alloca i64, !insn.addr !1144
  %0 = icmp eq i64* %arg2, null, !insn.addr !1145
  br i1 %0, label %dec_label_pc_3eed, label %dec_label_pc_3ebd, !insn.addr !1146

dec_label_pc_3ebd:                                ; preds = %dec_label_pc_3e9e
  %1 = call i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE10deallocateEPSA_m(i64* %result, i64* nonnull %arg2, i64 %arg3), !insn.addr !1147
  store i64 %1, i64* %rax.0.reg2mem, !insn.addr !1148
  br label %dec_label_pc_3eed, !insn.addr !1148

dec_label_pc_3eed:                                ; preds = %dec_label_pc_3ebd, %dec_label_pc_3e9e
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1149
}

define i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEmiEl(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_3ef0:
  %rax.0.reg2mem = alloca i64, !insn.addr !1150
  %0 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  %stack_var_-32 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1151
  %2 = sext i32 %arg2 to i64, !insn.addr !1152
  %3 = mul i64 %2, 8, !insn.addr !1153
  %4 = sub i64 %0, %3, !insn.addr !1154
  store i64 %4, i64* %stack_var_-32, align 8, !insn.addr !1155
  %5 = bitcast i64* %stack_var_-32 to i64**, !insn.addr !1156
  %6 = call i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* nonnull %stack_var_-24, i64** nonnull %5), !insn.addr !1156
  %7 = load i64, i64* %stack_var_-24, align 8, !insn.addr !1157
  %8 = call i64 @__readfsqword(i64 40), !insn.addr !1158
  %9 = icmp eq i64 %1, %8, !insn.addr !1158
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !1159
  br i1 %9, label %dec_label_pc_3f57, label %dec_label_pc_3f52, !insn.addr !1159

dec_label_pc_3f52:                                ; preds = %dec_label_pc_3ef0
  %10 = call i64 @__stack_chk_fail(), !insn.addr !1160
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !1160
  br label %dec_label_pc_3f57, !insn.addr !1160

dec_label_pc_3f57:                                ; preds = %dec_label_pc_3f52, %dec_label_pc_3ef0
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1161

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
  uselistorder i64 (i64*, i64**)* @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_, { 2, 1, 0 }
}

define i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_3f5a:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1162
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv(i64* %result) local_unnamed_addr {
dec_label_pc_3f70:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !1163
  ret i64 %1, !insn.addr !1164
}

define void @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE18uninitialized_moveIPSE_SH_EEvT_SI_T0_(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_3f86:
  %0 = call i64* @_ZSt18uninitialized_moveIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEESF_ET0_T_SH_SG_(i64* %arg1, i64* %arg2, i64* %arg3), !insn.addr !1165
  ret void, !insn.addr !1166
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13destroy_rangeEPSE_SG_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_3fb8:
  %stack_var_-24.01.reg2mem = alloca i64, !insn.addr !1167
  %0 = ptrtoint i64* %arg1 to i64
  %1 = icmp eq i64* %arg2, %arg1, !insn.addr !1168
  %2 = icmp eq i1 %1, false, !insn.addr !1169
  br i1 %2, label %dec_label_pc_3fce.lr.ph, label %dec_label_pc_3fe9, !insn.addr !1169

dec_label_pc_3fce.lr.ph:                          ; preds = %dec_label_pc_3fb8
  %3 = ptrtoint i64* %arg2 to i64
  store i64 %3, i64* %stack_var_-24.01.reg2mem
  br label %dec_label_pc_3fce

dec_label_pc_3fce:                                ; preds = %dec_label_pc_3fce.lr.ph, %dec_label_pc_3fce
  %stack_var_-24.01.reload = load i64, i64* %stack_var_-24.01.reg2mem
  %4 = add i64 %stack_var_-24.01.reload, -32, !insn.addr !1170
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1171
  %6 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev(i64* %5), !insn.addr !1171
  %7 = icmp eq i64 %4, %0, !insn.addr !1168
  %8 = icmp eq i1 %7, false, !insn.addr !1169
  store i64 %4, i64* %stack_var_-24.01.reg2mem, !insn.addr !1169
  br i1 %8, label %dec_label_pc_3fce, label %dec_label_pc_3fe9, !insn.addr !1169

dec_label_pc_3fe9:                                ; preds = %dec_label_pc_3fce, %dec_label_pc_3fb8
  ret i64 %0, !insn.addr !1172

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64* %stack_var_-24.01.reg2mem, { 1, 0, 2 }
  uselistorder i64 (i64*)* @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev, { 1, 0 }
  uselistorder i64 -32, { 1, 0 }
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder label %dec_label_pc_3fce, { 1, 0 }
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE7isSmallEv(i64* %result) local_unnamed_addr {
dec_label_pc_3fee:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv(i64* %result), !insn.addr !1173
  %2 = icmp eq i64 %1, %0, !insn.addr !1174
  %3 = zext i1 %2 to i64, !insn.addr !1175
  %4 = and i64 %1, -256, !insn.addr !1175
  %5 = or i64 %4, %3, !insn.addr !1175
  ret i64 %5, !insn.addr !1176

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
  uselistorder i64 -256, { 2, 0, 1, 6, 5, 4, 3 }
  uselistorder i64 (i64*)* @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv, { 1, 0 }
}

define i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_401e:
  %0 = call i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EEC1Ev(i64* %result), !insn.addr !1177
  ret i64 %0, !insn.addr !1178
}

define i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_403e:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !1179
  ret i64 %0, !insn.addr !1180
}

define i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEE7_M_headERSA_(i64* %arg1) local_unnamed_addr {
dec_label_pc_4058:
  %0 = call i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EE7_M_headERS8_(i64* %arg1), !insn.addr !1181
  ret i64 %0, !insn.addr !1182
}

define i64* @_ZSt12__get_helperILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEJEERT0_RSt11_Tuple_implIXT_EJS9_DpT1_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_4076:
  %0 = call i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEE7_M_headERS9_(i64* %arg1), !insn.addr !1183
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1184
  ret i64* %1, !insn.addr !1184
}

define i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_4094:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1EOS9_(i64* %result, i64* %arg2), !insn.addr !1185
  store i64 %0, i64* %result, align 8, !insn.addr !1186
  ret i64 %1, !insn.addr !1187
}

define i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_40cc:
  %0 = call i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %arg2), !insn.addr !1188
  ret i64 %0, !insn.addr !1189
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_40f6:
  %0 = bitcast i64* %arg2 to i64**, !insn.addr !1190
  %1 = call i64* @_ZSt4moveIRSt5tupleIJPN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEEONSt16remove_referenceIT_E4typeEOSE_(i64** %0), !insn.addr !1190
  %2 = call i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %1), !insn.addr !1191
  %3 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %arg2), !insn.addr !1192
  %4 = inttoptr i64 %3 to i64*, !insn.addr !1193
  store i64 0, i64* %4, align 8, !insn.addr !1193
  ret i64 %3, !insn.addr !1194

; uselistorder directives
  uselistorder i64 %3, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv, { 2, 1, 0 }
}

define i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result) local_unnamed_addr {
dec_label_pc_4140:
  %0 = call i64 @_ZNKSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result), !insn.addr !1195
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1196
  %2 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_max_sizeERKSB_(i64* %1), !insn.addr !1196
  ret i64 %2, !insn.addr !1197
}

define i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result) local_unnamed_addr {
dec_label_pc_4166:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !1198
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1198
  %3 = load i64, i64* %2, align 8, !insn.addr !1198
  %4 = sub i64 %3, %0, !insn.addr !1199
  %5 = ashr i64 %4, 3, !insn.addr !1200
  ret i64 %5, !insn.addr !1201

; uselistorder directives
  uselistorder i64 3, { 1, 2, 3, 0 }
}

define i64* @_ZSt12__relocate_aIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_418d:
  %0 = call i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg3), !insn.addr !1202
  %1 = call i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg2), !insn.addr !1203
  %2 = call i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg1), !insn.addr !1204
  %3 = call i64* @_ZSt14__relocate_a_1IPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %2, i64* %1, i64* %0, i64* %arg4), !insn.addr !1205
  ret i64* %3, !insn.addr !1206

; uselistorder directives
  uselistorder i64* (i64*)* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_, { 2, 1, 0 }
}

define i64* @_ZSt18uninitialized_moveIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEESF_ET0_T_SH_SG_(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_41f4:
  %0 = call i64 @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_(i64* %arg2), !insn.addr !1207
  %1 = call i64 @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_(i64* %arg1), !insn.addr !1208
  %2 = call i64* @_ZSt18uninitialized_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %1, i64 %0, i64* %arg3), !insn.addr !1209
  ret i64* %2, !insn.addr !1210

; uselistorder directives
  uselistorder i64 (i64*)* @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_, { 1, 0 }
}

define i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_4244:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !1211
}

define i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EE7_M_headERS8_(i64* %arg1) local_unnamed_addr {
dec_label_pc_4253:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !1212
}

define i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEE7_M_headERS9_(i64* %arg1) local_unnamed_addr {
dec_label_pc_4265:
  %0 = call i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EE7_M_headERS9_(i64* %arg1), !insn.addr !1213
  ret i64 %0, !insn.addr !1214
}

define i64* @_ZSt4moveIRSt5tupleIJPN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEEONSt16remove_referenceIT_E4typeEOSE_(i64** %arg1) local_unnamed_addr {
dec_label_pc_4283:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !1215
  ret i64* %0, !insn.addr !1215
}

define i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_4296:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !1216
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_max_sizeERKSB_(i64* %arg1) local_unnamed_addr {
dec_label_pc_42a9:
  %rax.0.reg2mem = alloca i64, !insn.addr !1217
  %stack_var_-48 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1218
  store i64 1152921504606846975, i64* %stack_var_-56, align 8, !insn.addr !1219
  store i64 1152921504606846975, i64* %stack_var_-48, align 8, !insn.addr !1220
  %1 = call i64* @_ZSt3minImERKT_S2_S2_(i64* nonnull %stack_var_-56, i64* nonnull %stack_var_-48), !insn.addr !1221
  %2 = load i64, i64* %1, align 8, !insn.addr !1222
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !1223
  %4 = icmp eq i64 %0, %3, !insn.addr !1223
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !1224
  br i1 %4, label %dec_label_pc_4328, label %dec_label_pc_4323, !insn.addr !1224

dec_label_pc_4323:                                ; preds = %dec_label_pc_42a9
  %5 = call i64 @__stack_chk_fail(), !insn.addr !1225
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !1225
  br label %dec_label_pc_4328, !insn.addr !1225

dec_label_pc_4328:                                ; preds = %dec_label_pc_4323, %dec_label_pc_42a9
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1226

; uselistorder directives
  uselistorder i64* (i64*, i64*)* @_ZSt3minImERKT_S2_S2_, { 0, 2, 1 }
}

define i64 @_ZNKSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result) local_unnamed_addr {
dec_label_pc_432a:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1227
}

define i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE8allocateEmPKv(i64* %result, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_433c:
  %0 = icmp ugt i64 %arg2, 1152921504606846975, !insn.addr !1228
  %1 = icmp eq i1 %0, false, !insn.addr !1229
  %2 = icmp eq i1 %1, false, !insn.addr !1230
  %3 = icmp eq i1 %2, false, !insn.addr !1231
  br i1 %3, label %dec_label_pc_4394, label %dec_label_pc_437a, !insn.addr !1232

dec_label_pc_437a:                                ; preds = %dec_label_pc_433c
  %4 = icmp ugt i64 %arg2, 2305843009213693951, !insn.addr !1233
  %5 = icmp eq i1 %4, false, !insn.addr !1234
  br i1 %5, label %dec_label_pc_438f, label %dec_label_pc_438a, !insn.addr !1234

dec_label_pc_438a:                                ; preds = %dec_label_pc_437a
  %6 = call i64 @_ZSt28__throw_bad_array_new_lengthv(), !insn.addr !1235
  br label %dec_label_pc_438f, !insn.addr !1235

dec_label_pc_438f:                                ; preds = %dec_label_pc_438a, %dec_label_pc_437a
  %7 = call i64 @_ZSt17__throw_bad_allocv(), !insn.addr !1236
  br label %dec_label_pc_4394, !insn.addr !1236

dec_label_pc_4394:                                ; preds = %dec_label_pc_438f, %dec_label_pc_433c
  %8 = mul i64 %arg2, 8, !insn.addr !1237
  %9 = call i64 @_Znwm(i64 %8), !insn.addr !1238
  ret i64 %9, !insn.addr !1239

; uselistorder directives
  uselistorder i64 (i64)* @_Znwm, { 1, 0 }
}

define i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg1) local_unnamed_addr {
dec_label_pc_43a7:
  ret i64* %arg1, !insn.addr !1240
}

define i64* @_ZSt14__relocate_a_1IPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_43b9:
  %storemerge.lcssa.reg2mem = alloca i64, !insn.addr !1241
  %stack_var_-48.01.reg2mem = alloca i64, !insn.addr !1241
  %storemerge2.reg2mem = alloca i64, !insn.addr !1241
  %0 = ptrtoint i64* %arg3 to i64
  %1 = icmp eq i64* %arg1, %arg2, !insn.addr !1242
  %2 = icmp eq i1 %1, false, !insn.addr !1243
  store i64 %0, i64* %storemerge.lcssa.reg2mem, !insn.addr !1243
  br i1 %2, label %dec_label_pc_43e0.lr.ph, label %dec_label_pc_4424, !insn.addr !1243

dec_label_pc_43e0.lr.ph:                          ; preds = %dec_label_pc_43b9
  %3 = ptrtoint i64* %arg2 to i64
  %4 = ptrtoint i64* %arg1 to i64
  store i64 %0, i64* %storemerge2.reg2mem
  store i64 %4, i64* %stack_var_-48.01.reg2mem
  br label %dec_label_pc_43e0

dec_label_pc_43e0:                                ; preds = %dec_label_pc_43e0.lr.ph, %dec_label_pc_43e0
  %stack_var_-48.01.reload = load i64, i64* %stack_var_-48.01.reg2mem
  %storemerge2.reload = load i64, i64* %storemerge2.reg2mem
  %5 = inttoptr i64 %stack_var_-48.01.reload to i64*, !insn.addr !1244
  %6 = call i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %5), !insn.addr !1244
  %7 = inttoptr i64 %storemerge2.reload to i64*, !insn.addr !1245
  %8 = call i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %7), !insn.addr !1245
  call void @_ZSt19__relocate_object_aISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESA_SaISA_EEvPT_PT0_RT1_(i64* %8, i64* %6, i64* %arg4), !insn.addr !1246
  %9 = add i64 %stack_var_-48.01.reload, 8, !insn.addr !1247
  %10 = add i64 %storemerge2.reload, 8, !insn.addr !1248
  %11 = icmp eq i64 %9, %3, !insn.addr !1242
  %12 = icmp eq i1 %11, false, !insn.addr !1243
  store i64 %10, i64* %storemerge2.reg2mem, !insn.addr !1243
  store i64 %9, i64* %stack_var_-48.01.reg2mem, !insn.addr !1243
  store i64 %10, i64* %storemerge.lcssa.reg2mem, !insn.addr !1243
  br i1 %12, label %dec_label_pc_43e0, label %dec_label_pc_4424, !insn.addr !1243

dec_label_pc_4424:                                ; preds = %dec_label_pc_43e0, %dec_label_pc_43b9
  %storemerge.lcssa.reload = load i64, i64* %storemerge.lcssa.reg2mem
  %13 = inttoptr i64 %storemerge.lcssa.reload to i64*, !insn.addr !1249
  ret i64* %13, !insn.addr !1249

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64* %storemerge2.reg2mem, { 1, 0, 2 }
  uselistorder i64* %stack_var_-48.01.reg2mem, { 1, 0, 2 }
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder i64* %arg1, { 1, 0 }
  uselistorder label %dec_label_pc_43e0, { 1, 0 }
}

define i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE10deallocateEPSA_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_442e:
  %0 = mul i64 %arg3, 8, !insn.addr !1250
  %1 = call i64 @_ZdlPvm(i64* %arg2, i64 %0), !insn.addr !1251
  ret i64 %1, !insn.addr !1252
}

define i64 @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_(i64* %arg1) local_unnamed_addr {
dec_label_pc_4463:
  %rax.0.reg2mem = alloca i64, !insn.addr !1253
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-24 = alloca i64, align 8
  %stack_var_-32 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-32, align 8, !insn.addr !1254
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1255
  %2 = bitcast i64* %stack_var_-32 to i64***, !insn.addr !1256
  %3 = call i64* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_(i64*** nonnull %2), !insn.addr !1256
  %4 = load i64, i64* %3, align 8, !insn.addr !1257
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1258
  %6 = call i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEC1ESF_(i64* nonnull %stack_var_-24, i64* %5), !insn.addr !1258
  %7 = load i64, i64* %stack_var_-24, align 8, !insn.addr !1259
  %8 = call i64 @__readfsqword(i64 40), !insn.addr !1260
  %9 = icmp eq i64 %1, %8, !insn.addr !1260
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !1261
  br i1 %9, label %dec_label_pc_44b8, label %dec_label_pc_44b3, !insn.addr !1261

dec_label_pc_44b3:                                ; preds = %dec_label_pc_4463
  %10 = call i64 @__stack_chk_fail(), !insn.addr !1262
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !1262
  br label %dec_label_pc_44b8, !insn.addr !1262

dec_label_pc_44b8:                                ; preds = %dec_label_pc_44b3, %dec_label_pc_4463
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1263

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
}

define i64* @_ZSt18uninitialized_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %arg1, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_44ba:
  %0 = call i64* @_ZNSt20__uninitialized_copyILb0EE13__uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS4_11PassManagerINS4_6ModuleENS4_15AnalysisManagerIS7_JEEEJEEENS4_8ArrayRefINS4_11PassBuilder15PipelineElementEEEEEESI_EET0_T_SL_SK_(i64 %arg1, i64 %arg2, i64* %arg3), !insn.addr !1264
  ret i64* %0, !insn.addr !1265
}

define i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EE7_M_headERS9_(i64* %arg1) local_unnamed_addr {
dec_label_pc_44f3:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !1266
}

define i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %arg1) local_unnamed_addr {
dec_label_pc_4505:
  ret i64* %arg1, !insn.addr !1267
}

define void @_ZSt19__relocate_object_aISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESA_SaISA_EEvPT_PT0_RT1_(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_4517:
  %0 = bitcast i64* %arg2 to i64**, !insn.addr !1268
  %1 = call i64* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_(i64** %0), !insn.addr !1268
  %2 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %1), !insn.addr !1269
  %3 = call i64 @_ZnwmPv(i64 8, i64* %arg1), !insn.addr !1270
  %4 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %2), !insn.addr !1271
  %5 = inttoptr i64 %3 to i64*, !insn.addr !1272
  %6 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %5, i64* %4), !insn.addr !1272
  %7 = call i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %arg2), !insn.addr !1273
  %8 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev(i64* %7), !insn.addr !1274
  ret void, !insn.addr !1275

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev, { 1, 0 }
  uselistorder i64* (i64*)* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_, { 2, 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_, { 2, 1, 0 }
  uselistorder i64* (i64*)* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE, { 7, 6, 5, 4, 3, 1, 0, 2 }
  uselistorder i64* (i64**)* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_, { 1, 0 }
}

define i64* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_(i64*** %arg1) local_unnamed_addr {
dec_label_pc_45da:
  %0 = bitcast i64*** %arg1 to i64*, !insn.addr !1276
  ret i64* %0, !insn.addr !1276
}

define i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEC1ESF_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_45ec:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-24, align 8, !insn.addr !1277
  %2 = bitcast i64* %stack_var_-24 to i64***, !insn.addr !1278
  %3 = call i64* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_(i64*** nonnull %2), !insn.addr !1278
  %4 = load i64, i64* %3, align 8, !insn.addr !1279
  store i64 %4, i64* %result, align 8, !insn.addr !1280
  ret i64 %1, !insn.addr !1281

; uselistorder directives
  uselistorder i64* (i64***)* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_, { 1, 0 }
}

define i64* @_ZNSt20__uninitialized_copyILb0EE13__uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS4_11PassManagerINS4_6ModuleENS4_15AnalysisManagerIS7_JEEEJEEENS4_8ArrayRefINS4_11PassBuilder15PipelineElementEEEEEESI_EET0_T_SL_SK_(i64 %arg1, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_4619:
  %0 = call i64* @_ZSt16__do_uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %arg1, i64 %arg2, i64* %arg3), !insn.addr !1282
  ret i64* %0, !insn.addr !1283
}

define i64* @_ZSt16__do_uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %arg1, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_464a:
  %storemerge.lcssa.reg2mem = alloca i64, !insn.addr !1284
  %storemerge1.reg2mem = alloca i64, !insn.addr !1284
  %0 = ptrtoint i64* %arg3 to i64
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-48 = alloca i64, align 8
  store i64 %arg1, i64* %stack_var_-48, align 8, !insn.addr !1285
  store i64 %arg2, i64* %stack_var_-56, align 8, !insn.addr !1286
  %1 = call i1 @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-56), !insn.addr !1287
  %2 = icmp eq i1 %1, false, !insn.addr !1288
  %3 = icmp eq i1 %2, false, !insn.addr !1289
  store i64 %0, i64* %storemerge1.reg2mem, !insn.addr !1289
  store i64 %0, i64* %storemerge.lcssa.reg2mem, !insn.addr !1289
  br i1 %3, label %dec_label_pc_466d, label %dec_label_pc_46bb, !insn.addr !1289

dec_label_pc_466d:                                ; preds = %dec_label_pc_464a, %dec_label_pc_466d
  %storemerge1.reload = load i64, i64* %storemerge1.reg2mem
  %4 = call i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEdeEv(i64* nonnull %stack_var_-48), !insn.addr !1290
  %5 = inttoptr i64 %storemerge1.reload to i64*, !insn.addr !1291
  %6 = call i64* @_ZSt11__addressofISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEPT_RSF_(i64* %5), !insn.addr !1291
  call void @_ZSt10_ConstructISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEJSE_EEvPT_DpOT0_(i64* %6, i64 %4), !insn.addr !1292
  %7 = call i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEppEv(i64* nonnull %stack_var_-48), !insn.addr !1293
  %8 = add i64 %storemerge1.reload, 32, !insn.addr !1294
  %9 = call i1 @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-56), !insn.addr !1287
  %10 = icmp eq i1 %9, false, !insn.addr !1288
  %11 = icmp eq i1 %10, false, !insn.addr !1289
  store i64 %8, i64* %storemerge1.reg2mem, !insn.addr !1289
  store i64 %8, i64* %storemerge.lcssa.reg2mem, !insn.addr !1289
  br i1 %11, label %dec_label_pc_466d, label %dec_label_pc_46bb, !insn.addr !1289

dec_label_pc_46bb:                                ; preds = %dec_label_pc_466d, %dec_label_pc_464a
  %storemerge.lcssa.reload = load i64, i64* %storemerge.lcssa.reg2mem
  %12 = inttoptr i64 %storemerge.lcssa.reload to i64*, !insn.addr !1295
  ret i64* %12, !insn.addr !1295

; uselistorder directives
  uselistorder i64 %storemerge1.reload, { 1, 0 }
  uselistorder i64* %stack_var_-48, { 1, 2, 3, 0, 4 }
  uselistorder i64* %stack_var_-56, { 1, 0, 2 }
  uselistorder i64* %storemerge1.reg2mem, { 2, 0, 1 }
  uselistorder i1 (i64*, i64*)* @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_, { 1, 0 }
  uselistorder label %dec_label_pc_466d, { 1, 0 }
}

define i1 @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_46c5:
  %0 = call i1 @_ZSteqIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* %arg1, i64* %arg2), !insn.addr !1296
  %1 = icmp ne i1 %0, true, !insn.addr !1297
  ret i1 %1, !insn.addr !1298

; uselistorder directives
  uselistorder i1 true, { 2, 0, 1 }
}

define i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEppEv(i64* %result) local_unnamed_addr {
dec_label_pc_46f2:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !1299
  store i64 %1, i64* %result, align 8, !insn.addr !1300
  ret i64 %0, !insn.addr !1301
}

define i64* @_ZSt11__addressofISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEPT_RSF_(i64* %arg1) local_unnamed_addr {
dec_label_pc_4716:
  ret i64* %arg1, !insn.addr !1302
}

define i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_4728:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1303
}

define void @_ZSt10_ConstructISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEJSE_EEvPT_DpOT0_(i64* %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_473d:
  %0 = call i64 @_ZnwmPv(i64 32, i64* %arg1), !insn.addr !1304
  %1 = inttoptr i64 %arg2 to i64*, !insn.addr !1305
  %2 = call i64* @_ZSt7forwardISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEOT_RNSt16remove_referenceISF_E4typeE(i64* %1), !insn.addr !1305
  %3 = inttoptr i64 %0 to i64*, !insn.addr !1306
  %4 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1EOSD_(i64* %3, i64* %2), !insn.addr !1306
  ret void, !insn.addr !1307

; uselistorder directives
  uselistorder i64 (i64, i64*)* @_ZnwmPv, { 5, 2, 1, 0, 4, 6, 3 }
  uselistorder i64 32, { 2, 7, 8, 3, 0, 1, 4, 9, 5, 12, 10, 6, 11 }
}

define i1 @_ZSteqIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_4784:
  %0 = call i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv(i64* %arg1), !insn.addr !1308
  %1 = call i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv(i64* %arg2), !insn.addr !1309
  %2 = icmp eq i64 %0, %1, !insn.addr !1310
  ret i1 %2, !insn.addr !1311

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv, { 1, 0 }
}

define i64* @_ZSt7forwardISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEOT_RNSt16remove_referenceISF_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_47c0:
  ret i64* %arg1, !insn.addr !1312
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1EOSD_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_47d2:
  %0 = alloca i128
  %rax.0.reg2mem = alloca i64, !insn.addr !1313
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %arg2 to i64
  %3 = ptrtoint i64* %result to i64
  %4 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !1314
  %5 = bitcast i64* %rdi to i128*
  %6 = load i128, i128* %5, align 8, !insn.addr !1315
  call void @__asm_movups(i128 %6, i128 %4), !insn.addr !1315
  %7 = add i64 %3, 16, !insn.addr !1316
  %8 = inttoptr i64 %7 to i64*, !insn.addr !1316
  %9 = load i64, i64* %8, align 8, !insn.addr !1316
  call void @__asm_movq(i64 %9, i128 %4), !insn.addr !1316
  %10 = call i64 @_ZNSt14_Function_baseC1Ev(i64* %result), !insn.addr !1317
  %11 = add i64 %2, 24, !insn.addr !1318
  %12 = inttoptr i64 %11 to i64*, !insn.addr !1318
  %13 = load i64, i64* %12, align 8, !insn.addr !1318
  %14 = add i64 %3, 24, !insn.addr !1319
  %15 = inttoptr i64 %14 to i64*, !insn.addr !1319
  store i64 %13, i64* %15, align 8, !insn.addr !1319
  %16 = call i64 @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv(i64* %arg2), !insn.addr !1320
  %17 = trunc i64 %16 to i8, !insn.addr !1321
  %18 = icmp eq i8 %17, 0, !insn.addr !1321
  store i64 %16, i64* %rax.0.reg2mem, !insn.addr !1322
  br i1 %18, label %dec_label_pc_4860, label %dec_label_pc_4822, !insn.addr !1322

dec_label_pc_4822:                                ; preds = %dec_label_pc_47d2
  %19 = add i64 %2, 8, !insn.addr !1323
  %20 = inttoptr i64 %19 to i64*, !insn.addr !1323
  %21 = load i64, i64* %20, align 8, !insn.addr !1323
  store i64 %2, i64* %result, align 8, !insn.addr !1324
  %22 = add i64 %3, 8, !insn.addr !1325
  %23 = inttoptr i64 %22 to i64*, !insn.addr !1325
  store i64 %21, i64* %23, align 8, !insn.addr !1325
  %24 = add i64 %2, 16, !insn.addr !1326
  %25 = inttoptr i64 %24 to i64*, !insn.addr !1326
  %26 = load i64, i64* %25, align 8, !insn.addr !1326
  store i64 %26, i64* %8, align 8, !insn.addr !1327
  store i64 0, i64* %25, align 8, !insn.addr !1328
  store i64 0, i64* %12, align 8, !insn.addr !1329
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !1329
  br label %dec_label_pc_4860, !insn.addr !1329

dec_label_pc_4860:                                ; preds = %dec_label_pc_4822, %dec_label_pc_47d2
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1330

; uselistorder directives
  uselistorder i128 %4, { 1, 0 }
  uselistorder i8 0, { 6, 7, 8, 3, 4, 13, 12, 14, 9, 10, 5, 1, 11, 2, 0 }
  uselistorder i64 (i64*)* @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv, { 1, 0 }
  uselistorder i64 24, { 3, 4, 5, 6, 8, 9, 0, 10, 1, 11, 12, 13, 14, 7, 2 }
  uselistorder i64 (i64*)* @_ZNSt14_Function_baseC1Ev, { 2, 1, 0 }
  uselistorder void (i128, i128)* @__asm_movups, { 0, 1, 3, 4, 5, 6, 7, 2 }
  uselistorder i128 (i128, i128)* @__asm_pxor, { 0, 1, 3, 2 }
}

define i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv(i64* %result) local_unnamed_addr {
dec_label_pc_4864:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1331
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_48c0:
  %0 = load i64, i64* inttoptr (i64 18647 to i64*), align 8, !insn.addr !1332
  %1 = add i64 %0, 16, !insn.addr !1333
  store i64 %1, i64* %result, align 8, !insn.addr !1334
  %2 = call i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result), !insn.addr !1335
  ret i64 %2, !insn.addr !1336

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev, { 1, 0 }
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEED0Ev(i64* %result) local_unnamed_addr {
dec_label_pc_48f2:
  %0 = call i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result), !insn.addr !1337
  %1 = call i64 @_ZdlPvm(i64* %result, i64 16), !insn.addr !1338
  ret i64 %1, !insn.addr !1339

; uselistorder directives
  uselistorder i64 (i64*, i64)* @_ZdlPvm, { 2, 0, 1 }
  uselistorder i64 16, { 0, 2, 9, 10, 11, 18, 19, 22, 21, 3, 20, 13, 14, 1, 15, 24, 23, 12, 16, 25, 26, 27, 4, 28, 29, 5, 6, 7, 30, 31, 32, 17, 8 }
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEE3runERS2_RS6_(i64* %this, i64* %result, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_4a80:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1340
  %2 = add i64 %0, 8, !insn.addr !1341
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1342
  %4 = call i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass3runERN4llvm6ModuleERNS1_15AnalysisManagerIS2_JEEE(i64* %this, i64* %3, i64* %arg3, i64* %arg4), !insn.addr !1342
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !1343
  %6 = icmp eq i64 %1, %5, !insn.addr !1343
  br i1 %6, label %dec_label_pc_4adb, label %dec_label_pc_4ad6, !insn.addr !1344

dec_label_pc_4ad6:                                ; preds = %dec_label_pc_4a80
  %7 = call i64 @__stack_chk_fail(), !insn.addr !1345
  br label %dec_label_pc_4adb, !insn.addr !1345

dec_label_pc_4adb:                                ; preds = %dec_label_pc_4ad6, %dec_label_pc_4a80
  %8 = ptrtoint i64* %this to i64
  ret i64 %8, !insn.addr !1346

; uselistorder directives
  uselistorder i64* %this, { 1, 0 }
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEE13printPipelineERNS_11raw_ostreamENS_12function_refIFNS_9StringRefESB_EEE(i64* %this, i64* %result, i64* %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_4ae2:
  %0 = ptrtoint i64* %this to i64
  %1 = add i64 %0, 8, !insn.addr !1347
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1348
  %3 = call i64 @_ZN4llvm13PassInfoMixinIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEE13printPipelineERNS_11raw_ostreamENS_12function_refIFNS_9StringRefES7_EEE(i64* %2, i64* %result, i64* %arg3, i64 %arg4), !insn.addr !1348
  ret i64 %3, !insn.addr !1349
}

define i64 @_ZNK4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEE4nameEv(i64* %result) local_unnamed_addr {
dec_label_pc_4b20:
  %0 = call i64 @_ZN4llvm13PassInfoMixinIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEE4nameEv(), !insn.addr !1350
  ret i64 %0, !insn.addr !1351
}

define i64 @_ZNK4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEE10isRequiredEv(i64* %result) local_unnamed_addr {
dec_label_pc_4b38:
  %0 = call i1 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEE18passIsRequiredImplIS4_EEbv(), !insn.addr !1352
  %1 = sext i1 %0 to i64, !insn.addr !1352
  ret i64 %1, !insn.addr !1353
}

define i64 @_ZN4llvm13PassInfoMixinIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEE13printPipelineERNS_11raw_ostreamENS_12function_refIFNS_9StringRefES7_EEE(i64* %this, i64* %result, i64* %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_4b50:
  %rax.0.reg2mem = alloca i64, !insn.addr !1354
  %0 = ptrtoint i64* %arg3 to i64
  %stack_var_-88 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-88, align 8, !insn.addr !1355
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1356
  %2 = call i64 @_ZN4llvm13PassInfoMixinIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEE4nameEv(), !insn.addr !1357
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1358
  %4 = call i64 @_ZNK4llvm12function_refIFNS_9StringRefES1_EEclES1_(i64* nonnull %stack_var_-88, i64* %3, i64 %0), !insn.addr !1358
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1359
  %6 = call i64 @_ZN4llvm11raw_ostreamlsENS_9StringRefE(i64* %result, i64* %5, i64 %0), !insn.addr !1359
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !1360
  %8 = icmp eq i64 %1, %7, !insn.addr !1360
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1361
  br i1 %8, label %dec_label_pc_4bd3, label %dec_label_pc_4bce, !insn.addr !1361

dec_label_pc_4bce:                                ; preds = %dec_label_pc_4b50
  %9 = call i64 @__stack_chk_fail(), !insn.addr !1362
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !1362
  br label %dec_label_pc_4bd3, !insn.addr !1362

dec_label_pc_4bd3:                                ; preds = %dec_label_pc_4bce, %dec_label_pc_4b50
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1363
}

define i64 @_ZN4llvm13PassInfoMixinIN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassEE4nameEv() local_unnamed_addr {
dec_label_pc_4bd5:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !1364
  %1 = load i64, i64* %0
  %stack_var_-40 = alloca i64, align 8
  %stack_var_-56 = alloca i8*, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !1365
  store i8* getelementptr inbounds ([50 x i8], [50 x i8]* @global_var_1986, i64 0, i64 0), i8** %stack_var_-56, align 8, !insn.addr !1366
  %3 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-40, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @global_var_19b8, i64 0, i64 0)), !insn.addr !1367
  %4 = load i64, i64* %stack_var_-40, align 8, !insn.addr !1368
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1369
  %6 = bitcast i8** %stack_var_-56 to i64*, !insn.addr !1369
  %7 = call i64 @_ZN4llvm9StringRef13consume_frontES0_(i64* nonnull %6, i64* %5, i64 %1), !insn.addr !1369
  %8 = load i8*, i8** %stack_var_-56, align 8, !insn.addr !1370
  %9 = ptrtoint i8* %8 to i64, !insn.addr !1370
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !1371
  %11 = icmp eq i64 %2, %10, !insn.addr !1371
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !1372
  br i1 %11, label %dec_label_pc_4c4c, label %dec_label_pc_4c47, !insn.addr !1372

dec_label_pc_4c47:                                ; preds = %dec_label_pc_4bd5
  %12 = call i64 @__stack_chk_fail(), !insn.addr !1373
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !1373
  br label %dec_label_pc_4c4c, !insn.addr !1373

dec_label_pc_4c4c:                                ; preds = %dec_label_pc_4c47, %dec_label_pc_4bd5
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1374

; uselistorder directives
  uselistorder i8** %stack_var_-56, { 1, 2, 0 }
  uselistorder i64* %stack_var_-40, { 1, 0 }
  uselistorder i64 ()* @__stack_chk_fail, { 31, 30, 29, 26, 21, 20, 19, 18, 24, 17, 16, 15, 23, 25, 11, 14, 7, 10, 9, 13, 6, 8, 28, 4, 3, 2, 1, 27, 22, 12, 5, 0 }
  uselistorder i64 (i64*, i8*)* @_ZN4llvm9StringRefC1EPKc, { 1, 0 }
  uselistorder i64 0, { 22, 23, 24, 25, 0, 46, 47, 56, 57, 1, 58, 26, 27, 2, 49, 28, 59, 60, 50, 14, 3, 51, 52, 53, 29, 4, 15, 16, 44, 5, 6, 7, 61, 8, 9, 45, 48, 21, 54, 17, 30, 18, 19, 20, 10, 55, 11, 12, 31, 32, 33, 34, 35, 36, 37, 38, 13, 39, 40, 41, 42, 43 }
  uselistorder i64 40, { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 65, 42, 43, 44, 45, 66, 64, 67, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63 }
}

define i1 @_ZN4llvm6detail9PassModelINS_6ModuleEN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPassENS_15AnalysisManagerIS2_JEEEJEE18passIsRequiredImplIS4_EEbv() local_unnamed_addr {
dec_label_pc_4c4e:
  ret i1 false, !insn.addr !1375

; uselistorder directives
  uselistorder i1 false, { 1, 26, 9, 4, 5, 31, 6, 32, 10, 33, 11, 27, 7, 36, 12, 13, 28, 14, 29, 15, 30, 43, 16, 2, 24, 25, 0, 47, 35, 37, 39, 40, 41, 42, 17, 45, 46, 44, 8, 48, 18, 21, 19, 38, 22, 23, 34, 20, 3, 49, 50, 51, 52, 53, 54, 55, 56 }
}

define i64 @_ZNK4llvm12function_refIFNS_9StringRefES1_EEclES1_(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_4c5e:
  %0 = ptrtoint i64* %result to i64
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-56, align 8, !insn.addr !1376
  %1 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* nonnull %stack_var_-56), !insn.addr !1377
  %2 = ptrtoint i64* %1 to i64, !insn.addr !1377
  %3 = add i64 %2, 8, !insn.addr !1378
  %4 = inttoptr i64 %3 to i64*, !insn.addr !1378
  %5 = load i64, i64* %4, align 8, !insn.addr !1378
  ret i64 %5, !insn.addr !1379

; uselistorder directives
  uselistorder i64 8, { 14, 15, 16, 29, 30, 10, 0, 32, 33, 1, 34, 2, 21, 3, 35, 11, 4, 36, 37, 38, 12, 39, 42, 43, 22, 13, 48, 49, 50, 31, 51, 52, 44, 45, 46, 47, 5, 6, 54, 53, 7, 8, 9, 55, 17, 40, 18, 41, 19, 20, 56, 57, 58, 23, 59, 60, 24, 25, 26, 27, 61, 62, 63, 28 }
  uselistorder i64* (i64*)* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE, { 3, 2, 1, 0 }
  uselistorder i32 1, { 80, 79, 81, 11, 10, 82, 12, 78, 13, 3, 84, 83, 15, 14, 85, 87, 86, 16, 19, 18, 17, 89, 88, 20, 9, 8, 21, 91, 90, 22, 23, 24, 92, 25, 94, 93, 27, 26, 95, 28, 73, 97, 96, 29, 99, 98, 100, 30, 101, 31, 32, 102, 33, 103, 77, 34, 2, 104, 35, 105, 36, 107, 106, 108, 37, 109, 38, 39, 40, 7, 110, 42, 41, 111, 76, 1, 45, 44, 43, 48, 47, 46, 49, 74, 115, 114, 113, 112, 53, 52, 51, 50, 54, 116, 55, 118, 117, 56, 119, 57, 123, 122, 121, 120, 58, 124, 59, 60, 61, 6, 5, 62, 125, 70, 126, 128, 127, 71, 130, 129, 132, 131, 134, 133, 75, 63, 0, 136, 135, 138, 137, 140, 139, 148, 142, 141, 64, 143, 66, 65, 4, 149, 68, 67, 72, 69, 147, 146, 145, 144 }
}

declare i64 @strlen(i64) local_unnamed_addr

declare i64 @memcmp(i64, i64, i64) local_unnamed_addr

declare i64 @__stack_chk_fail() local_unnamed_addr

declare i64 @_ZN4llvm11raw_ostream5writeEPKcm(i64*, i8*, i64) local_unnamed_addr

declare i64 @memcpy(i64, i64, i64) local_unnamed_addr

declare i64 @__assert_fail(i64, i64, i64, i64) local_unnamed_addr

declare i64 @_ZN4llvm19SmallPtrSetImplBase14insert_imp_bigEPKv(i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm25llvm_unreachable_internalEPKcS1_j(i8*, i8*, i32) local_unnamed_addr

declare i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass27FoldReadonlyVolatileGlobalsERN4llvm6ModuleE(i64*) local_unnamed_addr

declare i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass25ForwardNumericGlobalSeedsERN4llvm6ModuleE(i64*) local_unnamed_addr

declare i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass11SimplifyMBAERN4llvm6ModuleE(i64*) local_unnamed_addr

declare i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass30CanonicalizeObfuscatedComparesERN4llvm6ModuleE(i64*) local_unnamed_addr

declare i64 @_ZN22deobfuscate_opaque_mba24DeobfuscateOpaqueMBAPass18EliminateDeadPathsERN4llvm6ModuleE(i64*) local_unnamed_addr

declare i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjE8set_sizeEm(i64*, i64) local_unnamed_addr

declare i64 @_Znwm(i64) local_unnamed_addr

declare i64 @_ZdlPvm(i64*, i64) local_unnamed_addr

declare i64 @_ZNK4llvm15SmallVectorBaseIjE8capacityEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjE13mallocForGrowEPvmmRm(i64*, i64*, i64, i64, i64*) local_unnamed_addr

declare i64 @free(i64) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjE20set_allocation_rangeEPvm(i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZSt20__throw_length_errorPKc(i8*) local_unnamed_addr

declare i64 @_ZSt28__throw_bad_array_new_lengthv() local_unnamed_addr

declare i64 @_ZSt17__throw_bad_allocv() local_unnamed_addr

declare i128 @__asm_pxor(i128, i128) local_unnamed_addr

declare void @__asm_movups(i128, i128) local_unnamed_addr

declare void @__asm_movq(i64, i128) local_unnamed_addr

declare i64 @__readfsqword(i64) local_unnamed_addr

!0 = !{i64 23}
!1 = !{i64 29}
!2 = !{i64 59}
!3 = !{i64 94}
!4 = !{i64 143}
!5 = !{i64 146}
!6 = !{i64 172}
!7 = !{i64 215}
!8 = !{i64 218}
!9 = !{i64 313}
!10 = !{i64 327}
!11 = !{i64 336}
!12 = !{i64 338}
!13 = !{i64 351}
!14 = !{i64 352}
!15 = !{i64 370}
!16 = !{i64 373}
!17 = !{i64 378}
!18 = !{i64 413}
!19 = !{i64 454}
!20 = !{i64 460}
!21 = !{i64 462}
!22 = !{i64 490}
!23 = !{i64 532}
!24 = !{i64 540}
!25 = !{i64 543}
!26 = !{i64 545}
!27 = !{i64 548}
!28 = !{i64 558}
!29 = !{i64 566}
!30 = !{i64 569}
!31 = !{i64 571}
!32 = !{i64 574}
!33 = !{i64 584}
!34 = !{i64 592}
!35 = !{i64 595}
!36 = !{i64 597}
!37 = !{i64 600}
!38 = !{i64 610}
!39 = !{i64 618}
!40 = !{i64 621}
!41 = !{i64 623}
!42 = !{i64 626}
!43 = !{i64 636}
!44 = !{i64 644}
!45 = !{i64 647}
!46 = !{i64 649}
!47 = !{i64 652}
!48 = !{i64 662}
!49 = !{i64 670}
!50 = !{i64 673}
!51 = !{i64 675}
!52 = !{i64 678}
!53 = !{i64 685}
!54 = !{i64 691}
!55 = !{i64 693}
!56 = !{i64 708}
!57 = !{i64 710}
!58 = !{i64 718}
!59 = !{i64 727}
!60 = !{i64 731}
!61 = !{i64 740}
!62 = !{i64 745}
!63 = !{i64 754}
!64 = !{i64 763}
!65 = !{i64 772}
!66 = !{i64 774}
!67 = !{i64 784}
!68 = !{i64 786}
!69 = !{i64 827}
!70 = !{i64 859}
!71 = !{i64 864}
!72 = !{i64 886}
!73 = !{i64 891}
!74 = !{i64 893}
!75 = !{i64 909}
!76 = !{i64 919}
!77 = !{i64 930}
!78 = !{i64 939}
!79 = !{i64 941}
!80 = !{i64 947}
!81 = !{i64 948}
!82 = !{i64 964}
!83 = !{i64 993}
!84 = !{i64 1012}
!85 = !{i64 1024}
!86 = !{i64 1034}
!87 = !{i64 1043}
!88 = !{i64 1045}
!89 = !{i64 1051}
!90 = !{i64 1080}
!91 = !{i64 1086}
!92 = !{i64 1103}
!93 = !{i64 1120}
!94 = !{i64 1135}
!95 = !{i64 1150}
!96 = !{i64 1159}
!97 = !{i64 1180}
!98 = !{i64 1202}
!99 = !{i64 1218}
!100 = !{i64 1242}
!101 = !{i64 1245}
!102 = !{i64 1265}
!103 = !{i64 1268}
!104 = !{i64 1340}
!105 = !{i64 1354}
!106 = !{i64 1363}
!107 = !{i64 1365}
!108 = !{i64 1375}
!109 = !{i64 1392}
!110 = !{i64 1414}
!111 = !{i64 1432}
!112 = !{i64 1442}
!113 = !{i64 1451}
!114 = !{i64 1453}
!115 = !{i64 1463}
!116 = !{i64 1483}
!117 = !{i64 1492}
!118 = !{i64 1537}
!119 = !{i64 1551}
!120 = !{i64 1568}
!121 = !{i64 1590}
!122 = !{i64 1608}
!123 = !{i64 1618}
!124 = !{i64 1627}
!125 = !{i64 1629}
!126 = !{i64 1639}
!127 = !{i64 1664}
!128 = !{i64 1676}
!129 = !{i64 1762}
!130 = !{i64 1780}
!131 = !{i64 1782}
!132 = !{i64 1802}
!133 = !{i64 1806}
!134 = !{i64 1809}
!135 = !{i64 1821}
!136 = !{i64 1830}
!137 = !{i64 1845}
!138 = !{i64 1850}
!139 = !{i64 1852}
!140 = !{i64 1861}
!141 = !{i64 1879}
!142 = !{i64 1895}
!143 = !{i64 1910}
!144 = !{i64 1916}
!145 = !{i64 1956}
!146 = !{i64 1963}
!147 = !{i64 1988}
!148 = !{i64 2000}
!149 = !{i64 2070}
!150 = !{i64 2088}
!151 = !{i64 2102}
!152 = !{i64 2119}
!153 = !{i64 2141}
!154 = !{i64 2164}
!155 = !{i64 2175}
!156 = !{i64 2184}
!157 = !{i64 2186}
!158 = !{i64 2196}
!159 = !{i64 2210}
!160 = !{i64 2224}
!161 = !{i64 2247}
!162 = !{i64 2291}
!163 = !{i64 2304}
!164 = !{i64 2315}
!165 = !{i64 2326}
!166 = !{i64 2337}
!167 = !{i64 2354}
!168 = !{i64 2376}
!169 = !{i64 2399}
!170 = !{i64 2410}
!171 = !{i64 2419}
!172 = !{i64 2421}
!173 = !{i64 2431}
!174 = !{i64 2445}
!175 = !{i64 2462}
!176 = !{i64 2474}
!177 = !{i64 2477}
!178 = !{i64 2481}
!179 = !{i64 2484}
!180 = !{i64 2488}
!181 = !{i64 2492}
!182 = !{i64 2496}
!183 = !{i64 2500}
!184 = !{i64 2511}
!185 = !{i64 2523}
!186 = !{i64 2526}
!187 = !{i64 2530}
!188 = !{i64 2534}
!189 = !{i64 2538}
!190 = !{i64 2542}
!191 = !{i64 2546}
!192 = !{i64 2550}
!193 = !{i64 2556}
!194 = !{i64 2571}
!195 = !{i64 2585}
!196 = !{i64 2609}
!197 = !{i64 2627}
!198 = !{i64 2634}
!199 = !{i64 2675}
!200 = !{i64 2690}
!201 = !{i64 2705}
!202 = !{i64 2720}
!203 = !{i64 2737}
!204 = !{i64 2752}
!205 = !{i64 2780}
!206 = !{i64 2798}
!207 = !{i64 2810}
!208 = !{i64 2813}
!209 = !{i64 2822}
!210 = !{i64 2837}
!211 = !{i64 2842}
!212 = !{i64 2845}
!213 = !{i64 2864}
!214 = !{i64 2879}
!215 = !{i64 2914}
!216 = !{i64 2927}
!217 = !{i64 2938}
!218 = !{i64 2945}
!219 = !{i64 2962}
!220 = !{i64 2974}
!221 = !{i64 2977}
!222 = !{i64 2981}
!223 = !{i64 2984}
!224 = !{i64 2988}
!225 = !{i64 2992}
!226 = !{i64 3003}
!227 = !{i64 3015}
!228 = !{i64 3018}
!229 = !{i64 3022}
!230 = !{i64 3026}
!231 = !{i64 3030}
!232 = !{i64 3034}
!233 = !{i64 3040}
!234 = !{i64 3058}
!235 = !{i64 3070}
!236 = !{i64 3073}
!237 = !{i64 3077}
!238 = !{i64 3080}
!239 = !{i64 3084}
!240 = !{i64 3088}
!241 = !{i64 3094}
!242 = !{i64 3126}
!243 = !{i64 3133}
!244 = !{i64 3157}
!245 = !{i64 3170}
!246 = !{i64 3182}
!247 = !{i64 3189}
!248 = !{i64 3209}
!249 = !{i64 3225}
!250 = !{i64 3231}
!251 = !{i64 3268}
!252 = !{i64 3283}
!253 = !{i64 3298}
!254 = !{i64 3313}
!255 = !{i64 3330}
!256 = !{i64 3345}
!257 = !{i64 3365}
!258 = !{i64 3371}
!259 = !{i64 3395}
!260 = !{i64 3398}
!261 = !{i64 3403}
!262 = !{i64 3433}
!263 = !{i64 3445}
!264 = !{i64 3448}
!265 = !{i64 3457}
!266 = !{i64 3472}
!267 = !{i64 3477}
!268 = !{i64 3480}
!269 = !{i64 3489}
!270 = !{i64 3507}
!271 = !{i64 3512}
!272 = !{i64 3521}
!273 = !{i64 3526}
!274 = !{i64 3537}
!275 = !{i64 3550}
!276 = !{i64 3561}
!277 = !{i64 3570}
!278 = !{i64 3573}
!279 = !{i64 3578}
!280 = !{i64 3611}
!281 = !{i64 3625}
!282 = !{i64 3630}
!283 = !{i64 3632}
!284 = !{i64 3602}
!285 = !{i64 3649}
!286 = !{i64 3660}
!287 = !{i64 3668}
!288 = !{i64 3670}
!289 = !{i64 3695}
!290 = !{i64 3719}
!291 = !{i64 3723}
!292 = !{i64 3726}
!293 = !{i64 3730}
!294 = !{i64 3734}
!295 = !{i64 3743}
!296 = !{i64 3772}
!297 = !{i64 3783}
!298 = !{i64 3794}
!299 = !{i64 3816}
!300 = !{i64 3820}
!301 = !{i64 3824}
!302 = !{i64 3827}
!303 = !{i64 3831}
!304 = !{i64 3835}
!305 = !{i64 3844}
!306 = !{i64 3865}
!307 = !{i64 3871}
!308 = !{i64 3885}
!309 = !{i64 3899}
!310 = !{i64 3936}
!311 = !{i64 3951}
!312 = !{i64 3966}
!313 = !{i64 3981}
!314 = !{i64 3989}
!315 = !{i64 3992}
!316 = !{i64 3996}
!317 = !{i64 3999}
!318 = !{i64 4018}
!319 = !{i64 4033}
!320 = !{i64 4057}
!321 = !{i64 4075}
!322 = !{i64 4082}
!323 = !{i64 4102}
!324 = !{i64 4109}
!325 = !{i64 4129}
!326 = !{i64 4139}
!327 = !{i64 4153}
!328 = !{i64 4184}
!329 = !{i64 4191}
!330 = !{i64 4220}
!331 = !{i64 4231}
!332 = !{i64 4242}
!333 = !{i64 4256}
!334 = !{i64 4280}
!335 = !{i64 4293}
!336 = !{i64 4305}
!337 = !{i64 4312}
!338 = !{i64 4333}
!339 = !{i64 4339}
!340 = !{i64 4368}
!341 = !{i64 4379}
!342 = !{i64 4388}
!343 = !{i64 4398}
!344 = !{i64 4423}
!345 = !{i64 4430}
!346 = !{i64 4445}
!347 = !{i64 4446}
!348 = !{i64 4462}
!349 = !{i64 4467}
!350 = !{i64 4469}
!351 = !{i64 4478}
!352 = !{i64 4483}
!353 = !{i64 4485}
!354 = !{i64 4492}
!355 = !{i64 4497}
!356 = !{i64 4499}
!357 = !{i64 4521}
!358 = !{i64 6609}
!359 = !{i64 6627}
!360 = !{i64 6648}
!361 = !{i64 6652}
!362 = !{i64 6689}
!363 = !{i64 6706}
!364 = !{i64 6710}
!365 = !{i64 6713}
!366 = !{i64 6717}
!367 = !{i64 6748}
!368 = !{i64 6751}
!369 = !{i64 6764}
!370 = !{i64 6780}
!371 = !{i64 6800}
!372 = !{i64 6818}
!373 = !{i64 6819}
!374 = !{i64 6843}
!375 = !{i64 6848}
!376 = !{i64 6861}
!377 = !{i64 6865}
!378 = !{i64 6875}
!379 = !{i64 6880}
!380 = !{i64 6882}
!381 = !{i64 6884}
!382 = !{i64 6908}
!383 = !{i64 6912}
!384 = !{i64 6915}
!385 = !{i64 6920}
!386 = !{i64 6929}
!387 = !{i64 6934}
!388 = !{i64 6945}
!389 = !{i64 6951}
!390 = !{i64 6980}
!391 = !{i64 6991}
!392 = !{i64 6997}
!393 = !{i64 7018}
!394 = !{i64 7043}
!395 = !{i64 7048}
!396 = !{i64 7051}
!397 = !{i64 7055}
!398 = !{i64 7072}
!399 = !{i64 7077}
!400 = !{i64 7078}
!401 = !{i64 7109}
!402 = !{i64 7124}
!403 = !{i64 7139}
!404 = !{i64 7144}
!405 = !{i64 7147}
!406 = !{i64 7156}
!407 = !{i64 7171}
!408 = !{i64 7186}
!409 = !{i64 7200}
!410 = !{i64 7205}
!411 = !{i64 7207}
!412 = !{i64 7216}
!413 = !{i64 7229}
!414 = !{i64 7230}
!415 = !{i64 7247}
!416 = !{i64 7251}
!417 = !{i64 7255}
!418 = !{i64 7277}
!419 = !{i64 7282}
!420 = !{i64 7300}
!421 = !{i64 7305}
!422 = !{i64 7308}
!423 = !{i64 7319}
!424 = !{i64 7327}
!425 = !{i64 7331}
!426 = !{i64 7334}
!427 = !{i64 7352}
!428 = !{i64 7357}
!429 = !{i64 7367}
!430 = !{i64 7372}
!431 = !{i64 7376}
!432 = !{i64 7393}
!433 = !{i64 7398}
!434 = !{i64 7410}
!435 = !{i64 7419}
!436 = !{i64 7421}
!437 = !{i64 7431}
!438 = !{i64 7432}
!439 = !{i64 7460}
!440 = !{i64 7486}
!441 = !{i64 7494}
!442 = !{i64 7496}
!443 = !{i64 7512}
!444 = !{i64 7537}
!445 = !{i64 7546}
!446 = !{i64 7549}
!447 = !{i64 7553}
!448 = !{i64 7559}
!449 = !{i64 7560}
!450 = !{i64 7590}
!451 = !{i64 7598}
!452 = !{i64 7613}
!453 = !{i64 7628}
!454 = !{i64 7633}
!455 = !{i64 7636}
!456 = !{i64 7639}
!457 = !{i64 7641}
!458 = !{i64 7657}
!459 = !{i64 7662}
!460 = !{i64 7664}
!461 = !{i64 7680}
!462 = !{i64 7695}
!463 = !{i64 7710}
!464 = !{i64 7724}
!465 = !{i64 7729}
!466 = !{i64 7731}
!467 = !{i64 7742}
!468 = !{i64 7760}
!469 = !{i64 7765}
!470 = !{i64 7789}
!471 = !{i64 7794}
!472 = !{i64 7796}
!473 = !{i64 7800}
!474 = !{i64 7802}
!475 = !{i64 7830}
!476 = !{i64 7845}
!477 = !{i64 7858}
!478 = !{i64 7866}
!479 = !{i64 7870}
!480 = !{i64 7876}
!481 = !{i64 7880}
!482 = !{i64 7889}
!483 = !{i64 7911}
!484 = !{i64 7916}
!485 = !{i64 7918}
!486 = !{i64 7923}
!487 = !{i64 7932}
!488 = !{i64 7944}
!489 = !{i64 7958}
!490 = !{i64 7967}
!491 = !{i64 7975}
!492 = !{i64 7982}
!493 = !{i64 7991}
!494 = !{i64 7992}
!495 = !{i64 8023}
!496 = !{i64 8033}
!497 = !{i64 8040}
!498 = !{i64 8051}
!499 = !{i64 8062}
!500 = !{i64 8071}
!501 = !{i64 8076}
!502 = !{i64 8078}
!503 = !{i64 8115}
!504 = !{i64 8122}
!505 = !{i64 8139}
!506 = !{i64 8156}
!507 = !{i64 8181}
!508 = !{i64 8186}
!509 = !{i64 8239}
!510 = !{i64 8240}
!511 = !{i64 8260}
!512 = !{i64 8282}
!513 = !{i64 8287}
!514 = !{i64 8289}
!515 = !{i64 8302}
!516 = !{i64 8317}
!517 = !{i64 8320}
!518 = !{i64 8322}
!519 = !{i64 8326}
!520 = !{i64 8435}
!521 = !{i64 8439}
!522 = !{i64 8339}
!523 = !{i64 8350}
!524 = !{i64 8354}
!525 = !{i64 8356}
!526 = !{i64 8374}
!527 = !{i64 8379}
!528 = !{i64 8401}
!529 = !{i64 8406}
!530 = !{i64 8414}
!531 = !{i64 8423}
!532 = !{i64 8427}
!533 = !{i64 8445}
!534 = !{i64 8452}
!535 = !{i64 8455}
!536 = !{i64 8457}
!537 = !{i64 8481}
!538 = !{i64 8488}
!539 = !{i64 8491}
!540 = !{i64 8493}
!541 = !{i64 8497}
!542 = !{i64 8500}
!543 = !{i64 8510}
!544 = !{i64 8515}
!545 = !{i64 8530}
!546 = !{i64 8533}
!547 = !{i64 8536}
!548 = !{i64 8538}
!549 = !{i64 8542}
!550 = !{i64 8545}
!551 = !{i64 8563}
!552 = !{i64 8568}
!553 = !{i64 8590}
!554 = !{i64 8595}
!555 = !{i64 8603}
!556 = !{i64 8619}
!557 = !{i64 8624}
!558 = !{i64 8629}
!559 = !{i64 8638}
!560 = !{i64 8640}
!561 = !{i64 8646}
!562 = !{i64 8664}
!563 = !{i64 8669}
!564 = !{i64 8670}
!565 = !{i64 8702}
!566 = !{i64 8713}
!567 = !{i64 8717}
!568 = !{i64 8722}
!569 = !{i64 8724}
!570 = !{i64 8733}
!571 = !{i64 8738}
!572 = !{i64 8747}
!573 = !{i64 8753}
!574 = !{i64 8754}
!575 = !{i64 8782}
!576 = !{i64 8786}
!577 = !{i64 8789}
!578 = !{i64 8826}
!579 = !{i64 8838}
!580 = !{i64 8846}
!581 = !{i64 8860}
!582 = !{i64 8864}
!583 = !{i64 8867}
!584 = !{i64 8879}
!585 = !{i64 8884}
!586 = !{i64 8887}
!587 = !{i64 8899}
!588 = !{i64 8904}
!589 = !{i64 8907}
!590 = !{i64 8932}
!591 = !{i64 8934}
!592 = !{i64 8962}
!593 = !{i64 8966}
!594 = !{i64 8969}
!595 = !{i64 9006}
!596 = !{i64 9018}
!597 = !{i64 9026}
!598 = !{i64 9040}
!599 = !{i64 9044}
!600 = !{i64 9047}
!601 = !{i64 9056}
!602 = !{i64 9060}
!603 = !{i64 9063}
!604 = !{i64 9068}
!605 = !{i64 9071}
!606 = !{i64 9084}
!607 = !{i64 9087}
!608 = !{i64 9092}
!609 = !{i64 9095}
!610 = !{i64 9120}
!611 = !{i64 9145}
!612 = !{i64 9154}
!613 = !{i64 9161}
!614 = !{i64 9168}
!615 = !{i64 9189}
!616 = !{i64 9193}
!617 = !{i64 9196}
!618 = !{i64 9200}
!619 = !{i64 9204}
!620 = !{i64 9208}
!621 = !{i64 9219}
!622 = !{i64 9229}
!623 = !{i64 9246}
!624 = !{i64 9268}
!625 = !{i64 9281}
!626 = !{i64 9294}
!627 = !{i64 9304}
!628 = !{i64 9313}
!629 = !{i64 9315}
!630 = !{i64 9325}
!631 = !{i64 9326}
!632 = !{i64 9342}
!633 = !{i64 9376}
!634 = !{i64 9365}
!635 = !{i64 9372}
!636 = !{i64 9384}
!637 = !{i64 9397}
!638 = !{i64 9405}
!639 = !{i64 9407}
!640 = !{i64 9367}
!641 = !{i64 9417}
!642 = !{i64 9426}
!643 = !{i64 9428}
!644 = !{i64 9434}
!645 = !{i64 9465}
!646 = !{i64 9467}
!647 = !{i64 9471}
!648 = !{i64 9504}
!649 = !{i64 9521}
!650 = !{i64 9528}
!651 = !{i64 9553}
!652 = !{i64 9560}
!653 = !{i64 9591}
!654 = !{i64 9594}
!655 = !{i64 9607}
!656 = !{i64 9608}
!657 = !{i64 9619}
!658 = !{i64 9623}
!659 = !{i64 9628}
!660 = !{i64 9631}
!661 = !{i64 9634}
!662 = !{i64 9636}
!663 = !{i64 9645}
!664 = !{i64 9651}
!665 = !{i64 9652}
!666 = !{i64 9678}
!667 = !{i64 9686}
!668 = !{i64 9688}
!669 = !{i64 9725}
!670 = !{i64 9740}
!671 = !{i64 9746}
!672 = !{i64 9770}
!673 = !{i64 9776}
!674 = !{i64 9807}
!675 = !{i64 9810}
!676 = !{i64 9814}
!677 = !{i64 9815}
!678 = !{i64 9836}
!679 = !{i64 9858}
!680 = !{i64 9873}
!681 = !{i64 9894}
!682 = !{i64 9899}
!683 = !{i64 9911}
!684 = !{i64 9920}
!685 = !{i64 9922}
!686 = !{i64 9932}
!687 = !{i64 9961}
!688 = !{i64 9966}
!689 = !{i64 9973}
!690 = !{i64 9980}
!691 = !{i64 9987}
!692 = !{i64 9992}
!693 = !{i64 9999}
!694 = !{i64 10004}
!695 = !{i64 10005}
!696 = !{i64 10026}
!697 = !{i64 10048}
!698 = !{i64 10063}
!699 = !{i64 10084}
!700 = !{i64 10089}
!701 = !{i64 10101}
!702 = !{i64 10110}
!703 = !{i64 10112}
!704 = !{i64 10122}
!705 = !{i64 10137}
!706 = !{i64 10178}
!707 = !{i64 10185}
!708 = !{i64 10210}
!709 = !{i64 10225}
!710 = !{i64 10232}
!711 = !{i64 10274}
!712 = !{i64 10281}
!713 = !{i64 10306}
!714 = !{i64 10321}
!715 = !{i64 10328}
!716 = !{i64 10355}
!717 = !{i64 10381}
!718 = !{i64 10392}
!719 = !{i64 10397}
!720 = !{i64 10401}
!721 = !{i64 10419}
!722 = !{i64 10424}
!723 = !{i64 10454}
!724 = !{i64 10464}
!725 = !{i64 10473}
!726 = !{i64 10475}
!727 = !{i64 10489}
!728 = !{i64 10506}
!729 = !{i64 10513}
!730 = !{i64 10525}
!731 = !{i64 10535}
!732 = !{i64 10576}
!733 = !{i64 10592}
!734 = !{i64 10605}
!735 = !{i64 10623}
!736 = !{i64 10639}
!737 = !{i64 10644}
!738 = !{i64 10654}
!739 = !{i64 10665}
!740 = !{i64 10666}
!741 = !{i64 10689}
!742 = !{i64 10713}
!743 = !{i64 10728}
!744 = !{i64 10736}
!745 = !{i64 10751}
!746 = !{i64 10766}
!747 = !{i64 10778}
!748 = !{i64 10788}
!749 = !{i64 10797}
!750 = !{i64 10799}
!751 = !{i64 10812}
!752 = !{i64 10830}
!753 = !{i64 10848}
!754 = !{i64 10868}
!755 = !{i64 10892}
!756 = !{i64 10898}
!757 = !{i64 10922}
!758 = !{i64 10928}
!759 = !{i64 10952}
!760 = !{i64 10960}
!761 = !{i64 10966}
!762 = !{i64 10990}
!763 = !{i64 10998}
!764 = !{i64 11004}
!765 = !{i64 11022}
!766 = !{i64 11040}
!767 = !{i64 11073}
!768 = !{i64 11078}
!769 = !{i64 11085}
!770 = !{i64 11095}
!771 = !{i64 11100}
!772 = !{i64 11107}
!773 = !{i64 11112}
!774 = !{i64 11130}
!775 = !{i64 11163}
!776 = !{i64 11168}
!777 = !{i64 11175}
!778 = !{i64 11185}
!779 = !{i64 11190}
!780 = !{i64 11197}
!781 = !{i64 11202}
!782 = !{i64 11204}
!783 = !{i64 11225}
!784 = !{i64 11240}
!785 = !{i64 11245}
!786 = !{i64 11247}
!787 = !{i64 11263}
!788 = !{i64 11268}
!789 = !{i64 11272}
!790 = !{i64 11308}
!791 = !{i64 11321}
!792 = !{i64 11330}
!793 = !{i64 11359}
!794 = !{i64 11368}
!795 = !{i64 11376}
!796 = !{i64 11385}
!797 = !{i64 11387}
!798 = !{i64 11397}
!799 = !{i64 11430}
!800 = !{i64 11445}
!801 = !{i64 11466}
!802 = !{i64 11480}
!803 = !{i64 11524}
!804 = !{i64 11530}
!805 = !{i64 11556}
!806 = !{i64 11571}
!807 = !{i64 11576}
!808 = !{i64 11580}
!809 = !{i64 11588}
!810 = !{i64 11590}
!811 = !{i64 11614}
!812 = !{i64 11618}
!813 = !{i64 11621}
!814 = !{i64 11633}
!815 = !{i64 11642}
!816 = !{i64 11657}
!817 = !{i64 11662}
!818 = !{i64 11664}
!819 = !{i64 11700}
!820 = !{i64 11708}
!821 = !{i64 11716}
!822 = !{i64 11724}
!823 = !{i64 11730}
!824 = !{i64 11748}
!825 = !{i64 11762}
!826 = !{i64 11769}
!827 = !{i64 11777}
!828 = !{i64 11782}
!829 = !{i64 11796}
!830 = !{i64 11803}
!831 = !{i64 11811}
!832 = !{i64 11816}
!833 = !{i64 11841}
!834 = !{i64 11858}
!835 = !{i64 11864}
!836 = !{i64 11889}
!837 = !{i64 11894}
!838 = !{i64 11901}
!839 = !{i64 11909}
!840 = !{i64 11919}
!841 = !{i64 11926}
!842 = !{i64 11962}
!843 = !{i64 11969}
!844 = !{i64 12004}
!845 = !{i64 12011}
!846 = !{i64 12036}
!847 = !{i64 12049}
!848 = !{i64 12052}
!849 = !{i64 12055}
!850 = !{i64 12041}
!851 = !{i64 12064}
!852 = !{i64 12079}
!853 = !{i64 12084}
!854 = !{i64 12093}
!855 = !{i64 12102}
!856 = !{i64 12115}
!857 = !{i64 12143}
!858 = !{i64 12161}
!859 = !{i64 12168}
!860 = !{i64 12186}
!861 = !{i64 12210}
!862 = !{i64 12216}
!863 = !{i64 12234}
!864 = !{i64 12258}
!865 = !{i64 12274}
!866 = !{i64 12281}
!867 = !{i64 12305}
!868 = !{i64 12321}
!869 = !{i64 12328}
!870 = !{i64 12346}
!871 = !{i64 12351}
!872 = !{i64 12398}
!873 = !{i64 12417}
!874 = !{i64 12424}
!875 = !{i64 12442}
!876 = !{i64 12460}
!877 = !{i64 12493}
!878 = !{i64 12502}
!879 = !{i64 12506}
!880 = !{i64 12509}
!881 = !{i64 12512}
!882 = !{i64 12523}
!883 = !{i64 12528}
!884 = !{i64 12535}
!885 = !{i64 12540}
!886 = !{i64 12565}
!887 = !{i64 12571}
!888 = !{i64 12572}
!889 = !{i64 12596}
!890 = !{i64 12629}
!891 = !{i64 12638}
!892 = !{i64 12647}
!893 = !{i64 12649}
!894 = !{i64 12655}
!895 = !{i64 12656}
!896 = !{i64 12687}
!897 = !{i64 12696}
!898 = !{i64 12710}
!899 = !{i64 12715}
!900 = !{i64 12719}
!901 = !{i64 12725}
!902 = !{i64 12728}
!903 = !{i64 12731}
!904 = !{i64 12733}
!905 = !{i64 12770}
!906 = !{i64 12775}
!907 = !{i64 12778}
!908 = !{i64 12781}
!909 = !{i64 12784}
!910 = !{i64 12786}
!911 = !{i64 12836}
!912 = !{i64 12799}
!913 = !{i64 12808}
!914 = !{i64 12854}
!915 = !{i64 12867}
!916 = !{i64 12870}
!917 = !{i64 12878}
!918 = !{i64 12900}
!919 = !{i64 12925}
!920 = !{i64 12930}
!921 = !{i64 12934}
!922 = !{i64 12952}
!923 = !{i64 12982}
!924 = !{i64 12998}
!925 = !{i64 13003}
!926 = !{i64 13012}
!927 = !{i64 13037}
!928 = !{i64 13043}
!929 = !{i64 13067}
!930 = !{i64 13073}
!931 = !{i64 13091}
!932 = !{i64 13138}
!933 = !{i64 13156}
!934 = !{i64 13183}
!935 = !{i64 13191}
!936 = !{i64 13195}
!937 = !{i64 13198}
!938 = !{i64 13220}
!939 = !{i64 13247}
!940 = !{i64 13284}
!941 = !{i64 13299}
!942 = !{i64 13310}
!943 = !{i64 13321}
!944 = !{i64 13325}
!945 = !{i64 13333}
!946 = !{i64 13337}
!947 = !{i64 13346}
!948 = !{i64 13361}
!949 = !{i64 13382}
!950 = !{i64 13394}
!951 = !{i64 13404}
!952 = !{i64 13422}
!953 = !{i64 13440}
!954 = !{i64 13468}
!955 = !{i64 13477}
!956 = !{i64 13485}
!957 = !{i64 13509}
!958 = !{i64 13515}
!959 = !{i64 13540}
!960 = !{i64 13545}
!961 = !{i64 13577}
!962 = !{i64 13606}
!963 = !{i64 13621}
!964 = !{i64 13643}
!965 = !{i64 13653}
!966 = !{i64 13654}
!967 = !{i64 13674}
!968 = !{i64 13707}
!969 = !{i64 13730}
!970 = !{i64 13735}
!971 = !{i64 13753}
!972 = !{i64 13763}
!973 = !{i64 13772}
!974 = !{i64 13774}
!975 = !{i64 13780}
!976 = !{i64 13805}
!977 = !{i64 13812}
!978 = !{i64 13836}
!979 = !{i64 13842}
!980 = !{i64 13867}
!981 = !{i64 13873}
!982 = !{i64 13891}
!983 = !{i64 13892}
!984 = !{i64 13908}
!985 = !{i64 13927}
!986 = !{i64 13941}
!987 = !{i64 13946}
!988 = !{i64 13954}
!989 = !{i64 13963}
!990 = !{i64 13965}
!991 = !{i64 13971}
!992 = !{i64 13995}
!993 = !{i64 14009}
!994 = !{i64 14046}
!995 = !{i64 14076}
!996 = !{i64 14094}
!997 = !{i64 14099}
!998 = !{i64 14120}
!999 = !{i64 14146}
!1000 = !{i64 14173}
!1001 = !{i64 14182}
!1002 = !{i64 14194}
!1003 = !{i64 14223}
!1004 = !{i64 14260}
!1005 = !{i64 14275}
!1006 = !{i64 14286}
!1007 = !{i64 14311}
!1008 = !{i64 14329}
!1009 = !{i64 14334}
!1010 = !{i64 14351}
!1011 = !{i64 14360}
!1012 = !{i64 14375}
!1013 = !{i64 14393}
!1014 = !{i64 14398}
!1015 = !{i64 14415}
!1016 = !{i64 14438}
!1017 = !{i64 14442}
!1018 = !{i64 14446}
!1019 = !{i64 14460}
!1020 = !{i64 14476}
!1021 = !{i64 14490}
!1022 = !{i64 14498}
!1023 = !{i64 14510}
!1024 = !{i64 14520}
!1025 = !{i64 14529}
!1026 = !{i64 14538}
!1027 = !{i64 14540}
!1028 = !{i64 14550}
!1029 = !{i64 14552}
!1030 = !{i64 14568}
!1031 = !{i64 14590}
!1032 = !{i64 14595}
!1033 = !{i64 14611}
!1034 = !{i64 14616}
!1035 = !{i64 14627}
!1036 = !{i64 14636}
!1037 = !{i64 14645}
!1038 = !{i64 14647}
!1039 = !{i64 14653}
!1040 = !{i64 14677}
!1041 = !{i64 14683}
!1042 = !{i64 14707}
!1043 = !{i64 14713}
!1044 = !{i64 14734}
!1045 = !{i64 14752}
!1046 = !{i64 14757}
!1047 = !{i64 14758}
!1048 = !{i64 14786}
!1049 = !{i64 14819}
!1050 = !{i64 14849}
!1051 = !{i64 14874}
!1052 = !{i64 14883}
!1053 = !{i64 14885}
!1054 = !{i64 14891}
!1055 = !{i64 14912}
!1056 = !{i64 14938}
!1057 = !{i64 14953}
!1058 = !{i64 14958}
!1059 = !{i64 14962}
!1060 = !{i64 14970}
!1061 = !{i64 15008}
!1062 = !{i64 15038}
!1063 = !{i64 15048}
!1064 = !{i64 15078}
!1065 = !{i64 15093}
!1066 = !{i64 15114}
!1067 = !{i64 15126}
!1068 = !{i64 15141}
!1069 = !{i64 15152}
!1070 = !{i64 15163}
!1071 = !{i64 15195}
!1072 = !{i64 15203}
!1073 = !{i64 15205}
!1074 = !{i64 15214}
!1075 = !{i64 15222}
!1076 = !{i64 15245}
!1077 = !{i64 15252}
!1078 = !{i64 15277}
!1079 = !{i64 15289}
!1080 = !{i64 15296}
!1081 = !{i64 15320}
!1082 = !{i64 15326}
!1083 = !{i64 15350}
!1084 = !{i64 15356}
!1085 = !{i64 15392}
!1086 = !{i64 15399}
!1087 = !{i64 15434}
!1088 = !{i64 15441}
!1089 = !{i64 15469}
!1090 = !{i64 15474}
!1091 = !{i64 15476}
!1092 = !{i64 15493}
!1093 = !{i64 15501}
!1094 = !{i64 15523}
!1095 = !{i64 15538}
!1096 = !{i64 15543}
!1097 = !{i64 15553}
!1098 = !{i64 15559}
!1099 = !{i64 15561}
!1100 = !{i64 15570}
!1101 = !{i64 15582}
!1102 = !{i64 15597}
!1103 = !{i64 15602}
!1104 = !{i64 15620}
!1105 = !{i64 15625}
!1106 = !{i64 15628}
!1107 = !{i64 15642}
!1108 = !{i64 15647}
!1109 = !{i64 15651}
!1110 = !{i64 15660}
!1111 = !{i64 15665}
!1112 = !{i64 15669}
!1113 = !{i64 15678}
!1114 = !{i64 15683}
!1115 = !{i64 15693}
!1116 = !{i64 15702}
!1117 = !{i64 15704}
!1118 = !{i64 15714}
!1119 = !{i64 15716}
!1120 = !{i64 15732}
!1121 = !{i64 15761}
!1122 = !{i64 15766}
!1123 = !{i64 15774}
!1124 = !{i64 15783}
!1125 = !{i64 15785}
!1126 = !{i64 15791}
!1127 = !{i64 15820}
!1128 = !{i64 15825}
!1129 = !{i64 15835}
!1130 = !{i64 15840}
!1131 = !{i64 15846}
!1132 = !{i64 15852}
!1133 = !{i64 15861}
!1134 = !{i64 15862}
!1135 = !{i64 15882}
!1136 = !{i64 15887}
!1137 = !{i64 15924}
!1138 = !{i64 15930}
!1139 = !{i64 15938}
!1140 = !{i64 15986}
!1141 = !{i64 15992}
!1142 = !{i64 16011}
!1143 = !{i64 16029}
!1144 = !{i64 16030}
!1145 = !{i64 16054}
!1146 = !{i64 16059}
!1147 = !{i64 16103}
!1148 = !{i64 16108}
!1149 = !{i64 16111}
!1150 = !{i64 16112}
!1151 = !{i64 16132}
!1152 = !{i64 16154}
!1153 = !{i64 16158}
!1154 = !{i64 16165}
!1155 = !{i64 16168}
!1156 = !{i64 16186}
!1157 = !{i64 16191}
!1158 = !{i64 16199}
!1159 = !{i64 16208}
!1160 = !{i64 16210}
!1161 = !{i64 16216}
!1162 = !{i64 16238}
!1163 = !{i64 16256}
!1164 = !{i64 16261}
!1165 = !{i64 16304}
!1166 = !{i64 16311}
!1167 = !{i64 16312}
!1168 = !{i64 16355}
!1169 = !{i64 16359}
!1170 = !{i64 16334}
!1171 = !{i64 16346}
!1172 = !{i64 16364}
!1173 = !{i64 16397}
!1174 = !{i64 16402}
!1175 = !{i64 16405}
!1176 = !{i64 16413}
!1177 = !{i64 16437}
!1178 = !{i64 16444}
!1179 = !{i64 16462}
!1180 = !{i64 16471}
!1181 = !{i64 16495}
!1182 = !{i64 16501}
!1183 = !{i64 16525}
!1184 = !{i64 16531}
!1185 = !{i64 16566}
!1186 = !{i64 16582}
!1187 = !{i64 16587}
!1188 = !{i64 16622}
!1189 = !{i64 16629}
!1190 = !{i64 16662}
!1191 = !{i64 16673}
!1192 = !{i64 16685}
!1193 = !{i64 16690}
!1194 = !{i64 16703}
!1195 = !{i64 16727}
!1196 = !{i64 16735}
!1197 = !{i64 16741}
!1198 = !{i64 16758}
!1199 = !{i64 16769}
!1200 = !{i64 16775}
!1201 = !{i64 16780}
!1202 = !{i64 16819}
!1203 = !{i64 16834}
!1204 = !{i64 16849}
!1205 = !{i64 16870}
!1206 = !{i64 16883}
!1207 = !{i64 16916}
!1208 = !{i64 16931}
!1209 = !{i64 16952}
!1210 = !{i64 16962}
!1211 = !{i64 16978}
!1212 = !{i64 16996}
!1213 = !{i64 17020}
!1214 = !{i64 17026}
!1215 = !{i64 17044}
!1216 = !{i64 17064}
!1217 = !{i64 17065}
!1218 = !{i64 17081}
!1219 = !{i64 17106}
!1220 = !{i64 17146}
!1221 = !{i64 17164}
!1222 = !{i64 17169}
!1223 = !{i64 17176}
!1224 = !{i64 17185}
!1225 = !{i64 17187}
!1226 = !{i64 17193}
!1227 = !{i64 17211}
!1228 = !{i64 17254}
!1229 = !{i64 17264}
!1230 = !{i64 17267}
!1231 = !{i64 17270}
!1232 = !{i64 17272}
!1233 = !{i64 17284}
!1234 = !{i64 17288}
!1235 = !{i64 17290}
!1236 = !{i64 17295}
!1237 = !{i64 17304}
!1238 = !{i64 17311}
!1239 = !{i64 17318}
!1240 = !{i64 17336}
!1241 = !{i64 17337}
!1242 = !{i64 17438}
!1243 = !{i64 17442}
!1244 = !{i64 17383}
!1245 = !{i64 17398}
!1246 = !{i64 17419}
!1247 = !{i64 17424}
!1248 = !{i64 17429}
!1249 = !{i64 17453}
!1250 = !{i64 17482}
!1251 = !{i64 17500}
!1252 = !{i64 17506}
!1253 = !{i64 17507}
!1254 = !{i64 17519}
!1255 = !{i64 17523}
!1256 = !{i64 17545}
!1257 = !{i64 17550}
!1258 = !{i64 17563}
!1259 = !{i64 17568}
!1260 = !{i64 17576}
!1261 = !{i64 17585}
!1262 = !{i64 17587}
!1263 = !{i64 17593}
!1264 = !{i64 17644}
!1265 = !{i64 17650}
!1266 = !{i64 17668}
!1267 = !{i64 17686}
!1268 = !{i64 17719}
!1269 = !{i64 17751}
!1270 = !{i64 17788}
!1271 = !{i64 17803}
!1272 = !{i64 17814}
!1273 = !{i64 17828}
!1274 = !{i64 17868}
!1275 = !{i64 17881}
!1276 = !{i64 17899}
!1277 = !{i64 17916}
!1278 = !{i64 17927}
!1279 = !{i64 17932}
!1280 = !{i64 17939}
!1281 = !{i64 17944}
!1282 = !{i64 17987}
!1283 = !{i64 17993}
!1284 = !{i64 17994}
!1285 = !{i64 18007}
!1286 = !{i64 18011}
!1287 = !{i64 18098}
!1288 = !{i64 18103}
!1289 = !{i64 18105}
!1290 = !{i64 18036}
!1291 = !{i64 18051}
!1292 = !{i64 18062}
!1293 = !{i64 18074}
!1294 = !{i64 18079}
!1295 = !{i64 18116}
!1296 = !{i64 18151}
!1297 = !{i64 18156}
!1298 = !{i64 18160}
!1299 = !{i64 18181}
!1300 = !{i64 18189}
!1301 = !{i64 18197}
!1302 = !{i64 18215}
!1303 = !{i64 18236}
!1304 = !{i64 18270}
!1305 = !{i64 18285}
!1306 = !{i64 18296}
!1307 = !{i64 18307}
!1308 = !{i64 18336}
!1309 = !{i64 18351}
!1310 = !{i64 18356}
!1311 = !{i64 18367}
!1312 = !{i64 18385}
!1313 = !{i64 18386}
!1314 = !{i64 18410}
!1315 = !{i64 18414}
!1316 = !{i64 18417}
!1317 = !{i64 18429}
!1318 = !{i64 18438}
!1319 = !{i64 18446}
!1320 = !{i64 18457}
!1321 = !{i64 18462}
!1322 = !{i64 18464}
!1323 = !{i64 18474}
!1324 = !{i64 18481}
!1325 = !{i64 18484}
!1326 = !{i64 18492}
!1327 = !{i64 18500}
!1328 = !{i64 18508}
!1329 = !{i64 18520}
!1330 = !{i64 18530}
!1331 = !{i64 18552}
!1332 = !{i64 18640}
!1333 = !{i64 18647}
!1334 = !{i64 18655}
!1335 = !{i64 18665}
!1336 = !{i64 18672}
!1337 = !{i64 18697}
!1338 = !{i64 18714}
!1339 = !{i64 18720}
!1340 = !{i64 19100}
!1341 = !{i64 19119}
!1342 = !{i64 19138}
!1343 = !{i64 19147}
!1344 = !{i64 19156}
!1345 = !{i64 19158}
!1346 = !{i64 19168}
!1347 = !{i64 19202}
!1348 = !{i64 19224}
!1349 = !{i64 19231}
!1350 = !{i64 19248}
!1351 = !{i64 19254}
!1352 = !{i64 19272}
!1353 = !{i64 19278}
!1354 = !{i64 19280}
!1355 = !{i64 19300}
!1356 = !{i64 19308}
!1357 = !{i64 19323}
!1358 = !{i64 19354}
!1359 = !{i64 19385}
!1360 = !{i64 19395}
!1361 = !{i64 19404}
!1362 = !{i64 19406}
!1363 = !{i64 19412}
!1364 = !{i64 19413}
!1365 = !{i64 19425}
!1366 = !{i64 19447}
!1367 = !{i64 19476}
!1368 = !{i64 19481}
!1369 = !{i64 19499}
!1370 = !{i64 19504}
!1371 = !{i64 19516}
!1372 = !{i64 19525}
!1373 = !{i64 19527}
!1374 = !{i64 19533}
!1375 = !{i64 19548}
!1376 = !{i64 19579}
!1377 = !{i64 19601}
!1378 = !{i64 19617}
!1379 = !{i64 19637}
