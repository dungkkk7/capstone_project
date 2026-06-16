source_filename = "test"
target datalayout = "e-m:e-p:64:64-i64:64-f80:128-n8:16:32:64-S128"

@global_var_591c = constant [46 x i8] c"/usr/include/llvm-21/llvm/IR/DiagnosticInfo.h\00"
@global_var_594a = constant [28 x i8] c"unknown SourceMgr::DiagKind\00"
@global_var_5966 = constant [12 x i8] c"<tombstone>\00"
@global_var_5972 = constant [27 x i8] c"REMILL_STATE_FORWARD_TRACE\00"
@global_var_598d = constant [4 x i8] c"RAX\00"
@global_var_5991 = constant [4 x i8] c"RBX\00"
@global_var_5995 = constant [4 x i8] c"RCX\00"
@global_var_5999 = constant [4 x i8] c"RDX\00"
@global_var_599d = constant [4 x i8] c"RSI\00"
@global_var_59a1 = constant [4 x i8] c"RDI\00"
@global_var_59a5 = constant [4 x i8] c"RBP\00"
@global_var_59a9 = constant [4 x i8] c"RSP\00"
@global_var_59ad = constant [3 x i8] c"R8\00"
@global_var_59b0 = constant [3 x i8] c"R9\00"
@global_var_59b3 = constant [4 x i8] c"R10\00"
@global_var_59b7 = constant [4 x i8] c"R11\00"
@global_var_59bb = constant [4 x i8] c"R12\00"
@global_var_59bf = constant [4 x i8] c"R13\00"
@global_var_59c3 = constant [4 x i8] c"R14\00"
@global_var_59c7 = constant [4 x i8] c"R15\00"
@global_var_59cb = constant [4 x i8] c"RIP\00"
@global_var_59cf = constant [3 x i8] c"CF\00"
@global_var_59d2 = constant [3 x i8] c"PF\00"
@global_var_59d5 = constant [3 x i8] c"AF\00"
@global_var_59d8 = constant [3 x i8] c"ZF\00"
@global_var_59db = constant [3 x i8] c"SF\00"
@global_var_59de = constant [3 x i8] c"OF\00"
@global_var_59e1 = constant [3 x i8] c"DF\00"
@global_var_5a46 = constant [8 x i8] c".ptrint\00"
@global_var_5a4e = constant [8 x i8] c".intptr\00"
@global_var_5a56 = constant [6 x i8] c".zext\00"
@global_var_5a5c = constant [7 x i8] c".trunc\00"
@global_var_300 = local_unnamed_addr constant i64 -8554369199269478317
@global_var_5ab4 = constant [38 x i8] c"brighten-state-forward-pass function=\00"
@global_var_5ada = constant [8 x i8] c" loads=\00"
@global_var_5ae5 = constant [28 x i8] c"brighten-state-forward-pass\00"
@global_var_5b01 = constant [25 x i8] c"BrightenStateForwardPass\00"
@global_var_5b1a = constant [6 x i8] c"0.1.0\00"
@global_var_3f = constant [3 x i8] c"%(\00"
@global_var_618c = constant [612 x i8] c"bool llvm::operator==(const DenseMapIterator<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore, brighten_state_forward::{anonymous}::AliasKeyInfo, detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>, false>&, const DenseMapIterator<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore, brighten_state_forward::{anonymous}::AliasKeyInfo, detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>, false>&)\00"
@global_var_63f4 = constant [41 x i8] c"/usr/include/llvm-21/llvm/ADT/DenseMap.h\00"
@global_var_6424 = constant [60 x i8] c"(!LHS.Ptr || LHS.isHandleInSync()) && \22handle not in sync!\22\00"
@global_var_6464 = constant [60 x i8] c"(!RHS.Ptr || RHS.isHandleInSync()) && \22handle not in sync!\22\00"
@global_var_64a4 = constant [86 x i8] c"LHS.getEpochAddress() == RHS.getEpochAddress() && \22comparing incomparable iterators!\22\00"
@global_var_64fc = constant [628 x i8] c"llvm::DenseMapIterator<KeyT, ValueT, KeyInfoT, Bucket, IsConst>::value_type* llvm::DenseMapIterator<KeyT, ValueT, KeyInfoT, Bucket, IsConst>::operator->() const [with KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; Bucket = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>; bool IsConst = false; pointer = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>*]\00"
@global_var_6774 = constant [47 x i8] c"isHandleInSync() && \22invalid iterator access!\22\00"
@global_var_67a4 = constant [45 x i8] c"Ptr != End && \22dereferencing end() iterator\22\00"
@global_var_67d4 = constant [659 x i8] c"bool llvm::DenseMapBase<DerivedT, KeyT, ValueT, KeyInfoT, BucketT>::LookupBucketFor(const LookupKeyT&, BucketT*&) [with LookupKeyT = brighten_state_forward::{anonymous}::AliasKey; DerivedT = llvm::DenseMap<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore, brighten_state_forward::{anonymous}::AliasKeyInfo>; KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; BucketT = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>]\00"
@global_var_6a6c = constant [134 x i8] c"!KeyInfoT::isEqual(Val, EmptyKey) && !KeyInfoT::isEqual(Val, TombstoneKey) && \22Empty/Tombstone value shouldn't be inserted into map!\22\00"
@global_var_b2a4 = global i64 0
@global_var_11224 = global i64 0
@global_var_6afc = constant [565 x i8] c"void llvm::DenseMapBase<DerivedT, KeyT, ValueT, KeyInfoT, BucketT>::initEmpty() [with DerivedT = llvm::DenseMap<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore, brighten_state_forward::{anonymous}::AliasKeyInfo>; KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; BucketT = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>]\00"
@global_var_6d34 = constant [94 x i8] c"(getNumBuckets() & (getNumBuckets() - 1)) == 0 && \22# initial buckets must be a power of two!\22\00"
@global_var_6d94 = constant [602 x i8] c"llvm::DenseMapIterator<KeyT, ValueT, KeyInfoT, Bucket, IsConst>::DenseMapIterator(pointer, pointer, const llvm::DebugEpochBase&, bool) [with KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; Bucket = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>; bool IsConst = false; pointer = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>*]\00"
@global_var_6ff4 = constant [44 x i8] c"isHandleInSync() && \22invalid construction!\22\00"
@global_var_7024 = constant [667 x i8] c"BucketT* llvm::DenseMapBase<DerivedT, KeyT, ValueT, KeyInfoT, BucketT>::InsertIntoBucketImpl(const LookupKeyT&, BucketT*) [with LookupKeyT = brighten_state_forward::{anonymous}::AliasKey; DerivedT = llvm::DenseMap<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore, brighten_state_forward::{anonymous}::AliasKeyInfo>; KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; BucketT = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>]\00"
@global_var_72bf = constant [10 x i8] c"TheBucket\00"
@global_var_75ec = constant [429 x i8] c"void llvm::DenseMapIterator<KeyT, ValueT, KeyInfoT, Bucket, IsConst>::RetreatPastEmptyBuckets() [with KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; Bucket = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>; bool IsConst = false]\00"
@global_var_7799 = constant [11 x i8] c"Ptr >= End\00"
@global_var_77a4 = constant [429 x i8] c"void llvm::DenseMapIterator<KeyT, ValueT, KeyInfoT, Bucket, IsConst>::AdvancePastEmptyBuckets() [with KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; Bucket = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>; bool IsConst = false]\00"
@global_var_7951 = constant [11 x i8] c"Ptr <= End\00"
@global_var_7ddc = constant [385 x i8] c"void llvm::DenseMap<KeyT, ValueT, KeyInfoT, BucketT>::grow(unsigned int) [with KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; BucketT = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>]\00"
@global_var_7f5d = constant [8 x i8] c"Buckets\00"
@global_var_81cc = local_unnamed_addr constant [592 x i8] c"void llvm::DenseMapBase<DerivedT, KeyT, ValueT, KeyInfoT, BucketT>::moveFromOldBuckets(BucketT*, BucketT*) [with DerivedT = llvm::DenseMap<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore, brighten_state_forward::{anonymous}::AliasKeyInfo>; KeyT = brighten_state_forward::{anonymous}::AliasKey; ValueT = brighten_state_forward::{anonymous}::LastStore; KeyInfoT = brighten_state_forward::{anonymous}::AliasKeyInfo; BucketT = llvm::detail::DenseMapPair<brighten_state_forward::{anonymous}::AliasKey, brighten_state_forward::{anonymous}::LastStore>]\00"
@global_var_841c = local_unnamed_addr constant [39 x i8] c"!FoundVal && \22Key already in new map?\22\00"
@global_var_860a = constant [63 x i8] c"brighten_state_forward::{anonymous}::BrightenStateForwardPass]\00"
@global_var_8649 = constant [7 x i8] c"llvm::\00"
@global_var_8000 = local_unnamed_addr constant [82 x i8] c"l<To, const From*>::doit(const From*) [with To = llvm::Value; From = llvm::Value]\00"
@global_var_4ce4 = constant [57 x i8] c"llvm::StringRef llvm::StringRef::drop_back(size_t) const\00"
@global_var_4d24 = constant [42 x i8] c"/usr/include/llvm-21/llvm/ADT/StringRef.h\00"
@global_var_4d54 = constant [51 x i8] c"size() >= N && \22Dropping more elements than exist\22\00"
@global_var_4dd0 = constant [29 x i8] c"llvm::Twine::Twine(NodeKind)\00"
@global_var_4df4 = constant [38 x i8] c"/usr/include/llvm-21/llvm/ADT/Twine.h\00"
@global_var_4e1c = constant [31 x i8] c"isNullary() && \22Invalid kind!\22\00"
@global_var_4e3c = constant [53 x i8] c"llvm::Twine::Twine(Child, NodeKind, Child, NodeKind)\00"
@global_var_4e71 = constant [30 x i8] c"isValid() && \22Invalid twine!\22\00"
@global_var_4e94 = constant [32 x i8] c"llvm::Twine::Twine(const char*)\00"
@global_var_4eb4 = constant [43 x i8] c"llvm::Twine::Twine(const llvm::StringRef&)\00"
@global_var_4ee4 = constant [56 x i8] c"llvm::Twine::Twine(const llvm::StringRef&, const char*)\00"
@global_var_4f2c = constant [61 x i8] c"llvm::Type* llvm::Type::getContainedType(unsigned int) const\00"
@global_var_4f6c = constant [36 x i8] c"/usr/include/llvm-21/llvm/IR/Type.h\00"
@global_var_4f94 = constant [45 x i8] c"i < NumContainedTys && \22Index out of range!\22\00"
@global_var_4fcc = constant [56 x i8] c"void llvm::TrackingMDRef::retrack(llvm::TrackingMDRef&)\00"
@global_var_5004 = constant [45 x i8] c"/usr/include/llvm-21/llvm/IR/TrackingMDRef.h\00"
@global_var_5034 = constant [41 x i8] c"MD == X.MD && \22Expected values to match\22\00"
@global_var_506c = constant [65 x i8] c"decltype(auto) llvm::cast(From*) [with To = Value; From = Value]\00"
@global_var_50b4 = constant [44 x i8] c"/usr/include/llvm-21/llvm/Support/Casting.h\00"
@global_var_50e4 = constant [60 x i8] c"isa<To>(Val) && \22cast<Ty>() argument of incompatible type!\22\00"
@global_var_5124 = local_unnamed_addr constant [59 x i8] c"auto llvm::cast_if_present(Y*) [with X = Value; Y = Value]\00"
@global_var_5164 = local_unnamed_addr constant [70 x i8] c"isa<X>(Val) && \22cast_if_present<Ty>() argument of incompatible type!\22\00"
@global_var_51ac = constant [77 x i8] c"decltype(auto) llvm::cast(From*) [with To = Instruction; From = const Value]\00"
@global_var_51fc = constant [68 x i8] c"llvm::Value* llvm::UnaryInstruction::getOperand(unsigned int) const\00"
@global_var_5244 = constant [42 x i8] c"/usr/include/llvm-21/llvm/IR/InstrTypes.h\00"
@global_var_5274 = constant [94 x i8] c"i_nocapture < OperandTraits<UnaryInstruction>::operands(this) && \22getOperand() out of range!\22\00"
@global_var_52dc = constant [81 x i8] c"decltype(auto) llvm::dyn_cast(From*) [with To = Instruction; From = const Value]\00"
@global_var_5334 = constant [61 x i8] c"detail::isPresent(Val) && \22dyn_cast on a non-existent value\22\00"
@global_var_5374 = constant [73 x i8] c"decltype(auto) llvm::dyn_cast(From*) [with To = StructType; From = Type]\00"
@global_var_53c4 = constant [72 x i8] c"decltype(auto) llvm::dyn_cast(From*) [with To = ArrayType; From = Type]\00"
@global_var_540c = constant [61 x i8] c"llvm::Value* llvm::StoreInst::getOperand(unsigned int) const\00"
@global_var_544c = constant [44 x i8] c"/usr/include/llvm-21/llvm/IR/Instructions.h\00"
@global_var_547c = constant [87 x i8] c"i_nocapture < OperandTraits<StoreInst>::operands(this) && \22getOperand() out of range!\22\00"
@global_var_54dc = constant [78 x i8] c"decltype(auto) llvm::dyn_cast(From*) [with To = LoadInst; From = Instruction]\00"
@global_var_552c = constant [79 x i8] c"decltype(auto) llvm::dyn_cast(From*) [with To = StoreInst; From = Instruction]\00"
@global_var_557c = constant [61 x i8] c"void llvm::IRBuilderBase::SetInsertPoint(llvm::Instruction*)\00"
@global_var_55bc = constant [41 x i8] c"/usr/include/llvm-21/llvm/IR/IRBuilder.h\00"
@global_var_55ec = constant [59 x i8] c"InsertPt != BB->end() && \22Can't read debug loc from end()\22\00"
@global_var_564c = constant [75 x i8] c"llvm::SmallPtrSetImplBase::SmallPtrSetImplBase(const void**, unsigned int)\00"
@global_var_569c = constant [44 x i8] c"/usr/include/llvm-21/llvm/ADT/SmallPtrSet.h\00"
@global_var_56cc = constant [74 x i8] c"llvm::has_single_bit(SmallSize) && \22Initial size must be a power of two!\22\00"
@global_var_571c = constant [56 x i8] c"void llvm::SmallPtrSetIteratorImpl::AdvanceIfNotValid()\00"
@global_var_5754 = constant [14 x i8] c"Bucket <= End\00"
@global_var_5764 = constant [56 x i8] c"void llvm::SmallPtrSetIteratorImpl::RetreatIfNotValid()\00"
@global_var_579c = constant [14 x i8] c"Bucket >= End\00"
@global_var_57b4 = constant [68 x i8] c"decltype(auto) llvm::cast(From*) [with To = Function; From = Value]\00"
@global_var_57fc = constant [74 x i8] c"decltype(auto) llvm::cast(From*) [with To = CallInst; From = const Value]\00"
@global_var_584c = constant [79 x i8] c"decltype(auto) llvm::cast(From*) [with To = IntrinsicInst; From = const Value]\00"
@global_var_59fc = constant [74 x i8] c"decltype(auto) llvm::dyn_cast(From*) [with To = IntegerType; From = Type]\00"
@global_var_5a64 = constant [78 x i8] c"decltype(auto) llvm::dyn_cast(From*) [with To = CallBase; From = Instruction]\00"
@global_var_5b24 = constant [50 x i8] c"basic_string: construction from null is not valid\00"
@global_var_5b5c = constant [81 x i8] c"constexpr llvm::ArrayRef<T>::ArrayRef(const T*, const T*) [with T = llvm::Type*]\00"
@global_var_5bb4 = constant [41 x i8] c"/usr/include/llvm-21/llvm/ADT/ArrayRef.h\00"
@global_var_5bdd = constant [13 x i8] c"begin <= end\00"
@global_var_5bec = constant [309 x i8] c"llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::reference llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::operator*() const [with OptionsT = llvm::ilist_detail::node_options<llvm::DbgRecord, false, false, void, false, void>; bool IsReverse = false; bool IsConst = false; reference = llvm::DbgRecord&]\00"
@global_var_5d24 = constant [47 x i8] c"/usr/include/llvm-21/llvm/ADT/ilist_iterator.h\00"
@global_var_5d53 = constant [28 x i8] c"!NodePtr->isKnownSentinel()\00"
@global_var_5d74 = constant [65 x i8] c"const T& llvm::ArrayRef<T>::front() const [with T = llvm::Type*]\00"
@global_var_5db5 = constant [9 x i8] c"!empty()\00"
@global_var_5dc4 = constant [307 x i8] c"llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::reference llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::operator*() const [with OptionsT = llvm::ilist_detail::node_options<llvm::Function, false, false, void, false, void>; bool IsReverse = false; bool IsConst = false; reference = llvm::Function&]\00"
@global_var_5efc = constant [311 x i8] c"llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::reference llvm::ilist_iterator<OptionsT, IsReverse, IsConst>::operator*() const [with OptionsT = llvm::ilist_detail::node_options<llvm::BasicBlock, false, false, void, false, void>; bool IsReverse = false; bool IsConst = false; reference = llvm::BasicBlock&]\00"
@global_var_6034 = constant [338 x i8] c"llvm::ilist_iterator_w_bits<OptionsT, IsReverse, IsConst>::reference llvm::ilist_iterator_w_bits<OptionsT, IsReverse, IsConst>::operator*() const [with OptionsT = llvm::ilist_detail::node_options<llvm::Instruction, false, false, void, true, llvm::BasicBlock>; bool IsReverse = false; bool IsConst = false; reference = llvm::Instruction&]\00"
@global_var_72cc = constant [305 x i8] c"static intptr_t llvm::PointerIntPairInfo<PointerT, IntBits, PtrTraits>::updatePointer(intptr_t, PointerT) [with PointerT = void*; unsigned int IntBits = 2; PtrTraits = llvm::pointer_union_detail::PointerUnionUIntTraits<llvm::MetadataAsValue*, llvm::Metadata*, llvm::DebugValueUser*>; intptr_t = long int]\00"
@global_var_7404 = constant [47 x i8] c"/usr/include/llvm-21/llvm/ADT/PointerIntPair.h\00"
@global_var_7434 = constant [74 x i8] c"(PtrWord & ~PointerBitMask) == 0 && \22Pointer is not sufficiently aligned\22\00"
@global_var_7484 = constant [301 x i8] c"static intptr_t llvm::PointerIntPairInfo<PointerT, IntBits, PtrTraits>::updateInt(intptr_t, intptr_t) [with PointerT = void*; unsigned int IntBits = 2; PtrTraits = llvm::pointer_union_detail::PointerUnionUIntTraits<llvm::MetadataAsValue*, llvm::Metadata*, llvm::DebugValueUser*>; intptr_t = long int]\00"
@global_var_75b4 = constant [55 x i8] c"(Int & ~IntMask) == 0 && \22Integer too large for field\22\00"
@global_var_795c = constant [26 x i8] c"vector::_M_realloc_insert\00"
@global_var_797c = constant [113 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::Function; From = llvm::Value]\00"
@global_var_79f4 = constant [38 x i8] c"Val && \22isa<> used on a null pointer\22\00"
@global_var_7a1c = constant [116 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::Instruction; From = llvm::Value]\00"
@global_var_7a94 = constant [114 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::StructType; From = llvm::Type]\00"
@global_var_7b0c = constant [113 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::ArrayType; From = llvm::Type]\00"
@global_var_7b84 = constant [119 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::LoadInst; From = llvm::Instruction]\00"
@global_var_7bfc = constant [120 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::StoreInst; From = llvm::Instruction]\00"
@global_var_7c74 = constant [118 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::IntrinsicInst; From = llvm::Value]\00"
@global_var_7cec = constant [116 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::GlobalAlias; From = llvm::Value]\00"
@global_var_7d64 = constant [115 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::IntegerType; From = llvm::Type]\00"
@global_var_7f6c = constant [119 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::CallBase; From = llvm::Instruction]\00"
@global_var_7fe4 = constant [110 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::Value; From = llvm::Value]\00"
@global_var_8054 = constant [125 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::FPMathOperator; From = llvm::Instruction]\00"
@global_var_80d4 = constant [113 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::CallInst; From = llvm::Value]\00"
@global_var_814c = constant [124 x i8] c"static bool llvm::isa_impl_cl<To, const From*>::doit(const From*) [with To = llvm::DbgInfoIntrinsic; From = llvm::CallBase]\00"
@0 = external global i32
@global_var_40 = constant i128* inttoptr (i64 -556888036579737560 to i128*)
@global_var_472 = constant i32 1207959637
@global_var_5627 = external constant i8*
@1 = internal constant [2 x i8] c"_\00"
@2 = constant i8* getelementptr inbounds ([2 x i8], [2 x i8]* @1, i64 0, i64 0)
@3 = internal constant [2 x i8] c"\0A\00"
@4 = constant i8* getelementptr inbounds ([2 x i8], [2 x i8]* @3, i64 0, i64 0)
@global_var_59f3 = constant [2 x i8] c"_\00"
@global_var_5ae2 = constant [2 x i8] c"\0A\00"

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
  %3 = call i64 @_ZN4llvm25llvm_unreachable_internalEPKcS1_j(i8* getelementptr inbounds ([28 x i8], [28 x i8]* @global_var_594a, i64 0, i64 0), i8* getelementptr inbounds ([46 x i8], [46 x i8]* @global_var_591c, i64 0, i64 0), i32 ptrtoint (i32* @global_var_472 to i32)), !insn.addr !19
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

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1ce:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !21
  %2 = inttoptr i64 %1 to i64*, !insn.addr !22
  %3 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(i64* %2), !insn.addr !22
  %4 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(i64* %result), !insn.addr !23
  ret i64 %4, !insn.addr !24
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo11getEmptyKeyEv(i64* %result) local_unnamed_addr {
dec_label_pc_1f9:
  %0 = ptrtoint i64* %result to i64
  %stack_var_-33 = alloca i64, align 8
  %stack_var_-34 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !25
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1IS3_EEPKcRKS3_(i64* %result, i8* bitcast (i8** @global_var_5627 to i8*), i64* nonnull %stack_var_-34), !insn.addr !26
  %3 = add i64 %0, 32, !insn.addr !27
  %4 = inttoptr i64 %3 to i64*, !insn.addr !28
  %5 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1IS3_EEPKcRKS3_(i64* %4, i8* bitcast (i8** @global_var_5627 to i8*), i64* nonnull %stack_var_-33), !insn.addr !28
  %6 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !29
  %7 = inttoptr i64 %6 to i64*, !insn.addr !29
  store i64 0, i64* %7, align 8, !insn.addr !29
  %8 = call i64 @_ZNSt15__new_allocatorIcED1Ev(i64* nonnull %stack_var_-33), !insn.addr !30
  %9 = call i64 @_ZNSt15__new_allocatorIcED1Ev(i64* nonnull %stack_var_-34), !insn.addr !31
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !32
  %11 = icmp eq i64 %1, %10, !insn.addr !32
  br i1 %11, label %dec_label_pc_29e, label %dec_label_pc_299, !insn.addr !33

dec_label_pc_299:                                 ; preds = %dec_label_pc_1f9
  %12 = call i64 @__stack_chk_fail(), !insn.addr !34
  br label %dec_label_pc_29e, !insn.addr !34

dec_label_pc_29e:                                 ; preds = %dec_label_pc_299, %dec_label_pc_1f9
  ret i64 %0, !insn.addr !35
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo15getTombstoneKeyEv(i64* %result) local_unnamed_addr {
dec_label_pc_2a4:
  %0 = ptrtoint i64* %result to i64
  %stack_var_-33 = alloca i64, align 8
  %stack_var_-34 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !36
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1IS3_EEPKcRKS3_(i64* %result, i8* getelementptr inbounds ([12 x i8], [12 x i8]* @global_var_5966, i64 0, i64 0), i64* nonnull %stack_var_-34), !insn.addr !37
  %3 = add i64 %0, 32, !insn.addr !38
  %4 = inttoptr i64 %3 to i64*, !insn.addr !39
  %5 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1IS3_EEPKcRKS3_(i64* %4, i8* bitcast (i8** @global_var_5627 to i8*), i64* nonnull %stack_var_-33), !insn.addr !39
  %6 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !40
  %7 = inttoptr i64 %6 to i64*, !insn.addr !40
  store i64 0, i64* %7, align 8, !insn.addr !40
  %8 = call i64 @_ZNSt15__new_allocatorIcED1Ev(i64* nonnull %stack_var_-33), !insn.addr !41
  %9 = call i64 @_ZNSt15__new_allocatorIcED1Ev(i64* nonnull %stack_var_-34), !insn.addr !42
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !43
  %11 = icmp eq i64 %1, %10, !insn.addr !43
  br i1 %11, label %dec_label_pc_349, label %dec_label_pc_344, !insn.addr !44

dec_label_pc_344:                                 ; preds = %dec_label_pc_2a4
  %12 = call i64 @__stack_chk_fail(), !insn.addr !45
  br label %dec_label_pc_349, !insn.addr !45

dec_label_pc_349:                                 ; preds = %dec_label_pc_344, %dec_label_pc_2a4
  ret i64 %0, !insn.addr !46

; uselistorder directives
  uselistorder i64 (i64*, i8*, i64*)* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1IS3_EEPKcRKS3_, { 3, 2, 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo12getHashValueERKNS0_8AliasKeyE(i64* %arg1) local_unnamed_addr {
dec_label_pc_34f:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !47
  %1 = load i64, i64* %0
  %stack_var_-40 = alloca i64, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !48
  %3 = call i64 @_ZN4llvm9StringRefC1ERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEE(i64* nonnull %stack_var_-40, i64* %arg1), !insn.addr !49
  %4 = load i64, i64* %stack_var_-40, align 8, !insn.addr !50
  %5 = inttoptr i64 %4 to i64*, !insn.addr !51
  %6 = call i64 @_ZN4llvm12DenseMapInfoINS_9StringRefEvE12getHashValueES1_(i64* %5, i64 %1), !insn.addr !51
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !52
  %8 = icmp eq i64 %2, %7, !insn.addr !52
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !53
  br i1 %8, label %dec_label_pc_3a4, label %dec_label_pc_39f, !insn.addr !53

dec_label_pc_39f:                                 ; preds = %dec_label_pc_34f
  %9 = call i64 @__stack_chk_fail(), !insn.addr !54
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !54
  br label %dec_label_pc_3a4, !insn.addr !54

dec_label_pc_3a4:                                 ; preds = %dec_label_pc_39f, %dec_label_pc_34f
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !55

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_3a6:
  %0 = call i1 @_ZSteqIcSt11char_traitsIcESaIcEEbRKNSt7__cxx1112basic_stringIT_T0_T1_EESA_(i64* %arg1, i64* %arg2), !insn.addr !56
  %1 = sext i1 %0 to i64, !insn.addr !56
  ret i64 %1, !insn.addr !57
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L12TraceEnabledEv() local_unnamed_addr {
dec_label_pc_3cb:
  %0 = call i64 @getenv(i64 ptrtoint ([27 x i8]* @global_var_5972 to i64)), !insn.addr !58
  %1 = icmp eq i64 %0, 0, !insn.addr !59
  %2 = icmp eq i1 %1, false, !insn.addr !60
  %3 = zext i1 %2 to i64, !insn.addr !60
  %4 = and i64 %0, -256, !insn.addr !60
  %5 = or i64 %4, %3, !insn.addr !60
  ret i64 %5, !insn.addr !61

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L15IsKnownStateRegEN4llvm9StringRefE(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_3ea:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !62
  %storemerge.reg2mem = alloca i64, !insn.addr !62
  %1 = load i64, i64* %0
  %stack_var_-40 = alloca i64, align 8
  %2 = load i64, i64* %0
  %stack_var_-56 = alloca i64, align 8
  %3 = load i64, i64* %0
  %stack_var_-72 = alloca i64, align 8
  %4 = load i64, i64* %0
  %stack_var_-88 = alloca i64, align 8
  %5 = load i64, i64* %0
  %stack_var_-104 = alloca i64, align 8
  %6 = load i64, i64* %0
  %stack_var_-120 = alloca i64, align 8
  %7 = load i64, i64* %0
  %stack_var_-136 = alloca i64, align 8
  %8 = load i64, i64* %0
  %stack_var_-152 = alloca i64, align 8
  %9 = load i64, i64* %0
  %stack_var_-168 = alloca i64, align 8
  %10 = load i64, i64* %0
  %stack_var_-184 = alloca i64, align 8
  %11 = load i64, i64* %0
  %stack_var_-200 = alloca i64, align 8
  %12 = load i64, i64* %0
  %stack_var_-216 = alloca i64, align 8
  %13 = load i64, i64* %0
  %stack_var_-232 = alloca i64, align 8
  %14 = load i64, i64* %0
  %stack_var_-248 = alloca i64, align 8
  %15 = load i64, i64* %0
  %stack_var_-264 = alloca i64, align 8
  %16 = load i64, i64* %0
  %stack_var_-280 = alloca i64, align 8
  %17 = load i64, i64* %0
  %stack_var_-296 = alloca i64, align 8
  %18 = load i64, i64* %0
  %stack_var_-312 = alloca i64, align 8
  %19 = load i64, i64* %0
  %stack_var_-328 = alloca i64, align 8
  %20 = load i64, i64* %0
  %stack_var_-344 = alloca i64, align 8
  %21 = load i64, i64* %0
  %stack_var_-360 = alloca i64, align 8
  %22 = load i64, i64* %0
  %stack_var_-376 = alloca i64, align 8
  %23 = load i64, i64* %0
  %stack_var_-392 = alloca i64, align 8
  %24 = load i64, i64* %0
  %stack_var_-408 = alloca i64, align 8
  %25 = call i64 @__readfsqword(i64 40), !insn.addr !63
  %26 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-408, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_598d, i64 0, i64 0)), !insn.addr !64
  %27 = load i64, i64* %stack_var_-408, align 8, !insn.addr !65
  %28 = inttoptr i64 %arg2 to i64*, !insn.addr !66
  %29 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %27, i64 %24), !insn.addr !66
  %30 = trunc i64 %29 to i8, !insn.addr !67
  %31 = icmp eq i8 %30, 0, !insn.addr !67
  %32 = icmp eq i1 %31, false, !insn.addr !68
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !68
  br i1 %32, label %dec_label_pc_aa0, label %dec_label_pc_467, !insn.addr !68

dec_label_pc_467:                                 ; preds = %dec_label_pc_3ea
  %33 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-392, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_5991, i64 0, i64 0)), !insn.addr !69
  %34 = load i64, i64* %stack_var_-392, align 8, !insn.addr !70
  %35 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %34, i64 %23), !insn.addr !71
  %36 = trunc i64 %35 to i8, !insn.addr !72
  %37 = icmp eq i8 %36, 0, !insn.addr !72
  %38 = icmp eq i1 %37, false, !insn.addr !73
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !73
  br i1 %38, label %dec_label_pc_aa0, label %dec_label_pc_4af, !insn.addr !73

dec_label_pc_4af:                                 ; preds = %dec_label_pc_467
  %39 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-376, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_5995, i64 0, i64 0)), !insn.addr !74
  %40 = load i64, i64* %stack_var_-376, align 8, !insn.addr !75
  %41 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %40, i64 %22), !insn.addr !76
  %42 = trunc i64 %41 to i8, !insn.addr !77
  %43 = icmp eq i8 %42, 0, !insn.addr !77
  %44 = icmp eq i1 %43, false, !insn.addr !78
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !78
  br i1 %44, label %dec_label_pc_aa0, label %dec_label_pc_4f7, !insn.addr !78

dec_label_pc_4f7:                                 ; preds = %dec_label_pc_4af
  %45 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-360, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_5999, i64 0, i64 0)), !insn.addr !79
  %46 = load i64, i64* %stack_var_-360, align 8, !insn.addr !80
  %47 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %46, i64 %21), !insn.addr !81
  %48 = trunc i64 %47 to i8, !insn.addr !82
  %49 = icmp eq i8 %48, 0, !insn.addr !82
  %50 = icmp eq i1 %49, false, !insn.addr !83
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !83
  br i1 %50, label %dec_label_pc_aa0, label %dec_label_pc_53f, !insn.addr !83

dec_label_pc_53f:                                 ; preds = %dec_label_pc_4f7
  %51 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-344, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_599d, i64 0, i64 0)), !insn.addr !84
  %52 = load i64, i64* %stack_var_-344, align 8, !insn.addr !85
  %53 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %52, i64 %20), !insn.addr !86
  %54 = trunc i64 %53 to i8, !insn.addr !87
  %55 = icmp eq i8 %54, 0, !insn.addr !87
  %56 = icmp eq i1 %55, false, !insn.addr !88
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !88
  br i1 %56, label %dec_label_pc_aa0, label %dec_label_pc_587, !insn.addr !88

dec_label_pc_587:                                 ; preds = %dec_label_pc_53f
  %57 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-328, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59a1, i64 0, i64 0)), !insn.addr !89
  %58 = load i64, i64* %stack_var_-328, align 8, !insn.addr !90
  %59 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %58, i64 %19), !insn.addr !91
  %60 = trunc i64 %59 to i8, !insn.addr !92
  %61 = icmp eq i8 %60, 0, !insn.addr !92
  %62 = icmp eq i1 %61, false, !insn.addr !93
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !93
  br i1 %62, label %dec_label_pc_aa0, label %dec_label_pc_5cf, !insn.addr !93

dec_label_pc_5cf:                                 ; preds = %dec_label_pc_587
  %63 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-312, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59a5, i64 0, i64 0)), !insn.addr !94
  %64 = load i64, i64* %stack_var_-312, align 8, !insn.addr !95
  %65 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %64, i64 %18), !insn.addr !96
  %66 = trunc i64 %65 to i8, !insn.addr !97
  %67 = icmp eq i8 %66, 0, !insn.addr !97
  %68 = icmp eq i1 %67, false, !insn.addr !98
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !98
  br i1 %68, label %dec_label_pc_aa0, label %dec_label_pc_617, !insn.addr !98

dec_label_pc_617:                                 ; preds = %dec_label_pc_5cf
  %69 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-296, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59a9, i64 0, i64 0)), !insn.addr !99
  %70 = load i64, i64* %stack_var_-296, align 8, !insn.addr !100
  %71 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %70, i64 %17), !insn.addr !101
  %72 = trunc i64 %71 to i8, !insn.addr !102
  %73 = icmp eq i8 %72, 0, !insn.addr !102
  %74 = icmp eq i1 %73, false, !insn.addr !103
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !103
  br i1 %74, label %dec_label_pc_aa0, label %dec_label_pc_65f, !insn.addr !103

dec_label_pc_65f:                                 ; preds = %dec_label_pc_617
  %75 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-280, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59ad, i64 0, i64 0)), !insn.addr !104
  %76 = load i64, i64* %stack_var_-280, align 8, !insn.addr !105
  %77 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %76, i64 %16), !insn.addr !106
  %78 = trunc i64 %77 to i8, !insn.addr !107
  %79 = icmp eq i8 %78, 0, !insn.addr !107
  %80 = icmp eq i1 %79, false, !insn.addr !108
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !108
  br i1 %80, label %dec_label_pc_aa0, label %dec_label_pc_6a7, !insn.addr !108

dec_label_pc_6a7:                                 ; preds = %dec_label_pc_65f
  %81 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-264, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59b0, i64 0, i64 0)), !insn.addr !109
  %82 = load i64, i64* %stack_var_-264, align 8, !insn.addr !110
  %83 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %82, i64 %15), !insn.addr !111
  %84 = trunc i64 %83 to i8, !insn.addr !112
  %85 = icmp eq i8 %84, 0, !insn.addr !112
  %86 = icmp eq i1 %85, false, !insn.addr !113
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !113
  br i1 %86, label %dec_label_pc_aa0, label %dec_label_pc_6ef, !insn.addr !113

dec_label_pc_6ef:                                 ; preds = %dec_label_pc_6a7
  %87 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-248, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59b3, i64 0, i64 0)), !insn.addr !114
  %88 = load i64, i64* %stack_var_-248, align 8, !insn.addr !115
  %89 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %88, i64 %14), !insn.addr !116
  %90 = trunc i64 %89 to i8, !insn.addr !117
  %91 = icmp eq i8 %90, 0, !insn.addr !117
  %92 = icmp eq i1 %91, false, !insn.addr !118
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !118
  br i1 %92, label %dec_label_pc_aa0, label %dec_label_pc_737, !insn.addr !118

dec_label_pc_737:                                 ; preds = %dec_label_pc_6ef
  %93 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-232, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59b7, i64 0, i64 0)), !insn.addr !119
  %94 = load i64, i64* %stack_var_-232, align 8, !insn.addr !120
  %95 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %94, i64 %13), !insn.addr !121
  %96 = trunc i64 %95 to i8, !insn.addr !122
  %97 = icmp eq i8 %96, 0, !insn.addr !122
  %98 = icmp eq i1 %97, false, !insn.addr !123
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !123
  br i1 %98, label %dec_label_pc_aa0, label %dec_label_pc_77f, !insn.addr !123

dec_label_pc_77f:                                 ; preds = %dec_label_pc_737
  %99 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-216, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59bb, i64 0, i64 0)), !insn.addr !124
  %100 = load i64, i64* %stack_var_-216, align 8, !insn.addr !125
  %101 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %100, i64 %12), !insn.addr !126
  %102 = trunc i64 %101 to i8, !insn.addr !127
  %103 = icmp eq i8 %102, 0, !insn.addr !127
  %104 = icmp eq i1 %103, false, !insn.addr !128
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !128
  br i1 %104, label %dec_label_pc_aa0, label %dec_label_pc_7c7, !insn.addr !128

dec_label_pc_7c7:                                 ; preds = %dec_label_pc_77f
  %105 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-200, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59bf, i64 0, i64 0)), !insn.addr !129
  %106 = load i64, i64* %stack_var_-200, align 8, !insn.addr !130
  %107 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %106, i64 %11), !insn.addr !131
  %108 = trunc i64 %107 to i8, !insn.addr !132
  %109 = icmp eq i8 %108, 0, !insn.addr !132
  %110 = icmp eq i1 %109, false, !insn.addr !133
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !133
  br i1 %110, label %dec_label_pc_aa0, label %dec_label_pc_80f, !insn.addr !133

dec_label_pc_80f:                                 ; preds = %dec_label_pc_7c7
  %111 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-184, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59c3, i64 0, i64 0)), !insn.addr !134
  %112 = load i64, i64* %stack_var_-184, align 8, !insn.addr !135
  %113 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %112, i64 %10), !insn.addr !136
  %114 = trunc i64 %113 to i8, !insn.addr !137
  %115 = icmp eq i8 %114, 0, !insn.addr !137
  %116 = icmp eq i1 %115, false, !insn.addr !138
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !138
  br i1 %116, label %dec_label_pc_aa0, label %dec_label_pc_857, !insn.addr !138

dec_label_pc_857:                                 ; preds = %dec_label_pc_80f
  %117 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-168, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59c7, i64 0, i64 0)), !insn.addr !139
  %118 = load i64, i64* %stack_var_-168, align 8, !insn.addr !140
  %119 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %118, i64 %9), !insn.addr !141
  %120 = trunc i64 %119 to i8, !insn.addr !142
  %121 = icmp eq i8 %120, 0, !insn.addr !142
  %122 = icmp eq i1 %121, false, !insn.addr !143
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !143
  br i1 %122, label %dec_label_pc_aa0, label %dec_label_pc_89f, !insn.addr !143

dec_label_pc_89f:                                 ; preds = %dec_label_pc_857
  %123 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-152, i8* getelementptr inbounds ([4 x i8], [4 x i8]* @global_var_59cb, i64 0, i64 0)), !insn.addr !144
  %124 = load i64, i64* %stack_var_-152, align 8, !insn.addr !145
  %125 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %124, i64 %8), !insn.addr !146
  %126 = trunc i64 %125 to i8, !insn.addr !147
  %127 = icmp eq i8 %126, 0, !insn.addr !147
  %128 = icmp eq i1 %127, false, !insn.addr !148
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !148
  br i1 %128, label %dec_label_pc_aa0, label %dec_label_pc_8e7, !insn.addr !148

dec_label_pc_8e7:                                 ; preds = %dec_label_pc_89f
  %129 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-136, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59cf, i64 0, i64 0)), !insn.addr !149
  %130 = load i64, i64* %stack_var_-136, align 8, !insn.addr !150
  %131 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %130, i64 %7), !insn.addr !151
  %132 = trunc i64 %131 to i8, !insn.addr !152
  %133 = icmp eq i8 %132, 0, !insn.addr !152
  %134 = icmp eq i1 %133, false, !insn.addr !153
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !153
  br i1 %134, label %dec_label_pc_aa0, label %dec_label_pc_926, !insn.addr !153

dec_label_pc_926:                                 ; preds = %dec_label_pc_8e7
  %135 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-120, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59d2, i64 0, i64 0)), !insn.addr !154
  %136 = load i64, i64* %stack_var_-120, align 8, !insn.addr !155
  %137 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %136, i64 %6), !insn.addr !156
  %138 = trunc i64 %137 to i8, !insn.addr !157
  %139 = icmp eq i8 %138, 0, !insn.addr !157
  %140 = icmp eq i1 %139, false, !insn.addr !158
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !158
  br i1 %140, label %dec_label_pc_aa0, label %dec_label_pc_965, !insn.addr !158

dec_label_pc_965:                                 ; preds = %dec_label_pc_926
  %141 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-104, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59d5, i64 0, i64 0)), !insn.addr !159
  %142 = load i64, i64* %stack_var_-104, align 8, !insn.addr !160
  %143 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %142, i64 %5), !insn.addr !161
  %144 = trunc i64 %143 to i8, !insn.addr !162
  %145 = icmp eq i8 %144, 0, !insn.addr !162
  %146 = icmp eq i1 %145, false, !insn.addr !163
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !163
  br i1 %146, label %dec_label_pc_aa0, label %dec_label_pc_9a4, !insn.addr !163

dec_label_pc_9a4:                                 ; preds = %dec_label_pc_965
  %147 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-88, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59d8, i64 0, i64 0)), !insn.addr !164
  %148 = load i64, i64* %stack_var_-88, align 8, !insn.addr !165
  %149 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %148, i64 %4), !insn.addr !166
  %150 = trunc i64 %149 to i8, !insn.addr !167
  %151 = icmp eq i8 %150, 0, !insn.addr !167
  %152 = icmp eq i1 %151, false, !insn.addr !168
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !168
  br i1 %152, label %dec_label_pc_aa0, label %dec_label_pc_9e3, !insn.addr !168

dec_label_pc_9e3:                                 ; preds = %dec_label_pc_9a4
  %153 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-72, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59db, i64 0, i64 0)), !insn.addr !169
  %154 = load i64, i64* %stack_var_-72, align 8, !insn.addr !170
  %155 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %154, i64 %3), !insn.addr !171
  %156 = trunc i64 %155 to i8, !insn.addr !172
  %157 = icmp eq i8 %156, 0, !insn.addr !172
  %158 = icmp eq i1 %157, false, !insn.addr !173
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !173
  br i1 %158, label %dec_label_pc_aa0, label %dec_label_pc_a1e, !insn.addr !173

dec_label_pc_a1e:                                 ; preds = %dec_label_pc_9e3
  %159 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-56, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59de, i64 0, i64 0)), !insn.addr !174
  %160 = load i64, i64* %stack_var_-56, align 8, !insn.addr !175
  %161 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %160, i64 %2), !insn.addr !176
  %162 = trunc i64 %161 to i8, !insn.addr !177
  %163 = icmp eq i8 %162, 0, !insn.addr !177
  %164 = icmp eq i1 %163, false, !insn.addr !178
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !178
  br i1 %164, label %dec_label_pc_aa0, label %dec_label_pc_a59, !insn.addr !178

dec_label_pc_a59:                                 ; preds = %dec_label_pc_a1e
  %165 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-40, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @global_var_59e1, i64 0, i64 0)), !insn.addr !179
  %166 = load i64, i64* %stack_var_-40, align 8, !insn.addr !180
  %167 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %result, i64* %28, i64 %166, i64 %1), !insn.addr !181
  %168 = trunc i64 %167 to i8, !insn.addr !182
  %169 = icmp ne i8 %168, 0, !insn.addr !182
  %spec.select = zext i1 %169 to i64
  store i64 %spec.select, i64* %storemerge.reg2mem
  br label %dec_label_pc_aa0

dec_label_pc_aa0:                                 ; preds = %dec_label_pc_a59, %dec_label_pc_3ea, %dec_label_pc_467, %dec_label_pc_4af, %dec_label_pc_4f7, %dec_label_pc_53f, %dec_label_pc_587, %dec_label_pc_5cf, %dec_label_pc_617, %dec_label_pc_65f, %dec_label_pc_6a7, %dec_label_pc_6ef, %dec_label_pc_737, %dec_label_pc_77f, %dec_label_pc_7c7, %dec_label_pc_80f, %dec_label_pc_857, %dec_label_pc_89f, %dec_label_pc_8e7, %dec_label_pc_926, %dec_label_pc_965, %dec_label_pc_9a4, %dec_label_pc_9e3, %dec_label_pc_a1e
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %170 = call i64 @__readfsqword(i64 40), !insn.addr !183
  %171 = icmp eq i64 %25, %170, !insn.addr !183
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !184
  br i1 %171, label %dec_label_pc_ab4, label %dec_label_pc_aaf, !insn.addr !184

dec_label_pc_aaf:                                 ; preds = %dec_label_pc_aa0
  %172 = call i64 @__stack_chk_fail(), !insn.addr !185
  store i64 %172, i64* %rax.0.reg2mem, !insn.addr !185
  br label %dec_label_pc_ab4, !insn.addr !185

dec_label_pc_ab4:                                 ; preds = %dec_label_pc_aaf, %dec_label_pc_aa0
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !186

; uselistorder directives
  uselistorder i64* %stack_var_-408, { 1, 0 }
  uselistorder i64* %stack_var_-392, { 1, 0 }
  uselistorder i64* %stack_var_-376, { 1, 0 }
  uselistorder i64* %stack_var_-360, { 1, 0 }
  uselistorder i64* %stack_var_-344, { 1, 0 }
  uselistorder i64* %stack_var_-328, { 1, 0 }
  uselistorder i64* %stack_var_-312, { 1, 0 }
  uselistorder i64* %stack_var_-296, { 1, 0 }
  uselistorder i64* %stack_var_-280, { 1, 0 }
  uselistorder i64* %stack_var_-264, { 1, 0 }
  uselistorder i64* %stack_var_-248, { 1, 0 }
  uselistorder i64* %stack_var_-232, { 1, 0 }
  uselistorder i64* %stack_var_-216, { 1, 0 }
  uselistorder i64* %stack_var_-200, { 1, 0 }
  uselistorder i64* %stack_var_-184, { 1, 0 }
  uselistorder i64* %stack_var_-168, { 1, 0 }
  uselistorder i64* %stack_var_-152, { 1, 0 }
  uselistorder i64* %stack_var_-136, { 1, 0 }
  uselistorder i64* %stack_var_-120, { 1, 0 }
  uselistorder i64* %stack_var_-104, { 1, 0 }
  uselistorder i64* %stack_var_-88, { 1, 0 }
  uselistorder i64* %stack_var_-72, { 1, 0 }
  uselistorder i64* %stack_var_-56, { 1, 0 }
  uselistorder i64* %stack_var_-40, { 1, 0 }
  uselistorder i64* %storemerge.reg2mem, { 0, 1, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 }
  uselistorder i64* %0, { 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
  uselistorder label %dec_label_pc_aa0, { 0, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1 }
}

define i64 @_ZNSt14_Optional_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0EED2Ev(i64* %result) local_unnamed_addr {
dec_label_pc_ab6:
  %0 = call i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0ELb0EED1Ev(i64* %result), !insn.addr !187
  ret i64 %0, !insn.addr !188
}

define i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_ad2:
  %0 = call i64 @_ZNSt14_Optional_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0EED2Ev(i64* %result), !insn.addr !189
  ret i64 %0, !insn.addr !190
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_aee:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(i64* %result), !insn.addr !191
  %2 = add i64 %0, 32, !insn.addr !192
  %3 = inttoptr i64 %2 to i64*, !insn.addr !193
  %4 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(i64* %3), !insn.addr !193
  %5 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !194
  %6 = inttoptr i64 %5 to i64*, !insn.addr !194
  store i64 0, i64* %6, align 8, !insn.addr !194
  ret i64 %0, !insn.addr !195

; uselistorder directives
  uselistorder i64 %0, { 1, 0, 2 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L18ClassifyStateAliasEPN4llvm5ValueE(i64* %this, i64* %result, i64* %arg3) local_unnamed_addr {
dec_label_pc_b25:
  %storemerge1.reg2mem = alloca i64*, !insn.addr !196
  %stack_var_-168 = alloca i64, align 8
  %stack_var_-264 = alloca i64, align 8
  %stack_var_-216 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-120 = alloca i64, align 8
  %stack_var_-88 = alloca i64, align 8
  %stack_var_-344 = alloca i64, align 8
  %stack_var_-280 = alloca i64, align 8
  %stack_var_-296 = alloca i64, align 8
  %stack_var_-312 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !197
  %1 = icmp eq i64* %result, null, !insn.addr !198
  store i64* null, i64** %storemerge1.reg2mem, !insn.addr !199
  br i1 %1, label %dec_label_pc_b71, label %dec_label_pc_b5b, !insn.addr !199

dec_label_pc_b5b:                                 ; preds = %dec_label_pc_b25
  %2 = call i64 @_ZN4llvm5Value17stripPointerCastsEv(i64* nonnull %result), !insn.addr !200
  %phitmp = inttoptr i64 %2 to i64*
  store i64* %phitmp, i64** %storemerge1.reg2mem, !insn.addr !201
  br label %dec_label_pc_b71, !insn.addr !201

dec_label_pc_b71:                                 ; preds = %dec_label_pc_b25, %dec_label_pc_b5b
  %3 = ptrtoint i64* %this to i64
  %storemerge1.reload = load i64*, i64** %storemerge1.reg2mem
  %4 = call i64 @_ZN4llvm16dyn_cast_or_nullINS_11GlobalAliasENS_5ValueEEEDaPT0_(i64* %storemerge1.reload), !insn.addr !202
  %5 = icmp eq i64 %4, 0, !insn.addr !203
  %6 = icmp eq i1 %5, false, !insn.addr !204
  br i1 %6, label %dec_label_pc_b9e, label %dec_label_pc_b8a, !insn.addr !204

dec_label_pc_b8a:                                 ; preds = %dec_label_pc_b71
  %7 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1ESt9nullopt_t(i64 %3), !insn.addr !205
  br label %dec_label_pc_e2b, !insn.addr !206

dec_label_pc_b9e:                                 ; preds = %dec_label_pc_b71
  %8 = inttoptr i64 %4 to i64*, !insn.addr !207
  %9 = call i64 @_ZNK4llvm5Value7getNameEv(i64* %8), !insn.addr !207
  store i64 %9, i64* %stack_var_-312, align 8, !insn.addr !208
  %10 = call i64 @_ZNK4llvm9StringRef4findEcm(i64* nonnull %stack_var_-312, i8 95, i64 0), !insn.addr !209
  %11 = icmp eq i64 %10, -1, !insn.addr !210
  %12 = icmp eq i1 %11, false, !insn.addr !211
  br i1 %12, label %dec_label_pc_bf9, label %dec_label_pc_be5, !insn.addr !211

dec_label_pc_be5:                                 ; preds = %dec_label_pc_b9e
  %13 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1ESt9nullopt_t(i64 %3), !insn.addr !212
  br label %dec_label_pc_e2b, !insn.addr !213

dec_label_pc_bf9:                                 ; preds = %dec_label_pc_b9e
  %14 = call i64 @_ZNK4llvm9StringRef10take_frontEm(i64* nonnull %stack_var_-312, i64 %10), !insn.addr !214
  store i64 %14, i64* %stack_var_-296, align 8, !insn.addr !215
  %15 = inttoptr i64 %14 to i64*, !insn.addr !216
  %16 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L15IsKnownStateRegEN4llvm9StringRefE(i64* %15, i64 %10), !insn.addr !216
  %17 = trunc i64 %16 to i8
  %18 = icmp eq i8 %17, 1, !insn.addr !217
  br i1 %18, label %dec_label_pc_c54, label %dec_label_pc_c40, !insn.addr !218

dec_label_pc_c40:                                 ; preds = %dec_label_pc_bf9
  %19 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1ESt9nullopt_t(i64 %3), !insn.addr !219
  br label %dec_label_pc_e2b, !insn.addr !220

dec_label_pc_c54:                                 ; preds = %dec_label_pc_bf9
  %20 = add i64 %10, 1, !insn.addr !221
  %21 = call i64 @_ZNK4llvm9StringRef4findEcm(i64* nonnull %stack_var_-312, i8 95, i64 %20), !insn.addr !222
  %22 = icmp eq i64 %21, -1, !insn.addr !223
  %23 = icmp eq i1 %22, false, !insn.addr !224
  br i1 %23, label %dec_label_pc_c98, label %dec_label_pc_c84, !insn.addr !224

dec_label_pc_c84:                                 ; preds = %dec_label_pc_c54
  %24 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1ESt9nullopt_t(i64 %3), !insn.addr !225
  br label %dec_label_pc_e2b, !insn.addr !226

dec_label_pc_c98:                                 ; preds = %dec_label_pc_c54
  %25 = call i64 @_ZNK4llvm9StringRef5sliceEmm(i64* nonnull %stack_var_-312, i64 %20, i64 %21), !insn.addr !227
  store i64 %25, i64* %stack_var_-280, align 8, !insn.addr !228
  store i64 0, i64* %stack_var_-344, align 8, !insn.addr !229
  %26 = call i64 @_ZNK4llvm9StringRef5emptyEv(i64* nonnull %stack_var_-280), !insn.addr !230
  %27 = trunc i64 %26 to i8, !insn.addr !231
  %28 = icmp eq i8 %27, 0, !insn.addr !231
  %29 = icmp eq i1 %28, false, !insn.addr !232
  br i1 %29, label %dec_label_pc_d17, label %dec_label_pc_ce8, !insn.addr !232

dec_label_pc_ce8:                                 ; preds = %dec_label_pc_c98
  %30 = bitcast i64* %stack_var_-344 to i32*, !insn.addr !233
  %31 = call i1 @_ZNK4llvm9StringRef12getAsIntegerIlEEbjRT_(i64* nonnull %stack_var_-280, i32 10, i32* nonnull %30), !insn.addr !233
  %32 = icmp eq i1 %31, false, !insn.addr !234
  br i1 %32, label %dec_label_pc_d0e, label %dec_label_pc_d17, !insn.addr !235

dec_label_pc_d0e:                                 ; preds = %dec_label_pc_ce8
  %33 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyC1Ev(i64* nonnull %stack_var_-88), !insn.addr !236
  %34 = call i64 @_ZNK4llvm9StringRef3strB5cxx11Ev(i64* nonnull %stack_var_-120, i64* nonnull %stack_var_-296), !insn.addr !237
  %35 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEOS4_(i64* nonnull %stack_var_-56, i64* nonnull %stack_var_-120, i64* nonnull %stack_var_-56), !insn.addr !238
  %36 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(i64* nonnull %stack_var_-120), !insn.addr !239
  %37 = call i64 @_ZN4llvm5TwineC1ERKNS_9StringRefE(i64* nonnull %stack_var_-216, i64* nonnull %stack_var_-280), !insn.addr !240
  %38 = call i64 @_ZN4llvmplERKNS_9StringRefEPKc(i64* nonnull %stack_var_-264, i64* nonnull %stack_var_-296, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @global_var_59f3, i64 0, i64 0)), !insn.addr !241
  %39 = call i64 @_ZN4llvmplERKNS_5TwineES2_(i64* nonnull %stack_var_-168, i64* nonnull %stack_var_-264, i64* nonnull %stack_var_-216), !insn.addr !242
  %40 = call i64 @_ZNK4llvm5Twine3strB5cxx11Ev(i64* nonnull %stack_var_-120, i64* nonnull %stack_var_-168, i64* nonnull %stack_var_-168), !insn.addr !243
  %41 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEOS4_(i64* nonnull %stack_var_-88, i64* nonnull %stack_var_-120, i64* nonnull %stack_var_-120), !insn.addr !244
  %42 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(i64* nonnull %stack_var_-120), !insn.addr !245
  %43 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1IS2_Lb1EEEOT_(i64* %this, i64* nonnull %stack_var_-88), !insn.addr !246
  %44 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-88), !insn.addr !247
  br label %dec_label_pc_e2b, !insn.addr !247

dec_label_pc_d17:                                 ; preds = %dec_label_pc_ce8, %dec_label_pc_c98
  %45 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1ESt9nullopt_t(i64 %3), !insn.addr !248
  br label %dec_label_pc_e2b, !insn.addr !249

dec_label_pc_e2b:                                 ; preds = %dec_label_pc_d0e, %dec_label_pc_d17, %dec_label_pc_c84, %dec_label_pc_c40, %dec_label_pc_be5, %dec_label_pc_b8a
  %46 = call i64 @__readfsqword(i64 40), !insn.addr !250
  %47 = icmp eq i64 %0, %46, !insn.addr !250
  br i1 %47, label %dec_label_pc_e3f, label %dec_label_pc_e3a, !insn.addr !251

dec_label_pc_e3a:                                 ; preds = %dec_label_pc_e2b
  %48 = call i64 @__stack_chk_fail(), !insn.addr !252
  br label %dec_label_pc_e3f, !insn.addr !252

dec_label_pc_e3f:                                 ; preds = %dec_label_pc_e3a, %dec_label_pc_e2b
  ret i64 %3, !insn.addr !253

; uselistorder directives
  uselistorder i64 %10, { 0, 2, 1, 3 }
  uselistorder i64 %3, { 4, 5, 3, 2, 1, 0 }
  uselistorder i64** %storemerge1.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*)* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev, { 3, 2, 1, 0 }
  uselistorder i64 (i64*, i8, i64)* @_ZNK4llvm9StringRef4findEcm, { 1, 0 }
  uselistorder i64 (i64)* @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1ESt9nullopt_t, { 4, 3, 2, 1, 0 }
  uselistorder label %dec_label_pc_e2b, { 1, 0, 2, 3, 4, 5 }
  uselistorder label %dec_label_pc_b71, { 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L15CastStoredValueERN4llvm9IRBuilderINS1_14ConstantFolderENS1_24IRBuilderDefaultInserterEEEPNS1_5ValueEPNS1_4TypeE(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_e48:
  %rax.1.reg2mem = alloca i64, !insn.addr !254
  %rax.0.reg2mem = alloca i64, !insn.addr !254
  %0 = ptrtoint i64* %arg3 to i64
  %1 = ptrtoint i64* %arg2 to i64
  %stack_var_-72 = alloca i64, align 8
  %stack_var_-88 = alloca i64, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !255
  %3 = call i64 @_ZNK4llvm5Value7getTypeEv(i64* %arg2), !insn.addr !256
  %4 = icmp eq i64 %3, %0, !insn.addr !257
  %5 = icmp eq i1 %4, false, !insn.addr !258
  store i64 %1, i64* %rax.0.reg2mem, !insn.addr !258
  br i1 %5, label %dec_label_pc_e9c, label %dec_label_pc_10c3, !insn.addr !258

dec_label_pc_e9c:                                 ; preds = %dec_label_pc_e48
  %6 = inttoptr i64 %3 to i64*, !insn.addr !259
  %7 = call i64 @_ZNK4llvm4Type11isPointerTyEv(i64* %6), !insn.addr !259
  %8 = trunc i64 %7 to i8, !insn.addr !260
  %9 = icmp eq i8 %8, 0, !insn.addr !260
  br i1 %9, label %dec_label_pc_ec6, label %dec_label_pc_eac, !insn.addr !261

dec_label_pc_eac:                                 ; preds = %dec_label_pc_e9c
  %10 = call i64 @_ZNK4llvm4Type11isIntegerTyEv(i64* %arg3), !insn.addr !262
  %11 = trunc i64 %10 to i8, !insn.addr !263
  %12 = icmp eq i8 %11, 0, !insn.addr !263
  br i1 %12, label %dec_label_pc_ec6, label %dec_label_pc_ecf, !insn.addr !264

dec_label_pc_ec6:                                 ; preds = %dec_label_pc_eac, %dec_label_pc_e9c
  %13 = call i64 @_ZNK4llvm4Type11isIntegerTyEv(i64* %6), !insn.addr !265
  %14 = trunc i64 %13 to i8, !insn.addr !266
  %15 = icmp eq i8 %14, 0, !insn.addr !266
  br i1 %15, label %dec_label_pc_f4a, label %dec_label_pc_f30, !insn.addr !267

dec_label_pc_ecf:                                 ; preds = %dec_label_pc_eac
  %16 = call i64 @_ZNK4llvm5Value7getNameEv(i64* %arg2), !insn.addr !268
  store i64 %16, i64* %stack_var_-88, align 8, !insn.addr !269
  %17 = call i64 @_ZN4llvmplERKNS_9StringRefEPKc(i64* nonnull %stack_var_-72, i64* nonnull %stack_var_-88, i8* getelementptr inbounds ([8 x i8], [8 x i8]* @global_var_5a46, i64 0, i64 0)), !insn.addr !270
  %18 = call i64 @_ZN4llvm13IRBuilderBase14CreatePtrToIntEPNS_5ValueEPNS_4TypeERKNS_5TwineE(i64* %arg1, i64* %arg2, i64* %arg3, i64* nonnull %stack_var_-72), !insn.addr !271
  store i64 %18, i64* %rax.0.reg2mem, !insn.addr !272
  br label %dec_label_pc_10c3, !insn.addr !272

dec_label_pc_f30:                                 ; preds = %dec_label_pc_ec6
  %19 = call i64 @_ZNK4llvm4Type11isPointerTyEv(i64* %arg3), !insn.addr !273
  %20 = trunc i64 %19 to i8, !insn.addr !274
  %21 = icmp eq i8 %20, 0, !insn.addr !274
  br i1 %21, label %dec_label_pc_f4a, label %dec_label_pc_f53, !insn.addr !275

dec_label_pc_f4a:                                 ; preds = %dec_label_pc_f30, %dec_label_pc_ec6
  %22 = call i64 @_ZN4llvm8dyn_castINS_11IntegerTypeENS_4TypeEEEDcPT0_(i64* %6), !insn.addr !276
  %23 = call i64 @_ZN4llvm8dyn_castINS_11IntegerTypeENS_4TypeEEEDcPT0_(i64* %arg3), !insn.addr !277
  %24 = icmp ne i64 %22, 0, !insn.addr !278
  %25 = icmp eq i64 %23, 0, !insn.addr !279
  %26 = icmp eq i1 %25, false, !insn.addr !280
  %or.cond = icmp eq i1 %24, %26
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !281
  br i1 %or.cond, label %dec_label_pc_fdf, label %dec_label_pc_10c3, !insn.addr !281

dec_label_pc_f53:                                 ; preds = %dec_label_pc_f30
  %27 = call i64 @_ZNK4llvm5Value7getNameEv(i64* %arg2), !insn.addr !282
  store i64 %27, i64* %stack_var_-88, align 8, !insn.addr !283
  %28 = call i64 @_ZN4llvmplERKNS_9StringRefEPKc(i64* nonnull %stack_var_-72, i64* nonnull %stack_var_-88, i8* getelementptr inbounds ([8 x i8], [8 x i8]* @global_var_5a4e, i64 0, i64 0)), !insn.addr !284
  %29 = call i64 @_ZN4llvm13IRBuilderBase14CreateIntToPtrEPNS_5ValueEPNS_4TypeERKNS_5TwineE(i64* %arg1, i64* %arg2, i64* %arg3, i64* nonnull %stack_var_-72), !insn.addr !285
  store i64 %29, i64* %rax.0.reg2mem, !insn.addr !286
  br label %dec_label_pc_10c3, !insn.addr !286

dec_label_pc_fdf:                                 ; preds = %dec_label_pc_f4a
  %30 = inttoptr i64 %22 to i64*, !insn.addr !287
  %31 = call i64 @_ZNK4llvm11IntegerType11getBitWidthEv(i64* %30), !insn.addr !287
  %32 = trunc i64 %31 to i32, !insn.addr !288
  %33 = inttoptr i64 %23 to i64*, !insn.addr !289
  %34 = call i64 @_ZNK4llvm11IntegerType11getBitWidthEv(i64* %33), !insn.addr !289
  %35 = trunc i64 %34 to i32, !insn.addr !290
  %36 = icmp eq i32 %32, %35, !insn.addr !291
  %37 = icmp eq i1 %36, false, !insn.addr !292
  store i64 %1, i64* %rax.0.reg2mem, !insn.addr !292
  br i1 %37, label %dec_label_pc_100e, label %dec_label_pc_10c3, !insn.addr !292

dec_label_pc_100e:                                ; preds = %dec_label_pc_fdf
  %38 = icmp ult i32 %32, %35, !insn.addr !293
  %39 = icmp eq i1 %38, false, !insn.addr !294
  %40 = call i64 @_ZNK4llvm5Value7getNameEv(i64* %arg2)
  store i64 %40, i64* %stack_var_-88, align 8
  br i1 %39, label %dec_label_pc_106a, label %dec_label_pc_1016, !insn.addr !294

dec_label_pc_1016:                                ; preds = %dec_label_pc_100e
  %41 = call i64 @_ZN4llvmplERKNS_9StringRefEPKc(i64* nonnull %stack_var_-72, i64* nonnull %stack_var_-88, i8* getelementptr inbounds ([6 x i8], [6 x i8]* @global_var_5a56, i64 0, i64 0)), !insn.addr !295
  %42 = call i64 @_ZN4llvm13IRBuilderBase10CreateZExtEPNS_5ValueEPNS_4TypeERKNS_5TwineEb(i64* %arg1, i64* %arg2, i64* %arg3, i64* nonnull %stack_var_-72, i1 false), !insn.addr !296
  store i64 %42, i64* %rax.0.reg2mem, !insn.addr !297
  br label %dec_label_pc_10c3, !insn.addr !297

dec_label_pc_106a:                                ; preds = %dec_label_pc_100e
  %43 = call i64 @_ZN4llvmplERKNS_9StringRefEPKc(i64* nonnull %stack_var_-72, i64* nonnull %stack_var_-88, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @global_var_5a5c, i64 0, i64 0)), !insn.addr !298
  %44 = call i64 @_ZN4llvm13IRBuilderBase11CreateTruncEPNS_5ValueEPNS_4TypeERKNS_5TwineEbb(i64* %arg1, i64* %arg2, i64* %arg3, i64* nonnull %stack_var_-72, i1 false, i1 false), !insn.addr !299
  store i64 %44, i64* %rax.0.reg2mem, !insn.addr !300
  br label %dec_label_pc_10c3, !insn.addr !300

dec_label_pc_10c3:                                ; preds = %dec_label_pc_fdf, %dec_label_pc_f4a, %dec_label_pc_e48, %dec_label_pc_106a, %dec_label_pc_1016, %dec_label_pc_f53, %dec_label_pc_ecf
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %45 = call i64 @__readfsqword(i64 40), !insn.addr !301
  %46 = icmp eq i64 %2, %45, !insn.addr !301
  store i64 %rax.0.reload, i64* %rax.1.reg2mem, !insn.addr !302
  br i1 %46, label %dec_label_pc_10d7, label %dec_label_pc_10d2, !insn.addr !302

dec_label_pc_10d2:                                ; preds = %dec_label_pc_10c3
  %47 = call i64 @__stack_chk_fail(), !insn.addr !303
  store i64 %47, i64* %rax.1.reg2mem, !insn.addr !303
  br label %dec_label_pc_10d7, !insn.addr !303

dec_label_pc_10d7:                                ; preds = %dec_label_pc_10d2, %dec_label_pc_10c3
  %rax.1.reload = load i64, i64* %rax.1.reg2mem
  ret i64 %rax.1.reload, !insn.addr !304

; uselistorder directives
  uselistorder i64 %23, { 1, 0 }
  uselistorder i64* %stack_var_-88, { 0, 1, 4, 2, 5, 3, 6 }
  uselistorder i64* %rax.0.reg2mem, { 0, 7, 6, 1, 5, 2, 4, 3 }
  uselistorder i64 (i64*)* @_ZNK4llvm11IntegerType11getBitWidthEv, { 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm8dyn_castINS_11IntegerTypeENS_4TypeEEEDcPT0_, { 1, 0 }
  uselistorder i64 (i64*, i64*, i8*)* @_ZN4llvmplERKNS_9StringRefEPKc, { 4, 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm4Type11isIntegerTyEv, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm4Type11isPointerTyEv, { 1, 0 }
  uselistorder i64* %arg3, { 0, 1, 3, 2, 4, 5, 6, 7 }
  uselistorder i64* %arg2, { 1, 0, 2, 3, 4, 5, 6, 7, 8 }
  uselistorder label %dec_label_pc_10c3, { 3, 4, 0, 5, 1, 6, 2 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L13IsBarrierCallERN4llvm8CallBaseE(i64* %arg1) local_unnamed_addr {
dec_label_pc_10dd:
  %rax.0.reg2mem = alloca i64, !insn.addr !305
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-24 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !306
  store i64 %0, i64* %stack_var_-24, align 8, !insn.addr !307
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !308
  %3 = call i1 @_ZN4llvm3isaINS_16DbgInfoIntrinsicEPNS_8CallBaseEEEbRKT0_(i64** nonnull %2), !insn.addr !308
  %4 = icmp eq i1 %3, false, !insn.addr !309
  %. = zext i1 %4 to i64
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !310
  %6 = icmp eq i64 %1, %5, !insn.addr !310
  store i64 %., i64* %rax.0.reg2mem, !insn.addr !311
  br i1 %6, label %dec_label_pc_1134, label %dec_label_pc_112f, !insn.addr !311

dec_label_pc_112f:                                ; preds = %dec_label_pc_10dd
  %7 = call i64 @__stack_chk_fail(), !insn.addr !312
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !312
  br label %dec_label_pc_1134, !insn.addr !312

dec_label_pc_1134:                                ; preds = %dec_label_pc_112f, %dec_label_pc_10dd
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !313
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L15ForwardFunctionERN4llvm8FunctionE(i64* %arg1) local_unnamed_addr {
dec_label_pc_1136:
  %rax.0.reg2mem = alloca i64, !insn.addr !314
  %rbx.0.reg2mem = alloca i64, !insn.addr !314
  %stack_var_-744.08.reg2mem = alloca i64, !insn.addr !314
  %stack_var_-764.4.lcssa.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-765.4.lcssa.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-764.3.lcssa.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-765.3.lcssa.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-764.2.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-765.2.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-764.1.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-765.1.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-764.0.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-765.0.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-765.39.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-764.310.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-765.412.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-764.413.reg2mem = alloca i32, !insn.addr !314
  %stack_var_-472 = alloca i64, align 8
  %stack_var_-600 = alloca i64, align 8
  %stack_var_-616 = alloca i64, align 8
  %stack_var_-552 = alloca i64, align 8
  %stack_var_-632 = alloca i64, align 8
  %stack_var_-648 = alloca i64, align 8
  %stack_var_-584 = alloca i64, align 8
  %stack_var_-752 = alloca i64, align 8
  %stack_var_-760 = alloca i64, align 8
  %stack_var_-312 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !315
  %1 = call i64 @_ZNK4llvm11GlobalValue13isDeclarationEv(i64* %arg1), !insn.addr !316
  %2 = trunc i64 %1 to i8, !insn.addr !317
  %3 = icmp eq i8 %2, 0, !insn.addr !317
  %4 = icmp eq i1 %3, false, !insn.addr !318
  store i64 0, i64* %rbx.0.reg2mem, !insn.addr !318
  br i1 %4, label %dec_label_pc_17e4, label %dec_label_pc_1171, !insn.addr !318

dec_label_pc_1171:                                ; preds = %dec_label_pc_1136
  %5 = call i64 @_ZNK4llvm8Function5emptyEv(i64* %arg1), !insn.addr !319
  %6 = trunc i64 %5 to i8, !insn.addr !320
  %7 = icmp ne i8 %6, 0, !insn.addr !320
  %phitmp = icmp eq i1 %7, false
  store i64 0, i64* %rbx.0.reg2mem, !insn.addr !321
  br i1 %phitmp, label %dec_label_pc_119e, label %dec_label_pc_17e4, !insn.addr !321

dec_label_pc_119e:                                ; preds = %dec_label_pc_1171
  %8 = call i64 @_ZN4llvm11SmallVectorIPNS_11InstructionELj32EEC1Ev(i64* nonnull %stack_var_-312), !insn.addr !322
  %9 = call i64 @_ZN4llvm8Function5beginEv(i64* %arg1), !insn.addr !323
  store i64 %9, i64* %stack_var_-760, align 8, !insn.addr !324
  %10 = call i64 @_ZN4llvm8Function3endEv(i64* %arg1), !insn.addr !325
  store i64 %10, i64* %stack_var_-752, align 8, !insn.addr !326
  %11 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* nonnull %stack_var_-760, i64* nonnull %stack_var_-752), !insn.addr !327
  %12 = trunc i64 %11 to i8, !insn.addr !328
  %13 = icmp eq i8 %12, 0, !insn.addr !328
  %14 = icmp eq i1 %13, false, !insn.addr !329
  store i32 0, i32* %stack_var_-765.4.lcssa.reg2mem, !insn.addr !329
  store i32 0, i32* %stack_var_-764.4.lcssa.reg2mem, !insn.addr !329
  br i1 %14, label %dec_label_pc_11fd.lr.ph, label %dec_label_pc_16ab, !insn.addr !329

dec_label_pc_11fd.lr.ph:                          ; preds = %dec_label_pc_119e
  %15 = ptrtoint i64* %stack_var_-752 to i64, !insn.addr !330
  store i32 0, i32* %stack_var_-764.413.reg2mem
  store i32 0, i32* %stack_var_-765.412.reg2mem
  br label %dec_label_pc_11fd

dec_label_pc_11fd:                                ; preds = %dec_label_pc_11fd.lr.ph, %dec_label_pc_166c
  %stack_var_-765.412.reload = load i32, i32* %stack_var_-765.412.reg2mem
  %stack_var_-764.413.reload = load i32, i32* %stack_var_-764.413.reg2mem
  %16 = call i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* nonnull %stack_var_-760), !insn.addr !331
  %17 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEEC1Ej(i64* nonnull %stack_var_-584, i32 0), !insn.addr !332
  %18 = call i64 @_ZN4llvm10BasicBlock5beginEv(i64 %16, i64 0, i64 %15), !insn.addr !333
  store i64 %18, i64* %stack_var_-648, align 8, !insn.addr !334
  %19 = inttoptr i64 %16 to i64*, !insn.addr !335
  %20 = call i64 @_ZN4llvm10BasicBlock3endEv(i64* %19), !insn.addr !335
  store i64 %20, i64* %stack_var_-632, align 8, !insn.addr !336
  %21 = call i64 @_ZN4llvmneERKNS_21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEES8_(i64* nonnull %stack_var_-648, i64* nonnull %stack_var_-632), !insn.addr !337
  %22 = trunc i64 %21 to i8, !insn.addr !338
  %23 = icmp eq i8 %22, 0, !insn.addr !338
  %24 = icmp eq i1 %23, false, !insn.addr !339
  store i32 %stack_var_-764.413.reload, i32* %stack_var_-764.310.reg2mem, !insn.addr !339
  store i32 %stack_var_-765.412.reload, i32* %stack_var_-765.39.reg2mem, !insn.addr !339
  store i32 %stack_var_-765.412.reload, i32* %stack_var_-765.3.lcssa.reg2mem, !insn.addr !339
  store i32 %stack_var_-764.413.reload, i32* %stack_var_-764.3.lcssa.reg2mem, !insn.addr !339
  br i1 %24, label %dec_label_pc_1274, label %dec_label_pc_166c, !insn.addr !339

dec_label_pc_1274:                                ; preds = %dec_label_pc_11fd, %dec_label_pc_163c
  %stack_var_-765.39.reload = load i32, i32* %stack_var_-765.39.reg2mem
  %stack_var_-764.310.reload = load i32, i32* %stack_var_-764.310.reg2mem
  %25 = call i64 @_ZNK4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEdeEv(i64* nonnull %stack_var_-648), !insn.addr !340
  %26 = inttoptr i64 %25 to i64*, !insn.addr !341
  %27 = call i64 @_ZN4llvm8dyn_castINS_8LoadInstENS_11InstructionEEEDcPT0_(i64* %26), !insn.addr !341
  %28 = icmp eq i64 %27, 0, !insn.addr !342
  br i1 %28, label %dec_label_pc_14b1, label %dec_label_pc_12ae, !insn.addr !343

dec_label_pc_12ae:                                ; preds = %dec_label_pc_1274
  %29 = inttoptr i64 %27 to i64*, !insn.addr !344
  %30 = call i64 @_ZNK4llvm8LoadInst10isVolatileEv(i64* %29), !insn.addr !344
  %31 = trunc i64 %30 to i8, !insn.addr !345
  %32 = icmp eq i8 %31, 0, !insn.addr !345
  %33 = icmp eq i1 %32, false, !insn.addr !346
  br i1 %33, label %dec_label_pc_12e4, label %dec_label_pc_12e0, !insn.addr !346

dec_label_pc_12e0:                                ; preds = %dec_label_pc_12ae
  %34 = call i64 @_ZNK4llvm11Instruction8isAtomicEv(i64* %29), !insn.addr !347
  %35 = trunc i64 %34 to i8, !insn.addr !348
  %36 = icmp ne i8 %35, 0, !insn.addr !348
  %37 = icmp eq i1 %36, false, !insn.addr !349
  br i1 %37, label %dec_label_pc_12f8, label %dec_label_pc_12e4, !insn.addr !350

dec_label_pc_12e4:                                ; preds = %dec_label_pc_12ae, %dec_label_pc_12e0
  %38 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E5clearEv(i64* nonnull %stack_var_-584), !insn.addr !351
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !352
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !352
  br label %dec_label_pc_163c, !insn.addr !352

dec_label_pc_12f8:                                ; preds = %dec_label_pc_12e0
  %39 = call i64 @_ZN4llvm8LoadInst17getPointerOperandEv(i64* %29), !insn.addr !353
  %40 = inttoptr i64 %39 to i64*, !insn.addr !354
  %41 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L18ClassifyStateAliasEPN4llvm5ValueE(i64* nonnull %stack_var_-552, i64* %40, i64* %40), !insn.addr !354
  %42 = call i64 @_ZNKSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEcvbEv(i64* nonnull %stack_var_-552), !insn.addr !355
  %43 = trunc i64 %42 to i8
  %44 = icmp eq i8 %43, 1, !insn.addr !356
  %45 = icmp eq i1 %44, false, !insn.addr !357
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.1.reg2mem, !insn.addr !357
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.1.reg2mem, !insn.addr !357
  br i1 %45, label %dec_label_pc_149d, label %dec_label_pc_1336, !insn.addr !357

dec_label_pc_1336:                                ; preds = %dec_label_pc_12f8
  %46 = call i64 @_ZNRSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEdeEv(i64* nonnull %stack_var_-552), !insn.addr !358
  %47 = inttoptr i64 %46 to i64*, !insn.addr !359
  %48 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E4findERKS4_(i64* nonnull %stack_var_-584, i64* %47), !insn.addr !359
  store i64 %48, i64* %stack_var_-616, align 8, !insn.addr !360
  %49 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E3endEv(i64* nonnull %stack_var_-584), !insn.addr !361
  store i64 %49, i64* %stack_var_-600, align 8, !insn.addr !362
  %50 = call i64 @_ZN4llvmeqERKNS_16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEESB_(i64* nonnull %stack_var_-616, i64* nonnull %stack_var_-600), !insn.addr !363
  %51 = trunc i64 %50 to i8, !insn.addr !364
  %52 = icmp eq i8 %51, 0, !insn.addr !364
  %53 = icmp eq i1 %52, false, !insn.addr !365
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.1.reg2mem, !insn.addr !365
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.1.reg2mem, !insn.addr !365
  br i1 %53, label %dec_label_pc_149d, label %dec_label_pc_13a6, !insn.addr !365

dec_label_pc_13a6:                                ; preds = %dec_label_pc_1336
  store i64 0, i64* %stack_var_-600, align 8, !insn.addr !366
  %54 = call i64 @_ZN4llvm8ArrayRefINS_17OperandBundleDefTIPNS_5ValueEEEEC1Ev(i64* nonnull %stack_var_-600), !insn.addr !367
  %55 = load i64, i64* %stack_var_-600, align 8, !insn.addr !368
  %56 = inttoptr i64 %55 to i64*, !insn.addr !369
  %57 = call i64 @_ZN4llvm9IRBuilderINS_14ConstantFolderENS_24IRBuilderDefaultInserterEEC1EPNS_11InstructionEPNS_6MDNodeENS_8ArrayRefINS_17OperandBundleDefTIPNS_5ValueEEEEE(i64* nonnull %stack_var_-472, i64* %29, i64* null, i64* %56, i64 0), !insn.addr !369
  %58 = call i64 @_ZNK4llvm5Value7getTypeEv(i64* %29), !insn.addr !370
  %59 = call i64 @_ZNK4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEptEv(i64* nonnull %stack_var_-616), !insn.addr !371
  %60 = add i64 %59, 72, !insn.addr !372
  %61 = inttoptr i64 %60 to i64*, !insn.addr !372
  %62 = load i64, i64* %61, align 8, !insn.addr !372
  %63 = inttoptr i64 %62 to i64*, !insn.addr !373
  %64 = inttoptr i64 %58 to i64*, !insn.addr !373
  %65 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L15CastStoredValueERN4llvm9IRBuilderINS1_14ConstantFolderENS1_24IRBuilderDefaultInserterEEEPNS1_5ValueEPNS1_4TypeE(i64* nonnull %stack_var_-472, i64* %63, i64* %64), !insn.addr !373
  %66 = icmp eq i64 %65, 0, !insn.addr !374
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.0.reg2mem, !insn.addr !375
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.0.reg2mem, !insn.addr !375
  br i1 %66, label %dec_label_pc_1488, label %dec_label_pc_1445, !insn.addr !375

dec_label_pc_1445:                                ; preds = %dec_label_pc_13a6
  %67 = inttoptr i64 %65 to i64*, !insn.addr !376
  %68 = call i64 @_ZN4llvm5Value18replaceAllUsesWithEPS0_(i64* %29, i64* %67), !insn.addr !376
  %69 = call i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE9push_backES2_(i64* nonnull %stack_var_-312, i64* %29), !insn.addr !377
  %70 = add i32 %stack_var_-764.310.reload, 1, !insn.addr !378
  store i32 1, i32* %stack_var_-765.0.reg2mem, !insn.addr !379
  store i32 %70, i32* %stack_var_-764.0.reg2mem, !insn.addr !379
  br label %dec_label_pc_1488, !insn.addr !379

dec_label_pc_1488:                                ; preds = %dec_label_pc_13a6, %dec_label_pc_1445
  %stack_var_-764.0.reload = load i32, i32* %stack_var_-764.0.reg2mem
  %stack_var_-765.0.reload = load i32, i32* %stack_var_-765.0.reg2mem
  %71 = call i64 @_ZN4llvm9IRBuilderINS_14ConstantFolderENS_24IRBuilderDefaultInserterEED1Ev(i64* nonnull %stack_var_-472), !insn.addr !380
  store i32 %stack_var_-765.0.reload, i32* %stack_var_-765.1.reg2mem, !insn.addr !381
  store i32 %stack_var_-764.0.reload, i32* %stack_var_-764.1.reg2mem, !insn.addr !381
  br label %dec_label_pc_149d, !insn.addr !381

dec_label_pc_149d:                                ; preds = %dec_label_pc_1336, %dec_label_pc_12f8, %dec_label_pc_1488
  %stack_var_-764.1.reload = load i32, i32* %stack_var_-764.1.reg2mem
  %stack_var_-765.1.reload = load i32, i32* %stack_var_-765.1.reg2mem
  %72 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEED1Ev(i64* nonnull %stack_var_-552), !insn.addr !382
  store i32 %stack_var_-765.1.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !383
  store i32 %stack_var_-764.1.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !383
  br label %dec_label_pc_163c, !insn.addr !383

dec_label_pc_14b1:                                ; preds = %dec_label_pc_1274
  %73 = call i64 @_ZN4llvm8dyn_castINS_9StoreInstENS_11InstructionEEEDcPT0_(i64* %26), !insn.addr !384
  %74 = icmp eq i64 %73, 0, !insn.addr !385
  br i1 %74, label %dec_label_pc_15d3, label %dec_label_pc_14d5, !insn.addr !386

dec_label_pc_14d5:                                ; preds = %dec_label_pc_14b1
  %75 = inttoptr i64 %73 to i64*, !insn.addr !387
  %76 = call i64 @_ZNK4llvm9StoreInst10isVolatileEv(i64* %75), !insn.addr !387
  %77 = trunc i64 %76 to i8, !insn.addr !388
  %78 = icmp eq i8 %77, 0, !insn.addr !388
  %79 = icmp eq i1 %78, false, !insn.addr !389
  br i1 %79, label %dec_label_pc_150b, label %dec_label_pc_1507, !insn.addr !389

dec_label_pc_1507:                                ; preds = %dec_label_pc_14d5
  %80 = call i64 @_ZNK4llvm11Instruction8isAtomicEv(i64* %75), !insn.addr !390
  %81 = trunc i64 %80 to i8, !insn.addr !391
  %82 = icmp ne i8 %81, 0, !insn.addr !391
  %83 = icmp eq i1 %82, false, !insn.addr !392
  br i1 %83, label %dec_label_pc_151f, label %dec_label_pc_150b, !insn.addr !393

dec_label_pc_150b:                                ; preds = %dec_label_pc_14d5, %dec_label_pc_1507
  %84 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E5clearEv(i64* nonnull %stack_var_-584), !insn.addr !394
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !395
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !395
  br label %dec_label_pc_163c, !insn.addr !395

dec_label_pc_151f:                                ; preds = %dec_label_pc_1507
  %85 = call i64 @_ZN4llvm9StoreInst17getPointerOperandEv(i64* %75), !insn.addr !396
  %86 = inttoptr i64 %85 to i64*, !insn.addr !397
  %87 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L18ClassifyStateAliasEPN4llvm5ValueE(i64* nonnull %stack_var_-472, i64* %86, i64* %86), !insn.addr !397
  %88 = call i64 @_ZNKSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEcvbEv(i64* nonnull %stack_var_-472), !insn.addr !398
  %89 = trunc i64 %88 to i8
  %90 = icmp eq i8 %89, 1, !insn.addr !399
  br i1 %90, label %dec_label_pc_156a, label %dec_label_pc_1559, !insn.addr !400

dec_label_pc_1559:                                ; preds = %dec_label_pc_151f
  %91 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E5clearEv(i64* nonnull %stack_var_-584), !insn.addr !401
  br label %dec_label_pc_15c2, !insn.addr !402

dec_label_pc_156a:                                ; preds = %dec_label_pc_151f
  %92 = call i64 @_ZNRSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEdeEv(i64* nonnull %stack_var_-472), !insn.addr !403
  %93 = inttoptr i64 %92 to i64*, !insn.addr !404
  %94 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_EixERKS4_(i64* nonnull %stack_var_-584, i64* %93), !insn.addr !404
  %95 = call i64 @_ZN4llvm9StoreInst15getValueOperandEv(i64* %75), !insn.addr !405
  %96 = call i64 @_ZN4llvm9StoreInst15getValueOperandEv(i64* %75), !insn.addr !406
  %97 = inttoptr i64 %96 to i64*, !insn.addr !407
  %98 = call i64 @_ZNK4llvm5Value7getTypeEv(i64* %97), !insn.addr !407
  %99 = inttoptr i64 %94 to i64*, !insn.addr !408
  store i64 %95, i64* %99, align 8, !insn.addr !408
  %100 = add i64 %94, 8, !insn.addr !409
  %101 = inttoptr i64 %100 to i64*, !insn.addr !409
  store i64 %98, i64* %101, align 8, !insn.addr !409
  br label %dec_label_pc_15c2, !insn.addr !410

dec_label_pc_15c2:                                ; preds = %dec_label_pc_156a, %dec_label_pc_1559
  %102 = call i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEED1Ev(i64* nonnull %stack_var_-472), !insn.addr !411
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !412
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !412
  br label %dec_label_pc_163c, !insn.addr !412

dec_label_pc_15d3:                                ; preds = %dec_label_pc_14b1
  %103 = call i64 @_ZN4llvm8dyn_castINS_8CallBaseENS_11InstructionEEEDcPT0_(i64* %26), !insn.addr !413
  %104 = icmp eq i64 %103, 0, !insn.addr !414
  br i1 %104, label %dec_label_pc_1617, label %dec_label_pc_15f3, !insn.addr !415

dec_label_pc_15f3:                                ; preds = %dec_label_pc_15d3
  %105 = inttoptr i64 %103 to i64*, !insn.addr !416
  %106 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L13IsBarrierCallERN4llvm8CallBaseE(i64* %105), !insn.addr !416
  %107 = trunc i64 %106 to i8, !insn.addr !417
  %108 = icmp eq i8 %107, 0, !insn.addr !417
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !418
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !418
  br i1 %108, label %dec_label_pc_163c, label %dec_label_pc_1606, !insn.addr !418

dec_label_pc_1606:                                ; preds = %dec_label_pc_15f3
  %109 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E5clearEv(i64* nonnull %stack_var_-584), !insn.addr !419
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !420
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !420
  br label %dec_label_pc_163c, !insn.addr !420

dec_label_pc_1617:                                ; preds = %dec_label_pc_15d3
  %110 = call i64 @_ZNK4llvm11Instruction16mayWriteToMemoryEv(i64* %26), !insn.addr !421
  %111 = trunc i64 %110 to i8, !insn.addr !422
  %112 = icmp eq i8 %111, 0, !insn.addr !422
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !423
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !423
  br i1 %112, label %dec_label_pc_163c, label %dec_label_pc_162a, !insn.addr !423

dec_label_pc_162a:                                ; preds = %dec_label_pc_1617
  %113 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E5clearEv(i64* nonnull %stack_var_-584), !insn.addr !424
  store i32 %stack_var_-765.39.reload, i32* %stack_var_-765.2.reg2mem, !insn.addr !425
  store i32 %stack_var_-764.310.reload, i32* %stack_var_-764.2.reg2mem, !insn.addr !425
  br label %dec_label_pc_163c, !insn.addr !425

dec_label_pc_163c:                                ; preds = %dec_label_pc_15f3, %dec_label_pc_1606, %dec_label_pc_162a, %dec_label_pc_1617, %dec_label_pc_15c2, %dec_label_pc_150b, %dec_label_pc_149d, %dec_label_pc_12e4
  %stack_var_-764.2.reload = load i32, i32* %stack_var_-764.2.reg2mem
  %stack_var_-765.2.reload = load i32, i32* %stack_var_-765.2.reg2mem
  %114 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEppEv(i64* nonnull %stack_var_-648), !insn.addr !426
  %115 = call i64 @_ZN4llvmneERKNS_21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEES8_(i64* nonnull %stack_var_-648, i64* nonnull %stack_var_-632), !insn.addr !337
  %116 = trunc i64 %115 to i8, !insn.addr !338
  %117 = icmp eq i8 %116, 0, !insn.addr !338
  %118 = icmp eq i1 %117, false, !insn.addr !339
  store i32 %stack_var_-764.2.reload, i32* %stack_var_-764.310.reg2mem, !insn.addr !339
  store i32 %stack_var_-765.2.reload, i32* %stack_var_-765.39.reg2mem, !insn.addr !339
  store i32 %stack_var_-765.2.reload, i32* %stack_var_-765.3.lcssa.reg2mem, !insn.addr !339
  store i32 %stack_var_-764.2.reload, i32* %stack_var_-764.3.lcssa.reg2mem, !insn.addr !339
  br i1 %118, label %dec_label_pc_1274, label %dec_label_pc_166c, !insn.addr !339

dec_label_pc_166c:                                ; preds = %dec_label_pc_163c, %dec_label_pc_11fd
  %stack_var_-764.3.lcssa.reload = load i32, i32* %stack_var_-764.3.lcssa.reg2mem
  %stack_var_-765.3.lcssa.reload = load i32, i32* %stack_var_-765.3.lcssa.reg2mem
  %119 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEED1Ev(i64* nonnull %stack_var_-584), !insn.addr !427
  %120 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* nonnull %stack_var_-760), !insn.addr !428
  %121 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* nonnull %stack_var_-760, i64* nonnull %stack_var_-752), !insn.addr !327
  %122 = trunc i64 %121 to i8, !insn.addr !328
  %123 = icmp eq i8 %122, 0, !insn.addr !328
  %124 = icmp eq i1 %123, false, !insn.addr !329
  store i32 %stack_var_-764.3.lcssa.reload, i32* %stack_var_-764.413.reg2mem, !insn.addr !329
  store i32 %stack_var_-765.3.lcssa.reload, i32* %stack_var_-765.412.reg2mem, !insn.addr !329
  store i32 %stack_var_-765.3.lcssa.reload, i32* %stack_var_-765.4.lcssa.reg2mem, !insn.addr !329
  store i32 %stack_var_-764.3.lcssa.reload, i32* %stack_var_-764.4.lcssa.reg2mem, !insn.addr !329
  br i1 %124, label %dec_label_pc_11fd, label %dec_label_pc_16ab, !insn.addr !329

dec_label_pc_16ab:                                ; preds = %dec_label_pc_166c, %dec_label_pc_119e
  %stack_var_-764.4.lcssa.reload = load i32, i32* %stack_var_-764.4.lcssa.reg2mem
  %stack_var_-765.4.lcssa.reload = load i32, i32* %stack_var_-765.4.lcssa.reg2mem
  %125 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE5beginEv(i64* nonnull %stack_var_-312), !insn.addr !429
  %126 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE3endEv(i64* nonnull %stack_var_-312), !insn.addr !430
  %127 = icmp eq i64 %125, %126, !insn.addr !431
  %128 = icmp eq i1 %127, false, !insn.addr !432
  store i64 %125, i64* %stack_var_-744.08.reg2mem, !insn.addr !432
  br i1 %128, label %dec_label_pc_16e7, label %dec_label_pc_171f, !insn.addr !432

dec_label_pc_16e7:                                ; preds = %dec_label_pc_16ab, %dec_label_pc_16e7
  %stack_var_-744.08.reload = load i64, i64* %stack_var_-744.08.reg2mem
  %129 = inttoptr i64 %stack_var_-744.08.reload to i64*, !insn.addr !433
  %130 = load i64, i64* %129, align 8, !insn.addr !433
  %131 = inttoptr i64 %130 to i64*, !insn.addr !434
  %132 = call i64 @_ZN4llvm11Instruction15eraseFromParentEv(i64* %131), !insn.addr !434
  %133 = add i64 %stack_var_-744.08.reload, 8, !insn.addr !435
  %134 = icmp eq i64 %133, %126, !insn.addr !431
  %135 = icmp eq i1 %134, false, !insn.addr !432
  store i64 %133, i64* %stack_var_-744.08.reg2mem, !insn.addr !432
  br i1 %135, label %dec_label_pc_16e7, label %dec_label_pc_171f, !insn.addr !432

dec_label_pc_171f:                                ; preds = %dec_label_pc_16e7, %dec_label_pc_16ab
  %136 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L12TraceEnabledEv(), !insn.addr !436
  %137 = trunc i64 %136 to i8, !insn.addr !437
  %138 = icmp eq i8 %137, 0, !insn.addr !437
  %139 = trunc i32 %stack_var_-765.4.lcssa.reload to i8, !insn.addr !438
  %140 = icmp eq i8 %139, 0, !insn.addr !438
  %or.cond = or i1 %140, %138
  br i1 %or.cond, label %dec_label_pc_17ce, label %dec_label_pc_1745, !insn.addr !439

dec_label_pc_1745:                                ; preds = %dec_label_pc_171f
  %141 = call i64 @_ZN4llvm4errsEv(), !insn.addr !440
  %142 = inttoptr i64 %141 to i64*, !insn.addr !441
  %143 = call i64 @_ZN4llvm11raw_ostreamlsEPKc(i64* %142, i8* getelementptr inbounds ([38 x i8], [38 x i8]* @global_var_5ab4, i64 0, i64 0)), !insn.addr !441
  %144 = call i64 @_ZNK4llvm5Value7getNameEv(i64* %arg1), !insn.addr !442
  %145 = inttoptr i64 %143 to i64*, !insn.addr !443
  %146 = inttoptr i64 %144 to i64*, !insn.addr !443
  %147 = call i64 @_ZN4llvm11raw_ostreamlsENS_9StringRefE(i64* %145, i64* %146, i64 %141), !insn.addr !443
  %148 = inttoptr i64 %147 to i64*, !insn.addr !444
  %149 = call i64 @_ZN4llvm11raw_ostreamlsEPKc(i64* %148, i8* getelementptr inbounds ([8 x i8], [8 x i8]* @global_var_5ada, i64 0, i64 0)), !insn.addr !444
  %150 = inttoptr i64 %149 to i64*, !insn.addr !445
  %151 = call i64 @_ZN4llvm11raw_ostreamlsEj(i64* %150, i32 %stack_var_-764.4.lcssa.reload), !insn.addr !445
  %152 = inttoptr i64 %151 to i64*, !insn.addr !446
  %153 = call i64 @_ZN4llvm11raw_ostreamlsEPKc(i64* %152, i8* getelementptr inbounds ([2 x i8], [2 x i8]* @global_var_5ae2, i64 0, i64 0)), !insn.addr !446
  br label %dec_label_pc_17ce, !insn.addr !446

dec_label_pc_17ce:                                ; preds = %dec_label_pc_171f, %dec_label_pc_1745
  %154 = urem i32 %stack_var_-765.4.lcssa.reload, 256
  %155 = zext i32 %154 to i64, !insn.addr !447
  %156 = call i64 @_ZN4llvm11SmallVectorIPNS_11InstructionELj32EED1Ev(i64* nonnull %stack_var_-312), !insn.addr !448
  store i64 %155, i64* %rbx.0.reg2mem, !insn.addr !448
  br label %dec_label_pc_17e4, !insn.addr !448

dec_label_pc_17e4:                                ; preds = %dec_label_pc_1136, %dec_label_pc_1171, %dec_label_pc_17ce
  %rbx.0.reload = load i64, i64* %rbx.0.reg2mem
  %157 = call i64 @__readfsqword(i64 40), !insn.addr !449
  %158 = icmp eq i64 %0, %157, !insn.addr !449
  store i64 %rbx.0.reload, i64* %rax.0.reg2mem, !insn.addr !450
  br i1 %158, label %dec_label_pc_17fa, label %dec_label_pc_17f5, !insn.addr !450

dec_label_pc_17f5:                                ; preds = %dec_label_pc_17e4
  %159 = call i64 @__stack_chk_fail(), !insn.addr !451
  store i64 %159, i64* %rax.0.reg2mem, !insn.addr !451
  br label %dec_label_pc_17fa, !insn.addr !451

dec_label_pc_17fa:                                ; preds = %dec_label_pc_17f5, %dec_label_pc_17e4
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !452

; uselistorder directives
  uselistorder i64 %126, { 1, 0 }
  uselistorder i32 %stack_var_-765.4.lcssa.reload, { 1, 0 }
  uselistorder i64 %94, { 1, 0 }
  uselistorder i64* %75, { 2, 1, 3, 0, 4 }
  uselistorder i64* %29, { 2, 1, 4, 3, 5, 0, 6 }
  uselistorder i32 %stack_var_-764.310.reload, { 5, 6, 3, 4, 2, 1, 10, 9, 7, 8, 0 }
  uselistorder i32 %stack_var_-765.39.reload, { 5, 6, 3, 4, 2, 1, 9, 7, 8, 0 }
  uselistorder i64* %stack_var_-760, { 1, 2, 3, 0, 4 }
  uselistorder i64* %stack_var_-752, { 1, 2, 0, 3 }
  uselistorder i64* %stack_var_-648, { 1, 2, 3, 0, 4 }
  uselistorder i64* %stack_var_-632, { 1, 0, 2 }
  uselistorder i64* %stack_var_-600, { 2, 0, 3, 1, 4 }
  uselistorder i32* %stack_var_-764.413.reg2mem, { 1, 0, 2 }
  uselistorder i32* %stack_var_-765.412.reg2mem, { 1, 0, 2 }
  uselistorder i32* %stack_var_-764.310.reg2mem, { 2, 0, 1 }
  uselistorder i32* %stack_var_-765.39.reg2mem, { 2, 0, 1 }
  uselistorder i32* %stack_var_-765.2.reg2mem, { 0, 7, 8, 5, 6, 4, 3, 2, 1 }
  uselistorder i32* %stack_var_-764.2.reg2mem, { 0, 7, 8, 5, 6, 4, 3, 2, 1 }
  uselistorder i64* %stack_var_-744.08.reg2mem, { 2, 0, 1 }
  uselistorder i64* %rbx.0.reg2mem, { 0, 3, 2, 1 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Value7getNameEv, { 4, 3, 2, 1, 0 }
  uselistorder i64 (i64*, i8*)* @_ZN4llvm11raw_ostreamlsEPKc, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm9StoreInst15getValueOperandEv, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEED1Ev, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNRSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEdeEv, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNKSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEcvbEv, { 1, 0 }
  uselistorder i64 (i64*, i64*, i64*)* @_ZN22brighten_state_forward12_GLOBAL__N_1L18ClassifyStateAliasEPN4llvm5ValueE, { 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E5clearEv, { 4, 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm11Instruction8isAtomicEv, { 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEES7_, { 1, 0 }
  uselistorder label %dec_label_pc_17e4, { 2, 1, 0 }
  uselistorder label %dec_label_pc_17ce, { 1, 0 }
  uselistorder label %dec_label_pc_16e7, { 1, 0 }
  uselistorder label %dec_label_pc_163c, { 2, 3, 1, 0, 4, 5, 6, 7 }
  uselistorder label %dec_label_pc_150b, { 1, 0 }
  uselistorder label %dec_label_pc_149d, { 2, 0, 1 }
  uselistorder label %dec_label_pc_1488, { 1, 0 }
  uselistorder label %dec_label_pc_12e4, { 1, 0 }
  uselistorder label %dec_label_pc_1274, { 1, 0 }
  uselistorder label %dec_label_pc_11fd, { 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPass3runERN4llvm6ModuleERNS2_15AnalysisManagerIS3_JEEE(i64* %this, i64* %result, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_1806:
  %stack_var_-49.01.reg2mem = alloca i8, !insn.addr !453
  %stack_var_-40 = alloca i64, align 8
  %stack_var_-48 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !454
  %1 = call i64 @_ZN4llvm6Module5beginEv(i64* %arg3), !insn.addr !455
  store i64 %1, i64* %stack_var_-48, align 8, !insn.addr !456
  %2 = call i64 @_ZN4llvm6Module3endEv(i64* %arg3), !insn.addr !457
  store i64 %2, i64* %stack_var_-40, align 8, !insn.addr !458
  %3 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-40), !insn.addr !459
  %4 = trunc i64 %3 to i8, !insn.addr !460
  %5 = icmp eq i8 %4, 0, !insn.addr !460
  %6 = icmp eq i1 %5, false, !insn.addr !461
  store i8 0, i8* %stack_var_-49.01.reg2mem, !insn.addr !461
  br i1 %6, label %dec_label_pc_185f, label %dec_label_pc_18c0, !insn.addr !461

dec_label_pc_185f:                                ; preds = %dec_label_pc_1806, %dec_label_pc_185f
  %stack_var_-49.01.reload = load i8, i8* %stack_var_-49.01.reg2mem
  %7 = call i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* nonnull %stack_var_-48), !insn.addr !462
  %8 = inttoptr i64 %7 to i64*, !insn.addr !463
  %9 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_1L15ForwardFunctionERN4llvm8FunctionE(i64* %8), !insn.addr !463
  %10 = trunc i64 %9 to i8, !insn.addr !464
  %11 = or i8 %stack_var_-49.01.reload, %10, !insn.addr !464
  %12 = icmp eq i8 %11, 0, !insn.addr !465
  %13 = icmp eq i1 %12, false, !insn.addr !466
  %14 = zext i1 %13 to i8, !insn.addr !467
  %15 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* nonnull %stack_var_-48), !insn.addr !468
  %16 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-40), !insn.addr !459
  %17 = trunc i64 %16 to i8, !insn.addr !460
  %18 = icmp eq i8 %17, 0, !insn.addr !460
  %19 = icmp eq i1 %18, false, !insn.addr !461
  store i8 %14, i8* %stack_var_-49.01.reg2mem, !insn.addr !461
  br i1 %19, label %dec_label_pc_185f, label %dec_label_pc_18ac, !insn.addr !461

dec_label_pc_18ac:                                ; preds = %dec_label_pc_185f
  %phitmp = icmp eq i1 %13, false
  br i1 %phitmp, label %dec_label_pc_18c0, label %dec_label_pc_18b2, !insn.addr !469

dec_label_pc_18b2:                                ; preds = %dec_label_pc_18ac
  %20 = call i64 @_ZN4llvm17PreservedAnalyses4noneEv(i64* %this), !insn.addr !470
  br label %dec_label_pc_18cc, !insn.addr !471

dec_label_pc_18c0:                                ; preds = %dec_label_pc_1806, %dec_label_pc_18ac
  %21 = call i64 @_ZN4llvm17PreservedAnalyses3allEv(i64* %this), !insn.addr !472
  br label %dec_label_pc_18cc, !insn.addr !472

dec_label_pc_18cc:                                ; preds = %dec_label_pc_18c0, %dec_label_pc_18b2
  %22 = call i64 @__readfsqword(i64 40), !insn.addr !473
  %23 = icmp eq i64 %0, %22, !insn.addr !473
  br i1 %23, label %dec_label_pc_18e0, label %dec_label_pc_18db, !insn.addr !474

dec_label_pc_18db:                                ; preds = %dec_label_pc_18cc
  %24 = call i64 @__stack_chk_fail(), !insn.addr !475
  br label %dec_label_pc_18e0, !insn.addr !475

dec_label_pc_18e0:                                ; preds = %dec_label_pc_18db, %dec_label_pc_18cc
  %25 = ptrtoint i64* %this to i64
  ret i64 %25, !insn.addr !476

; uselistorder directives
  uselistorder i64* %stack_var_-48, { 1, 2, 3, 0, 4 }
  uselistorder i64* %stack_var_-40, { 1, 0, 2 }
  uselistorder i8* %stack_var_-49.01.reg2mem, { 2, 0, 1 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEES7_, { 1, 0 }
  uselistorder i64* %this, { 2, 1, 0 }
  uselistorder label %dec_label_pc_18c0, { 1, 0 }
  uselistorder label %dec_label_pc_185f, { 1, 0 }
}

define i64 @_ZZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_ENKUlNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS5_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEE_clES3_S9_SC_(i64 %arg1, i64 %arg2, i64 %arg3, i64 %arg4, i64 %arg5, i64 %arg6) local_unnamed_addr {
dec_label_pc_18e6:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !477
  %storemerge.reg2mem = alloca i64, !insn.addr !477
  %1 = load i64, i64* %0
  %stack_var_-40 = alloca i64, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !478
  %3 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-40, i8* getelementptr inbounds ([28 x i8], [28 x i8]* @global_var_5ae5, i64 0, i64 0)), !insn.addr !479
  %4 = load i64, i64* %stack_var_-40, align 8, !insn.addr !480
  %5 = inttoptr i64 %arg2 to i64*, !insn.addr !481
  %6 = inttoptr i64 %arg3 to i64*, !insn.addr !481
  %7 = call i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %5, i64* %6, i64 %4, i64 %1), !insn.addr !481
  %8 = trunc i64 %7 to i8, !insn.addr !482
  %9 = icmp eq i8 %8, 0, !insn.addr !482
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !483
  br i1 %9, label %dec_label_pc_1972, label %dec_label_pc_1953, !insn.addr !483

dec_label_pc_1953:                                ; preds = %dec_label_pc_18e6
  %10 = inttoptr i64 %arg4 to i64*, !insn.addr !484
  %11 = call i64 @_ZN4llvm11PassManagerINS_6ModuleENS_15AnalysisManagerIS1_JEEEJEE7addPassIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEEENSt9enable_ifIXnt9is_same_vIT_S4_EEvE4typeEOSA_(i64* %10, i64* nonnull %stack_var_-40), !insn.addr !484
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !485
  br label %dec_label_pc_1972, !insn.addr !485

dec_label_pc_1972:                                ; preds = %dec_label_pc_18e6, %dec_label_pc_1953
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %12 = call i64 @__readfsqword(i64 40), !insn.addr !486
  %13 = icmp eq i64 %2, %12, !insn.addr !486
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !487
  br i1 %13, label %dec_label_pc_1986, label %dec_label_pc_1981, !insn.addr !487

dec_label_pc_1981:                                ; preds = %dec_label_pc_1972
  %14 = call i64 @__stack_chk_fail(), !insn.addr !488
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !488
  br label %dec_label_pc_1986, !insn.addr !488

dec_label_pc_1986:                                ; preds = %dec_label_pc_1981, %dec_label_pc_1972
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !489

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 0, 2, 1 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*, i64*, i64, i64)* @_ZN4llvmeqENS_9StringRefES0_, { 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
  uselistorder label %dec_label_pc_1972, { 1, 0 }
}

define i64 @_ZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_1988:
  %rax.0.reg2mem = alloca i64, !insn.addr !490
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-57 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !491
  %1 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1IZZ21llvmGetPassPluginInfoENKUlRS9_E_clESF_EUlS1_S7_SB_E_vEEOT_(i64* nonnull %stack_var_-56, i64* nonnull %stack_var_-57), !insn.addr !492
  %2 = call i64 @_ZN4llvm11PassBuilder31registerPipelineParsingCallbackERKSt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEEE(i64* %arg2, i64* nonnull %stack_var_-56), !insn.addr !493
  %3 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev(i64* nonnull %stack_var_-56), !insn.addr !494
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !495
  %5 = icmp eq i64 %0, %4, !insn.addr !495
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !496
  br i1 %5, label %dec_label_pc_19ee, label %dec_label_pc_19e9, !insn.addr !496

dec_label_pc_19e9:                                ; preds = %dec_label_pc_1988
  %6 = call i64 @__stack_chk_fail(), !insn.addr !497
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !497
  br label %dec_label_pc_19ee, !insn.addr !497

dec_label_pc_19ee:                                ; preds = %dec_label_pc_19e9, %dec_label_pc_1988
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !498
}

define i64 @_ZZ21llvmGetPassPluginInfoENUlRN4llvm11PassBuilderEE_4_FUNES1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_19f0:
  %0 = call i64 @_ZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_(i64* null, i64* %arg1), !insn.addr !499
  ret i64 %0, !insn.addr !500
}

define i64 @llvmGetPassPluginInfo(i64 %arg1) local_unnamed_addr {
dec_label_pc_1a13:
  %0 = inttoptr i64 %arg1 to i32*, !insn.addr !501
  store i32 1, i32* %0, align 4, !insn.addr !501
  %1 = add i64 %arg1, 8, !insn.addr !502
  %2 = inttoptr i64 %1 to i64*, !insn.addr !502
  store i64 ptrtoint ([25 x i8]* @global_var_5b01 to i64), i64* %2, align 8, !insn.addr !502
  %3 = add i64 %arg1, 16, !insn.addr !503
  %4 = inttoptr i64 %3 to i64*, !insn.addr !503
  store i64 ptrtoint ([6 x i8]* @global_var_5b1a to i64), i64* %4, align 8, !insn.addr !503
  %5 = add i64 %arg1, 24, !insn.addr !504
  %6 = inttoptr i64 %5 to i64*, !insn.addr !504
  store i64 6640, i64* %6, align 8, !insn.addr !504
  ret i64 %arg1, !insn.addr !505
}

define i64 @_ZN4llvm17make_filter_rangeIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEZNS_L13filterDbgVarsES8_EUlRS5_E_EENS1_INS_20filter_iterator_implIDTcl9adl_begincl7declvalIRT_EEEET0_NS_6detail15fwd_or_bidi_tagISF_E4typeEEEEEOSD_SG_(i64** %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_1a5c:
  %0 = ptrtoint i64** %arg1 to i64
  %stack_var_-72 = alloca i64, align 8
  %stack_var_-40 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !506
  %2 = inttoptr i64 %arg2 to i64**, !insn.addr !507
  %3 = call i64 @_ZN4llvm9adl_beginIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl10begin_implcl7forwardIT_Efp_EEEOSA_(i64** %2), !insn.addr !507
  %4 = call i64 @_ZN4llvm7adl_endIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl8end_implcl7forwardIT_Efp_EEEOSA_(i64** %2), !insn.addr !508
  %5 = ptrtoint i64* %stack_var_-40 to i64, !insn.addr !509
  %6 = call i64 @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_(i64 %5, i64 %4, i64 %4), !insn.addr !510
  %7 = ptrtoint i64* %stack_var_-72 to i64, !insn.addr !511
  %8 = call i64 @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_(i64 %7, i64 %3, i64 %4), !insn.addr !512
  %9 = call i64 @_ZN4llvm10make_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEENS8_IT_EESE_SE_(i64 %0, i64 ptrtoint (i32* @0 to i64)), !insn.addr !513
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !514
  %11 = icmp eq i64 %1, %10, !insn.addr !514
  br i1 %11, label %dec_label_pc_1b2e, label %dec_label_pc_1b29, !insn.addr !515

dec_label_pc_1b29:                                ; preds = %dec_label_pc_1a5c
  %12 = call i64 @__stack_chk_fail(), !insn.addr !516
  br label %dec_label_pc_1b2e, !insn.addr !516

dec_label_pc_1b2e:                                ; preds = %dec_label_pc_1b29, %dec_label_pc_1a5c
  ret i64 %0, !insn.addr !517

; uselistorder directives
  uselistorder i64 %4, { 0, 2, 1 }
  uselistorder i64 (i64, i64, i64)* @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_, { 1, 0 }
}

define i64 @_ZN4llvm9adl_beginIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEEDTcl10begin_implcl7forwardIT_Efp_EEEOSG_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_1b34:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !518
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !519
  %3 = call i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %2), !insn.addr !520
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !521
  %5 = icmp eq i64 %0, %4, !insn.addr !521
  br i1 %5, label %dec_label_pc_1b86, label %dec_label_pc_1b81, !insn.addr !522

dec_label_pc_1b81:                                ; preds = %dec_label_pc_1b34
  %6 = call i64 @__stack_chk_fail(), !insn.addr !523
  br label %dec_label_pc_1b86, !insn.addr !523

dec_label_pc_1b86:                                ; preds = %dec_label_pc_1b81, %dec_label_pc_1b34
  %7 = ptrtoint i64* %result to i64
  ret i64 %7, !insn.addr !524

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64 @_ZN4llvm12map_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_EENS_15mapped_iteratorIT_T0_DTclcl7declvalISH_EEdecl7declvalISG_EEEEEESG_SH_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_1b8c:
  %stack_var_8 = alloca i64, align 8
  %stack_var_-17 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_-17 to i64**, !insn.addr !525
  %1 = call i64* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_(i64** nonnull %0), !insn.addr !525
  %2 = bitcast i64* %stack_var_8 to i64**, !insn.addr !526
  %3 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %2), !insn.addr !526
  %4 = call i64 @_ZN4llvm15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEC1ESD_SE_(i64 %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !527
  ret i64 %arg1, !insn.addr !528
}

define i64 @_ZN4llvm7adl_endIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEEDTcl8end_implcl7forwardIT_Efp_EEEOSG_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_1be4:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !529
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !530
  %3 = call i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %2), !insn.addr !531
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !532
  %5 = icmp eq i64 %0, %4, !insn.addr !532
  br i1 %5, label %dec_label_pc_1c36, label %dec_label_pc_1c31, !insn.addr !533

dec_label_pc_1c31:                                ; preds = %dec_label_pc_1be4
  %6 = call i64 @__stack_chk_fail(), !insn.addr !534
  br label %dec_label_pc_1c36, !insn.addr !534

dec_label_pc_1c36:                                ; preds = %dec_label_pc_1c31, %dec_label_pc_1be4
  %7 = ptrtoint i64* %result to i64
  ret i64 %7, !insn.addr !535

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64 @_ZN4llvm10make_rangeINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS_17DbgVariableRecordEEEEEENS9_IT_EESK_SK_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_1c3c:
  %stack_var_8 = alloca i64, align 8
  %stack_var_40 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_40 to i64**, !insn.addr !536
  %1 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %0), !insn.addr !536
  %2 = bitcast i64* %stack_var_8 to i64**, !insn.addr !537
  %3 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %2), !insn.addr !537
  %4 = call i64 @_ZN4llvm14iterator_rangeINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEEEC1ESI_SI_(i64 %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !538
  ret i64 %arg1, !insn.addr !539
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC2Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1cca:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_StorageIS2_Lb0EEC1Ev(i64* %result), !insn.addr !540
  %2 = add i64 %0, 72, !insn.addr !541
  %3 = inttoptr i64 %2 to i8*, !insn.addr !541
  store i8 0, i8* %3, align 1, !insn.addr !541
  ret i64 %0, !insn.addr !542

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEED2Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1cee:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_StorageIS2_Lb0EED1Ev(i64* %result), !insn.addr !543
  ret i64 %0, !insn.addr !544
}

define i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb1ELb0ELb0EEC2Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1d0a:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC2Ev(i64* %result), !insn.addr !545
  ret i64 %0, !insn.addr !546
}

define i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb1ELb0ELb0EED2Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1d26:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEED2Ev(i64* %result), !insn.addr !547
  ret i64 %0, !insn.addr !548
}

define i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0ELb0EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1d42:
  %0 = call i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb1ELb0ELb0EEC2Ev(i64* %result), !insn.addr !549
  ret i64 %0, !insn.addr !550
}

define i64 @_ZNSt14_Optional_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0EEC2Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1d5e:
  %0 = call i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0ELb0EEC1Ev(i64* %result), !insn.addr !551
  ret i64 %0, !insn.addr !552
}

define i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1ESt9nullopt_t(i64 %arg1) local_unnamed_addr {
dec_label_pc_1d7a:
  %0 = inttoptr i64 %arg1 to i64*, !insn.addr !553
  %1 = call i64 @_ZNSt14_Optional_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0EEC2Ev(i64* %0), !insn.addr !553
  ret i64 %1, !insn.addr !554
}

define i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0ELb0EED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1d96:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_M_resetEv(i64* %result), !insn.addr !555
  %1 = call i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb1ELb0ELb0EED2Ev(i64* %result), !insn.addr !556
  ret i64 %1, !insn.addr !557
}

define i64 @_ZNSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC1IS2_Lb1EEEOT_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_1dbe:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg2), !insn.addr !558
  %2 = ptrtoint i64* %1 to i64, !insn.addr !558
  %3 = call i64 @_ZNSt14_Optional_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0EEC2IJS2_ELb0EEESt10in_place_tDpOT_(i64 %0, i64 %2), !insn.addr !559
  ret i64 %3, !insn.addr !560
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEEC1Ej(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_1df2:
  %0 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE4initEj(i64* %result, i32 %arg2), !insn.addr !561
  ret i64 %0, !insn.addr !562
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_1e16:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10destroyAllEv(i64* %result), !insn.addr !563
  %2 = add i64 %0, 16, !insn.addr !564
  %3 = inttoptr i64 %2 to i32*, !insn.addr !564
  %4 = load i32, i32* %3, align 4, !insn.addr !564
  %5 = zext i32 %4 to i64, !insn.addr !565
  %6 = mul nuw nsw i64 %5, 88, !insn.addr !566
  %7 = call i64 @_ZN4llvm17deallocate_bufferEPvmm(i64* %result, i64 %6, i64 8), !insn.addr !567
  ret i64 %7, !insn.addr !568
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyaSERKS1_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_1e68:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_(i64* %result, i64* %arg2), !insn.addr !569
  %3 = add i64 %0, 32, !insn.addr !570
  %4 = add i64 %1, 32, !insn.addr !571
  %5 = inttoptr i64 %4 to i64*, !insn.addr !572
  %6 = inttoptr i64 %3 to i64*, !insn.addr !572
  %7 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_(i64* %5, i64* %6), !insn.addr !572
  %8 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !573
  %9 = inttoptr i64 %8 to i64*, !insn.addr !573
  %10 = load i64, i64* %9, align 8, !insn.addr !573
  %11 = add i64 %1, ptrtoint (i128** @global_var_40 to i64), !insn.addr !574
  %12 = inttoptr i64 %11 to i64*, !insn.addr !574
  store i64 %10, i64* %12, align 8, !insn.addr !574
  ret i64 %1, !insn.addr !575

; uselistorder directives
  uselistorder i64 (i64*, i64*)* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_, { 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E5clearEv(i64* %result) local_unnamed_addr {
dec_label_pc_1ebc:
  %rax.0.reg2mem = alloca i64, !insn.addr !576
  %stack_var_-120.02.reg2mem = alloca i64, !insn.addr !576
  %stack_var_-104 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !577
  %1 = call i64 @_ZN4llvm14DebugEpochBase14incrementEpochEv(i64* %result), !insn.addr !578
  %2 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumEntriesEv(i64* %result), !insn.addr !579
  %3 = trunc i64 %2 to i32, !insn.addr !580
  %4 = icmp eq i32 %3, 0, !insn.addr !580
  %5 = icmp eq i1 %4, false, !insn.addr !581
  br i1 %5, label %dec_label_pc_1f18.critedge, label %dec_label_pc_1ef4, !insn.addr !581

dec_label_pc_1ef4:                                ; preds = %dec_label_pc_1ebc
  %6 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16getNumTombstonesEv(i64* %result), !insn.addr !582
  %7 = trunc i64 %6 to i32, !insn.addr !583
  %8 = icmp eq i32 %7, 0, !insn.addr !583
  %9 = icmp eq i1 %8, false, !insn.addr !584
  br i1 %9, label %dec_label_pc_1f18.critedge, label %dec_label_pc_1ff9, !insn.addr !584

dec_label_pc_1f18.critedge:                       ; preds = %dec_label_pc_1ebc, %dec_label_pc_1ef4
  %10 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumEntriesEv(i64* %result), !insn.addr !585
  %.tr = trunc i64 %10 to i32
  %11 = mul i32 %.tr, 4, !insn.addr !586
  %12 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !587
  %13 = trunc i64 %12 to i32, !insn.addr !588
  %14 = icmp ult i32 %11, %13, !insn.addr !588
  %15 = icmp eq i1 %14, false, !insn.addr !589
  br i1 %15, label %dec_label_pc_1f53, label %dec_label_pc_1f3b, !insn.addr !589

dec_label_pc_1f3b:                                ; preds = %dec_label_pc_1f18.critedge
  %16 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !590
  %17 = trunc i64 %16 to i32, !insn.addr !591
  %18 = icmp ugt i32 %17, ptrtoint (i128** @global_var_40 to i32)
  br i1 %18, label %dec_label_pc_1f5c, label %dec_label_pc_1f53, !insn.addr !592

dec_label_pc_1f53:                                ; preds = %dec_label_pc_1f3b, %dec_label_pc_1f18.critedge
  %19 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* nonnull %stack_var_-104), !insn.addr !593
  %20 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !594
  %21 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result), !insn.addr !595
  %22 = icmp eq i64 %20, %21, !insn.addr !596
  %23 = icmp eq i1 %22, false, !insn.addr !597
  store i64 %20, i64* %stack_var_-120.02.reg2mem, !insn.addr !597
  br i1 %23, label %dec_label_pc_1f9b, label %dec_label_pc_1fc8, !insn.addr !597

dec_label_pc_1f5c:                                ; preds = %dec_label_pc_1f3b
  %24 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16shrink_and_clearEv(i64* %result), !insn.addr !598
  br label %dec_label_pc_1ff9, !insn.addr !599

dec_label_pc_1f9b:                                ; preds = %dec_label_pc_1f53, %dec_label_pc_1f9b
  %stack_var_-120.02.reload = load i64, i64* %stack_var_-120.02.reg2mem
  %25 = inttoptr i64 %stack_var_-120.02.reload to i64*, !insn.addr !600
  %26 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %25), !insn.addr !600
  %27 = inttoptr i64 %26 to i64*, !insn.addr !601
  %28 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyaSERKS1_(i64* %27, i64* nonnull %stack_var_-104), !insn.addr !601
  %29 = add i64 %stack_var_-120.02.reload, 88, !insn.addr !602
  %30 = icmp eq i64 %29, %21, !insn.addr !596
  %31 = icmp eq i1 %30, false, !insn.addr !597
  store i64 %29, i64* %stack_var_-120.02.reg2mem, !insn.addr !597
  br i1 %31, label %dec_label_pc_1f9b, label %dec_label_pc_1fc8, !insn.addr !597

dec_label_pc_1fc8:                                ; preds = %dec_label_pc_1f9b, %dec_label_pc_1f53
  %32 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13setNumEntriesEj(i64* %result, i32 0), !insn.addr !603
  %33 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16setNumTombstonesEj(i64* %result, i32 0), !insn.addr !604
  %34 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-104), !insn.addr !605
  br label %dec_label_pc_1ff9, !insn.addr !606

dec_label_pc_1ff9:                                ; preds = %dec_label_pc_1ef4, %dec_label_pc_1fc8, %dec_label_pc_1f5c
  %35 = call i64 @__readfsqword(i64 40), !insn.addr !607
  %36 = icmp eq i64 %0, %35, !insn.addr !607
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !608
  br i1 %36, label %dec_label_pc_200d, label %dec_label_pc_2008, !insn.addr !608

dec_label_pc_2008:                                ; preds = %dec_label_pc_1ff9
  %37 = call i64 @__stack_chk_fail(), !insn.addr !609
  store i64 %37, i64* %rax.0.reg2mem, !insn.addr !609
  br label %dec_label_pc_200d, !insn.addr !609

dec_label_pc_200d:                                ; preds = %dec_label_pc_2008, %dec_label_pc_1ff9
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !610

; uselistorder directives
  uselistorder i64 %21, { 1, 0 }
  uselistorder i64* %stack_var_-120.02.reg2mem, { 2, 0, 1 }
  uselistorder i64* %result, { 0, 1, 4, 2, 3, 5, 6, 7, 8, 9, 10 }
  uselistorder label %dec_label_pc_1ff9, { 1, 2, 0 }
  uselistorder label %dec_label_pc_1f9b, { 1, 0 }
  uselistorder label %dec_label_pc_1f18.critedge, { 1, 0 }
}

define i64 @_ZNKSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEcvbEv(i64* %result) local_unnamed_addr {
dec_label_pc_2014:
  %0 = call i64 @_ZNKSt19_Optional_base_implIN22brighten_state_forward12_GLOBAL__N_18AliasKeyESt14_Optional_baseIS2_Lb0ELb0EEE13_M_is_engagedEv(i64* %result), !insn.addr !611
  ret i64 %0, !insn.addr !612
}

define i64 @_ZNRSt8optionalIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_202e:
  %0 = call i64 @_ZNSt19_Optional_base_implIN22brighten_state_forward12_GLOBAL__N_18AliasKeyESt14_Optional_baseIS2_Lb0ELb0EEE6_M_getEv(i64* %result), !insn.addr !613
  ret i64 %0, !insn.addr !614
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E4findERKS4_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2048:
  %storemerge1.reg2mem = alloca i64, !insn.addr !615
  %storemerge.reg2mem = alloca i64, !insn.addr !615
  %0 = call i64* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E6doFindIS4_EEPS9_RKT_(i64* %result, i64* %arg2), !insn.addr !616
  %1 = icmp eq i64* %0, null, !insn.addr !617
  br i1 %1, label %dec_label_pc_20b8, label %dec_label_pc_2076, !insn.addr !618

dec_label_pc_2076:                                ; preds = %dec_label_pc_2048
  %2 = call i1 @_ZN4llvm20shouldReverseIterateIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEEbv(), !insn.addr !619
  %3 = icmp eq i1 %2, false, !insn.addr !620
  br i1 %3, label %dec_label_pc_208d, label %dec_label_pc_207f, !insn.addr !621

dec_label_pc_207f:                                ; preds = %dec_label_pc_2076
  %4 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !622
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !623
  br label %dec_label_pc_2099, !insn.addr !623

dec_label_pc_208d:                                ; preds = %dec_label_pc_2076
  %5 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result), !insn.addr !624
  store i64 %5, i64* %storemerge.reg2mem, !insn.addr !624
  br label %dec_label_pc_2099, !insn.addr !624

dec_label_pc_2099:                                ; preds = %dec_label_pc_208d, %dec_label_pc_207f
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %6 = inttoptr i64 %storemerge.reload to i64*, !insn.addr !625
  %7 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12makeIteratorEPS9_SC_RNS_14DebugEpochBaseEb(i64* %result, i64* nonnull %0, i64* %6, i64* %result, i1 true), !insn.addr !625
  store i64 %7, i64* %storemerge1.reg2mem, !insn.addr !626
  br label %dec_label_pc_20c5, !insn.addr !626

dec_label_pc_20b8:                                ; preds = %dec_label_pc_2048
  %8 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E3endEv(i64* %result), !insn.addr !627
  store i64 %8, i64* %storemerge1.reg2mem, !insn.addr !628
  br label %dec_label_pc_20c5, !insn.addr !628

dec_label_pc_20c5:                                ; preds = %dec_label_pc_20b8, %dec_label_pc_2099
  %storemerge1.reload = load i64, i64* %storemerge1.reg2mem
  ret i64 %storemerge1.reload, !insn.addr !629

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %storemerge1.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E3endEv, { 1, 0 }
  uselistorder i64* %result, { 0, 1, 2, 4, 3, 5 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_20c8:
  %0 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result), !insn.addr !630
  %1 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result), !insn.addr !631
  %2 = inttoptr i64 %1 to i64*, !insn.addr !632
  %3 = inttoptr i64 %0 to i64*, !insn.addr !632
  %4 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12makeIteratorEPS9_SC_RNS_14DebugEpochBaseEb(i64* %result, i64* %2, i64* %3, i64* %result, i1 true), !insn.addr !632
  ret i64 %4, !insn.addr !633

; uselistorder directives
  uselistorder i64 (i64*, i64*, i64*, i64*, i1)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12makeIteratorEPS9_SC_RNS_14DebugEpochBaseEb, { 1, 0 }
}

define i64 @_ZN4llvmeqERKNS_16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEESB_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_2115:
  %rdi.0.reg2mem = alloca i64, !insn.addr !634
  %rsi.2.reg2mem = alloca i64, !insn.addr !634
  %rsi.1.reg2mem = alloca i64, !insn.addr !634
  %rsi.01.reg2mem = alloca i64, !insn.addr !634
  %0 = ptrtoint i64* %arg2 to i64
  %1 = icmp eq i64* %arg1, null, !insn.addr !635
  br i1 %1, label %dec_label_pc_216a, label %dec_label_pc_2132, !insn.addr !636

dec_label_pc_2132:                                ; preds = %dec_label_pc_2115
  %2 = call i64 @_ZNK4llvm14DebugEpochBase10HandleBase14isHandleInSyncEv(i64* nonnull %arg1), !insn.addr !637
  %3 = trunc i64 %2 to i8, !insn.addr !638
  %4 = icmp eq i8 %3, 0, !insn.addr !638
  %5 = icmp eq i1 %4, false, !insn.addr !639
  br i1 %5, label %dec_label_pc_216a, label %dec_label_pc_216a.thread, !insn.addr !639

dec_label_pc_216a.thread:                         ; preds = %dec_label_pc_2132
  %6 = call i64 @__assert_fail(i64 ptrtoint ([60 x i8]* @global_var_6424 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1298, i64 ptrtoint ([612 x i8]* @global_var_618c to i64)), !insn.addr !640
  store i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64* %rsi.01.reg2mem
  br label %dec_label_pc_2176

dec_label_pc_216a:                                ; preds = %dec_label_pc_2132, %dec_label_pc_2115
  %7 = icmp eq i64* %arg2, null, !insn.addr !641
  store i64 %0, i64* %rsi.01.reg2mem, !insn.addr !642
  store i64 0, i64* %rsi.1.reg2mem, !insn.addr !642
  br i1 %7, label %dec_label_pc_21ae, label %dec_label_pc_2176, !insn.addr !642

dec_label_pc_2176:                                ; preds = %dec_label_pc_216a.thread, %dec_label_pc_216a
  %rsi.01.reload = load i64, i64* %rsi.01.reg2mem
  %8 = call i64 @_ZNK4llvm14DebugEpochBase10HandleBase14isHandleInSyncEv(i64* %arg2), !insn.addr !643
  %9 = trunc i64 %8 to i8, !insn.addr !644
  %10 = icmp eq i8 %9, 0, !insn.addr !644
  %11 = icmp eq i1 %10, false, !insn.addr !645
  store i64 %rsi.01.reload, i64* %rsi.1.reg2mem, !insn.addr !645
  br i1 %11, label %dec_label_pc_21ae, label %dec_label_pc_2186, !insn.addr !645

dec_label_pc_2186:                                ; preds = %dec_label_pc_2176
  %12 = call i64 @__assert_fail(i64 ptrtoint ([60 x i8]* @global_var_6464 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1299, i64 ptrtoint ([612 x i8]* @global_var_618c to i64)), !insn.addr !646
  store i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64* %rsi.1.reg2mem, !insn.addr !646
  br label %dec_label_pc_21ae, !insn.addr !646

dec_label_pc_21ae:                                ; preds = %dec_label_pc_2186, %dec_label_pc_2176, %dec_label_pc_216a
  %rsi.1.reload = load i64, i64* %rsi.1.reg2mem
  %13 = call i64 @_ZNK4llvm14DebugEpochBase10HandleBase15getEpochAddressEv(i64* %arg1), !insn.addr !647
  %14 = call i64 @_ZNK4llvm14DebugEpochBase10HandleBase15getEpochAddressEv(i64* %arg2), !insn.addr !648
  %15 = icmp eq i64 %13, %14, !insn.addr !649
  store i64 %rsi.1.reload, i64* %rsi.2.reg2mem, !insn.addr !650
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !650
  br i1 %15, label %dec_label_pc_21f6, label %dec_label_pc_21ce, !insn.addr !650

dec_label_pc_21ce:                                ; preds = %dec_label_pc_21ae
  %16 = call i64 @__assert_fail(i64 ptrtoint ([86 x i8]* @global_var_64a4 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1300, i64 ptrtoint ([612 x i8]* @global_var_618c to i64)), !insn.addr !651
  store i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64* %rsi.2.reg2mem, !insn.addr !651
  store i64 ptrtoint ([86 x i8]* @global_var_64a4 to i64), i64* %rdi.0.reg2mem, !insn.addr !651
  br label %dec_label_pc_21f6, !insn.addr !651

dec_label_pc_21f6:                                ; preds = %dec_label_pc_21ce, %dec_label_pc_21ae
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %rsi.2.reload = load i64, i64* %rsi.2.reg2mem
  %17 = icmp eq i64 %rdi.0.reload, %rsi.2.reload, !insn.addr !652
  %18 = zext i1 %17 to i64, !insn.addr !653
  %19 = and i64 %rsi.2.reload, -256, !insn.addr !653
  %20 = or i64 %19, %18, !insn.addr !653
  ret i64 %20, !insn.addr !654

; uselistorder directives
  uselistorder i64 %rsi.2.reload, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm14DebugEpochBase10HandleBase15getEpochAddressEv, { 1, 0 }
  uselistorder i64* %arg2, { 1, 2, 0, 3 }
  uselistorder label %dec_label_pc_2176, { 1, 0 }
}

define i64 @_ZNK4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEptEv(i64* %result) local_unnamed_addr {
dec_label_pc_2210:
  %rdi.1.reg2mem = alloca i64, !insn.addr !655
  %rdi.0.reg2mem = alloca i64, !insn.addr !655
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm14DebugEpochBase10HandleBase14isHandleInSyncEv(i64* %result), !insn.addr !656
  %2 = trunc i64 %1 to i8, !insn.addr !657
  %3 = icmp eq i8 %2, 0, !insn.addr !657
  %4 = icmp eq i1 %3, false, !insn.addr !658
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !658
  br i1 %4, label %dec_label_pc_2254, label %dec_label_pc_222c, !insn.addr !658

dec_label_pc_222c:                                ; preds = %dec_label_pc_2210
  %5 = call i64 @__assert_fail(i64 ptrtoint ([47 x i8]* @global_var_6774 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1289, i64 ptrtoint ([628 x i8]* @global_var_64fc to i64)), !insn.addr !659
  store i64 ptrtoint ([47 x i8]* @global_var_6774 to i64), i64* %rdi.0.reg2mem, !insn.addr !659
  br label %dec_label_pc_2254, !insn.addr !659

dec_label_pc_2254:                                ; preds = %dec_label_pc_222c, %dec_label_pc_2210
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %6 = add i64 %0, 8, !insn.addr !660
  %7 = inttoptr i64 %6 to i64*, !insn.addr !660
  %8 = load i64, i64* %7, align 8, !insn.addr !660
  %9 = icmp eq i64 %rdi.0.reload, %8, !insn.addr !661
  %10 = icmp eq i1 %9, false, !insn.addr !662
  store i64 %rdi.0.reload, i64* %rdi.1.reg2mem, !insn.addr !662
  br i1 %10, label %dec_label_pc_2290, label %dec_label_pc_2268, !insn.addr !662

dec_label_pc_2268:                                ; preds = %dec_label_pc_2254
  %11 = call i64 @__assert_fail(i64 ptrtoint ([45 x i8]* @global_var_67a4 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1290, i64 ptrtoint ([628 x i8]* @global_var_64fc to i64)), !insn.addr !663
  store i64 ptrtoint ([45 x i8]* @global_var_67a4 to i64), i64* %rdi.1.reg2mem, !insn.addr !663
  br label %dec_label_pc_2290, !insn.addr !663

dec_label_pc_2290:                                ; preds = %dec_label_pc_2268, %dec_label_pc_2254
  %rdi.1.reload = load i64, i64* %rdi.1.reg2mem
  %12 = call i1 @_ZN4llvm20shouldReverseIterateIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEEbv(), !insn.addr !664
  %13 = icmp eq i1 %12, false, !insn.addr !665
  %14 = add i64 %rdi.1.reload, -88
  %storemerge = select i1 %13, i64 %rdi.1.reload, i64 %14
  ret i64 %storemerge, !insn.addr !666

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_EixERKS4_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_22b0:
  %rax.0.reg2mem = alloca i64, !insn.addr !667
  %storemerge.in.reg2mem = alloca i64, !insn.addr !667
  %stack_var_-24 = alloca i64**, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !668
  %1 = bitcast i64*** %stack_var_-24 to i64**, !insn.addr !669
  %2 = call i1 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15LookupBucketForIS4_EEbRKT_RPS9_(i64* %result, i64* %arg2, i64** nonnull %1), !insn.addr !669
  %3 = icmp eq i1 %2, false, !insn.addr !670
  %4 = load i64**, i64*** %stack_var_-24, align 8
  br i1 %3, label %dec_label_pc_22f4, label %dec_label_pc_22ea, !insn.addr !671

dec_label_pc_22ea:                                ; preds = %dec_label_pc_22b0
  %5 = ptrtoint i64** %4 to i64, !insn.addr !672
  store i64 %5, i64* %storemerge.in.reg2mem, !insn.addr !673
  br label %dec_label_pc_230f, !insn.addr !673

dec_label_pc_22f4:                                ; preds = %dec_label_pc_22b0
  %6 = ptrtoint i64* %arg2 to i64
  %7 = call i64* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16InsertIntoBucketIRKS4_JEEEPS9_SF_OT_DpOT0_(i64* %result, i64** %4, i64 %6), !insn.addr !674
  %8 = ptrtoint i64* %7 to i64, !insn.addr !674
  store i64 %8, i64* %storemerge.in.reg2mem, !insn.addr !675
  br label %dec_label_pc_230f, !insn.addr !675

dec_label_pc_230f:                                ; preds = %dec_label_pc_22f4, %dec_label_pc_22ea
  %storemerge.in.reload = load i64, i64* %storemerge.in.reg2mem
  %storemerge = add i64 %storemerge.in.reload, 72
  %9 = call i64 @__readfsqword(i64 40), !insn.addr !676
  %10 = icmp eq i64 %0, %9, !insn.addr !676
  store i64 %storemerge, i64* %rax.0.reg2mem, !insn.addr !677
  br i1 %10, label %dec_label_pc_2323, label %dec_label_pc_231e, !insn.addr !677

dec_label_pc_231e:                                ; preds = %dec_label_pc_230f
  %11 = call i64 @__stack_chk_fail(), !insn.addr !678
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !678
  br label %dec_label_pc_2323, !insn.addr !678

dec_label_pc_2323:                                ; preds = %dec_label_pc_231e, %dec_label_pc_230f
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !679

; uselistorder directives
  uselistorder i64** %4, { 1, 0 }
  uselistorder i64* %storemerge.in.reg2mem, { 0, 2, 1 }
  uselistorder i64* %arg2, { 1, 0 }
}

define i64 @_ZN4llvm11PassManagerINS_6ModuleENS_15AnalysisManagerIS1_JEEEJEE7addPassIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEEENSt9enable_ifIXnt9is_same_vIT_S4_EEvE4typeEOSA_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2326:
  %rax.0.reg2mem = alloca i64, !insn.addr !680
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !681
  %1 = call i64 @_Znwm(i64 16), !insn.addr !682
  %2 = call i64* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg2), !insn.addr !683
  %3 = call i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEEC1ES5_(i64 %1), !insn.addr !684
  %4 = inttoptr i64 %1 to i64*, !insn.addr !685
  %5 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1IS8_vEEPS6_(i64* nonnull %stack_var_-40, i64* %4), !insn.addr !685
  %6 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE9push_backEOSA_(i64* %result, i64* nonnull %stack_var_-40), !insn.addr !686
  %7 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev(i64* nonnull %stack_var_-40), !insn.addr !687
  %8 = call i64 @__readfsqword(i64 40), !insn.addr !688
  %9 = icmp eq i64 %0, %8, !insn.addr !688
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !689
  br i1 %9, label %dec_label_pc_23ac, label %dec_label_pc_23a7, !insn.addr !689

dec_label_pc_23a7:                                ; preds = %dec_label_pc_2326
  %10 = call i64 @__stack_chk_fail(), !insn.addr !690
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !690
  br label %dec_label_pc_23ac, !insn.addr !690

dec_label_pc_23ac:                                ; preds = %dec_label_pc_23a7, %dec_label_pc_2326
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !691
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1IZZ21llvmGetPassPluginInfoENKUlRS9_E_clESF_EUlS1_S7_SB_E_vEEOT_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_23b6:
  %0 = alloca i128
  %rax.0.reg2mem = alloca i64, !insn.addr !692
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %result to i64
  %3 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !693
  %4 = bitcast i64* %rdi to i128*
  %5 = load i128, i128* %4, align 8, !insn.addr !694
  call void @__asm_movups(i128 %5, i128 %3), !insn.addr !694
  %6 = add i64 %2, 16, !insn.addr !695
  %7 = inttoptr i64 %6 to i64*, !insn.addr !695
  %8 = load i64, i64* %7, align 8, !insn.addr !695
  call void @__asm_movq(i64 %8, i128 %3), !insn.addr !695
  %9 = call i64 @_ZNSt14_Function_baseC1Ev(i64* %result), !insn.addr !696
  %10 = add i64 %2, 24, !insn.addr !697
  %11 = inttoptr i64 %10 to i64*, !insn.addr !697
  store i64 0, i64* %11, align 8, !insn.addr !697
  %12 = call i1 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E21_M_not_empty_functionISF_EEbRKT_(i64* %arg2), !insn.addr !698
  %13 = icmp eq i1 %12, false, !insn.addr !699
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !700
  br i1 %13, label %dec_label_pc_243a, label %dec_label_pc_23fe, !insn.addr !700

dec_label_pc_23fe:                                ; preds = %dec_label_pc_23b6
  %14 = call i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg2), !insn.addr !701
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorISF_EEvRSt9_Any_dataOT_(i64* %result, i64* %14), !insn.addr !702
  store i64 12601, i64* %11, align 8, !insn.addr !703
  store i64 12719, i64* %7, align 8, !insn.addr !704
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !704
  br label %dec_label_pc_243a, !insn.addr !704

dec_label_pc_243a:                                ; preds = %dec_label_pc_23fe, %dec_label_pc_23b6
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !705

; uselistorder directives
  uselistorder i128 %3, { 1, 0 }
}

define i64 @_ZN4llvm20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC1ES6_S6_SA_(i64 %arg1, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_243e:
  %0 = call i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC2ES6_S6_SA_(i64 %arg1, i64 %arg2, i64 %arg3), !insn.addr !706
  ret i64 %0, !insn.addr !707
}

define i64 @_ZN4llvm10make_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEENS8_IT_EESE_SE_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_246c:
  %stack_var_8 = alloca i64, align 8
  %stack_var_32 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_32 to i64**, !insn.addr !708
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !708
  %2 = bitcast i64* %stack_var_8 to i64**, !insn.addr !709
  %3 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %2), !insn.addr !709
  %4 = call i64 @_ZN4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEC1ESC_SC_(i64 %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !710
  ret i64 %arg1, !insn.addr !711
}

define i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_24e9:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !712
  ret i64** %0, !insn.addr !712
}

define i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_24f7:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !713
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !714
  %3 = bitcast i64** %2 to i64*, !insn.addr !715
  %4 = call i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE5beginEv(i64* %result, i64* %3), !insn.addr !715
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !716
  %6 = icmp eq i64 %0, %5, !insn.addr !716
  br i1 %6, label %dec_label_pc_254f, label %dec_label_pc_254a, !insn.addr !717

dec_label_pc_254a:                                ; preds = %dec_label_pc_24f7
  %7 = call i64 @__stack_chk_fail(), !insn.addr !718
  br label %dec_label_pc_254f, !insn.addr !718

dec_label_pc_254f:                                ; preds = %dec_label_pc_254a, %dec_label_pc_24f7
  %8 = ptrtoint i64* %result to i64
  ret i64 %8, !insn.addr !719

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2555:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !720
  ret i64* %0, !insn.addr !720
}

define i64* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2563:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !721
  ret i64* %0, !insn.addr !721
}

define i64 @_ZN4llvm15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEC1ESD_SE_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_2572:
  %stack_var_-33 = alloca i64, align 8
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !722
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !722
  %2 = call i64 @_ZN4llvm21iterator_adaptor_baseINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS_17DbgVariableRecordEEEESE_SD_SI_lPSI_SI_EC2ESE_(i64 %arg1), !insn.addr !723
  %3 = add i64 %arg1, 24, !insn.addr !724
  %4 = bitcast i64* %stack_var_-33 to i64**, !insn.addr !725
  %5 = call i64* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_(i64** nonnull %4), !insn.addr !725
  %6 = inttoptr i64 %3 to i64*, !insn.addr !726
  %7 = call i64 @_ZN4llvm15callable_detail8CallableIZNS_L13filterDbgVarsENS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS6_E0_Lb0EEC1ERKSB_(i64* %6, i64* %5), !insn.addr !726
  ret i64 %7, !insn.addr !727

; uselistorder directives
  uselistorder i64* (i64**)* @_ZSt4moveIRZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EONSt16remove_referenceIT_E4typeEOSD_, { 1, 0 }
}

define i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS2_IS9_EEEUlRS7_E_St26bidirectional_iterator_tagEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSH_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_25e2:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !728
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE(i64* %1), !insn.addr !729
  %3 = bitcast i64** %2 to i64*, !insn.addr !730
  %4 = call i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE3endEv(i64* %result, i64* %3), !insn.addr !730
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !731
  %6 = icmp eq i64 %0, %5, !insn.addr !731
  br i1 %6, label %dec_label_pc_263a, label %dec_label_pc_2635, !insn.addr !732

dec_label_pc_2635:                                ; preds = %dec_label_pc_25e2
  %7 = call i64 @__stack_chk_fail(), !insn.addr !733
  br label %dec_label_pc_263a, !insn.addr !733

dec_label_pc_263a:                                ; preds = %dec_label_pc_2635, %dec_label_pc_25e2
  %8 = ptrtoint i64* %result to i64
  ret i64 %8, !insn.addr !734

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRN4llvm14iterator_rangeINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS1_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEEEEOT_RNSt16remove_referenceISG_E4typeE, { 3, 2, 1, 0 }
  uselistorder i64* %result, { 1, 0 }
}

define i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** %arg1) local_unnamed_addr {
dec_label_pc_2640:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !735
  ret i64* %0, !insn.addr !735
}

define i64 @_ZN4llvm14iterator_rangeINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsES9_EUlSA_E0_St17reference_wrapperINS_17DbgVariableRecordEEEEEC1ESI_SI_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_264e:
  %stack_var_40 = alloca i64, align 8
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !736
  %1 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %0), !insn.addr !736
  %2 = ptrtoint i64* %1 to i64, !insn.addr !736
  %3 = load i64, i64* %1, align 8, !insn.addr !737
  %4 = add i64 %2, 8, !insn.addr !738
  %5 = inttoptr i64 %4 to i64*, !insn.addr !738
  %6 = load i64, i64* %5, align 8, !insn.addr !738
  %7 = inttoptr i64 %arg1 to i64*, !insn.addr !739
  store i64 %3, i64* %7, align 8, !insn.addr !739
  %8 = add i64 %arg1, 8, !insn.addr !740
  %9 = inttoptr i64 %8 to i64*, !insn.addr !740
  store i64 %6, i64* %9, align 8, !insn.addr !740
  %10 = add i64 %2, 16, !insn.addr !741
  %11 = inttoptr i64 %10 to i64*, !insn.addr !741
  %12 = load i64, i64* %11, align 8, !insn.addr !741
  %13 = add i64 %2, 24, !insn.addr !742
  %14 = inttoptr i64 %13 to i64*, !insn.addr !742
  %15 = load i64, i64* %14, align 8, !insn.addr !742
  %16 = add i64 %arg1, 16, !insn.addr !743
  %17 = inttoptr i64 %16 to i64*, !insn.addr !743
  store i64 %12, i64* %17, align 8, !insn.addr !743
  %18 = add i64 %arg1, 24, !insn.addr !744
  %19 = inttoptr i64 %18 to i64*, !insn.addr !744
  store i64 %15, i64* %19, align 8, !insn.addr !744
  %20 = bitcast i64* %stack_var_40 to i64**, !insn.addr !745
  %21 = call i64* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_(i64** nonnull %20), !insn.addr !745
  %22 = ptrtoint i64* %21 to i64, !insn.addr !745
  %23 = load i64, i64* %21, align 8, !insn.addr !746
  %24 = add i64 %22, 8, !insn.addr !747
  %25 = inttoptr i64 %24 to i64*, !insn.addr !747
  %26 = load i64, i64* %25, align 8, !insn.addr !747
  %27 = add i64 %arg1, 32, !insn.addr !748
  %28 = inttoptr i64 %27 to i64*, !insn.addr !748
  store i64 %23, i64* %28, align 8, !insn.addr !748
  %29 = add i64 %arg1, 40, !insn.addr !749
  %30 = inttoptr i64 %29 to i64*, !insn.addr !749
  store i64 %26, i64* %30, align 8, !insn.addr !749
  %31 = add i64 %22, 16, !insn.addr !750
  %32 = inttoptr i64 %31 to i64*, !insn.addr !750
  %33 = load i64, i64* %32, align 8, !insn.addr !750
  %34 = add i64 %22, 24, !insn.addr !751
  %35 = inttoptr i64 %34 to i64*, !insn.addr !751
  %36 = load i64, i64* %35, align 8, !insn.addr !751
  %37 = add i64 %arg1, 48, !insn.addr !752
  %38 = inttoptr i64 %37 to i64*, !insn.addr !752
  store i64 %33, i64* %38, align 8, !insn.addr !752
  %39 = add i64 %arg1, 56, !insn.addr !753
  %40 = inttoptr i64 %39 to i64*, !insn.addr !753
  store i64 %36, i64* %40, align 8, !insn.addr !753
  ret i64 %33, !insn.addr !754

; uselistorder directives
  uselistorder i64 %33, { 1, 0 }
  uselistorder i64 %22, { 2, 1, 0 }
  uselistorder i64 %2, { 2, 1, 0 }
  uselistorder i64* (i64**)* @_ZSt4moveIRN4llvm15mapped_iteratorINS0_20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS0_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS0_17DbgVariableRecordEEEEEONSt16remove_referenceIT_E4typeEOSM_, { 3, 2, 1, 0 }
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_StorageIS2_Lb0EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_26be:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !755
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_StorageIS2_Lb0EED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_26ca:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !756
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_M_resetEv(i64* %result) local_unnamed_addr {
dec_label_pc_26d6:
  %rax.0.reg2mem = alloca i64, !insn.addr !757
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 72, !insn.addr !758
  %2 = inttoptr i64 %1 to i8*, !insn.addr !758
  %3 = load i8, i8* %2, align 1, !insn.addr !758
  %4 = icmp eq i8 %3, 0, !insn.addr !759
  br i1 %4, label %dec_label_pc_26fc, label %dec_label_pc_26ee, !insn.addr !760

dec_label_pc_26ee:                                ; preds = %dec_label_pc_26d6
  %5 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE10_M_destroyEv(i64* %result), !insn.addr !761
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !762
  br label %dec_label_pc_2704, !insn.addr !762

dec_label_pc_26fc:                                ; preds = %dec_label_pc_26d6
  store i8 0, i8* %2, align 1, !insn.addr !763
  store i64 %0, i64* %rax.0.reg2mem, !insn.addr !763
  br label %dec_label_pc_2704, !insn.addr !763

dec_label_pc_2704:                                ; preds = %dec_label_pc_26fc, %dec_label_pc_26ee
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !764

; uselistorder directives
  uselistorder i64* %rax.0.reg2mem, { 0, 2, 1 }
}

define i64* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_2707:
  ret i64* %arg1, !insn.addr !765
}

define i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb1ELb0ELb0EECI2St22_Optional_payload_baseIS2_EIJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_2716:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC2IJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2), !insn.addr !766
  ret i64 %0, !insn.addr !767
}

define i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0ELb0EECI1St22_Optional_payload_baseIS2_EIJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_273c:
  %0 = call i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb1ELb0ELb0EECI2St22_Optional_payload_baseIS2_EIJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2), !insn.addr !768
  ret i64 %0, !insn.addr !769
}

define i64 @_ZNSt14_Optional_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0EEC2IJS2_ELb0EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_2762:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !770
  %1 = call i64* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %0), !insn.addr !770
  %2 = ptrtoint i64* %1 to i64, !insn.addr !770
  %3 = call i64 @_ZNSt17_Optional_payloadIN22brighten_state_forward12_GLOBAL__N_18AliasKeyELb0ELb0ELb0EECI1St22_Optional_payload_baseIS2_EIJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !771
  ret i64 %3, !insn.addr !772
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE4initEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_2796:
  %rax.0.reg2mem = alloca i64, !insn.addr !773
  %0 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E31getMinBucketToReserveForEntriesEj(i64* %result, i32 %arg2), !insn.addr !774
  %1 = trunc i64 %0 to i32, !insn.addr !775
  %2 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE15allocateBucketsEj(i64* %result, i32 %1), !insn.addr !776
  %3 = trunc i64 %2 to i8, !insn.addr !777
  %4 = icmp eq i8 %3, 0, !insn.addr !777
  br i1 %4, label %dec_label_pc_27dc, label %dec_label_pc_27ce, !insn.addr !778

dec_label_pc_27ce:                                ; preds = %dec_label_pc_2796
  %5 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E9initEmptyEv(i64* %result), !insn.addr !779
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !780
  br label %dec_label_pc_27f2, !insn.addr !780

dec_label_pc_27dc:                                ; preds = %dec_label_pc_2796
  %6 = ptrtoint i64* %result to i64
  %7 = add i64 %6, 8, !insn.addr !781
  %8 = inttoptr i64 %7 to i32*, !insn.addr !781
  store i32 0, i32* %8, align 4, !insn.addr !781
  %9 = add i64 %6, 12, !insn.addr !782
  %10 = inttoptr i64 %9 to i32*, !insn.addr !782
  store i32 0, i32* %10, align 4, !insn.addr !782
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !782
  br label %dec_label_pc_27f2, !insn.addr !782

dec_label_pc_27f2:                                ; preds = %dec_label_pc_27dc, %dec_label_pc_27ce
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !783

; uselistorder directives
  uselistorder i64* %rax.0.reg2mem, { 0, 2, 1 }
  uselistorder i64* %result, { 3, 0, 1, 2 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10destroyAllEv(i64* %result) local_unnamed_addr {
dec_label_pc_27f6:
  %rax.0.reg2mem = alloca i64, !insn.addr !784
  %stack_var_-184.01.reg2mem = alloca i64, !insn.addr !784
  %stack_var_-88 = alloca i64, align 8
  %stack_var_-168 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !785
  %1 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !786
  %2 = trunc i64 %1 to i32, !insn.addr !787
  %3 = icmp eq i32 %2, 0, !insn.addr !787
  %4 = icmp eq i1 %3, false, !insn.addr !788
  %5 = icmp eq i1 %4, false, !insn.addr !789
  br i1 %5, label %dec_label_pc_2942, label %dec_label_pc_2833, !insn.addr !789

dec_label_pc_2833:                                ; preds = %dec_label_pc_27f6
  %6 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* nonnull %stack_var_-168), !insn.addr !790
  %7 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15getTombstoneKeyEv(i64* nonnull %stack_var_-88), !insn.addr !791
  %8 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !792
  %9 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result), !insn.addr !793
  %10 = icmp eq i64 %8, %9, !insn.addr !794
  %11 = icmp eq i1 %10, false, !insn.addr !795
  store i64 %8, i64* %stack_var_-184.01.reg2mem, !insn.addr !795
  br i1 %11, label %dec_label_pc_287f, label %dec_label_pc_2924, !insn.addr !795

dec_label_pc_287f:                                ; preds = %dec_label_pc_2833, %dec_label_pc_28f1
  %stack_var_-184.01.reload = load i64, i64* %stack_var_-184.01.reg2mem
  %12 = inttoptr i64 %stack_var_-184.01.reload to i64*, !insn.addr !796
  %13 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %12), !insn.addr !796
  %14 = inttoptr i64 %13 to i64*, !insn.addr !797
  %15 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %14, i64* nonnull %stack_var_-168), !insn.addr !797
  %16 = trunc i64 %15 to i8
  %17 = icmp eq i8 %16, 1, !insn.addr !798
  br i1 %17, label %dec_label_pc_28f1, label %dec_label_pc_28aa, !insn.addr !799

dec_label_pc_28aa:                                ; preds = %dec_label_pc_287f
  %18 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %12), !insn.addr !800
  %19 = inttoptr i64 %18 to i64*, !insn.addr !801
  %20 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %19, i64* nonnull %stack_var_-88), !insn.addr !801
  %21 = trunc i64 %20 to i8
  %22 = icmp eq i8 %21, 1, !insn.addr !802
  br i1 %22, label %dec_label_pc_28f1, label %dec_label_pc_28e2, !insn.addr !803

dec_label_pc_28e2:                                ; preds = %dec_label_pc_28aa
  %23 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE9getSecondEv(i64* %12), !insn.addr !804
  br label %dec_label_pc_28f1, !insn.addr !804

dec_label_pc_28f1:                                ; preds = %dec_label_pc_287f, %dec_label_pc_28aa, %dec_label_pc_28e2
  %24 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %12), !insn.addr !805
  %25 = inttoptr i64 %24 to i64*, !insn.addr !806
  %26 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* %25), !insn.addr !806
  %27 = add i64 %stack_var_-184.01.reload, 88, !insn.addr !807
  %28 = icmp eq i64 %27, %9, !insn.addr !794
  %29 = icmp eq i1 %28, false, !insn.addr !795
  store i64 %27, i64* %stack_var_-184.01.reg2mem, !insn.addr !795
  br i1 %29, label %dec_label_pc_287f, label %dec_label_pc_2924, !insn.addr !795

dec_label_pc_2924:                                ; preds = %dec_label_pc_28f1, %dec_label_pc_2833
  %30 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-88), !insn.addr !808
  %31 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-168), !insn.addr !809
  br label %dec_label_pc_2942, !insn.addr !810

dec_label_pc_2942:                                ; preds = %dec_label_pc_27f6, %dec_label_pc_2924
  %32 = call i64 @__readfsqword(i64 40), !insn.addr !811
  %33 = icmp eq i64 %0, %32, !insn.addr !811
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !812
  br i1 %33, label %dec_label_pc_2956, label %dec_label_pc_2951, !insn.addr !812

dec_label_pc_2951:                                ; preds = %dec_label_pc_2942
  %34 = call i64 @__stack_chk_fail(), !insn.addr !813
  store i64 %34, i64* %rax.0.reg2mem, !insn.addr !813
  br label %dec_label_pc_2956, !insn.addr !813

dec_label_pc_2956:                                ; preds = %dec_label_pc_2951, %dec_label_pc_2942
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !814

; uselistorder directives
  uselistorder i64* %12, { 2, 0, 1, 3 }
  uselistorder i64 %9, { 1, 0 }
  uselistorder i64* %stack_var_-184.01.reg2mem, { 2, 0, 1 }
  uselistorder label %dec_label_pc_2942, { 1, 0 }
  uselistorder label %dec_label_pc_28f1, { 2, 1, 0 }
  uselistorder label %dec_label_pc_287f, { 1, 0 }
}

define i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumEntriesEv(i64* %result) local_unnamed_addr {
dec_label_pc_2958:
  %0 = call i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE13getNumEntriesEv(i64* %result), !insn.addr !815
  ret i64 %0, !insn.addr !816
}

define i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16getNumTombstonesEv(i64* %result) local_unnamed_addr {
dec_label_pc_2972:
  %0 = call i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE16getNumTombstonesEv(i64* %result), !insn.addr !817
  ret i64 %0, !insn.addr !818
}

define i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result) local_unnamed_addr {
dec_label_pc_298c:
  %0 = call i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE13getNumBucketsEv(i64* %result), !insn.addr !819
  ret i64 %0, !insn.addr !820
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16shrink_and_clearEv(i64* %result) local_unnamed_addr {
dec_label_pc_29a6:
  %0 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE16shrink_and_clearEv(i64* %result), !insn.addr !821
  ret i64 %0, !insn.addr !822
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* %result) local_unnamed_addr {
dec_label_pc_29c1:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !823
  %1 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo11getEmptyKeyEv(i64* %result), !insn.addr !824
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !825
  %3 = icmp eq i64 %0, %2, !insn.addr !825
  br i1 %3, label %dec_label_pc_29fc, label %dec_label_pc_29f7, !insn.addr !826

dec_label_pc_29f7:                                ; preds = %dec_label_pc_29c1
  %4 = call i64 @__stack_chk_fail(), !insn.addr !827
  br label %dec_label_pc_29fc, !insn.addr !827

dec_label_pc_29fc:                                ; preds = %dec_label_pc_29f7, %dec_label_pc_29c1
  %5 = ptrtoint i64* %result to i64
  ret i64 %5, !insn.addr !828

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result) local_unnamed_addr {
dec_label_pc_2a02:
  %0 = call i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE10getBucketsEv(i64* %result), !insn.addr !829
  ret i64 %0, !insn.addr !830
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result) local_unnamed_addr {
dec_label_pc_2a1c:
  %0 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !831
  %1 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !832
  %2 = and i64 %1, 4294967295, !insn.addr !833
  %3 = mul nuw nsw i64 %2, 88, !insn.addr !834
  %4 = add i64 %3, %0, !insn.addr !835
  ret i64 %4, !insn.addr !836
}

define i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %result) local_unnamed_addr {
dec_label_pc_2a64:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !837
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13setNumEntriesEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_2a72:
  %0 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE13setNumEntriesEj(i64* %result, i32 %arg2), !insn.addr !838
  ret i64 %0, !insn.addr !839
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16setNumTombstonesEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_2a96:
  %0 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE16setNumTombstonesEj(i64* %result, i32 %arg2), !insn.addr !840
  ret i64 %0, !insn.addr !841
}

define i64 @_ZNKSt19_Optional_base_implIN22brighten_state_forward12_GLOBAL__N_18AliasKeyESt14_Optional_baseIS2_Lb0ELb0EEE13_M_is_engagedEv(i64* %result) local_unnamed_addr {
dec_label_pc_2aba:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 72, !insn.addr !842
  %2 = inttoptr i64 %1 to i8*, !insn.addr !842
  %3 = load i8, i8* %2, align 1, !insn.addr !842
  %4 = zext i8 %3 to i64, !insn.addr !842
  ret i64 %4, !insn.addr !843
}

define i64 @_ZNSt19_Optional_base_implIN22brighten_state_forward12_GLOBAL__N_18AliasKeyESt14_Optional_baseIS2_Lb0ELb0EEE6_M_getEv(i64* %result) local_unnamed_addr {
dec_label_pc_2acc:
  %0 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !844
  %1 = trunc i64 %0 to i8, !insn.addr !845
  %2 = icmp eq i8 %1, 0, !insn.addr !845
  br i1 %2, label %dec_label_pc_2b00, label %dec_label_pc_2ae1, !insn.addr !846

dec_label_pc_2ae1:                                ; preds = %dec_label_pc_2acc
  %3 = call i64 @_ZNKSt19_Optional_base_implIN22brighten_state_forward12_GLOBAL__N_18AliasKeyESt14_Optional_baseIS2_Lb0ELb0EEE13_M_is_engagedEv(i64* %result), !insn.addr !847
  br label %dec_label_pc_2b00

dec_label_pc_2b00:                                ; preds = %dec_label_pc_2ae1, %dec_label_pc_2acc
  %4 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE6_M_getEv(i64* %result), !insn.addr !848
  ret i64 %4, !insn.addr !849

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNKSt19_Optional_base_implIN22brighten_state_forward12_GLOBAL__N_18AliasKeyESt14_Optional_baseIS2_Lb0ELb0EEE13_M_is_engagedEv, { 1, 0 }
}

define i64* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E6doFindIS4_EEPS9_RKT_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_2b10:
  %rax.0.reg2mem = alloca i64, !insn.addr !850
  %rbx.0.reg2mem = alloca i64, !insn.addr !850
  %storemerge.reg2mem = alloca i64, !insn.addr !850
  %stack_var_-132.01.reg2mem = alloca i32, !insn.addr !850
  %stack_var_-128.02.reg2mem = alloca i32, !insn.addr !850
  %.reg2mem = alloca i64*, !insn.addr !850
  %stack_var_-104 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !851
  %1 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !852
  %2 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !853
  %3 = trunc i64 %2 to i32, !insn.addr !854
  %4 = icmp eq i32 %3, 0, !insn.addr !855
  %5 = icmp eq i1 %4, false, !insn.addr !856
  store i64 0, i64* %rbx.0.reg2mem, !insn.addr !856
  br i1 %5, label %dec_label_pc_2b6e, label %dec_label_pc_2c4c, !insn.addr !856

dec_label_pc_2b6e:                                ; preds = %dec_label_pc_2b10
  %6 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* nonnull %stack_var_-104), !insn.addr !857
  %7 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12getHashValueERKS4_(i64* %arg2), !insn.addr !858
  %8 = add i32 %3, -1, !insn.addr !859
  %9 = trunc i64 %7 to i32, !insn.addr !860
  %10 = and i32 %8, %9, !insn.addr !860
  %11 = zext i32 %10 to i64, !insn.addr !861
  %12 = mul nuw nsw i64 %11, 88, !insn.addr !862
  %13 = add i64 %12, %1, !insn.addr !863
  %14 = inttoptr i64 %13 to i64*, !insn.addr !864
  %15 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %14), !insn.addr !864
  %16 = inttoptr i64 %15 to i64*, !insn.addr !865
  %17 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %arg2, i64* %16), !insn.addr !865
  %18 = urem i64 %17, 256, !insn.addr !866
  %19 = icmp eq i64 %18, 0, !insn.addr !867
  %20 = icmp eq i1 %19, false, !insn.addr !868
  %21 = icmp eq i1 %20, false, !insn.addr !869
  store i64* %14, i64** %.reg2mem, !insn.addr !870
  store i32 1, i32* %stack_var_-128.02.reg2mem, !insn.addr !870
  store i32 %10, i32* %stack_var_-132.01.reg2mem, !insn.addr !870
  store i64 %13, i64* %storemerge.reg2mem, !insn.addr !870
  br i1 %21, label %dec_label_pc_2bf4, label %dec_label_pc_2c40, !insn.addr !870

dec_label_pc_2bf4:                                ; preds = %dec_label_pc_2b6e, %dec_label_pc_2c26
  %.reload = load i64*, i64** %.reg2mem
  %22 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %.reload), !insn.addr !871
  %23 = inttoptr i64 %22 to i64*, !insn.addr !872
  %24 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %23, i64* nonnull %stack_var_-104), !insn.addr !872
  %25 = urem i64 %24, 256, !insn.addr !873
  %26 = icmp eq i64 %25, 0, !insn.addr !874
  %27 = icmp eq i1 %26, false, !insn.addr !875
  %28 = icmp eq i1 %27, false, !insn.addr !876
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !877
  br i1 %28, label %dec_label_pc_2c26, label %dec_label_pc_2c40, !insn.addr !877

dec_label_pc_2c26:                                ; preds = %dec_label_pc_2bf4
  %stack_var_-132.01.reload = load i32, i32* %stack_var_-132.01.reg2mem
  %stack_var_-128.02.reload = load i32, i32* %stack_var_-128.02.reg2mem
  %29 = add i32 %stack_var_-128.02.reload, 1, !insn.addr !878
  %30 = add i32 %stack_var_-132.01.reload, %stack_var_-128.02.reload, !insn.addr !879
  %31 = and i32 %30, %8, !insn.addr !880
  %32 = zext i32 %31 to i64, !insn.addr !861
  %33 = mul nuw nsw i64 %32, 88, !insn.addr !862
  %34 = add i64 %33, %1, !insn.addr !863
  %35 = inttoptr i64 %34 to i64*, !insn.addr !864
  %36 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %35), !insn.addr !864
  %37 = inttoptr i64 %36 to i64*, !insn.addr !865
  %38 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %arg2, i64* %37), !insn.addr !865
  %39 = urem i64 %38, 256, !insn.addr !866
  %40 = icmp eq i64 %39, 0, !insn.addr !867
  %41 = icmp eq i1 %40, false, !insn.addr !868
  %42 = icmp eq i1 %41, false, !insn.addr !869
  store i64* %35, i64** %.reg2mem, !insn.addr !870
  store i32 %29, i32* %stack_var_-128.02.reg2mem, !insn.addr !870
  store i32 %31, i32* %stack_var_-132.01.reg2mem, !insn.addr !870
  store i64 %34, i64* %storemerge.reg2mem, !insn.addr !870
  br i1 %42, label %dec_label_pc_2bf4, label %dec_label_pc_2c40, !insn.addr !870

dec_label_pc_2c40:                                ; preds = %dec_label_pc_2c26, %dec_label_pc_2bf4, %dec_label_pc_2b6e
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %43 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-104), !insn.addr !881
  store i64 %storemerge.reload, i64* %rbx.0.reg2mem, !insn.addr !881
  br label %dec_label_pc_2c4c, !insn.addr !881

dec_label_pc_2c4c:                                ; preds = %dec_label_pc_2b10, %dec_label_pc_2c40
  %rbx.0.reload = load i64, i64* %rbx.0.reg2mem
  %44 = call i64 @__readfsqword(i64 40), !insn.addr !882
  %45 = icmp eq i64 %0, %44, !insn.addr !882
  store i64 %rbx.0.reload, i64* %rax.0.reg2mem, !insn.addr !883
  br i1 %45, label %dec_label_pc_2c63, label %dec_label_pc_2c5e, !insn.addr !883

dec_label_pc_2c5e:                                ; preds = %dec_label_pc_2c4c
  %46 = call i64 @__stack_chk_fail(), !insn.addr !884
  store i64 %46, i64* %rax.0.reg2mem, !insn.addr !884
  br label %dec_label_pc_2c63, !insn.addr !884

dec_label_pc_2c63:                                ; preds = %dec_label_pc_2c5e, %dec_label_pc_2c4c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %47 = inttoptr i64 %rax.0.reload to i64*, !insn.addr !885
  ret i64* %47, !insn.addr !885

; uselistorder directives
  uselistorder i32 %stack_var_-128.02.reload, { 1, 0 }
  uselistorder i32 %8, { 1, 0 }
  uselistorder i64** %.reg2mem, { 2, 0, 1 }
  uselistorder i32* %stack_var_-128.02.reg2mem, { 2, 0, 1 }
  uselistorder i32* %stack_var_-132.01.reg2mem, { 2, 0, 1 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1, 3 }
  uselistorder i64* %rbx.0.reg2mem, { 0, 2, 1 }
  uselistorder i64* %arg2, { 1, 0, 2 }
  uselistorder label %dec_label_pc_2c4c, { 1, 0 }
  uselistorder label %dec_label_pc_2bf4, { 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12makeIteratorEPS9_SC_RNS_14DebugEpochBaseEb(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4, i1 %arg5) local_unnamed_addr {
dec_label_pc_2c6a:
  %rax.0.reg2mem = alloca i64, !insn.addr !886
  %storemerge.reg2mem = alloca i64, !insn.addr !886
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !887
  %1 = call i1 @_ZN4llvm20shouldReverseIterateIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEEbv(), !insn.addr !888
  %2 = icmp eq i1 %1, false, !insn.addr !889
  br i1 %2, label %dec_label_pc_2cf5, label %dec_label_pc_2ca0, !insn.addr !890

dec_label_pc_2ca0:                                ; preds = %dec_label_pc_2c6a
  %3 = ptrtoint i64* %arg2 to i64
  %4 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result), !insn.addr !891
  %5 = icmp eq i64 %4, %3, !insn.addr !892
  %6 = icmp eq i1 %5, false, !insn.addr !893
  br i1 %6, label %dec_label_pc_2cc0, label %dec_label_pc_2cb2, !insn.addr !893

dec_label_pc_2cb2:                                ; preds = %dec_label_pc_2ca0
  %7 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !894
  store i64 %7, i64* %storemerge.reg2mem, !insn.addr !895
  br label %dec_label_pc_2cc8, !insn.addr !895

dec_label_pc_2cc0:                                ; preds = %dec_label_pc_2ca0
  %8 = add i64 %3, 88, !insn.addr !896
  store i64 %8, i64* %storemerge.reg2mem, !insn.addr !896
  br label %dec_label_pc_2cc8, !insn.addr !896

dec_label_pc_2cc8:                                ; preds = %dec_label_pc_2cc0, %dec_label_pc_2cb2
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %9 = inttoptr i64 %storemerge.reload to i64*, !insn.addr !897
  %10 = call i64 @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEC1EPS8_SA_RKNS_14DebugEpochBaseEb(i64* nonnull %stack_var_-40, i64* %9, i64* %arg3, i64* %arg4, i1 %arg5), !insn.addr !897
  br label %dec_label_pc_2d1c, !insn.addr !898

dec_label_pc_2cf5:                                ; preds = %dec_label_pc_2c6a
  %11 = call i64 @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEC1EPS8_SA_RKNS_14DebugEpochBaseEb(i64* nonnull %stack_var_-40, i64* %arg2, i64* %arg3, i64* %arg4, i1 %arg5), !insn.addr !899
  br label %dec_label_pc_2d1c, !insn.addr !900

dec_label_pc_2d1c:                                ; preds = %dec_label_pc_2cf5, %dec_label_pc_2cc8
  %storemerge2 = load i64, i64* %stack_var_-40, align 8
  %12 = call i64 @__readfsqword(i64 40), !insn.addr !901
  %13 = icmp eq i64 %0, %12, !insn.addr !901
  store i64 %storemerge2, i64* %rax.0.reg2mem, !insn.addr !902
  br i1 %13, label %dec_label_pc_2d30, label %dec_label_pc_2d2b, !insn.addr !902

dec_label_pc_2d2b:                                ; preds = %dec_label_pc_2d1c
  %14 = call i64 @__stack_chk_fail(), !insn.addr !903
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !903
  br label %dec_label_pc_2d30, !insn.addr !903

dec_label_pc_2d30:                                ; preds = %dec_label_pc_2d2b, %dec_label_pc_2d1c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !904

; uselistorder directives
  uselistorder i64 %3, { 1, 0 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*, i64*, i64*, i64*, i1)* @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEC1EPS8_SA_RKNS_14DebugEpochBaseEb, { 1, 0 }
  uselistorder i1 %arg5, { 1, 0 }
}

define i1 @_ZN4llvm20shouldReverseIterateIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEEbv() local_unnamed_addr {
dec_label_pc_2d32:
  ret i1 false, !insn.addr !905
}

define i1 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15LookupBucketForIS4_EEbRKT_RPS9_(i64* %result, i64* %arg2, i64** %arg3) local_unnamed_addr {
dec_label_pc_2d42:
  %rax.0.reg2mem = alloca i64, !insn.addr !906
  %rbx.0.reg2mem = alloca i64, !insn.addr !906
  %storemerge.reg2mem = alloca i64, !insn.addr !906
  %stack_var_-208.08.reg2mem = alloca i64, !insn.addr !906
  %stack_var_-220.09.reg2mem = alloca i32, !insn.addr !906
  %stack_var_-216.010.reg2mem = alloca i32, !insn.addr !906
  %.reg2mem23 = alloca i64, !insn.addr !906
  %.reg2mem = alloca i64*, !insn.addr !906
  %.lcssa.reg2mem = alloca i64, !insn.addr !906
  %stack_var_-104 = alloca i64, align 8
  %stack_var_-184 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !907
  %1 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !908
  %2 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !909
  %3 = trunc i64 %2 to i32, !insn.addr !910
  %4 = icmp eq i32 %3, 0, !insn.addr !911
  %5 = icmp eq i1 %4, false, !insn.addr !912
  br i1 %5, label %dec_label_pc_2dbe, label %dec_label_pc_2da6, !insn.addr !912

dec_label_pc_2da6:                                ; preds = %dec_label_pc_2d42
  %6 = bitcast i64** %arg3 to i64*
  store i64 0, i64* %6, align 8, !insn.addr !913
  store i64 0, i64* %rbx.0.reg2mem, !insn.addr !914
  br label %dec_label_pc_2fda, !insn.addr !914

dec_label_pc_2dbe:                                ; preds = %dec_label_pc_2d42
  %7 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* nonnull %stack_var_-184), !insn.addr !915
  %8 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15getTombstoneKeyEv(i64* nonnull %stack_var_-104), !insn.addr !916
  %9 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %arg2, i64* nonnull %stack_var_-184), !insn.addr !917
  %10 = trunc i64 %9 to i8
  %11 = icmp eq i8 %10, 1, !insn.addr !918
  br i1 %11, label %dec_label_pc_2e21, label %dec_label_pc_2e04, !insn.addr !919

dec_label_pc_2e04:                                ; preds = %dec_label_pc_2dbe
  %12 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %arg2, i64* nonnull %stack_var_-104), !insn.addr !920
  %13 = trunc i64 %12 to i8
  %14 = icmp eq i8 %13, 1, !insn.addr !921
  %15 = icmp eq i1 %14, false, !insn.addr !922
  br i1 %15, label %dec_label_pc_2e49, label %dec_label_pc_2e21, !insn.addr !922

dec_label_pc_2e21:                                ; preds = %dec_label_pc_2e04, %dec_label_pc_2dbe
  %16 = call i64 @__assert_fail(i64 ptrtoint ([134 x i8]* @global_var_6a6c to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 696, i64 ptrtoint ([659 x i8]* @global_var_67d4 to i64)), !insn.addr !923
  br label %dec_label_pc_2e49, !insn.addr !923

dec_label_pc_2e49:                                ; preds = %dec_label_pc_2e21, %dec_label_pc_2e04
  %17 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12getHashValueERKS4_(i64* %arg2), !insn.addr !924
  %18 = add i32 %3, -1, !insn.addr !925
  %19 = trunc i64 %17 to i32, !insn.addr !926
  %20 = and i32 %18, %19, !insn.addr !926
  %21 = zext i32 %20 to i64, !insn.addr !927
  %22 = mul nuw nsw i64 %21, 88, !insn.addr !928
  %23 = add i64 %22, %1, !insn.addr !929
  %24 = inttoptr i64 %23 to i64*, !insn.addr !930
  %25 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %24), !insn.addr !930
  %26 = inttoptr i64 %25 to i64*, !insn.addr !931
  %27 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %arg2, i64* %26), !insn.addr !931
  %28 = urem i64 %27, 256, !insn.addr !932
  %29 = icmp eq i64 %28, 0, !insn.addr !933
  %30 = icmp eq i1 %29, false, !insn.addr !934
  %31 = icmp eq i1 %30, false, !insn.addr !935
  store i64 %23, i64* %.lcssa.reg2mem, !insn.addr !936
  store i64* %24, i64** %.reg2mem, !insn.addr !936
  store i64 %23, i64* %.reg2mem23, !insn.addr !936
  store i32 1, i32* %stack_var_-216.010.reg2mem, !insn.addr !936
  store i32 %20, i32* %stack_var_-220.09.reg2mem, !insn.addr !936
  store i64 0, i64* %stack_var_-208.08.reg2mem, !insn.addr !936
  br i1 %31, label %dec_label_pc_2eed, label %dec_label_pc_2ed2, !insn.addr !936

dec_label_pc_2ed2:                                ; preds = %dec_label_pc_2f49, %dec_label_pc_2e49
  %.lcssa.reload = load i64, i64* %.lcssa.reg2mem
  %32 = bitcast i64** %arg3 to i64*
  store i64 %.lcssa.reload, i64* %32, align 8, !insn.addr !937
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !938
  br label %dec_label_pc_2fbf, !insn.addr !938

dec_label_pc_2eed:                                ; preds = %dec_label_pc_2e49, %dec_label_pc_2f49
  %stack_var_-208.08.reload = load i64, i64* %stack_var_-208.08.reg2mem
  %.reload24 = load i64, i64* %.reg2mem23
  %.reload = load i64*, i64** %.reg2mem
  %33 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %.reload), !insn.addr !939
  %34 = inttoptr i64 %33 to i64*, !insn.addr !940
  %35 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %34, i64* nonnull %stack_var_-184), !insn.addr !940
  %36 = urem i64 %35, 256, !insn.addr !941
  %37 = icmp eq i64 %36, 0, !insn.addr !942
  %38 = icmp eq i1 %37, false, !insn.addr !943
  %39 = icmp eq i1 %38, false, !insn.addr !944
  br i1 %39, label %dec_label_pc_2f49, label %dec_label_pc_2f1e, !insn.addr !945

dec_label_pc_2f1e:                                ; preds = %dec_label_pc_2eed
  %40 = icmp eq i64 %stack_var_-208.08.reload, 0, !insn.addr !946
  %storemerge2 = select i1 %40, i64 %.reload24, i64 %stack_var_-208.08.reload
  %41 = bitcast i64** %arg3 to i64*
  store i64 %storemerge2, i64* %41, align 8, !insn.addr !947
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !948
  br label %dec_label_pc_2fbf, !insn.addr !948

dec_label_pc_2f49:                                ; preds = %dec_label_pc_2eed
  %stack_var_-220.09.reload = load i32, i32* %stack_var_-220.09.reg2mem
  %stack_var_-216.010.reload = load i32, i32* %stack_var_-216.010.reg2mem
  %42 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %.reload), !insn.addr !949
  %43 = inttoptr i64 %42 to i64*, !insn.addr !950
  %44 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %43, i64* nonnull %stack_var_-104), !insn.addr !950
  %45 = trunc i64 %44 to i8, !insn.addr !951
  %46 = icmp eq i8 %45, 0, !insn.addr !951
  %47 = icmp eq i64 %stack_var_-208.08.reload, 0, !insn.addr !952
  %48 = icmp eq i1 %47, false, !insn.addr !953
  %or.cond = or i1 %48, %46
  %spec.select = select i1 %or.cond, i64 %stack_var_-208.08.reload, i64 %.reload24
  %49 = add i32 %stack_var_-216.010.reload, 1, !insn.addr !954
  %50 = add i32 %stack_var_-220.09.reload, %stack_var_-216.010.reload, !insn.addr !955
  %51 = and i32 %50, %18, !insn.addr !956
  %52 = zext i32 %51 to i64, !insn.addr !927
  %53 = mul nuw nsw i64 %52, 88, !insn.addr !928
  %54 = add i64 %53, %1, !insn.addr !929
  %55 = inttoptr i64 %54 to i64*, !insn.addr !930
  %56 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %55), !insn.addr !930
  %57 = inttoptr i64 %56 to i64*, !insn.addr !931
  %58 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %arg2, i64* %57), !insn.addr !931
  %59 = urem i64 %58, 256, !insn.addr !932
  %60 = icmp eq i64 %59, 0, !insn.addr !933
  %61 = icmp eq i1 %60, false, !insn.addr !934
  %62 = icmp eq i1 %61, false, !insn.addr !935
  store i64 %54, i64* %.lcssa.reg2mem, !insn.addr !936
  store i64* %55, i64** %.reg2mem, !insn.addr !936
  store i64 %54, i64* %.reg2mem23, !insn.addr !936
  store i32 %49, i32* %stack_var_-216.010.reg2mem, !insn.addr !936
  store i32 %51, i32* %stack_var_-220.09.reg2mem, !insn.addr !936
  store i64 %spec.select, i64* %stack_var_-208.08.reg2mem, !insn.addr !936
  br i1 %62, label %dec_label_pc_2eed, label %dec_label_pc_2ed2, !insn.addr !936

dec_label_pc_2fbf:                                ; preds = %dec_label_pc_2f1e, %dec_label_pc_2ed2
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %63 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-104), !insn.addr !957
  %64 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-184), !insn.addr !958
  store i64 %storemerge.reload, i64* %rbx.0.reg2mem, !insn.addr !958
  br label %dec_label_pc_2fda, !insn.addr !958

dec_label_pc_2fda:                                ; preds = %dec_label_pc_2fbf, %dec_label_pc_2da6
  %rbx.0.reload = load i64, i64* %rbx.0.reg2mem
  %65 = and i64 %rbx.0.reload, 4294967295, !insn.addr !959
  %66 = call i64 @__readfsqword(i64 40), !insn.addr !960
  %67 = icmp eq i64 %0, %66, !insn.addr !960
  store i64 %65, i64* %rax.0.reg2mem, !insn.addr !961
  br i1 %67, label %dec_label_pc_2ff0, label %dec_label_pc_2feb, !insn.addr !961

dec_label_pc_2feb:                                ; preds = %dec_label_pc_2fda
  %68 = call i64 @__stack_chk_fail(), !insn.addr !962
  store i64 %68, i64* %rax.0.reg2mem, !insn.addr !962
  br label %dec_label_pc_2ff0, !insn.addr !962

dec_label_pc_2ff0:                                ; preds = %dec_label_pc_2feb, %dec_label_pc_2fda
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %69 = urem i64 %rax.0.reload, 2
  %70 = icmp ne i64 %69, 0, !insn.addr !963
  ret i1 %70, !insn.addr !963

; uselistorder directives
  uselistorder i32 %stack_var_-216.010.reload, { 1, 0 }
  uselistorder i32 %18, { 1, 0 }
  uselistorder i64* %.lcssa.reg2mem, { 1, 0, 2 }
  uselistorder i64** %.reg2mem, { 2, 0, 1 }
  uselistorder i64* %.reg2mem23, { 2, 0, 1 }
  uselistorder i32* %stack_var_-216.010.reg2mem, { 2, 0, 1 }
  uselistorder i32* %stack_var_-220.09.reg2mem, { 2, 0, 1 }
  uselistorder i64* %stack_var_-208.08.reg2mem, { 2, 0, 1 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %rbx.0.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12getHashValueERKS4_, { 1, 0 }
  uselistorder i64** %arg3, { 2, 1, 0 }
  uselistorder i64* %arg2, { 1, 0, 2, 3, 4 }
  uselistorder label %dec_label_pc_2eed, { 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_19LastStoreC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_2ff6:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !964
  %1 = add i64 %0, 8, !insn.addr !965
  %2 = inttoptr i64 %1 to i64*, !insn.addr !965
  store i64 0, i64* %2, align 8, !insn.addr !965
  ret i64 %0, !insn.addr !966

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16InsertIntoBucketIRKS4_JEEEPS9_SF_OT_DpOT0_(i64* %arg1, i64** %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_3018:
  %0 = inttoptr i64 %arg3 to i64*, !insn.addr !967
  %1 = bitcast i64** %arg2 to i64*, !insn.addr !967
  %2 = call i64* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E20InsertIntoBucketImplIS4_EEPS9_RKT_SD_(i64* %arg1, i64* %0, i64* %1), !insn.addr !967
  %3 = call i64** @_ZSt7forwardIRKN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %0), !insn.addr !968
  %4 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %2), !insn.addr !969
  %5 = inttoptr i64 %4 to i64*, !insn.addr !970
  %6 = bitcast i64** %3 to i64*, !insn.addr !970
  %7 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyaSERKS1_(i64* %5, i64* %6), !insn.addr !970
  %8 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE9getSecondEv(i64* %2), !insn.addr !971
  %9 = inttoptr i64 %8 to i64*, !insn.addr !972
  %10 = call i64 @_ZnwmPv(i64 16, i64* %9), !insn.addr !972
  %11 = inttoptr i64 %10 to i64*, !insn.addr !973
  store i64 0, i64* %11, align 8, !insn.addr !973
  %12 = add i64 %10, 8, !insn.addr !974
  %13 = inttoptr i64 %12 to i64*, !insn.addr !974
  store i64 0, i64* %13, align 8, !insn.addr !974
  %14 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_19LastStoreC1Ev(i64* %11), !insn.addr !975
  ret i64* %2, !insn.addr !976

; uselistorder directives
  uselistorder i64 %10, { 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyaSERKS1_, { 1, 0 }
}

define i64* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_30a8:
  ret i64* %arg1, !insn.addr !977
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEEC1ES5_(i64 %arg1) local_unnamed_addr {
dec_label_pc_30b6:
  %stack_var_-17 = alloca i64, align 8
  %0 = inttoptr i64 %arg1 to i64*, !insn.addr !978
  %1 = call i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEEC1Ev(i64* %0), !insn.addr !978
  store i64 ptrtoint (i64* @global_var_b2a4 to i64), i64* %0, align 8, !insn.addr !979
  %2 = bitcast i64* %stack_var_-17 to i64**, !insn.addr !980
  %3 = call i64* @_ZSt4moveIRN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEEONSt16remove_referenceIT_E4typeEOS5_(i64** nonnull %2), !insn.addr !980
  %4 = ptrtoint i64* %3 to i64, !insn.addr !980
  ret i64 %4, !insn.addr !981
}

define i1 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E21_M_not_empty_functionISF_EEbRKT_(i64* %arg1) local_unnamed_addr {
dec_label_pc_30eb:
  ret i1 true, !insn.addr !982
}

define i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_30fa:
  ret i64* %arg1, !insn.addr !983
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorISF_EEvRSt9_Any_dataOT_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_3108:
  %0 = call i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg2), !insn.addr !984
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createISF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64* %0, i64 ptrtoint (i32* @0 to i64)), !insn.addr !985
  ret void, !insn.addr !986
}

define i64 @_ZNSt17_Function_handlerIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEZZ21llvmGetPassPluginInfoENKUlRS9_E_clESD_EUlS1_S7_SB_E_E9_M_invokeERKSt9_Any_dataOS1_S7_OSB_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_3139:
  %0 = call i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %arg4), !insn.addr !987
  %1 = ptrtoint i64* %0 to i64, !insn.addr !987
  %2 = call i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %arg3), !insn.addr !988
  %3 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %arg2), !insn.addr !989
  %4 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg1), !insn.addr !990
  %5 = inttoptr i64 %4 to i64*, !insn.addr !991
  %6 = call i64 @_ZSt10__invoke_rIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EENSt9enable_ifIX16is_invocable_r_vIT_T0_DpT1_EESH_E4typeEOSI_DpOSJ_(i64* %5, i64* %3, i64** %2, i64 %1), !insn.addr !991
  ret i64 %6, !insn.addr !992
}

define i64 @_ZNSt17_Function_handlerIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEZZ21llvmGetPassPluginInfoENKUlRS9_E_clESD_EUlS1_S7_SB_E_E10_M_managerERSt9_Any_dataRKSH_St18_Manager_operation(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_31af:
  %0 = trunc i64 %arg3 to i32, !insn.addr !993
  switch i32 %0, label %dec_label_pc_320d [
    i32 0, label %dec_label_pc_31d5
    i32 1, label %dec_label_pc_31ed
  ]

dec_label_pc_31d5:                                ; preds = %dec_label_pc_31af
  %1 = call i64** @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v(i64* %arg1), !insn.addr !994
  %2 = bitcast i64** %1 to i64*, !insn.addr !995
  store i64 ptrtoint (i64* @global_var_11224 to i64), i64* %2, align 8, !insn.addr !995
  br label %dec_label_pc_3223, !insn.addr !996

dec_label_pc_31ed:                                ; preds = %dec_label_pc_31af
  %3 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg2), !insn.addr !997
  %4 = call i64** @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %arg1), !insn.addr !998
  %5 = bitcast i64** %4 to i64*, !insn.addr !999
  store i64 %3, i64* %5, align 8, !insn.addr !999
  br label %dec_label_pc_3223, !insn.addr !1000

dec_label_pc_320d:                                ; preds = %dec_label_pc_31af
  %6 = and i64 %arg3, 4294967295
  %7 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_managerERSt9_Any_dataRKSH_St18_Manager_operation(i64* %arg1, i64* %arg2, i64 %6), !insn.addr !1001
  br label %dec_label_pc_3223, !insn.addr !1001

dec_label_pc_3223:                                ; preds = %dec_label_pc_320d, %dec_label_pc_31ed, %dec_label_pc_31d5
  ret i64 0, !insn.addr !1002

; uselistorder directives
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder i64* %arg1, { 2, 1, 0 }
}

define i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagEC2ES6_S6_SA_(i64 %arg1, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_322e:
  %0 = inttoptr i64 %arg1 to i64*, !insn.addr !1003
  %1 = call i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EC2ES7_(i64* %0, i64 %arg2), !insn.addr !1003
  %2 = add i64 %arg1, 8, !insn.addr !1004
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1004
  store i64 %arg3, i64* %3, align 8, !insn.addr !1004
  %4 = call i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagE13findNextValidEv(i64* %0), !insn.addr !1005
  ret i64 %4, !insn.addr !1006
}

define i64 @_ZN4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEC1ESC_SC_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_3270:
  %stack_var_32 = alloca i64, align 8
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !1007
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !1007
  %2 = ptrtoint i64* %1 to i64, !insn.addr !1007
  %3 = load i64, i64* %1, align 8, !insn.addr !1008
  %4 = add i64 %2, 8, !insn.addr !1009
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1009
  %6 = load i64, i64* %5, align 8, !insn.addr !1009
  %7 = inttoptr i64 %arg1 to i64*, !insn.addr !1010
  store i64 %3, i64* %7, align 8, !insn.addr !1010
  %8 = add i64 %arg1, 8, !insn.addr !1011
  %9 = inttoptr i64 %8 to i64*, !insn.addr !1011
  store i64 %6, i64* %9, align 8, !insn.addr !1011
  %10 = add i64 %2, 16, !insn.addr !1012
  %11 = inttoptr i64 %10 to i64*, !insn.addr !1012
  %12 = load i64, i64* %11, align 8, !insn.addr !1012
  %13 = add i64 %arg1, 16, !insn.addr !1013
  %14 = inttoptr i64 %13 to i64*, !insn.addr !1013
  store i64 %12, i64* %14, align 8, !insn.addr !1013
  %15 = bitcast i64* %stack_var_32 to i64**, !insn.addr !1014
  %16 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %15), !insn.addr !1014
  %17 = ptrtoint i64* %16 to i64, !insn.addr !1014
  %18 = load i64, i64* %16, align 8, !insn.addr !1015
  %19 = add i64 %17, 8, !insn.addr !1016
  %20 = inttoptr i64 %19 to i64*, !insn.addr !1016
  %21 = load i64, i64* %20, align 8, !insn.addr !1016
  %22 = add i64 %arg1, 24, !insn.addr !1017
  %23 = inttoptr i64 %22 to i64*, !insn.addr !1017
  store i64 %18, i64* %23, align 8, !insn.addr !1017
  %24 = add i64 %arg1, 32, !insn.addr !1018
  %25 = inttoptr i64 %24 to i64*, !insn.addr !1018
  store i64 %21, i64* %25, align 8, !insn.addr !1018
  %26 = add i64 %17, 16, !insn.addr !1019
  %27 = inttoptr i64 %26 to i64*, !insn.addr !1019
  %28 = load i64, i64* %27, align 8, !insn.addr !1019
  %29 = add i64 %arg1, 40, !insn.addr !1020
  %30 = inttoptr i64 %29 to i64*, !insn.addr !1020
  store i64 %28, i64* %30, align 8, !insn.addr !1020
  ret i64 %28, !insn.addr !1021

; uselistorder directives
  uselistorder i64 %28, { 1, 0 }
  uselistorder i64 %17, { 1, 0 }
  uselistorder i64 %2, { 1, 0 }
}

define i64 @_ZN4llvm21iterator_adaptor_baseINS_15mapped_iteratorINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS8_EEEUlRS6_E_St26bidirectional_iterator_tagEEZNS_L13filterDbgVarsESA_EUlSB_E0_St17reference_wrapperINS_17DbgVariableRecordEEEESE_SD_SI_lPSI_SI_EC2ESE_(i64 %arg1) local_unnamed_addr {
dec_label_pc_32d0:
  %stack_var_8 = alloca i64, align 8
  %0 = bitcast i64* %stack_var_8 to i64**, !insn.addr !1022
  %1 = call i64* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_(i64** nonnull %0), !insn.addr !1022
  %2 = ptrtoint i64* %1 to i64, !insn.addr !1022
  %3 = load i64, i64* %1, align 8, !insn.addr !1023
  %4 = add i64 %2, 8, !insn.addr !1024
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1024
  %6 = load i64, i64* %5, align 8, !insn.addr !1024
  %7 = inttoptr i64 %arg1 to i64*, !insn.addr !1025
  store i64 %3, i64* %7, align 8, !insn.addr !1025
  %8 = add i64 %arg1, 8, !insn.addr !1026
  %9 = inttoptr i64 %8 to i64*, !insn.addr !1026
  store i64 %6, i64* %9, align 8, !insn.addr !1026
  %10 = add i64 %2, 16, !insn.addr !1027
  %11 = inttoptr i64 %10 to i64*, !insn.addr !1027
  %12 = load i64, i64* %11, align 8, !insn.addr !1027
  %13 = add i64 %arg1, 16, !insn.addr !1028
  %14 = inttoptr i64 %13 to i64*, !insn.addr !1028
  store i64 %12, i64* %14, align 8, !insn.addr !1028
  ret i64 %12, !insn.addr !1029

; uselistorder directives
  uselistorder i64 %12, { 1, 0 }
  uselistorder i64 %2, { 1, 0 }
  uselistorder i64* (i64**)* @_ZSt4moveIRN4llvm20filter_iterator_implINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS0_L13filterDbgVarsENS0_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEEONSt16remove_referenceIT_E4typeEOSG_, { 2, 6, 5, 1, 4, 3, 0 }
}

define i64 @_ZN4llvm15callable_detail8CallableIZNS_L13filterDbgVarsENS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS6_E0_Lb0EEC1ERKSB_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3306:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt8optionalIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC1IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %1, i64 %0), !insn.addr !1030
  ret i64 %2, !insn.addr !1031
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE10_M_destroyEv(i64* %result) local_unnamed_addr {
dec_label_pc_332c:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 72, !insn.addr !1032
  %2 = inttoptr i64 %1 to i8*, !insn.addr !1032
  store i8 0, i8* %2, align 1, !insn.addr !1032
  %3 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* %result), !insn.addr !1033
  ret i64 %3, !insn.addr !1034
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEC2IJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_3350:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !1035
  %1 = call i64* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %0), !insn.addr !1035
  %2 = ptrtoint i64* %1 to i64, !insn.addr !1035
  %3 = call i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_StorageIS2_Lb0EEC1IJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !1036
  %4 = add i64 %arg1, 72, !insn.addr !1037
  %5 = inttoptr i64 %4 to i8*, !insn.addr !1037
  store i8 1, i8* %5, align 1, !insn.addr !1037
  ret i64 %arg1, !insn.addr !1038

; uselistorder directives
  uselistorder i64 %arg1, { 1, 0, 2 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E31getMinBucketToReserveForEntriesEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_338c:
  %storemerge.reg2mem = alloca i64, !insn.addr !1039
  %0 = icmp eq i32 %arg2, 0, !insn.addr !1040
  %1 = icmp eq i1 %0, false, !insn.addr !1041
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1041
  br i1 %1, label %dec_label_pc_33a8, label %dec_label_pc_33cc, !insn.addr !1041

dec_label_pc_33a8:                                ; preds = %dec_label_pc_338c
  %2 = mul i32 %arg2, 4, !insn.addr !1042
  %3 = zext i32 %2 to i64, !insn.addr !1043
  %4 = mul nuw i64 %3, 2863311531, !insn.addr !1043
  %5 = udiv i64 %4, 8589934592, !insn.addr !1044
  %6 = add nuw nsw i64 %5, 1, !insn.addr !1045
  %7 = call i64 @_ZN4llvm12NextPowerOf2Em(i64 %6), !insn.addr !1046
  store i64 %7, i64* %storemerge.reg2mem, !insn.addr !1046
  br label %dec_label_pc_33cc, !insn.addr !1046

dec_label_pc_33cc:                                ; preds = %dec_label_pc_338c, %dec_label_pc_33a8
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1047

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_33cc, { 1, 0 }
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE15allocateBucketsEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_33ce:
  %storemerge.reg2mem = alloca i64, !insn.addr !1048
  %storemerge1.reg2mem = alloca i64, !insn.addr !1048
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !1049
  %2 = inttoptr i64 %1 to i32*, !insn.addr !1049
  store i32 %arg2, i32* %2, align 4, !insn.addr !1049
  %3 = icmp eq i32 %arg2, 0, !insn.addr !1050
  %4 = icmp eq i1 %3, false, !insn.addr !1051
  store i64 0, i64* %storemerge1.reg2mem, !insn.addr !1051
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1051
  br i1 %4, label %dec_label_pc_3404, label %dec_label_pc_343d, !insn.addr !1051

dec_label_pc_3404:                                ; preds = %dec_label_pc_33ce
  %5 = zext i32 %arg2 to i64, !insn.addr !1052
  %6 = mul nuw nsw i64 %5, 88, !insn.addr !1053
  %7 = inttoptr i64 %6 to i64*, !insn.addr !1054
  %8 = call i64 @_ZN4llvm15allocate_bufferEmm(i64* %7, i64 8, i64 %5), !insn.addr !1054
  store i64 %8, i64* %storemerge1.reg2mem, !insn.addr !1055
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !1055
  br label %dec_label_pc_343d, !insn.addr !1055

dec_label_pc_343d:                                ; preds = %dec_label_pc_33ce, %dec_label_pc_3404
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %storemerge1.reload = load i64, i64* %storemerge1.reg2mem
  store i64 %storemerge1.reload, i64* %result, align 8
  ret i64 %storemerge.reload, !insn.addr !1056

; uselistorder directives
  uselistorder i64 %5, { 1, 0 }
  uselistorder i64* %storemerge1.reg2mem, { 0, 2, 1 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_343d, { 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyC1ERKS1_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3440:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1ERKS4_(i64* %result, i64* %arg2), !insn.addr !1057
  %3 = add i64 %1, 32, !insn.addr !1058
  %4 = add i64 %0, 32, !insn.addr !1059
  %5 = inttoptr i64 %3 to i64*, !insn.addr !1060
  %6 = inttoptr i64 %4 to i64*, !insn.addr !1060
  %7 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1ERKS4_(i64* %5, i64* %6), !insn.addr !1060
  %8 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !1061
  %9 = inttoptr i64 %8 to i64*, !insn.addr !1061
  %10 = load i64, i64* %9, align 8, !insn.addr !1061
  %11 = add i64 %1, ptrtoint (i128** @global_var_40 to i64), !insn.addr !1062
  %12 = inttoptr i64 %11 to i64*, !insn.addr !1062
  store i64 %10, i64* %12, align 8, !insn.addr !1062
  ret i64 %1, !insn.addr !1063

; uselistorder directives
  uselistorder i64 %1, { 1, 0, 2 }
  uselistorder i64 (i64*, i64*)* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1ERKS4_, { 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E9initEmptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_3492:
  %rax.0.reg2mem = alloca i64, !insn.addr !1064
  %stack_var_-120.01.reg2mem = alloca i64, !insn.addr !1064
  %stack_var_-104 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1065
  %1 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13setNumEntriesEj(i64* %result, i32 0), !insn.addr !1066
  %2 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16setNumTombstonesEj(i64* %result, i32 0), !insn.addr !1067
  %3 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !1068
  %4 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !1069
  %5 = add i64 %4, 4294967295, !insn.addr !1070
  %6 = and i64 %5, %3, !insn.addr !1071
  %7 = trunc i64 %6 to i32, !insn.addr !1072
  %8 = icmp eq i32 %7, 0, !insn.addr !1072
  br i1 %8, label %dec_label_pc_351b, label %dec_label_pc_34f3, !insn.addr !1073

dec_label_pc_34f3:                                ; preds = %dec_label_pc_3492
  %9 = call i64 @__assert_fail(i64 ptrtoint ([94 x i8]* @global_var_6d34 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 439, i64 ptrtoint ([565 x i8]* @global_var_6afc to i64)), !insn.addr !1074
  br label %dec_label_pc_351b, !insn.addr !1074

dec_label_pc_351b:                                ; preds = %dec_label_pc_34f3, %dec_label_pc_3492
  %10 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* nonnull %stack_var_-104), !insn.addr !1075
  %11 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv(i64* %result), !insn.addr !1076
  %12 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv(i64* %result), !insn.addr !1077
  %13 = icmp eq i64 %11, %12, !insn.addr !1078
  %14 = icmp eq i1 %13, false, !insn.addr !1079
  store i64 %11, i64* %stack_var_-120.01.reg2mem, !insn.addr !1079
  br i1 %14, label %dec_label_pc_3549, label %dec_label_pc_3583, !insn.addr !1079

dec_label_pc_3549:                                ; preds = %dec_label_pc_351b, %dec_label_pc_3549
  %stack_var_-120.01.reload = load i64, i64* %stack_var_-120.01.reg2mem
  %15 = inttoptr i64 %stack_var_-120.01.reload to i64*, !insn.addr !1080
  %16 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %15), !insn.addr !1080
  %17 = inttoptr i64 %16 to i64*, !insn.addr !1081
  %18 = call i64 @_ZnwmPv(i64 72, i64* %17), !insn.addr !1081
  %19 = inttoptr i64 %18 to i64*, !insn.addr !1082
  %20 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyC1ERKS1_(i64* %19, i64* nonnull %stack_var_-104), !insn.addr !1082
  %21 = add i64 %stack_var_-120.01.reload, 88, !insn.addr !1083
  %22 = icmp eq i64 %21, %12, !insn.addr !1078
  %23 = icmp eq i1 %22, false, !insn.addr !1079
  store i64 %21, i64* %stack_var_-120.01.reg2mem, !insn.addr !1079
  br i1 %23, label %dec_label_pc_3549, label %dec_label_pc_3583, !insn.addr !1079

dec_label_pc_3583:                                ; preds = %dec_label_pc_3549, %dec_label_pc_351b
  %24 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-104), !insn.addr !1084
  %25 = call i64 @__readfsqword(i64 40), !insn.addr !1085
  %26 = icmp eq i64 %0, %25, !insn.addr !1085
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1086
  br i1 %26, label %dec_label_pc_35a3, label %dec_label_pc_359e, !insn.addr !1086

dec_label_pc_359e:                                ; preds = %dec_label_pc_3583
  %27 = call i64 @__stack_chk_fail(), !insn.addr !1087
  store i64 %27, i64* %rax.0.reg2mem, !insn.addr !1087
  br label %dec_label_pc_35a3, !insn.addr !1087

dec_label_pc_35a3:                                ; preds = %dec_label_pc_359e, %dec_label_pc_3583
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1088

; uselistorder directives
  uselistorder i64 %12, { 1, 0 }
  uselistorder i64* %stack_var_-120.01.reg2mem, { 2, 0, 1 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getBucketsEndEv, { 6, 5, 4, 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10getBucketsEv, { 7, 6, 5, 4, 3, 2, 1, 0 }
  uselistorder label %dec_label_pc_3549, { 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15getTombstoneKeyEv(i64* %result) local_unnamed_addr {
dec_label_pc_35a9:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1089
  %1 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo15getTombstoneKeyEv(i64* %result), !insn.addr !1090
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !1091
  %3 = icmp eq i64 %0, %2, !insn.addr !1091
  br i1 %3, label %dec_label_pc_35e4, label %dec_label_pc_35df, !insn.addr !1092

dec_label_pc_35df:                                ; preds = %dec_label_pc_35a9
  %4 = call i64 @__stack_chk_fail(), !insn.addr !1093
  br label %dec_label_pc_35e4, !insn.addr !1093

dec_label_pc_35e4:                                ; preds = %dec_label_pc_35df, %dec_label_pc_35a9
  %5 = ptrtoint i64* %result to i64
  ret i64 %5, !insn.addr !1094

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE9getSecondEv(i64* %result) local_unnamed_addr {
dec_label_pc_35ea:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 72, !insn.addr !1095
  ret i64 %1, !insn.addr !1096
}

define i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE13getNumEntriesEv(i64* %result) local_unnamed_addr {
dec_label_pc_35fc:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !1097
  %2 = inttoptr i64 %1 to i32*, !insn.addr !1097
  %3 = load i32, i32* %2, align 4, !insn.addr !1097
  %4 = zext i32 %3 to i64, !insn.addr !1097
  ret i64 %4, !insn.addr !1098
}

define i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE16getNumTombstonesEv(i64* %result) local_unnamed_addr {
dec_label_pc_360e:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 12, !insn.addr !1099
  %2 = inttoptr i64 %1 to i32*, !insn.addr !1099
  %3 = load i32, i32* %2, align 4, !insn.addr !1099
  %4 = zext i32 %3 to i64, !insn.addr !1099
  ret i64 %4, !insn.addr !1100
}

define i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE13getNumBucketsEv(i64* %result) local_unnamed_addr {
dec_label_pc_3620:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !1101
  %2 = inttoptr i64 %1 to i32*, !insn.addr !1101
  %3 = load i32, i32* %2, align 4, !insn.addr !1101
  %4 = zext i32 %3 to i64, !insn.addr !1101
  ret i64 %4, !insn.addr !1102
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE16shrink_and_clearEv(i64* %result) local_unnamed_addr {
dec_label_pc_3632:
  %rax.0.reg2mem = alloca i64, !insn.addr !1103
  %rdi.0.reg2mem = alloca i64, !insn.addr !1103
  %stack_var_-28.0.reg2mem = alloca i32, !insn.addr !1103
  %0 = ptrtoint i64* %result to i64
  %stack_var_-36 = alloca i128*, align 8
  %stack_var_-32 = alloca i32, align 4
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1104
  %2 = add i64 %0, 16, !insn.addr !1105
  %3 = inttoptr i64 %2 to i32*, !insn.addr !1105
  %4 = load i32, i32* %3, align 4, !insn.addr !1105
  %5 = add i64 %0, 8, !insn.addr !1106
  %6 = inttoptr i64 %5 to i32*, !insn.addr !1106
  %7 = load i32, i32* %6, align 4, !insn.addr !1106
  %8 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10destroyAllEv(i64* %result), !insn.addr !1107
  %9 = icmp eq i32 %7, 0, !insn.addr !1108
  store i32 0, i32* %stack_var_-28.0.reg2mem, !insn.addr !1109
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !1109
  br i1 %9, label %dec_label_pc_36b4, label %dec_label_pc_367a, !insn.addr !1109

dec_label_pc_367a:                                ; preds = %dec_label_pc_3632
  %10 = call i64 @_ZN4llvm12Log2_32_CeilEj(i32 %7), !insn.addr !1110
  %11 = trunc i64 %10 to i32, !insn.addr !1111
  %12 = add i32 %11, 1, !insn.addr !1111
  %13 = urem i32 %12, 32, !insn.addr !1112
  %14 = shl i32 1, %13
  store i32 %14, i32* %stack_var_-32, align 4, !insn.addr !1113
  store i128* inttoptr (i32 ptrtoint (i128** @global_var_40 to i32) to i128*), i128** %stack_var_-36, align 8, !insn.addr !1114
  %15 = ptrtoint i128** %stack_var_-36 to i64, !insn.addr !1115
  %16 = bitcast i128** %stack_var_-36 to i32*, !insn.addr !1116
  %17 = call i32* @_ZSt3maxIiERKT_S2_S2_(i32* nonnull %16, i32* nonnull %stack_var_-32), !insn.addr !1116
  %18 = load i32, i32* %17, align 4, !insn.addr !1117
  store i32 %18, i32* %stack_var_-28.0.reg2mem, !insn.addr !1118
  store i64 %15, i64* %rdi.0.reg2mem, !insn.addr !1118
  br label %dec_label_pc_36b4, !insn.addr !1118

dec_label_pc_36b4:                                ; preds = %dec_label_pc_367a, %dec_label_pc_3632
  %stack_var_-28.0.reload = load i32, i32* %stack_var_-28.0.reg2mem
  %19 = load i32, i32* %3, align 4, !insn.addr !1119
  %20 = icmp eq i32 %stack_var_-28.0.reload, %19, !insn.addr !1120
  %21 = icmp eq i1 %20, false, !insn.addr !1121
  br i1 %21, label %dec_label_pc_36ce, label %dec_label_pc_36c0, !insn.addr !1121

dec_label_pc_36c0:                                ; preds = %dec_label_pc_36b4
  %22 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E9initEmptyEv(i64* %result), !insn.addr !1122
  br label %dec_label_pc_3710, !insn.addr !1123

dec_label_pc_36ce:                                ; preds = %dec_label_pc_36b4
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %23 = zext i32 %4 to i64, !insn.addr !1124
  %24 = mul nuw nsw i64 %23, 88, !insn.addr !1125
  %25 = inttoptr i64 %rdi.0.reload to i64*, !insn.addr !1126
  %26 = call i64 @_ZN4llvm17deallocate_bufferEPvmm(i64* %25, i64 %24, i64 8), !insn.addr !1126
  %27 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE4initEj(i64* %result, i32 %stack_var_-28.0.reload), !insn.addr !1127
  br label %dec_label_pc_3710, !insn.addr !1127

dec_label_pc_3710:                                ; preds = %dec_label_pc_36ce, %dec_label_pc_36c0
  %28 = call i64 @__readfsqword(i64 40), !insn.addr !1128
  %29 = icmp eq i64 %1, %28, !insn.addr !1128
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1129
  br i1 %29, label %dec_label_pc_3724, label %dec_label_pc_371f, !insn.addr !1129

dec_label_pc_371f:                                ; preds = %dec_label_pc_3710
  %30 = call i64 @__stack_chk_fail(), !insn.addr !1130
  store i64 %30, i64* %rax.0.reg2mem, !insn.addr !1130
  br label %dec_label_pc_3724, !insn.addr !1130

dec_label_pc_3724:                                ; preds = %dec_label_pc_371f, %dec_label_pc_3710
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1131

; uselistorder directives
  uselistorder i32 %stack_var_-28.0.reload, { 1, 0 }
  uselistorder i128** %stack_var_-36, { 2, 1, 0 }
  uselistorder i64 (i64*, i32)* @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE4initEj, { 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E10destroyAllEv, { 1, 0 }
}

define i64 @_ZNK4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE10getBucketsEv(i64* %result) local_unnamed_addr {
dec_label_pc_3726:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1132
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE13setNumEntriesEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_3738:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !1133
  %2 = inttoptr i64 %1 to i32*, !insn.addr !1133
  store i32 %arg2, i32* %2, align 4, !insn.addr !1133
  ret i64 %0, !insn.addr !1134

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE16setNumTombstonesEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_3750:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 12, !insn.addr !1135
  %2 = inttoptr i64 %1 to i32*, !insn.addr !1135
  store i32 %arg2, i32* %2, align 4, !insn.addr !1135
  ret i64 %0, !insn.addr !1136

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE6_M_getEv(i64* %result) local_unnamed_addr {
dec_label_pc_3768:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1137
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E12getHashValueERKS4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_3776:
  %0 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo12getHashValueERKNS0_8AliasKeyE(i64* %arg1), !insn.addr !1138
  ret i64 %0, !insn.addr !1139
}

define i64 @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EEC1EPS8_SA_RKNS_14DebugEpochBaseEb(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4, i1 %arg5) local_unnamed_addr {
dec_label_pc_3790:
  %rax.1.reg2mem = alloca i64, !insn.addr !1140
  %rax.0.reg2mem = alloca i64, !insn.addr !1140
  %0 = ptrtoint i64* %arg3 to i64
  %1 = ptrtoint i64* %arg2 to i64
  %2 = ptrtoint i64* %result to i64
  %3 = call i64 @_ZN4llvm14DebugEpochBase10HandleBaseC1EPKS0_(i64* %result, i64* %arg4), !insn.addr !1141
  store i64 %1, i64* %result, align 8, !insn.addr !1142
  %4 = add i64 %2, 8, !insn.addr !1143
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1143
  store i64 %0, i64* %5, align 8, !insn.addr !1143
  %6 = call i64 @_ZNK4llvm14DebugEpochBase10HandleBase14isHandleInSyncEv(i64* %result), !insn.addr !1144
  %7 = trunc i64 %6 to i8, !insn.addr !1145
  %8 = icmp eq i8 %7, 0, !insn.addr !1145
  %9 = icmp eq i1 %8, false, !insn.addr !1146
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !1146
  br i1 %9, label %dec_label_pc_3810, label %dec_label_pc_37e8, !insn.addr !1146

dec_label_pc_37e8:                                ; preds = %dec_label_pc_3790
  %10 = call i64 @__assert_fail(i64 ptrtoint ([44 x i8]* @global_var_6ff4 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1261, i64 ptrtoint ([602 x i8]* @global_var_6d94 to i64)), !insn.addr !1147
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !1147
  br label %dec_label_pc_3810, !insn.addr !1147

dec_label_pc_3810:                                ; preds = %dec_label_pc_37e8, %dec_label_pc_3790
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %11 = icmp eq i1 %arg5, false, !insn.addr !1148
  %12 = icmp eq i1 %11, false, !insn.addr !1149
  store i64 %rax.0.reload, i64* %rax.1.reg2mem, !insn.addr !1149
  br i1 %12, label %dec_label_pc_383c, label %dec_label_pc_3816, !insn.addr !1149

dec_label_pc_3816:                                ; preds = %dec_label_pc_3810
  %13 = call i1 @_ZN4llvm20shouldReverseIterateIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEEbv(), !insn.addr !1150
  %14 = icmp eq i1 %13, false, !insn.addr !1151
  br i1 %14, label %dec_label_pc_382d, label %dec_label_pc_381f, !insn.addr !1152

dec_label_pc_381f:                                ; preds = %dec_label_pc_3816
  %15 = call i64 @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EE23RetreatPastEmptyBucketsEv(i64* nonnull %result), !insn.addr !1153
  store i64 %15, i64* %rax.1.reg2mem, !insn.addr !1154
  br label %dec_label_pc_383c, !insn.addr !1154

dec_label_pc_382d:                                ; preds = %dec_label_pc_3816
  %16 = call i64 @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EE23AdvancePastEmptyBucketsEv(i64* nonnull %result), !insn.addr !1155
  store i64 %16, i64* %rax.1.reg2mem, !insn.addr !1156
  br label %dec_label_pc_383c, !insn.addr !1156

dec_label_pc_383c:                                ; preds = %dec_label_pc_3810, %dec_label_pc_382d, %dec_label_pc_381f
  %rax.1.reload = load i64, i64* %rax.1.reg2mem
  ret i64 %rax.1.reload, !insn.addr !1157

; uselistorder directives
  uselistorder i64* %rax.1.reg2mem, { 0, 2, 1, 3 }
  uselistorder i1 ()* @_ZN4llvm20shouldReverseIterateIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEEbv, { 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm14DebugEpochBase10HandleBase14isHandleInSyncEv, { 3, 2, 1, 0 }
  uselistorder i64* %result, { 1, 0, 2, 3, 4, 5 }
  uselistorder label %dec_label_pc_383c, { 1, 2, 0 }
}

define i64* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E20InsertIntoBucketImplIS4_EEPS9_RKT_SD_(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_383e:
  %rax.0.reg2mem = alloca i64, !insn.addr !1158
  %0 = ptrtoint i64* %arg3 to i64
  %stack_var_-104 = alloca i64, align 8
  %stack_var_-144 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-144, align 8, !insn.addr !1159
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1160
  %2 = call i64 @_ZN4llvm14DebugEpochBase14incrementEpochEv(i64* %result), !insn.addr !1161
  %3 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumEntriesEv(i64* %result), !insn.addr !1162
  %4 = trunc i64 %3 to i32, !insn.addr !1163
  %5 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !1164
  %6 = trunc i64 %5 to i32, !insn.addr !1165
  %7 = mul i32 %4, 4, !insn.addr !1163
  %8 = add i32 %7, 4, !insn.addr !1166
  %9 = mul i32 %6, 3, !insn.addr !1167
  %10 = icmp ult i32 %8, %9, !insn.addr !1167
  %11 = icmp eq i1 %10, false, !insn.addr !1168
  %12 = icmp eq i1 %11, false, !insn.addr !1169
  br i1 %12, label %dec_label_pc_38f4, label %dec_label_pc_38b5, !insn.addr !1170

dec_label_pc_38b5:                                ; preds = %dec_label_pc_383e
  %13 = mul i32 %6, 2, !insn.addr !1171
  %14 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E4growEj(i64* %result, i32 %13), !insn.addr !1172
  %15 = bitcast i64* %stack_var_-144 to i64**, !insn.addr !1173
  %16 = call i1 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15LookupBucketForIS4_EEbRKT_RPS9_(i64* %result, i64* %arg2, i64** nonnull %15), !insn.addr !1173
  %17 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv(i64* %result), !insn.addr !1174
  br label %dec_label_pc_394d, !insn.addr !1175

dec_label_pc_38f4:                                ; preds = %dec_label_pc_383e
  %18 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16getNumTombstonesEv(i64* %result), !insn.addr !1176
  %19 = trunc i64 %18 to i32, !insn.addr !1177
  %20 = sub i32 0, %4
  %21 = sub i32 %20, 1
  %.neg2 = add i32 %6, %21, !insn.addr !1177
  %22 = sub i32 %.neg2, %19, !insn.addr !1178
  %23 = udiv i32 %6, 8, !insn.addr !1179
  %24 = icmp ult i32 %23, %22, !insn.addr !1180
  %25 = icmp eq i1 %24, false, !insn.addr !1181
  %26 = icmp eq i1 %25, false, !insn.addr !1182
  %27 = icmp eq i1 %26, false, !insn.addr !1183
  %28 = icmp eq i1 %27, false, !insn.addr !1184
  br i1 %28, label %dec_label_pc_394d, label %dec_label_pc_3922, !insn.addr !1185

dec_label_pc_3922:                                ; preds = %dec_label_pc_38f4
  %29 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E4growEj(i64* %result, i32 %6), !insn.addr !1186
  %30 = bitcast i64* %stack_var_-144 to i64**, !insn.addr !1187
  %31 = call i1 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15LookupBucketForIS4_EEbRKT_RPS9_(i64* %result, i64* %arg2, i64** nonnull %30), !insn.addr !1187
  br label %dec_label_pc_394d, !insn.addr !1187

dec_label_pc_394d:                                ; preds = %dec_label_pc_3922, %dec_label_pc_38f4, %dec_label_pc_38b5
  %32 = load i64, i64* %stack_var_-144, align 8, !insn.addr !1188
  %33 = icmp eq i64 %32, 0, !insn.addr !1189
  %34 = icmp eq i1 %33, false, !insn.addr !1190
  br i1 %34, label %dec_label_pc_3981, label %dec_label_pc_3959, !insn.addr !1190

dec_label_pc_3959:                                ; preds = %dec_label_pc_394d
  %35 = call i64 @__assert_fail(i64 ptrtoint ([10 x i8]* @global_var_72bf to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 636, i64 ptrtoint ([667 x i8]* @global_var_7024 to i64)), !insn.addr !1191
  br label %dec_label_pc_3981, !insn.addr !1191

dec_label_pc_3981:                                ; preds = %dec_label_pc_3959, %dec_label_pc_394d
  %36 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E19incrementNumEntriesEv(i64* %result), !insn.addr !1192
  %37 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* nonnull %stack_var_-104), !insn.addr !1193
  %38 = load i64, i64* %stack_var_-144, align 8, !insn.addr !1194
  %39 = inttoptr i64 %38 to i64*, !insn.addr !1195
  %40 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %39), !insn.addr !1195
  %41 = inttoptr i64 %40 to i64*, !insn.addr !1196
  %42 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %41, i64* nonnull %stack_var_-104), !insn.addr !1196
  %43 = trunc i64 %42 to i8
  %44 = icmp eq i8 %43, 1, !insn.addr !1197
  br i1 %44, label %dec_label_pc_39cd, label %dec_label_pc_39c1, !insn.addr !1198

dec_label_pc_39c1:                                ; preds = %dec_label_pc_3981
  %45 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E22decrementNumTombstonesEv(i64* %result), !insn.addr !1199
  br label %dec_label_pc_39cd, !insn.addr !1199

dec_label_pc_39cd:                                ; preds = %dec_label_pc_39c1, %dec_label_pc_3981
  %46 = load i64, i64* %stack_var_-144, align 8, !insn.addr !1200
  %47 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-104), !insn.addr !1201
  %48 = call i64 @__readfsqword(i64 40), !insn.addr !1202
  %49 = icmp eq i64 %1, %48, !insn.addr !1202
  store i64 %46, i64* %rax.0.reg2mem, !insn.addr !1203
  br i1 %49, label %dec_label_pc_39f7, label %dec_label_pc_39f2, !insn.addr !1203

dec_label_pc_39f2:                                ; preds = %dec_label_pc_39cd
  %50 = call i64 @__stack_chk_fail(), !insn.addr !1204
  store i64 %50, i64* %rax.0.reg2mem, !insn.addr !1204
  br label %dec_label_pc_39f7, !insn.addr !1204

dec_label_pc_39f7:                                ; preds = %dec_label_pc_39f2, %dec_label_pc_39cd
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %51 = inttoptr i64 %rax.0.reload to i64*, !insn.addr !1205
  ret i64* %51, !insn.addr !1205

; uselistorder directives
  uselistorder i32 %6, { 3, 1, 2, 0, 4 }
  uselistorder i64* %stack_var_-144, { 2, 3, 4, 0, 1, 5 }
  uselistorder i64 (i64*, i32)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E4growEj, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumBucketsEv, { 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
  uselistorder i64* %result, { 3, 4, 0, 1, 2, 5, 6, 7, 8, 9, 10 }
}

define i64** @_ZSt7forwardIRKN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_39fd:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !1206
  ret i64** %0, !insn.addr !1206
}

define i64* @_ZSt4moveIRN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEEONSt16remove_referenceIT_E4typeEOS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_3a0b:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !1207
  ret i64* %0, !insn.addr !1207
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createISF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_3a19:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %arg1), !insn.addr !1208
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1209
  %2 = call i64 @_ZnwmPv(i64 1, i64* %1), !insn.addr !1209
  %3 = call i64* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE(i64* %arg2), !insn.addr !1210
  ret void, !insn.addr !1211

; uselistorder directives
  uselistorder i64* (i64*)* @_ZSt7forwardIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISF_E4typeE, { 2, 1, 0 }
}

define i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg1) local_unnamed_addr {
dec_label_pc_3a51:
  %0 = call i64* @_ZNKSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERKT_v(i64* %arg1), !insn.addr !1212
  %1 = call i64* @_ZSt11__addressofIKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EPT_RSG_(i64* %0), !insn.addr !1213
  %2 = ptrtoint i64* %1 to i64, !insn.addr !1213
  ret i64 %2, !insn.addr !1214
}

define i64 @_ZSt10__invoke_rIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EENSt9enable_ifIX16is_invocable_r_vIT_T0_DpT1_EESH_E4typeEOSI_DpOSJ_(i64* %this, i64* %result, i64** %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_3a7b:
  %0 = inttoptr i64 %arg4 to i64*, !insn.addr !1215
  %1 = call i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %0), !insn.addr !1215
  %2 = ptrtoint i64* %1 to i64, !insn.addr !1215
  %3 = bitcast i64** %arg3 to i64*, !insn.addr !1216
  %4 = call i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %3), !insn.addr !1216
  %5 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %result), !insn.addr !1217
  %6 = ptrtoint i64* %5 to i64, !insn.addr !1217
  %7 = call i64** @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE(i64* %this), !insn.addr !1218
  %8 = bitcast i64** %7 to i64*, !insn.addr !1219
  %9 = call i1 @_ZSt13__invoke_implIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EET_St14__invoke_otherOT0_DpOT1_(i64* %8, i64 %6, i64** %4, i64 %2), !insn.addr !1219
  %10 = sext i1 %9 to i64, !insn.addr !1219
  ret i64 %10, !insn.addr !1220
}

define i64** @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %result) local_unnamed_addr {
dec_label_pc_3aee:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !1221
  %1 = inttoptr i64 %0 to i64**, !insn.addr !1222
  ret i64** %1, !insn.addr !1222
}

define i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_managerERSt9_Any_dataRKSH_St18_Manager_operation(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_3b08:
  %0 = trunc i64 %arg3 to i32, !insn.addr !1223
  %1 = icmp eq i32 %0, 3, !insn.addr !1223
  br i1 %1, label %dec_label_pc_3b96, label %dec_label_pc_3b24, !insn.addr !1224

dec_label_pc_3b24:                                ; preds = %dec_label_pc_3b08
  %2 = icmp sgt i32 %0, 3, !insn.addr !1225
  br i1 %2, label %dec_label_pc_3ba3, label %dec_label_pc_3b29, !insn.addr !1225

dec_label_pc_3b29:                                ; preds = %dec_label_pc_3b24
  switch i32 %0, label %dec_label_pc_3ba3 [
    i32 2, label %dec_label_pc_3b76
    i32 0, label %dec_label_pc_3b3e
    i32 1, label %dec_label_pc_3b56
  ]

dec_label_pc_3b3e:                                ; preds = %dec_label_pc_3b29
  %3 = call i64** @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v(i64* %arg1), !insn.addr !1226
  %4 = bitcast i64** %3 to i64*, !insn.addr !1227
  store i64 ptrtoint (i64* @global_var_11224 to i64), i64* %4, align 8, !insn.addr !1227
  br label %dec_label_pc_3ba3, !insn.addr !1228

dec_label_pc_3b56:                                ; preds = %dec_label_pc_3b29
  %5 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg2), !insn.addr !1229
  %6 = call i64** @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %arg1), !insn.addr !1230
  %7 = bitcast i64** %6 to i64*, !insn.addr !1231
  store i64 %5, i64* %7, align 8, !insn.addr !1231
  br label %dec_label_pc_3ba3, !insn.addr !1232

dec_label_pc_3b76:                                ; preds = %dec_label_pc_3b29
  %8 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data(i64* %arg2), !insn.addr !1233
  %9 = inttoptr i64 %8 to i64**, !insn.addr !1234
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorIRKSF_EEvRSt9_Any_dataOT_(i64* %arg1, i64** %9), !insn.addr !1234
  br label %dec_label_pc_3ba3, !insn.addr !1235

dec_label_pc_3b96:                                ; preds = %dec_label_pc_3b08
  %10 = call i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_destroyERSt9_Any_dataSt17integral_constantIbLb1EE(i64* %arg1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !1236
  br label %dec_label_pc_3ba3, !insn.addr !1237

dec_label_pc_3ba3:                                ; preds = %dec_label_pc_3b29, %dec_label_pc_3b96, %dec_label_pc_3b76, %dec_label_pc_3b56, %dec_label_pc_3b3e, %dec_label_pc_3b24
  ret i64 0, !insn.addr !1238

; uselistorder directives
  uselistorder i64** (i64*)* @_ZNSt9_Any_data9_M_accessIPZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E14_M_get_pointerERKSt9_Any_data, { 3, 2, 1, 0 }
  uselistorder i64** (i64*)* @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v, { 1, 0 }
  uselistorder i64* %arg1, { 0, 1, 3, 2 }
  uselistorder label %dec_label_pc_3ba3, { 1, 2, 3, 4, 0, 5 }
}

define i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EC2ES7_(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_3bae:
  %stack_var_-24 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-24, align 8, !insn.addr !1239
  %0 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !1240
  %1 = call i64* @_ZSt4moveIRN4llvm14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEONSt16remove_referenceIT_E4typeEOS9_(i64** nonnull %0), !insn.addr !1240
  %2 = load i64, i64* %1, align 8, !insn.addr !1241
  store i64 %2, i64* %result, align 8, !insn.addr !1242
  ret i64 %2, !insn.addr !1243

; uselistorder directives
  uselistorder i64 %2, { 1, 0 }
}

define i64 @_ZN4llvm20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS6_EEEUlRS4_E_St26bidirectional_iterator_tagE13findNextValidEv(i64* %result) local_unnamed_addr {
dec_label_pc_3bd8:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16
  %2 = add i64 %0, 8, !insn.addr !1244
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1245
  %4 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %result, i64* %3), !insn.addr !1245
  %5 = trunc i64 %4 to i8, !insn.addr !1246
  %6 = icmp eq i8 %5, 0, !insn.addr !1246
  br i1 %6, label %dec_label_pc_3c44, label %dec_label_pc_3c0e, !insn.addr !1247

dec_label_pc_3be7:                                ; preds = %dec_label_pc_3c0e
  %7 = call i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EppEv(i64* %result), !insn.addr !1248
  %8 = call i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %result, i64* %3), !insn.addr !1245
  %9 = trunc i64 %8 to i8, !insn.addr !1246
  %10 = icmp eq i8 %9, 0, !insn.addr !1246
  br i1 %10, label %dec_label_pc_3c44, label %dec_label_pc_3c0e, !insn.addr !1247

dec_label_pc_3c0e:                                ; preds = %dec_label_pc_3bd8, %dec_label_pc_3be7
  %11 = call i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* %result), !insn.addr !1249
  %12 = call i64 @_GLOBAL_OFFSET_TABLE_.1(i64 %1, i64 %11), !insn.addr !1250
  %13 = trunc i64 %12 to i8
  %14 = icmp eq i8 %13, 1, !insn.addr !1251
  br i1 %14, label %dec_label_pc_3c44, label %dec_label_pc_3be7, !insn.addr !1252

dec_label_pc_3c44:                                ; preds = %dec_label_pc_3be7, %dec_label_pc_3c0e, %dec_label_pc_3bd8
  ret i64 0, !insn.addr !1253

; uselistorder directives
  uselistorder i64* %3, { 1, 0 }
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_, { 1, 0 }
  uselistorder i64* %result, { 2, 3, 1, 0, 4 }
  uselistorder label %dec_label_pc_3c44, { 1, 0, 2 }
  uselistorder label %dec_label_pc_3c0e, { 1, 0 }
}

define i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE5beginEv(i64* %this, i64* %result) local_unnamed_addr {
dec_label_pc_3c4c:
  %0 = ptrtoint i64* %result to i64
  %1 = ptrtoint i64* %this to i64
  %2 = add i64 %0, 8, !insn.addr !1254
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1254
  %4 = load i64, i64* %3, align 8, !insn.addr !1254
  store i64 %0, i64* %this, align 8, !insn.addr !1255
  %5 = add i64 %1, 8, !insn.addr !1256
  %6 = inttoptr i64 %5 to i64*, !insn.addr !1256
  store i64 %4, i64* %6, align 8, !insn.addr !1256
  %7 = add i64 %0, 16, !insn.addr !1257
  %8 = inttoptr i64 %7 to i64*, !insn.addr !1257
  %9 = load i64, i64* %8, align 8, !insn.addr !1257
  %10 = add i64 %1, 16, !insn.addr !1258
  %11 = inttoptr i64 %10 to i64*, !insn.addr !1258
  store i64 %9, i64* %11, align 8, !insn.addr !1258
  ret i64 %1, !insn.addr !1259

; uselistorder directives
  uselistorder i64 %1, { 0, 2, 1 }
  uselistorder i64 %0, { 2, 0, 1 }
}

define i64 @_ZNSt8optionalIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC1IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_3c7c:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !1260
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !1260
  %2 = ptrtoint i64** %1 to i64, !insn.addr !1260
  %3 = call i64 @_ZNSt14_Optional_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb1EEC2IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !1261
  ret i64 %3, !insn.addr !1262
}

define i64 @_ZNK4llvm14iterator_rangeINS_20filter_iterator_implINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS0_IS7_EEEUlRS5_E_St26bidirectional_iterator_tagEEE3endEv(i64* %this, i64* %result) local_unnamed_addr {
dec_label_pc_3cb0:
  %0 = ptrtoint i64* %result to i64
  %1 = ptrtoint i64* %this to i64
  %2 = add i64 %0, 24, !insn.addr !1263
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1263
  %4 = load i64, i64* %3, align 8, !insn.addr !1263
  %5 = add i64 %0, 32, !insn.addr !1264
  %6 = inttoptr i64 %5 to i64*, !insn.addr !1264
  %7 = load i64, i64* %6, align 8, !insn.addr !1264
  store i64 %4, i64* %this, align 8, !insn.addr !1265
  %8 = add i64 %1, 8, !insn.addr !1266
  %9 = inttoptr i64 %8 to i64*, !insn.addr !1266
  store i64 %7, i64* %9, align 8, !insn.addr !1266
  %10 = add i64 %0, 40, !insn.addr !1267
  %11 = inttoptr i64 %10 to i64*, !insn.addr !1267
  %12 = load i64, i64* %11, align 8, !insn.addr !1267
  %13 = add i64 %1, 16, !insn.addr !1268
  %14 = inttoptr i64 %13 to i64*, !insn.addr !1268
  store i64 %12, i64* %14, align 8, !insn.addr !1268
  ret i64 %1, !insn.addr !1269

; uselistorder directives
  uselistorder i64 %1, { 0, 2, 1 }
  uselistorder i64 %0, { 2, 1, 0 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyC1EOS1_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_3ce2:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EOS4_(i64* %result, i64* %arg2), !insn.addr !1270
  %3 = add i64 %1, 32, !insn.addr !1271
  %4 = add i64 %0, 32, !insn.addr !1272
  %5 = inttoptr i64 %3 to i64*, !insn.addr !1273
  %6 = inttoptr i64 %4 to i64*, !insn.addr !1273
  %7 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EOS4_(i64* %5, i64* %6), !insn.addr !1273
  %8 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !1274
  %9 = inttoptr i64 %8 to i64*, !insn.addr !1274
  %10 = load i64, i64* %9, align 8, !insn.addr !1274
  %11 = add i64 %1, ptrtoint (i128** @global_var_40 to i64), !insn.addr !1275
  %12 = inttoptr i64 %11 to i64*, !insn.addr !1275
  store i64 %10, i64* %12, align 8, !insn.addr !1275
  ret i64 %1, !insn.addr !1276

; uselistorder directives
  uselistorder i64 %1, { 1, 0, 2 }
  uselistorder i64 (i64*, i64*)* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EOS4_, { 1, 0 }
}

define i64 @_ZNSt22_Optional_payload_baseIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEE8_StorageIS2_Lb0EEC1IJS2_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_3d34:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !1277
  %1 = call i64* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %0), !insn.addr !1277
  %2 = inttoptr i64 %arg1 to i64*, !insn.addr !1278
  %3 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyC1EOS1_(i64* %2, i64* %1), !insn.addr !1278
  ret i64 %3, !insn.addr !1279

; uselistorder directives
  uselistorder i64* (i64*)* @_ZSt7forwardIN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEOT_RNSt16remove_referenceIS3_E4typeE, { 3, 2, 1, 0 }
}

define i64 @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EE23RetreatPastEmptyBucketsEv(i64* %result) local_unnamed_addr {
dec_label_pc_3d68:
  %rax.0.reg2mem = alloca i64, !insn.addr !1280
  %rdi.02.reg2mem = alloca i64, !insn.addr !1280
  %rdi.2.ph.reg2mem = alloca i64, !insn.addr !1280
  %0 = ptrtoint i64* %result to i64
  %stack_var_-88 = alloca i64, align 8
  %stack_var_-168 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1281
  %2 = add i64 %0, 8, !insn.addr !1282
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1282
  %4 = load i64, i64* %3, align 8, !insn.addr !1282
  %5 = icmp ugt i64 %4, %0, !insn.addr !1283
  %6 = icmp eq i1 %5, false, !insn.addr !1284
  br i1 %6, label %dec_label_pc_3dcb, label %dec_label_pc_3da3, !insn.addr !1284

dec_label_pc_3da3:                                ; preds = %dec_label_pc_3d68
  %7 = call i64 @__assert_fail(i64 ptrtoint ([11 x i8]* @global_var_7799 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1341, i64 ptrtoint ([429 x i8]* @global_var_75ec to i64)), !insn.addr !1285
  br label %dec_label_pc_3dcb, !insn.addr !1285

dec_label_pc_3dcb:                                ; preds = %dec_label_pc_3da3, %dec_label_pc_3d68
  %8 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo11getEmptyKeyEv(i64* nonnull %stack_var_-168), !insn.addr !1286
  %9 = ptrtoint i64* %stack_var_-88 to i64, !insn.addr !1287
  %10 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo15getTombstoneKeyEv(i64* nonnull %stack_var_-88), !insn.addr !1288
  %11 = load i64, i64* %3, align 8, !insn.addr !1289
  %12 = icmp eq i64 %11, %9, !insn.addr !1290
  store i64 %9, i64* %rdi.02.reg2mem, !insn.addr !1291
  br i1 %12, label %dec_label_pc_3e89, label %dec_label_pc_3e1a, !insn.addr !1291

dec_label_pc_3de8:                                ; preds = %dec_label_pc_3e1a, %dec_label_pc_3e49
  %rdi.2.ph.reload = load i64, i64* %rdi.2.ph.reg2mem
  %13 = add i64 %rdi.2.ph.reload, -88, !insn.addr !1292
  store i64 %13, i64* %result, align 8, !insn.addr !1293
  %14 = load i64, i64* %3, align 8, !insn.addr !1289
  %15 = icmp eq i64 %rdi.2.ph.reload, %14, !insn.addr !1290
  store i64 %rdi.2.ph.reload, i64* %rdi.02.reg2mem, !insn.addr !1291
  br i1 %15, label %dec_label_pc_3e89, label %dec_label_pc_3e1a, !insn.addr !1291

dec_label_pc_3e1a:                                ; preds = %dec_label_pc_3dcb, %dec_label_pc_3de8
  %rdi.02.reload = load i64, i64* %rdi.02.reg2mem
  %16 = add i64 %rdi.02.reload, -88, !insn.addr !1294
  %17 = inttoptr i64 %16 to i64*, !insn.addr !1295
  %18 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %17), !insn.addr !1295
  %19 = inttoptr i64 %18 to i64*, !insn.addr !1296
  %20 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %19, i64* nonnull %stack_var_-168), !insn.addr !1296
  %21 = trunc i64 %20 to i8, !insn.addr !1297
  %22 = icmp eq i8 %21, 0, !insn.addr !1297
  %23 = icmp eq i1 %22, false, !insn.addr !1298
  store i64 %18, i64* %rdi.2.ph.reg2mem, !insn.addr !1298
  br i1 %23, label %dec_label_pc_3de8, label %dec_label_pc_3e49, !insn.addr !1298

dec_label_pc_3e49:                                ; preds = %dec_label_pc_3e1a
  %24 = add i64 %18, -88, !insn.addr !1299
  %25 = inttoptr i64 %24 to i64*, !insn.addr !1300
  %26 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %25), !insn.addr !1300
  %27 = inttoptr i64 %26 to i64*, !insn.addr !1301
  %28 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %27, i64* nonnull %stack_var_-88), !insn.addr !1301
  %29 = trunc i64 %28 to i8, !insn.addr !1302
  %30 = icmp eq i8 %29, 0, !insn.addr !1302
  store i64 %26, i64* %rdi.2.ph.reg2mem, !insn.addr !1303
  br i1 %30, label %dec_label_pc_3e89, label %dec_label_pc_3de8, !insn.addr !1303

dec_label_pc_3e89:                                ; preds = %dec_label_pc_3de8, %dec_label_pc_3e49, %dec_label_pc_3dcb
  %31 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-88), !insn.addr !1304
  %32 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-168), !insn.addr !1305
  %33 = call i64 @__readfsqword(i64 40), !insn.addr !1306
  %34 = icmp eq i64 %1, %33, !insn.addr !1306
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1307
  br i1 %34, label %dec_label_pc_3eb8, label %dec_label_pc_3eb3, !insn.addr !1307

dec_label_pc_3eb3:                                ; preds = %dec_label_pc_3e89
  %35 = call i64 @__stack_chk_fail(), !insn.addr !1308
  store i64 %35, i64* %rax.0.reg2mem, !insn.addr !1308
  br label %dec_label_pc_3eb8, !insn.addr !1308

dec_label_pc_3eb8:                                ; preds = %dec_label_pc_3eb3, %dec_label_pc_3e89
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1309

; uselistorder directives
  uselistorder i64 %18, { 1, 0, 2 }
  uselistorder i64 %rdi.2.ph.reload, { 0, 2, 1 }
  uselistorder i64* %3, { 1, 0, 2 }
  uselistorder i64* %rdi.2.ph.reg2mem, { 2, 1, 0 }
  uselistorder i64* %rdi.02.reg2mem, { 0, 2, 1 }
  uselistorder i64 -88, { 0, 1, 3, 2 }
  uselistorder label %dec_label_pc_3e89, { 1, 0, 2 }
  uselistorder label %dec_label_pc_3e1a, { 1, 0 }
  uselistorder label %dec_label_pc_3de8, { 1, 0 }
}

define i64 @_ZN4llvm16DenseMapIteratorIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EELb0EE23AdvancePastEmptyBucketsEv(i64* %result) local_unnamed_addr {
dec_label_pc_3eba:
  %rax.0.reg2mem = alloca i64, !insn.addr !1310
  %rdi.02.reg2mem = alloca i64, !insn.addr !1310
  %rdi.2.ph.reg2mem = alloca i64, !insn.addr !1310
  %0 = ptrtoint i64* %result to i64
  %stack_var_-88 = alloca i64, align 8
  %stack_var_-168 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1311
  %2 = add i64 %0, 8, !insn.addr !1312
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1312
  %4 = load i64, i64* %3, align 8, !insn.addr !1312
  %5 = icmp ult i64 %4, %0, !insn.addr !1313
  %6 = icmp eq i1 %5, false, !insn.addr !1314
  br i1 %6, label %dec_label_pc_3f1d, label %dec_label_pc_3ef5, !insn.addr !1314

dec_label_pc_3ef5:                                ; preds = %dec_label_pc_3eba
  %7 = call i64 @__assert_fail(i64 ptrtoint ([11 x i8]* @global_var_7951 to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 1331, i64 ptrtoint ([429 x i8]* @global_var_77a4 to i64)), !insn.addr !1315
  br label %dec_label_pc_3f1d, !insn.addr !1315

dec_label_pc_3f1d:                                ; preds = %dec_label_pc_3ef5, %dec_label_pc_3eba
  %8 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo11getEmptyKeyEv(i64* nonnull %stack_var_-168), !insn.addr !1316
  %9 = ptrtoint i64* %stack_var_-88 to i64, !insn.addr !1317
  %10 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo15getTombstoneKeyEv(i64* nonnull %stack_var_-88), !insn.addr !1318
  %11 = load i64, i64* %3, align 8, !insn.addr !1319
  %12 = icmp eq i64 %11, %9, !insn.addr !1320
  store i64 %9, i64* %rdi.02.reg2mem, !insn.addr !1321
  br i1 %12, label %dec_label_pc_3fd3, label %dec_label_pc_3f6c, !insn.addr !1321

dec_label_pc_3f3a:                                ; preds = %dec_label_pc_3f6c, %dec_label_pc_3f97
  %rdi.2.ph.reload = load i64, i64* %rdi.2.ph.reg2mem
  %13 = add i64 %rdi.2.ph.reload, 88, !insn.addr !1322
  store i64 %13, i64* %result, align 8, !insn.addr !1323
  %14 = load i64, i64* %3, align 8, !insn.addr !1319
  %15 = icmp eq i64 %rdi.2.ph.reload, %14, !insn.addr !1320
  store i64 %rdi.2.ph.reload, i64* %rdi.02.reg2mem, !insn.addr !1321
  br i1 %15, label %dec_label_pc_3fd3, label %dec_label_pc_3f6c, !insn.addr !1321

dec_label_pc_3f6c:                                ; preds = %dec_label_pc_3f1d, %dec_label_pc_3f3a
  %rdi.02.reload = load i64, i64* %rdi.02.reg2mem
  %16 = inttoptr i64 %rdi.02.reload to i64*, !insn.addr !1324
  %17 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %16), !insn.addr !1324
  %18 = inttoptr i64 %17 to i64*, !insn.addr !1325
  %19 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %18, i64* nonnull %stack_var_-168), !insn.addr !1325
  %20 = trunc i64 %19 to i8, !insn.addr !1326
  %21 = icmp eq i8 %20, 0, !insn.addr !1326
  %22 = icmp eq i1 %21, false, !insn.addr !1327
  store i64 %17, i64* %rdi.2.ph.reg2mem, !insn.addr !1327
  br i1 %22, label %dec_label_pc_3f3a, label %dec_label_pc_3f97, !insn.addr !1327

dec_label_pc_3f97:                                ; preds = %dec_label_pc_3f6c
  %23 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %18), !insn.addr !1328
  %24 = inttoptr i64 %23 to i64*, !insn.addr !1329
  %25 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %24, i64* nonnull %stack_var_-88), !insn.addr !1329
  %26 = trunc i64 %25 to i8, !insn.addr !1330
  %27 = icmp eq i8 %26, 0, !insn.addr !1330
  store i64 %23, i64* %rdi.2.ph.reg2mem, !insn.addr !1331
  br i1 %27, label %dec_label_pc_3fd3, label %dec_label_pc_3f3a, !insn.addr !1331

dec_label_pc_3fd3:                                ; preds = %dec_label_pc_3f3a, %dec_label_pc_3f97, %dec_label_pc_3f1d
  %28 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-88), !insn.addr !1332
  %29 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-168), !insn.addr !1333
  %30 = call i64 @__readfsqword(i64 40), !insn.addr !1334
  %31 = icmp eq i64 %1, %30, !insn.addr !1334
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1335
  br i1 %31, label %dec_label_pc_4002, label %dec_label_pc_3ffd, !insn.addr !1335

dec_label_pc_3ffd:                                ; preds = %dec_label_pc_3fd3
  %32 = call i64 @__stack_chk_fail(), !insn.addr !1336
  store i64 %32, i64* %rax.0.reg2mem, !insn.addr !1336
  br label %dec_label_pc_4002, !insn.addr !1336

dec_label_pc_4002:                                ; preds = %dec_label_pc_3ffd, %dec_label_pc_3fd3
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1337

; uselistorder directives
  uselistorder i64 %rdi.2.ph.reload, { 0, 2, 1 }
  uselistorder i64* %3, { 1, 0, 2 }
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64* %rdi.2.ph.reg2mem, { 2, 1, 0 }
  uselistorder i64* %rdi.02.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*)* @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo15getTombstoneKeyEv, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo11getEmptyKeyEv, { 2, 1, 0 }
  uselistorder label %dec_label_pc_3fd3, { 1, 0, 2 }
  uselistorder label %dec_label_pc_3f6c, { 1, 0 }
  uselistorder label %dec_label_pc_3f3a, { 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E4growEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_4004:
  %0 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE4growEj(i64* %result, i32 %arg2), !insn.addr !1338
  ret i64 %0, !insn.addr !1339
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E19incrementNumEntriesEv(i64* %result) local_unnamed_addr {
dec_label_pc_4028:
  %0 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumEntriesEv(i64* %result), !insn.addr !1340
  %1 = trunc i64 %0 to i32
  %2 = add i32 %1, 1, !insn.addr !1341
  %3 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13setNumEntriesEj(i64* %result, i32 %2), !insn.addr !1342
  ret i64 %3, !insn.addr !1343

; uselistorder directives
  uselistorder i64 (i64*, i32)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13setNumEntriesEj, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E13getNumEntriesEv, { 3, 2, 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E22decrementNumTombstonesEv(i64* %result) local_unnamed_addr {
dec_label_pc_4054:
  %0 = call i64 @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16getNumTombstonesEv(i64* %result), !insn.addr !1344
  %1 = trunc i64 %0 to i32
  %2 = add i32 %1, -1, !insn.addr !1345
  %3 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16setNumTombstonesEj(i64* %result, i32 %2), !insn.addr !1346
  ret i64 %3, !insn.addr !1347

; uselistorder directives
  uselistorder i64 (i64*, i32)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16setNumTombstonesEj, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E16getNumTombstonesEv, { 2, 1, 0 }
}

define i64* @_ZNKSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERKT_v(i64* %result) local_unnamed_addr {
dec_label_pc_4080:
  %0 = call i64 @_ZNKSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !1348
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1349
  ret i64* %1, !insn.addr !1349
}

define i64* @_ZSt11__addressofIKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EPT_RSG_(i64* %arg1) local_unnamed_addr {
dec_label_pc_409a:
  ret i64* %arg1, !insn.addr !1350
}

define i64** @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_40a8:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !1351
  ret i64** %0, !insn.addr !1351
}

define i1 @_ZSt13__invoke_implIbRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_JS4_SA_SD_EET_St14__invoke_otherOT0_DpOT1_(i64* %result, i64 %arg2, i64** %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_40b6:
  %0 = call i64** @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE(i64* %result), !insn.addr !1352
  %1 = ptrtoint i64** %0 to i64, !insn.addr !1352
  %2 = inttoptr i64 %arg4 to i64*, !insn.addr !1353
  %3 = call i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %2), !insn.addr !1353
  %4 = ptrtoint i64* %3 to i64, !insn.addr !1353
  %5 = bitcast i64** %arg3 to i64*, !insn.addr !1354
  %6 = call i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %5), !insn.addr !1354
  %7 = ptrtoint i64** %6 to i64, !insn.addr !1354
  %8 = inttoptr i64 %arg2 to i64*, !insn.addr !1355
  %9 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %8), !insn.addr !1355
  %10 = ptrtoint i64* %9 to i64, !insn.addr !1355
  %11 = load i64, i64* %3, align 8, !insn.addr !1356
  %12 = add i64 %4, 8, !insn.addr !1357
  %13 = inttoptr i64 %12 to i64*, !insn.addr !1357
  %14 = load i64, i64* %13, align 8, !insn.addr !1357
  %15 = load i64, i64* %9, align 8, !insn.addr !1358
  %16 = add i64 %10, 8, !insn.addr !1359
  %17 = inttoptr i64 %16 to i64*, !insn.addr !1359
  %18 = load i64, i64* %17, align 8, !insn.addr !1359
  %19 = call i64 @_ZZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES1_ENKUlNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS5_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEE_clES3_S9_SC_(i64 %1, i64 %15, i64 %18, i64 %7, i64 %11, i64 %14), !insn.addr !1360
  %20 = urem i64 %19, 2
  %21 = icmp ne i64 %20, 0, !insn.addr !1361
  ret i1 %21, !insn.addr !1361

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE, { 2, 1, 0 }
  uselistorder i64* (i64*)* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE, { 2, 1, 0 }
  uselistorder i64** (i64*)* @_ZSt7forwardIRZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISG_E4typeE, { 1, 0 }
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E15_M_init_functorIRKSF_EEvRSt9_Any_dataOT_(i64* %arg1, i64** %arg2) local_unnamed_addr {
dec_label_pc_413c:
  %0 = bitcast i64** %arg2 to i64*
  %1 = call i64** @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE(i64* %0), !insn.addr !1362
  call void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createIRKSF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64** %1, i64 ptrtoint (i32* @0 to i64)), !insn.addr !1363
  ret void, !insn.addr !1364
}

define i64 @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E10_M_destroyERSt9_Any_dataSt17integral_constantIbLb1EE(i64* %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_416d:
  %0 = call i64* @_ZNSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %arg1), !insn.addr !1365
  %1 = ptrtoint i64* %0 to i64, !insn.addr !1365
  ret i64 %1, !insn.addr !1366
}

define i64 @_ZN4llvm21iterator_adaptor_baseINS_20filter_iterator_baseINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEZNS_L13filterDbgVarsENS_14iterator_rangeIS7_EEEUlRS5_E_St26bidirectional_iterator_tagEES7_SC_S5_lPS5_SA_EppEv(i64* %result) local_unnamed_addr {
dec_label_pc_4188:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* %result), !insn.addr !1367
  ret i64 %0, !insn.addr !1368
}

define i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_41a6:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !1369
  ret i64** %0, !insn.addr !1369
}

define i64 @_ZNSt17_Optional_payloadIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb0ELb0EECI1St22_Optional_payload_baseISA_EIJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_41b4:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC2IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2), !insn.addr !1370
  ret i64 %0, !insn.addr !1371
}

define i64 @_ZNSt14_Optional_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb1EEC2IJRKSA_ELb0EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_41da:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !1372
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !1372
  %2 = ptrtoint i64** %1 to i64, !insn.addr !1372
  %3 = call i64 @_ZNSt17_Optional_payloadIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_Lb1ELb0ELb0EECI1St22_Optional_payload_baseISA_EIJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !1373
  ret i64 %3, !insn.addr !1374
}

define i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE4growEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_420e:
  %rax.0.reg2mem = alloca i64, !insn.addr !1375
  %0 = ptrtoint i64* %result to i64
  %stack_var_-36 = alloca i128*, align 8
  %stack_var_-32 = alloca i32, align 4
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1376
  %2 = add i64 %0, 16, !insn.addr !1377
  %3 = inttoptr i64 %2 to i32*, !insn.addr !1377
  %4 = load i32, i32* %3, align 4, !insn.addr !1377
  %5 = add i32 %arg2, -1, !insn.addr !1378
  %6 = zext i32 %5 to i64, !insn.addr !1379
  %7 = call i64 @_ZN4llvm12NextPowerOf2Em(i64 %6), !insn.addr !1380
  %8 = trunc i64 %7 to i32, !insn.addr !1381
  store i32 %8, i32* %stack_var_-32, align 4, !insn.addr !1381
  store i128* inttoptr (i32 ptrtoint (i128** @global_var_40 to i32) to i128*), i128** %stack_var_-36, align 8, !insn.addr !1382
  %9 = bitcast i128** %stack_var_-36 to i32*, !insn.addr !1383
  %10 = call i32* @_ZSt3maxIjERKT_S2_S2_(i32* nonnull %9, i32* nonnull %stack_var_-32), !insn.addr !1383
  %11 = load i32, i32* %10, align 4, !insn.addr !1384
  %12 = call i64 @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE15allocateBucketsEj(i64* %result, i32 %11), !insn.addr !1385
  %13 = icmp eq i64* %result, null, !insn.addr !1386
  %14 = icmp eq i1 %13, false, !insn.addr !1387
  br i1 %14, label %dec_label_pc_42c7, label %dec_label_pc_42b9, !insn.addr !1387

dec_label_pc_42b9:                                ; preds = %dec_label_pc_420e
  %15 = call i64 @__assert_fail(i64 ptrtoint ([8 x i8]* @global_var_7f5d to i64), i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), i64 860, i64 ptrtoint ([385 x i8]* @global_var_7ddc to i64)), !insn.addr !1388
  %16 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E9initEmptyEv(i64* %result), !insn.addr !1389
  br label %dec_label_pc_4329, !insn.addr !1390

dec_label_pc_42c7:                                ; preds = %dec_label_pc_420e
  %17 = zext i32 %4 to i64, !insn.addr !1391
  %18 = mul nuw nsw i64 %17, 88, !insn.addr !1392
  %19 = add i64 %18, %0, !insn.addr !1393
  %20 = inttoptr i64 %19 to i64*, !insn.addr !1394
  %21 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E18moveFromOldBucketsEPS9_SC_(i64* %result, i64* %result, i64* %20), !insn.addr !1394
  %22 = call i64 @_ZN4llvm17deallocate_bufferEPvmm(i64* %result, i64 %18, i64 8), !insn.addr !1395
  br label %dec_label_pc_4329, !insn.addr !1395

dec_label_pc_4329:                                ; preds = %dec_label_pc_42c7, %dec_label_pc_42b9
  %23 = call i64 @__readfsqword(i64 40), !insn.addr !1396
  %24 = icmp eq i64 %1, %23, !insn.addr !1396
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1397
  br i1 %24, label %dec_label_pc_433d, label %dec_label_pc_4338, !insn.addr !1397

dec_label_pc_4338:                                ; preds = %dec_label_pc_4329
  %25 = call i64 @__stack_chk_fail(), !insn.addr !1398
  store i64 %25, i64* %rax.0.reg2mem, !insn.addr !1398
  br label %dec_label_pc_433d, !insn.addr !1398

dec_label_pc_433d:                                ; preds = %dec_label_pc_4338, %dec_label_pc_4329
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1399

; uselistorder directives
  uselistorder i64 %18, { 1, 0 }
  uselistorder i128** %stack_var_-36, { 1, 0 }
  uselistorder i64 (i64*, i64, i64)* @_ZN4llvm17deallocate_bufferEPvmm, { 2, 1, 0 }
  uselistorder i64 ptrtoint ([41 x i8]* @global_var_63f4 to i64), { 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 12, 1, 13, 2, 14 }
  uselistorder i64 (i64*, i32)* @_ZN4llvm8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS2_9LastStoreENS2_12AliasKeyInfoENS_6detail12DenseMapPairIS3_S4_EEE15allocateBucketsEj, { 1, 0 }
  uselistorder i64 (i64)* @_ZN4llvm12NextPowerOf2Em, { 1, 0 }
}

define i64** @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_433f:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !1400
  ret i64** %0, !insn.addr !1400
}

define void @_ZNSt14_Function_base13_Base_managerIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_E9_M_createIRKSF_EEvRSt9_Any_dataOT_St17integral_constantIbLb1EE(i64* %arg1, i64** %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_434d:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %arg1), !insn.addr !1401
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1402
  %2 = call i64 @_ZnwmPv(i64 1, i64* %1), !insn.addr !1402
  %3 = bitcast i64** %arg2 to i64*
  %4 = call i64** @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE(i64* %3), !insn.addr !1403
  ret void, !insn.addr !1404

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRKZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES2_EUlNS0_9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS6_JEEEJEEENS0_8ArrayRefINS1_15PipelineElementEEEE_EOT_RNSt16remove_referenceISH_E4typeE, { 1, 0 }
}

define i64* @_ZNSt9_Any_data9_M_accessIZZ21llvmGetPassPluginInfoENKUlRN4llvm11PassBuilderEE_clES3_EUlNS1_9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS7_JEEEJEEENS1_8ArrayRefINS2_15PipelineElementEEEE_EERT_v(i64* %result) local_unnamed_addr {
dec_label_pc_4386:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !1405
  %1 = inttoptr i64 %0 to i64*, !insn.addr !1406
  ret i64* %1, !insn.addr !1406
}

define i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EC2IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_43a0:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !1407
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !1407
  %2 = ptrtoint i64** %1 to i64, !insn.addr !1407
  %3 = call i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_E8_StorageISA_Lb1EEC1IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %2), !insn.addr !1408
  %4 = add i64 %arg1, 1, !insn.addr !1409
  %5 = inttoptr i64 %4 to i8*, !insn.addr !1409
  store i8 1, i8* %5, align 1, !insn.addr !1409
  ret i64 %arg1, !insn.addr !1410

; uselistorder directives
  uselistorder i64 %arg1, { 1, 0, 2 }
}

define i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyaSEOS1_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_43dc:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEOS4_(i64* %result, i64* %arg2, i64* %arg2), !insn.addr !1411
  %3 = add i64 %0, 32, !insn.addr !1412
  %4 = add i64 %1, 32, !insn.addr !1413
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1414
  %6 = inttoptr i64 %3 to i64*, !insn.addr !1414
  %7 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEOS4_(i64* %5, i64* %6, i64* %6), !insn.addr !1414
  %8 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !1415
  %9 = inttoptr i64 %8 to i64*, !insn.addr !1415
  %10 = load i64, i64* %9, align 8, !insn.addr !1415
  %11 = add i64 %1, ptrtoint (i128** @global_var_40 to i64), !insn.addr !1416
  %12 = inttoptr i64 %11 to i64*, !insn.addr !1416
  store i64 %10, i64* %12, align 8, !insn.addr !1416
  ret i64 %1, !insn.addr !1417

; uselistorder directives
  uselistorder i64 (i64*, i64*, i64*)* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEOS4_, { 3, 2, 1, 0 }
}

define i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E18moveFromOldBucketsEPS9_SC_(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_4430:
  %rax.0.reg2mem = alloca i64, !insn.addr !1418
  %stack_var_-200.01.reg2mem = alloca i64, !insn.addr !1418
  %stack_var_-208 = alloca i64, align 8
  %stack_var_-104 = alloca i64, align 8
  %stack_var_-184 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1419
  %1 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E9initEmptyEv(i64* %result), !insn.addr !1420
  %2 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv(i64* nonnull %stack_var_-184), !insn.addr !1421
  %3 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15getTombstoneKeyEv(i64* nonnull %stack_var_-104), !insn.addr !1422
  %4 = icmp eq i64* %arg2, %arg3, !insn.addr !1423
  %5 = icmp eq i1 %4, false, !insn.addr !1424
  br i1 %5, label %dec_label_pc_44ab.lr.ph, label %dec_label_pc_4642, !insn.addr !1424

dec_label_pc_44ab.lr.ph:                          ; preds = %dec_label_pc_4430
  %6 = ptrtoint i64* %arg3 to i64
  %7 = ptrtoint i64* %arg2 to i64
  %8 = bitcast i64* %stack_var_-208 to i64**
  store i64 %7, i64* %stack_var_-200.01.reg2mem
  br label %dec_label_pc_44ab

dec_label_pc_44ab:                                ; preds = %dec_label_pc_44ab.lr.ph, %dec_label_pc_460f
  %stack_var_-200.01.reload = load i64, i64* %stack_var_-200.01.reg2mem
  %9 = inttoptr i64 %stack_var_-200.01.reload to i64*, !insn.addr !1425
  %10 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %9), !insn.addr !1425
  %11 = inttoptr i64 %10 to i64*, !insn.addr !1426
  %12 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %11, i64* nonnull %stack_var_-184), !insn.addr !1426
  %13 = trunc i64 %12 to i8
  %14 = icmp eq i8 %13, 1, !insn.addr !1427
  br i1 %14, label %dec_label_pc_460f, label %dec_label_pc_44d6, !insn.addr !1428

dec_label_pc_44d6:                                ; preds = %dec_label_pc_44ab
  %15 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %9), !insn.addr !1429
  %16 = inttoptr i64 %15 to i64*, !insn.addr !1430
  %17 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_(i64* %16, i64* nonnull %stack_var_-104), !insn.addr !1430
  %18 = trunc i64 %17 to i8
  %19 = icmp eq i8 %18, 1, !insn.addr !1431
  br i1 %19, label %dec_label_pc_460f, label %dec_label_pc_4512, !insn.addr !1432

dec_label_pc_4512:                                ; preds = %dec_label_pc_44d6
  %20 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %9), !insn.addr !1433
  %21 = inttoptr i64 %20 to i64*, !insn.addr !1434
  %22 = call i1 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15LookupBucketForIS4_EEbRKT_RPS9_(i64* %result, i64* %21, i64** nonnull %8), !insn.addr !1434
  %23 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %9), !insn.addr !1435
  %24 = inttoptr i64 %23 to i64**, !insn.addr !1436
  %25 = call i64* @_ZSt4moveIRN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEONSt16remove_referenceIT_E4typeEOS5_(i64** %24), !insn.addr !1436
  %26 = load i64, i64* %stack_var_-208, align 8, !insn.addr !1437
  %27 = inttoptr i64 %26 to i64*, !insn.addr !1438
  %28 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %27), !insn.addr !1438
  %29 = inttoptr i64 %28 to i64*, !insn.addr !1439
  %30 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyaSEOS1_(i64* %29, i64* %25), !insn.addr !1439
  %31 = load i64, i64* %stack_var_-208, align 8, !insn.addr !1440
  %32 = inttoptr i64 %31 to i64*, !insn.addr !1441
  %33 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE9getSecondEv(i64* %32), !insn.addr !1441
  %34 = inttoptr i64 %33 to i64*, !insn.addr !1442
  %35 = call i64 @_ZnwmPv(i64 16, i64* %34), !insn.addr !1442
  %36 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE9getSecondEv(i64* %9), !insn.addr !1443
  %37 = inttoptr i64 %36 to i64**, !insn.addr !1444
  %38 = call i64* @_ZSt4moveIRN22brighten_state_forward12_GLOBAL__N_19LastStoreEEONSt16remove_referenceIT_E4typeEOS5_(i64** %37), !insn.addr !1444
  %39 = ptrtoint i64* %38 to i64, !insn.addr !1444
  %40 = add i64 %39, 8, !insn.addr !1445
  %41 = inttoptr i64 %40 to i64*, !insn.addr !1445
  %42 = load i64, i64* %41, align 8, !insn.addr !1445
  %43 = load i64, i64* %38, align 8, !insn.addr !1446
  %44 = inttoptr i64 %35 to i64*, !insn.addr !1447
  store i64 %43, i64* %44, align 8, !insn.addr !1447
  %45 = add i64 %35, 8, !insn.addr !1448
  %46 = inttoptr i64 %45 to i64*, !insn.addr !1448
  store i64 %42, i64* %46, align 8, !insn.addr !1448
  %47 = call i64 @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E19incrementNumEntriesEv(i64* %result), !insn.addr !1449
  %48 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE9getSecondEv(i64* %9), !insn.addr !1450
  br label %dec_label_pc_460f, !insn.addr !1450

dec_label_pc_460f:                                ; preds = %dec_label_pc_44ab, %dec_label_pc_44d6, %dec_label_pc_4512
  %49 = call i64 @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv(i64* %9), !insn.addr !1451
  %50 = inttoptr i64 %49 to i64*, !insn.addr !1452
  %51 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* %50), !insn.addr !1452
  %52 = add i64 %stack_var_-200.01.reload, 88, !insn.addr !1453
  %53 = icmp eq i64 %52, %6, !insn.addr !1423
  %54 = icmp eq i1 %53, false, !insn.addr !1424
  store i64 %52, i64* %stack_var_-200.01.reg2mem, !insn.addr !1424
  br i1 %54, label %dec_label_pc_44ab, label %dec_label_pc_4642, !insn.addr !1424

dec_label_pc_4642:                                ; preds = %dec_label_pc_460f, %dec_label_pc_4430
  %55 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-104), !insn.addr !1454
  %56 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev(i64* nonnull %stack_var_-184), !insn.addr !1455
  %57 = call i64 @__readfsqword(i64 40), !insn.addr !1456
  %58 = icmp eq i64 %0, %57, !insn.addr !1456
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1457
  br i1 %58, label %dec_label_pc_4671, label %dec_label_pc_466c, !insn.addr !1457

dec_label_pc_466c:                                ; preds = %dec_label_pc_4642
  %59 = call i64 @__stack_chk_fail(), !insn.addr !1458
  store i64 %59, i64* %rax.0.reg2mem, !insn.addr !1458
  br label %dec_label_pc_4671, !insn.addr !1458

dec_label_pc_4671:                                ; preds = %dec_label_pc_466c, %dec_label_pc_4642
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1459

; uselistorder directives
  uselistorder i64 %35, { 1, 0 }
  uselistorder i64* %9, { 5, 0, 1, 2, 3, 4, 6 }
  uselistorder i64* %stack_var_-208, { 1, 2, 0 }
  uselistorder i64* %stack_var_-200.01.reg2mem, { 1, 0, 2 }
  uselistorder i64 (i64*)* @_ZN22brighten_state_forward12_GLOBAL__N_18AliasKeyD1Ev, { 16, 15, 17, 14, 13, 12, 11, 10, 9, 0, 8, 7, 6, 4, 3, 5, 2, 1 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E19incrementNumEntriesEv, { 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE9getSecondEv, { 4, 3, 2, 1, 0 }
  uselistorder i1 (i64*, i64*, i64**)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15LookupBucketForIS4_EEbRKT_RPS9_, { 3, 2, 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN22brighten_state_forward12_GLOBAL__N_112AliasKeyInfo7isEqualERKNS0_8AliasKeyES4_, { 17, 16, 15, 14, 13, 12, 11, 8, 10, 9, 0, 7, 6, 4, 5, 1, 3, 2 }
  uselistorder i64 (i64*)* @_ZN4llvm6detail12DenseMapPairIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreEE8getFirstEv, { 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 8, 10, 9, 0, 6, 7, 1, 5, 4, 3, 2 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E15getTombstoneKeyEv, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E11getEmptyKeyEv, { 6, 5, 4, 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm12DenseMapBaseINS_8DenseMapIN22brighten_state_forward12_GLOBAL__N_18AliasKeyENS3_9LastStoreENS3_12AliasKeyInfoENS_6detail12DenseMapPairIS4_S5_EEEES4_S5_S6_S9_E9initEmptyEv, { 3, 2, 1, 0 }
  uselistorder i64* %arg3, { 1, 0 }
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder label %dec_label_pc_460f, { 2, 1, 0 }
  uselistorder label %dec_label_pc_44ab, { 1, 0 }
}

define i64 @_ZNSt22_Optional_payload_baseIZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_E8_StorageISA_Lb1EEC1IJRKSA_EEESt10in_place_tDpOT_(i64 %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_4678:
  %0 = inttoptr i64 %arg2 to i64*, !insn.addr !1460
  %1 = call i64** @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE(i64* %0), !insn.addr !1460
  %2 = ptrtoint i64** %1 to i64, !insn.addr !1460
  ret i64 %2, !insn.addr !1461

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRKZN4llvmL13filterDbgVarsENS0_14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEUlRS5_E0_EOT_RNSt16remove_referenceISD_E4typeE, { 3, 2, 1, 0 }
}

define i64* @_ZSt4moveIRN22brighten_state_forward12_GLOBAL__N_18AliasKeyEEONSt16remove_referenceIT_E4typeEOS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_4697:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !1462
  ret i64* %0, !insn.addr !1462
}

define i64* @_ZSt4moveIRN22brighten_state_forward12_GLOBAL__N_19LastStoreEEONSt16remove_referenceIT_E4typeEOS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_46a5:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !1463
  ret i64* %0, !insn.addr !1463
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_46b4:
  store i64 ptrtoint (i64* @global_var_b2a4 to i64), i64* %result, align 8, !insn.addr !1464
  %0 = call i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result), !insn.addr !1465
  ret i64 %0, !insn.addr !1466
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEED0Ev(i64* %result) local_unnamed_addr {
dec_label_pc_46e2:
  %0 = call i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result), !insn.addr !1467
  %1 = call i64 @_ZdlPvm(i64* %result, i64 16), !insn.addr !1468
  ret i64 %1, !insn.addr !1469
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEE3runERS2_RS7_(i64* %this, i64* %result, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_4712:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1470
  %2 = add i64 %0, 8, !insn.addr !1471
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1472
  %4 = call i64 @_ZN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPass3runERN4llvm6ModuleERNS2_15AnalysisManagerIS3_JEEE(i64* %this, i64* %3, i64* %arg3, i64* %arg4), !insn.addr !1472
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !1473
  %6 = icmp eq i64 %1, %5, !insn.addr !1473
  br i1 %6, label %dec_label_pc_476d, label %dec_label_pc_4768, !insn.addr !1474

dec_label_pc_4768:                                ; preds = %dec_label_pc_4712
  %7 = call i64 @__stack_chk_fail(), !insn.addr !1475
  br label %dec_label_pc_476d, !insn.addr !1475

dec_label_pc_476d:                                ; preds = %dec_label_pc_4768, %dec_label_pc_4712
  %8 = ptrtoint i64* %this to i64
  ret i64 %8, !insn.addr !1476

; uselistorder directives
  uselistorder i64* %this, { 1, 0 }
}

define i64 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEE13printPipelineERNS_11raw_ostreamENS_12function_refIFNS_9StringRefESC_EEE(i64* %this, i64* %result, i64* %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_4774:
  %0 = ptrtoint i64* %this to i64
  %1 = add i64 %0, 8, !insn.addr !1477
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1478
  %3 = call i64 @_ZN4llvm13PassInfoMixinIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEE13printPipelineERNS_11raw_ostreamENS_12function_refIFNS_9StringRefES8_EEE(i64* %2, i64* %result, i64* %arg3, i64 %arg4), !insn.addr !1478
  ret i64 %3, !insn.addr !1479
}

define i64 @_ZNK4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEE4nameEv(i64* %result) local_unnamed_addr {
dec_label_pc_47b2:
  %0 = call i64 @_ZN4llvm13PassInfoMixinIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEE4nameEv(), !insn.addr !1480
  ret i64 %0, !insn.addr !1481
}

define i64 @_ZNK4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEE10isRequiredEv(i64* %result) local_unnamed_addr {
dec_label_pc_47ca:
  %0 = call i1 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEE18passIsRequiredImplIS5_EEbv(), !insn.addr !1482
  %1 = sext i1 %0 to i64, !insn.addr !1482
  ret i64 %1, !insn.addr !1483
}

define i64 @_ZN4llvm13PassInfoMixinIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEE13printPipelineERNS_11raw_ostreamENS_12function_refIFNS_9StringRefES8_EEE(i64* %this, i64* %result, i64* %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_47e2:
  %rax.0.reg2mem = alloca i64, !insn.addr !1484
  %0 = ptrtoint i64* %arg3 to i64
  %stack_var_-88 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-88, align 8, !insn.addr !1485
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1486
  %2 = call i64 @_ZN4llvm13PassInfoMixinIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEE4nameEv(), !insn.addr !1487
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1488
  %4 = call i64 @_ZNK4llvm12function_refIFNS_9StringRefES1_EEclES1_(i64* nonnull %stack_var_-88, i64* %3, i64 %0), !insn.addr !1488
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1489
  %6 = call i64 @_ZN4llvm11raw_ostreamlsENS_9StringRefE(i64* %result, i64* %5, i64 %0), !insn.addr !1489
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !1490
  %8 = icmp eq i64 %1, %7, !insn.addr !1490
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1491
  br i1 %8, label %dec_label_pc_4861, label %dec_label_pc_485c, !insn.addr !1491

dec_label_pc_485c:                                ; preds = %dec_label_pc_47e2
  %9 = call i64 @__stack_chk_fail(), !insn.addr !1492
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !1492
  br label %dec_label_pc_4861, !insn.addr !1492

dec_label_pc_4861:                                ; preds = %dec_label_pc_485c, %dec_label_pc_47e2
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1493
}

define i64 @_ZN4llvm13PassInfoMixinIN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassEE4nameEv() local_unnamed_addr {
dec_label_pc_4863:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !1494
  %1 = load i64, i64* %0
  %stack_var_-40 = alloca i64, align 8
  %stack_var_-56 = alloca i8*, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !1495
  store i8* getelementptr inbounds ([63 x i8], [63 x i8]* @global_var_860a, i64 0, i64 0), i8** %stack_var_-56, align 8, !insn.addr !1496
  %3 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-40, i8* getelementptr inbounds ([7 x i8], [7 x i8]* @global_var_8649, i64 0, i64 0)), !insn.addr !1497
  %4 = load i64, i64* %stack_var_-40, align 8, !insn.addr !1498
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1499
  %6 = bitcast i8** %stack_var_-56 to i64*, !insn.addr !1499
  %7 = call i64 @_ZN4llvm9StringRef13consume_frontES0_(i64* nonnull %6, i64* %5, i64 %1), !insn.addr !1499
  %8 = load i8*, i8** %stack_var_-56, align 8, !insn.addr !1500
  %9 = ptrtoint i8* %8 to i64, !insn.addr !1500
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !1501
  %11 = icmp eq i64 %2, %10, !insn.addr !1501
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !1502
  br i1 %11, label %dec_label_pc_48d6, label %dec_label_pc_48d1, !insn.addr !1502

dec_label_pc_48d1:                                ; preds = %dec_label_pc_4863
  %12 = call i64 @__stack_chk_fail(), !insn.addr !1503
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !1503
  br label %dec_label_pc_48d6, !insn.addr !1503

dec_label_pc_48d6:                                ; preds = %dec_label_pc_48d1, %dec_label_pc_4863
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1504

; uselistorder directives
  uselistorder i8** %stack_var_-56, { 1, 2, 0 }
  uselistorder i64* %stack_var_-40, { 1, 0 }
}

define i1 @_ZN4llvm6detail9PassModelINS_6ModuleEN22brighten_state_forward12_GLOBAL__N_124BrightenStateForwardPassENS_15AnalysisManagerIS2_JEEEJEE18passIsRequiredImplIS5_EEbv() local_unnamed_addr {
dec_label_pc_48d8:
  ret i1 false, !insn.addr !1505
}

define i64 @_ZSt23__is_constant_evaluatedv() local_unnamed_addr {
dec_label_pc_48e3:
  ret i64 0, !insn.addr !1506
}

define i64 @_ZNSt11char_traitsIcE2ltERKcS2_(i8* %arg1, i8* %arg2) local_unnamed_addr {
dec_label_pc_48f2:
  %0 = alloca i64
  %1 = load i64, i64* %0
  %2 = load i64, i64* %0
  %3 = trunc i64 %1 to i8
  %4 = trunc i64 %2 to i8
  %5 = icmp ult i8 %3, %4, !insn.addr !1507
  %6 = zext i1 %5 to i64, !insn.addr !1508
  ret i64 %6, !insn.addr !1509

; uselistorder directives
  uselistorder i64* %0, { 1, 0 }
}

define i64 @_ZNSt11char_traitsIcE7compareEPKcS2_m(i8* %arg1, i8* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_4919:
  %rax.0.reg2mem = alloca i64, !insn.addr !1510
  %storemerge3.reg2mem = alloca i64, !insn.addr !1510
  %0 = icmp eq i64 %arg3, 0, !insn.addr !1511
  %1 = icmp eq i1 %0, false, !insn.addr !1512
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1512
  br i1 %1, label %dec_label_pc_4942, label %dec_label_pc_49db, !insn.addr !1512

dec_label_pc_4942:                                ; preds = %dec_label_pc_4919
  %2 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !1513
  %3 = trunc i64 %2 to i8, !insn.addr !1514
  %4 = icmp eq i8 %3, 0, !insn.addr !1514
  %5 = ptrtoint i8* %arg2 to i64
  %6 = ptrtoint i8* %arg1 to i64
  store i64 0, i64* %storemerge3.reg2mem, !insn.addr !1515
  br i1 %4, label %dec_label_pc_49c3, label %dec_label_pc_4955, !insn.addr !1515

dec_label_pc_4955:                                ; preds = %dec_label_pc_4942, %dec_label_pc_49b2
  %storemerge3.reload = load i64, i64* %storemerge3.reg2mem
  %7 = add i64 %storemerge3.reload, %5, !insn.addr !1516
  %8 = add i64 %storemerge3.reload, %6, !insn.addr !1517
  %9 = inttoptr i64 %8 to i8*, !insn.addr !1518
  %10 = inttoptr i64 %7 to i8*, !insn.addr !1518
  %11 = call i64 @_ZNSt11char_traitsIcE2ltERKcS2_(i8* %9, i8* %10), !insn.addr !1518
  %12 = trunc i64 %11 to i8, !insn.addr !1519
  %13 = icmp eq i8 %12, 0, !insn.addr !1519
  store i64 4294967295, i64* %rax.0.reg2mem, !insn.addr !1520
  br i1 %13, label %dec_label_pc_4981, label %dec_label_pc_49db, !insn.addr !1520

dec_label_pc_4981:                                ; preds = %dec_label_pc_4955
  %14 = call i64 @_ZNSt11char_traitsIcE2ltERKcS2_(i8* %10, i8* %9), !insn.addr !1521
  %15 = trunc i64 %14 to i8, !insn.addr !1522
  %16 = icmp eq i8 %15, 0, !insn.addr !1522
  store i64 1, i64* %rax.0.reg2mem, !insn.addr !1523
  br i1 %16, label %dec_label_pc_49b2, label %dec_label_pc_49db, !insn.addr !1523

dec_label_pc_49b2:                                ; preds = %dec_label_pc_4981
  %17 = add nuw i64 %storemerge3.reload, 1, !insn.addr !1524
  %18 = icmp ult i64 %17, %arg3, !insn.addr !1525
  store i64 %17, i64* %storemerge3.reg2mem, !insn.addr !1526
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1526
  br i1 %18, label %dec_label_pc_4955, label %dec_label_pc_49db, !insn.addr !1526

dec_label_pc_49c3:                                ; preds = %dec_label_pc_4942
  %19 = call i64 @memcmp(i64 %6, i64 %5, i64 %arg3), !insn.addr !1527
  store i64 %19, i64* %rax.0.reg2mem, !insn.addr !1528
  br label %dec_label_pc_49db, !insn.addr !1528

dec_label_pc_49db:                                ; preds = %dec_label_pc_4955, %dec_label_pc_4981, %dec_label_pc_49b2, %dec_label_pc_4919, %dec_label_pc_49c3
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1529

; uselistorder directives
  uselistorder i64 %storemerge3.reload, { 0, 2, 1 }
  uselistorder i64 %6, { 1, 0 }
  uselistorder i64 %5, { 1, 0 }
  uselistorder i64* %storemerge3.reg2mem, { 2, 0, 1 }
  uselistorder i64* %rax.0.reg2mem, { 0, 5, 3, 2, 1, 4 }
  uselistorder i64 (i8*, i8*)* @_ZNSt11char_traitsIcE2ltERKcS2_, { 1, 0 }
  uselistorder i64 %arg3, { 1, 0, 2 }
  uselistorder label %dec_label_pc_49db, { 4, 2, 1, 0, 3 }
  uselistorder label %dec_label_pc_4955, { 1, 0 }
}

define i64 @_ZNSt11char_traitsIcE6lengthEPKc(i8* %arg1) local_unnamed_addr {
dec_label_pc_49dd:
  %storemerge.reg2mem = alloca i64, !insn.addr !1530
  %0 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !1531
  %1 = trunc i64 %0 to i8, !insn.addr !1532
  %2 = icmp eq i8 %1, 0, !insn.addr !1532
  br i1 %2, label %dec_label_pc_4a04, label %dec_label_pc_49f6, !insn.addr !1533

dec_label_pc_49f6:                                ; preds = %dec_label_pc_49dd
  %3 = call i64 @_ZN9__gnu_cxx11char_traitsIcE6lengthEPKc(i8* %arg1), !insn.addr !1534
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !1535
  br label %dec_label_pc_4a11, !insn.addr !1535

dec_label_pc_4a04:                                ; preds = %dec_label_pc_49dd
  %4 = ptrtoint i8* %arg1 to i64, !insn.addr !1536
  %5 = call i64 @strlen(i64 %4), !insn.addr !1537
  store i64 %5, i64* %storemerge.reg2mem, !insn.addr !1538
  br label %dec_label_pc_4a11, !insn.addr !1538

dec_label_pc_4a11:                                ; preds = %dec_label_pc_4a04, %dec_label_pc_49f6
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1539

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZNSt11char_traitsIcE4findEPKcmRS1_(i8* %arg1, i64 %arg2, i8* %arg3) local_unnamed_addr {
dec_label_pc_4a13:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !1540
  %1 = load i64, i64* %0
  %2 = icmp eq i64 %arg2, 0, !insn.addr !1541
  %3 = icmp eq i1 %2, false, !insn.addr !1542
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1542
  br i1 %3, label %dec_label_pc_4a39, label %dec_label_pc_4a78, !insn.addr !1542

dec_label_pc_4a39:                                ; preds = %dec_label_pc_4a13
  %4 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !1543
  %5 = trunc i64 %4 to i8, !insn.addr !1544
  %6 = icmp eq i8 %5, 0, !insn.addr !1544
  br i1 %6, label %dec_label_pc_4a5b, label %dec_label_pc_4a42, !insn.addr !1545

dec_label_pc_4a42:                                ; preds = %dec_label_pc_4a39
  %7 = call i64 @_ZN9__gnu_cxx11char_traitsIcE4findEPKcmRS2_(i8* %arg1, i64 %arg2, i8* %arg3), !insn.addr !1546
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !1547
  br label %dec_label_pc_4a78, !insn.addr !1547

dec_label_pc_4a5b:                                ; preds = %dec_label_pc_4a39
  %sext = mul i64 %1, 72057594037927936
  %8 = ashr exact i64 %sext, 56, !insn.addr !1548
  %9 = ptrtoint i8* %arg1 to i64, !insn.addr !1549
  %10 = and i64 %8, 4294967295, !insn.addr !1550
  %11 = call i64 @memchr(i64 %9, i64 %10, i64 %arg2, i64 %8), !insn.addr !1551
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !1552
  br label %dec_label_pc_4a78, !insn.addr !1552

dec_label_pc_4a78:                                ; preds = %dec_label_pc_4a13, %dec_label_pc_4a5b, %dec_label_pc_4a42
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1553

; uselistorder directives
  uselistorder i64* %rax.0.reg2mem, { 0, 3, 2, 1 }
  uselistorder i64 %arg2, { 1, 0, 2 }
  uselistorder i8* %arg1, { 1, 0 }
  uselistorder label %dec_label_pc_4a78, { 1, 2, 0 }
}

define i64 @_ZnwmPv(i64 %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_4a7a:
  %0 = ptrtoint i64* %arg2 to i64
  ret i64 %0, !insn.addr !1554
}

define i64 @_ZN4llvm14DebugEpochBase14incrementEpochEv(i64* %result) local_unnamed_addr {
dec_label_pc_4a9c:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !1555
}

define i64 @_ZN4llvm14DebugEpochBase10HandleBaseC1EPKS0_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_4aac:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !1556
}

define i64 @_ZNK4llvm14DebugEpochBase10HandleBase14isHandleInSyncEv(i64* %result) local_unnamed_addr {
dec_label_pc_4ac0:
  ret i64 1, !insn.addr !1557
}

define i64 @_ZNK4llvm14DebugEpochBase10HandleBase15getEpochAddressEv(i64* %result) local_unnamed_addr {
dec_label_pc_4ad4:
  ret i64 0, !insn.addr !1558
}

define i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result) local_unnamed_addr {
dec_label_pc_8650:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1559
}

define i64 @_ZNKSt9_Any_data9_M_accessEv(i64* %result) local_unnamed_addr {
dec_label_pc_8662:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1560
}

define i64 @_ZNSt14_Function_baseD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_8674:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !1561
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1561
  %3 = load i64, i64* %2, align 8, !insn.addr !1561
  %4 = icmp eq i64 %3, 0, !insn.addr !1562
  %spec.select = select i1 %4, i64 0, i64 %0
  ret i64 %spec.select, !insn.addr !1563
}

define i64 @_ZNKSt14_Function_base8_M_emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_86b2:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !1564
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1564
  %3 = load i64, i64* %2, align 8, !insn.addr !1564
  %4 = icmp eq i64 %3, 0, !insn.addr !1565
  %5 = zext i1 %4 to i64, !insn.addr !1566
  %6 = and i64 %3, -256, !insn.addr !1566
  %7 = or i64 %6, %5, !insn.addr !1566
  ret i64 %7, !insn.addr !1567

; uselistorder directives
  uselistorder i64 %3, { 1, 0 }
}

define i64* @_ZSt3minImERKT_S2_S2_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_86ce:
  %0 = icmp ult i64* %arg2, %arg1, !insn.addr !1568
  %1 = icmp eq i1 %0, false, !insn.addr !1569
  %storemerge.v = select i1 %1, i64* %arg1, i64* %arg2
  ret i64* %storemerge.v, !insn.addr !1570
}

define i64 @_ZN4llvm12Log2_32_CeilEj(i32 %arg1) local_unnamed_addr {
dec_label_pc_86fd:
  %0 = add i32 %arg1, -1, !insn.addr !1571
  %1 = call i32 @_ZN4llvm11countl_zeroIjEEiT_(i32 %0), !insn.addr !1572
  %2 = sub i32 32, %1, !insn.addr !1573
  %3 = zext i32 %2 to i64, !insn.addr !1574
  ret i64 %3, !insn.addr !1575
}

define i64 @_ZN4llvm12NextPowerOf2Em(i64 %arg1) local_unnamed_addr {
dec_label_pc_8724:
  %0 = udiv i64 %arg1, 2, !insn.addr !1576
  %1 = or i64 %0, %arg1, !insn.addr !1577
  %2 = udiv i64 %1, 4, !insn.addr !1578
  %3 = or i64 %2, %1, !insn.addr !1579
  %4 = udiv i64 %3, 16, !insn.addr !1580
  %5 = or i64 %4, %3, !insn.addr !1581
  %6 = udiv i64 %5, 256, !insn.addr !1582
  %7 = or i64 %6, %5, !insn.addr !1583
  %8 = udiv i64 %7, 65536, !insn.addr !1584
  %9 = or i64 %8, %7, !insn.addr !1585
  %10 = udiv i64 %9, 4294967296, !insn.addr !1586
  %11 = or i64 %10, %9, !insn.addr !1587
  %12 = add i64 %11, 1, !insn.addr !1588
  ret i64 %12, !insn.addr !1589

; uselistorder directives
  uselistorder i64 %9, { 1, 0 }
  uselistorder i64 %7, { 1, 0 }
  uselistorder i64 %5, { 1, 0 }
  uselistorder i64 %3, { 1, 0 }
  uselistorder i64 %1, { 1, 0 }
  uselistorder i64 %arg1, { 1, 0 }
}

define i64 @_ZN4llvm21PointerLikeTypeTraitsIPvE16getAsVoidPointerES1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_8781:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !1590
}

define i64 @_ZN4llvm9StringRef13compareMemoryEPKcS2_m(i8* %arg1, i8* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_8793:
  %storemerge.reg2mem = alloca i64, !insn.addr !1591
  %0 = icmp eq i64 %arg3, 0, !insn.addr !1592
  %1 = icmp eq i1 %0, false, !insn.addr !1593
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1593
  br i1 %1, label %dec_label_pc_87b9, label %dec_label_pc_87d1, !insn.addr !1593

dec_label_pc_87b9:                                ; preds = %dec_label_pc_8793
  %2 = ptrtoint i8* %arg2 to i64, !insn.addr !1594
  %3 = ptrtoint i8* %arg1 to i64, !insn.addr !1595
  %4 = call i64 @memcmp(i64 %3, i64 %2, i64 %arg3), !insn.addr !1596
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !1597
  br label %dec_label_pc_87d1, !insn.addr !1597

dec_label_pc_87d1:                                ; preds = %dec_label_pc_8793, %dec_label_pc_87b9
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1598

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_87d1, { 1, 0 }
}

define i64 @_ZN4llvm9StringRefC1EPKc(i64* %result, i8* %arg2) local_unnamed_addr {
dec_label_pc_87d4:
  %storemerge.reg2mem = alloca i64, !insn.addr !1599
  %0 = ptrtoint i8* %arg2 to i64, !insn.addr !1600
  store i64 %0, i64* %result, align 8, !insn.addr !1601
  %1 = icmp eq i8* %arg2, null, !insn.addr !1602
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1603
  br i1 %1, label %dec_label_pc_880d, label %dec_label_pc_87fa, !insn.addr !1603

dec_label_pc_87fa:                                ; preds = %dec_label_pc_87d4
  %2 = call i64 @_ZNSt11char_traitsIcE6lengthEPKc(i8* nonnull %arg2), !insn.addr !1604
  store i64 %2, i64* %storemerge.reg2mem, !insn.addr !1605
  br label %dec_label_pc_880d, !insn.addr !1605

dec_label_pc_880d:                                ; preds = %dec_label_pc_87d4, %dec_label_pc_87fa
  %3 = ptrtoint i64* %result to i64
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %4 = add i64 %3, 8, !insn.addr !1606
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1606
  store i64 %storemerge.reload, i64* %5, align 8, !insn.addr !1606
  ret i64 %storemerge.reload, !insn.addr !1607

; uselistorder directives
  uselistorder i64 %storemerge.reload, { 1, 0 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %result, { 1, 0 }
  uselistorder label %dec_label_pc_880d, { 1, 0 }
}

define i64 @_ZN4llvm9StringRefC1EPKcm(i64* %result, i8* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_8818:
  %0 = ptrtoint i8* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !1608
  %2 = add i64 %1, 8, !insn.addr !1609
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1609
  store i64 %arg3, i64* %3, align 8, !insn.addr !1609
  ret i64 %1, !insn.addr !1610

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64 @_ZN4llvm9StringRefC1ERKNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_8846:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4dataEv(i64* %arg2), !insn.addr !1611
  store i64 %1, i64* %result, align 8, !insn.addr !1612
  %2 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv(i64* %arg2), !insn.addr !1613
  %3 = add i64 %0, 8, !insn.addr !1614
  %4 = inttoptr i64 %3 to i64*, !insn.addr !1614
  store i64 %2, i64* %4, align 8, !insn.addr !1614
  ret i64 %2, !insn.addr !1615

; uselistorder directives
  uselistorder i64 %2, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef4dataEv(i64* %result) local_unnamed_addr {
dec_label_pc_8884:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1616
}

define i64 @_ZNK4llvm9StringRef5emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_889a:
  %0 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1617
  %1 = icmp eq i64 %0, 0, !insn.addr !1618
  %2 = zext i1 %1 to i64, !insn.addr !1619
  %3 = and i64 %0, -256, !insn.addr !1619
  %4 = or i64 %3, %2, !insn.addr !1619
  ret i64 %4, !insn.addr !1620

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result) local_unnamed_addr {
dec_label_pc_88be:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !1621
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1621
  %3 = load i64, i64* %2, align 8, !insn.addr !1621
  ret i64 %3, !insn.addr !1622
}

define i64 @_ZNK4llvm9StringRef3strB5cxx11Ev(i64* %this, i64* %result) local_unnamed_addr {
dec_label_pc_88d4:
  %stack_var_-41 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1623
  %1 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %result), !insn.addr !1624
  %2 = icmp eq i64 %1, 0, !insn.addr !1625
  %3 = icmp eq i1 %2, false, !insn.addr !1626
  br i1 %3, label %dec_label_pc_891c, label %dec_label_pc_890e, !insn.addr !1627

dec_label_pc_890e:                                ; preds = %dec_label_pc_88d4
  %4 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(i64* %this), !insn.addr !1628
  br label %dec_label_pc_8967, !insn.addr !1629

dec_label_pc_891c:                                ; preds = %dec_label_pc_88d4
  %5 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1630
  %6 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %result), !insn.addr !1631
  %7 = inttoptr i64 %6 to i8*, !insn.addr !1632
  %8 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EPKcmRKS3_(i64* %this, i8* %7, i64 %5, i64* nonnull %stack_var_-41), !insn.addr !1632
  %9 = call i64 @_ZNSt15__new_allocatorIcED1Ev(i64* nonnull %stack_var_-41), !insn.addr !1633
  br label %dec_label_pc_8967, !insn.addr !1634

dec_label_pc_8967:                                ; preds = %dec_label_pc_891c, %dec_label_pc_890e
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !1635
  %11 = icmp eq i64 %0, %10, !insn.addr !1635
  br i1 %11, label %dec_label_pc_897b, label %dec_label_pc_8976, !insn.addr !1636

dec_label_pc_8976:                                ; preds = %dec_label_pc_8967
  %12 = call i64 @__stack_chk_fail(), !insn.addr !1637
  br label %dec_label_pc_897b, !insn.addr !1637

dec_label_pc_897b:                                ; preds = %dec_label_pc_8976, %dec_label_pc_8967
  %13 = ptrtoint i64* %this to i64
  ret i64 %13, !insn.addr !1638

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNSt15__new_allocatorIcED1Ev, { 4, 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev, { 2, 1, 0 }
  uselistorder i64* %this, { 2, 0, 1 }
}

define i64 @_ZNK4llvm9StringRefcvSt17basic_string_viewIcSt11char_traitsIcEEEv(i64* %result) local_unnamed_addr {
dec_label_pc_8986:
  %rax.0.reg2mem = alloca i64, !insn.addr !1639
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1640
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1641
  %2 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %result), !insn.addr !1642
  %3 = inttoptr i64 %2 to i8*, !insn.addr !1643
  %4 = call i64 @_ZNSt17basic_string_viewIcSt11char_traitsIcEEC1EPKcm(i64* nonnull %stack_var_-56, i8* %3, i64 %1), !insn.addr !1643
  %5 = load i64, i64* %stack_var_-56, align 8, !insn.addr !1644
  %6 = call i64 @__readfsqword(i64 40), !insn.addr !1645
  %7 = icmp eq i64 %0, %6, !insn.addr !1645
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !1646
  br i1 %7, label %dec_label_pc_89f2, label %dec_label_pc_89ed, !insn.addr !1646

dec_label_pc_89ed:                                ; preds = %dec_label_pc_8986
  %8 = call i64 @__stack_chk_fail(), !insn.addr !1647
  store i64 %8, i64* %rax.0.reg2mem, !insn.addr !1647
  br label %dec_label_pc_89f2, !insn.addr !1647

dec_label_pc_89f2:                                ; preds = %dec_label_pc_89ed, %dec_label_pc_8986
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1648

; uselistorder directives
  uselistorder i64* %stack_var_-56, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef11starts_withES0_(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_89f8:
  %storemerge.reg2mem = alloca i64, !insn.addr !1649
  %0 = ptrtoint i64* %result to i64
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-56, align 8, !insn.addr !1650
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %this), !insn.addr !1651
  %2 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !1652
  %3 = icmp ult i64 %1, %2, !insn.addr !1653
  br i1 %3, label %dec_label_pc_8a82, label %dec_label_pc_8a3f, !insn.addr !1654

dec_label_pc_8a3f:                                ; preds = %dec_label_pc_89f8
  %4 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !1655
  %5 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !1656
  %6 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %this), !insn.addr !1657
  %7 = inttoptr i64 %6 to i8*, !insn.addr !1658
  %8 = inttoptr i64 %5 to i8*, !insn.addr !1658
  %9 = call i64 @_ZN4llvm9StringRef13compareMemoryEPKcS2_m(i8* %7, i8* %8, i64 %4), !insn.addr !1658
  %10 = trunc i64 %9 to i32, !insn.addr !1659
  %11 = icmp eq i32 %10, 0, !insn.addr !1659
  %12 = icmp eq i1 %11, false, !insn.addr !1660
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !1660
  br i1 %12, label %dec_label_pc_8a82, label %dec_label_pc_8a87, !insn.addr !1660

dec_label_pc_8a82:                                ; preds = %dec_label_pc_8a3f, %dec_label_pc_89f8
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1661
  br label %dec_label_pc_8a87, !insn.addr !1661

dec_label_pc_8a87:                                ; preds = %dec_label_pc_8a3f, %dec_label_pc_8a82
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1662

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_8a87, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef4findEcm(i64* %result, i8 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_8a90:
  %rax.0.reg2mem = alloca i64, !insn.addr !1663
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1664
  %1 = call i64 @_ZNK4llvm9StringRefcvSt17basic_string_viewIcSt11char_traitsIcEEEv(i64* %result), !insn.addr !1665
  store i64 %1, i64* %stack_var_-40, align 8, !insn.addr !1666
  %2 = call i64 @_ZNKSt17basic_string_viewIcSt11char_traitsIcEE4findEcm(i64* nonnull %stack_var_-40, i8 %arg2, i64 %arg3), !insn.addr !1667
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !1668
  %4 = icmp eq i64 %0, %3, !insn.addr !1668
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !1669
  br i1 %4, label %dec_label_pc_8af6, label %dec_label_pc_8af1, !insn.addr !1669

dec_label_pc_8af1:                                ; preds = %dec_label_pc_8a90
  %5 = call i64 @__stack_chk_fail(), !insn.addr !1670
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !1670
  br label %dec_label_pc_8af6, !insn.addr !1670

dec_label_pc_8af6:                                ; preds = %dec_label_pc_8af1, %dec_label_pc_8a90
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1671
}

define i64 @_ZNK4llvm9StringRef6substrEmm(i64* %result, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_8af8:
  %rax.0.reg2mem = alloca i64, !insn.addr !1672
  %stack_var_-64 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-96 = alloca i64, align 8
  %stack_var_-88 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-88, align 8, !insn.addr !1673
  store i64 %arg3, i64* %stack_var_-96, align 8, !insn.addr !1674
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1675
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1676
  store i64 %1, i64* %stack_var_-56, align 8, !insn.addr !1677
  %2 = call i64* @_ZSt3minImERKT_S2_S2_(i64* nonnull %stack_var_-88, i64* nonnull %stack_var_-56), !insn.addr !1678
  %3 = load i64, i64* %2, align 8, !insn.addr !1679
  store i64 %3, i64* %stack_var_-88, align 8, !insn.addr !1680
  %4 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1681
  %5 = load i64, i64* %stack_var_-88, align 8, !insn.addr !1682
  %6 = sub i64 %4, %5, !insn.addr !1683
  store i64 %6, i64* %stack_var_-64, align 8, !insn.addr !1684
  %7 = call i64* @_ZSt3minImERKT_S2_S2_(i64* nonnull %stack_var_-96, i64* nonnull %stack_var_-64), !insn.addr !1685
  %8 = load i64, i64* %7, align 8, !insn.addr !1686
  %9 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %result), !insn.addr !1687
  %10 = load i64, i64* %stack_var_-88, align 8, !insn.addr !1688
  %11 = add i64 %10, %9, !insn.addr !1689
  %12 = inttoptr i64 %11 to i8*, !insn.addr !1690
  %13 = call i64 @_ZN4llvm9StringRefC1EPKcm(i64* nonnull %stack_var_-56, i8* %12, i64 %8), !insn.addr !1690
  %14 = load i64, i64* %stack_var_-56, align 8, !insn.addr !1691
  %15 = call i64 @__readfsqword(i64 40), !insn.addr !1692
  %16 = icmp eq i64 %0, %15, !insn.addr !1692
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !1693
  br i1 %16, label %dec_label_pc_8bbc, label %dec_label_pc_8bb7, !insn.addr !1693

dec_label_pc_8bb7:                                ; preds = %dec_label_pc_8af8
  %17 = call i64 @__stack_chk_fail(), !insn.addr !1694
  store i64 %17, i64* %rax.0.reg2mem, !insn.addr !1694
  br label %dec_label_pc_8bbc, !insn.addr !1694

dec_label_pc_8bbc:                                ; preds = %dec_label_pc_8bb7, %dec_label_pc_8af8
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1695

; uselistorder directives
  uselistorder i64* %stack_var_-88, { 1, 2, 3, 0, 4 }
  uselistorder i64* %stack_var_-56, { 2, 0, 1, 3 }
}

define i64 @_ZNK4llvm9StringRef10take_frontEm(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_8bc2:
  %storemerge.reg2mem = alloca i64, !insn.addr !1696
  %0 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1697
  %1 = icmp ugt i64 %0, %arg2, !insn.addr !1698
  %2 = icmp eq i1 %1, false, !insn.addr !1699
  %3 = icmp eq i1 %2, false, !insn.addr !1700
  br i1 %3, label %dec_label_pc_8bfa, label %dec_label_pc_8bed, !insn.addr !1701

dec_label_pc_8bed:                                ; preds = %dec_label_pc_8bc2
  %4 = ptrtoint i64* %result to i64
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !1702
  br label %dec_label_pc_8c1d, !insn.addr !1702

dec_label_pc_8bfa:                                ; preds = %dec_label_pc_8bc2
  %5 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1703
  %6 = sub i64 %5, %arg2, !insn.addr !1704
  %7 = call i64 @_ZNK4llvm9StringRef9drop_backEm(i64* %result, i64 %6), !insn.addr !1705
  store i64 %7, i64* %storemerge.reg2mem, !insn.addr !1706
  br label %dec_label_pc_8c1d, !insn.addr !1706

dec_label_pc_8c1d:                                ; preds = %dec_label_pc_8bfa, %dec_label_pc_8bed
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1707

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %result, { 0, 1, 3, 2 }
}

define i64 @_ZNK4llvm9StringRef9drop_backEm(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_8c20:
  %0 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1708
  %1 = icmp ult i64 %0, %arg2, !insn.addr !1709
  %2 = icmp eq i1 %1, false, !insn.addr !1710
  br i1 %2, label %dec_label_pc_8c6e, label %dec_label_pc_8c46, !insn.addr !1710

dec_label_pc_8c46:                                ; preds = %dec_label_pc_8c20
  %3 = call i64 @__assert_fail(i64 ptrtoint ([51 x i8]* @global_var_4d54 to i64), i64 ptrtoint ([42 x i8]* @global_var_4d24 to i64), i64 625, i64 ptrtoint ([57 x i8]* @global_var_4ce4 to i64)), !insn.addr !1711
  br label %dec_label_pc_8c6e, !insn.addr !1711

dec_label_pc_8c6e:                                ; preds = %dec_label_pc_8c46, %dec_label_pc_8c20
  %4 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1712
  %5 = sub i64 %4, %arg2, !insn.addr !1713
  %6 = call i64 @_ZNK4llvm9StringRef6substrEmm(i64* %result, i64 0, i64 %5), !insn.addr !1714
  ret i64 %6, !insn.addr !1715
}

define i64 @_ZN4llvm9StringRef13consume_frontES0_(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_8c94:
  %storemerge.reg2mem = alloca i64, !insn.addr !1716
  %0 = ptrtoint i64* %result to i64
  %stack_var_-40 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-40, align 8, !insn.addr !1717
  %1 = call i64 @_ZNK4llvm9StringRef11starts_withES0_(i64* %this, i64* %result, i64 %arg3), !insn.addr !1718
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !1719
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1720
  br i1 %3, label %dec_label_pc_8cdd, label %dec_label_pc_8d12, !insn.addr !1720

dec_label_pc_8cdd:                                ; preds = %dec_label_pc_8c94
  %4 = ptrtoint i64* %this to i64
  %5 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-40), !insn.addr !1721
  %6 = call i64 @_ZNK4llvm9StringRef6substrEmm(i64* %this, i64 %5, i64 -1), !insn.addr !1722
  store i64 %6, i64* %this, align 8, !insn.addr !1723
  %7 = add i64 %4, 8, !insn.addr !1724
  %8 = inttoptr i64 %7 to i64*, !insn.addr !1724
  store i64 -1, i64* %8, align 8, !insn.addr !1724
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !1725
  br label %dec_label_pc_8d12, !insn.addr !1725

dec_label_pc_8d12:                                ; preds = %dec_label_pc_8c94, %dec_label_pc_8cdd
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1726

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*, i64, i64)* @_ZNK4llvm9StringRef6substrEmm, { 1, 0 }
  uselistorder i64* %this, { 0, 1, 3, 2 }
  uselistorder label %dec_label_pc_8d12, { 1, 0 }
}

define i64 @_ZNK4llvm9StringRef5sliceEmm(i64* %result, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_8d14:
  %rax.0.reg2mem = alloca i64, !insn.addr !1727
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-80 = alloca i64, align 8
  %stack_var_-72 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-72, align 8, !insn.addr !1728
  store i64 %arg3, i64* %stack_var_-80, align 8, !insn.addr !1729
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !1730
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1731
  store i64 %1, i64* %stack_var_-56, align 8, !insn.addr !1732
  %2 = call i64* @_ZSt3minImERKT_S2_S2_(i64* nonnull %stack_var_-72, i64* nonnull %stack_var_-56), !insn.addr !1733
  %3 = load i64, i64* %2, align 8, !insn.addr !1734
  store i64 %3, i64* %stack_var_-72, align 8, !insn.addr !1735
  %4 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %result), !insn.addr !1736
  store i64 %4, i64* %stack_var_-56, align 8, !insn.addr !1737
  %5 = call i64* @_ZSt5clampImERKT_S2_S2_S2_(i64* nonnull %stack_var_-80, i64* nonnull %stack_var_-72, i64* nonnull %stack_var_-56), !insn.addr !1738
  %6 = load i64, i64* %5, align 8, !insn.addr !1739
  store i64 %6, i64* %stack_var_-80, align 8, !insn.addr !1740
  %7 = load i64, i64* %stack_var_-72, align 8, !insn.addr !1741
  %8 = sub i64 %6, %7, !insn.addr !1742
  %9 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %result), !insn.addr !1743
  %10 = load i64, i64* %stack_var_-72, align 8, !insn.addr !1744
  %11 = add i64 %10, %9, !insn.addr !1745
  %12 = inttoptr i64 %11 to i8*, !insn.addr !1746
  %13 = call i64 @_ZN4llvm9StringRefC1EPKcm(i64* nonnull %stack_var_-56, i8* %12, i64 %8), !insn.addr !1746
  %14 = load i64, i64* %stack_var_-56, align 8, !insn.addr !1747
  %15 = call i64 @__readfsqword(i64 40), !insn.addr !1748
  %16 = icmp eq i64 %0, %15, !insn.addr !1748
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !1749
  br i1 %16, label %dec_label_pc_8de4, label %dec_label_pc_8ddf, !insn.addr !1749

dec_label_pc_8ddf:                                ; preds = %dec_label_pc_8d14
  %17 = call i64 @__stack_chk_fail(), !insn.addr !1750
  store i64 %17, i64* %rax.0.reg2mem, !insn.addr !1750
  br label %dec_label_pc_8de4, !insn.addr !1750

dec_label_pc_8de4:                                ; preds = %dec_label_pc_8ddf, %dec_label_pc_8d14
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1751

; uselistorder directives
  uselistorder i64* %stack_var_-72, { 2, 3, 0, 4, 1, 5 }
  uselistorder i64* %stack_var_-80, { 1, 0, 2 }
  uselistorder i64* %stack_var_-56, { 3, 0, 1, 4, 2, 5 }
  uselistorder i64 (i64*, i8*, i64)* @_ZN4llvm9StringRefC1EPKcm, { 1, 0 }
}

define i64 @_ZN4llvmeqENS_9StringRefES0_(i64* %this, i64* %result, i64 %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_8dea:
  %rax.0.reg2mem = alloca i64, !insn.addr !1752
  %0 = ptrtoint i64* %this to i64
  %stack_var_-40 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-40, align 8, !insn.addr !1753
  store i64 %arg3, i64* %stack_var_-56, align 8, !insn.addr !1754
  %1 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-40), !insn.addr !1755
  %2 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !1756
  %3 = icmp eq i64 %1, %2, !insn.addr !1757
  %4 = icmp eq i1 %3, false, !insn.addr !1758
  %5 = icmp eq i1 %4, false, !insn.addr !1759
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1760
  br i1 %5, label %dec_label_pc_8e44, label %dec_label_pc_8e98, !insn.addr !1760

dec_label_pc_8e44:                                ; preds = %dec_label_pc_8dea
  %6 = call i64 @_ZNK4llvm9StringRef5emptyEv(i64* nonnull %stack_var_-40), !insn.addr !1761
  %7 = trunc i64 %6 to i8, !insn.addr !1762
  %8 = icmp eq i8 %7, 0, !insn.addr !1762
  store i64 1, i64* %rax.0.reg2mem, !insn.addr !1763
  br i1 %8, label %dec_label_pc_8e5b, label %dec_label_pc_8e98, !insn.addr !1763

dec_label_pc_8e5b:                                ; preds = %dec_label_pc_8e44
  %9 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-40), !insn.addr !1764
  %10 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !1765
  %11 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-40), !insn.addr !1766
  %12 = call i64 @memcmp(i64 %11, i64 %10, i64 %9), !insn.addr !1767
  %13 = trunc i64 %12 to i32, !insn.addr !1768
  %14 = icmp eq i32 %13, 0, !insn.addr !1768
  %15 = zext i1 %14 to i64, !insn.addr !1769
  %16 = and i64 %12, -256, !insn.addr !1769
  %17 = or i64 %16, %15, !insn.addr !1769
  store i64 %17, i64* %rax.0.reg2mem, !insn.addr !1769
  br label %dec_label_pc_8e98, !insn.addr !1769

dec_label_pc_8e98:                                ; preds = %dec_label_pc_8e44, %dec_label_pc_8dea, %dec_label_pc_8e5b
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1770

; uselistorder directives
  uselistorder i64 %12, { 1, 0 }
  uselistorder i64* %rax.0.reg2mem, { 0, 3, 1, 2 }
  uselistorder i64 (i64, i64, i64)* @memcmp, { 1, 2, 0 }
  uselistorder label %dec_label_pc_8e98, { 2, 0, 1 }
}

define i64 @_ZN4llvm11raw_ostreamlsENS_9StringRefE(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_8ea2:
  %storemerge.reg2mem = alloca i64, !insn.addr !1771
  %0 = ptrtoint i64* %result to i64
  %1 = ptrtoint i64* %this to i64
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-56, align 8, !insn.addr !1772
  %2 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* nonnull %stack_var_-56), !insn.addr !1773
  %3 = add i64 %1, 24, !insn.addr !1774
  %4 = inttoptr i64 %3 to i64*, !insn.addr !1774
  %5 = load i64, i64* %4, align 8, !insn.addr !1774
  %6 = add i64 %1, 32, !insn.addr !1775
  %7 = inttoptr i64 %6 to i64*, !insn.addr !1775
  %8 = load i64, i64* %7, align 8, !insn.addr !1775
  %9 = sub i64 %5, %8, !insn.addr !1776
  %10 = icmp ult i64 %9, %2, !insn.addr !1777
  %11 = icmp eq i1 %10, false, !insn.addr !1778
  br i1 %11, label %dec_label_pc_8f16, label %dec_label_pc_8ef2, !insn.addr !1778

dec_label_pc_8ef2:                                ; preds = %dec_label_pc_8ea2
  %12 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !1779
  %13 = inttoptr i64 %12 to i8*, !insn.addr !1780
  %14 = call i64 @_ZN4llvm11raw_ostream5writeEPKcm(i64* %this, i8* %13, i64 %2), !insn.addr !1780
  store i64 %14, i64* %storemerge.reg2mem, !insn.addr !1781
  br label %dec_label_pc_8f5e, !insn.addr !1781

dec_label_pc_8f16:                                ; preds = %dec_label_pc_8ea2
  %15 = icmp eq i64 %2, 0, !insn.addr !1782
  store i64 %1, i64* %storemerge.reg2mem, !insn.addr !1783
  br i1 %15, label %dec_label_pc_8f5e, label %dec_label_pc_8f1d, !insn.addr !1783

dec_label_pc_8f1d:                                ; preds = %dec_label_pc_8f16
  %16 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* nonnull %stack_var_-56), !insn.addr !1784
  %17 = load i64, i64* %7, align 8, !insn.addr !1785
  %18 = call i64 @memcpy(i64 %17, i64 %16, i64 %2), !insn.addr !1786
  %19 = load i64, i64* %7, align 8, !insn.addr !1787
  %20 = add i64 %19, %2, !insn.addr !1788
  store i64 %20, i64* %7, align 8, !insn.addr !1789
  store i64 %1, i64* %storemerge.reg2mem, !insn.addr !1789
  br label %dec_label_pc_8f5e, !insn.addr !1789

dec_label_pc_8f5e:                                ; preds = %dec_label_pc_8f16, %dec_label_pc_8f1d, %dec_label_pc_8ef2
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1790

; uselistorder directives
  uselistorder i64* %7, { 0, 2, 1, 3 }
  uselistorder i64 %2, { 0, 2, 3, 1, 4 }
  uselistorder i64 %1, { 1, 0, 2, 3 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1, 3 }
  uselistorder label %dec_label_pc_8f5e, { 1, 0, 2 }
}

define i64 @_ZN4llvm11raw_ostreamlsEPKc(i64* %result, i8* %arg2) local_unnamed_addr {
dec_label_pc_8f60:
  %0 = alloca i64
  %rax.0.reg2mem = alloca i64, !insn.addr !1791
  %1 = load i64, i64* %0
  %stack_var_-40 = alloca i64, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !1792
  %3 = call i64 @_ZN4llvm9StringRefC1EPKc(i64* nonnull %stack_var_-40, i8* %arg2), !insn.addr !1793
  %4 = load i64, i64* %stack_var_-40, align 8, !insn.addr !1794
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1795
  %6 = call i64 @_ZN4llvm11raw_ostreamlsENS_9StringRefE(i64* %result, i64* %5, i64 %1), !insn.addr !1795
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !1796
  %8 = icmp eq i64 %2, %7, !insn.addr !1796
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !1797
  br i1 %8, label %dec_label_pc_8fc1, label %dec_label_pc_8fbc, !insn.addr !1797

dec_label_pc_8fbc:                                ; preds = %dec_label_pc_8f60
  %9 = call i64 @__stack_chk_fail(), !insn.addr !1798
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !1798
  br label %dec_label_pc_8fc1, !insn.addr !1798

dec_label_pc_8fc1:                                ; preds = %dec_label_pc_8fbc, %dec_label_pc_8f60
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1799

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 1, 0 }
  uselistorder i64 (i64*, i64*, i64)* @_ZN4llvm11raw_ostreamlsENS_9StringRefE, { 1, 2, 0 }
  uselistorder i64 (i64*, i8*)* @_ZN4llvm9StringRefC1EPKc, { 24, 26, 25, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
}

define i64 @_ZN4llvm11raw_ostreamlsEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_8fc4:
  %0 = zext i32 %arg2 to i64, !insn.addr !1800
  %1 = call i64 @_ZN4llvm11raw_ostreamlsEm(i64* %result, i64 %0), !insn.addr !1801
  ret i64 %1, !insn.addr !1802
}

define i64 @_ZNK4llvm3UsecvPNS_5ValueEEv(i64* %result) local_unnamed_addr {
dec_label_pc_8fec:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1803
}

define i64 @_ZNK4llvm3Use3getEv(i64* %result) local_unnamed_addr {
dec_label_pc_9002:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !1804
}

define i64 @_ZNK4llvm5Value7getTypeEv(i64* %result) local_unnamed_addr {
dec_label_pc_9018:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !1805
  %2 = inttoptr i64 %1 to i64*, !insn.addr !1805
  %3 = load i64, i64* %2, align 8, !insn.addr !1805
  ret i64 %3, !insn.addr !1806
}

define i64 @_ZNK4llvm5Value10getValueIDEv(i64* %result) local_unnamed_addr {
dec_label_pc_902e:
  %0 = alloca i64
  %1 = load i64, i64* %0
  %2 = urem i64 %1, 256, !insn.addr !1807
  ret i64 %2, !insn.addr !1808
}

define i64 @_ZN4llvm5Value17stripPointerCastsEv(i64* %result) local_unnamed_addr {
dec_label_pc_9046:
  %0 = call i64 @_ZNK4llvm5Value17stripPointerCastsEv(i64* %result), !insn.addr !1809
  ret i64 %0, !insn.addr !1810
}

define i64 @_ZNK4llvm5Value24getSubclassDataFromValueEv(i64* %result) local_unnamed_addr {
dec_label_pc_9064:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 2, !insn.addr !1811
  %2 = inttoptr i64 %1 to i16*, !insn.addr !1811
  %3 = load i16, i16* %2, align 2, !insn.addr !1811
  %4 = zext i16 %3 to i64, !insn.addr !1811
  ret i64 %4, !insn.addr !1812
}

define i64 @_ZN4llvm8isa_implINS_11InstructionENS_5ValueEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_907a:
  %0 = call i64 @_ZNK4llvm5Value10getValueIDEv(i64* %arg1), !insn.addr !1813
  %1 = trunc i64 %0 to i32, !insn.addr !1814
  %2 = icmp ult i32 %1, 29
  %3 = icmp ne i1 %2, true, !insn.addr !1815
  %4 = zext i1 %3 to i64, !insn.addr !1815
  %5 = and i64 %0, -256, !insn.addr !1815
  %6 = or i64 %5, %4, !insn.addr !1815
  ret i64 %6, !insn.addr !1816

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm8isa_implINS_8FunctionENS_5ValueEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_909e:
  %0 = call i64 @_ZNK4llvm5Value10getValueIDEv(i64* %arg1), !insn.addr !1817
  %1 = trunc i64 %0 to i32, !insn.addr !1818
  %2 = icmp eq i32 %1, 13, !insn.addr !1818
  %3 = zext i1 %2 to i64, !insn.addr !1819
  %4 = and i64 %0, -256, !insn.addr !1819
  %5 = or i64 %4, %3, !insn.addr !1819
  ret i64 %5, !insn.addr !1820

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm8isa_implINS_11GlobalAliasENS_5ValueEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_90c2:
  %0 = call i64 @_ZNK4llvm5Value10getValueIDEv(i64* %arg1), !insn.addr !1821
  %1 = trunc i64 %0 to i32, !insn.addr !1822
  %2 = icmp eq i32 %1, 14, !insn.addr !1822
  %3 = zext i1 %2 to i64, !insn.addr !1823
  %4 = and i64 %0, -256, !insn.addr !1823
  %5 = or i64 %4, %3, !insn.addr !1823
  ret i64 %5, !insn.addr !1824

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm5TwineC1ENS0_8NodeKindE(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_90e6:
  %rax.0.reg2mem = alloca i64, !insn.addr !1825
  %0 = ptrtoint i64* %result to i64
  %1 = trunc i64 %arg2 to i8, !insn.addr !1826
  %2 = add i64 %0, 32, !insn.addr !1827
  %3 = inttoptr i64 %2 to i8*, !insn.addr !1827
  store i8 %1, i8* %3, align 1, !insn.addr !1827
  %4 = add i64 %0, 33, !insn.addr !1828
  %5 = inttoptr i64 %4 to i8*, !insn.addr !1828
  store i8 1, i8* %5, align 1, !insn.addr !1828
  %6 = call i64 @_ZNK4llvm5Twine9isNullaryEv(i64* %result), !insn.addr !1829
  %7 = trunc i64 %6 to i8, !insn.addr !1830
  %8 = icmp eq i8 %7, 0, !insn.addr !1830
  %9 = icmp eq i1 %8, false, !insn.addr !1831
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !1831
  br i1 %9, label %dec_label_pc_9146, label %dec_label_pc_911e, !insn.addr !1831

dec_label_pc_911e:                                ; preds = %dec_label_pc_90e6
  %10 = call i64 @__assert_fail(i64 ptrtoint ([31 x i8]* @global_var_4e1c to i64), i64 ptrtoint ([38 x i8]* @global_var_4df4 to i64), i64 177, i64 ptrtoint ([29 x i8]* @global_var_4dd0 to i64)), !insn.addr !1832
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !1832
  br label %dec_label_pc_9146, !insn.addr !1832

dec_label_pc_9146:                                ; preds = %dec_label_pc_911e, %dec_label_pc_90e6
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1833
}

define i64 @_ZN4llvm5TwineC1ENS0_5ChildENS0_8NodeKindES1_S2_(i64 %arg1, i64 %arg2, i64 %arg3, i8 %arg4, i64 %arg5, i64 %arg6, i64 %arg7) local_unnamed_addr {
dec_label_pc_914a:
  %rax.0.reg2mem = alloca i64, !insn.addr !1834
  %0 = trunc i64 %arg7 to i8, !insn.addr !1835
  %1 = inttoptr i64 %arg1 to i64*, !insn.addr !1836
  store i64 %arg2, i64* %1, align 8, !insn.addr !1836
  %2 = add i64 %arg1, 8, !insn.addr !1837
  %3 = inttoptr i64 %2 to i64*, !insn.addr !1837
  store i64 %arg3, i64* %3, align 8, !insn.addr !1837
  %4 = add i64 %arg1, 16, !insn.addr !1838
  %5 = inttoptr i64 %4 to i64*, !insn.addr !1838
  store i64 %arg5, i64* %5, align 8, !insn.addr !1838
  %6 = add i64 %arg1, 24, !insn.addr !1839
  %7 = inttoptr i64 %6 to i64*, !insn.addr !1839
  store i64 %arg6, i64* %7, align 8, !insn.addr !1839
  %8 = add i64 %arg1, 32, !insn.addr !1840
  %9 = inttoptr i64 %8 to i8*, !insn.addr !1840
  store i8 %arg4, i8* %9, align 1, !insn.addr !1840
  %10 = add i64 %arg1, 33, !insn.addr !1841
  %11 = inttoptr i64 %10 to i8*, !insn.addr !1841
  store i8 %0, i8* %11, align 1, !insn.addr !1841
  %12 = call i64 @_ZNK4llvm5Twine7isValidEv(i64* %1), !insn.addr !1842
  %13 = trunc i64 %12 to i8, !insn.addr !1843
  %14 = icmp eq i8 %13, 0, !insn.addr !1843
  %15 = icmp eq i1 %14, false, !insn.addr !1844
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !1844
  br i1 %15, label %dec_label_pc_91f5, label %dec_label_pc_91cd, !insn.addr !1844

dec_label_pc_91cd:                                ; preds = %dec_label_pc_914a
  %16 = call i64 @__assert_fail(i64 ptrtoint ([30 x i8]* @global_var_4e71 to i64), i64 ptrtoint ([38 x i8]* @global_var_4df4 to i64), i64 191, i64 ptrtoint ([53 x i8]* @global_var_4e3c to i64)), !insn.addr !1845
  store i64 %16, i64* %rax.0.reg2mem, !insn.addr !1845
  br label %dec_label_pc_91f5, !insn.addr !1845

dec_label_pc_91f5:                                ; preds = %dec_label_pc_91cd, %dec_label_pc_914a
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1846

; uselistorder directives
  uselistorder i64 %arg1, { 0, 1, 3, 2, 5, 4 }
}

define i64 @_ZNK4llvm5Twine6isNullEv(i64* %result) local_unnamed_addr {
dec_label_pc_91f8:
  %0 = call i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %result), !insn.addr !1847
  %1 = trunc i64 %0 to i8, !insn.addr !1848
  %2 = icmp eq i8 %1, 0, !insn.addr !1848
  %3 = zext i1 %2 to i64, !insn.addr !1849
  %4 = and i64 %0, -256, !insn.addr !1849
  %5 = or i64 %4, %3, !insn.addr !1849
  ret i64 %5, !insn.addr !1850

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm5Twine7isEmptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_921c:
  %0 = call i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %result), !insn.addr !1851
  %1 = trunc i64 %0 to i8, !insn.addr !1852
  %2 = icmp eq i8 %1, 1, !insn.addr !1852
  %3 = zext i1 %2 to i64, !insn.addr !1853
  %4 = and i64 %0, -256, !insn.addr !1853
  %5 = or i64 %4, %3, !insn.addr !1853
  ret i64 %5, !insn.addr !1854

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm5Twine9isNullaryEv(i64* %result) local_unnamed_addr {
dec_label_pc_9240:
  %0 = call i64 @_ZNK4llvm5Twine6isNullEv(i64* %result), !insn.addr !1855
  %1 = trunc i64 %0 to i8, !insn.addr !1856
  %2 = icmp eq i8 %1, 0, !insn.addr !1856
  %3 = icmp eq i1 %2, false, !insn.addr !1857
  br i1 %3, label %dec_label_pc_927c, label %dec_label_pc_9260, !insn.addr !1857

dec_label_pc_9260:                                ; preds = %dec_label_pc_9240
  %4 = call i64 @_ZNK4llvm5Twine7isEmptyEv(i64* %result), !insn.addr !1858
  %5 = trunc i64 %4 to i8, !insn.addr !1859
  %6 = icmp ne i8 %5, 0, !insn.addr !1859
  %spec.select = zext i1 %6 to i64
  ret i64 %spec.select

dec_label_pc_927c:                                ; preds = %dec_label_pc_9240
  ret i64 1, !insn.addr !1860
}

define i64 @_ZNK4llvm5Twine7isUnaryEv(i64* %result) local_unnamed_addr {
dec_label_pc_927e:
  %storemerge.reg2mem = alloca i64, !insn.addr !1861
  %0 = call i64 @_ZNK4llvm5Twine10getRHSKindEv(i64* %result), !insn.addr !1862
  %1 = trunc i64 %0 to i8, !insn.addr !1863
  %2 = icmp eq i8 %1, 1, !insn.addr !1863
  %3 = icmp eq i1 %2, false, !insn.addr !1864
  br i1 %3, label %dec_label_pc_92b8, label %dec_label_pc_929e, !insn.addr !1864

dec_label_pc_929e:                                ; preds = %dec_label_pc_927e
  %4 = call i64 @_ZNK4llvm5Twine9isNullaryEv(i64* %result), !insn.addr !1865
  %5 = trunc i64 %4 to i8
  %6 = icmp eq i8 %5, 1, !insn.addr !1866
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !1867
  br i1 %6, label %dec_label_pc_92b8, label %dec_label_pc_92bd, !insn.addr !1867

dec_label_pc_92b8:                                ; preds = %dec_label_pc_929e, %dec_label_pc_927e
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1868
  br label %dec_label_pc_92bd, !insn.addr !1868

dec_label_pc_92bd:                                ; preds = %dec_label_pc_929e, %dec_label_pc_92b8
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1869

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_92bd, { 1, 0 }
}

define i64 @_ZNK4llvm5Twine8isBinaryEv(i64* %result) local_unnamed_addr {
dec_label_pc_92c0:
  %storemerge.reg2mem = alloca i64, !insn.addr !1870
  %0 = call i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %result), !insn.addr !1871
  %1 = trunc i64 %0 to i8, !insn.addr !1872
  %2 = icmp eq i8 %1, 0, !insn.addr !1872
  br i1 %2, label %dec_label_pc_92f7, label %dec_label_pc_92e0, !insn.addr !1873

dec_label_pc_92e0:                                ; preds = %dec_label_pc_92c0
  %3 = call i64 @_ZNK4llvm5Twine10getRHSKindEv(i64* %result), !insn.addr !1874
  %4 = trunc i64 %3 to i8, !insn.addr !1875
  %5 = icmp eq i8 %4, 1, !insn.addr !1875
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !1876
  br i1 %5, label %dec_label_pc_92f7, label %dec_label_pc_92fc, !insn.addr !1876

dec_label_pc_92f7:                                ; preds = %dec_label_pc_92e0, %dec_label_pc_92c0
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !1877
  br label %dec_label_pc_92fc, !insn.addr !1877

dec_label_pc_92fc:                                ; preds = %dec_label_pc_92e0, %dec_label_pc_92f7
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !1878

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_92fc, { 1, 0 }
}

define i64 @_ZNK4llvm5Twine7isValidEv(i64* %result) local_unnamed_addr {
dec_label_pc_92fe:
  %rax.0.reg2mem = alloca i64, !insn.addr !1879
  %0 = call i64 @_ZNK4llvm5Twine9isNullaryEv(i64* %result), !insn.addr !1880
  %1 = trunc i64 %0 to i8, !insn.addr !1881
  %2 = icmp eq i8 %1, 0, !insn.addr !1881
  br i1 %2, label %dec_label_pc_9335, label %dec_label_pc_931e, !insn.addr !1882

dec_label_pc_931e:                                ; preds = %dec_label_pc_92fe
  %3 = call i64 @_ZNK4llvm5Twine10getRHSKindEv(i64* %result), !insn.addr !1883
  %4 = trunc i64 %3 to i8, !insn.addr !1884
  %5 = icmp eq i8 %4, 1, !insn.addr !1884
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1885
  br i1 %5, label %dec_label_pc_9335, label %dec_label_pc_9421, !insn.addr !1885

dec_label_pc_9335:                                ; preds = %dec_label_pc_931e, %dec_label_pc_92fe
  %6 = call i64 @_ZNK4llvm5Twine10getRHSKindEv(i64* %result), !insn.addr !1886
  %7 = trunc i64 %6 to i8, !insn.addr !1887
  %8 = icmp eq i8 %7, 0, !insn.addr !1887
  %9 = icmp eq i1 %8, false, !insn.addr !1888
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1889
  br i1 %9, label %dec_label_pc_9367, label %dec_label_pc_9421, !insn.addr !1889

dec_label_pc_9367:                                ; preds = %dec_label_pc_9335
  %10 = call i64 @_ZNK4llvm5Twine10getRHSKindEv(i64* %result), !insn.addr !1890
  %11 = trunc i64 %10 to i8, !insn.addr !1891
  %12 = icmp eq i8 %11, 1, !insn.addr !1891
  br i1 %12, label %dec_label_pc_938e, label %dec_label_pc_9377, !insn.addr !1892

dec_label_pc_9377:                                ; preds = %dec_label_pc_9367
  %13 = call i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %result), !insn.addr !1893
  %14 = trunc i64 %13 to i8, !insn.addr !1894
  %15 = icmp eq i8 %14, 1, !insn.addr !1894
  %16 = icmp eq i1 %15, false, !insn.addr !1895
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1895
  br i1 %16, label %dec_label_pc_938e, label %dec_label_pc_9421, !insn.addr !1895

dec_label_pc_938e:                                ; preds = %dec_label_pc_9377, %dec_label_pc_9367
  %17 = call i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %result), !insn.addr !1896
  %18 = trunc i64 %17 to i8, !insn.addr !1897
  %19 = icmp eq i8 %18, 2, !insn.addr !1897
  %20 = icmp eq i1 %19, false, !insn.addr !1898
  br i1 %20, label %dec_label_pc_93ce, label %dec_label_pc_93b1, !insn.addr !1898

dec_label_pc_93b1:                                ; preds = %dec_label_pc_938e
  %21 = call i64 @_ZNK4llvm5Twine8isBinaryEv(i64* %result), !insn.addr !1899
  %22 = trunc i64 %21 to i8
  %23 = icmp eq i8 %22, 1, !insn.addr !1900
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1901
  br i1 %23, label %dec_label_pc_93ce, label %dec_label_pc_9421, !insn.addr !1901

dec_label_pc_93ce:                                ; preds = %dec_label_pc_93b1, %dec_label_pc_938e
  %24 = call i64 @_ZNK4llvm5Twine10getRHSKindEv(i64* %result), !insn.addr !1902
  %25 = trunc i64 %24 to i8, !insn.addr !1903
  %26 = icmp eq i8 %25, 2, !insn.addr !1903
  %27 = icmp eq i1 %26, false, !insn.addr !1904
  br i1 %27, label %36, label %dec_label_pc_93ee, !insn.addr !1904

dec_label_pc_93ee:                                ; preds = %dec_label_pc_93ce
  %28 = ptrtoint i64* %result to i64
  %29 = add i64 %28, 16, !insn.addr !1905
  %30 = inttoptr i64 %29 to i64*, !insn.addr !1905
  %31 = load i64, i64* %30, align 8, !insn.addr !1905
  %32 = inttoptr i64 %31 to i64*, !insn.addr !1906
  %33 = call i64 @_ZNK4llvm5Twine8isBinaryEv(i64* %32), !insn.addr !1906
  %34 = trunc i64 %33 to i8
  %35 = icmp eq i8 %34, 1, !insn.addr !1907
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !1908
  br i1 %35, label %36, label %dec_label_pc_9421, !insn.addr !1908

; <label>:36:                                     ; preds = %dec_label_pc_93ce, %dec_label_pc_93ee
  store i64 1, i64* %rax.0.reg2mem
  br label %dec_label_pc_9421

dec_label_pc_9421:                                ; preds = %36, %dec_label_pc_93ee, %dec_label_pc_93b1, %dec_label_pc_9377, %dec_label_pc_9335, %dec_label_pc_931e
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1909

; uselistorder directives
  uselistorder i64* %rax.0.reg2mem, { 0, 2, 1, 3, 4, 5, 6 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine8isBinaryEv, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine10getRHSKindEv, { 3, 2, 1, 0, 4, 5 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine9isNullaryEv, { 0, 2, 1 }
  uselistorder i64* %result, { 8, 0, 1, 2, 3, 4, 5, 6, 7 }
  uselistorder label %36, { 1, 0 }
}

define i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %result) local_unnamed_addr {
dec_label_pc_9424:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !1910
  %2 = inttoptr i64 %1 to i8*, !insn.addr !1910
  %3 = load i8, i8* %2, align 1, !insn.addr !1910
  %4 = zext i8 %3 to i64, !insn.addr !1910
  ret i64 %4, !insn.addr !1911
}

define i64 @_ZNK4llvm5Twine10getRHSKindEv(i64* %result) local_unnamed_addr {
dec_label_pc_943a:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 33, !insn.addr !1912
  %2 = inttoptr i64 %1 to i8*, !insn.addr !1912
  %3 = load i8, i8* %2, align 1, !insn.addr !1912
  %4 = zext i8 %3 to i64, !insn.addr !1912
  ret i64 %4, !insn.addr !1913
}

define i64 @_ZN4llvm5TwineC1EPKc(i64* %result, i8* %arg2) local_unnamed_addr {
dec_label_pc_9450:
  %rax.0.reg2mem = alloca i64, !insn.addr !1914
  %storemerge.reg2mem = alloca i8, !insn.addr !1914
  %rsi = alloca i64, align 8
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !1915
  %2 = inttoptr i64 %1 to i8*, !insn.addr !1915
  store i8 1, i8* %2, align 1, !insn.addr !1915
  %3 = add i64 %0, 33, !insn.addr !1916
  %4 = inttoptr i64 %3 to i8*, !insn.addr !1916
  store i8 1, i8* %4, align 1, !insn.addr !1916
  %5 = bitcast i64* %rsi to i8*
  %6 = load i8, i8* %5, align 8, !insn.addr !1917
  %7 = icmp eq i8 %6, 0, !insn.addr !1918
  store i8 1, i8* %storemerge.reg2mem, !insn.addr !1919
  br i1 %7, label %dec_label_pc_949c, label %dec_label_pc_947f, !insn.addr !1919

dec_label_pc_947f:                                ; preds = %dec_label_pc_9450
  %8 = ptrtoint i8* %arg2 to i64, !insn.addr !1920
  store i64 %8, i64* %result, align 8, !insn.addr !1921
  store i8 3, i8* %storemerge.reg2mem, !insn.addr !1922
  br label %dec_label_pc_949c, !insn.addr !1922

dec_label_pc_949c:                                ; preds = %dec_label_pc_9450, %dec_label_pc_947f
  %storemerge.reload = load i8, i8* %storemerge.reg2mem
  store i8 %storemerge.reload, i8* %2, align 1
  %9 = call i64 @_ZNK4llvm5Twine7isValidEv(i64* %result), !insn.addr !1923
  %10 = trunc i64 %9 to i8, !insn.addr !1924
  %11 = icmp eq i8 %10, 0, !insn.addr !1924
  %12 = icmp eq i1 %11, false, !insn.addr !1925
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !1925
  br i1 %12, label %dec_label_pc_94d4, label %dec_label_pc_94ac, !insn.addr !1925

dec_label_pc_94ac:                                ; preds = %dec_label_pc_949c
  %13 = call i64 @__assert_fail(i64 ptrtoint ([30 x i8]* @global_var_4e71 to i64), i64 ptrtoint ([38 x i8]* @global_var_4df4 to i64), i64 282, i64 ptrtoint ([32 x i8]* @global_var_4e94 to i64)), !insn.addr !1926
  store i64 %13, i64* %rax.0.reg2mem, !insn.addr !1926
  br label %dec_label_pc_94d4, !insn.addr !1926

dec_label_pc_94d4:                                ; preds = %dec_label_pc_94ac, %dec_label_pc_949c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1927

; uselistorder directives
  uselistorder i8* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_949c, { 1, 0 }
}

define i64 @_ZN4llvm5TwineC1ERKNS_9StringRefE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_94d8:
  %rax.0.reg2mem = alloca i64, !insn.addr !1928
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !1929
  %2 = inttoptr i64 %1 to i8*, !insn.addr !1929
  store i8 5, i8* %2, align 1, !insn.addr !1929
  %3 = add i64 %0, 33, !insn.addr !1930
  %4 = inttoptr i64 %3 to i8*, !insn.addr !1930
  store i8 1, i8* %4, align 1, !insn.addr !1930
  %5 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %arg2), !insn.addr !1931
  store i64 %5, i64* %result, align 8, !insn.addr !1932
  %6 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %arg2), !insn.addr !1933
  %7 = add i64 %0, 8, !insn.addr !1934
  %8 = inttoptr i64 %7 to i64*, !insn.addr !1934
  store i64 %6, i64* %8, align 8, !insn.addr !1934
  %9 = call i64 @_ZNK4llvm5Twine7isValidEv(i64* %result), !insn.addr !1935
  %10 = trunc i64 %9 to i8, !insn.addr !1936
  %11 = icmp eq i8 %10, 0, !insn.addr !1936
  %12 = icmp eq i1 %11, false, !insn.addr !1937
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !1937
  br i1 %12, label %dec_label_pc_955b, label %dec_label_pc_9533, !insn.addr !1937

dec_label_pc_9533:                                ; preds = %dec_label_pc_94d8
  %13 = call i64 @__assert_fail(i64 ptrtoint ([30 x i8]* @global_var_4e71 to i64), i64 ptrtoint ([38 x i8]* @global_var_4df4 to i64), i64 309, i64 ptrtoint ([43 x i8]* @global_var_4eb4 to i64)), !insn.addr !1938
  store i64 %13, i64* %rax.0.reg2mem, !insn.addr !1938
  br label %dec_label_pc_955b, !insn.addr !1938

dec_label_pc_955b:                                ; preds = %dec_label_pc_9533, %dec_label_pc_94d8
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1939
}

define i64 @_ZN4llvm5TwineC1ERKNS_9StringRefEPKc(i64* %result, i64* %arg2, i8* %arg3) local_unnamed_addr {
dec_label_pc_955e:
  %rax.0.reg2mem = alloca i64, !insn.addr !1940
  %0 = ptrtoint i8* %arg3 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = add i64 %1, 32, !insn.addr !1941
  %3 = inttoptr i64 %2 to i8*, !insn.addr !1941
  store i8 5, i8* %3, align 1, !insn.addr !1941
  %4 = add i64 %1, 33, !insn.addr !1942
  %5 = inttoptr i64 %4 to i8*, !insn.addr !1942
  store i8 3, i8* %5, align 1, !insn.addr !1942
  %6 = call i64 @_ZNK4llvm9StringRef4dataEv(i64* %arg2), !insn.addr !1943
  store i64 %6, i64* %result, align 8, !insn.addr !1944
  %7 = call i64 @_ZNK4llvm9StringRef4sizeEv(i64* %arg2), !insn.addr !1945
  %8 = add i64 %1, 8, !insn.addr !1946
  %9 = inttoptr i64 %8 to i64*, !insn.addr !1946
  store i64 %7, i64* %9, align 8, !insn.addr !1946
  %10 = add i64 %1, 16, !insn.addr !1947
  %11 = inttoptr i64 %10 to i64*, !insn.addr !1947
  store i64 %0, i64* %11, align 8, !insn.addr !1947
  %12 = call i64 @_ZNK4llvm5Twine7isValidEv(i64* %result), !insn.addr !1948
  %13 = trunc i64 %12 to i8, !insn.addr !1949
  %14 = icmp eq i8 %13, 0, !insn.addr !1949
  %15 = icmp eq i1 %14, false, !insn.addr !1950
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !1950
  br i1 %15, label %dec_label_pc_95f1, label %dec_label_pc_95c9, !insn.addr !1950

dec_label_pc_95c9:                                ; preds = %dec_label_pc_955e
  %16 = call i64 @__assert_fail(i64 ptrtoint ([30 x i8]* @global_var_4e71 to i64), i64 ptrtoint ([38 x i8]* @global_var_4df4 to i64), i64 400, i64 ptrtoint ([56 x i8]* @global_var_4ee4 to i64)), !insn.addr !1951
  store i64 %16, i64* %rax.0.reg2mem, !insn.addr !1951
  br label %dec_label_pc_95f1, !insn.addr !1951

dec_label_pc_95f1:                                ; preds = %dec_label_pc_95c9, %dec_label_pc_955e
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !1952

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine7isValidEv, { 2, 0, 3, 1 }
  uselistorder i64 (i64*)* @_ZNK4llvm9StringRef4sizeEv, { 15, 14, 16, 2, 1, 0, 13, 12, 17, 9, 8, 7, 6, 11, 10, 20, 19, 18, 5, 4, 3 }
  uselistorder i64 (i64*)* @_ZNK4llvm9StringRef4dataEv, { 8, 7, 10, 9, 1, 0, 6, 5, 12, 11, 4, 3, 2 }
  uselistorder i8 3, { 1, 0 }
}

define i64 @_ZNK4llvm5Twine6concatERKS0_(i64* %this, i64* %result, i64* %arg3) local_unnamed_addr {
dec_label_pc_95f4:
  %stack_var_-48.0.reg2mem = alloca i64, !insn.addr !1953
  %stack_var_-73.0.reg2mem = alloca i64, !insn.addr !1953
  %stack_var_-56.0.reg2mem = alloca i64, !insn.addr !1953
  %stack_var_-64.0.reg2mem = alloca i64, !insn.addr !1953
  %stack_var_-74.0.reg2mem = alloca i8, !insn.addr !1953
  %0 = ptrtoint i64* %this to i64
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !1954
  %2 = call i64 @_ZNK4llvm5Twine6isNullEv(i64* %result), !insn.addr !1955
  %3 = trunc i64 %2 to i8, !insn.addr !1956
  %4 = icmp eq i8 %3, 0, !insn.addr !1956
  %5 = icmp eq i1 %4, false, !insn.addr !1957
  br i1 %5, label %dec_label_pc_964c, label %dec_label_pc_962c, !insn.addr !1957

dec_label_pc_962c:                                ; preds = %dec_label_pc_95f4
  %6 = call i64 @_ZNK4llvm5Twine6isNullEv(i64* %arg3), !insn.addr !1958
  %7 = trunc i64 %6 to i8, !insn.addr !1959
  %8 = icmp eq i8 %7, 0, !insn.addr !1959
  br i1 %8, label %dec_label_pc_9643, label %dec_label_pc_964c, !insn.addr !1960

dec_label_pc_9643:                                ; preds = %dec_label_pc_962c
  %9 = ptrtoint i64* %arg3 to i64
  %10 = call i64 @_ZNK4llvm5Twine7isEmptyEv(i64* %result), !insn.addr !1961
  %11 = trunc i64 %10 to i8, !insn.addr !1962
  %12 = icmp eq i8 %11, 0, !insn.addr !1962
  br i1 %12, label %dec_label_pc_96a5, label %dec_label_pc_9672, !insn.addr !1963

dec_label_pc_964c:                                ; preds = %dec_label_pc_962c, %dec_label_pc_95f4
  %13 = call i64 @_ZN4llvm5TwineC1ENS0_8NodeKindE(i64* %this, i64 0), !insn.addr !1964
  br label %dec_label_pc_9799, !insn.addr !1965

dec_label_pc_9672:                                ; preds = %dec_label_pc_9643
  %14 = add i64 %9, 8, !insn.addr !1966
  %15 = inttoptr i64 %14 to i64*, !insn.addr !1966
  %16 = load i64, i64* %15, align 8, !insn.addr !1966
  store i64 %9, i64* %this, align 8, !insn.addr !1967
  %17 = add i64 %0, 8, !insn.addr !1968
  %18 = inttoptr i64 %17 to i64*, !insn.addr !1968
  store i64 %16, i64* %18, align 8, !insn.addr !1968
  %19 = add i64 %9, 16, !insn.addr !1969
  %20 = inttoptr i64 %19 to i64*, !insn.addr !1969
  %21 = load i64, i64* %20, align 8, !insn.addr !1969
  %22 = add i64 %9, 24, !insn.addr !1970
  %23 = inttoptr i64 %22 to i64*, !insn.addr !1970
  %24 = load i64, i64* %23, align 8, !insn.addr !1970
  %25 = add i64 %0, 16, !insn.addr !1971
  %26 = inttoptr i64 %25 to i64*, !insn.addr !1971
  store i64 %21, i64* %26, align 8, !insn.addr !1971
  %27 = add i64 %0, 24, !insn.addr !1972
  %28 = inttoptr i64 %27 to i64*, !insn.addr !1972
  store i64 %24, i64* %28, align 8, !insn.addr !1972
  %29 = add i64 %9, 32, !insn.addr !1973
  %30 = inttoptr i64 %29 to i64*, !insn.addr !1973
  %31 = load i64, i64* %30, align 8, !insn.addr !1973
  %32 = add i64 %0, 32, !insn.addr !1974
  %33 = inttoptr i64 %32 to i64*, !insn.addr !1974
  store i64 %31, i64* %33, align 8, !insn.addr !1974
  br label %dec_label_pc_9799, !insn.addr !1975

dec_label_pc_96a5:                                ; preds = %dec_label_pc_9643
  %34 = ptrtoint i64* %result to i64
  %35 = call i64 @_ZNK4llvm5Twine7isEmptyEv(i64* %arg3), !insn.addr !1976
  %36 = trunc i64 %35 to i8, !insn.addr !1977
  %37 = icmp eq i8 %36, 0, !insn.addr !1977
  br i1 %37, label %dec_label_pc_96e8, label %dec_label_pc_96b5, !insn.addr !1978

dec_label_pc_96b5:                                ; preds = %dec_label_pc_96a5
  %38 = add i64 %34, 8, !insn.addr !1979
  %39 = inttoptr i64 %38 to i64*, !insn.addr !1979
  %40 = load i64, i64* %39, align 8, !insn.addr !1979
  store i64 %34, i64* %this, align 8, !insn.addr !1980
  %41 = add i64 %0, 8, !insn.addr !1981
  %42 = inttoptr i64 %41 to i64*, !insn.addr !1981
  store i64 %40, i64* %42, align 8, !insn.addr !1981
  %43 = add i64 %34, 16, !insn.addr !1982
  %44 = inttoptr i64 %43 to i64*, !insn.addr !1982
  %45 = load i64, i64* %44, align 8, !insn.addr !1982
  %46 = add i64 %34, 24, !insn.addr !1983
  %47 = inttoptr i64 %46 to i64*, !insn.addr !1983
  %48 = load i64, i64* %47, align 8, !insn.addr !1983
  %49 = add i64 %0, 16, !insn.addr !1984
  %50 = inttoptr i64 %49 to i64*, !insn.addr !1984
  store i64 %45, i64* %50, align 8, !insn.addr !1984
  %51 = add i64 %0, 24, !insn.addr !1985
  %52 = inttoptr i64 %51 to i64*, !insn.addr !1985
  store i64 %48, i64* %52, align 8, !insn.addr !1985
  %53 = add i64 %34, 32, !insn.addr !1986
  %54 = inttoptr i64 %53 to i64*, !insn.addr !1986
  %55 = load i64, i64* %54, align 8, !insn.addr !1986
  %56 = add i64 %0, 32, !insn.addr !1987
  %57 = inttoptr i64 %56 to i64*, !insn.addr !1987
  store i64 %55, i64* %57, align 8, !insn.addr !1987
  br label %dec_label_pc_9799, !insn.addr !1988

dec_label_pc_96e8:                                ; preds = %dec_label_pc_96a5
  %58 = call i64 @_ZNK4llvm5Twine7isUnaryEv(i64* %result), !insn.addr !1989
  %59 = trunc i64 %58 to i8, !insn.addr !1990
  %60 = icmp eq i8 %59, 0, !insn.addr !1990
  store i8 2, i8* %stack_var_-74.0.reg2mem, !insn.addr !1991
  br i1 %60, label %dec_label_pc_9732, label %dec_label_pc_9710, !insn.addr !1991

dec_label_pc_9710:                                ; preds = %dec_label_pc_96e8
  %61 = add i64 %34, 8, !insn.addr !1992
  %62 = inttoptr i64 %61 to i64*, !insn.addr !1992
  %63 = load i64, i64* %62, align 8, !insn.addr !1992
  %64 = call i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %result), !insn.addr !1993
  %65 = trunc i64 %64 to i8, !insn.addr !1994
  store i8 %65, i8* %stack_var_-74.0.reg2mem, !insn.addr !1994
  store i64 %63, i64* %stack_var_-64.0.reg2mem, !insn.addr !1994
  br label %dec_label_pc_9732, !insn.addr !1994

dec_label_pc_9732:                                ; preds = %dec_label_pc_9710, %dec_label_pc_96e8
  %stack_var_-64.0.reload = load i64, i64* %stack_var_-64.0.reg2mem
  %stack_var_-74.0.reload = load i8, i8* %stack_var_-74.0.reg2mem
  %66 = call i64 @_ZNK4llvm5Twine7isUnaryEv(i64* %arg3), !insn.addr !1995
  %67 = trunc i64 %66 to i8, !insn.addr !1996
  %68 = icmp eq i8 %67, 0, !insn.addr !1996
  store i64 %9, i64* %stack_var_-56.0.reg2mem, !insn.addr !1997
  store i64 2, i64* %stack_var_-73.0.reg2mem, !insn.addr !1997
  br i1 %68, label %dec_label_pc_9764, label %dec_label_pc_9742, !insn.addr !1997

dec_label_pc_9742:                                ; preds = %dec_label_pc_9732
  %69 = add i64 %9, 8, !insn.addr !1998
  %70 = inttoptr i64 %69 to i64*, !insn.addr !1998
  %71 = load i64, i64* %70, align 8, !insn.addr !1998
  %72 = call i64 @_ZNK4llvm5Twine10getLHSKindEv(i64* %arg3), !insn.addr !1999
  %phitmp = urem i64 %72, 256
  store i64 %71, i64* %stack_var_-56.0.reg2mem, !insn.addr !2000
  store i64 %phitmp, i64* %stack_var_-73.0.reg2mem, !insn.addr !2000
  store i64 %71, i64* %stack_var_-48.0.reg2mem, !insn.addr !2000
  br label %dec_label_pc_9764, !insn.addr !2000

dec_label_pc_9764:                                ; preds = %dec_label_pc_9742, %dec_label_pc_9732
  %stack_var_-48.0.reload = load i64, i64* %stack_var_-48.0.reg2mem
  %stack_var_-73.0.reload = load i64, i64* %stack_var_-73.0.reg2mem
  %stack_var_-56.0.reload = load i64, i64* %stack_var_-56.0.reg2mem
  %73 = call i64 @_ZN4llvm5TwineC1ENS0_5ChildENS0_8NodeKindES1_S2_(i64 %0, i64 %34, i64 %stack_var_-64.0.reload, i8 %stack_var_-74.0.reload, i64 %stack_var_-56.0.reload, i64 %stack_var_-48.0.reload, i64 %stack_var_-73.0.reload), !insn.addr !2001
  br label %dec_label_pc_9799, !insn.addr !2002

dec_label_pc_9799:                                ; preds = %dec_label_pc_9764, %dec_label_pc_96b5, %dec_label_pc_9672, %dec_label_pc_964c
  %74 = call i64 @__readfsqword(i64 40), !insn.addr !2003
  %75 = icmp eq i64 %1, %74, !insn.addr !2003
  br i1 %75, label %dec_label_pc_97ad, label %dec_label_pc_97a8, !insn.addr !2004

dec_label_pc_97a8:                                ; preds = %dec_label_pc_9799
  %76 = call i64 @__stack_chk_fail(), !insn.addr !2005
  br label %dec_label_pc_97ad, !insn.addr !2005

dec_label_pc_97ad:                                ; preds = %dec_label_pc_97a8, %dec_label_pc_9799
  ret i64 %0, !insn.addr !2006

; uselistorder directives
  uselistorder i64 %34, { 0, 6, 2, 3, 4, 1, 5 }
  uselistorder i64 %9, { 6, 0, 1, 2, 3, 5, 4 }
  uselistorder i64 %0, { 9, 8, 4, 5, 6, 7, 0, 1, 2, 3 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine10getLHSKindEv, { 6, 5, 1, 0, 4, 3, 2 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine7isUnaryEv, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine7isEmptyEv, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Twine6isNullEv, { 2, 1, 0 }
  uselistorder i64* %arg3, { 0, 1, 2, 4, 3 }
  uselistorder i64* %result, { 0, 1, 4, 2, 3 }
}

define i64 @_ZN4llvmplERKNS_5TwineES2_(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_97b7:
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2007
  %1 = call i64 @_ZNK4llvm5Twine6concatERKS0_(i64* %result, i64* %arg2, i64* %arg3), !insn.addr !2008
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !2009
  %3 = icmp eq i64 %0, %2, !insn.addr !2009
  br i1 %3, label %dec_label_pc_980a, label %dec_label_pc_9805, !insn.addr !2010

dec_label_pc_9805:                                ; preds = %dec_label_pc_97b7
  %4 = call i64 @__stack_chk_fail(), !insn.addr !2011
  br label %dec_label_pc_980a, !insn.addr !2011

dec_label_pc_980a:                                ; preds = %dec_label_pc_9805, %dec_label_pc_97b7
  %5 = ptrtoint i64* %result to i64
  ret i64 %5, !insn.addr !2012

; uselistorder directives
  uselistorder i64* %result, { 1, 0 }
}

define i64 @_ZN4llvmplERKNS_9StringRefEPKc(i64* %result, i64* %arg2, i8* %arg3) local_unnamed_addr {
dec_label_pc_9810:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm5TwineC1ERKNS_9StringRefEPKc(i64* %result, i64* %arg2, i8* %arg3), !insn.addr !2013
  ret i64 %0, !insn.addr !2014
}

define i64 @_ZNK4llvm4Type15getSubclassDataEv(i64* %result) local_unnamed_addr {
dec_label_pc_9846:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !2015
  %2 = inttoptr i64 %1 to i32*, !insn.addr !2015
  %3 = load i32, i32* %2, align 4, !insn.addr !2015
  %4 = udiv i32 %3, 256, !insn.addr !2016
  %5 = zext i32 %4 to i64, !insn.addr !2016
  ret i64 %5, !insn.addr !2017
}

define i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result) local_unnamed_addr {
dec_label_pc_985e:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !2018
  %2 = inttoptr i64 %1 to i8*, !insn.addr !2018
  %3 = load i8, i8* %2, align 1, !insn.addr !2018
  %4 = zext i8 %3 to i64, !insn.addr !2019
  ret i64 %4, !insn.addr !2020
}

define i64 @_ZNK4llvm4Type14isIEEELikeFPTyEv(i64* %result) local_unnamed_addr {
dec_label_pc_9878:
  %storemerge.reg2mem = alloca i64, !insn.addr !2021
  %0 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result), !insn.addr !2022
  %1 = trunc i64 %0 to i32, !insn.addr !2023
  %2 = icmp sgt i32 %1, 3, !insn.addr !2023
  br i1 %2, label %dec_label_pc_989f, label %dec_label_pc_9899, !insn.addr !2023

dec_label_pc_9899:                                ; preds = %dec_label_pc_9878
  %3 = icmp slt i32 %1, 0, !insn.addr !2024
  %4 = icmp eq i1 %3, false, !insn.addr !2025
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !2025
  br i1 %4, label %dec_label_pc_98b0, label %dec_label_pc_98ab, !insn.addr !2025

dec_label_pc_989f:                                ; preds = %dec_label_pc_9878
  %5 = icmp eq i32 %1, 5, !insn.addr !2026
  %6 = icmp eq i1 %5, false, !insn.addr !2027
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !2027
  br i1 %6, label %dec_label_pc_98ab, label %dec_label_pc_98b0, !insn.addr !2027

dec_label_pc_98ab:                                ; preds = %dec_label_pc_9899, %dec_label_pc_989f
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2028
  br label %dec_label_pc_98b0, !insn.addr !2028

dec_label_pc_98b0:                                ; preds = %dec_label_pc_9899, %dec_label_pc_989f, %dec_label_pc_98ab
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2029

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 3, 2, 1 }
  uselistorder i32 3, { 3, 4, 0, 1, 5, 2 }
  uselistorder label %dec_label_pc_98b0, { 2, 1, 0 }
  uselistorder label %dec_label_pc_98ab, { 1, 0 }
}

define i64 @_ZNK4llvm4Type17isFloatingPointTyEv(i64* %result) local_unnamed_addr {
dec_label_pc_98b2:
  %0 = call i64 @_ZNK4llvm4Type14isIEEELikeFPTyEv(i64* %result), !insn.addr !2030
  %1 = trunc i64 %0 to i8, !insn.addr !2031
  %2 = icmp eq i8 %1, 0, !insn.addr !2031
  %3 = icmp eq i1 %2, false, !insn.addr !2032
  br i1 %3, label %dec_label_pc_9900, label %dec_label_pc_98d2, !insn.addr !2032

dec_label_pc_98d2:                                ; preds = %dec_label_pc_98b2
  %4 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result), !insn.addr !2033
  %5 = trunc i64 %4 to i32, !insn.addr !2034
  %6 = icmp eq i32 %5, 4, !insn.addr !2034
  br i1 %6, label %dec_label_pc_9900, label %dec_label_pc_98e3, !insn.addr !2035

dec_label_pc_98e3:                                ; preds = %dec_label_pc_98d2
  %7 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result), !insn.addr !2036
  %8 = trunc i64 %7 to i32, !insn.addr !2037
  %9 = icmp eq i32 %8, 6, !insn.addr !2037
  %spec.select = zext i1 %9 to i64
  ret i64 %spec.select

dec_label_pc_9900:                                ; preds = %dec_label_pc_98b2, %dec_label_pc_98d2
  ret i64 1, !insn.addr !2038

; uselistorder directives
  uselistorder label %dec_label_pc_9900, { 1, 0 }
}

define i64 @_ZNK4llvm4Type16isFPOrFPVectorTyEv(i64* %result) local_unnamed_addr {
dec_label_pc_9902:
  %0 = call i64 @_ZNK4llvm4Type13getScalarTypeEv(i64* %result), !insn.addr !2039
  %1 = inttoptr i64 %0 to i64*, !insn.addr !2040
  %2 = call i64 @_ZNK4llvm4Type17isFloatingPointTyEv(i64* %1), !insn.addr !2040
  ret i64 %2, !insn.addr !2041
}

define i64 @_ZNK4llvm4Type11isIntegerTyEv(i64* %result) local_unnamed_addr {
dec_label_pc_9928:
  %0 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result), !insn.addr !2042
  %1 = trunc i64 %0 to i32, !insn.addr !2043
  %2 = icmp eq i32 %1, 12, !insn.addr !2043
  %3 = zext i1 %2 to i64, !insn.addr !2044
  %4 = and i64 %0, -256, !insn.addr !2044
  %5 = or i64 %4, %3, !insn.addr !2044
  ret i64 %5, !insn.addr !2045

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm4Type11isPointerTyEv(i64* %result) local_unnamed_addr {
dec_label_pc_994c:
  %0 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result), !insn.addr !2046
  %1 = trunc i64 %0 to i32, !insn.addr !2047
  %2 = icmp eq i32 %1, 14, !insn.addr !2047
  %3 = zext i1 %2 to i64, !insn.addr !2048
  %4 = and i64 %0, -256, !insn.addr !2048
  %5 = or i64 %4, %3, !insn.addr !2048
  ret i64 %5, !insn.addr !2049

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm4Type10isVectorTyEv(i64* %result) local_unnamed_addr {
dec_label_pc_9970:
  %0 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result), !insn.addr !2050
  %1 = trunc i64 %0 to i32, !insn.addr !2051
  %2 = icmp eq i32 %1, 18, !insn.addr !2051
  br i1 %2, label %dec_label_pc_99ae, label %dec_label_pc_9991, !insn.addr !2052

dec_label_pc_9991:                                ; preds = %dec_label_pc_9970
  %3 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %result), !insn.addr !2053
  %4 = trunc i64 %3 to i32, !insn.addr !2054
  %5 = icmp eq i32 %4, 17, !insn.addr !2054
  %spec.select = zext i1 %5 to i64
  ret i64 %spec.select

dec_label_pc_99ae:                                ; preds = %dec_label_pc_9970
  ret i64 1, !insn.addr !2055
}

define i64 @_ZNK4llvm4Type13getScalarTypeEv(i64* %result) local_unnamed_addr {
dec_label_pc_99b0:
  %storemerge.reg2mem = alloca i64, !insn.addr !2056
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm4Type10isVectorTyEv(i64* %result), !insn.addr !2057
  %2 = trunc i64 %1 to i8, !insn.addr !2058
  %3 = icmp eq i8 %2, 0, !insn.addr !2058
  store i64 %0, i64* %storemerge.reg2mem, !insn.addr !2059
  br i1 %3, label %dec_label_pc_99e7, label %dec_label_pc_99d0, !insn.addr !2059

dec_label_pc_99d0:                                ; preds = %dec_label_pc_99b0
  %4 = call i64 @_ZNK4llvm4Type16getContainedTypeEj(i64* %result, i32 0), !insn.addr !2060
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !2061
  br label %dec_label_pc_99e7, !insn.addr !2061

dec_label_pc_99e7:                                ; preds = %dec_label_pc_99b0, %dec_label_pc_99d0
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2062

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_99e7, { 1, 0 }
}

define i64 @_ZNK4llvm4Type16getContainedTypeEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_99ea:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 12, !insn.addr !2063
  %2 = inttoptr i64 %1 to i32*, !insn.addr !2063
  %3 = load i32, i32* %2, align 4, !insn.addr !2063
  %4 = icmp ugt i32 %3, %arg2, !insn.addr !2064
  br i1 %4, label %dec_label_pc_9a31, label %dec_label_pc_9a09, !insn.addr !2065

dec_label_pc_9a09:                                ; preds = %dec_label_pc_99ea
  %5 = call i64 @__assert_fail(i64 ptrtoint ([45 x i8]* @global_var_4f94 to i64), i64 ptrtoint ([36 x i8]* @global_var_4f6c to i64), i64 379, i64 ptrtoint ([61 x i8]* @global_var_4f2c to i64)), !insn.addr !2066
  br label %dec_label_pc_9a31, !insn.addr !2066

dec_label_pc_9a31:                                ; preds = %dec_label_pc_9a09, %dec_label_pc_99ea
  %6 = add i64 %0, 16, !insn.addr !2067
  %7 = inttoptr i64 %6 to i64*, !insn.addr !2067
  %8 = load i64, i64* %7, align 8, !insn.addr !2067
  %9 = zext i32 %arg2 to i64, !insn.addr !2068
  %10 = mul i64 %9, 8, !insn.addr !2069
  %11 = add i64 %8, %10, !insn.addr !2070
  %12 = inttoptr i64 %11 to i64*, !insn.addr !2071
  %13 = load i64, i64* %12, align 8, !insn.addr !2071
  ret i64 %13, !insn.addr !2072
}

define i64 @_ZNK4llvm11IntegerType11getBitWidthEv(i64* %result) local_unnamed_addr {
dec_label_pc_9a48:
  %0 = call i64 @_ZNK4llvm4Type15getSubclassDataEv(i64* %result), !insn.addr !2073
  ret i64 %0, !insn.addr !2074
}

define i64 @_ZN4llvm11IntegerType7classofEPKNS_4TypeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_9a66:
  %0 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %arg1), !insn.addr !2075
  %1 = trunc i64 %0 to i32, !insn.addr !2076
  %2 = icmp eq i32 %1, 12, !insn.addr !2076
  %3 = zext i1 %2 to i64, !insn.addr !2077
  %4 = and i64 %0, -256, !insn.addr !2077
  %5 = or i64 %4, %3, !insn.addr !2077
  ret i64 %5, !insn.addr !2078

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm10StructType9isLiteralEv(i64* %result) local_unnamed_addr {
dec_label_pc_9a8a:
  %0 = call i64 @_ZNK4llvm4Type15getSubclassDataEv(i64* %result), !insn.addr !2079
  %1 = and i64 %0, 4, !insn.addr !2080
  %2 = icmp eq i64 %1, 0, !insn.addr !2081
  %3 = icmp eq i1 %2, false, !insn.addr !2082
  %4 = zext i1 %3 to i64, !insn.addr !2082
  ret i64 %4, !insn.addr !2083

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm4Type15getSubclassDataEv, { 1, 0 }
}

define i64 @_ZNK4llvm10StructType13element_beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_9ab0:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !2084
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2084
  %3 = load i64, i64* %2, align 8, !insn.addr !2084
  ret i64 %3, !insn.addr !2085
}

define i64 @_ZNK4llvm10StructType11element_endEv(i64* %result) local_unnamed_addr {
dec_label_pc_9ac6:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !2086
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2086
  %3 = load i64, i64* %2, align 8, !insn.addr !2086
  %4 = add i64 %0, 12, !insn.addr !2087
  %5 = inttoptr i64 %4 to i32*, !insn.addr !2087
  %6 = load i32, i32* %5, align 4, !insn.addr !2087
  %7 = zext i32 %6 to i64, !insn.addr !2088
  %8 = mul i64 %7, 8, !insn.addr !2089
  %9 = add i64 %8, %3, !insn.addr !2090
  ret i64 %9, !insn.addr !2091
}

define i64 @_ZNK4llvm10StructType8elementsEv(i64* %result) local_unnamed_addr {
dec_label_pc_9aec:
  %rax.0.reg2mem = alloca i64, !insn.addr !2092
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2093
  %1 = call i64 @_ZNK4llvm10StructType11element_endEv(i64* %result), !insn.addr !2094
  %2 = call i64 @_ZNK4llvm10StructType13element_beginEv(i64* %result), !insn.addr !2095
  %3 = inttoptr i64 %2 to i64**, !insn.addr !2096
  %4 = inttoptr i64 %1 to i64**, !insn.addr !2096
  %5 = call i64 @_ZN4llvm8ArrayRefIPNS_4TypeEEC1EPKS2_S5_(i64* nonnull %stack_var_-56, i64** %3, i64** %4), !insn.addr !2096
  %6 = load i64, i64* %stack_var_-56, align 8, !insn.addr !2097
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !2098
  %8 = icmp eq i64 %0, %7, !insn.addr !2098
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !2099
  br i1 %8, label %dec_label_pc_9b58, label %dec_label_pc_9b53, !insn.addr !2099

dec_label_pc_9b53:                                ; preds = %dec_label_pc_9aec
  %9 = call i64 @__stack_chk_fail(), !insn.addr !2100
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !2100
  br label %dec_label_pc_9b58, !insn.addr !2100

dec_label_pc_9b58:                                ; preds = %dec_label_pc_9b53, %dec_label_pc_9aec
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2101

; uselistorder directives
  uselistorder i64* %stack_var_-56, { 1, 0 }
}

define i64 @_ZN4llvm10StructType7classofEPKNS_4TypeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_9b5e:
  %0 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %arg1), !insn.addr !2102
  %1 = trunc i64 %0 to i32, !insn.addr !2103
  %2 = icmp eq i32 %1, 15, !insn.addr !2103
  %3 = zext i1 %2 to i64, !insn.addr !2104
  %4 = and i64 %0, -256, !insn.addr !2104
  %5 = or i64 %4, %3, !insn.addr !2104
  ret i64 %5, !insn.addr !2105

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm9ArrayType14getElementTypeEv(i64* %result) local_unnamed_addr {
dec_label_pc_9b82:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 24, !insn.addr !2106
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2106
  %3 = load i64, i64* %2, align 8, !insn.addr !2106
  ret i64 %3, !insn.addr !2107
}

define i64 @_ZN4llvm9ArrayType7classofEPKNS_4TypeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_9b98:
  %0 = call i64 @_ZNK4llvm4Type9getTypeIDEv(i64* %arg1), !insn.addr !2108
  %1 = trunc i64 %0 to i32, !insn.addr !2109
  %2 = icmp eq i32 %1, 16, !insn.addr !2109
  %3 = zext i1 %2 to i64, !insn.addr !2110
  %4 = and i64 %0, -256, !insn.addr !2110
  %5 = or i64 %4, %3, !insn.addr !2110
  ret i64 %5, !insn.addr !2111

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm4Type9getTypeIDEv, { 9, 8, 2, 7, 6, 1, 0, 4, 3, 5 }
}

define i64 @_ZN4llvm13FastMathFlagsC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9bbc:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i64* %result to i32*, !insn.addr !2112
  store i32 0, i32* %1, align 4, !insn.addr !2112
  ret i64 %0, !insn.addr !2113
}

define i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi0EJS4_S6_S8_EECI1NS1_IS9_SG_Li1EJS6_S8_EEEES6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_9bd6:
  %0 = call i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi1EJS6_S8_EEC1ES6_(i64* %result, i64* %arg2), !insn.addr !2114
  ret i64 %0, !insn.addr !2115
}

define i64 @_ZN4llvm12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEECI1NS_20pointer_union_detail19PointerUnionMembersIS7_NS_14PointerIntPairIPvLj2EiNS8_22PointerUnionUIntTraitsIJS2_S4_S6_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi1EJS4_S6_EEEES4_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_9c00:
  %0 = call i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi0EJS4_S6_S8_EECI1NS1_IS9_SG_Li1EJS6_S8_EEEES6_(i64* %result, i64* %arg2), !insn.addr !2116
  ret i64 %0, !insn.addr !2117
}

define i64 @_ZN4llvm16MetadataTracking5trackERPNS_8MetadataE(i64** %arg1) local_unnamed_addr {
dec_label_pc_9c2a:
  %rax.0.reg2mem = alloca i64, !insn.addr !2118
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2119
  %1 = call i64 @_ZN4llvm12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEECI1NS_20pointer_union_detail19PointerUnionMembersIS7_NS_14PointerIntPairIPvLj2EiNS8_22PointerUnionUIntTraitsIJS2_S4_S6_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi1EJS4_S6_EEEES4_(i64* nonnull %stack_var_-24, i64* null), !insn.addr !2120
  %2 = load i64, i64* %stack_var_-24, align 8, !insn.addr !2121
  %3 = bitcast i64** %arg1 to i64*, !insn.addr !2122
  %4 = call i64 @_ZN4llvm16MetadataTracking5trackEPvRNS_8MetadataENS_12PointerUnionIJPNS_15MetadataAsValueEPS2_PNS_14DebugValueUserEEEE(i64* %3, i64* nonnull %stack_var_-24, i64 %2), !insn.addr !2122
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !2123
  %6 = icmp eq i64 %0, %5, !insn.addr !2123
  store i64 %4, i64* %rax.0.reg2mem, !insn.addr !2124
  br i1 %6, label %dec_label_pc_9c88, label %dec_label_pc_9c83, !insn.addr !2124

dec_label_pc_9c83:                                ; preds = %dec_label_pc_9c2a
  %7 = call i64 @__stack_chk_fail(), !insn.addr !2125
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !2125
  br label %dec_label_pc_9c88, !insn.addr !2125

dec_label_pc_9c88:                                ; preds = %dec_label_pc_9c83, %dec_label_pc_9c2a
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2126

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 0, 2, 1 }
}

define i64 @_ZN4llvm16MetadataTracking7untrackERPNS_8MetadataE(i64** %arg1) local_unnamed_addr {
dec_label_pc_9c8a:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !2127
  %1 = call i64 @_ZN4llvm16MetadataTracking7untrackEPvRNS_8MetadataE(i64* %0, i64* %0), !insn.addr !2127
  ret i64 %1, !insn.addr !2128
}

define i64 @_ZN4llvm16MetadataTracking7retrackERPNS_8MetadataES3_(i64** %arg1, i64** %arg2) local_unnamed_addr {
dec_label_pc_9cb3:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !2129
  %1 = bitcast i64** %arg2 to i64*
  %2 = call i64 @_ZN4llvm16MetadataTracking7retrackEPvRNS_8MetadataES1_(i64* %0, i64* %0, i64* %1), !insn.addr !2129
  ret i64 %2, !insn.addr !2130
}

define i64 @_ZN4llvm13TrackingMDRefC1ERKS0_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_9ce4:
  %0 = ptrtoint i64* %arg2 to i64
  store i64 %0, i64* %result, align 8, !insn.addr !2131
  %1 = call i64 @_ZN4llvm13TrackingMDRef5trackEv(i64* %result), !insn.addr !2132
  ret i64 %1, !insn.addr !2133
}

define i64 @_ZN4llvm13TrackingMDRefaSEOS0_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_9d16:
  %0 = icmp eq i64* %arg2, %result, !insn.addr !2134
  %1 = icmp eq i1 %0, false, !insn.addr !2135
  br i1 %1, label %dec_label_pc_9d3a, label %dec_label_pc_9d6b, !insn.addr !2135

dec_label_pc_9d3a:                                ; preds = %dec_label_pc_9d16
  %2 = ptrtoint i64* %arg2 to i64
  %3 = call i64 @_ZN4llvm13TrackingMDRef7untrackEv(i64* %result), !insn.addr !2136
  store i64 %2, i64* %result, align 8, !insn.addr !2137
  %4 = call i64 @_ZN4llvm13TrackingMDRef7retrackERS0_(i64* %result, i64* %arg2), !insn.addr !2138
  br label %dec_label_pc_9d6b, !insn.addr !2139

dec_label_pc_9d6b:                                ; preds = %dec_label_pc_9d16, %dec_label_pc_9d3a
  %5 = ptrtoint i64* %result to i64
  ret i64 %5, !insn.addr !2140

; uselistorder directives
  uselistorder i64* %arg2, { 0, 2, 1 }
  uselistorder i64* %result, { 4, 0, 1, 2, 3 }
  uselistorder label %dec_label_pc_9d6b, { 1, 0 }
}

define i64 @_ZN4llvm13TrackingMDRefD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9d6e:
  %0 = call i64 @_ZN4llvm13TrackingMDRef7untrackEv(i64* %result), !insn.addr !2141
  ret i64 %0, !insn.addr !2142
}

define i64 @_ZN4llvm13TrackingMDRef5trackEv(i64* %result) local_unnamed_addr {
dec_label_pc_9d8e:
  %rax.0.reg2mem = alloca i64, !insn.addr !2143
  %0 = ptrtoint i64* %result to i64
  %1 = icmp eq i64* %result, null, !insn.addr !2144
  store i64 %0, i64* %rax.0.reg2mem, !insn.addr !2145
  br i1 %1, label %dec_label_pc_9db6, label %dec_label_pc_9daa, !insn.addr !2145

dec_label_pc_9daa:                                ; preds = %dec_label_pc_9d8e
  %2 = bitcast i64* %result to i64**, !insn.addr !2146
  %3 = call i64 @_ZN4llvm16MetadataTracking5trackERPNS_8MetadataE(i64** %2), !insn.addr !2146
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !2146
  br label %dec_label_pc_9db6, !insn.addr !2146

dec_label_pc_9db6:                                ; preds = %dec_label_pc_9daa, %dec_label_pc_9d8e
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2147
}

define i64 @_ZN4llvm13TrackingMDRef7untrackEv(i64* %result) local_unnamed_addr {
dec_label_pc_9dba:
  %rax.0.reg2mem = alloca i64, !insn.addr !2148
  %0 = ptrtoint i64* %result to i64
  %1 = icmp eq i64* %result, null, !insn.addr !2149
  store i64 %0, i64* %rax.0.reg2mem, !insn.addr !2150
  br i1 %1, label %dec_label_pc_9de2, label %dec_label_pc_9dd6, !insn.addr !2150

dec_label_pc_9dd6:                                ; preds = %dec_label_pc_9dba
  %2 = bitcast i64* %result to i64**, !insn.addr !2151
  %3 = call i64 @_ZN4llvm16MetadataTracking7untrackERPNS_8MetadataE(i64** %2), !insn.addr !2151
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !2151
  br label %dec_label_pc_9de2, !insn.addr !2151

dec_label_pc_9de2:                                ; preds = %dec_label_pc_9dd6, %dec_label_pc_9dba
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2152
}

define i64 @_ZN4llvm13TrackingMDRef7retrackERS0_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_9de6:
  %rax.0.reg2mem = alloca i64, !insn.addr !2153
  %0 = icmp eq i64* %result, %arg2, !insn.addr !2154
  br i1 %0, label %dec_label_pc_9e35, label %dec_label_pc_9e35.thread, !insn.addr !2155

dec_label_pc_9e35.thread:                         ; preds = %dec_label_pc_9de6
  %1 = call i64 @__assert_fail(i64 ptrtoint ([41 x i8]* @global_var_5034 to i64), i64 ptrtoint ([45 x i8]* @global_var_5004 to i64), i64 94, i64 ptrtoint ([56 x i8]* @global_var_4fcc to i64)), !insn.addr !2156
  br label %dec_label_pc_9e41

dec_label_pc_9e35:                                ; preds = %dec_label_pc_9de6
  %2 = icmp eq i64* %arg2, null, !insn.addr !2157
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !2158
  br i1 %2, label %dec_label_pc_9e5f, label %dec_label_pc_9e41, !insn.addr !2158

dec_label_pc_9e41:                                ; preds = %dec_label_pc_9e35.thread, %dec_label_pc_9e35
  %3 = ptrtoint i64* %arg2 to i64
  %4 = bitcast i64* %arg2 to i64**, !insn.addr !2159
  %5 = bitcast i64* %result to i64**, !insn.addr !2159
  %6 = call i64 @_ZN4llvm16MetadataTracking7retrackERPNS_8MetadataES3_(i64** %4, i64** %5), !insn.addr !2159
  store i64 0, i64* %arg2, align 8, !insn.addr !2160
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !2160
  br label %dec_label_pc_9e5f, !insn.addr !2160

dec_label_pc_9e5f:                                ; preds = %dec_label_pc_9e41, %dec_label_pc_9e35
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2161

; uselistorder directives
  uselistorder i64* %arg2, { 1, 2, 4, 0, 3 }
  uselistorder label %dec_label_pc_9e41, { 1, 0 }
}

define i64 @_ZN4llvm13TrackingMDRefC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9e62:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !2162
  ret i64 %0, !insn.addr !2163
}

define i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9e7c:
  %0 = call i64 @_ZN4llvm13TrackingMDRefC1Ev(i64* %result), !insn.addr !2164
  ret i64 %0, !insn.addr !2165
}

define i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9e9c:
  %0 = call i64 @_ZN4llvm13TrackingMDRefD1Ev(i64* %result), !insn.addr !2166
  ret i64 %0, !insn.addr !2167
}

define i64 @_ZN4llvm8DebugLocC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9ebc:
  %0 = call i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEEC1Ev(i64* %result), !insn.addr !2168
  ret i64 %0, !insn.addr !2169
}

define i64 @_ZN4llvm8DebugLocD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9edc:
  %0 = call i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEED1Ev(i64* %result), !insn.addr !2170
  ret i64 %0, !insn.addr !2171
}

define i64 @_ZN4llvm8DebugLocC1ERKS0_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_9efc:
  %0 = call i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEEC1ERKS2_(i64* %result, i64* %arg2), !insn.addr !2172
  ret i64 %0, !insn.addr !2173
}

define i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_9f26:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !2174
  %1 = add i64 %0, 8, !insn.addr !2175
  %2 = inttoptr i64 %1 to i8*, !insn.addr !2175
  store i8 0, i8* %2, align 1, !insn.addr !2175
  %3 = add i64 %0, 9, !insn.addr !2176
  %4 = inttoptr i64 %3 to i8*, !insn.addr !2176
  store i8 0, i8* %4, align 1, !insn.addr !2176
  ret i64 %0, !insn.addr !2177

; uselistorder directives
  uselistorder i64 %0, { 1, 0, 2 }
}

define i64 @_ZN4llvm14InsertPositionC1EDn(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_9f50:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !2178
  %1 = add i64 %0, 8, !insn.addr !2179
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2179
  store i64 0, i64* %2, align 8, !insn.addr !2179
  %3 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1Ev(i64* %result), !insn.addr !2180
  ret i64 %3, !insn.addr !2181
}

define i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %result) local_unnamed_addr {
dec_label_pc_9f86:
  %0 = call i64 @_ZNK4llvm5Value10getValueIDEv(i64* %result), !insn.addr !2182
  %1 = add i64 %0, 4294967267, !insn.addr !2183
  %2 = and i64 %1, 4294967295, !insn.addr !2183
  ret i64 %2, !insn.addr !2184

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm5Value10getValueIDEv, { 1, 0, 3, 2 }
}

define i64 @_ZN4llvm8DebugLocaSEOS0_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_9fa8:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEEaSEOS2_(i64* %result, i64* %arg2), !insn.addr !2185
  ret i64 %0, !insn.addr !2186
}

define i64 @_ZNK4llvm11Instruction24getSubclassDataFromValueEv(i64* %result) local_unnamed_addr {
dec_label_pc_9fd6:
  %0 = call i64 @_ZNK4llvm5Value24getSubclassDataFromValueEv(i64* %result), !insn.addr !2187
  ret i64 %0, !insn.addr !2188
}

define i64 @_ZNK4llvm9DbgRecord13getRecordKindEv(i64* %result) local_unnamed_addr {
dec_label_pc_9ff4:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !2189
  %2 = inttoptr i64 %1 to i8*, !insn.addr !2189
  %3 = load i8, i8* %2, align 1, !insn.addr !2189
  %4 = zext i8 %3 to i64, !insn.addr !2189
  ret i64 %4, !insn.addr !2190
}

define i64 @_ZN4llvm17DbgVariableRecord7classofEPKNS_9DbgRecordE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a00a:
  %0 = call i64 @_ZNK4llvm9DbgRecord13getRecordKindEv(i64* %arg1), !insn.addr !2191
  %1 = trunc i64 %0 to i8, !insn.addr !2192
  %2 = icmp eq i8 %1, 0, !insn.addr !2192
  %3 = zext i1 %2 to i64, !insn.addr !2193
  %4 = and i64 %0, -256, !insn.addr !2193
  %5 = or i64 %4, %3, !insn.addr !2193
  ret i64 %5, !insn.addr !2194

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm10BasicBlock5beginEv(i64 %arg1, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_a02e:
  %rax.0.reg2mem = alloca i64, !insn.addr !2195
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2196
  %1 = add i64 %arg1, 48, !insn.addr !2197
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2198
  %3 = call i64 @_ZN4llvm12simple_ilistINS_11InstructionEJNS_19ilist_iterator_bitsILb1EEENS_12ilist_parentINS_10BasicBlockEEEEE5beginEv(i64* %2), !insn.addr !2198
  store i64 %3, i64* %stack_var_-40, align 8, !insn.addr !2199
  %4 = call i64 @_ZNK4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EE10setHeadBitEb(i64* nonnull %stack_var_-40, i1 true), !insn.addr !2200
  %5 = load i64, i64* %stack_var_-40, align 8, !insn.addr !2201
  %6 = call i64 @__readfsqword(i64 40), !insn.addr !2202
  %7 = icmp eq i64 %0, %6, !insn.addr !2202
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !2203
  br i1 %7, label %dec_label_pc_a092, label %dec_label_pc_a08d, !insn.addr !2203

dec_label_pc_a08d:                                ; preds = %dec_label_pc_a02e
  %8 = call i64 @__stack_chk_fail(), !insn.addr !2204
  store i64 %8, i64* %rax.0.reg2mem, !insn.addr !2204
  br label %dec_label_pc_a092, !insn.addr !2204

dec_label_pc_a092:                                ; preds = %dec_label_pc_a08d, %dec_label_pc_a02e
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2205

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 1, 0, 2 }
}

define i64 @_ZN4llvm10BasicBlock3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_a094:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 48, !insn.addr !2206
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2207
  %3 = call i64 @_ZN4llvm12simple_ilistINS_11InstructionEJNS_19ilist_iterator_bitsILb1EEENS_12ilist_parentINS_10BasicBlockEEEEE3endEv(i64* %2), !insn.addr !2207
  ret i64 %3, !insn.addr !2208
}

define i64 @_ZNK4llvm8Function14getIntrinsicIDEv(i64* %result) local_unnamed_addr {
dec_label_pc_a0b6:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 36, !insn.addr !2209
  %2 = inttoptr i64 %1 to i32*, !insn.addr !2209
  %3 = load i32, i32* %2, align 4, !insn.addr !2209
  %4 = zext i32 %3 to i64, !insn.addr !2209
  ret i64 %4, !insn.addr !2210
}

define i64 @_ZNK4llvm8Function11isIntrinsicEv(i64* %result) local_unnamed_addr {
dec_label_pc_a0cc:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 33, !insn.addr !2211
  %2 = inttoptr i64 %1 to i8*, !insn.addr !2211
  %3 = load i8, i8* %2, align 1, !insn.addr !2211
  %4 = and i8 %3, 32
  %5 = icmp eq i8 %4, 0, !insn.addr !2212
  %6 = icmp eq i1 %5, false, !insn.addr !2213
  %7 = zext i1 %6 to i64, !insn.addr !2213
  ret i64 %7, !insn.addr !2214

; uselistorder directives
  uselistorder i64 33, { 0, 2, 6, 1, 5, 3, 4 }
}

define i64 @_ZN4llvm8Function5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_a0ea:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 72, !insn.addr !2215
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2216
  %3 = call i64 @_ZN4llvm12simple_ilistINS_10BasicBlockEJEE5beginEv(i64* %2), !insn.addr !2216
  ret i64 %3, !insn.addr !2217
}

define i64 @_ZN4llvm8Function3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_a10c:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 72, !insn.addr !2218
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2219
  %3 = call i64 @_ZN4llvm12simple_ilistINS_10BasicBlockEJEE3endEv(i64* %2), !insn.addr !2219
  ret i64 %3, !insn.addr !2220
}

define i64 @_ZNK4llvm8Function5emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_a12e:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 72, !insn.addr !2221
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2222
  %3 = call i64 @_ZNK4llvm12simple_ilistINS_10BasicBlockEJEE5emptyEv(i64* %2), !insn.addr !2222
  ret i64 %3, !insn.addr !2223
}

define i64 @_ZN4llvm14ValueIsPresentIPNS_5ValueEvE11unwrapValueERS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_a150:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !2224
}

define i64 @_ZN4llvm6detail11unwrapValueIPNS_5ValueEEEDcRT_(i64** %arg1) local_unnamed_addr {
dec_label_pc_a162:
  %0 = call i64 @_ZN4llvm14ValueIsPresentIPNS_5ValueEvE11unwrapValueERS2_(i64** %arg1), !insn.addr !2225
  ret i64 %0, !insn.addr !2226
}

define i64 @_ZN4llvm4castINS_5ValueES1_EEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a180:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2227
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2228
  %2 = call i1 @_ZN4llvm3isaINS_5ValueEPS1_EEbRKT0_(i64** nonnull %1), !insn.addr !2228
  %3 = icmp eq i1 %2, false, !insn.addr !2229
  %4 = icmp eq i1 %3, false, !insn.addr !2230
  br i1 %4, label %dec_label_pc_a1c8, label %dec_label_pc_a1a0, !insn.addr !2230

dec_label_pc_a1a0:                                ; preds = %dec_label_pc_a180
  %5 = call i64 @__assert_fail(i64 ptrtoint ([60 x i8]* @global_var_50e4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 578, i64 ptrtoint ([65 x i8]* @global_var_506c to i64)), !insn.addr !2231
  br label %dec_label_pc_a1c8, !insn.addr !2231

dec_label_pc_a1c8:                                ; preds = %dec_label_pc_a1a0, %dec_label_pc_a180
  %6 = call i64 @_ZN4llvm8CastInfoINS_5ValueEPS1_vE6doCastERKS2_(i64** nonnull %1), !insn.addr !2232
  ret i64 %6, !insn.addr !2233
}

define i64 @_ZN4llvm15cast_if_presentINS_5ValueES1_EEDaPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a1d6:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2234
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2235
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_5ValueEEEbRKT_(i64** nonnull %1), !insn.addr !2235
  %3 = call i64 @_ZN4llvm8CastInfoINS_5ValueEPS1_vE10castFailedEv(), !insn.addr !2236
  ret i64 %3, !insn.addr !2237
}

define i64 @_ZN4llvm12cast_or_nullINS_5ValueES1_EEDaPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a252:
  %0 = call i64 @_ZN4llvm15cast_if_presentINS_5ValueES1_EEDaPT0_(i64* %arg1), !insn.addr !2238
  ret i64 %0, !insn.addr !2239
}

define i64 @_ZN4llvm16UnaryInstructionnwEm(i64 %arg1) local_unnamed_addr {
dec_label_pc_a274:
  %0 = inttoptr i64 %arg1 to i64*, !insn.addr !2240
  %1 = call i64 @_ZN4llvm4UsernwEmNS0_28IntrusiveOperandsAllocMarkerE(i64* %0, i64 1, i64 1), !insn.addr !2240
  ret i64 %1, !insn.addr !2241
}

define i64 @_ZN4llvm4castINS_11InstructionEKNS_5ValueEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a299:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2242
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2243
  %2 = call i1 @_ZN4llvm3isaINS_11InstructionEPKNS_5ValueEEEbRKT0_(i64** nonnull %1), !insn.addr !2243
  %3 = icmp eq i1 %2, false, !insn.addr !2244
  %4 = icmp eq i1 %3, false, !insn.addr !2245
  br i1 %4, label %dec_label_pc_a2e1, label %dec_label_pc_a2b9, !insn.addr !2245

dec_label_pc_a2b9:                                ; preds = %dec_label_pc_a299
  %5 = call i64 @__assert_fail(i64 ptrtoint ([60 x i8]* @global_var_50e4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 578, i64 ptrtoint ([77 x i8]* @global_var_51ac to i64)), !insn.addr !2246
  br label %dec_label_pc_a2e1, !insn.addr !2246

dec_label_pc_a2e1:                                ; preds = %dec_label_pc_a2b9, %dec_label_pc_a299
  %6 = call i64 @_ZN4llvm8CastInfoINS_11InstructionEPKNS_5ValueEvE6doCastERKS4_(i64** nonnull %1), !insn.addr !2247
  ret i64 %6, !insn.addr !2248
}

define i64 @_ZNK4llvm16UnaryInstruction10getOperandEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_a2f0:
  %0 = call i64 @_ZN4llvm21FixedNumOperandTraitsINS_16UnaryInstructionELj1EE8operandsEPKNS_4UserE(i64* %result), !insn.addr !2249
  %1 = trunc i64 %0 to i32, !insn.addr !2250
  %2 = icmp ugt i32 %1, %arg2, !insn.addr !2250
  br i1 %2, label %dec_label_pc_a33c, label %dec_label_pc_a314, !insn.addr !2251

dec_label_pc_a314:                                ; preds = %dec_label_pc_a2f0
  %3 = call i64 @__assert_fail(i64 ptrtoint ([94 x i8]* @global_var_5274 to i64), i64 ptrtoint ([42 x i8]* @global_var_5244 to i64), i64 95, i64 ptrtoint ([68 x i8]* @global_var_51fc to i64)), !insn.addr !2252
  br label %dec_label_pc_a33c, !insn.addr !2252

dec_label_pc_a33c:                                ; preds = %dec_label_pc_a314, %dec_label_pc_a2f0
  %4 = call i64 @_ZN4llvm21FixedNumOperandTraitsINS_16UnaryInstructionELj1EE8op_beginEPS1_(i64* %result), !insn.addr !2253
  %5 = zext i32 %arg2 to i64, !insn.addr !2254
  %6 = mul i64 %5, 32, !insn.addr !2255
  %7 = add i64 %4, %6, !insn.addr !2256
  %8 = inttoptr i64 %7 to i64*, !insn.addr !2257
  %9 = call i64 @_ZNK4llvm3Use3getEv(i64* %8), !insn.addr !2257
  %10 = inttoptr i64 %9 to i64*, !insn.addr !2258
  %11 = call i64 @_ZN4llvm12cast_or_nullINS_5ValueES1_EEDaPT0_(i64* %10), !insn.addr !2258
  ret i64 %11, !insn.addr !2259
}

define i64 @_ZN4llvm8CallBase7classofEPKNS_11InstructionE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a364:
  %0 = call i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %arg1), !insn.addr !2260
  %1 = trunc i64 %0 to i32, !insn.addr !2261
  %2 = icmp eq i32 %1, 56, !insn.addr !2261
  br i1 %2, label %dec_label_pc_a3b3, label %dec_label_pc_a385, !insn.addr !2262

dec_label_pc_a385:                                ; preds = %dec_label_pc_a364
  %3 = call i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %arg1), !insn.addr !2263
  %4 = trunc i64 %3 to i32, !insn.addr !2264
  %5 = icmp eq i32 %4, 5, !insn.addr !2264
  br i1 %5, label %dec_label_pc_a3b3, label %dec_label_pc_a396, !insn.addr !2265

dec_label_pc_a396:                                ; preds = %dec_label_pc_a385
  %6 = call i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %arg1), !insn.addr !2266
  %7 = trunc i64 %6 to i32, !insn.addr !2267
  %8 = icmp eq i32 %7, 11, !insn.addr !2267
  %spec.select = zext i1 %8 to i64
  ret i64 %spec.select

dec_label_pc_a3b3:                                ; preds = %dec_label_pc_a364, %dec_label_pc_a385
  ret i64 1, !insn.addr !2268

; uselistorder directives
  uselistorder label %dec_label_pc_a3b3, { 1, 0 }
}

define i64 @_ZNK4llvm8CallBase16getCalledOperandEv(i64* %result) local_unnamed_addr {
dec_label_pc_a3b6:
  %0 = call i64* @_ZNK4llvm8CallBase2OpILin1EEERKNS_3UseEv(i64* %result), !insn.addr !2269
  %1 = call i64 @_ZNK4llvm3UsecvPNS_5ValueEEv(i64* %0), !insn.addr !2270
  ret i64 %1, !insn.addr !2271
}

define i64 @_ZN4llvm19dyn_cast_if_presentINS_8FunctionENS_5ValueEEEDaPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a3dc:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2272
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2273
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_5ValueEEEbRKT_(i64** nonnull %1), !insn.addr !2273
  %3 = call i64 @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE10castFailedEv(), !insn.addr !2274
  ret i64 %3, !insn.addr !2275
}

define i64 @_ZN4llvm16dyn_cast_or_nullINS_8FunctionENS_5ValueEEEDaPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a41d:
  %0 = call i64 @_ZN4llvm19dyn_cast_if_presentINS_8FunctionENS_5ValueEEEDaPT0_(i64* %arg1), !insn.addr !2276
  ret i64 %0, !insn.addr !2277
}

define i64 @_ZN4llvm8dyn_castINS_11InstructionEKNS_5ValueEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a43b:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2278
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2279
  %2 = call i1 @_ZN4llvm6detail9isPresentIPKNS_5ValueEEEbRKT_(i64** nonnull %1), !insn.addr !2279
  %3 = icmp eq i1 %2, false, !insn.addr !2280
  %4 = icmp eq i1 %3, false, !insn.addr !2281
  br i1 %4, label %dec_label_pc_a483, label %dec_label_pc_a45b, !insn.addr !2281

dec_label_pc_a45b:                                ; preds = %dec_label_pc_a43b
  %5 = call i64 @__assert_fail(i64 ptrtoint ([61 x i8]* @global_var_5334 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 662, i64 ptrtoint ([81 x i8]* @global_var_52dc to i64)), !insn.addr !2282
  br label %dec_label_pc_a483, !insn.addr !2282

dec_label_pc_a483:                                ; preds = %dec_label_pc_a45b, %dec_label_pc_a43b
  %6 = call i64 @_ZN4llvm8CastInfoINS_11InstructionEPKNS_5ValueEvE16doCastIfPossibleERKS4_(i64** nonnull %1), !insn.addr !2283
  ret i64 %6, !insn.addr !2284
}

define i64 @_ZN4llvm8dyn_castINS_10StructTypeENS_4TypeEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a491:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2285
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2286
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_4TypeEEEbRKT_(i64** nonnull %1), !insn.addr !2286
  %3 = icmp eq i1 %2, false, !insn.addr !2287
  %4 = icmp eq i1 %3, false, !insn.addr !2288
  br i1 %4, label %dec_label_pc_a4d9, label %dec_label_pc_a4b1, !insn.addr !2288

dec_label_pc_a4b1:                                ; preds = %dec_label_pc_a491
  %5 = call i64 @__assert_fail(i64 ptrtoint ([61 x i8]* @global_var_5334 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 662, i64 ptrtoint ([73 x i8]* @global_var_5374 to i64)), !insn.addr !2289
  br label %dec_label_pc_a4d9, !insn.addr !2289

dec_label_pc_a4d9:                                ; preds = %dec_label_pc_a4b1, %dec_label_pc_a491
  %6 = call i64 @_ZN4llvm8CastInfoINS_10StructTypeEPNS_4TypeEvE16doCastIfPossibleERKS3_(i64** nonnull %1), !insn.addr !2290
  ret i64 %6, !insn.addr !2291
}

define i64 @_ZN4llvm8dyn_castINS_9ArrayTypeENS_4TypeEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a4e7:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2292
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2293
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_4TypeEEEbRKT_(i64** nonnull %1), !insn.addr !2293
  %3 = icmp eq i1 %2, false, !insn.addr !2294
  %4 = icmp eq i1 %3, false, !insn.addr !2295
  br i1 %4, label %dec_label_pc_a52f, label %dec_label_pc_a507, !insn.addr !2295

dec_label_pc_a507:                                ; preds = %dec_label_pc_a4e7
  %5 = call i64 @__assert_fail(i64 ptrtoint ([61 x i8]* @global_var_5334 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 662, i64 ptrtoint ([72 x i8]* @global_var_53c4 to i64)), !insn.addr !2296
  br label %dec_label_pc_a52f, !insn.addr !2296

dec_label_pc_a52f:                                ; preds = %dec_label_pc_a507, %dec_label_pc_a4e7
  %6 = call i64 @_ZN4llvm8CastInfoINS_9ArrayTypeEPNS_4TypeEvE16doCastIfPossibleERKS3_(i64** nonnull %1), !insn.addr !2297
  ret i64 %6, !insn.addr !2298
}

define i64 @_ZN4llvm14FPMathOperator41isComposedOfHomogeneousFloatingPointTypesEPNS_4TypeE(i64* %this, i64* %result, i64* %arg3) local_unnamed_addr {
dec_label_pc_a53d:
  %rax.0.reg2mem = alloca i64, !insn.addr !2299
  %storemerge.reg2mem = alloca i64, !insn.addr !2299
  %stack_var_-64.0.reg2mem = alloca i64, !insn.addr !2299
  %stack_var_-56.0.reg2mem = alloca i64, !insn.addr !2299
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2300
  %1 = call i64 @_ZN4llvm8dyn_castINS_10StructTypeENS_4TypeEEEDcPT0_(i64* %this), !insn.addr !2301
  %2 = icmp eq i64 %1, 0, !insn.addr !2302
  br i1 %2, label %dec_label_pc_a5d9, label %dec_label_pc_a573, !insn.addr !2303

dec_label_pc_a573:                                ; preds = %dec_label_pc_a53d
  %3 = inttoptr i64 %1 to i64*, !insn.addr !2304
  %4 = call i64 @_ZNK4llvm10StructType9isLiteralEv(i64* %3), !insn.addr !2304
  %5 = trunc i64 %4 to i8
  %6 = icmp eq i8 %5, 1, !insn.addr !2305
  %7 = icmp eq i1 %6, false, !insn.addr !2306
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2306
  br i1 %7, label %dec_label_pc_a629, label %dec_label_pc_a586, !insn.addr !2306

dec_label_pc_a586:                                ; preds = %dec_label_pc_a573
  %8 = call i64 @_ZNK4llvm10StructType24containsHomogeneousTypesEv(i64* %3), !insn.addr !2307
  %9 = trunc i64 %8 to i8
  %10 = icmp ne i8 %9, 1, !insn.addr !2308
  %phitmp = icmp eq i1 %10, false
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2309
  br i1 %phitmp, label %dec_label_pc_a5b0, label %dec_label_pc_a629, !insn.addr !2309

dec_label_pc_a5b0:                                ; preds = %dec_label_pc_a586
  %11 = call i64 @_ZNK4llvm10StructType8elementsEv(i64* %3), !insn.addr !2310
  store i64 %11, i64* %stack_var_-40, align 8, !insn.addr !2311
  %12 = call i64 @_ZNK4llvm8ArrayRefIPNS_4TypeEE5frontEv(i64* nonnull %stack_var_-40), !insn.addr !2312
  %13 = inttoptr i64 %12 to i64*, !insn.addr !2313
  %14 = load i64, i64* %13, align 8, !insn.addr !2313
  store i64 %14, i64* %stack_var_-64.0.reg2mem, !insn.addr !2314
  br label %dec_label_pc_a61c, !insn.addr !2314

dec_label_pc_a5d9:                                ; preds = %dec_label_pc_a53d
  %15 = ptrtoint i64* %this to i64
  %16 = call i64 @_ZN4llvm8dyn_castINS_9ArrayTypeENS_4TypeEEEDcPT0_(i64* %this), !insn.addr !2315
  %17 = icmp eq i64 %16, 0, !insn.addr !2316
  store i64 %16, i64* %stack_var_-56.0.reg2mem, !insn.addr !2317
  store i64 %15, i64* %stack_var_-64.0.reg2mem, !insn.addr !2317
  br i1 %17, label %dec_label_pc_a61c, label %dec_label_pc_a5f0, !insn.addr !2317

dec_label_pc_a5f0:                                ; preds = %dec_label_pc_a5d9, %dec_label_pc_a5f0
  %stack_var_-56.0.reload = load i64, i64* %stack_var_-56.0.reg2mem
  %18 = inttoptr i64 %stack_var_-56.0.reload to i64*, !insn.addr !2318
  %19 = call i64 @_ZNK4llvm9ArrayType14getElementTypeEv(i64* %18), !insn.addr !2318
  %20 = inttoptr i64 %19 to i64*, !insn.addr !2319
  %21 = call i64 @_ZN4llvm8dyn_castINS_9ArrayTypeENS_4TypeEEEDcPT0_(i64* %20), !insn.addr !2319
  %22 = icmp eq i64 %21, 0, !insn.addr !2320
  %23 = icmp eq i1 %22, false, !insn.addr !2321
  %24 = icmp eq i1 %23, false, !insn.addr !2322
  %25 = icmp eq i1 %24, false, !insn.addr !2323
  store i64 %21, i64* %stack_var_-56.0.reg2mem, !insn.addr !2323
  store i64 %19, i64* %stack_var_-64.0.reg2mem, !insn.addr !2323
  br i1 %25, label %dec_label_pc_a5f0, label %dec_label_pc_a61c, !insn.addr !2323

dec_label_pc_a61c:                                ; preds = %dec_label_pc_a5f0, %dec_label_pc_a5d9, %dec_label_pc_a5b0
  %stack_var_-64.0.reload = load i64, i64* %stack_var_-64.0.reg2mem
  %26 = inttoptr i64 %stack_var_-64.0.reload to i64*, !insn.addr !2324
  %27 = call i64 @_ZNK4llvm4Type16isFPOrFPVectorTyEv(i64* %26), !insn.addr !2324
  store i64 %27, i64* %storemerge.reg2mem, !insn.addr !2325
  br label %dec_label_pc_a629, !insn.addr !2325

dec_label_pc_a629:                                ; preds = %dec_label_pc_a573, %dec_label_pc_a586, %dec_label_pc_a61c
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %28 = call i64 @__readfsqword(i64 40), !insn.addr !2326
  %29 = icmp eq i64 %0, %28, !insn.addr !2326
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !2327
  br i1 %29, label %dec_label_pc_a63d, label %dec_label_pc_a638, !insn.addr !2327

dec_label_pc_a638:                                ; preds = %dec_label_pc_a629
  %30 = call i64 @__stack_chk_fail(), !insn.addr !2328
  store i64 %30, i64* %rax.0.reg2mem, !insn.addr !2328
  br label %dec_label_pc_a63d, !insn.addr !2328

dec_label_pc_a63d:                                ; preds = %dec_label_pc_a638, %dec_label_pc_a629
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2329

; uselistorder directives
  uselistorder i64* %stack_var_-56.0.reg2mem, { 2, 0, 1 }
  uselistorder i64* %stack_var_-64.0.reg2mem, { 0, 1, 3, 2 }
  uselistorder i64* %storemerge.reg2mem, { 0, 3, 2, 1 }
  uselistorder i64 (i64*)* @_ZN4llvm8dyn_castINS_9ArrayTypeENS_4TypeEEEDcPT0_, { 1, 0 }
  uselistorder i64* %this, { 0, 2, 1 }
  uselistorder label %dec_label_pc_a629, { 2, 1, 0 }
  uselistorder label %dec_label_pc_a5f0, { 1, 0 }
}

define i64 @_ZN4llvm14FPMathOperator28isSupportedFloatingPointTypeEPNS_4TypeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a63f:
  %0 = alloca i64
  %1 = load i64, i64* %0
  %2 = load i64, i64* %0
  %3 = call i64 @_ZNK4llvm4Type16isFPOrFPVectorTyEv(i64* %arg1), !insn.addr !2330
  %4 = trunc i64 %3 to i8, !insn.addr !2331
  %5 = icmp eq i8 %4, 0, !insn.addr !2331
  %6 = icmp eq i1 %5, false, !insn.addr !2332
  br i1 %6, label %dec_label_pc_a67b, label %dec_label_pc_a65f, !insn.addr !2332

dec_label_pc_a65f:                                ; preds = %dec_label_pc_a63f
  %7 = inttoptr i64 %1 to i64*, !insn.addr !2333
  %8 = inttoptr i64 %2 to i64*, !insn.addr !2333
  %9 = call i64 @_ZN4llvm14FPMathOperator41isComposedOfHomogeneousFloatingPointTypesEPNS_4TypeE(i64* %arg1, i64* %7, i64* %8), !insn.addr !2333
  %10 = trunc i64 %9 to i8, !insn.addr !2334
  %11 = icmp ne i8 %10, 0, !insn.addr !2334
  %spec.select = zext i1 %11 to i64
  ret i64 %spec.select

dec_label_pc_a67b:                                ; preds = %dec_label_pc_a63f
  ret i64 1, !insn.addr !2335

; uselistorder directives
  uselistorder i64* %0, { 1, 0 }
}

define i64 @_ZN4llvm14FPMathOperator7classofEPKNS_5ValueE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a67d:
  %rax.0.reg2mem = alloca i64, !insn.addr !2336
  %0 = call i64 @_ZN4llvm8dyn_castINS_11InstructionEKNS_5ValueEEEDcPT0_(i64* %arg1), !insn.addr !2337
  %1 = icmp eq i64 %0, 0, !insn.addr !2338
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !2339
  br i1 %1, label %dec_label_pc_a726, label %dec_label_pc_a6a4, !insn.addr !2339

dec_label_pc_a6a4:                                ; preds = %dec_label_pc_a67d
  %2 = inttoptr i64 %0 to i64*, !insn.addr !2340
  %3 = call i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %2), !insn.addr !2340
  %4 = trunc i64 %3 to i32, !insn.addr !2341
  %5 = icmp ult i32 %4, 58
  %6 = icmp ne i1 %5, true, !insn.addr !2342
  %7 = icmp eq i1 %6, false, !insn.addr !2343
  %8 = icmp eq i1 %7, false, !insn.addr !2344
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !2344
  br i1 %8, label %dec_label_pc_a726, label %dec_label_pc_a6c7, !insn.addr !2344

dec_label_pc_a6c7:                                ; preds = %dec_label_pc_a6a4
  %9 = and i64 %3, and (i64 ptrtoint ([3 x i8]* @global_var_3f to i64), i64 255), !insn.addr !2345
  %10 = shl i64 1, %9
  %11 = and i64 %10, 18119951644971008, !insn.addr !2346
  %12 = icmp eq i64 %11, 0, !insn.addr !2347
  %13 = icmp eq i1 %12, false, !insn.addr !2348
  %14 = icmp eq i1 %13, false, !insn.addr !2349
  %15 = icmp eq i1 %14, false, !insn.addr !2350
  store i64 1, i64* %rax.0.reg2mem, !insn.addr !2350
  br i1 %15, label %dec_label_pc_a726, label %dec_label_pc_a6eb, !insn.addr !2350

dec_label_pc_a6eb:                                ; preds = %dec_label_pc_a6c7
  %16 = urem i64 %10, 252201579132747777, !insn.addr !2351
  %17 = icmp eq i64 %16, 0, !insn.addr !2352
  %18 = icmp eq i1 %17, false, !insn.addr !2353
  %19 = icmp eq i1 %18, false, !insn.addr !2354
  %20 = icmp eq i1 %19, false, !insn.addr !2355
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !2355
  br i1 %20, label %dec_label_pc_a70b, label %dec_label_pc_a726, !insn.addr !2355

dec_label_pc_a70b:                                ; preds = %dec_label_pc_a6eb
  %21 = call i64 @_ZNK4llvm5Value7getTypeEv(i64* %arg1), !insn.addr !2356
  %22 = inttoptr i64 %21 to i64*, !insn.addr !2357
  %23 = call i64 @_ZN4llvm14FPMathOperator28isSupportedFloatingPointTypeEPNS_4TypeE(i64* %22), !insn.addr !2357
  store i64 %23, i64* %rax.0.reg2mem, !insn.addr !2358
  br label %dec_label_pc_a726, !insn.addr !2358

dec_label_pc_a726:                                ; preds = %dec_label_pc_a6a4, %dec_label_pc_a6eb, %dec_label_pc_a6c7, %dec_label_pc_a67d, %dec_label_pc_a70b
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2359

; uselistorder directives
  uselistorder i64* %rax.0.reg2mem, { 0, 5, 2, 3, 1, 4 }
  uselistorder label %dec_label_pc_a726, { 4, 1, 2, 0, 3 }
}

define i64 @_ZNK4llvm8LoadInst10isVolatileEv(i64* %result) local_unnamed_addr {
dec_label_pc_a728:
  %0 = call i64 @_ZNK4llvm11Instruction15getSubclassDataINS_8Bitfield7ElementIbLj0ELj1ELb1EEEEENT_4TypeEv(i64* %result), !insn.addr !2360
  ret i64 %0, !insn.addr !2361
}

define i64 @_ZN4llvm8LoadInst17getPointerOperandEv(i64* %result) local_unnamed_addr {
dec_label_pc_a746:
  %0 = call i64 @_ZNK4llvm16UnaryInstruction10getOperandEj(i64* %result, i32 0), !insn.addr !2362
  ret i64 %0, !insn.addr !2363
}

define i64 @_ZN4llvm8LoadInst7classofEPKNS_11InstructionE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a769:
  %0 = call i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %arg1), !insn.addr !2364
  %1 = trunc i64 %0 to i32, !insn.addr !2365
  %2 = icmp eq i32 %1, 32, !insn.addr !2365
  %3 = zext i1 %2 to i64, !insn.addr !2366
  %4 = and i64 %0, -256, !insn.addr !2366
  %5 = or i64 %4, %3, !insn.addr !2366
  ret i64 %5, !insn.addr !2367

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm9StoreInst10isVolatileEv(i64* %result) local_unnamed_addr {
dec_label_pc_a78e:
  %0 = call i64 @_ZNK4llvm11Instruction15getSubclassDataINS_8Bitfield7ElementIbLj0ELj1ELb1EEEEENT_4TypeEv(i64* %result), !insn.addr !2368
  ret i64 %0, !insn.addr !2369

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm11Instruction15getSubclassDataINS_8Bitfield7ElementIbLj0ELj1ELb1EEEEENT_4TypeEv, { 1, 0 }
}

define i64 @_ZN4llvm9StoreInst15getValueOperandEv(i64* %result) local_unnamed_addr {
dec_label_pc_a7ac:
  %0 = call i64 @_ZNK4llvm9StoreInst10getOperandEj(i64* %result, i32 0), !insn.addr !2370
  ret i64 %0, !insn.addr !2371
}

define i64 @_ZN4llvm9StoreInst17getPointerOperandEv(i64* %result) local_unnamed_addr {
dec_label_pc_a7d0:
  %0 = call i64 @_ZNK4llvm9StoreInst10getOperandEj(i64* %result, i32 1), !insn.addr !2372
  ret i64 %0, !insn.addr !2373

; uselistorder directives
  uselistorder i64 (i64*, i32)* @_ZNK4llvm9StoreInst10getOperandEj, { 1, 0 }
}

define i64 @_ZN4llvm9StoreInst7classofEPKNS_11InstructionE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a7f3:
  %0 = call i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %arg1), !insn.addr !2374
  %1 = trunc i64 %0 to i32, !insn.addr !2375
  %2 = icmp eq i32 %1, 33, !insn.addr !2375
  %3 = zext i1 %2 to i64, !insn.addr !2376
  %4 = and i64 %0, -256, !insn.addr !2376
  %5 = or i64 %4, %3, !insn.addr !2376
  ret i64 %5, !insn.addr !2377

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNK4llvm9StoreInst10getOperandEj(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_a818:
  %0 = call i64 @_ZN4llvm21FixedNumOperandTraitsINS_9StoreInstELj2EE8operandsEPKNS_4UserE(i64* %result), !insn.addr !2378
  %1 = trunc i64 %0 to i32, !insn.addr !2379
  %2 = icmp ugt i32 %1, %arg2, !insn.addr !2379
  br i1 %2, label %dec_label_pc_a864, label %dec_label_pc_a83c, !insn.addr !2380

dec_label_pc_a83c:                                ; preds = %dec_label_pc_a818
  %3 = call i64 @__assert_fail(i64 ptrtoint ([87 x i8]* @global_var_547c to i64), i64 ptrtoint ([44 x i8]* @global_var_544c to i64), i64 422, i64 ptrtoint ([61 x i8]* @global_var_540c to i64)), !insn.addr !2381
  br label %dec_label_pc_a864, !insn.addr !2381

dec_label_pc_a864:                                ; preds = %dec_label_pc_a83c, %dec_label_pc_a818
  %4 = call i64 @_ZN4llvm21FixedNumOperandTraitsINS_9StoreInstELj2EE8op_beginEPS1_(i64* %result), !insn.addr !2382
  %5 = zext i32 %arg2 to i64, !insn.addr !2383
  %6 = mul i64 %5, 32, !insn.addr !2384
  %7 = add i64 %4, %6, !insn.addr !2385
  %8 = inttoptr i64 %7 to i64*, !insn.addr !2386
  %9 = call i64 @_ZNK4llvm3Use3getEv(i64* %8), !insn.addr !2386
  %10 = inttoptr i64 %9 to i64*, !insn.addr !2387
  %11 = call i64 @_ZN4llvm12cast_or_nullINS_5ValueES1_EEDaPT0_(i64* %10), !insn.addr !2387
  ret i64 %11, !insn.addr !2388

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm12cast_or_nullINS_5ValueES1_EEDaPT0_, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm3Use3getEv, { 1, 0 }
}

define i64 @_ZN4llvm8ArrayRefINS_17OperandBundleDefTIPNS_5ValueEEEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_a88c:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !2389
  %1 = add i64 %0, 8, !insn.addr !2390
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2390
  store i64 0, i64* %2, align 8, !insn.addr !2390
  ret i64 %0, !insn.addr !2391

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm8CallInst7classofEPKNS_11InstructionE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a8b2:
  %0 = call i64 @_ZNK4llvm11Instruction9getOpcodeEv(i64* %arg1), !insn.addr !2392
  %1 = trunc i64 %0 to i32, !insn.addr !2393
  %2 = icmp eq i32 %1, 56, !insn.addr !2393
  %3 = zext i1 %2 to i64, !insn.addr !2394
  %4 = and i64 %0, -256, !insn.addr !2394
  %5 = or i64 %4, %3, !insn.addr !2394
  ret i64 %5, !insn.addr !2395

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm11Instruction9getOpcodeEv, { 1, 3, 2, 0, 6, 5, 4 }
}

define i64 @_ZN4llvm8CallInst7classofEPKNS_5ValueE(i64* %arg1) local_unnamed_addr {
dec_label_pc_a8d6:
  %storemerge.reg2mem = alloca i64, !insn.addr !2396
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2397
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2398
  %2 = call i1 @_ZN4llvm3isaINS_11InstructionEPKNS_5ValueEEEbRKT0_(i64** nonnull %1), !insn.addr !2398
  %3 = icmp eq i1 %2, false, !insn.addr !2399
  br i1 %3, label %dec_label_pc_a915, label %dec_label_pc_a8f6, !insn.addr !2400

dec_label_pc_a8f6:                                ; preds = %dec_label_pc_a8d6
  %4 = load i64, i64* %stack_var_-16, align 8, !insn.addr !2401
  %5 = inttoptr i64 %4 to i64*, !insn.addr !2402
  %6 = call i64 @_ZN4llvm4castINS_11InstructionEKNS_5ValueEEEDcPT0_(i64* %5), !insn.addr !2402
  %7 = inttoptr i64 %6 to i64*, !insn.addr !2403
  %8 = call i64 @_ZN4llvm8CallInst7classofEPKNS_11InstructionE(i64* %7), !insn.addr !2403
  %9 = trunc i64 %8 to i8, !insn.addr !2404
  %10 = icmp eq i8 %9, 0, !insn.addr !2404
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !2405
  br i1 %10, label %dec_label_pc_a915, label %dec_label_pc_a91a, !insn.addr !2405

dec_label_pc_a915:                                ; preds = %dec_label_pc_a8f6, %dec_label_pc_a8d6
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2406
  br label %dec_label_pc_a91a, !insn.addr !2406

dec_label_pc_a91a:                                ; preds = %dec_label_pc_a8f6, %dec_label_pc_a915
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2407

; uselistorder directives
  uselistorder i64* %stack_var_-16, { 1, 0, 2 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_a91a, { 1, 0 }
}

define i64 @_ZN4llvm8dyn_castINS_8LoadInstENS_11InstructionEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a91c:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2408
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2409
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_11InstructionEEEbRKT_(i64** nonnull %1), !insn.addr !2409
  %3 = icmp eq i1 %2, false, !insn.addr !2410
  %4 = icmp eq i1 %3, false, !insn.addr !2411
  br i1 %4, label %dec_label_pc_a964, label %dec_label_pc_a93c, !insn.addr !2411

dec_label_pc_a93c:                                ; preds = %dec_label_pc_a91c
  %5 = call i64 @__assert_fail(i64 ptrtoint ([61 x i8]* @global_var_5334 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 662, i64 ptrtoint ([78 x i8]* @global_var_54dc to i64)), !insn.addr !2412
  br label %dec_label_pc_a964, !insn.addr !2412

dec_label_pc_a964:                                ; preds = %dec_label_pc_a93c, %dec_label_pc_a91c
  %6 = call i64 @_ZN4llvm8CastInfoINS_8LoadInstEPNS_11InstructionEvE16doCastIfPossibleERKS3_(i64** nonnull %1), !insn.addr !2413
  ret i64 %6, !insn.addr !2414
}

define i64 @_ZN4llvm8dyn_castINS_9StoreInstENS_11InstructionEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_a972:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2415
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2416
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_11InstructionEEEbRKT_(i64** nonnull %1), !insn.addr !2416
  %3 = icmp eq i1 %2, false, !insn.addr !2417
  %4 = icmp eq i1 %3, false, !insn.addr !2418
  br i1 %4, label %dec_label_pc_a9ba, label %dec_label_pc_a992, !insn.addr !2418

dec_label_pc_a992:                                ; preds = %dec_label_pc_a972
  %5 = call i64 @__assert_fail(i64 ptrtoint ([61 x i8]* @global_var_5334 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 662, i64 ptrtoint ([79 x i8]* @global_var_552c to i64)), !insn.addr !2419
  br label %dec_label_pc_a9ba, !insn.addr !2419

dec_label_pc_a9ba:                                ; preds = %dec_label_pc_a992, %dec_label_pc_a972
  %6 = call i64 @_ZN4llvm8CastInfoINS_9StoreInstEPNS_11InstructionEvE16doCastIfPossibleERKS3_(i64** nonnull %1), !insn.addr !2420
  ret i64 %6, !insn.addr !2421
}

define i64 @_ZN4llvm24IRBuilderDefaultInserterC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_a9c8:
  %0 = ptrtoint i64* %result to i64
  %1 = load i64, i64* inttoptr (i64 43483 to i64*), align 8, !insn.addr !2422
  %2 = add i64 %1, 16, !insn.addr !2423
  store i64 %2, i64* %result, align 8, !insn.addr !2424
  ret i64 %0, !insn.addr !2425
}

define i64 @_ZNK4llvm9FMFSource3getENS_13FastMathFlagsE(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_a9ea:
  %stack_var_-20 = alloca i64, align 8
  %sext = mul i64 %arg2, 4294967296
  %0 = ashr exact i64 %sext, 32, !insn.addr !2426
  store i64 %0, i64* %stack_var_-20, align 8, !insn.addr !2426
  %1 = bitcast i64* %stack_var_-20 to i64**, !insn.addr !2427
  %2 = call i64 @_ZNKRSt8optionalIN4llvm13FastMathFlagsEE8value_orIRS1_EES1_OT_(i64* %result, i64** nonnull %1), !insn.addr !2427
  ret i64 %2, !insn.addr !2428

; uselistorder directives
  uselistorder i64* %stack_var_-20, { 1, 0 }
}

define i64 @_ZN4llvm13IRBuilderBaseC1ERNS_11LLVMContextERKNS_15IRBuilderFolderERKNS_24IRBuilderDefaultInserterEPNS_6MDNodeENS_8ArrayRefINS_17OperandBundleDefTIPNS_5ValueEEEEE(i64* %this, i64* %result, i64* %arg3, i64* %arg4, i64* %arg5, i64* %arg6, i64 %arg7) local_unnamed_addr {
dec_label_pc_aa12:
  %0 = ptrtoint i64* %arg6 to i64
  %1 = ptrtoint i64* %arg5 to i64
  %2 = ptrtoint i64* %arg4 to i64
  %3 = ptrtoint i64* %arg3 to i64
  %4 = ptrtoint i64* %result to i64
  %5 = ptrtoint i64* %this to i64
  %6 = call i64 @_ZN4llvm11SmallVectorISt4pairIjPNS_6MDNodeEELj2EEC1Ev(i64* %this), !insn.addr !2429
  %7 = add i64 %5, 48, !insn.addr !2430
  %8 = inttoptr i64 %7 to i64*, !insn.addr !2431
  %9 = call i64 @_ZN4llvm8DebugLocC1Ev(i64* %8), !insn.addr !2431
  %10 = add i64 %5, ptrtoint (i128** @global_var_40 to i64), !insn.addr !2432
  %11 = inttoptr i64 %10 to i64*, !insn.addr !2433
  %12 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1Ev(i64* %11), !insn.addr !2433
  %13 = add i64 %5, 80, !insn.addr !2434
  %14 = inttoptr i64 %13 to i64*, !insn.addr !2434
  store i64 %4, i64* %14, align 8, !insn.addr !2434
  %15 = add i64 %5, 88, !insn.addr !2435
  %16 = inttoptr i64 %15 to i64*, !insn.addr !2435
  store i64 %3, i64* %16, align 8, !insn.addr !2435
  %17 = add i64 %5, 96, !insn.addr !2436
  %18 = inttoptr i64 %17 to i64*, !insn.addr !2436
  store i64 %2, i64* %18, align 8, !insn.addr !2436
  %19 = add i64 %5, 104, !insn.addr !2437
  %20 = inttoptr i64 %19 to i64*, !insn.addr !2437
  store i64 %1, i64* %20, align 8, !insn.addr !2437
  %21 = add i64 %5, 112, !insn.addr !2438
  %22 = inttoptr i64 %21 to i64*, !insn.addr !2439
  %23 = call i64 @_ZN4llvm13FastMathFlagsC1Ev(i64* %22), !insn.addr !2439
  %24 = add i64 %5, 116, !insn.addr !2440
  %25 = inttoptr i64 %24 to i8*, !insn.addr !2440
  store i8 0, i8* %25, align 1, !insn.addr !2440
  %26 = add i64 %5, 117, !insn.addr !2441
  %27 = inttoptr i64 %26 to i8*, !insn.addr !2441
  store i8 2, i8* %27, align 1, !insn.addr !2441
  %28 = add i64 %5, 118, !insn.addr !2442
  %29 = inttoptr i64 %28 to i8*, !insn.addr !2442
  store i8 7, i8* %29, align 1, !insn.addr !2442
  %30 = add i64 %5, 120, !insn.addr !2443
  %31 = inttoptr i64 %30 to i64*, !insn.addr !2443
  store i64 %0, i64* %31, align 8, !insn.addr !2443
  %32 = add i64 %5, 128, !insn.addr !2444
  %33 = inttoptr i64 %32 to i64*, !insn.addr !2444
  store i64 %arg7, i64* %33, align 8, !insn.addr !2444
  %34 = call i64 @_ZN4llvm13IRBuilderBase19ClearInsertionPointEv(i64* %this), !insn.addr !2445
  ret i64 %34, !insn.addr !2446

; uselistorder directives
  uselistorder i64 %5, { 1, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
}

define i64 @_ZN4llvm13IRBuilderBase19ClearInsertionPointEv(i64* %result) local_unnamed_addr {
dec_label_pc_aadc:
  %rax.0.reg2mem = alloca i64, !insn.addr !2447
  %0 = ptrtoint i64* %result to i64
  %stack_var_-40 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !2448
  %2 = add i64 %0, 56, !insn.addr !2449
  %3 = inttoptr i64 %2 to i64*, !insn.addr !2449
  store i64 0, i64* %3, align 8, !insn.addr !2449
  store i64 0, i64* %stack_var_-40, align 8, !insn.addr !2450
  %4 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1Ev(i64* nonnull %stack_var_-40), !insn.addr !2451
  %5 = load i64, i64* %stack_var_-40, align 8, !insn.addr !2452
  %6 = add i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !2453
  %7 = inttoptr i64 %6 to i64*, !insn.addr !2453
  store i64 %5, i64* %7, align 8, !insn.addr !2453
  %8 = add i64 %0, 72, !insn.addr !2454
  %9 = inttoptr i64 %8 to i16*, !insn.addr !2454
  store i16 0, i16* %9, align 2, !insn.addr !2454
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !2455
  %11 = icmp eq i64 %1, %10, !insn.addr !2455
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !2456
  br i1 %11, label %dec_label_pc_ab4c, label %dec_label_pc_ab47, !insn.addr !2456

dec_label_pc_ab47:                                ; preds = %dec_label_pc_aadc
  %12 = call i64 @__stack_chk_fail(), !insn.addr !2457
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !2457
  br label %dec_label_pc_ab4c, !insn.addr !2457

dec_label_pc_ab4c:                                ; preds = %dec_label_pc_ab47, %dec_label_pc_aadc
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2458

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 1, 0, 2 }
  uselistorder i64 %0, { 1, 0, 2 }
  uselistorder i64 (i64*)* @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1Ev, { 2, 1, 0 }
}

define i64 @_ZN4llvm13IRBuilderBase14SetInsertPointEPNS_11InstructionE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_ab4e:
  %rax.0.reg2mem = alloca i64, !insn.addr !2459
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %stack_var_-40 = alloca i64, align 8
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !2460
  %3 = add i64 %0, 24, !insn.addr !2461
  %4 = inttoptr i64 %3 to i64*, !insn.addr !2462
  %5 = call i64 @_ZN4llvm12ilist_detail18node_parent_accessINS_15ilist_node_implINS0_12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEEES5_E9getParentEv(i64* %4), !insn.addr !2462
  %6 = add i64 %1, 56, !insn.addr !2463
  %7 = inttoptr i64 %6 to i64*, !insn.addr !2463
  store i64 %5, i64* %7, align 8, !insn.addr !2463
  %8 = call i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEE11getIteratorEv(i64* %4), !insn.addr !2464
  store i64 %8, i64* %stack_var_-40, align 8, !insn.addr !2465
  %9 = add i64 %1, ptrtoint (i128** @global_var_40 to i64), !insn.addr !2466
  %10 = inttoptr i64 %9 to i64*, !insn.addr !2466
  store i64 %8, i64* %10, align 8, !insn.addr !2466
  %11 = trunc i64 %1 to i16, !insn.addr !2467
  %12 = add i64 %1, 72, !insn.addr !2468
  %13 = inttoptr i64 %12 to i16*, !insn.addr !2468
  store i16 %11, i16* %13, align 2, !insn.addr !2468
  %14 = load i64, i64* %7, align 8, !insn.addr !2469
  %15 = inttoptr i64 %14 to i64*, !insn.addr !2470
  %16 = call i64 @_ZN4llvm10BasicBlock3endEv(i64* %15), !insn.addr !2470
  store i64 %16, i64* %stack_var_-40, align 8, !insn.addr !2471
  %17 = call i64 @_ZN4llvmneERKNS_21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEES8_(i64* %10, i64* nonnull %stack_var_-40), !insn.addr !2472
  %18 = trunc i64 %17 to i8, !insn.addr !2473
  %19 = icmp eq i8 %18, 0, !insn.addr !2473
  %20 = icmp eq i1 %19, false, !insn.addr !2474
  br i1 %20, label %dec_label_pc_ac10, label %dec_label_pc_abe8, !insn.addr !2474

dec_label_pc_abe8:                                ; preds = %dec_label_pc_ab4e
  %21 = call i64 @__assert_fail(i64 ptrtoint ([59 x i8]* @global_var_55ec to i64), i64 ptrtoint ([41 x i8]* @global_var_55bc to i64), i64 217, i64 ptrtoint ([61 x i8]* @global_var_557c to i64)), !insn.addr !2475
  br label %dec_label_pc_ac10, !insn.addr !2475

dec_label_pc_ac10:                                ; preds = %dec_label_pc_abe8, %dec_label_pc_ab4e
  %22 = call i64 @_ZNK4llvm11Instruction17getStableDebugLocEv(i64* %arg2), !insn.addr !2476
  %23 = inttoptr i64 %22 to i64*, !insn.addr !2477
  %24 = call i64 @_ZN4llvm8DebugLocC1ERKS0_(i64* nonnull %stack_var_-40, i64* %23), !insn.addr !2477
  %25 = ptrtoint i64* %stack_var_-40 to i64, !insn.addr !2478
  %26 = call i64 @_ZN4llvm13IRBuilderBase23SetCurrentDebugLocationENS_8DebugLocE(i64* %result, i64 %25), !insn.addr !2479
  %27 = call i64 @_ZN4llvm8DebugLocD1Ev(i64* nonnull %stack_var_-40), !insn.addr !2480
  %28 = call i64 @__readfsqword(i64 40), !insn.addr !2481
  %29 = icmp eq i64 %2, %28, !insn.addr !2481
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !2482
  br i1 %29, label %dec_label_pc_ac62, label %dec_label_pc_ac5d, !insn.addr !2482

dec_label_pc_ac5d:                                ; preds = %dec_label_pc_ac10
  %30 = call i64 @__stack_chk_fail(), !insn.addr !2483
  store i64 %30, i64* %rax.0.reg2mem, !insn.addr !2483
  br label %dec_label_pc_ac62, !insn.addr !2483

dec_label_pc_ac62:                                ; preds = %dec_label_pc_ac5d, %dec_label_pc_ac10
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2484

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 0, 3, 1, 2, 4, 5 }
  uselistorder i64 %1, { 1, 2, 0, 3 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvmneERKNS_21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEES8_, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm10BasicBlock3endEv, { 1, 0 }
  uselistorder i64 56, { 1, 2, 0, 3 }
}

define i64 @_ZN4llvm13IRBuilderBase23SetCurrentDebugLocationENS_8DebugLocE(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_ac64:
  %0 = ptrtoint i64* %result to i64
  %1 = inttoptr i64 %arg2 to i64**, !insn.addr !2485
  %2 = call i64* @_ZSt4moveIRN4llvm8DebugLocEEONSt16remove_referenceIT_E4typeEOS4_(i64** %1), !insn.addr !2485
  %3 = add i64 %0, 48, !insn.addr !2486
  %4 = inttoptr i64 %3 to i64*, !insn.addr !2487
  %5 = call i64 @_ZN4llvm8DebugLocaSEOS0_(i64* %4, i64* %2), !insn.addr !2487
  ret i64 %5, !insn.addr !2488
}

define i64 @_ZNK4llvm13IRBuilderBase17AddMetadataToInstEPNS_11InstructionE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_ac9e:
  %stack_var_-40.0.in2.reg2mem = alloca i64, !insn.addr !2489
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv(i64* %result), !insn.addr !2490
  %1 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE3endEv(i64* %result), !insn.addr !2491
  %2 = icmp eq i64 %1, %0, !insn.addr !2492
  %3 = icmp eq i1 %2, false, !insn.addr !2493
  store i64 %0, i64* %stack_var_-40.0.in2.reg2mem, !insn.addr !2493
  br i1 %3, label %dec_label_pc_acdc, label %dec_label_pc_ad0f, !insn.addr !2493

dec_label_pc_acdc:                                ; preds = %dec_label_pc_ac9e, %dec_label_pc_acdc
  %stack_var_-40.0.in2.reload = load i64, i64* %stack_var_-40.0.in2.reg2mem
  %stack_var_-40.0 = inttoptr i64 %stack_var_-40.0.in2.reload to i32*
  %4 = add i64 %stack_var_-40.0.in2.reload, 8, !insn.addr !2494
  %5 = inttoptr i64 %4 to i64*, !insn.addr !2494
  %6 = load i64, i64* %5, align 8, !insn.addr !2494
  %7 = load i32, i32* %stack_var_-40.0, align 4, !insn.addr !2495
  %8 = zext i32 %7 to i64, !insn.addr !2495
  %9 = inttoptr i64 %8 to i64*, !insn.addr !2496
  %10 = trunc i64 %6 to i32, !insn.addr !2496
  %11 = call i64 @_ZN4llvm11Instruction11setMetadataEjPNS_6MDNodeE(i64* %arg2, i64* %9, i32 %10, i64* %9), !insn.addr !2496
  %12 = add i64 %stack_var_-40.0.in2.reload, 16, !insn.addr !2497
  %13 = icmp eq i64 %1, %12, !insn.addr !2492
  %14 = icmp eq i1 %13, false, !insn.addr !2493
  store i64 %12, i64* %stack_var_-40.0.in2.reg2mem, !insn.addr !2493
  br i1 %14, label %dec_label_pc_acdc, label %dec_label_pc_ad0f, !insn.addr !2493

dec_label_pc_ad0f:                                ; preds = %dec_label_pc_acdc, %dec_label_pc_ac9e
  %15 = call i64 @_ZNK4llvm13IRBuilderBase20SetInstDebugLocationEPNS_11InstructionE(i64* %result, i64* %arg2), !insn.addr !2498
  ret i64 %15, !insn.addr !2499

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
  uselistorder i64* %stack_var_-40.0.in2.reg2mem, { 2, 0, 1 }
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder label %dec_label_pc_acdc, { 1, 0 }
}

define i64 @_ZN4llvm9FMFSourceC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_ad26:
  %0 = call i64 @_ZNSt8optionalIN4llvm13FastMathFlagsEEC1Ev(i64* %result), !insn.addr !2500
  ret i64 %0, !insn.addr !2501
}

define i64 @_ZNK4llvm13IRBuilderBase10setFPAttrsEPNS_11InstructionEPNS_6MDNodeENS_13FastMathFlagsE(i64* %result, i64* %arg2, i64* %arg3, i64 %arg4) local_unnamed_addr {
dec_label_pc_ad46:
  %stack_var_-32.0.reg2mem = alloca i64, !insn.addr !2502
  %0 = ptrtoint i64* %arg3 to i64
  %1 = icmp eq i64* %arg3, null, !insn.addr !2503
  %2 = icmp eq i1 %1, false, !insn.addr !2504
  store i64 %0, i64* %stack_var_-32.0.reg2mem, !insn.addr !2504
  br i1 %2, label %dec_label_pc_ad74, label %dec_label_pc_ad68, !insn.addr !2504

dec_label_pc_ad68:                                ; preds = %dec_label_pc_ad46
  %3 = ptrtoint i64* %result to i64
  %4 = add i64 %3, 104, !insn.addr !2505
  %5 = inttoptr i64 %4 to i64*, !insn.addr !2505
  %6 = load i64, i64* %5, align 8, !insn.addr !2505
  store i64 %6, i64* %stack_var_-32.0.reg2mem, !insn.addr !2506
  br label %dec_label_pc_ad74, !insn.addr !2506

dec_label_pc_ad74:                                ; preds = %dec_label_pc_ad68, %dec_label_pc_ad46
  %stack_var_-32.0.reload = load i64, i64* %stack_var_-32.0.reg2mem
  %7 = icmp eq i64 %stack_var_-32.0.reload, 0, !insn.addr !2507
  br i1 %7, label %dec_label_pc_ad90, label %dec_label_pc_ad7b, !insn.addr !2508

dec_label_pc_ad7b:                                ; preds = %dec_label_pc_ad74
  %8 = trunc i64 %stack_var_-32.0.reload to i32, !insn.addr !2509
  %9 = inttoptr i64 %arg4 to i64*, !insn.addr !2509
  %10 = call i64 @_ZN4llvm11Instruction11setMetadataEjPNS_6MDNodeE(i64* %arg2, i64* inttoptr (i64 3 to i64*), i32 %8, i64* %9), !insn.addr !2509
  br label %dec_label_pc_ad90, !insn.addr !2509

dec_label_pc_ad90:                                ; preds = %dec_label_pc_ad7b, %dec_label_pc_ad74
  %11 = ptrtoint i64* %arg2 to i64
  %12 = and i64 %arg4, 4294967295
  %13 = inttoptr i64 %12 to i64*, !insn.addr !2510
  %14 = call i64 @_ZN4llvm11Instruction16setFastMathFlagsENS_13FastMathFlagsE(i64* %arg2, i64* %13, i64 %12), !insn.addr !2510
  ret i64 %11, !insn.addr !2511

; uselistorder directives
  uselistorder i64 %12, { 1, 0 }
  uselistorder i64 104, { 1, 0 }
  uselistorder i64* %arg2, { 0, 2, 1 }
}

define i64 @_ZN4llvm13IRBuilderBase11CreateTruncEPNS_5ValueEPNS_4TypeERKNS_5TwineEbb(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4, i1 %arg5, i1 %arg6) local_unnamed_addr {
dec_label_pc_ada8:
  %0 = alloca i64
  %rax.1.reg2mem = alloca i64, !insn.addr !2512
  %rax.0.reg2mem = alloca i64, !insn.addr !2512
  %1 = ptrtoint i64* %arg3 to i64
  %2 = ptrtoint i64* %arg2 to i64
  %3 = load i64, i64* %0
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-72 = alloca i64, align 8
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !2513
  %5 = call i64 @_ZNK4llvm5Value7getTypeEv(i64* %arg2), !insn.addr !2514
  %6 = icmp eq i64 %5, %1, !insn.addr !2515
  %7 = icmp eq i1 %6, false, !insn.addr !2516
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !2517
  br i1 %7, label %dec_label_pc_ae01, label %dec_label_pc_aeda, !insn.addr !2517

dec_label_pc_ae01:                                ; preds = %dec_label_pc_ada8
  %8 = ptrtoint i64* %result to i64
  %9 = add i64 %8, 88, !insn.addr !2518
  %10 = inttoptr i64 %9 to i64*, !insn.addr !2518
  %11 = load i64, i64* %10, align 8, !insn.addr !2518
  %12 = icmp eq i64 %11, 0, !insn.addr !2519
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !2520
  br i1 %12, label %dec_label_pc_ae42, label %dec_label_pc_aeda, !insn.addr !2520

dec_label_pc_ae42:                                ; preds = %dec_label_pc_ae01
  %13 = call i64 @_ZN4llvm14InsertPositionC1EDn(i64* nonnull %stack_var_-72, i64 0), !insn.addr !2521
  %14 = call i64 @_ZN4llvm5TwineC1EPKc(i64* nonnull %stack_var_-56, i8* bitcast (i8** @global_var_5627 to i8*)), !insn.addr !2522
  %15 = load i64, i64* %stack_var_-72, align 8, !insn.addr !2523
  %16 = inttoptr i64 %15 to i64*, !insn.addr !2524
  %17 = call i64 @_ZN4llvm8CastInst6CreateENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineENS_14InsertPositionE(i64* inttoptr (i64 38 to i64*), i64 %2, i64* %arg3, i64* nonnull %stack_var_-56, i64* %16, i64 %3), !insn.addr !2524
  %18 = icmp eq i1 %arg5, false, !insn.addr !2525
  %.pre3 = inttoptr i64 %17 to i64*
  br i1 %18, label %dec_label_pc_aeab, label %dec_label_pc_ae9a, !insn.addr !2526

dec_label_pc_ae9a:                                ; preds = %dec_label_pc_ae42
  %19 = call i64 @_ZN4llvm11Instruction20setHasNoUnsignedWrapEb(i64* %.pre3, i1 true), !insn.addr !2527
  br label %dec_label_pc_aeab, !insn.addr !2527

dec_label_pc_aeab:                                ; preds = %dec_label_pc_ae42, %dec_label_pc_ae9a
  %20 = icmp eq i1 %arg6, false, !insn.addr !2528
  br i1 %20, label %dec_label_pc_aec2, label %dec_label_pc_aeb1, !insn.addr !2529

dec_label_pc_aeb1:                                ; preds = %dec_label_pc_aeab
  %21 = call i64 @_ZN4llvm11Instruction18setHasNoSignedWrapEb(i64* %.pre3, i1 true), !insn.addr !2530
  br label %dec_label_pc_aec2, !insn.addr !2530

dec_label_pc_aec2:                                ; preds = %dec_label_pc_aeab, %dec_label_pc_aeb1
  %22 = call i64* @_ZNK4llvm13IRBuilderBase6InsertINS_11InstructionEEEPT_S4_RKNS_5TwineE(i64* %result, i64* %.pre3, i64* %arg4), !insn.addr !2531
  %23 = ptrtoint i64* %22 to i64, !insn.addr !2531
  store i64 %23, i64* %rax.0.reg2mem, !insn.addr !2532
  br label %dec_label_pc_aeda, !insn.addr !2532

dec_label_pc_aeda:                                ; preds = %dec_label_pc_ae01, %dec_label_pc_ada8, %dec_label_pc_aec2
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %24 = call i64 @__readfsqword(i64 40), !insn.addr !2533
  %25 = icmp eq i64 %4, %24, !insn.addr !2533
  store i64 %rax.0.reload, i64* %rax.1.reg2mem, !insn.addr !2534
  br i1 %25, label %dec_label_pc_aeee, label %dec_label_pc_aee9, !insn.addr !2534

dec_label_pc_aee9:                                ; preds = %dec_label_pc_aeda
  %26 = call i64 @__stack_chk_fail(), !insn.addr !2535
  store i64 %26, i64* %rax.1.reg2mem, !insn.addr !2535
  br label %dec_label_pc_aeee, !insn.addr !2535

dec_label_pc_aeee:                                ; preds = %dec_label_pc_aee9, %dec_label_pc_aeda
  %rax.1.reload = load i64, i64* %rax.1.reg2mem
  ret i64 %rax.1.reload, !insn.addr !2536

; uselistorder directives
  uselistorder i64* %stack_var_-72, { 1, 0 }
  uselistorder i64 %2, { 1, 0 }
  uselistorder i64* %rax.0.reg2mem, { 0, 3, 1, 2 }
  uselistorder label %dec_label_pc_aeda, { 2, 0, 1 }
  uselistorder label %dec_label_pc_aec2, { 1, 0 }
  uselistorder label %dec_label_pc_aeab, { 1, 0 }
}

define i64 @_ZN4llvm13IRBuilderBase10CreateZExtEPNS_5ValueEPNS_4TypeERKNS_5TwineEb(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4, i1 %arg5) local_unnamed_addr {
dec_label_pc_aef0:
  %0 = alloca i64
  %rax.1.reg2mem = alloca i64, !insn.addr !2537
  %rax.0.reg2mem = alloca i64, !insn.addr !2537
  %1 = ptrtoint i64* %arg3 to i64
  %2 = load i64, i64* %0
  %stack_var_-72 = alloca i64, align 8
  %stack_var_-88 = alloca i64, align 8
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !2538
  %4 = call i64 @_ZNK4llvm5Value7getTypeEv(i64* %arg2), !insn.addr !2539
  %5 = icmp eq i64 %4, %1, !insn.addr !2540
  %6 = icmp eq i1 %5, false, !insn.addr !2541
  br i1 %6, label %dec_label_pc_af48, label %dec_label_pc_af3f, !insn.addr !2542

dec_label_pc_af3f:                                ; preds = %dec_label_pc_aef0
  %7 = ptrtoint i64* %arg2 to i64
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !2543
  br label %dec_label_pc_b017, !insn.addr !2543

dec_label_pc_af48:                                ; preds = %dec_label_pc_aef0
  %8 = ptrtoint i64* %result to i64
  %9 = add i64 %8, 88, !insn.addr !2544
  %10 = inttoptr i64 %9 to i64*, !insn.addr !2544
  %11 = load i64, i64* %10, align 8, !insn.addr !2544
  %12 = icmp eq i64 %11, 0, !insn.addr !2545
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !2546
  br i1 %12, label %dec_label_pc_af89, label %dec_label_pc_b017, !insn.addr !2546

dec_label_pc_af89:                                ; preds = %dec_label_pc_af48
  %13 = call i64 @_ZN4llvm16UnaryInstructionnwEm(i64 72), !insn.addr !2547
  %14 = call i64 @_ZN4llvm14InsertPositionC1EDn(i64* nonnull %stack_var_-88, i64 0), !insn.addr !2548
  %15 = call i64 @_ZN4llvm5TwineC1EPKc(i64* nonnull %stack_var_-72, i8* bitcast (i8** @global_var_5627 to i8*)), !insn.addr !2549
  %16 = load i64, i64* %stack_var_-88, align 8, !insn.addr !2550
  %17 = inttoptr i64 %13 to i64*, !insn.addr !2551
  %18 = inttoptr i64 %16 to i64*, !insn.addr !2551
  %19 = call i64 @_ZN4llvm8ZExtInstC1EPNS_5ValueEPNS_4TypeERKNS_5TwineENS_14InsertPositionE(i64* %17, i64* %arg2, i64* %arg3, i64* nonnull %stack_var_-72, i64* %18, i64 %2), !insn.addr !2551
  %20 = call i64* @_ZNK4llvm13IRBuilderBase6InsertINS_8ZExtInstEEEPT_S4_RKNS_5TwineE(i64* %result, i64* %17, i64* %arg4), !insn.addr !2552
  %21 = ptrtoint i64* %20 to i64, !insn.addr !2552
  %22 = icmp eq i1 %arg5, false, !insn.addr !2553
  store i64 %21, i64* %rax.0.reg2mem, !insn.addr !2554
  br i1 %22, label %dec_label_pc_b017, label %dec_label_pc_b002, !insn.addr !2554

dec_label_pc_b002:                                ; preds = %dec_label_pc_af89
  %23 = call i64 @_ZN4llvm11Instruction9setNonNegEb(i64* %20, i1 true), !insn.addr !2555
  store i64 %21, i64* %rax.0.reg2mem, !insn.addr !2555
  br label %dec_label_pc_b017, !insn.addr !2555

dec_label_pc_b017:                                ; preds = %dec_label_pc_af89, %dec_label_pc_b002, %dec_label_pc_af48, %dec_label_pc_af3f
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %24 = call i64 @__readfsqword(i64 40), !insn.addr !2556
  %25 = icmp eq i64 %3, %24, !insn.addr !2556
  store i64 %rax.0.reload, i64* %rax.1.reg2mem, !insn.addr !2557
  br i1 %25, label %dec_label_pc_b02b, label %dec_label_pc_b026, !insn.addr !2557

dec_label_pc_b026:                                ; preds = %dec_label_pc_b017
  %26 = call i64 @__stack_chk_fail(), !insn.addr !2558
  store i64 %26, i64* %rax.1.reg2mem, !insn.addr !2558
  br label %dec_label_pc_b02b, !insn.addr !2558

dec_label_pc_b02b:                                ; preds = %dec_label_pc_b026, %dec_label_pc_b017
  %rax.1.reload = load i64, i64* %rax.1.reg2mem
  ret i64 %rax.1.reload, !insn.addr !2559

; uselistorder directives
  uselistorder i64 %21, { 1, 0 }
  uselistorder i64* %stack_var_-88, { 1, 0 }
  uselistorder i64* %rax.0.reg2mem, { 0, 2, 1, 3, 4 }
  uselistorder i64 72, { 1, 3, 4, 5, 6, 7, 8, 2, 11, 13, 9, 14, 0, 12, 10 }
  uselistorder i64* %arg2, { 0, 2, 1 }
  uselistorder label %dec_label_pc_b017, { 1, 0, 2, 3 }
}

define i64 @_ZN4llvm13IRBuilderBase14CreatePtrToIntEPNS_5ValueEPNS_4TypeERKNS_5TwineE(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_b032:
  %rax.0.reg2mem = alloca i64, !insn.addr !2560
  %0 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !2561
  store i64 0, i64* %stack_var_-24, align 8, !insn.addr !2562
  %2 = call i64 @_ZN4llvm9FMFSourceC1Ev(i64* nonnull %stack_var_-24), !insn.addr !2563
  %3 = call i64 @_ZN4llvm13IRBuilderBase10CreateCastENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineEPNS_6MDNodeENS_9FMFSourceE(i64 %0, i64* inttoptr (i64 47 to i64*), i64* %arg2, i64* %arg3, i64* %arg4, i64 0), !insn.addr !2564
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !2565
  %5 = icmp eq i64 %1, %4, !insn.addr !2565
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !2566
  br i1 %5, label %dec_label_pc_b0b6, label %dec_label_pc_b0b1, !insn.addr !2566

dec_label_pc_b0b1:                                ; preds = %dec_label_pc_b032
  %6 = call i64 @__stack_chk_fail(), !insn.addr !2567
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !2567
  br label %dec_label_pc_b0b6, !insn.addr !2567

dec_label_pc_b0b6:                                ; preds = %dec_label_pc_b0b1, %dec_label_pc_b032
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2568
}

define i64 @_ZN4llvm13IRBuilderBase14CreateIntToPtrEPNS_5ValueEPNS_4TypeERKNS_5TwineE(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_b0b8:
  %rax.0.reg2mem = alloca i64, !insn.addr !2569
  %0 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !2570
  store i64 0, i64* %stack_var_-24, align 8, !insn.addr !2571
  %2 = call i64 @_ZN4llvm9FMFSourceC1Ev(i64* nonnull %stack_var_-24), !insn.addr !2572
  %3 = call i64 @_ZN4llvm13IRBuilderBase10CreateCastENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineEPNS_6MDNodeENS_9FMFSourceE(i64 %0, i64* inttoptr (i64 48 to i64*), i64* %arg2, i64* %arg3, i64* %arg4, i64 0), !insn.addr !2573
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !2574
  %5 = icmp eq i64 %1, %4, !insn.addr !2574
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !2575
  br i1 %5, label %dec_label_pc_b13c, label %dec_label_pc_b137, !insn.addr !2575

dec_label_pc_b137:                                ; preds = %dec_label_pc_b0b8
  %6 = call i64 @__stack_chk_fail(), !insn.addr !2576
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !2576
  br label %dec_label_pc_b13c, !insn.addr !2576

dec_label_pc_b13c:                                ; preds = %dec_label_pc_b137, %dec_label_pc_b0b8
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2577

; uselistorder directives
  uselistorder i64 (i64, i64*, i64*, i64*, i64*, i64)* @_ZN4llvm13IRBuilderBase10CreateCastENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineEPNS_6MDNodeENS_9FMFSourceE, { 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm9FMFSourceC1Ev, { 1, 0 }
}

define i64 @_ZN4llvm13IRBuilderBase10CreateCastENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineEPNS_6MDNodeENS_9FMFSourceE(i64 %arg1, i64* %arg2, i64* %arg3, i64* %arg4, i64* %arg5, i64 %arg6) local_unnamed_addr {
dec_label_pc_b13e:
  %0 = alloca i64
  %rax.1.reg2mem = alloca i64, !insn.addr !2578
  %rax.0.reg2mem = alloca i64, !insn.addr !2578
  %.pre-phi.reg2mem = alloca i64*, !insn.addr !2578
  %1 = ptrtoint i64* %arg4 to i64
  %2 = ptrtoint i64* %arg3 to i64
  %stack_var_8 = alloca i64, align 8
  %stack_var_-88 = alloca i64, align 8
  %3 = load i64, i64* %0
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-72 = alloca i64, align 8
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !2579
  %5 = call i64 @_ZNK4llvm5Value7getTypeEv(i64* %arg3), !insn.addr !2580
  %6 = icmp eq i64 %5, %1, !insn.addr !2581
  %7 = icmp eq i1 %6, false, !insn.addr !2582
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !2583
  br i1 %7, label %dec_label_pc_b190, label %dec_label_pc_b26f, !insn.addr !2583

dec_label_pc_b190:                                ; preds = %dec_label_pc_b13e
  %8 = add i64 %arg1, 88, !insn.addr !2584
  %9 = inttoptr i64 %8 to i64*, !insn.addr !2584
  %10 = load i64, i64* %9, align 8, !insn.addr !2584
  %11 = icmp eq i64 %10, 0, !insn.addr !2585
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !2586
  br i1 %11, label %dec_label_pc_b1cf, label %dec_label_pc_b26f, !insn.addr !2586

dec_label_pc_b1cf:                                ; preds = %dec_label_pc_b190
  %12 = call i64 @_ZN4llvm14InsertPositionC1EDn(i64* nonnull %stack_var_-72, i64 0), !insn.addr !2587
  %13 = call i64 @_ZN4llvm5TwineC1EPKc(i64* nonnull %stack_var_-56, i8* bitcast (i8** @global_var_5627 to i8*)), !insn.addr !2588
  %14 = load i64, i64* %stack_var_-72, align 8, !insn.addr !2589
  %15 = inttoptr i64 %14 to i64*, !insn.addr !2590
  %16 = call i64 @_ZN4llvm8CastInst6CreateENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineENS_14InsertPositionE(i64* %arg2, i64 %2, i64* %arg4, i64* nonnull %stack_var_-56, i64* %15, i64 %3), !insn.addr !2590
  store i64 %16, i64* %stack_var_-88, align 8, !insn.addr !2591
  %17 = bitcast i64* %stack_var_-88 to i64**, !insn.addr !2592
  %18 = call i1 @_ZN4llvm3isaINS_14FPMathOperatorEPNS_11InstructionEEEbRKT0_(i64** nonnull %17), !insn.addr !2592
  %19 = icmp eq i1 %18, false, !insn.addr !2593
  br i1 %19, label %dec_label_pc_b1cf.dec_label_pc_b257_crit_edge, label %dec_label_pc_b22f, !insn.addr !2594

dec_label_pc_b1cf.dec_label_pc_b257_crit_edge:    ; preds = %dec_label_pc_b1cf
  %.pre = inttoptr i64 %arg1 to i64*, !insn.addr !2595
  store i64* %.pre, i64** %.pre-phi.reg2mem
  br label %dec_label_pc_b257

dec_label_pc_b22f:                                ; preds = %dec_label_pc_b1cf
  %20 = add i64 %arg1, 112, !insn.addr !2596
  %21 = inttoptr i64 %20 to i32*, !insn.addr !2596
  %22 = load i32, i32* %21, align 4, !insn.addr !2596
  %23 = zext i32 %22 to i64, !insn.addr !2597
  %24 = call i64 @_ZNK4llvm9FMFSource3getENS_13FastMathFlagsE(i64* nonnull %stack_var_8, i64 %23), !insn.addr !2598
  %25 = and i64 %24, 4294967295, !insn.addr !2599
  %26 = load i64, i64* %stack_var_-88, align 8, !insn.addr !2600
  %27 = inttoptr i64 %arg1 to i64*
  %28 = inttoptr i64 %26 to i64*, !insn.addr !2601
  %29 = inttoptr i64 %arg6 to i64*, !insn.addr !2601
  %30 = call i64 @_ZNK4llvm13IRBuilderBase10setFPAttrsEPNS_11InstructionEPNS_6MDNodeENS_13FastMathFlagsE(i64* %27, i64* %28, i64* %29, i64 %25), !insn.addr !2601
  store i64* %27, i64** %.pre-phi.reg2mem, !insn.addr !2601
  br label %dec_label_pc_b257, !insn.addr !2601

dec_label_pc_b257:                                ; preds = %dec_label_pc_b1cf.dec_label_pc_b257_crit_edge, %dec_label_pc_b22f
  %.pre-phi.reload = load i64*, i64** %.pre-phi.reg2mem
  %31 = load i64, i64* %stack_var_-88, align 8, !insn.addr !2602
  %32 = inttoptr i64 %31 to i64*, !insn.addr !2595
  %33 = call i64* @_ZNK4llvm13IRBuilderBase6InsertINS_11InstructionEEEPT_S4_RKNS_5TwineE(i64* %.pre-phi.reload, i64* %32, i64* %arg5), !insn.addr !2595
  %34 = ptrtoint i64* %33 to i64, !insn.addr !2595
  store i64 %34, i64* %rax.0.reg2mem, !insn.addr !2603
  br label %dec_label_pc_b26f, !insn.addr !2603

dec_label_pc_b26f:                                ; preds = %dec_label_pc_b190, %dec_label_pc_b13e, %dec_label_pc_b257
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %35 = call i64 @__readfsqword(i64 40), !insn.addr !2604
  %36 = icmp eq i64 %4, %35, !insn.addr !2604
  store i64 %rax.0.reload, i64* %rax.1.reg2mem, !insn.addr !2605
  br i1 %36, label %dec_label_pc_b283, label %dec_label_pc_b27e, !insn.addr !2605

dec_label_pc_b27e:                                ; preds = %dec_label_pc_b26f
  %37 = call i64 @__stack_chk_fail(), !insn.addr !2606
  store i64 %37, i64* %rax.1.reg2mem, !insn.addr !2606
  br label %dec_label_pc_b283, !insn.addr !2606

dec_label_pc_b283:                                ; preds = %dec_label_pc_b27e, %dec_label_pc_b26f
  %rax.1.reload = load i64, i64* %rax.1.reg2mem
  ret i64 %rax.1.reload, !insn.addr !2607

; uselistorder directives
  uselistorder i64* %stack_var_-72, { 1, 0 }
  uselistorder i64* %stack_var_-88, { 1, 2, 0, 3 }
  uselistorder i64 %2, { 1, 0 }
  uselistorder i64* %rax.0.reg2mem, { 0, 3, 1, 2 }
  uselistorder i64* (i64*, i64*, i64*)* @_ZNK4llvm13IRBuilderBase6InsertINS_11InstructionEEEPT_S4_RKNS_5TwineE, { 1, 0 }
  uselistorder i64 112, { 1, 0 }
  uselistorder i64 (i64*, i64, i64*, i64*, i64*, i64)* @_ZN4llvm8CastInst6CreateENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineENS_14InsertPositionE, { 1, 0 }
  uselistorder i64 (i64*, i8*)* @_ZN4llvm5TwineC1EPKc, { 2, 1, 0 }
  uselistorder i64 (i64*, i64)* @_ZN4llvm14InsertPositionC1EDn, { 2, 1, 0 }
  uselistorder i64 88, { 16, 17, 18, 9, 10, 2, 11, 3, 12, 4, 5, 0, 13, 6, 1, 7, 14, 15, 8 }
  uselistorder i64 (i64*)* @_ZNK4llvm5Value7getTypeEv, { 3, 2, 1, 4, 6, 5, 0 }
  uselistorder i64 %arg1, { 1, 2, 0, 3 }
  uselistorder label %dec_label_pc_b26f, { 2, 0, 1 }
  uselistorder label %dec_label_pc_b257, { 1, 0 }
}

define i64 @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj(i64* %result, i64** %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_b2d4:
  %rax.0.reg2mem = alloca i64, !insn.addr !2608
  %0 = ptrtoint i64** %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !2609
  %2 = add i64 %1, 8, !insn.addr !2610
  %3 = inttoptr i64 %2 to i32*, !insn.addr !2610
  store i32 %arg3, i32* %3, align 4, !insn.addr !2610
  %4 = add i64 %1, 12, !insn.addr !2611
  %5 = inttoptr i64 %4 to i32*, !insn.addr !2611
  store i32 0, i32* %5, align 4, !insn.addr !2611
  %6 = add i64 %1, 16, !insn.addr !2612
  %7 = inttoptr i64 %6 to i32*, !insn.addr !2612
  store i32 0, i32* %7, align 4, !insn.addr !2612
  %8 = add i64 %1, 20, !insn.addr !2613
  %9 = inttoptr i64 %8 to i8*, !insn.addr !2613
  store i8 1, i8* %9, align 1, !insn.addr !2613
  %10 = call i1 @_ZN4llvm14has_single_bitIjvEEbT_(i32 %arg3), !insn.addr !2614
  %11 = sext i1 %10 to i64, !insn.addr !2614
  %12 = icmp eq i1 %10, false, !insn.addr !2615
  %13 = icmp eq i1 %12, false, !insn.addr !2616
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !2616
  br i1 %13, label %dec_label_pc_b354, label %dec_label_pc_b32c, !insn.addr !2616

dec_label_pc_b32c:                                ; preds = %dec_label_pc_b2d4
  %14 = call i64 @__assert_fail(i64 ptrtoint ([74 x i8]* @global_var_56cc to i64), i64 ptrtoint ([44 x i8]* @global_var_569c to i64), i64 83, i64 ptrtoint ([75 x i8]* @global_var_564c to i64)), !insn.addr !2617
  store i64 %14, i64* %rax.0.reg2mem, !insn.addr !2617
  br label %dec_label_pc_b354, !insn.addr !2617

dec_label_pc_b354:                                ; preds = %dec_label_pc_b32c, %dec_label_pc_b2d4
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2618
}

define i64 @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv() local_unnamed_addr {
dec_label_pc_b357:
  ret i64 -2, !insn.addr !2619
}

define i64 @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv() local_unnamed_addr {
dec_label_pc_b368:
  ret i64 -1, !insn.addr !2620
}

define i64 @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv(i64* %result) local_unnamed_addr {
dec_label_pc_b37a:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm19SmallPtrSetImplBase7isSmallEv(i64* %result), !insn.addr !2621
  %2 = trunc i64 %1 to i8, !insn.addr !2622
  %3 = icmp eq i8 %2, 0, !insn.addr !2622
  %.pn.in.in.in.in.v = select i1 %3, i64 8, i64 12
  %.pn.in.in.in.in = add i64 %.pn.in.in.in.in.v, %0
  %.pn.in.in.in = inttoptr i64 %.pn.in.in.in.in to i32*
  %.pn.in.in = load i32, i32* %.pn.in.in.in, align 4
  %.pn.in = zext i32 %.pn.in.in to i64
  %.pn = mul i64 %.pn.in, 8
  %storemerge = add i64 %.pn, %0
  ret i64 %storemerge, !insn.addr !2623
}

define i64 @_ZN4llvm19SmallPtrSetImplBase10insert_impEPKv(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_b3cc:
  %rax.1.reg2mem = alloca i64, !insn.addr !2624
  %rax.0.reg2mem = alloca i64, !insn.addr !2624
  %.reg2mem1 = alloca i32, !insn.addr !2624
  %.reg2mem = alloca i64, !insn.addr !2624
  %stack_var_-40 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-81 = alloca i8, align 1
  %stack_var_-80 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2625
  %1 = call i64 @_ZNK4llvm19SmallPtrSetImplBase7isSmallEv(i64* %result), !insn.addr !2626
  %2 = trunc i64 %1 to i8, !insn.addr !2627
  %3 = icmp eq i8 %2, 0, !insn.addr !2627
  br i1 %3, label %dec_label_pc_b539, label %dec_label_pc_b403, !insn.addr !2628

dec_label_pc_b403:                                ; preds = %dec_label_pc_b3cc
  %4 = ptrtoint i64* %arg2 to i64
  %5 = ptrtoint i64* %result to i64
  store i64 %5, i64* %stack_var_-80, align 8, !insn.addr !2629
  %6 = add i64 %5, 12, !insn.addr !2630
  %7 = inttoptr i64 %6 to i32*, !insn.addr !2630
  %8 = load i32, i32* %7, align 4, !insn.addr !2630
  %9 = zext i32 %8 to i64, !insn.addr !2631
  %10 = mul i64 %9, 8, !insn.addr !2632
  %11 = add i64 %10, %5, !insn.addr !2633
  %12 = icmp eq i32 %8, 0, !insn.addr !2634
  %13 = icmp eq i1 %12, false, !insn.addr !2635
  store i64 %5, i64* %.reg2mem, !insn.addr !2635
  store i32 %8, i32* %.reg2mem1, !insn.addr !2635
  br i1 %13, label %dec_label_pc_b42b, label %dec_label_pc_b495, !insn.addr !2635

dec_label_pc_b42b:                                ; preds = %dec_label_pc_b403, %dec_label_pc_b47f
  %.reload = load i64, i64* %.reg2mem
  %14 = inttoptr i64 %.reload to i64*, !insn.addr !2636
  %15 = load i64, i64* %14, align 8, !insn.addr !2636
  %16 = icmp eq i64 %15, %4, !insn.addr !2637
  %17 = icmp eq i1 %16, false, !insn.addr !2638
  br i1 %17, label %dec_label_pc_b47f, label %dec_label_pc_b440, !insn.addr !2638

dec_label_pc_b440:                                ; preds = %dec_label_pc_b42b
  store i8 0, i8* %stack_var_-81, align 1, !insn.addr !2639
  %18 = bitcast i64* %stack_var_-80 to i64****, !insn.addr !2640
  %19 = bitcast i8* %stack_var_-81 to i1*, !insn.addr !2640
  %20 = call i64 @_ZSt9make_pairIRPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS5_INS6_IT0_E4typeEE6__typeEEOS7_OSC_(i64**** nonnull %18, i1* nonnull %19), !insn.addr !2640
  store i64 %20, i64* %stack_var_-56, align 8, !insn.addr !2641
  %21 = call i64 @_ZNSt4pairIPKPKvbEC1IPS1_bLb1EEEOS_IT_T0_E(i64* nonnull %stack_var_-40, i64* nonnull %stack_var_-56), !insn.addr !2642
  %22 = load i64, i64* %stack_var_-40, align 8, !insn.addr !2643
  store i64 %22, i64* %rax.0.reg2mem, !insn.addr !2644
  br label %dec_label_pc_b54d, !insn.addr !2644

dec_label_pc_b47f:                                ; preds = %dec_label_pc_b42b
  %23 = add i64 %.reload, 8, !insn.addr !2645
  store i64 %23, i64* %stack_var_-80, align 8, !insn.addr !2646
  %24 = icmp eq i64 %11, %23, !insn.addr !2634
  %25 = icmp eq i1 %24, false, !insn.addr !2635
  store i64 %23, i64* %.reg2mem, !insn.addr !2635
  br i1 %25, label %dec_label_pc_b42b, label %dec_label_pc_b48b.dec_label_pc_b495_crit_edge, !insn.addr !2635

dec_label_pc_b48b.dec_label_pc_b495_crit_edge:    ; preds = %dec_label_pc_b47f
  %.pre = load i32, i32* %7, align 4
  store i32 %.pre, i32* %.reg2mem1
  br label %dec_label_pc_b495

dec_label_pc_b495:                                ; preds = %dec_label_pc_b48b.dec_label_pc_b495_crit_edge, %dec_label_pc_b403
  %.reload2 = load i32, i32* %.reg2mem1, !insn.addr !2647
  %26 = add i64 %5, 8, !insn.addr !2648
  %27 = inttoptr i64 %26 to i32*, !insn.addr !2648
  %28 = load i32, i32* %27, align 4, !insn.addr !2648
  %29 = icmp ult i32 %.reload2, %28, !insn.addr !2649
  %30 = icmp eq i1 %29, false, !insn.addr !2650
  br i1 %30, label %dec_label_pc_b539, label %dec_label_pc_b4ab, !insn.addr !2650

dec_label_pc_b4ab:                                ; preds = %dec_label_pc_b495
  %31 = add i32 %.reload2, 1, !insn.addr !2651
  store i32 %31, i32* %7, align 4, !insn.addr !2652
  %32 = zext i32 %.reload2 to i64, !insn.addr !2653
  %33 = mul i64 %32, 8, !insn.addr !2654
  %34 = add i64 %33, %5, !insn.addr !2655
  %35 = inttoptr i64 %34 to i64*, !insn.addr !2656
  store i64 %4, i64* %35, align 8, !insn.addr !2656
  %36 = call i64 @_ZN4llvm14DebugEpochBase14incrementEpochEv(i64* %result), !insn.addr !2657
  store i8 1, i8* %stack_var_-81, align 1, !insn.addr !2658
  %37 = load i32, i32* %7, align 4, !insn.addr !2659
  %38 = add i32 %37, -1, !insn.addr !2660
  %39 = zext i32 %38 to i64, !insn.addr !2661
  %40 = mul i64 %39, 8, !insn.addr !2662
  %41 = add i64 %40, %5, !insn.addr !2663
  store i64 %41, i64* %stack_var_-80, align 8, !insn.addr !2664
  %42 = bitcast i64* %stack_var_-80 to i64***, !insn.addr !2665
  %43 = bitcast i8* %stack_var_-81 to i1*, !insn.addr !2665
  %44 = call i64 @_ZSt9make_pairIPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS4_INS5_IT0_E4typeEE6__typeEEOS6_OSB_(i64*** nonnull %42, i1* nonnull %43), !insn.addr !2665
  store i64 %44, i64* %stack_var_-56, align 8, !insn.addr !2666
  %45 = call i64 @_ZNSt4pairIPKPKvbEC1IPS1_bLb1EEEOS_IT_T0_E(i64* nonnull %stack_var_-40, i64* nonnull %stack_var_-56), !insn.addr !2667
  %46 = load i64, i64* %stack_var_-40, align 8, !insn.addr !2668
  store i64 %46, i64* %rax.0.reg2mem, !insn.addr !2669
  br label %dec_label_pc_b54d, !insn.addr !2669

dec_label_pc_b539:                                ; preds = %dec_label_pc_b495, %dec_label_pc_b3cc
  %47 = call i64 @_ZN4llvm19SmallPtrSetImplBase14insert_imp_bigEPKv(i64* %result, i64* %arg2), !insn.addr !2670
  store i64 %47, i64* %rax.0.reg2mem, !insn.addr !2671
  br label %dec_label_pc_b54d, !insn.addr !2671

dec_label_pc_b54d:                                ; preds = %dec_label_pc_b539, %dec_label_pc_b440, %dec_label_pc_b4ab
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %48 = call i64 @__readfsqword(i64 40), !insn.addr !2672
  %49 = icmp eq i64 %0, %48, !insn.addr !2672
  store i64 %rax.0.reload, i64* %rax.1.reg2mem, !insn.addr !2673
  br i1 %49, label %dec_label_pc_b561, label %dec_label_pc_b55c, !insn.addr !2673

dec_label_pc_b55c:                                ; preds = %dec_label_pc_b54d
  %50 = call i64 @__stack_chk_fail(), !insn.addr !2674
  store i64 %50, i64* %rax.1.reg2mem, !insn.addr !2674
  br label %dec_label_pc_b561, !insn.addr !2674

dec_label_pc_b561:                                ; preds = %dec_label_pc_b55c, %dec_label_pc_b54d
  %rax.1.reload = load i64, i64* %rax.1.reg2mem
  ret i64 %rax.1.reload, !insn.addr !2675

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
  uselistorder i64 (i64*)* @_ZN4llvm14DebugEpochBase14incrementEpochEv, { 2, 1, 0 }
  uselistorder i64 12, { 1, 0, 2, 6, 7, 3, 4, 5 }
  uselistorder i64* %result, { 0, 1, 3, 2 }
  uselistorder label %dec_label_pc_b54d, { 0, 2, 1 }
  uselistorder label %dec_label_pc_b42b, { 1, 0 }
}

define i64 @_ZNK4llvm19SmallPtrSetImplBase7isSmallEv(i64* %result) local_unnamed_addr {
dec_label_pc_b564:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 20, !insn.addr !2676
  %2 = inttoptr i64 %1 to i8*, !insn.addr !2676
  %3 = load i8, i8* %2, align 1, !insn.addr !2676
  %4 = zext i8 %3 to i64, !insn.addr !2676
  ret i64 %4, !insn.addr !2677
}

define i64 @_ZN4llvm23SmallPtrSetIteratorImplC1EPKPKvS4_(i64* %result, i64** %arg2, i64** %arg3) local_unnamed_addr {
dec_label_pc_b57a:
  %storemerge.reg2mem = alloca i64, !insn.addr !2678
  %0 = ptrtoint i64** %arg3 to i64
  %1 = ptrtoint i64** %arg2 to i64
  %2 = ptrtoint i64* %result to i64
  store i64 %1, i64* %result, align 8, !insn.addr !2679
  %3 = add i64 %2, 8, !insn.addr !2680
  %4 = inttoptr i64 %3 to i64*, !insn.addr !2680
  store i64 %0, i64* %4, align 8, !insn.addr !2680
  %5 = call i1 @_ZN4llvm20shouldReverseIterateIPvEEbv(), !insn.addr !2681
  %6 = icmp eq i1 %5, false, !insn.addr !2682
  br i1 %6, label %dec_label_pc_b5c0, label %dec_label_pc_b5b2, !insn.addr !2683

dec_label_pc_b5b2:                                ; preds = %dec_label_pc_b57a
  %7 = call i64 @_ZN4llvm23SmallPtrSetIteratorImpl17RetreatIfNotValidEv(i64* nonnull %result), !insn.addr !2684
  store i64 %7, i64* %storemerge.reg2mem, !insn.addr !2685
  br label %dec_label_pc_b5cc, !insn.addr !2685

dec_label_pc_b5c0:                                ; preds = %dec_label_pc_b57a
  %8 = call i64 @_ZN4llvm23SmallPtrSetIteratorImpl17AdvanceIfNotValidEv(i64* nonnull %result), !insn.addr !2686
  store i64 %8, i64* %storemerge.reg2mem, !insn.addr !2686
  br label %dec_label_pc_b5cc, !insn.addr !2686

dec_label_pc_b5cc:                                ; preds = %dec_label_pc_b5c0, %dec_label_pc_b5b2
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2687

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* %result, { 1, 0, 2, 3 }
}

define i64 @_ZN4llvm23SmallPtrSetIteratorImpl17AdvanceIfNotValidEv(i64* %result) local_unnamed_addr {
dec_label_pc_b5ce:
  %rdi.1.reg2mem = alloca i64, !insn.addr !2688
  %.reg2mem = alloca i64, !insn.addr !2688
  %rdi.0.reg2mem = alloca i64, !insn.addr !2688
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !2689
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2689
  %3 = load i64, i64* %2, align 8, !insn.addr !2689
  %4 = icmp ult i64 %3, %0, !insn.addr !2690
  %5 = icmp eq i1 %4, false, !insn.addr !2691
  store i64 %3, i64* %.reg2mem, !insn.addr !2691
  store i64 %0, i64* %rdi.1.reg2mem, !insn.addr !2691
  br i1 %5, label %dec_label_pc_b62d, label %dec_label_pc_b5f3, !insn.addr !2691

dec_label_pc_b5f3:                                ; preds = %dec_label_pc_b5ce
  %6 = call i64 @__assert_fail(i64 ptrtoint ([14 x i8]* @global_var_5754 to i64), i64 ptrtoint ([44 x i8]* @global_var_569c to i64), i64 298, i64 ptrtoint ([56 x i8]* @global_var_571c to i64)), !insn.addr !2692
  store i64 ptrtoint ([14 x i8]* @global_var_5754 to i64), i64* %rdi.0.reg2mem, !insn.addr !2692
  br label %dec_label_pc_b61b, !insn.addr !2692

dec_label_pc_b61b:                                ; preds = %dec_label_pc_b641, %dec_label_pc_b655, %dec_label_pc_b5f3
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %7 = add i64 %rdi.0.reload, 8, !insn.addr !2693
  store i64 %7, i64* %result, align 8, !insn.addr !2694
  %.pre = load i64, i64* %2, align 8
  store i64 %.pre, i64* %.reg2mem, !insn.addr !2694
  store i64 %rdi.0.reload, i64* %rdi.1.reg2mem, !insn.addr !2694
  br label %dec_label_pc_b62d, !insn.addr !2694

dec_label_pc_b62d:                                ; preds = %dec_label_pc_b61b, %dec_label_pc_b5ce
  %rdi.1.reload = load i64, i64* %rdi.1.reg2mem
  %.reload = load i64, i64* %.reg2mem, !insn.addr !2695
  %8 = icmp eq i64 %rdi.1.reload, %.reload, !insn.addr !2696
  br i1 %8, label %dec_label_pc_b679, label %dec_label_pc_b641, !insn.addr !2697

dec_label_pc_b641:                                ; preds = %dec_label_pc_b62d
  %9 = call i64 @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv(), !insn.addr !2698
  %10 = icmp eq i64 %rdi.1.reload, %9, !insn.addr !2699
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !2700
  br i1 %10, label %dec_label_pc_b61b, label %dec_label_pc_b655, !insn.addr !2700

dec_label_pc_b655:                                ; preds = %dec_label_pc_b641
  %11 = call i64 @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv(), !insn.addr !2701
  %12 = icmp eq i64 %rdi.1.reload, %11, !insn.addr !2702
  %13 = icmp eq i1 %12, false, !insn.addr !2703
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !2703
  br i1 %13, label %dec_label_pc_b679, label %dec_label_pc_b61b, !insn.addr !2703

dec_label_pc_b679:                                ; preds = %dec_label_pc_b655, %dec_label_pc_b62d
  ret i64 0, !insn.addr !2704

; uselistorder directives
  uselistorder i64 %rdi.1.reload, { 3, 2, 4, 0, 1 }
  uselistorder i64 %0, { 0, 2, 1 }
  uselistorder i64* %rdi.0.reg2mem, { 2, 1, 0, 3 }
  uselistorder label %dec_label_pc_b61b, { 1, 0, 2 }
}

define i64 @_ZN4llvm23SmallPtrSetIteratorImpl17RetreatIfNotValidEv(i64* %result) local_unnamed_addr {
dec_label_pc_b682:
  %rdi.1.reg2mem = alloca i64, !insn.addr !2705
  %.reg2mem = alloca i64, !insn.addr !2705
  %rdi.0.reg2mem = alloca i64, !insn.addr !2705
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !2706
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2706
  %3 = load i64, i64* %2, align 8, !insn.addr !2706
  %4 = icmp ugt i64 %3, %0, !insn.addr !2707
  %5 = icmp eq i1 %4, false, !insn.addr !2708
  store i64 %3, i64* %.reg2mem, !insn.addr !2708
  store i64 %0, i64* %rdi.1.reg2mem, !insn.addr !2708
  br i1 %5, label %dec_label_pc_b6e1, label %dec_label_pc_b6a7, !insn.addr !2708

dec_label_pc_b6a7:                                ; preds = %dec_label_pc_b682
  %6 = call i64 @__assert_fail(i64 ptrtoint ([14 x i8]* @global_var_579c to i64), i64 ptrtoint ([44 x i8]* @global_var_569c to i64), i64 305, i64 ptrtoint ([56 x i8]* @global_var_5764 to i64)), !insn.addr !2709
  store i64 ptrtoint ([14 x i8]* @global_var_579c to i64), i64* %rdi.0.reg2mem, !insn.addr !2709
  br label %dec_label_pc_b6cf, !insn.addr !2709

dec_label_pc_b6cf:                                ; preds = %dec_label_pc_b6f5, %dec_label_pc_b70d, %dec_label_pc_b6a7
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %7 = add i64 %rdi.0.reload, -8, !insn.addr !2710
  store i64 %7, i64* %result, align 8, !insn.addr !2711
  %.pre = load i64, i64* %2, align 8
  store i64 %.pre, i64* %.reg2mem, !insn.addr !2711
  store i64 %rdi.0.reload, i64* %rdi.1.reg2mem, !insn.addr !2711
  br label %dec_label_pc_b6e1, !insn.addr !2711

dec_label_pc_b6e1:                                ; preds = %dec_label_pc_b6cf, %dec_label_pc_b682
  %rdi.1.reload = load i64, i64* %rdi.1.reg2mem
  %.reload = load i64, i64* %.reg2mem, !insn.addr !2712
  %8 = icmp eq i64 %rdi.1.reload, %.reload, !insn.addr !2713
  br i1 %8, label %dec_label_pc_b735, label %dec_label_pc_b6f5, !insn.addr !2714

dec_label_pc_b6f5:                                ; preds = %dec_label_pc_b6e1
  %9 = add i64 %rdi.1.reload, -8, !insn.addr !2715
  %10 = inttoptr i64 %9 to i64*, !insn.addr !2716
  %11 = load i64, i64* %10, align 8, !insn.addr !2716
  %12 = call i64 @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv(), !insn.addr !2717
  %13 = icmp eq i64 %11, %12, !insn.addr !2718
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !2719
  br i1 %13, label %dec_label_pc_b6cf, label %dec_label_pc_b70d, !insn.addr !2719

dec_label_pc_b70d:                                ; preds = %dec_label_pc_b6f5
  %14 = load i64, i64* %10, align 8, !insn.addr !2720
  %15 = call i64 @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv(), !insn.addr !2721
  %16 = icmp eq i64 %14, %15, !insn.addr !2722
  %17 = icmp eq i1 %16, false, !insn.addr !2723
  store i64 %rdi.1.reload, i64* %rdi.0.reg2mem, !insn.addr !2723
  br i1 %17, label %dec_label_pc_b735, label %dec_label_pc_b6cf, !insn.addr !2723

dec_label_pc_b735:                                ; preds = %dec_label_pc_b70d, %dec_label_pc_b6e1
  ret i64 0, !insn.addr !2724

; uselistorder directives
  uselistorder i64 %rdi.1.reload, { 2, 3, 0, 1 }
  uselistorder i64* %rdi.0.reg2mem, { 2, 1, 0, 3 }
  uselistorder i64 ()* @_ZN4llvm19SmallPtrSetImplBase18getTombstoneMarkerEv, { 1, 0 }
  uselistorder i64 ()* @_ZN4llvm19SmallPtrSetImplBase14getEmptyMarkerEv, { 1, 0 }
  uselistorder label %dec_label_pc_b6cf, { 1, 0, 2 }
}

define i64 @_ZN4llvm4castINS_8FunctionENS_5ValueEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_b73d:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2725
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2726
  %2 = call i1 @_ZN4llvm3isaINS_8FunctionEPNS_5ValueEEEbRKT0_(i64** nonnull %1), !insn.addr !2726
  %3 = icmp eq i1 %2, false, !insn.addr !2727
  %4 = icmp eq i1 %3, false, !insn.addr !2728
  br i1 %4, label %dec_label_pc_b785, label %dec_label_pc_b75d, !insn.addr !2728

dec_label_pc_b75d:                                ; preds = %dec_label_pc_b73d
  %5 = call i64 @__assert_fail(i64 ptrtoint ([60 x i8]* @global_var_50e4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 578, i64 ptrtoint ([68 x i8]* @global_var_57b4 to i64)), !insn.addr !2729
  br label %dec_label_pc_b785, !insn.addr !2729

dec_label_pc_b785:                                ; preds = %dec_label_pc_b75d, %dec_label_pc_b73d
  %6 = call i64 @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE6doCastERKS3_(i64** nonnull %1), !insn.addr !2730
  ret i64 %6, !insn.addr !2731
}

define i64 @_ZNK4llvm13IntrinsicInst14getIntrinsicIDEv(i64* %result) local_unnamed_addr {
dec_label_pc_b794:
  %0 = call i64 @_ZNK4llvm8CallBase16getCalledOperandEv(i64* %result), !insn.addr !2732
  %1 = inttoptr i64 %0 to i64*, !insn.addr !2733
  %2 = call i64 @_ZN4llvm4castINS_8FunctionENS_5ValueEEEDcPT0_(i64* %1), !insn.addr !2733
  %3 = inttoptr i64 %2 to i64*, !insn.addr !2734
  %4 = call i64 @_ZNK4llvm8Function14getIntrinsicIDEv(i64* %3), !insn.addr !2734
  ret i64 %4, !insn.addr !2735
}

define i64 @_ZN4llvm13IntrinsicInst7classofEPKNS_8CallInstE(i64* %arg1) local_unnamed_addr {
dec_label_pc_b7c2:
  %storemerge.reg2mem = alloca i64, !insn.addr !2736
  %0 = call i64 @_ZNK4llvm8CallBase16getCalledOperandEv(i64* %arg1), !insn.addr !2737
  %1 = inttoptr i64 %0 to i64*, !insn.addr !2738
  %2 = call i64 @_ZN4llvm16dyn_cast_or_nullINS_8FunctionENS_5ValueEEEDaPT0_(i64* %1), !insn.addr !2738
  %3 = icmp eq i64 %2, 0, !insn.addr !2739
  br i1 %3, label %dec_label_pc_b808, label %dec_label_pc_b7f1, !insn.addr !2740

dec_label_pc_b7f1:                                ; preds = %dec_label_pc_b7c2
  %4 = inttoptr i64 %2 to i64*, !insn.addr !2741
  %5 = call i64 @_ZNK4llvm8Function11isIntrinsicEv(i64* %4), !insn.addr !2741
  %6 = trunc i64 %5 to i8, !insn.addr !2742
  %7 = icmp eq i8 %6, 0, !insn.addr !2742
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !2743
  br i1 %7, label %dec_label_pc_b808, label %dec_label_pc_b80d, !insn.addr !2743

dec_label_pc_b808:                                ; preds = %dec_label_pc_b7f1, %dec_label_pc_b7c2
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2744
  br label %dec_label_pc_b80d, !insn.addr !2744

dec_label_pc_b80d:                                ; preds = %dec_label_pc_b7f1, %dec_label_pc_b808
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2745

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*)* @_ZNK4llvm8CallBase16getCalledOperandEv, { 1, 0 }
  uselistorder label %dec_label_pc_b80d, { 1, 0 }
}

define i64 @_ZN4llvm4castINS_8CallInstEKNS_5ValueEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_b80f:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2746
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2747
  %2 = call i1 @_ZN4llvm3isaINS_8CallInstEPKNS_5ValueEEEbRKT0_(i64** nonnull %1), !insn.addr !2747
  %3 = icmp eq i1 %2, false, !insn.addr !2748
  %4 = icmp eq i1 %3, false, !insn.addr !2749
  br i1 %4, label %dec_label_pc_b857, label %dec_label_pc_b82f, !insn.addr !2749

dec_label_pc_b82f:                                ; preds = %dec_label_pc_b80f
  %5 = call i64 @__assert_fail(i64 ptrtoint ([60 x i8]* @global_var_50e4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 578, i64 ptrtoint ([74 x i8]* @global_var_57fc to i64)), !insn.addr !2750
  br label %dec_label_pc_b857, !insn.addr !2750

dec_label_pc_b857:                                ; preds = %dec_label_pc_b82f, %dec_label_pc_b80f
  %6 = call i64 @_ZN4llvm8CastInfoINS_8CallInstEPKNS_5ValueEvE6doCastERKS4_(i64** nonnull %1), !insn.addr !2751
  ret i64 %6, !insn.addr !2752
}

define i64 @_ZN4llvm13IntrinsicInst7classofEPKNS_5ValueE(i64* %arg1) local_unnamed_addr {
dec_label_pc_b865:
  %storemerge.reg2mem = alloca i64, !insn.addr !2753
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2754
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2755
  %2 = call i1 @_ZN4llvm3isaINS_8CallInstEPKNS_5ValueEEEbRKT0_(i64** nonnull %1), !insn.addr !2755
  %3 = icmp eq i1 %2, false, !insn.addr !2756
  br i1 %3, label %dec_label_pc_b8a4, label %dec_label_pc_b885, !insn.addr !2757

dec_label_pc_b885:                                ; preds = %dec_label_pc_b865
  %4 = load i64, i64* %stack_var_-16, align 8, !insn.addr !2758
  %5 = inttoptr i64 %4 to i64*, !insn.addr !2759
  %6 = call i64 @_ZN4llvm4castINS_8CallInstEKNS_5ValueEEEDcPT0_(i64* %5), !insn.addr !2759
  %7 = inttoptr i64 %6 to i64*, !insn.addr !2760
  %8 = call i64 @_ZN4llvm13IntrinsicInst7classofEPKNS_8CallInstE(i64* %7), !insn.addr !2760
  %9 = trunc i64 %8 to i8, !insn.addr !2761
  %10 = icmp eq i8 %9, 0, !insn.addr !2761
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !2762
  br i1 %10, label %dec_label_pc_b8a4, label %dec_label_pc_b8a9, !insn.addr !2762

dec_label_pc_b8a4:                                ; preds = %dec_label_pc_b885, %dec_label_pc_b865
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2763
  br label %dec_label_pc_b8a9, !insn.addr !2763

dec_label_pc_b8a9:                                ; preds = %dec_label_pc_b885, %dec_label_pc_b8a4
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2764

; uselistorder directives
  uselistorder i64* %stack_var_-16, { 1, 0, 2 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_b8a9, { 1, 0 }
}

define i64 @_ZN4llvm4castINS_13IntrinsicInstEKNS_5ValueEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_b8ab:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2765
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2766
  %2 = call i1 @_ZN4llvm3isaINS_13IntrinsicInstEPKNS_5ValueEEEbRKT0_(i64** nonnull %1), !insn.addr !2766
  %3 = icmp eq i1 %2, false, !insn.addr !2767
  %4 = icmp eq i1 %3, false, !insn.addr !2768
  br i1 %4, label %dec_label_pc_b8f3, label %dec_label_pc_b8cb, !insn.addr !2768

dec_label_pc_b8cb:                                ; preds = %dec_label_pc_b8ab
  %5 = call i64 @__assert_fail(i64 ptrtoint ([60 x i8]* @global_var_50e4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 578, i64 ptrtoint ([79 x i8]* @global_var_584c to i64)), !insn.addr !2769
  br label %dec_label_pc_b8f3, !insn.addr !2769

dec_label_pc_b8f3:                                ; preds = %dec_label_pc_b8cb, %dec_label_pc_b8ab
  %6 = call i64 @_ZN4llvm8CastInfoINS_13IntrinsicInstEPKNS_5ValueEvE6doCastERKS4_(i64** nonnull %1), !insn.addr !2770
  ret i64 %6, !insn.addr !2771
}

define i64 @_ZN4llvmL18isDbgInfoIntrinsicEj(i32 %arg1) local_unnamed_addr {
dec_label_pc_b901:
  %0 = and i32 %arg1, -4
  %1 = icmp eq i32 %0, 68
  %. = zext i1 %1 to i64
  ret i64 %., !insn.addr !2772
}

define i64 @_ZN4llvm16DbgInfoIntrinsic7classofEPKNS_13IntrinsicInstE(i64* %arg1) local_unnamed_addr {
dec_label_pc_b921:
  %0 = call i64 @_ZNK4llvm13IntrinsicInst14getIntrinsicIDEv(i64* %arg1), !insn.addr !2773
  %1 = trunc i64 %0 to i32, !insn.addr !2774
  %2 = call i64 @_ZN4llvmL18isDbgInfoIntrinsicEj(i32 %1), !insn.addr !2775
  ret i64 %2, !insn.addr !2776
}

define i64 @_ZN4llvm16DbgInfoIntrinsic7classofEPKNS_5ValueE(i64* %arg1) local_unnamed_addr {
dec_label_pc_b946:
  %storemerge.reg2mem = alloca i64, !insn.addr !2777
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2778
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2779
  %2 = call i1 @_ZN4llvm3isaINS_13IntrinsicInstEPKNS_5ValueEEEbRKT0_(i64** nonnull %1), !insn.addr !2779
  %3 = icmp eq i1 %2, false, !insn.addr !2780
  br i1 %3, label %dec_label_pc_b985, label %dec_label_pc_b966, !insn.addr !2781

dec_label_pc_b966:                                ; preds = %dec_label_pc_b946
  %4 = load i64, i64* %stack_var_-16, align 8, !insn.addr !2782
  %5 = inttoptr i64 %4 to i64*, !insn.addr !2783
  %6 = call i64 @_ZN4llvm4castINS_13IntrinsicInstEKNS_5ValueEEEDcPT0_(i64* %5), !insn.addr !2783
  %7 = inttoptr i64 %6 to i64*, !insn.addr !2784
  %8 = call i64 @_ZN4llvm16DbgInfoIntrinsic7classofEPKNS_13IntrinsicInstE(i64* %7), !insn.addr !2784
  %9 = trunc i64 %8 to i8, !insn.addr !2785
  %10 = icmp eq i8 %9, 0, !insn.addr !2785
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !2786
  br i1 %10, label %dec_label_pc_b985, label %dec_label_pc_b98a, !insn.addr !2786

dec_label_pc_b985:                                ; preds = %dec_label_pc_b966, %dec_label_pc_b946
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2787
  br label %dec_label_pc_b98a, !insn.addr !2787

dec_label_pc_b98a:                                ; preds = %dec_label_pc_b966, %dec_label_pc_b985
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2788

; uselistorder directives
  uselistorder i64* %stack_var_-16, { 1, 0, 2 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_b98a, { 1, 0 }
}

define i64 @_ZN4llvm17PreservedAnalysesC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_b98c:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm11SmallPtrSetIPvLj2EEC1Ev(i64* %result), !insn.addr !2789
  %2 = add i64 %0, 40, !insn.addr !2790
  %3 = inttoptr i64 %2 to i64*, !insn.addr !2791
  %4 = call i64 @_ZN4llvm11SmallPtrSetIPNS_11AnalysisKeyELj2EEC1Ev(i64* %3), !insn.addr !2791
  ret i64 %4, !insn.addr !2792
}

define i64 @_ZN4llvm17PreservedAnalyses4noneEv(i64* %result) local_unnamed_addr {
dec_label_pc_b9bb:
  %0 = alloca i128
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %result to i64
  %3 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !2793
  %4 = bitcast i64* %rdi to i128*
  %5 = load i128, i128* %4, align 8, !insn.addr !2794
  call void @__asm_movups(i128 %5, i128 %3), !insn.addr !2794
  %6 = add i64 %2, 16, !insn.addr !2795
  %7 = inttoptr i64 %6 to i128*, !insn.addr !2795
  %8 = load i128, i128* %7, align 8, !insn.addr !2795
  call void @__asm_movups(i128 %8, i128 %3), !insn.addr !2795
  %9 = add i64 %2, 32, !insn.addr !2796
  %10 = inttoptr i64 %9 to i128*, !insn.addr !2796
  %11 = load i128, i128* %10, align 8, !insn.addr !2796
  call void @__asm_movups(i128 %11, i128 %3), !insn.addr !2796
  %12 = add i64 %2, 48, !insn.addr !2797
  %13 = inttoptr i64 %12 to i128*, !insn.addr !2797
  %14 = load i128, i128* %13, align 8, !insn.addr !2797
  call void @__asm_movups(i128 %14, i128 %3), !insn.addr !2797
  %15 = add i64 %2, ptrtoint (i128** @global_var_40 to i64), !insn.addr !2798
  %16 = inttoptr i64 %15 to i128*, !insn.addr !2798
  %17 = load i128, i128* %16, align 8, !insn.addr !2798
  call void @__asm_movups(i128 %17, i128 %3), !insn.addr !2798
  %18 = call i64 @_ZN4llvm17PreservedAnalysesC1Ev(i64* %result), !insn.addr !2799
  ret i64 %2, !insn.addr !2800

; uselistorder directives
  uselistorder i128 %3, { 4, 3, 2, 1, 0 }
  uselistorder i64 %2, { 0, 4, 3, 2, 1 }
  uselistorder i128 %1, { 1, 0 }
}

define i64 @_ZN4llvm17PreservedAnalyses3allEv(i64* %result) local_unnamed_addr {
dec_label_pc_b9f8:
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2801
  %1 = call i64 @_ZN4llvm17PreservedAnalysesC1Ev(i64* %result), !insn.addr !2802
  %2 = load i64, i64* inttoptr (i64 47666 to i64*), align 8, !insn.addr !2803
  %3 = inttoptr i64 %2 to i64*, !insn.addr !2804
  %4 = call i64 @_ZN4llvm15SmallPtrSetImplIPvE6insertES1_(i64* nonnull %stack_var_-40, i64* %result, i64* %3), !insn.addr !2804
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !2805
  %6 = icmp eq i64 %0, %5, !insn.addr !2805
  br i1 %6, label %dec_label_pc_ba52, label %dec_label_pc_ba4d, !insn.addr !2806

dec_label_pc_ba4d:                                ; preds = %dec_label_pc_b9f8
  %7 = call i64 @__stack_chk_fail(), !insn.addr !2807
  br label %dec_label_pc_ba52, !insn.addr !2807

dec_label_pc_ba52:                                ; preds = %dec_label_pc_ba4d, %dec_label_pc_b9f8
  %8 = ptrtoint i64* %result to i64
  ret i64 %8, !insn.addr !2808

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm17PreservedAnalysesC1Ev, { 1, 0 }
  uselistorder i64* %result, { 2, 0, 1 }
}

define i64 @_ZN9__gnu_cxx11char_traitsIcE6lengthEPKc(i8* %arg1) local_unnamed_addr {
dec_label_pc_ba58:
  %rax.0.reg2mem = alloca i64, !insn.addr !2809
  %storemerge.reg2mem = alloca i64, !insn.addr !2809
  %stack_var_-25 = alloca i8, align 1
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2810
  %1 = ptrtoint i8* %arg1 to i64, !insn.addr !2811
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2812
  br label %dec_label_pc_ba86, !insn.addr !2812

dec_label_pc_ba86:                                ; preds = %dec_label_pc_ba86, %dec_label_pc_ba58
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  store i8 0, i8* %stack_var_-25, align 1, !insn.addr !2813
  %2 = add i64 %storemerge.reload, %1, !insn.addr !2814
  %3 = inttoptr i64 %2 to i8*, !insn.addr !2815
  %4 = call i64 @_ZN9__gnu_cxx11char_traitsIcE2eqERKcS3_(i8* %3, i8* nonnull %stack_var_-25), !insn.addr !2815
  %5 = trunc i64 %4 to i8
  %6 = icmp eq i8 %5, 1, !insn.addr !2816
  %7 = icmp eq i1 %6, false, !insn.addr !2817
  %8 = add i64 %storemerge.reload, 1, !insn.addr !2818
  store i64 %8, i64* %storemerge.reg2mem, !insn.addr !2817
  br i1 %7, label %dec_label_pc_ba86, label %dec_label_pc_baab, !insn.addr !2817

dec_label_pc_baab:                                ; preds = %dec_label_pc_ba86
  %9 = call i64 @__readfsqword(i64 40), !insn.addr !2819
  %10 = icmp eq i64 %0, %9, !insn.addr !2819
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !2820
  br i1 %10, label %dec_label_pc_bac3, label %dec_label_pc_babe, !insn.addr !2820

dec_label_pc_babe:                                ; preds = %dec_label_pc_baab
  %11 = call i64 @__stack_chk_fail(), !insn.addr !2821
  store i64 %11, i64* %rax.0.reg2mem, !insn.addr !2821
  br label %dec_label_pc_bac3, !insn.addr !2821

dec_label_pc_bac3:                                ; preds = %dec_label_pc_babe, %dec_label_pc_baab
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2822

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 2, 0, 1 }
}

define i64 @_ZN9__gnu_cxx11char_traitsIcE2eqERKcS3_(i8* %arg1, i8* %arg2) local_unnamed_addr {
dec_label_pc_bac5:
  %0 = alloca i64
  %1 = load i64, i64* %0
  %2 = load i64, i64* %0
  %3 = trunc i64 %1 to i8
  %4 = trunc i64 %2 to i8
  %5 = icmp eq i8 %3, %4, !insn.addr !2823
  %6 = zext i1 %5 to i64, !insn.addr !2824
  ret i64 %6, !insn.addr !2825

; uselistorder directives
  uselistorder i64* %0, { 1, 0 }
}

define i64 @_ZN4llvm6Module5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_baea:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 24, !insn.addr !2826
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2827
  %3 = call i64 @_ZN4llvm12simple_ilistINS_8FunctionEJEE5beginEv(i64* %2), !insn.addr !2827
  ret i64 %3, !insn.addr !2828
}

define i64 @_ZN4llvm6Module3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_bb0c:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 24, !insn.addr !2829
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2830
  %3 = call i64 @_ZN4llvm12simple_ilistINS_8FunctionEJEE3endEv(i64* %2), !insn.addr !2830
  ret i64 %3, !insn.addr !2831
}

define i64 @_ZNKSt19_Optional_base_implIN4llvm13FastMathFlagsESt14_Optional_baseIS1_Lb1ELb1EEE13_M_is_engagedEv(i64* %result) local_unnamed_addr {
dec_label_pc_bb2e:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 4, !insn.addr !2832
  %2 = inttoptr i64 %1 to i8*, !insn.addr !2832
  %3 = load i8, i8* %2, align 1, !insn.addr !2832
  %4 = zext i8 %3 to i64, !insn.addr !2832
  ret i64 %4, !insn.addr !2833
}

define i64 @_ZN4llvm11PassBuilder31registerPipelineParsingCallbackERKSt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS0_15PipelineElementEEEEE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_bb44:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 1328, !insn.addr !2834
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2835
  %3 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE9push_backERKSE_(i64* %2, i64* %arg2), !insn.addr !2835
  ret i64 %3, !insn.addr !2836
}

define i64 @_ZN4llvm19dyn_cast_if_presentINS_11GlobalAliasENS_5ValueEEEDaPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_bb75:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2837
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2838
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_5ValueEEEbRKT_(i64** nonnull %1), !insn.addr !2838
  %3 = call i64 @_ZN4llvm8CastInfoINS_11GlobalAliasEPNS_5ValueEvE10castFailedEv(), !insn.addr !2839
  ret i64 %3, !insn.addr !2840
}

define i64 @_ZN4llvm16dyn_cast_or_nullINS_11GlobalAliasENS_5ValueEEEDaPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_bbb6:
  %0 = call i64 @_ZN4llvm19dyn_cast_if_presentINS_11GlobalAliasENS_5ValueEEEDaPT0_(i64* %arg1), !insn.addr !2841
  ret i64 %0, !insn.addr !2842
}

define i64 @_ZN4llvm8dyn_castINS_11IntegerTypeENS_4TypeEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_bbd4:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2843
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2844
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_4TypeEEEbRKT_(i64** nonnull %1), !insn.addr !2844
  %3 = icmp eq i1 %2, false, !insn.addr !2845
  %4 = icmp eq i1 %3, false, !insn.addr !2846
  br i1 %4, label %dec_label_pc_bc1c, label %dec_label_pc_bbf4, !insn.addr !2846

dec_label_pc_bbf4:                                ; preds = %dec_label_pc_bbd4
  %5 = call i64 @__assert_fail(i64 ptrtoint ([61 x i8]* @global_var_5334 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 662, i64 ptrtoint ([74 x i8]* @global_var_59fc to i64)), !insn.addr !2847
  br label %dec_label_pc_bc1c, !insn.addr !2847

dec_label_pc_bc1c:                                ; preds = %dec_label_pc_bbf4, %dec_label_pc_bbd4
  %6 = call i64 @_ZN4llvm8CastInfoINS_11IntegerTypeEPNS_4TypeEvE16doCastIfPossibleERKS3_(i64** nonnull %1), !insn.addr !2848
  ret i64 %6, !insn.addr !2849

; uselistorder directives
  uselistorder i1 (i64**)* @_ZN4llvm6detail9isPresentIPNS_4TypeEEEbRKT_, { 0, 2, 1 }
}

define i64 @_ZN4llvm13IRBuilderBaseD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_bc2a:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 48, !insn.addr !2850
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2851
  %3 = call i64 @_ZN4llvm8DebugLocD1Ev(i64* %2), !insn.addr !2851
  %4 = call i64 @_ZN4llvm11SmallVectorISt4pairIjPNS_6MDNodeEELj2EED1Ev(i64* %result), !insn.addr !2852
  ret i64 %4, !insn.addr !2853

; uselistorder directives
  uselistorder i64 48, { 4, 1, 0, 2, 3, 5, 6, 7 }
}

define i64 @_ZN4llvm14ConstantFolderD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_bc5a:
  %0 = load i64, i64* inttoptr (i64 48241 to i64*), align 8, !insn.addr !2854
  %1 = add i64 %0, 16, !insn.addr !2855
  store i64 %1, i64* %result, align 8, !insn.addr !2856
  %2 = call i64 @_ZN4llvm15IRBuilderFolderD2Ev(i64* %result), !insn.addr !2857
  ret i64 %2, !insn.addr !2858
}

define i64 @_ZN4llvm14ConstantFolderD0Ev(i64* %result) local_unnamed_addr {
dec_label_pc_bc8c:
  %0 = call i64 @_ZN4llvm14ConstantFolderD1Ev(i64* %result), !insn.addr !2859
  %1 = call i64 @_ZdlPvm(i64* %result, i64 8), !insn.addr !2860
  ret i64 %1, !insn.addr !2861
}

define i64 @_ZN4llvm9IRBuilderINS_14ConstantFolderENS_24IRBuilderDefaultInserterEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_bcbc:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 144, !insn.addr !2862
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2863
  %3 = call i64 @_ZN4llvm24IRBuilderDefaultInserterD1Ev(i64* %2), !insn.addr !2863
  %4 = add i64 %0, 136, !insn.addr !2864
  %5 = inttoptr i64 %4 to i64*, !insn.addr !2865
  %6 = call i64 @_ZN4llvm14ConstantFolderD1Ev(i64* %5), !insn.addr !2865
  %7 = call i64 @_ZN4llvm13IRBuilderBaseD1Ev(i64* %result), !insn.addr !2866
  ret i64 %7, !insn.addr !2867
}

define i64 @_ZN4llvm8dyn_castINS_8CallBaseENS_11InstructionEEEDcPT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_bcff:
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-16 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-16, align 8, !insn.addr !2868
  %1 = bitcast i64* %stack_var_-16 to i64**, !insn.addr !2869
  %2 = call i1 @_ZN4llvm6detail9isPresentIPNS_11InstructionEEEbRKT_(i64** nonnull %1), !insn.addr !2869
  %3 = icmp eq i1 %2, false, !insn.addr !2870
  %4 = icmp eq i1 %3, false, !insn.addr !2871
  br i1 %4, label %dec_label_pc_bd47, label %dec_label_pc_bd1f, !insn.addr !2871

dec_label_pc_bd1f:                                ; preds = %dec_label_pc_bcff
  %5 = call i64 @__assert_fail(i64 ptrtoint ([61 x i8]* @global_var_5334 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 662, i64 ptrtoint ([78 x i8]* @global_var_5a64 to i64)), !insn.addr !2872
  br label %dec_label_pc_bd47, !insn.addr !2872

dec_label_pc_bd47:                                ; preds = %dec_label_pc_bd1f, %dec_label_pc_bcff
  %6 = call i64 @_ZN4llvm8CastInfoINS_8CallBaseEPNS_11InstructionEvE16doCastIfPossibleERKS3_(i64** nonnull %1), !insn.addr !2873
  ret i64 %6, !insn.addr !2874

; uselistorder directives
  uselistorder i1 (i64**)* @_ZN4llvm6detail9isPresentIPNS_11InstructionEEEbRKT_, { 2, 1, 0 }
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_bd56:
  %0 = call i64 @_ZNSt14_Function_baseD1Ev(i64* %result), !insn.addr !2875
  ret i64 %0, !insn.addr !2876
}

define i64 @_ZN9__gnu_cxx11char_traitsIcE4findEPKcmRS2_(i8* %arg1, i64 %arg2, i8* %arg3) local_unnamed_addr {
dec_label_pc_bd76:
  %storemerge.reg2mem = alloca i64, !insn.addr !2877
  %storemerge34.reg2mem = alloca i64, !insn.addr !2877
  %0 = ptrtoint i8* %arg1 to i64
  %1 = icmp eq i64 %arg2, 0, !insn.addr !2878
  store i64 0, i64* %storemerge34.reg2mem, !insn.addr !2879
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2879
  br i1 %1, label %dec_label_pc_bdd7, label %dec_label_pc_bd98, !insn.addr !2879

dec_label_pc_bd98:                                ; preds = %dec_label_pc_bd76, %dec_label_pc_bdc8
  %storemerge34.reload = load i64, i64* %storemerge34.reg2mem
  %2 = add i64 %storemerge34.reload, %0, !insn.addr !2880
  %3 = inttoptr i64 %2 to i8*, !insn.addr !2881
  %4 = call i64 @_ZN9__gnu_cxx11char_traitsIcE2eqERKcS3_(i8* %3, i8* %arg3), !insn.addr !2881
  %5 = trunc i64 %4 to i8, !insn.addr !2882
  %6 = icmp eq i8 %5, 0, !insn.addr !2882
  store i64 %2, i64* %storemerge.reg2mem, !insn.addr !2883
  br i1 %6, label %dec_label_pc_bdc8, label %dec_label_pc_bdd7, !insn.addr !2883

dec_label_pc_bdc8:                                ; preds = %dec_label_pc_bd98
  %7 = add nuw i64 %storemerge34.reload, 1, !insn.addr !2884
  %8 = icmp ult i64 %7, %arg2, !insn.addr !2878
  store i64 %7, i64* %storemerge34.reg2mem, !insn.addr !2879
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !2879
  br i1 %8, label %dec_label_pc_bd98, label %dec_label_pc_bdd7, !insn.addr !2879

dec_label_pc_bdd7:                                ; preds = %dec_label_pc_bdc8, %dec_label_pc_bd98, %dec_label_pc_bd76
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !2885

; uselistorder directives
  uselistorder i64* %storemerge34.reg2mem, { 2, 0, 1 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1, 3 }
  uselistorder i64 (i8*, i8*)* @_ZN9__gnu_cxx11char_traitsIcE2eqERKcS3_, { 1, 0 }
  uselistorder i64 %arg2, { 1, 0 }
  uselistorder label %dec_label_pc_bd98, { 1, 0 }
}

define i64 @_ZNSt17basic_string_viewIcSt11char_traitsIcEEC1EPKcm(i64* %result, i8* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_bdda:
  %0 = ptrtoint i8* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %arg3, i64* %result, align 8, !insn.addr !2886
  %2 = add i64 %1, 8, !insn.addr !2887
  %3 = inttoptr i64 %2 to i64*, !insn.addr !2887
  store i64 %0, i64* %3, align 8, !insn.addr !2887
  ret i64 %1, !insn.addr !2888

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64* @_ZSt3maxImERKT_S2_S2_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_be08:
  %0 = icmp ult i64* %arg1, %arg2, !insn.addr !2889
  %1 = icmp eq i1 %0, false, !insn.addr !2890
  %storemerge.v = select i1 %1, i64* %arg1, i64* %arg2
  ret i64* %storemerge.v, !insn.addr !2891
}

define i1 @_ZN4llvm14has_single_bitIjvEEbT_(i32 %arg1) local_unnamed_addr {
dec_label_pc_be37:
  %storemerge.reg2mem = alloca i1, !insn.addr !2892
  %0 = icmp eq i32 %arg1, 0, !insn.addr !2893
  br i1 %0, label %dec_label_pc_be5c, label %dec_label_pc_be48, !insn.addr !2894

dec_label_pc_be48:                                ; preds = %dec_label_pc_be37
  %1 = add i32 %arg1, -1, !insn.addr !2895
  %2 = and i32 %1, %arg1, !insn.addr !2896
  %3 = icmp eq i32 %2, 0, !insn.addr !2897
  %4 = icmp eq i1 %3, false, !insn.addr !2898
  store i1 true, i1* %storemerge.reg2mem, !insn.addr !2898
  br i1 %4, label %dec_label_pc_be5c, label %dec_label_pc_be61, !insn.addr !2898

dec_label_pc_be5c:                                ; preds = %dec_label_pc_be48, %dec_label_pc_be37
  store i1 false, i1* %storemerge.reg2mem, !insn.addr !2899
  br label %dec_label_pc_be61, !insn.addr !2899

dec_label_pc_be61:                                ; preds = %dec_label_pc_be48, %dec_label_pc_be5c
  %storemerge.reload = load i1, i1* %storemerge.reg2mem
  ret i1 %storemerge.reload, !insn.addr !2900

; uselistorder directives
  uselistorder i1* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_be61, { 1, 0 }
}

define i32 @_ZN4llvm11countl_zeroIjEEiT_(i32 %arg1) local_unnamed_addr {
dec_label_pc_be63:
  %0 = icmp eq i32 %arg1, 0, !insn.addr !2901
  %1 = icmp eq i1 %0, false, !insn.addr !2902
  %2 = call i32 @llvm.ctlz.i32(i32 %arg1, i1 true), !range !2903
  %spec.select = select i1 %1, i32 %2, i32 32
  ret i32 %spec.select, !insn.addr !2904
}

define i64 @_ZNKSt17basic_string_viewIcSt11char_traitsIcEE4findEcm(i64* %result, i8 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_be86:
  %stack_var_-32.0.reg2mem = alloca i64, !insn.addr !2905
  %0 = ptrtoint i64* %result to i64
  %stack_var_-52 = alloca i8, align 1
  store i8 %arg2, i8* %stack_var_-52, align 1, !insn.addr !2906
  %1 = icmp ugt i64 %0, %arg3, !insn.addr !2907
  %2 = icmp eq i1 %1, false, !insn.addr !2908
  store i64 -1, i64* %stack_var_-32.0.reg2mem, !insn.addr !2908
  br i1 %2, label %dec_label_pc_bf04, label %dec_label_pc_beb4, !insn.addr !2908

dec_label_pc_beb4:                                ; preds = %dec_label_pc_be86
  %3 = sub i64 %0, %arg3, !insn.addr !2909
  %4 = add i64 %0, 8, !insn.addr !2910
  %5 = inttoptr i64 %4 to i64*, !insn.addr !2910
  %6 = load i64, i64* %5, align 8, !insn.addr !2910
  %7 = add i64 %6, %arg3, !insn.addr !2911
  %8 = inttoptr i64 %7 to i8*, !insn.addr !2912
  %9 = call i64 @_ZNSt11char_traitsIcE4findEPKcmRS1_(i8* %8, i64 %3, i8* nonnull %stack_var_-52), !insn.addr !2912
  %10 = icmp eq i64 %9, 0, !insn.addr !2913
  store i64 -1, i64* %stack_var_-32.0.reg2mem, !insn.addr !2914
  br i1 %10, label %dec_label_pc_bf04, label %dec_label_pc_bef1, !insn.addr !2914

dec_label_pc_bef1:                                ; preds = %dec_label_pc_beb4
  %11 = load i64, i64* %5, align 8, !insn.addr !2915
  %12 = sub i64 %9, %11, !insn.addr !2916
  store i64 %12, i64* %stack_var_-32.0.reg2mem, !insn.addr !2917
  br label %dec_label_pc_bf04, !insn.addr !2917

dec_label_pc_bf04:                                ; preds = %dec_label_pc_bef1, %dec_label_pc_beb4, %dec_label_pc_be86
  %stack_var_-32.0.reload = load i64, i64* %stack_var_-32.0.reg2mem
  ret i64 %stack_var_-32.0.reload, !insn.addr !2918

; uselistorder directives
  uselistorder i64 -1, { 0, 1, 2, 6, 5, 3, 4 }
}

define i64* @_ZSt5clampImERKT_S2_S2_S2_(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_bf0a:
  %0 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !2919
  %1 = call i64* @_ZSt3maxImERKT_S2_S2_(i64* %arg1, i64* %arg2), !insn.addr !2920
  %2 = call i64* @_ZSt3minImERKT_S2_S2_(i64* %1, i64* %arg3), !insn.addr !2921
  ret i64* %2, !insn.addr !2922
}

define i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1IS3_EEPKcRKS3_(i64* %result, i8* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_bf74:
  %0 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv(i64* %result), !insn.addr !2923
  %1 = inttoptr i64 %0 to i8*, !insn.addr !2924
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcRKS3_(i64* %result, i8* %1, i64* %arg3), !insn.addr !2924
  %3 = icmp eq i8* %arg2, null, !insn.addr !2925
  %4 = icmp eq i1 %3, false, !insn.addr !2926
  br i1 %4, label %dec_label_pc_bfc8, label %dec_label_pc_bfb9, !insn.addr !2926

dec_label_pc_bfb9:                                ; preds = %dec_label_pc_bf74
  %5 = call i64 @_ZSt19__throw_logic_errorPKc(i8* getelementptr inbounds ([50 x i8], [50 x i8]* @global_var_5b24, i64 0, i64 0)), !insn.addr !2927
  br label %dec_label_pc_bfc8, !insn.addr !2927

dec_label_pc_bfc8:                                ; preds = %dec_label_pc_bfb9, %dec_label_pc_bf74
  %6 = call i64 @_ZNSt11char_traitsIcE6lengthEPKc(i8* %arg2), !insn.addr !2928
  %7 = ptrtoint i8* %arg2 to i64, !insn.addr !2929
  %8 = add i64 %6, %7, !insn.addr !2930
  %9 = bitcast i64* %result to i8*, !insn.addr !2931
  call void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tag(i8* %9, i8* %arg2, i64 %8), !insn.addr !2931
  ret i64 ptrtoint (i32* @0 to i64), !insn.addr !2932

; uselistorder directives
  uselistorder i8* %arg2, { 2, 1, 0, 3 }
}

define i1 @_ZN4llvm3isaINS_11InstructionEPKNS_5ValueEEEbRKT0_(i64** %arg1) local_unnamed_addr {
dec_label_pc_bffd:
  %0 = call i64 @_ZN4llvm8CastInfoINS_11InstructionEKPKNS_5ValueEvE10isPossibleERS5_(i64** %arg1), !insn.addr !2933
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !2934
  ret i1 %2, !insn.addr !2934
}

define i64 @_ZN4llvm8ArrayRefIPNS_4TypeEEC1EPKS2_S5_(i64* %result, i64** %arg2, i64** %arg3) local_unnamed_addr {
dec_label_pc_c01c:
  %rax.0.reg2mem = alloca i64, !insn.addr !2935
  %0 = ptrtoint i64** %arg3 to i64
  %1 = ptrtoint i64** %arg2 to i64
  %2 = ptrtoint i64* %result to i64
  store i64 %1, i64* %result, align 8, !insn.addr !2936
  %3 = sub i64 %0, %1, !insn.addr !2937
  %4 = ashr i64 %3, 3, !insn.addr !2938
  %5 = add i64 %2, 8, !insn.addr !2939
  %6 = inttoptr i64 %5 to i64*, !insn.addr !2939
  store i64 %4, i64* %6, align 8, !insn.addr !2939
  %7 = icmp ult i64** %arg3, %arg2, !insn.addr !2940
  %8 = icmp eq i1 %7, false, !insn.addr !2941
  store i64 %1, i64* %rax.0.reg2mem, !insn.addr !2941
  br i1 %8, label %dec_label_pc_c088, label %dec_label_pc_c060, !insn.addr !2941

dec_label_pc_c060:                                ; preds = %dec_label_pc_c01c
  %9 = call i64 @__assert_fail(i64 ptrtoint ([13 x i8]* @global_var_5bdd to i64), i64 ptrtoint ([41 x i8]* @global_var_5bb4 to i64), i64 85, i64 ptrtoint ([81 x i8]* @global_var_5b5c to i64)), !insn.addr !2942
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !2942
  br label %dec_label_pc_c088, !insn.addr !2942

dec_label_pc_c088:                                ; preds = %dec_label_pc_c060, %dec_label_pc_c01c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2943

; uselistorder directives
  uselistorder i64 %1, { 0, 2, 1 }
}

define i64 @_ZN4llvm8CastInfoINS_11IntegerTypeEPNS_4TypeEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c08b:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !2944
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_11IntegerTypeEPNS_4TypeES3_E4doitEPKS2_(i64* %0), !insn.addr !2944
  ret i64 %1, !insn.addr !2945
}

define i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi2EJS8_EECI1NS1_IS9_SG_Li3EJEEEESG_(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_c0ac:
  %0 = call i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi3EJEEC1ESG_(i64* %result, i64 %arg2), !insn.addr !2946
  ret i64 %0, !insn.addr !2947
}

define i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi1EJS6_S8_EEC1ES6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_c0d6:
  %rax.0.reg2mem = alloca i64, !insn.addr !2948
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2949
  %1 = call i64 @_ZN4llvm21PointerLikeTypeTraitsIPNS_8MetadataEE16getAsVoidPointerES2_(i64* %arg2), !insn.addr !2950
  %2 = inttoptr i64 %1 to i64*, !insn.addr !2951
  %3 = call i64 @_ZN4llvm14PointerIntPairIPvLj2EiNS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_18PointerIntPairInfoIS1_Lj2ESA_EEEC1ES1_i(i64* nonnull %stack_var_-40, i64* %2, i32 1), !insn.addr !2951
  %4 = load i64, i64* %stack_var_-40, align 8, !insn.addr !2952
  %5 = call i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi2EJS8_EECI1NS1_IS9_SG_Li3EJEEEESG_(i64* %result, i64 %4), !insn.addr !2953
  %6 = call i64 @__readfsqword(i64 40), !insn.addr !2954
  %7 = icmp eq i64 %0, %6, !insn.addr !2954
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !2955
  br i1 %7, label %dec_label_pc_c145, label %dec_label_pc_c140, !insn.addr !2955

dec_label_pc_c140:                                ; preds = %dec_label_pc_c0d6
  %8 = call i64 @__stack_chk_fail(), !insn.addr !2956
  store i64 %8, i64* %rax.0.reg2mem, !insn.addr !2956
  br label %dec_label_pc_c145, !insn.addr !2956

dec_label_pc_c145:                                ; preds = %dec_label_pc_c140, %dec_label_pc_c0d6
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2957

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 1, 0 }
}

define i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEEC1ERKS2_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_c14c:
  %0 = call i64 @_ZN4llvm13TrackingMDRefC1ERKS0_(i64* %result, i64* %arg2), !insn.addr !2958
  ret i64 %0, !insn.addr !2959
}

define i64* @_ZSt4moveIRN4llvm8DebugLocEEONSt16remove_referenceIT_E4typeEOS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c176:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !2960
  ret i64* %0, !insn.addr !2960
}

define i64 @_ZN4llvm18TypedTrackingMDRefINS_6MDNodeEEaSEOS2_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_c188:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i64* %arg2 to i64**, !insn.addr !2961
  %2 = call i64* @_ZSt4moveIRN4llvm13TrackingMDRefEEONSt16remove_referenceIT_E4typeEOS4_(i64** %1), !insn.addr !2961
  %3 = call i64 @_ZN4llvm13TrackingMDRefaSEOS0_(i64* %result, i64* %2), !insn.addr !2962
  ret i64 %0, !insn.addr !2963
}

define i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_c1c0:
  %rdi.0.reg2mem = alloca i64, !insn.addr !2964
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE15isKnownSentinelEv(i64* %result), !insn.addr !2965
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !2966
  %4 = icmp eq i1 %3, false, !insn.addr !2967
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !2967
  br i1 %4, label %dec_label_pc_c20e, label %dec_label_pc_c1e6, !insn.addr !2967

dec_label_pc_c1e6:                                ; preds = %dec_label_pc_c1c0
  %5 = call i64 @__assert_fail(i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64 ptrtoint ([47 x i8]* @global_var_5d24 to i64), i64 168, i64 ptrtoint ([309 x i8]* @global_var_5bec to i64)), !insn.addr !2968
  store i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64* %rdi.0.reg2mem, !insn.addr !2968
  br label %dec_label_pc_c20e, !insn.addr !2968

dec_label_pc_c20e:                                ; preds = %dec_label_pc_c1e6, %dec_label_pc_c1c0
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %6 = inttoptr i64 %rdi.0.reload to i64*, !insn.addr !2969
  %7 = call i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %6), !insn.addr !2969
  ret i64 %7, !insn.addr !2970
}

define i1 @_ZN4llvm3isaINS_17DbgVariableRecordENS_9DbgRecordEEEbRKT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_c21f:
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_17DbgVariableRecordEKNS_9DbgRecordEvE10isPossibleERS3_(i64* %arg1), !insn.addr !2971
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !2972
  ret i1 %2, !insn.addr !2972
}

define i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_c23d:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = icmp eq i64* %arg1, %arg2, !insn.addr !2973
  %2 = icmp eq i1 %1, false, !insn.addr !2974
  %3 = zext i1 %2 to i64, !insn.addr !2974
  %4 = and i64 %0, -256, !insn.addr !2974
  %5 = or i64 %4, %3, !insn.addr !2974
  ret i64 %5, !insn.addr !2975
}

define i64 @_ZNK4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EE10setHeadBitEb(i64* %result, i1 %arg2) local_unnamed_addr {
dec_label_pc_c264:
  %0 = ptrtoint i64* %result to i64
  %1 = sext i1 %arg2 to i8, !insn.addr !2976
  %2 = add i64 %0, 8, !insn.addr !2977
  %3 = inttoptr i64 %2 to i8*, !insn.addr !2977
  store i8 %1, i8* %3, align 1, !insn.addr !2977
  ret i64 %0, !insn.addr !2978

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm12simple_ilistINS_11InstructionEJNS_19ilist_iterator_bitsILb1EEENS_12ilist_parentINS_10BasicBlockEEEEE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_c284:
  %rax.0.reg2mem = alloca i64, !insn.addr !2979
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2980
  %1 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1ERNS_15ilist_node_implIS5_EE(i64* nonnull %stack_var_-40, i64* %result), !insn.addr !2981
  %2 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEppEv(i64* nonnull %stack_var_-40), !insn.addr !2982
  %3 = inttoptr i64 %2 to i64*, !insn.addr !2983
  %4 = load i64, i64* %3, align 8, !insn.addr !2983
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !2984
  %6 = icmp eq i64 %0, %5, !insn.addr !2984
  store i64 %4, i64* %rax.0.reg2mem, !insn.addr !2985
  br i1 %6, label %dec_label_pc_c2dd, label %dec_label_pc_c2d8, !insn.addr !2985

dec_label_pc_c2d8:                                ; preds = %dec_label_pc_c284
  %7 = call i64 @__stack_chk_fail(), !insn.addr !2986
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !2986
  br label %dec_label_pc_c2dd, !insn.addr !2986

dec_label_pc_c2dd:                                ; preds = %dec_label_pc_c2d8, %dec_label_pc_c284
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2987

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEppEv, { 1, 0 }
}

define i64 @_ZN4llvm12simple_ilistINS_11InstructionEJNS_19ilist_iterator_bitsILb1EEENS_12ilist_parentINS_10BasicBlockEEEEE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_c2e0:
  %rax.0.reg2mem = alloca i64, !insn.addr !2988
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2989
  %1 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1ERNS_15ilist_node_implIS5_EE(i64* nonnull %stack_var_-40, i64* %result), !insn.addr !2990
  %2 = load i64, i64* %stack_var_-40, align 8, !insn.addr !2991
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !2992
  %4 = icmp eq i64 %0, %3, !insn.addr !2992
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !2993
  br i1 %4, label %dec_label_pc_c32e, label %dec_label_pc_c329, !insn.addr !2993

dec_label_pc_c329:                                ; preds = %dec_label_pc_c2e0
  %5 = call i64 @__stack_chk_fail(), !insn.addr !2994
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !2994
  br label %dec_label_pc_c32e, !insn.addr !2994

dec_label_pc_c32e:                                ; preds = %dec_label_pc_c329, %dec_label_pc_c2e0
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !2995

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 1, 0 }
}

define i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEE11getIteratorEv(i64* %result) local_unnamed_addr {
dec_label_pc_c330:
  %rax.0.reg2mem = alloca i64, !insn.addr !2996
  %stack_var_-40 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !2997
  %1 = call i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1ERNS_15ilist_node_implIS5_EE(i64* nonnull %stack_var_-40, i64* %result), !insn.addr !2998
  %2 = load i64, i64* %stack_var_-40, align 8, !insn.addr !2999
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !3000
  %4 = icmp eq i64 %0, %3, !insn.addr !3000
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !3001
  br i1 %4, label %dec_label_pc_c37e, label %dec_label_pc_c379, !insn.addr !3001

dec_label_pc_c379:                                ; preds = %dec_label_pc_c330
  %5 = call i64 @__stack_chk_fail(), !insn.addr !3002
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !3002
  br label %dec_label_pc_c37e, !insn.addr !3002

dec_label_pc_c37e:                                ; preds = %dec_label_pc_c379, %dec_label_pc_c330
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3003

; uselistorder directives
  uselistorder i64* %stack_var_-40, { 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1ERNS_15ilist_node_implIS5_EE, { 2, 1, 0 }
}

define i64 @_ZN4llvm12simple_ilistINS_10BasicBlockEJEE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_c380:
  %rax.0.reg2mem = alloca i64, !insn.addr !3004
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3005
  %1 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE(i64* nonnull %stack_var_-24, i64* %result), !insn.addr !3006
  %2 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* nonnull %stack_var_-24), !insn.addr !3007
  %3 = inttoptr i64 %2 to i64*, !insn.addr !3008
  %4 = load i64, i64* %3, align 8, !insn.addr !3008
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !3009
  %6 = icmp eq i64 %0, %5, !insn.addr !3009
  store i64 %4, i64* %rax.0.reg2mem, !insn.addr !3010
  br i1 %6, label %dec_label_pc_c3d5, label %dec_label_pc_c3d0, !insn.addr !3010

dec_label_pc_c3d0:                                ; preds = %dec_label_pc_c380
  %7 = call i64 @__stack_chk_fail(), !insn.addr !3011
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !3011
  br label %dec_label_pc_c3d5, !insn.addr !3011

dec_label_pc_c3d5:                                ; preds = %dec_label_pc_c3d0, %dec_label_pc_c380
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3012

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEppEv, { 1, 0 }
}

define i64 @_ZN4llvm12simple_ilistINS_10BasicBlockEJEE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_c3d8:
  %rax.0.reg2mem = alloca i64, !insn.addr !3013
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3014
  %1 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE(i64* nonnull %stack_var_-24, i64* %result), !insn.addr !3015
  %2 = load i64, i64* %stack_var_-24, align 8, !insn.addr !3016
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !3017
  %4 = icmp eq i64 %0, %3, !insn.addr !3017
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !3018
  br i1 %4, label %dec_label_pc_c422, label %dec_label_pc_c41d, !insn.addr !3018

dec_label_pc_c41d:                                ; preds = %dec_label_pc_c3d8
  %5 = call i64 @__stack_chk_fail(), !insn.addr !3019
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !3019
  br label %dec_label_pc_c422, !insn.addr !3019

dec_label_pc_c422:                                ; preds = %dec_label_pc_c41d, %dec_label_pc_c3d8
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3020

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE, { 1, 0 }
}

define i64 @_ZNK4llvm12simple_ilistINS_10BasicBlockEJEE5emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_c424:
  %0 = call i64 @_ZNK4llvm14ilist_sentinelINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE5emptyEv(i64* %result), !insn.addr !3021
  ret i64 %0, !insn.addr !3022
}

define i1 @_ZN4llvm6detail9isPresentIPNS_5ValueEEEbRKT_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c442:
  %0 = call i64 @_ZN4llvm13simplify_typeIPNS_5ValueEE18getSimplifiedValueERS2_(i64** %arg1), !insn.addr !3023
  %1 = inttoptr i64 %0 to i64**, !insn.addr !3024
  %2 = call i64 @_ZN4llvm14ValueIsPresentIPNS_5ValueEvE9isPresentERKS2_(i64** %1), !insn.addr !3024
  %3 = urem i64 %2, 2
  %4 = icmp ne i64 %3, 0, !insn.addr !3025
  ret i1 %4, !insn.addr !3025
}

define i64 @_ZN4llvm8CastInfoINS_5ValueEPS1_vE10castFailedEv() local_unnamed_addr {
dec_label_pc_c468:
  ret i64 0, !insn.addr !3026
}

define i1 @_ZN4llvm3isaINS_5ValueEPS1_EEbRKT0_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c477:
  %0 = call i64 @_ZN4llvm8CastInfoINS_5ValueEKPS1_vE10isPossibleERS3_(i64** %arg1), !insn.addr !3027
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !3028
  ret i1 %2, !insn.addr !3028
}

define i64 @_ZN4llvm8CastInfoINS_5ValueEPS1_vE6doCastERKS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c495:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3029
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_5ValueEPS1_S2_E4doitEPKS1_(i64* %0), !insn.addr !3029
  ret i64 %1, !insn.addr !3030
}

define i64 @_ZN4llvm8CastInfoINS_11InstructionEPKNS_5ValueEvE6doCastERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c4b6:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3031
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_11InstructionEPKNS_5ValueES4_E4doitES4_(i64* %0), !insn.addr !3031
  ret i64 %1, !insn.addr !3032
}

define i64 @_ZN4llvm21FixedNumOperandTraitsINS_16UnaryInstructionELj1EE8op_beginEPS1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_c4d7:
  %0 = ptrtoint i64* %arg1 to i64
  %1 = add i64 %0, -32, !insn.addr !3033
  ret i64 %1, !insn.addr !3034
}

define i64 @_ZN4llvm21FixedNumOperandTraitsINS_16UnaryInstructionELj1EE8operandsEPKNS_4UserE(i64* %arg1) local_unnamed_addr {
dec_label_pc_c4ed:
  ret i64 1, !insn.addr !3035
}

define i1 @_ZN4llvm6detail9isPresentIPNS_4TypeEEEbRKT_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c500:
  %0 = call i64 @_ZN4llvm13simplify_typeIPNS_4TypeEE18getSimplifiedValueERS2_(i64** %arg1), !insn.addr !3036
  %1 = inttoptr i64 %0 to i64**, !insn.addr !3037
  %2 = call i64 @_ZN4llvm14ValueIsPresentIPNS_4TypeEvE9isPresentERKS2_(i64** %1), !insn.addr !3037
  %3 = urem i64 %2, 2
  %4 = icmp ne i64 %3, 0, !insn.addr !3038
  ret i1 %4, !insn.addr !3038
}

define i64* @_ZNK4llvm8CallBase2OpILin1EEERKNS_3UseEv(i64* %result) local_unnamed_addr {
dec_label_pc_c526:
  %0 = call i64* @_ZN4llvm4User6OpFromILin1ENS_8CallBaseEEERNS_3UseEPKT0_(i64* %result), !insn.addr !3039
  ret i64* %0, !insn.addr !3040
}

define i64 @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_c544:
  ret i64 0, !insn.addr !3041
}

define i64 @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c553:
  %storemerge.reg2mem = alloca i64, !insn.addr !3042
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_8FunctionEPNS_5ValueEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3043
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3044
  br i1 %2, label %dec_label_pc_c57d, label %dec_label_pc_c576, !insn.addr !3045

dec_label_pc_c576:                                ; preds = %dec_label_pc_c553
  %3 = call i64 @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE10castFailedEv(), !insn.addr !3046
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3047
  br label %dec_label_pc_c58a, !insn.addr !3047

dec_label_pc_c57d:                                ; preds = %dec_label_pc_c553
  %4 = call i64 @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE6doCastERKS3_(i64** %arg1), !insn.addr !3048
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3049
  br label %dec_label_pc_c58a, !insn.addr !3049

dec_label_pc_c58a:                                ; preds = %dec_label_pc_c57d, %dec_label_pc_c576
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3050

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64**)* @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE6doCastERKS3_, { 1, 0 }
  uselistorder i64 ()* @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE10castFailedEv, { 1, 0 }
}

define i64 @_ZN4llvm21VariadicOperandTraitsINS_8CallBaseEE6op_endEPS1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_c58c:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3051
}

define i64 @_ZN4llvm8CastInfoINS_9ArrayTypeEPNS_4TypeEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c59e:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3052
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_9ArrayTypeEPNS_4TypeES3_E4doitEPKS2_(i64* %0), !insn.addr !3052
  ret i64 %1, !insn.addr !3053
}

define i64 @_ZN4llvm8CastInfoINS_10StructTypeEPNS_4TypeEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c5bf:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3054
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_10StructTypeEPNS_4TypeES3_E4doitEPKS2_(i64* %0), !insn.addr !3054
  ret i64 %1, !insn.addr !3055
}

define i1 @_ZN4llvm6detail9isPresentIPKNS_5ValueEEEbRKT_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c5e0:
  %0 = call i64 @_ZN4llvm13simplify_typeIPKNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3056
  %1 = inttoptr i64 %0 to i64**, !insn.addr !3057
  %2 = call i64 @_ZN4llvm14ValueIsPresentIPKNS_5ValueEvE9isPresentERKS3_(i64** %1), !insn.addr !3057
  %3 = urem i64 %2, 2
  %4 = icmp ne i64 %3, 0, !insn.addr !3058
  ret i1 %4, !insn.addr !3058
}

define i64 @_ZN4llvm8CastInfoINS_11InstructionEPKNS_5ValueEvE16doCastIfPossibleERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c606:
  %storemerge.reg2mem = alloca i64, !insn.addr !3059
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_11InstructionEPKNS_5ValueEvE10isPossibleERKS4_(i64** %arg1), !insn.addr !3060
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3061
  br i1 %2, label %dec_label_pc_c630, label %dec_label_pc_c629, !insn.addr !3062

dec_label_pc_c629:                                ; preds = %dec_label_pc_c606
  %3 = call i64 @_ZN4llvm8CastInfoINS_11InstructionEPKNS_5ValueEvE10castFailedEv(), !insn.addr !3063
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3064
  br label %dec_label_pc_c63d, !insn.addr !3064

dec_label_pc_c630:                                ; preds = %dec_label_pc_c606
  %4 = call i64 @_ZN4llvm8CastInfoINS_11InstructionEPKNS_5ValueEvE6doCastERKS4_(i64** %arg1), !insn.addr !3065
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3066
  br label %dec_label_pc_c63d, !insn.addr !3066

dec_label_pc_c63d:                                ; preds = %dec_label_pc_c630, %dec_label_pc_c629
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3067

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZN4llvm8CastInfoINS_10StructTypeEPNS_4TypeEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c63f:
  %storemerge.reg2mem = alloca i64, !insn.addr !3068
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_10StructTypeEPNS_4TypeEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3069
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3070
  br i1 %2, label %dec_label_pc_c669, label %dec_label_pc_c662, !insn.addr !3071

dec_label_pc_c662:                                ; preds = %dec_label_pc_c63f
  %3 = call i64 @_ZN4llvm8CastInfoINS_10StructTypeEPNS_4TypeEvE10castFailedEv(), !insn.addr !3072
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3073
  br label %dec_label_pc_c676, !insn.addr !3073

dec_label_pc_c669:                                ; preds = %dec_label_pc_c63f
  %4 = call i64 @_ZN4llvm8CastInfoINS_10StructTypeEPNS_4TypeEvE6doCastERKS3_(i64** %arg1), !insn.addr !3074
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3075
  br label %dec_label_pc_c676, !insn.addr !3075

dec_label_pc_c676:                                ; preds = %dec_label_pc_c669, %dec_label_pc_c662
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3076

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZNK4llvm8ArrayRefIPNS_4TypeEE5frontEv(i64* %result) local_unnamed_addr {
dec_label_pc_c678:
  %rdi.0.reg2mem = alloca i64, !insn.addr !3077
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm8ArrayRefIPNS_4TypeEE5emptyEv(i64* %result), !insn.addr !3078
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !3079
  %4 = icmp eq i1 %3, false, !insn.addr !3080
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !3080
  br i1 %4, label %dec_label_pc_c6c3, label %dec_label_pc_c69b, !insn.addr !3080

dec_label_pc_c69b:                                ; preds = %dec_label_pc_c678
  %5 = call i64 @__assert_fail(i64 ptrtoint ([9 x i8]* @global_var_5db5 to i64), i64 ptrtoint ([41 x i8]* @global_var_5bb4 to i64), i64 151, i64 ptrtoint ([65 x i8]* @global_var_5d74 to i64)), !insn.addr !3081
  store i64 ptrtoint ([9 x i8]* @global_var_5db5 to i64), i64* %rdi.0.reg2mem, !insn.addr !3081
  br label %dec_label_pc_c6c3, !insn.addr !3081

dec_label_pc_c6c3:                                ; preds = %dec_label_pc_c69b, %dec_label_pc_c678
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  ret i64 %rdi.0.reload, !insn.addr !3082
}

define i64 @_ZN4llvm8CastInfoINS_9ArrayTypeEPNS_4TypeEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c6cc:
  %storemerge.reg2mem = alloca i64, !insn.addr !3083
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_9ArrayTypeEPNS_4TypeEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3084
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3085
  br i1 %2, label %dec_label_pc_c6f6, label %dec_label_pc_c6ef, !insn.addr !3086

dec_label_pc_c6ef:                                ; preds = %dec_label_pc_c6cc
  %3 = call i64 @_ZN4llvm8CastInfoINS_9ArrayTypeEPNS_4TypeEvE10castFailedEv(), !insn.addr !3087
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3088
  br label %dec_label_pc_c703, !insn.addr !3088

dec_label_pc_c6f6:                                ; preds = %dec_label_pc_c6cc
  %4 = call i64 @_ZN4llvm8CastInfoINS_9ArrayTypeEPNS_4TypeEvE6doCastERKS3_(i64** %arg1), !insn.addr !3089
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3090
  br label %dec_label_pc_c703, !insn.addr !3090

dec_label_pc_c703:                                ; preds = %dec_label_pc_c6f6, %dec_label_pc_c6ef
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3091

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZNK4llvm11Instruction15getSubclassDataINS_8Bitfield7ElementIbLj0ELj1ELb1EEEEENT_4TypeEv(i64* %result) local_unnamed_addr {
dec_label_pc_c706:
  %0 = call i64 @_ZNK4llvm11Instruction24getSubclassDataFromValueEv(i64* %result), !insn.addr !3092
  %1 = trunc i64 %0 to i16, !insn.addr !3093
  %2 = call i64 @_ZN4llvm8Bitfield3getINS0_7ElementIbLj0ELj1ELb1EEEtEENT_4TypeET0_(i16 %1), !insn.addr !3094
  ret i64 %2, !insn.addr !3095
}

define i64 @_ZN4llvm21FixedNumOperandTraitsINS_9StoreInstELj2EE8op_beginEPS1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_c72e:
  %0 = ptrtoint i64* %arg1 to i64
  %1 = sub i64 %0, ptrtoint (i128** @global_var_40 to i64), !insn.addr !3096
  ret i64 %1, !insn.addr !3097

; uselistorder directives
  uselistorder i128** @global_var_40, { 1, 0 }
  uselistorder i64 ptrtoint (i128** @global_var_40 to i64), { 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 }
}

define i64 @_ZN4llvm21FixedNumOperandTraitsINS_9StoreInstELj2EE8operandsEPKNS_4UserE(i64* %arg1) local_unnamed_addr {
dec_label_pc_c744:
  ret i64 2, !insn.addr !3098
}

define i1 @_ZN4llvm6detail9isPresentIPNS_11InstructionEEEbRKT_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c757:
  %0 = call i64 @_ZN4llvm13simplify_typeIPNS_11InstructionEE18getSimplifiedValueERS2_(i64** %arg1), !insn.addr !3099
  %1 = inttoptr i64 %0 to i64**, !insn.addr !3100
  %2 = call i64 @_ZN4llvm14ValueIsPresentIPNS_11InstructionEvE9isPresentERKS2_(i64** %1), !insn.addr !3100
  %3 = urem i64 %2, 2
  %4 = icmp ne i64 %3, 0, !insn.addr !3101
  ret i1 %4, !insn.addr !3101
}

define i64 @_ZN4llvm8CastInfoINS_8LoadInstEPNS_11InstructionEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c77d:
  %storemerge.reg2mem = alloca i64, !insn.addr !3102
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_8LoadInstEPNS_11InstructionEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3103
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3104
  br i1 %2, label %dec_label_pc_c7a7, label %dec_label_pc_c7a0, !insn.addr !3105

dec_label_pc_c7a0:                                ; preds = %dec_label_pc_c77d
  %3 = call i64 @_ZN4llvm8CastInfoINS_8LoadInstEPNS_11InstructionEvE10castFailedEv(), !insn.addr !3106
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3107
  br label %dec_label_pc_c7b4, !insn.addr !3107

dec_label_pc_c7a7:                                ; preds = %dec_label_pc_c77d
  %4 = call i64 @_ZN4llvm8CastInfoINS_8LoadInstEPNS_11InstructionEvE6doCastERKS3_(i64** %arg1), !insn.addr !3108
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3109
  br label %dec_label_pc_c7b4, !insn.addr !3109

dec_label_pc_c7b4:                                ; preds = %dec_label_pc_c7a7, %dec_label_pc_c7a0
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3110

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZN4llvm8CastInfoINS_9StoreInstEPNS_11InstructionEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_c7b6:
  %storemerge.reg2mem = alloca i64, !insn.addr !3111
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_9StoreInstEPNS_11InstructionEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3112
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3113
  br i1 %2, label %dec_label_pc_c7e0, label %dec_label_pc_c7d9, !insn.addr !3114

dec_label_pc_c7d9:                                ; preds = %dec_label_pc_c7b6
  %3 = call i64 @_ZN4llvm8CastInfoINS_9StoreInstEPNS_11InstructionEvE10castFailedEv(), !insn.addr !3115
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3116
  br label %dec_label_pc_c7ed, !insn.addr !3116

dec_label_pc_c7e0:                                ; preds = %dec_label_pc_c7b6
  %4 = call i64 @_ZN4llvm8CastInfoINS_9StoreInstEPNS_11InstructionEvE6doCastERKS3_(i64** %arg1), !insn.addr !3117
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3118
  br label %dec_label_pc_c7ed, !insn.addr !3118

dec_label_pc_c7ed:                                ; preds = %dec_label_pc_c7e0, %dec_label_pc_c7d9
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3119

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZNSt14_Function_baseC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_c7f0:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !3120
  %1 = add i64 %0, 8, !insn.addr !3121
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3121
  store i64 0, i64* %2, align 8, !insn.addr !3121
  %3 = add i64 %0, 16, !insn.addr !3122
  %4 = inttoptr i64 %3 to i64*, !insn.addr !3122
  store i64 0, i64* %4, align 8, !insn.addr !3122
  ret i64 %0, !insn.addr !3123

; uselistorder directives
  uselistorder i64 %0, { 1, 0, 2 }
}

define i64 @_ZNSt22_Optional_payload_baseIN4llvm13FastMathFlagsEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_c81e:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNSt22_Optional_payload_baseIN4llvm13FastMathFlagsEE8_StorageIS1_Lb1EEC1Ev(i64* %result), !insn.addr !3124
  %2 = add i64 %0, 4, !insn.addr !3125
  %3 = inttoptr i64 %2 to i8*, !insn.addr !3125
  store i8 0, i8* %3, align 1, !insn.addr !3125
  ret i64 %0, !insn.addr !3126

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZNSt17_Optional_payloadIN4llvm13FastMathFlagsELb1ELb1ELb1EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_c846:
  %0 = call i64 @_ZNSt22_Optional_payload_baseIN4llvm13FastMathFlagsEEC1Ev(i64* %result), !insn.addr !3127
  ret i64 %0, !insn.addr !3128
}

define i64 @_ZNSt14_Optional_baseIN4llvm13FastMathFlagsELb1ELb1EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_c866:
  %0 = call i64 @_ZNSt17_Optional_payloadIN4llvm13FastMathFlagsELb1ELb1ELb1EEC1Ev(i64* %result), !insn.addr !3129
  ret i64 %0, !insn.addr !3130
}

define i64 @_ZNSt8optionalIN4llvm13FastMathFlagsEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_c886:
  %0 = call i64 @_ZNSt14_Optional_baseIN4llvm13FastMathFlagsELb1ELb1EEC1Ev(i64* %result), !insn.addr !3131
  ret i64 %0, !insn.addr !3132
}

define i64 @_ZNKRSt8optionalIN4llvm13FastMathFlagsEE8value_orIRS1_EES1_OT_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_c8a6:
  %storemerge.in.in.reg2mem = alloca i32*, !insn.addr !3133
  %0 = call i64 @_ZNKSt19_Optional_base_implIN4llvm13FastMathFlagsESt14_Optional_baseIS1_Lb1ELb1EEE13_M_is_engagedEv(i64* %result), !insn.addr !3134
  %1 = trunc i64 %0 to i8, !insn.addr !3135
  %2 = icmp eq i8 %1, 0, !insn.addr !3135
  br i1 %2, label %dec_label_pc_c8da, label %dec_label_pc_c8ca, !insn.addr !3136

dec_label_pc_c8ca:                                ; preds = %dec_label_pc_c8a6
  %3 = call i64 @_ZNKSt19_Optional_base_implIN4llvm13FastMathFlagsESt14_Optional_baseIS1_Lb1ELb1EEE6_M_getEv(i64* %result), !insn.addr !3137
  %4 = inttoptr i64 %3 to i32*, !insn.addr !3138
  store i32* %4, i32** %storemerge.in.in.reg2mem, !insn.addr !3139
  br label %dec_label_pc_c8e8, !insn.addr !3139

dec_label_pc_c8da:                                ; preds = %dec_label_pc_c8a6
  %5 = bitcast i64** %arg2 to i64*
  %6 = call i64** @_ZSt7forwardIRN4llvm13FastMathFlagsEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %5), !insn.addr !3140
  %7 = bitcast i64** %6 to i32*, !insn.addr !3141
  store i32* %7, i32** %storemerge.in.in.reg2mem, !insn.addr !3141
  br label %dec_label_pc_c8e8, !insn.addr !3141

dec_label_pc_c8e8:                                ; preds = %dec_label_pc_c8da, %dec_label_pc_c8ca
  %storemerge.in.in.reload = load i32*, i32** %storemerge.in.in.reg2mem
  %storemerge.in = load i32, i32* %storemerge.in.in.reload, align 4
  %storemerge = zext i32 %storemerge.in to i64
  ret i64 %storemerge, !insn.addr !3142

; uselistorder directives
  uselistorder i32** %storemerge.in.in.reg2mem, { 0, 2, 1 }
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_c8ea:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !3143
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_c900:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv(i64* %result), !insn.addr !3144
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !3145
  %2 = mul i64 %1, 16, !insn.addr !3146
  %3 = add i64 %2, %0, !insn.addr !3147
  ret i64 %3, !insn.addr !3148
}

define i64 @_ZN4llvm11SmallVectorISt4pairIjPNS_6MDNodeEELj2EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_c93a:
  %0 = call i64 @_ZN4llvm15SmallVectorImplISt4pairIjPNS_6MDNodeEEEC1Ej(i64* %result, i32 2), !insn.addr !3149
  ret i64 %0, !insn.addr !3150
}

define i64 @_ZN4llvm11SmallVectorISt4pairIjPNS_6MDNodeEELj2EED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_c95e:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE3endEv(i64* %result), !insn.addr !3151
  %1 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv(i64* %result), !insn.addr !3152
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3153
  %3 = inttoptr i64 %0 to i64*, !insn.addr !3153
  %4 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt4pairIjPNS_6MDNodeEELb1EE13destroy_rangeEPS4_S6_(i64* %2, i64* %3), !insn.addr !3153
  %5 = call i64 @_ZN4llvm15SmallVectorImplISt4pairIjPNS_6MDNodeEEED1Ev(i64* %result), !insn.addr !3154
  ret i64 %5, !insn.addr !3155
}

define i64* @_ZNK4llvm13IRBuilderBase6InsertINS_11InstructionEEEPT_S4_RKNS_5TwineE(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_c9a8:
  %0 = call i64 @_ZNK4llvm13IRBuilderBase17AddMetadataToInstEPNS_11InstructionE(i64* %result, i64* %arg2), !insn.addr !3156
  ret i64* %arg2, !insn.addr !3157
}

define i64 @_ZN4llvm12ilist_detail18node_parent_accessINS_15ilist_node_implINS0_12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEEES5_E9getParentEv(i64* %result) local_unnamed_addr {
dec_label_pc_ca10:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !3158
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3159
  %3 = call i64 @_ZN4llvm12ilist_detail16node_base_parentINS_10BasicBlockEE17getNodeBaseParentEv(i64* %2), !insn.addr !3159
  ret i64 %3, !insn.addr !3160
}

define i64 @_ZN4llvmneERKNS_21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEES8_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_ca32:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = icmp eq i64* %arg1, %arg2, !insn.addr !3161
  %2 = icmp eq i1 %1, false, !insn.addr !3162
  %3 = zext i1 %2 to i64, !insn.addr !3162
  %4 = and i64 %0, -256, !insn.addr !3162
  %5 = or i64 %4, %3, !insn.addr !3162
  ret i64 %5, !insn.addr !3163
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_ca58:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !3164
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_ca6e:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv(i64* %result), !insn.addr !3165
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !3166
  %2 = mul i64 %1, 16, !insn.addr !3167
  %3 = add i64 %2, %0, !insn.addr !3168
  ret i64 %3, !insn.addr !3169

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv, { 1, 0 }
}

define i1 @_ZN4llvm3isaINS_14FPMathOperatorEPNS_11InstructionEEEbRKT0_(i64** %arg1) local_unnamed_addr {
dec_label_pc_caa7:
  %0 = call i64 @_ZN4llvm8CastInfoINS_14FPMathOperatorEKPNS_11InstructionEvE10isPossibleERS4_(i64** %arg1), !insn.addr !3170
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !3171
  ret i1 %2, !insn.addr !3171
}

define i64* @_ZNK4llvm13IRBuilderBase6InsertINS_8ZExtInstEEEPT_S4_RKNS_5TwineE(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_cac6:
  %0 = call i64 @_ZNK4llvm13IRBuilderBase17AddMetadataToInstEPNS_11InstructionE(i64* %result, i64* %arg2), !insn.addr !3172
  ret i64* %arg2, !insn.addr !3173

; uselistorder directives
  uselistorder i64 (i64*, i64*)* @_ZNK4llvm13IRBuilderBase17AddMetadataToInstEPNS_11InstructionE, { 1, 0 }
}

define i32* @_ZSt3maxIjERKT_S2_S2_(i32* %arg1, i32* %arg2) local_unnamed_addr {
dec_label_pc_cb2e:
  %0 = alloca i64
  %1 = load i64, i64* %0
  %2 = load i64, i64* %0
  %3 = trunc i64 %1 to i32
  %4 = trunc i64 %2 to i32
  %5 = icmp ult i32 %3, %4, !insn.addr !3174
  %6 = icmp eq i1 %5, false, !insn.addr !3175
  %storemerge.in = select i1 %6, i32* %arg1, i32* %arg2
  ret i32* %storemerge.in, !insn.addr !3176

; uselistorder directives
  uselistorder i64* %0, { 1, 0 }
}

define i64 @_ZSt9make_pairIRPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS5_INS6_IT0_E4typeEE6__typeEEOS7_OSC_(i64**** %arg1, i1* %arg2) local_unnamed_addr {
dec_label_pc_cb5a:
  %rax.0.reg2mem = alloca i64, !insn.addr !3177
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3178
  %1 = bitcast i1* %arg2 to i64*
  %2 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %1), !insn.addr !3179
  %3 = bitcast i64**** %arg1 to i64*, !insn.addr !3180
  %4 = call i64**** @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE(i64* %3), !insn.addr !3180
  %5 = call i64 @_ZNSt4pairIPPKvbEC1IRS2_bLb1EEEOT_OT0_(i64* nonnull %stack_var_-56, i64**** %4, i1* %2), !insn.addr !3181
  %6 = load i64, i64* %stack_var_-56, align 8, !insn.addr !3182
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !3183
  %8 = icmp eq i64 %0, %7, !insn.addr !3183
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3184
  br i1 %8, label %dec_label_pc_cbca, label %dec_label_pc_cbc5, !insn.addr !3184

dec_label_pc_cbc5:                                ; preds = %dec_label_pc_cb5a
  %9 = call i64 @__stack_chk_fail(), !insn.addr !3185
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !3185
  br label %dec_label_pc_cbca, !insn.addr !3185

dec_label_pc_cbca:                                ; preds = %dec_label_pc_cbc5, %dec_label_pc_cb5a
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3186

; uselistorder directives
  uselistorder i64* %stack_var_-56, { 1, 0 }
}

define i64 @_ZNSt4pairIPKPKvbEC1IPS1_bLb1EEEOS_IT_T0_E(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_cbd0:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg2), !insn.addr !3187
  %3 = load i64**, i64*** %2, align 8, !insn.addr !3188
  %4 = ptrtoint i64** %3 to i64, !insn.addr !3188
  store i64 %4, i64* %result, align 8, !insn.addr !3189
  %5 = add i64 %0, 8, !insn.addr !3190
  %6 = inttoptr i64 %5 to i64*, !insn.addr !3191
  %7 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %6), !insn.addr !3191
  %8 = bitcast i1* %7 to i8*, !insn.addr !3192
  %9 = load i8, i8* %8, align 1, !insn.addr !3192
  %10 = add i64 %1, 8, !insn.addr !3193
  %11 = inttoptr i64 %10 to i8*, !insn.addr !3193
  store i8 %9, i8* %11, align 1, !insn.addr !3193
  ret i64 %1, !insn.addr !3194

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64 @_ZSt9make_pairIPPKvbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS4_INS5_IT0_E4typeEE6__typeEEOS6_OSB_(i64*** %arg1, i1* %arg2) local_unnamed_addr {
dec_label_pc_cc17:
  %rax.0.reg2mem = alloca i64, !insn.addr !3195
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3196
  %1 = bitcast i1* %arg2 to i64*
  %2 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %1), !insn.addr !3197
  %3 = bitcast i64*** %arg1 to i64*, !insn.addr !3198
  %4 = call i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %3), !insn.addr !3198
  %5 = call i64 @_ZNSt4pairIPPKvbEC1IS2_bLb1EEEOT_OT0_(i64* nonnull %stack_var_-56, i64*** %4, i1* %2), !insn.addr !3199
  %6 = load i64, i64* %stack_var_-56, align 8, !insn.addr !3200
  %7 = call i64 @__readfsqword(i64 40), !insn.addr !3201
  %8 = icmp eq i64 %0, %7, !insn.addr !3201
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3202
  br i1 %8, label %dec_label_pc_cc87, label %dec_label_pc_cc82, !insn.addr !3202

dec_label_pc_cc82:                                ; preds = %dec_label_pc_cc17
  %9 = call i64 @__stack_chk_fail(), !insn.addr !3203
  store i64 %9, i64* %rax.0.reg2mem, !insn.addr !3203
  br label %dec_label_pc_cc87, !insn.addr !3203

dec_label_pc_cc87:                                ; preds = %dec_label_pc_cc82, %dec_label_pc_cc17
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3204

; uselistorder directives
  uselistorder i64* %stack_var_-56, { 1, 0 }
}

define i1 @_ZN4llvm20shouldReverseIterateIPvEEbv() local_unnamed_addr {
dec_label_pc_cc8d:
  ret i1 false, !insn.addr !3205
}

define i1 @_ZN4llvm3isaINS_8FunctionEPNS_5ValueEEEbRKT0_(i64** %arg1) local_unnamed_addr {
dec_label_pc_cc9c:
  %0 = call i64 @_ZN4llvm8CastInfoINS_8FunctionEKPNS_5ValueEvE10isPossibleERS4_(i64** %arg1), !insn.addr !3206
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !3207
  ret i1 %2, !insn.addr !3207
}

define i64 @_ZN4llvm8CastInfoINS_8FunctionEPNS_5ValueEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_ccba:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3208
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_8FunctionEPNS_5ValueES3_E4doitEPKS2_(i64* %0), !insn.addr !3208
  ret i64 %1, !insn.addr !3209
}

define i1 @_ZN4llvm3isaINS_8CallInstEPKNS_5ValueEEEbRKT0_(i64** %arg1) local_unnamed_addr {
dec_label_pc_ccdb:
  %0 = call i64 @_ZN4llvm8CastInfoINS_8CallInstEKPKNS_5ValueEvE10isPossibleERS5_(i64** %arg1), !insn.addr !3210
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !3211
  ret i1 %2, !insn.addr !3211
}

define i64 @_ZN4llvm8CastInfoINS_8CallInstEPKNS_5ValueEvE6doCastERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_ccf9:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3212
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_8CallInstEPKNS_5ValueES4_E4doitES4_(i64* %0), !insn.addr !3212
  ret i64 %1, !insn.addr !3213
}

define i1 @_ZN4llvm3isaINS_13IntrinsicInstEPKNS_5ValueEEEbRKT0_(i64** %arg1) local_unnamed_addr {
dec_label_pc_cd1a:
  %0 = call i64 @_ZN4llvm8CastInfoINS_13IntrinsicInstEKPKNS_5ValueEvE10isPossibleERS5_(i64** %arg1), !insn.addr !3214
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !3215
  ret i1 %2, !insn.addr !3215
}

define i64 @_ZN4llvm8CastInfoINS_13IntrinsicInstEPKNS_5ValueEvE6doCastERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_cd38:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3216
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_13IntrinsicInstEPKNS_5ValueES4_E4doitES4_(i64* %0), !insn.addr !3216
  ret i64 %1, !insn.addr !3217
}

define i64 @_ZN4llvm15SmallPtrSetImplIPvECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_cd5a:
  %0 = call i64 @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj(i64* %result, i64** %arg2, i32 %arg3), !insn.addr !3218
  ret i64 %0, !insn.addr !3219
}

define i64 @_ZN4llvm11SmallPtrSetIPvLj2EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_cd8a:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 24, !insn.addr !3220
  %2 = inttoptr i64 %1 to i64**, !insn.addr !3221
  %3 = call i64 @_ZN4llvm15SmallPtrSetImplIPvECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %2, i32 2), !insn.addr !3221
  ret i64 %3, !insn.addr !3222
}

define i64 @_ZN4llvm15SmallPtrSetImplIPNS_11AnalysisKeyEECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_cdba:
  %0 = call i64 @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj(i64* %result, i64** %arg2, i32 %arg3), !insn.addr !3223
  ret i64 %0, !insn.addr !3224

; uselistorder directives
  uselistorder i64 (i64*, i64**, i32)* @_ZN4llvm19SmallPtrSetImplBaseC1EPPKvj, { 1, 0 }
}

define i64 @_ZN4llvm11SmallPtrSetIPNS_11AnalysisKeyELj2EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_cdea:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 24, !insn.addr !3225
  %2 = inttoptr i64 %1 to i64**, !insn.addr !3226
  %3 = call i64 @_ZN4llvm15SmallPtrSetImplIPNS_11AnalysisKeyEECI1NS_19SmallPtrSetImplBaseEEPPKvj(i64* %result, i64** %2, i32 2), !insn.addr !3226
  ret i64 %3, !insn.addr !3227

; uselistorder directives
  uselistorder i32 2, { 3, 4, 5, 1, 0, 2 }
}

define i64 @_ZN4llvm15SmallPtrSetImplIPvE6insertES1_(i64* %this, i64* %result, i64* %arg3) local_unnamed_addr {
dec_label_pc_ce1a:
  %0 = ptrtoint i64* %arg3 to i64
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-64 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !3228
  %2 = call i64 @_ZN4llvm21PointerLikeTypeTraitsIPvE16getAsVoidPointerES1_(i64* %arg3), !insn.addr !3229
  %3 = inttoptr i64 %2 to i64*, !insn.addr !3230
  %4 = call i64 @_ZN4llvm19SmallPtrSetImplBase10insert_impEPKv(i64* %result, i64* %3), !insn.addr !3230
  %5 = inttoptr i64 %4 to i64**, !insn.addr !3231
  store i64 %0, i64* %stack_var_-64, align 8, !insn.addr !3232
  %6 = call i64 @_ZNK4llvm15SmallPtrSetImplIPvE12makeIteratorEPKPKv(i64* %result, i64** %5), !insn.addr !3233
  store i64 %6, i64* %stack_var_-56, align 8, !insn.addr !3234
  %7 = bitcast i64* %stack_var_-64 to i1**, !insn.addr !3235
  %8 = call i64 @_ZSt9make_pairIN4llvm19SmallPtrSetIteratorIPvEERbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS6_INS7_IT0_E4typeEE6__typeEEOS8_OSD_(i64* %this, i64* nonnull %stack_var_-56, i1** nonnull %7), !insn.addr !3235
  %9 = call i64 @__readfsqword(i64 40), !insn.addr !3236
  %10 = icmp eq i64 %1, %9, !insn.addr !3236
  br i1 %10, label %dec_label_pc_ceb0, label %dec_label_pc_ceab, !insn.addr !3237

dec_label_pc_ceab:                                ; preds = %dec_label_pc_ce1a
  %11 = call i64 @__stack_chk_fail(), !insn.addr !3238
  br label %dec_label_pc_ceb0, !insn.addr !3238

dec_label_pc_ceb0:                                ; preds = %dec_label_pc_ceab, %dec_label_pc_ce1a
  %12 = ptrtoint i64* %this to i64
  ret i64 %12, !insn.addr !3239

; uselistorder directives
  uselistorder i64* %this, { 1, 0 }
}

define i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_ceba:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = icmp eq i64* %arg1, %arg2, !insn.addr !3240
  %2 = icmp eq i1 %1, false, !insn.addr !3241
  %3 = zext i1 %2 to i64, !insn.addr !3241
  %4 = and i64 %0, -256, !insn.addr !3241
  %5 = or i64 %4, %3, !insn.addr !3241
  ret i64 %5, !insn.addr !3242
}

define i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* %result) local_unnamed_addr {
dec_label_pc_cee0:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEEE7getNextEv(i64* %result), !insn.addr !3243
  store i64 %1, i64* %result, align 8, !insn.addr !3244
  ret i64 %0, !insn.addr !3245
}

define i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_cf0c:
  %rdi.0.reg2mem = alloca i64, !insn.addr !3246
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE15isKnownSentinelEv(i64* %result), !insn.addr !3247
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !3248
  %4 = icmp eq i1 %3, false, !insn.addr !3249
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !3249
  br i1 %4, label %dec_label_pc_cf5a, label %dec_label_pc_cf32, !insn.addr !3249

dec_label_pc_cf32:                                ; preds = %dec_label_pc_cf0c
  %5 = call i64 @__assert_fail(i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64 ptrtoint ([47 x i8]* @global_var_5d24 to i64), i64 168, i64 ptrtoint ([307 x i8]* @global_var_5dc4 to i64)), !insn.addr !3250
  store i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64* %rdi.0.reg2mem, !insn.addr !3250
  br label %dec_label_pc_cf5a, !insn.addr !3250

dec_label_pc_cf5a:                                ; preds = %dec_label_pc_cf32, %dec_label_pc_cf0c
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %6 = inttoptr i64 %rdi.0.reload to i64*, !insn.addr !3251
  %7 = call i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_8FunctionELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %6), !insn.addr !3251
  ret i64 %7, !insn.addr !3252
}

define i64 @_ZN4llvm12simple_ilistINS_8FunctionEJEE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_cf6c:
  %rax.0.reg2mem = alloca i64, !insn.addr !3253
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3254
  %1 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE(i64* nonnull %stack_var_-24, i64* %result), !insn.addr !3255
  %2 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* nonnull %stack_var_-24), !insn.addr !3256
  %3 = inttoptr i64 %2 to i64*, !insn.addr !3257
  %4 = load i64, i64* %3, align 8, !insn.addr !3257
  %5 = call i64 @__readfsqword(i64 40), !insn.addr !3258
  %6 = icmp eq i64 %0, %5, !insn.addr !3258
  store i64 %4, i64* %rax.0.reg2mem, !insn.addr !3259
  br i1 %6, label %dec_label_pc_cfc1, label %dec_label_pc_cfbc, !insn.addr !3259

dec_label_pc_cfbc:                                ; preds = %dec_label_pc_cf6c
  %7 = call i64 @__stack_chk_fail(), !insn.addr !3260
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !3260
  br label %dec_label_pc_cfc1, !insn.addr !3260

dec_label_pc_cfc1:                                ; preds = %dec_label_pc_cfbc, %dec_label_pc_cf6c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3261

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEppEv, { 1, 0 }
}

define i64 @_ZN4llvm12simple_ilistINS_8FunctionEJEE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_cfc4:
  %rax.0.reg2mem = alloca i64, !insn.addr !3262
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3263
  %1 = call i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE(i64* nonnull %stack_var_-24, i64* %result), !insn.addr !3264
  %2 = load i64, i64* %stack_var_-24, align 8, !insn.addr !3265
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !3266
  %4 = icmp eq i64 %0, %3, !insn.addr !3266
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !3267
  br i1 %4, label %dec_label_pc_d00e, label %dec_label_pc_d009, !insn.addr !3267

dec_label_pc_d009:                                ; preds = %dec_label_pc_cfc4
  %5 = call i64 @__stack_chk_fail(), !insn.addr !3268
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !3268
  br label %dec_label_pc_d00e, !insn.addr !3268

dec_label_pc_d00e:                                ; preds = %dec_label_pc_d009, %dec_label_pc_cfc4
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3269

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE, { 1, 0 }
}

define i1 @_ZSteqIcSt11char_traitsIcESaIcEEbRKNSt7__cxx1112basic_stringIT_T0_T1_EESA_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_d010:
  %storemerge.reg2mem = alloca i1, !insn.addr !3270
  %0 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv(i64* %arg1), !insn.addr !3271
  %1 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv(i64* %arg2), !insn.addr !3272
  %2 = icmp eq i64 %0, %1, !insn.addr !3273
  %3 = icmp eq i1 %2, false, !insn.addr !3274
  br i1 %3, label %dec_label_pc_d08a, label %dec_label_pc_d047, !insn.addr !3274

dec_label_pc_d047:                                ; preds = %dec_label_pc_d010
  %4 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv(i64* %arg1), !insn.addr !3275
  %5 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4dataEv(i64* %arg2), !insn.addr !3276
  %6 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4dataEv(i64* %arg1), !insn.addr !3277
  %7 = inttoptr i64 %6 to i8*, !insn.addr !3278
  %8 = inttoptr i64 %5 to i8*, !insn.addr !3278
  %9 = call i64 @_ZNSt11char_traitsIcE7compareEPKcS2_m(i8* %7, i8* %8, i64 %4), !insn.addr !3278
  %10 = trunc i64 %9 to i32, !insn.addr !3279
  %11 = icmp eq i32 %10, 0, !insn.addr !3279
  %12 = icmp eq i1 %11, false, !insn.addr !3280
  store i1 true, i1* %storemerge.reg2mem, !insn.addr !3280
  br i1 %12, label %dec_label_pc_d08a, label %dec_label_pc_d08f, !insn.addr !3280

dec_label_pc_d08a:                                ; preds = %dec_label_pc_d047, %dec_label_pc_d010
  store i1 false, i1* %storemerge.reg2mem, !insn.addr !3281
  br label %dec_label_pc_d08f, !insn.addr !3281

dec_label_pc_d08f:                                ; preds = %dec_label_pc_d047, %dec_label_pc_d08a
  %storemerge.reload = load i1, i1* %storemerge.reg2mem
  ret i1 %storemerge.reload, !insn.addr !3282

; uselistorder directives
  uselistorder i1* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 (i64*)* @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4dataEv, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv, { 2, 1, 0 }
  uselistorder label %dec_label_pc_d08f, { 1, 0 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE9push_backERKSE_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_d098:
  %0 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE28reserveForParamAndGetAddressERKSE_m(i64* %result, i64* %arg2, i64 1), !insn.addr !3283
  %1 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !3284
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3285
  %3 = call i64 @_ZnwmPv(i64 32, i64* %2), !insn.addr !3285
  %4 = inttoptr i64 %3 to i64*, !insn.addr !3286
  %5 = inttoptr i64 %0 to i64*, !insn.addr !3286
  %6 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1ERKSD_(i64* %4, i64* %5), !insn.addr !3286
  %7 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !3287
  %8 = add i64 %7, 1, !insn.addr !3288
  %9 = call i64 @_ZN4llvm15SmallVectorBaseIjE8set_sizeEm(i64* %result, i64 %8), !insn.addr !3289
  ret i64 %9, !insn.addr !3290
}

define i64 @_ZN4llvm8CastInfoINS_11GlobalAliasEPNS_5ValueEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_d11a:
  ret i64 0, !insn.addr !3291
}

define i64 @_ZN4llvm8CastInfoINS_11GlobalAliasEPNS_5ValueEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d129:
  %storemerge.reg2mem = alloca i64, !insn.addr !3292
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_11GlobalAliasEPNS_5ValueEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3293
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3294
  br i1 %2, label %dec_label_pc_d153, label %dec_label_pc_d14c, !insn.addr !3295

dec_label_pc_d14c:                                ; preds = %dec_label_pc_d129
  %3 = call i64 @_ZN4llvm8CastInfoINS_11GlobalAliasEPNS_5ValueEvE10castFailedEv(), !insn.addr !3296
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3297
  br label %dec_label_pc_d160, !insn.addr !3297

dec_label_pc_d153:                                ; preds = %dec_label_pc_d129
  %4 = call i64 @_ZN4llvm8CastInfoINS_11GlobalAliasEPNS_5ValueEvE6doCastERKS3_(i64** %arg1), !insn.addr !3298
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3299
  br label %dec_label_pc_d160, !insn.addr !3299

dec_label_pc_d160:                                ; preds = %dec_label_pc_d153, %dec_label_pc_d14c
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3300

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64 ()* @_ZN4llvm8CastInfoINS_11GlobalAliasEPNS_5ValueEvE10castFailedEv, { 1, 0 }
}

define i1 @_ZNK4llvm9StringRef12getAsIntegerIlEEbjRT_(i64* %result, i32 %arg2, i32* %arg3) local_unnamed_addr {
dec_label_pc_d162:
  %rax.0.reg2mem = alloca i64, !insn.addr !3301
  %storemerge.reg2mem = alloca i64, !insn.addr !3301
  %0 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !3302
  %2 = add i64 %0, 8, !insn.addr !3303
  %3 = inttoptr i64 %2 to i64*, !insn.addr !3303
  %4 = load i64, i64* %3, align 8, !insn.addr !3303
  %5 = call i64 @_ZN4llvm18getAsSignedIntegerENS_9StringRefEjRx(i64* %result, i64 %4, i32 %arg2, i64* nonnull %stack_var_-24), !insn.addr !3304
  %6 = trunc i64 %5 to i8, !insn.addr !3305
  %7 = icmp eq i8 %6, 0, !insn.addr !3305
  store i64 1, i64* %storemerge.reg2mem, !insn.addr !3306
  br i1 %7, label %dec_label_pc_d1c0, label %dec_label_pc_d1d0, !insn.addr !3306

dec_label_pc_d1c0:                                ; preds = %dec_label_pc_d162
  %8 = load i64, i64* %stack_var_-24, align 8, !insn.addr !3307
  %9 = bitcast i32* %arg3 to i64*
  store i64 %8, i64* %9, align 8, !insn.addr !3308
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !3309
  br label %dec_label_pc_d1d0, !insn.addr !3309

dec_label_pc_d1d0:                                ; preds = %dec_label_pc_d162, %dec_label_pc_d1c0
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %10 = call i64 @__readfsqword(i64 40), !insn.addr !3310
  %11 = icmp eq i64 %1, %10, !insn.addr !3310
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !3311
  br i1 %11, label %dec_label_pc_d1e4, label %dec_label_pc_d1df, !insn.addr !3311

dec_label_pc_d1df:                                ; preds = %dec_label_pc_d1d0
  %12 = call i64 @__stack_chk_fail(), !insn.addr !3312
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !3312
  br label %dec_label_pc_d1e4, !insn.addr !3312

dec_label_pc_d1e4:                                ; preds = %dec_label_pc_d1df, %dec_label_pc_d1d0
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %13 = urem i64 %rax.0.reload, 2
  %14 = icmp ne i64 %13, 0, !insn.addr !3313
  ret i1 %14, !insn.addr !3313

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_d1d0, { 1, 0 }
}

define i64 @_ZN4llvm8CastInfoINS_11IntegerTypeEPNS_4TypeEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d1e6:
  %storemerge.reg2mem = alloca i64, !insn.addr !3314
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_11IntegerTypeEPNS_4TypeEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3315
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3316
  br i1 %2, label %dec_label_pc_d210, label %dec_label_pc_d209, !insn.addr !3317

dec_label_pc_d209:                                ; preds = %dec_label_pc_d1e6
  %3 = call i64 @_ZN4llvm8CastInfoINS_11IntegerTypeEPNS_4TypeEvE10castFailedEv(), !insn.addr !3318
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3319
  br label %dec_label_pc_d21d, !insn.addr !3319

dec_label_pc_d210:                                ; preds = %dec_label_pc_d1e6
  %4 = call i64 @_ZN4llvm8CastInfoINS_11IntegerTypeEPNS_4TypeEvE6doCastERKS3_(i64** %arg1), !insn.addr !3320
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3321
  br label %dec_label_pc_d21d, !insn.addr !3321

dec_label_pc_d21d:                                ; preds = %dec_label_pc_d210, %dec_label_pc_d209
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3322

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i1 @_ZN4llvm3isaINS_16DbgInfoIntrinsicEPNS_8CallBaseEEEbRKT0_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d21f:
  %0 = call i64 @_ZN4llvm8CastInfoINS_16DbgInfoIntrinsicEKPNS_8CallBaseEvE10isPossibleERS4_(i64** %arg1), !insn.addr !3323
  %1 = urem i64 %0, 2
  %2 = icmp ne i64 %1, 0, !insn.addr !3324
  ret i1 %2, !insn.addr !3324
}

define i64 @_ZN4llvm11SmallVectorIPNS_11InstructionELj32EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_d23e:
  %0 = call i64 @_ZN4llvm15SmallVectorImplIPNS_11InstructionEEC1Ej(i64* %result, i32 32), !insn.addr !3325
  ret i64 %0, !insn.addr !3326

; uselistorder directives
  uselistorder i32 32, { 2, 1, 3, 4, 0 }
}

define i64 @_ZN4llvm11SmallVectorIPNS_11InstructionELj32EED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_d262:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE3endEv(i64* %result), !insn.addr !3327
  %1 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE5beginEv(i64* %result), !insn.addr !3328
  %2 = inttoptr i64 %1 to i64**, !insn.addr !3329
  %3 = inttoptr i64 %0 to i64**, !insn.addr !3329
  %4 = call i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE13destroy_rangeEPS2_S4_(i64** %2, i64** %3), !insn.addr !3329
  %5 = call i64 @_ZN4llvm15SmallVectorImplIPNS_11InstructionEED1Ev(i64* %result), !insn.addr !3330
  ret i64 %5, !insn.addr !3331
}

define i64 @_ZN4llvmneERKNS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEES7_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_d2ac:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = icmp eq i64* %arg1, %arg2, !insn.addr !3332
  %2 = icmp eq i1 %1, false, !insn.addr !3333
  %3 = zext i1 %2 to i64, !insn.addr !3333
  %4 = and i64 %0, -256, !insn.addr !3333
  %5 = or i64 %4, %3, !insn.addr !3333
  ret i64 %5, !insn.addr !3334
}

define i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* %result) local_unnamed_addr {
dec_label_pc_d2d2:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE7getNextEv(i64* %result), !insn.addr !3335
  store i64 %1, i64* %result, align 8, !insn.addr !3336
  ret i64 %0, !insn.addr !3337
}

define i64 @_ZNK4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_d2fe:
  %rdi.0.reg2mem = alloca i64, !insn.addr !3338
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE15isKnownSentinelEv(i64* %result), !insn.addr !3339
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !3340
  %4 = icmp eq i1 %3, false, !insn.addr !3341
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !3341
  br i1 %4, label %dec_label_pc_d34c, label %dec_label_pc_d324, !insn.addr !3341

dec_label_pc_d324:                                ; preds = %dec_label_pc_d2fe
  %5 = call i64 @__assert_fail(i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64 ptrtoint ([47 x i8]* @global_var_5d24 to i64), i64 168, i64 ptrtoint ([311 x i8]* @global_var_5efc to i64)), !insn.addr !3342
  store i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64* %rdi.0.reg2mem, !insn.addr !3342
  br label %dec_label_pc_d34c, !insn.addr !3342

dec_label_pc_d34c:                                ; preds = %dec_label_pc_d324, %dec_label_pc_d2fe
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %6 = inttoptr i64 %rdi.0.reload to i64*, !insn.addr !3343
  %7 = call i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %6), !insn.addr !3343
  ret i64 %7, !insn.addr !3344
}

define i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEppEv(i64* %result) local_unnamed_addr {
dec_label_pc_d35e:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEE7getNextEv(i64* %result), !insn.addr !3345
  store i64 %1, i64* %result, align 8, !insn.addr !3346
  %2 = add i64 %0, 8, !insn.addr !3347
  %3 = inttoptr i64 %2 to i8*, !insn.addr !3347
  store i8 0, i8* %3, align 1, !insn.addr !3347
  %4 = add i64 %0, 9, !insn.addr !3348
  %5 = inttoptr i64 %4 to i8*, !insn.addr !3348
  store i8 0, i8* %5, align 1, !insn.addr !3348
  ret i64 %0, !insn.addr !3349
}

define i64 @_ZNK4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_d39a:
  %rdi.0.reg2mem = alloca i64, !insn.addr !3350
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0ENS_10BasicBlockEEELb0EE15isKnownSentinelEv(i64* %result), !insn.addr !3351
  %2 = trunc i64 %1 to i8
  %3 = icmp eq i8 %2, 1, !insn.addr !3352
  %4 = icmp eq i1 %3, false, !insn.addr !3353
  store i64 %0, i64* %rdi.0.reg2mem, !insn.addr !3353
  br i1 %4, label %dec_label_pc_d3e8, label %dec_label_pc_d3c0, !insn.addr !3353

dec_label_pc_d3c0:                                ; preds = %dec_label_pc_d39a
  %5 = call i64 @__assert_fail(i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64 ptrtoint ([47 x i8]* @global_var_5d24 to i64), i64 322, i64 ptrtoint ([338 x i8]* @global_var_6034 to i64)), !insn.addr !3354
  store i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), i64* %rdi.0.reg2mem, !insn.addr !3354
  br label %dec_label_pc_d3e8, !insn.addr !3354

dec_label_pc_d3e8:                                ; preds = %dec_label_pc_d3c0, %dec_label_pc_d39a
  %rdi.0.reload = load i64, i64* %rdi.0.reg2mem
  %6 = inttoptr i64 %rdi.0.reload to i64*, !insn.addr !3355
  %7 = call i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEE11getValuePtrEPNS_15ilist_node_implIS5_EE(i64* %6), !insn.addr !3355
  ret i64 %7, !insn.addr !3356

; uselistorder directives
  uselistorder i64 ptrtoint ([28 x i8]* @global_var_5d53 to i64), { 0, 4, 1, 5, 2, 6, 3, 7 }
}

define i64 @_ZN4llvm15IRBuilderFolderC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_d3fa:
  %0 = ptrtoint i64* %result to i64
  %1 = load i64, i64* inttoptr (i64 54285 to i64*), align 8, !insn.addr !3357
  %2 = add i64 %1, 16, !insn.addr !3358
  store i64 %2, i64* %result, align 8, !insn.addr !3359
  ret i64 %0, !insn.addr !3360
}

define i64 @_ZN4llvm14ConstantFolderC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_d41c:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm15IRBuilderFolderC1Ev(i64* %result), !insn.addr !3361
  %2 = load i64, i64* inttoptr (i64 54335 to i64*), align 8, !insn.addr !3362
  %3 = add i64 %2, 16, !insn.addr !3363
  store i64 %3, i64* %result, align 8, !insn.addr !3364
  ret i64 %0, !insn.addr !3365
}

define i64 @_ZN4llvm9IRBuilderINS_14ConstantFolderENS_24IRBuilderDefaultInserterEEC1EPNS_11InstructionEPNS_6MDNodeENS_8ArrayRefINS_17OperandBundleDefTIPNS_5ValueEEEEE(i64* %this, i64* %result, i64* %arg3, i64* %arg4, i64 %arg5) local_unnamed_addr {
dec_label_pc_d44e:
  %0 = ptrtoint i64* %this to i64
  %1 = add i64 %0, 144, !insn.addr !3366
  %2 = add i64 %0, 136, !insn.addr !3367
  %3 = call i64 @_ZNK4llvm5Value10getContextEv(i64* %result), !insn.addr !3368
  %4 = inttoptr i64 %3 to i64*, !insn.addr !3369
  %5 = inttoptr i64 %2 to i64*, !insn.addr !3369
  %6 = inttoptr i64 %1 to i64*, !insn.addr !3369
  %7 = call i64 @_ZN4llvm13IRBuilderBaseC1ERNS_11LLVMContextERKNS_15IRBuilderFolderERKNS_24IRBuilderDefaultInserterEPNS_6MDNodeENS_8ArrayRefINS_17OperandBundleDefTIPNS_5ValueEEEEE(i64* %this, i64* %4, i64* %5, i64* %6, i64* %arg3, i64* %arg4, i64 %arg5), !insn.addr !3369
  %8 = call i64 @_ZN4llvm14ConstantFolderC1Ev(i64* %5), !insn.addr !3370
  %9 = call i64 @_ZN4llvm24IRBuilderDefaultInserterC1Ev(i64* %6), !insn.addr !3371
  %10 = call i64 @_ZN4llvm13IRBuilderBase14SetInsertPointEPNS_11InstructionE(i64* %this, i64* %result), !insn.addr !3372
  ret i64 %10, !insn.addr !3373
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE9push_backES2_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_d508:
  %0 = ptrtoint i64* %arg2 to i64
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-56, align 8, !insn.addr !3374
  %1 = bitcast i64* %stack_var_-56 to i64**, !insn.addr !3375
  %2 = call i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE28reserveForParamAndGetAddressERS2_m(i64* %result, i64** nonnull %1, i64 1), !insn.addr !3375
  %3 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE3endEv(i64* %result), !insn.addr !3376
  %4 = inttoptr i64 %2 to i64*, !insn.addr !3377
  %5 = load i64, i64* %4, align 8, !insn.addr !3377
  %6 = inttoptr i64 %3 to i64*, !insn.addr !3378
  store i64 %5, i64* %6, align 8, !insn.addr !3378
  %7 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !3379
  %8 = add i64 %7, 1, !insn.addr !3380
  %9 = call i64 @_ZN4llvm15SmallVectorBaseIjE8set_sizeEm(i64* %result, i64 %8), !insn.addr !3381
  ret i64 %9, !insn.addr !3382

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE3endEv, { 2, 1, 0 }
}

define i64 @_ZN4llvm8CastInfoINS_8CallBaseEPNS_11InstructionEvE16doCastIfPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d575:
  %storemerge.reg2mem = alloca i64, !insn.addr !3383
  %0 = call i64 @_ZN4llvm14CastIsPossibleINS_8CallBaseEPNS_11InstructionEvE10isPossibleERKS3_(i64** %arg1), !insn.addr !3384
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !3385
  br i1 %2, label %dec_label_pc_d59f, label %dec_label_pc_d598, !insn.addr !3386

dec_label_pc_d598:                                ; preds = %dec_label_pc_d575
  %3 = call i64 @_ZN4llvm8CastInfoINS_8CallBaseEPNS_11InstructionEvE10castFailedEv(), !insn.addr !3387
  store i64 %3, i64* %storemerge.reg2mem, !insn.addr !3388
  br label %dec_label_pc_d5ac, !insn.addr !3388

dec_label_pc_d59f:                                ; preds = %dec_label_pc_d575
  %4 = call i64 @_ZN4llvm8CastInfoINS_8CallBaseEPNS_11InstructionEvE6doCastERKS3_(i64** %arg1), !insn.addr !3389
  store i64 %4, i64* %storemerge.reg2mem, !insn.addr !3390
  br label %dec_label_pc_d5ac, !insn.addr !3390

dec_label_pc_d5ac:                                ; preds = %dec_label_pc_d59f, %dec_label_pc_d598
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !3391

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_d5ae:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !3392
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_d5c4:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE5beginEv(i64* %result), !insn.addr !3393
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !3394
  %2 = mul i64 %1, 8, !insn.addr !3395
  %3 = add i64 %2, %0, !insn.addr !3396
  ret i64 %3, !insn.addr !3397
}

define i64 @_ZNSt15__new_allocatorIcED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_d5fe:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !3398
}

define i64 @_ZZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tagEN6_GuardC1EPS4_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_d60e:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !3399
  ret i64 %1, !insn.addr !3400
}

define i64 @_ZZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tagEN6_GuardD1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_d62c:
  %rax.0.reg2mem = alloca i64, !insn.addr !3401
  %0 = ptrtoint i64* %result to i64
  %1 = icmp eq i64* %result, null, !insn.addr !3402
  store i64 %0, i64* %rax.0.reg2mem, !insn.addr !3403
  br i1 %1, label %dec_label_pc_d657, label %dec_label_pc_d648, !insn.addr !3403

dec_label_pc_d648:                                ; preds = %dec_label_pc_d62c
  %2 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv(i64* nonnull %result), !insn.addr !3404
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !3404
  br label %dec_label_pc_d657, !insn.addr !3404

dec_label_pc_d657:                                ; preds = %dec_label_pc_d648, %dec_label_pc_d62c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3405
}

define void @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tag(i8* %arg1, i8* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_d65a:
  %.pre-phi.reg2mem = alloca i64*, !insn.addr !3406
  %stack_var_-64 = alloca i64, align 8
  %stack_var_-56 = alloca i8*, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3407
  store i8* %arg2, i8** %stack_var_-56, align 8, !insn.addr !3408
  %1 = ptrtoint i8* %arg2 to i64, !insn.addr !3409
  %2 = sub i64 %arg3, %1, !insn.addr !3410
  store i64 %2, i64* %stack_var_-64, align 8, !insn.addr !3411
  %3 = icmp ult i64 %2, 16
  br i1 %3, label %dec_label_pc_d65a.dec_label_pc_d701_crit_edge, label %dec_label_pc_d6b9, !insn.addr !3412

dec_label_pc_d65a.dec_label_pc_d701_crit_edge:    ; preds = %dec_label_pc_d65a
  %.pre = bitcast i8* %arg1 to i64*
  store i64* %.pre, i64** %.pre-phi.reg2mem
  br label %dec_label_pc_d701

dec_label_pc_d6b9:                                ; preds = %dec_label_pc_d65a
  %4 = ptrtoint i64* %stack_var_-64 to i64, !insn.addr !3413
  %5 = bitcast i8* %arg1 to i64*
  %6 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(i64* %5, i64* nonnull %stack_var_-64, i64* null, i64 %4), !insn.addr !3414
  %7 = inttoptr i64 %6 to i8*, !insn.addr !3415
  %8 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc(i64* %5, i8* %7), !insn.addr !3415
  %9 = load i64, i64* %stack_var_-64, align 8, !insn.addr !3416
  %10 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEm(i64* %5, i64 %9), !insn.addr !3417
  store i64* %5, i64** %.pre-phi.reg2mem, !insn.addr !3418
  br label %dec_label_pc_d701, !insn.addr !3418

dec_label_pc_d701:                                ; preds = %dec_label_pc_d65a.dec_label_pc_d701_crit_edge, %dec_label_pc_d6b9
  %.pre-phi.reload = load i64*, i64** %.pre-phi.reg2mem
  %11 = bitcast i8** %stack_var_-56 to i64*, !insn.addr !3419
  %12 = call i64 @_ZZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tagEN6_GuardC1EPS4_(i64* nonnull %11, i64* %.pre-phi.reload), !insn.addr !3419
  %13 = call i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv(i64* %.pre-phi.reload), !insn.addr !3420
  %14 = inttoptr i64 %13 to i8*, !insn.addr !3421
  %15 = inttoptr i64 %arg3 to i8*, !insn.addr !3421
  %16 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_S_copy_charsEPcPKcS7_(i8* %14, i8* %arg2, i8* %15), !insn.addr !3421
  store i8* null, i8** %stack_var_-56, align 8, !insn.addr !3422
  %17 = load i64, i64* %stack_var_-64, align 8, !insn.addr !3423
  %18 = call i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEm(i64* %.pre-phi.reload, i64 %17), !insn.addr !3424
  %19 = call i64 @_ZZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tagEN6_GuardD1Ev(i64* nonnull %11), !insn.addr !3425
  %20 = call i64 @__readfsqword(i64 40), !insn.addr !3426
  %21 = icmp eq i64 %0, %20, !insn.addr !3426
  br i1 %21, label %dec_label_pc_d771, label %dec_label_pc_d76c, !insn.addr !3427

dec_label_pc_d76c:                                ; preds = %dec_label_pc_d701
  %22 = call i64 @__stack_chk_fail(), !insn.addr !3428
  br label %dec_label_pc_d771, !insn.addr !3428

dec_label_pc_d771:                                ; preds = %dec_label_pc_d76c, %dec_label_pc_d701
  ret void, !insn.addr !3429

; uselistorder directives
  uselistorder i8** %stack_var_-56, { 1, 2, 0 }
  uselistorder i64* %stack_var_-64, { 1, 2, 0, 3, 4 }
  uselistorder i8* %arg1, { 1, 0 }
  uselistorder label %dec_label_pc_d701, { 1, 0 }
}

define i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_d773:
  %0 = bitcast i64* %arg1 to i1*, !insn.addr !3430
  ret i1* %0, !insn.addr !3430
}

define i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_d785:
  ret i64* %arg1, !insn.addr !3431
}

define i64 @_ZN4llvm8CastInfoINS_11InstructionEKPKNS_5ValueEvE10isPossibleERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d797:
  %rax.0.reg2mem = alloca i64, !insn.addr !3432
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3433
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !3434
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3435
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3436
  %3 = call i64 @_ZN4llvm14CastIsPossibleINS_11InstructionEPKNS_5ValueEvE10isPossibleERKS4_(i64** nonnull %2), !insn.addr !3436
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3437
  %5 = icmp eq i64 %0, %4, !insn.addr !3437
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3438
  br i1 %5, label %dec_label_pc_d7e6, label %dec_label_pc_d7e1, !insn.addr !3438

dec_label_pc_d7e1:                                ; preds = %dec_label_pc_d797
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3439
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3439
  br label %dec_label_pc_d7e6, !insn.addr !3439

dec_label_pc_d7e6:                                ; preds = %dec_label_pc_d7e1, %dec_label_pc_d797
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3440

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm14CastIsPossibleINS_11InstructionEPKNS_5ValueEvE10isPossibleERKS4_, { 1, 0 }
}

define i64 @_ZN4llvm16cast_convert_valINS_11IntegerTypeEPNS_4TypeES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_d7e8:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3441
}

define i64 @_ZN4llvm21PointerLikeTypeTraitsIPNS_8MetadataEE16getAsVoidPointerES2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_d7fa:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3442
}

define i64 @_ZN4llvm14PointerIntPairIPvLj2EiNS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_18PointerIntPairInfoIS1_Lj2ESA_EEEC1ES1_i(i64* %result, i64* %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_d80c:
  %0 = call i64 @_ZN4llvm6detail13PunnedPointerIPvEC1El(i64* %result, i32 0), !insn.addr !3443
  %1 = call i64 @_ZNR4llvm14PointerIntPairIPvLj2EiNS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_18PointerIntPairInfoIS1_Lj2ESA_EEE16setPointerAndIntES1_i(i64* %result, i64* %arg2, i32 %arg3), !insn.addr !3444
  ret i64 %1, !insn.addr !3445
}

define i64 @_ZN4llvm20pointer_union_detail19PointerUnionMembersINS_12PointerUnionIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_14PointerIntPairIPvLj2EiNS0_22PointerUnionUIntTraitsIJS4_S6_S8_EEENS_18PointerIntPairInfoISB_Lj2ESD_EEEELi3EJEEC1ESG_(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_d84e:
  %0 = ptrtoint i64* %result to i64
  store i64 %arg2, i64* %result, align 8, !insn.addr !3446
  ret i64 %0, !insn.addr !3447
}

define i64* @_ZSt4moveIRN4llvm13TrackingMDRefEEONSt16remove_referenceIT_E4typeEOS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d86c:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3448
  ret i64* %0, !insn.addr !3448
}

define i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE15isKnownSentinelEv(i64* %result) local_unnamed_addr {
dec_label_pc_d87e:
  ret i64 0, !insn.addr !3449
}

define i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_d891:
  %0 = call i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1), !insn.addr !3450
  ret i64 %0, !insn.addr !3451
}

define i64 @_ZN4llvm14CastIsPossibleINS_17DbgVariableRecordEKNS_9DbgRecordEvE10isPossibleERS3_(i64* %arg1) local_unnamed_addr {
dec_label_pc_d8af:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_17DbgVariableRecordEKNS_9DbgRecordES3_E4doitERS3_(i64* %arg1), !insn.addr !3452
  ret i64 %0, !insn.addr !3453
}

define i64 @_ZN4llvm9adl_beginIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl10begin_implcl7forwardIT_Efp_EEEOSA_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d8cd:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3454
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !3454
  %2 = call i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSB_(i64** %1), !insn.addr !3455
  ret i64 %2, !insn.addr !3456
}

define i64 @_ZN4llvm7adl_endIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl8end_implcl7forwardIT_Efp_EEEOSA_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d8f3:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3457
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !3457
  %2 = call i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSB_(i64** %1), !insn.addr !3458
  ret i64 %2, !insn.addr !3459
}

define i64* @_ZSt4moveIRN4llvm14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEONSt16remove_referenceIT_E4typeEOS9_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d919:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3460
  ret i64* %0, !insn.addr !3460
}

define i64 @_ZN4llvm21ilist_iterator_w_bitsINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEELb0ELb0EEC1ERNS_15ilist_node_implIS5_EE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_d92c:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !3461
  %2 = add i64 %1, 8, !insn.addr !3462
  %3 = inttoptr i64 %2 to i8*, !insn.addr !3462
  store i8 0, i8* %3, align 1, !insn.addr !3462
  %4 = add i64 %1, 9, !insn.addr !3463
  %5 = inttoptr i64 %4 to i8*, !insn.addr !3463
  store i8 0, i8* %5, align 1, !insn.addr !3463
  ret i64 %1, !insn.addr !3464

; uselistorder directives
  uselistorder i64 %1, { 1, 0, 2 }
}

define i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_d95a:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !3465
  ret i64 %1, !insn.addr !3466
}

define i64 @_ZNK4llvm14ilist_sentinelINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE5emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_d978:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE7getPrevEv(i64* %result), !insn.addr !3467
  %2 = icmp eq i64 %1, %0, !insn.addr !3468
  %3 = zext i1 %2 to i64, !insn.addr !3469
  %4 = and i64 %1, -256, !insn.addr !3469
  %5 = or i64 %4, %3, !insn.addr !3469
  ret i64 %5, !insn.addr !3470

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64 @_ZN4llvm13simplify_typeIPNS_5ValueEE18getSimplifiedValueERS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d9a5:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !3471
}

define i64 @_ZN4llvm14ValueIsPresentIPNS_5ValueEvE9isPresentERKS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d9b7:
  %0 = ptrtoint i64** %arg1 to i64
  %1 = icmp eq i64** %arg1, null, !insn.addr !3472
  %2 = icmp eq i1 %1, false, !insn.addr !3473
  %3 = zext i1 %2 to i64, !insn.addr !3473
  %4 = and i64 %0, -256, !insn.addr !3473
  %5 = or i64 %4, %3, !insn.addr !3473
  ret i64 %5, !insn.addr !3474
}

define i64 @_ZN4llvm8CastInfoINS_5ValueEKPS1_vE10isPossibleERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_d9d2:
  %rax.0.reg2mem = alloca i64, !insn.addr !3475
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3476
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3477
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3478
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3479
  %3 = call i64 @_ZN4llvm14CastIsPossibleINS_5ValueEPKS1_vE10isPossibleERKS3_(i64** nonnull %2), !insn.addr !3479
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3480
  %5 = icmp eq i64 %0, %4, !insn.addr !3480
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3481
  br i1 %5, label %dec_label_pc_da21, label %dec_label_pc_da1c, !insn.addr !3481

dec_label_pc_da1c:                                ; preds = %dec_label_pc_d9d2
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3482
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3482
  br label %dec_label_pc_da21, !insn.addr !3482

dec_label_pc_da21:                                ; preds = %dec_label_pc_da1c, %dec_label_pc_d9d2
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3483
}

define i64 @_ZN4llvm16cast_convert_valINS_5ValueEPS1_S2_E4doitEPKS1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_da23:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3484
}

define i64 @_ZN4llvm16cast_convert_valINS_11InstructionEPKNS_5ValueES4_E4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_da35:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3485
}

define i64 @_ZN4llvm13simplify_typeIPNS_4TypeEE18getSimplifiedValueERS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_da47:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !3486
}

define i64 @_ZN4llvm14ValueIsPresentIPNS_4TypeEvE9isPresentERKS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_da59:
  %0 = ptrtoint i64** %arg1 to i64
  %1 = icmp eq i64** %arg1, null, !insn.addr !3487
  %2 = icmp eq i1 %1, false, !insn.addr !3488
  %3 = zext i1 %2 to i64, !insn.addr !3488
  %4 = and i64 %0, -256, !insn.addr !3488
  %5 = or i64 %4, %3, !insn.addr !3488
  ret i64 %5, !insn.addr !3489
}

define i64* @_ZN4llvm4User6OpFromILin1ENS_8CallBaseEEERNS_3UseEPKT0_(i64* %arg1) local_unnamed_addr {
dec_label_pc_da74:
  %0 = call i64 @_ZN4llvm21VariadicOperandTraitsINS_8CallBaseEE6op_endEPS1_(i64* %arg1), !insn.addr !3490
  %1 = add i64 %0, -32, !insn.addr !3491
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3492
  ret i64* %2, !insn.addr !3492
}

define i64 @_ZN4llvm14CastIsPossibleINS_8FunctionEPNS_5ValueEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_da96:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_8FunctionEKPNS_5ValueEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3493
  ret i64 %0, !insn.addr !3494
}

define i64 @_ZN4llvm16cast_convert_valINS_9ArrayTypeEPNS_4TypeES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_dab4:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3495
}

define i64 @_ZN4llvm16cast_convert_valINS_10StructTypeEPNS_4TypeES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_dac6:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3496
}

define i64 @_ZN4llvm13simplify_typeIPKNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dad8:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !3497
}

define i64 @_ZN4llvm14ValueIsPresentIPKNS_5ValueEvE9isPresentERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_daea:
  %0 = ptrtoint i64** %arg1 to i64
  %1 = icmp eq i64** %arg1, null, !insn.addr !3498
  %2 = icmp eq i1 %1, false, !insn.addr !3499
  %3 = zext i1 %2 to i64, !insn.addr !3499
  %4 = and i64 %0, -256, !insn.addr !3499
  %5 = or i64 %4, %3, !insn.addr !3499
  ret i64 %5, !insn.addr !3500
}

define i64 @_ZN4llvm14CastIsPossibleINS_11InstructionEPKNS_5ValueEvE10isPossibleERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_db05:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_11InstructionEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1), !insn.addr !3501
  ret i64 %0, !insn.addr !3502
}

define i64 @_ZN4llvm8CastInfoINS_11InstructionEPKNS_5ValueEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_db23:
  ret i64 0, !insn.addr !3503
}

define i64 @_ZN4llvm14CastIsPossibleINS_10StructTypeEPNS_4TypeEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_db32:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_10StructTypeEKPNS_4TypeEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3504
  ret i64 %0, !insn.addr !3505
}

define i64 @_ZN4llvm8CastInfoINS_10StructTypeEPNS_4TypeEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_db50:
  ret i64 0, !insn.addr !3506
}

define i64 @_ZNK4llvm8ArrayRefIPNS_4TypeEE5emptyEv(i64* %result) local_unnamed_addr {
dec_label_pc_db60:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !3507
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3507
  %3 = load i64, i64* %2, align 8, !insn.addr !3507
  %4 = icmp eq i64 %3, 0, !insn.addr !3508
  %5 = zext i1 %4 to i64, !insn.addr !3509
  %6 = and i64 %3, -256, !insn.addr !3509
  %7 = or i64 %6, %5, !insn.addr !3509
  ret i64 %7, !insn.addr !3510

; uselistorder directives
  uselistorder i64 %3, { 1, 0 }
}

define i64 @_ZN4llvm14CastIsPossibleINS_9ArrayTypeEPNS_4TypeEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_db7c:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_9ArrayTypeEKPNS_4TypeEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3511
  ret i64 %0, !insn.addr !3512
}

define i64 @_ZN4llvm8CastInfoINS_9ArrayTypeEPNS_4TypeEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_db9a:
  ret i64 0, !insn.addr !3513
}

define i64 @_ZN4llvm8Bitfield3getINS0_7ElementIbLj0ELj1ELb1EEEtEENT_4TypeET0_(i16 %arg1) local_unnamed_addr {
dec_label_pc_dba9:
  %0 = call i64 @_ZN4llvm17bitfields_details4ImplINS_8Bitfield7ElementIbLj0ELj1ELb1EEEtE7extractEt(i16 %arg1), !insn.addr !3514
  %1 = trunc i64 %0 to i8, !insn.addr !3515
  %2 = icmp eq i8 %1, 0, !insn.addr !3515
  %3 = icmp eq i1 %2, false, !insn.addr !3516
  %4 = zext i1 %3 to i64, !insn.addr !3516
  %5 = and i64 %0, -256, !insn.addr !3516
  %6 = or i64 %5, %4, !insn.addr !3516
  ret i64 %6, !insn.addr !3517

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
}

define i64 @_ZN4llvm13simplify_typeIPKNS_11InstructionEE18getSimplifiedValueERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dbcd:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !3518
}

define i64 @_ZN4llvm13simplify_typeIPNS_11InstructionEE18getSimplifiedValueERS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dbdf:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !3519
}

define i64 @_ZN4llvm14ValueIsPresentIPNS_11InstructionEvE9isPresentERKS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dbf1:
  %0 = ptrtoint i64** %arg1 to i64
  %1 = icmp eq i64** %arg1, null, !insn.addr !3520
  %2 = icmp eq i1 %1, false, !insn.addr !3521
  %3 = zext i1 %2 to i64, !insn.addr !3521
  %4 = and i64 %0, -256, !insn.addr !3521
  %5 = or i64 %4, %3, !insn.addr !3521
  ret i64 %5, !insn.addr !3522
}

define i64 @_ZN4llvm14CastIsPossibleINS_8LoadInstEPNS_11InstructionEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dc0c:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_8LoadInstEKPNS_11InstructionEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3523
  ret i64 %0, !insn.addr !3524
}

define i64 @_ZN4llvm8CastInfoINS_8LoadInstEPNS_11InstructionEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_dc2a:
  ret i64 0, !insn.addr !3525
}

define i64 @_ZN4llvm8CastInfoINS_8LoadInstEPNS_11InstructionEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dc39:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3526
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_8LoadInstEPNS_11InstructionES3_E4doitEPKS2_(i64* %0), !insn.addr !3526
  ret i64 %1, !insn.addr !3527
}

define i64 @_ZN4llvm14CastIsPossibleINS_9StoreInstEPNS_11InstructionEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dc5a:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_9StoreInstEKPNS_11InstructionEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3528
  ret i64 %0, !insn.addr !3529
}

define i64 @_ZN4llvm8CastInfoINS_9StoreInstEPNS_11InstructionEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_dc78:
  ret i64 0, !insn.addr !3530
}

define i64 @_ZN4llvm8CastInfoINS_9StoreInstEPNS_11InstructionEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dc87:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3531
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_9StoreInstEPNS_11InstructionES3_E4doitEPKS2_(i64* %0), !insn.addr !3531
  ret i64 %1, !insn.addr !3532
}

define i64 @_ZNSt22_Optional_payload_baseIN4llvm13FastMathFlagsEE8_StorageIS1_Lb1EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_dca8:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !3533
}

define i64** @_ZSt7forwardIRN4llvm13FastMathFlagsEEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_dcb7:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !3534
  ret i64** %0, !insn.addr !3534
}

define i64 @_ZNKSt19_Optional_base_implIN4llvm13FastMathFlagsESt14_Optional_baseIS1_Lb1ELb1EEE6_M_getEv(i64* %result) local_unnamed_addr {
dec_label_pc_dcca:
  %0 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !3535
  %1 = trunc i64 %0 to i8, !insn.addr !3536
  %2 = icmp eq i8 %1, 0, !insn.addr !3536
  br i1 %2, label %dec_label_pc_dd02, label %dec_label_pc_dce3, !insn.addr !3537

dec_label_pc_dce3:                                ; preds = %dec_label_pc_dcca
  %3 = call i64 @_ZNKSt19_Optional_base_implIN4llvm13FastMathFlagsESt14_Optional_baseIS1_Lb1ELb1EEE13_M_is_engagedEv(i64* %result), !insn.addr !3538
  br label %dec_label_pc_dd02

dec_label_pc_dd02:                                ; preds = %dec_label_pc_dce3, %dec_label_pc_dcca
  %4 = call i64 @_ZNKSt22_Optional_payload_baseIN4llvm13FastMathFlagsEE6_M_getEv(i64* %result), !insn.addr !3539
  ret i64 %4, !insn.addr !3540

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNKSt19_Optional_base_implIN4llvm13FastMathFlagsESt14_Optional_baseIS1_Lb1ELb1EEE13_M_is_engagedEv, { 1, 0 }
}

define i64 @_ZN4llvm15SmallVectorImplISt4pairIjPNS_6MDNodeEEEC1Ej(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_dd12:
  %0 = zext i32 %arg2 to i64, !insn.addr !3541
  %1 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt4pairIjPNS_6MDNodeEELb1EEC1Em(i64* %result, i64 %0), !insn.addr !3542
  ret i64 %1, !insn.addr !3543
}

define i64 @_ZN4llvm15SmallVectorImplISt4pairIjPNS_6MDNodeEEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_dd3a:
  %rax.0.reg2mem = alloca i64, !insn.addr !3544
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE7isSmallEv(i64* %result), !insn.addr !3545
  %1 = and i64 %0, 4294967295, !insn.addr !3546
  %2 = xor i64 %1, 1, !insn.addr !3546
  %3 = trunc i64 %2 to i8, !insn.addr !3547
  %4 = icmp eq i8 %3, 0, !insn.addr !3547
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !3548
  br i1 %4, label %dec_label_pc_dd71, label %dec_label_pc_dd5d, !insn.addr !3548

dec_label_pc_dd5d:                                ; preds = %dec_label_pc_dd3a
  %5 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv(i64* %result), !insn.addr !3549
  %6 = call i64 @free(i64 %5), !insn.addr !3550
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3550
  br label %dec_label_pc_dd71, !insn.addr !3550

dec_label_pc_dd71:                                ; preds = %dec_label_pc_dd5d, %dec_label_pc_dd3a
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3551

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE5beginEv, { 2, 0, 1 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt4pairIjPNS_6MDNodeEELb1EE13destroy_rangeEPS4_S6_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_dd74:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !3552
}

define i64 @_ZN4llvm12ilist_detail16node_base_parentINS_10BasicBlockEE17getNodeBaseParentEv(i64* %result) local_unnamed_addr {
dec_label_pc_dd88:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !3553
}

define i64 @_ZN4llvm8CastInfoINS_14FPMathOperatorEKPNS_11InstructionEvE10isPossibleERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dd9d:
  %rax.0.reg2mem = alloca i64, !insn.addr !3554
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3555
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_11InstructionEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3556
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3557
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3558
  %3 = call i64 @_ZN4llvm14CastIsPossibleINS_14FPMathOperatorEPKNS_11InstructionEvE10isPossibleERKS4_(i64** nonnull %2), !insn.addr !3558
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3559
  %5 = icmp eq i64 %0, %4, !insn.addr !3559
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3560
  br i1 %5, label %dec_label_pc_ddec, label %dec_label_pc_dde7, !insn.addr !3560

dec_label_pc_dde7:                                ; preds = %dec_label_pc_dd9d
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3561
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3561
  br label %dec_label_pc_ddec, !insn.addr !3561

dec_label_pc_ddec:                                ; preds = %dec_label_pc_dde7, %dec_label_pc_dd9d
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3562
}

define i64**** @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_ddee:
  %0 = bitcast i64* %arg1 to i64****, !insn.addr !3563
  ret i64**** %0, !insn.addr !3563
}

define i64 @_ZNSt4pairIPPKvbEC1IRS2_bLb1EEEOT_OT0_(i64* %result, i64**** %arg2, i1* %arg3) local_unnamed_addr {
dec_label_pc_de00:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i64**** %arg2 to i64*, !insn.addr !3564
  %2 = call i64**** @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE(i64* %1), !insn.addr !3564
  %3 = load i64***, i64**** %2, align 8, !insn.addr !3565
  %4 = ptrtoint i64*** %3 to i64, !insn.addr !3565
  store i64 %4, i64* %result, align 8, !insn.addr !3566
  %5 = bitcast i1* %arg3 to i64*, !insn.addr !3567
  %6 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %5), !insn.addr !3567
  %7 = bitcast i1* %6 to i8*, !insn.addr !3568
  %8 = load i8, i8* %7, align 1, !insn.addr !3568
  %9 = add i64 %0, 8, !insn.addr !3569
  %10 = inttoptr i64 %9 to i8*, !insn.addr !3569
  store i8 %8, i8* %10, align 1, !insn.addr !3569
  ret i64 %0, !insn.addr !3570

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64**** (i64*)* @_ZSt7forwardIRPPKvEOT_RNSt16remove_referenceIS4_E4typeE, { 1, 0 }
}

define i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_de47:
  %0 = bitcast i64* %arg1 to i64***, !insn.addr !3571
  ret i64*** %0, !insn.addr !3571
}

define i64 @_ZNSt4pairIPPKvbEC1IS2_bLb1EEEOT_OT0_(i64* %result, i64*** %arg2, i1* %arg3) local_unnamed_addr {
dec_label_pc_de5a:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i64*** %arg2 to i64*, !insn.addr !3572
  %2 = call i64*** @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE(i64* %1), !insn.addr !3572
  %3 = load i64**, i64*** %2, align 8, !insn.addr !3573
  %4 = ptrtoint i64** %3 to i64, !insn.addr !3573
  store i64 %4, i64* %result, align 8, !insn.addr !3574
  %5 = bitcast i1* %arg3 to i64*, !insn.addr !3575
  %6 = call i1* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE(i64* %5), !insn.addr !3575
  %7 = bitcast i1* %6 to i8*, !insn.addr !3576
  %8 = load i8, i8* %7, align 1, !insn.addr !3576
  %9 = add i64 %0, 8, !insn.addr !3577
  %10 = inttoptr i64 %9 to i8*, !insn.addr !3577
  store i8 %8, i8* %10, align 1, !insn.addr !3577
  ret i64 %0, !insn.addr !3578

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i1* (i64*)* @_ZSt7forwardIbEOT_RNSt16remove_referenceIS0_E4typeE, { 4, 3, 2, 1, 0 }
  uselistorder i64*** (i64*)* @_ZSt7forwardIPPKvEOT_RNSt16remove_referenceIS3_E4typeE, { 2, 1, 0 }
}

define i64 @_ZN4llvm8CastInfoINS_8FunctionEKPNS_5ValueEvE10isPossibleERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dea1:
  %rax.0.reg2mem = alloca i64, !insn.addr !3579
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3580
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3581
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3582
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3583
  %3 = call i64 @_ZN4llvm14CastIsPossibleINS_8FunctionEPKNS_5ValueEvE10isPossibleERKS4_(i64** nonnull %2), !insn.addr !3583
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3584
  %5 = icmp eq i64 %0, %4, !insn.addr !3584
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3585
  br i1 %5, label %dec_label_pc_def0, label %dec_label_pc_deeb, !insn.addr !3585

dec_label_pc_deeb:                                ; preds = %dec_label_pc_dea1
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3586
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3586
  br label %dec_label_pc_def0, !insn.addr !3586

dec_label_pc_def0:                                ; preds = %dec_label_pc_deeb, %dec_label_pc_dea1
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3587
}

define i64 @_ZN4llvm16cast_convert_valINS_8FunctionEPNS_5ValueES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_def2:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3588
}

define i64 @_ZN4llvm8CastInfoINS_8CallInstEKPKNS_5ValueEvE10isPossibleERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_df04:
  %rax.0.reg2mem = alloca i64, !insn.addr !3589
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3590
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !3591
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3592
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3593
  %3 = call i64 @_ZN4llvm14CastIsPossibleINS_8CallInstEPKNS_5ValueEvE10isPossibleERKS4_(i64** nonnull %2), !insn.addr !3593
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3594
  %5 = icmp eq i64 %0, %4, !insn.addr !3594
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3595
  br i1 %5, label %dec_label_pc_df53, label %dec_label_pc_df4e, !insn.addr !3595

dec_label_pc_df4e:                                ; preds = %dec_label_pc_df04
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3596
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3596
  br label %dec_label_pc_df53, !insn.addr !3596

dec_label_pc_df53:                                ; preds = %dec_label_pc_df4e, %dec_label_pc_df04
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3597
}

define i64 @_ZN4llvm16cast_convert_valINS_8CallInstEPKNS_5ValueES4_E4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_df55:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3598
}

define i64 @_ZN4llvm8CastInfoINS_13IntrinsicInstEKPKNS_5ValueEvE10isPossibleERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_df67:
  %rax.0.reg2mem = alloca i64, !insn.addr !3599
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3600
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !3601
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3602
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3603
  %3 = call i64 @_ZN4llvm14CastIsPossibleINS_13IntrinsicInstEPKNS_5ValueEvE10isPossibleERKS4_(i64** nonnull %2), !insn.addr !3603
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3604
  %5 = icmp eq i64 %0, %4, !insn.addr !3604
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3605
  br i1 %5, label %dec_label_pc_dfb6, label %dec_label_pc_dfb1, !insn.addr !3605

dec_label_pc_dfb1:                                ; preds = %dec_label_pc_df67
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3606
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3606
  br label %dec_label_pc_dfb6, !insn.addr !3606

dec_label_pc_dfb6:                                ; preds = %dec_label_pc_dfb1, %dec_label_pc_df67
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3607
}

define i64 @_ZN4llvm16cast_convert_valINS_13IntrinsicInstEPKNS_5ValueES4_E4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_dfb8:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3608
}

define i64 @_ZN4llvm14CastIsPossibleINS_13IntrinsicInstEPKNS_5ValueEvE10isPossibleERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_dfca:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_13IntrinsicInstEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1), !insn.addr !3609
  ret i64 %0, !insn.addr !3610
}

define i64 @_ZNK4llvm15SmallPtrSetImplIPvE12makeIteratorEPKPKv(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_dfe8:
  %rax.0.reg2mem = alloca i64, !insn.addr !3611
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3612
  %1 = call i1 @_ZN4llvm20shouldReverseIterateIPvEEbv(), !insn.addr !3613
  %2 = icmp eq i1 %1, false, !insn.addr !3614
  br i1 %2, label %dec_label_pc_e05f, label %dec_label_pc_e015, !insn.addr !3615

dec_label_pc_e015:                                ; preds = %dec_label_pc_dfe8
  %3 = ptrtoint i64* %result to i64
  %4 = call i64 @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv(i64* %result), !insn.addr !3616
  %5 = ptrtoint i64** %arg2 to i64, !insn.addr !3617
  %6 = icmp eq i64 %4, %5, !insn.addr !3617
  %7 = icmp eq i1 %6, false, !insn.addr !3618
  %8 = add i64 %5, 8
  %storemerge = select i1 %7, i64 %8, i64 %3
  %9 = inttoptr i64 %storemerge to i64**, !insn.addr !3619
  %10 = bitcast i64* %result to i64**, !insn.addr !3619
  %11 = call i64 @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE(i64* nonnull %stack_var_-56, i64** %9, i64** %10, i64* %result), !insn.addr !3619
  br label %dec_label_pc_e090, !insn.addr !3620

dec_label_pc_e05f:                                ; preds = %dec_label_pc_dfe8
  %12 = call i64 @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv(i64* %result), !insn.addr !3621
  %13 = inttoptr i64 %12 to i64**, !insn.addr !3622
  %14 = call i64 @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE(i64* nonnull %stack_var_-56, i64** %arg2, i64** %13, i64* %result), !insn.addr !3622
  br label %dec_label_pc_e090, !insn.addr !3623

dec_label_pc_e090:                                ; preds = %dec_label_pc_e05f, %dec_label_pc_e015
  %storemerge2 = load i64, i64* %stack_var_-56, align 8
  %15 = call i64 @__readfsqword(i64 40), !insn.addr !3624
  %16 = icmp eq i64 %0, %15, !insn.addr !3624
  store i64 %storemerge2, i64* %rax.0.reg2mem, !insn.addr !3625
  br i1 %16, label %dec_label_pc_e0a4, label %dec_label_pc_e09f, !insn.addr !3625

dec_label_pc_e09f:                                ; preds = %dec_label_pc_e090
  %17 = call i64 @__stack_chk_fail(), !insn.addr !3626
  store i64 %17, i64* %rax.0.reg2mem, !insn.addr !3626
  br label %dec_label_pc_e0a4, !insn.addr !3626

dec_label_pc_e0a4:                                ; preds = %dec_label_pc_e09f, %dec_label_pc_e090
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3627

; uselistorder directives
  uselistorder i64 (i64*, i64**, i64**, i64*)* @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNK4llvm19SmallPtrSetImplBase10EndPointerEv, { 1, 0 }
  uselistorder i64** %arg2, { 1, 0 }
}

define i64 @_ZSt9make_pairIN4llvm19SmallPtrSetIteratorIPvEERbESt4pairINSt25__strip_reference_wrapperINSt5decayIT_E4typeEE6__typeENS6_INS7_IT0_E4typeEE6__typeEEOS8_OSD_(i64* %result, i64* %arg2, i1** %arg3) local_unnamed_addr {
dec_label_pc_e0aa:
  %0 = ptrtoint i64* %result to i64
  %1 = bitcast i1** %arg3 to i64*, !insn.addr !3628
  %2 = call i1** @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE(i64* %1), !insn.addr !3628
  %3 = call i64* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg2), !insn.addr !3629
  %4 = call i64 @_ZNSt4pairIN4llvm19SmallPtrSetIteratorIPvEEbEC1IS3_RbLb1EEEOT_OT0_(i64* %result, i64* %3, i1** %2), !insn.addr !3630
  ret i64 %0, !insn.addr !3631
}

define i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEEE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_e0fe:
  %0 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getNextEv(i64* %result), !insn.addr !3632
  ret i64 %0, !insn.addr !3633
}

define i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_8FunctionELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_e11c:
  %0 = call i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_8FunctionELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1), !insn.addr !3634
  ret i64 %0, !insn.addr !3635
}

define i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_8FunctionELb0ELb0EvLb0EvEELb0ELb0EEC1ERNS_15ilist_node_implIS4_EE(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_e13a:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !3636
  ret i64 %1, !insn.addr !3637
}

define i64 @_ZN4llvm15SmallVectorImplIPNS_11InstructionEEC1Ej(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_e158:
  %0 = zext i32 %arg2 to i64, !insn.addr !3638
  %1 = call i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EEC1Em(i64* %result, i64 %0), !insn.addr !3639
  ret i64 %1, !insn.addr !3640
}

define i64 @_ZN4llvm15SmallVectorImplIPNS_11InstructionEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_e180:
  %rax.0.reg2mem = alloca i64, !insn.addr !3641
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE7isSmallEv(i64* %result), !insn.addr !3642
  %1 = and i64 %0, 4294967295, !insn.addr !3643
  %2 = xor i64 %1, 1, !insn.addr !3643
  %3 = trunc i64 %2 to i8, !insn.addr !3644
  %4 = icmp eq i8 %3, 0, !insn.addr !3644
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !3645
  br i1 %4, label %dec_label_pc_e1b7, label %dec_label_pc_e1a3, !insn.addr !3645

dec_label_pc_e1a3:                                ; preds = %dec_label_pc_e180
  %5 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE5beginEv(i64* %result), !insn.addr !3646
  %6 = call i64 @free(i64 %5), !insn.addr !3647
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3647
  br label %dec_label_pc_e1b7, !insn.addr !3647

dec_label_pc_e1b7:                                ; preds = %dec_label_pc_e1a3, %dec_label_pc_e180
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3648

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE5beginEv, { 3, 2, 1, 0 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE13destroy_rangeEPS2_S4_(i64** %arg1, i64** %arg2) local_unnamed_addr {
dec_label_pc_e1ba:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !3649
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE28reserveForParamAndGetAddressERKSE_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_e1ce:
  %0 = call i64* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE32reserveForParamAndGetAddressImplINS_23SmallVectorTemplateBaseISE_Lb0EEEEEPKSE_PT_RSJ_m(i64* %result, i64* %arg2, i64 %arg3), !insn.addr !3650
  %1 = ptrtoint i64* %0 to i64, !insn.addr !3650
  ret i64 %1, !insn.addr !3651
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_e200:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !3652
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !3653
  %2 = mul i64 %1, 32, !insn.addr !3654
  %3 = add i64 %2, %0, !insn.addr !3655
  ret i64 %3, !insn.addr !3656
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1ERKSD_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_e23a:
  %0 = alloca i128
  %rax.0.reg2mem = alloca i64, !insn.addr !3657
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %result to i64
  %3 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !3658
  %4 = bitcast i64* %rdi to i128*
  %5 = load i128, i128* %4, align 8, !insn.addr !3659
  call void @__asm_movups(i128 %5, i128 %3), !insn.addr !3659
  %6 = add i64 %2, 16, !insn.addr !3660
  %7 = inttoptr i64 %6 to i64*, !insn.addr !3660
  %8 = load i64, i64* %7, align 8, !insn.addr !3660
  call void @__asm_movq(i64 %8, i128 %3), !insn.addr !3660
  %9 = call i64 @_ZNSt14_Function_baseC1Ev(i64* %result), !insn.addr !3661
  %10 = add i64 %2, 24, !insn.addr !3662
  %11 = inttoptr i64 %10 to i64*, !insn.addr !3662
  store i64 0, i64* %11, align 8, !insn.addr !3662
  %12 = call i64 @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv(i64* %arg2), !insn.addr !3663
  %13 = trunc i64 %12 to i8, !insn.addr !3664
  %14 = icmp eq i8 %13, 0, !insn.addr !3664
  store i64 %12, i64* %rax.0.reg2mem, !insn.addr !3665
  br i1 %14, label %dec_label_pc_e2c4, label %dec_label_pc_e286, !insn.addr !3665

dec_label_pc_e286:                                ; preds = %dec_label_pc_e23a
  %15 = ptrtoint i64* %arg2 to i64
  %16 = add i64 %15, 24, !insn.addr !3666
  %17 = inttoptr i64 %16 to i64*, !insn.addr !3666
  %18 = load i64, i64* %17, align 8, !insn.addr !3666
  store i64 %18, i64* %11, align 8, !insn.addr !3667
  %19 = add i64 %15, 16, !insn.addr !3668
  %20 = inttoptr i64 %19 to i64*, !insn.addr !3668
  %21 = load i64, i64* %20, align 8, !insn.addr !3668
  store i64 %21, i64* %7, align 8, !insn.addr !3669
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !3669
  br label %dec_label_pc_e2c4, !insn.addr !3669

dec_label_pc_e2c4:                                ; preds = %dec_label_pc_e286, %dec_label_pc_e23a
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3670

; uselistorder directives
  uselistorder i128 %3, { 1, 0 }
  uselistorder i64* %arg2, { 1, 0 }
}

define i64 @_ZN4llvm14CastIsPossibleINS_11GlobalAliasEPNS_5ValueEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e2c7:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_11GlobalAliasEKPNS_5ValueEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3671
  ret i64 %0, !insn.addr !3672
}

define i64 @_ZN4llvm8CastInfoINS_11GlobalAliasEPNS_5ValueEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e2e5:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3673
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_11GlobalAliasEPNS_5ValueES3_E4doitEPKS2_(i64* %0), !insn.addr !3673
  ret i64 %1, !insn.addr !3674
}

define i64 @_ZN4llvm14CastIsPossibleINS_11IntegerTypeEPNS_4TypeEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e306:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_11IntegerTypeEKPNS_4TypeEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3675
  ret i64 %0, !insn.addr !3676
}

define i64 @_ZN4llvm8CastInfoINS_11IntegerTypeEPNS_4TypeEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_e324:
  ret i64 0, !insn.addr !3677
}

define i64 @_ZN4llvm8CastInfoINS_16DbgInfoIntrinsicEKPNS_8CallBaseEvE10isPossibleERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e333:
  %rax.0.reg2mem = alloca i64, !insn.addr !3678
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3679
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_8CallBaseEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3680
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3681
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3682
  %3 = call i64 @_ZN4llvm14CastIsPossibleINS_16DbgInfoIntrinsicEPKNS_8CallBaseEvE10isPossibleERKS4_(i64** nonnull %2), !insn.addr !3682
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3683
  %5 = icmp eq i64 %0, %4, !insn.addr !3683
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3684
  br i1 %5, label %dec_label_pc_e382, label %dec_label_pc_e37d, !insn.addr !3684

dec_label_pc_e37d:                                ; preds = %dec_label_pc_e333
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3685
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3685
  br label %dec_label_pc_e382, !insn.addr !3685

dec_label_pc_e382:                                ; preds = %dec_label_pc_e37d, %dec_label_pc_e333
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3686
}

define i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_e384:
  %0 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getNextEv(i64* %result), !insn.addr !3687
  ret i64 %0, !insn.addr !3688
}

define i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE11getValuePtrEPNS_15ilist_node_implIS4_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_e3a2:
  %0 = call i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1), !insn.addr !3689
  ret i64 %0, !insn.addr !3690
}

define i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_e3c0:
  %0 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0ENS_10BasicBlockEEELb0EE7getNextEv(i64* %result), !insn.addr !3691
  ret i64 %0, !insn.addr !3692
}

define i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0ENS_10BasicBlockEEELb0EE15isKnownSentinelEv(i64* %result) local_unnamed_addr {
dec_label_pc_e3de:
  ret i64 0, !insn.addr !3693
}

define i64 @_ZN4llvm12ilist_detail18SpecificNodeAccessINS0_12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEE11getValuePtrEPNS_15ilist_node_implIS5_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_e3f1:
  %0 = call i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEEENT_7pointerEPNS_15ilist_node_implIS7_EE(i64* %arg1), !insn.addr !3694
  ret i64 %0, !insn.addr !3695
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE28reserveForParamAndGetAddressERS2_m(i64* %result, i64** %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_e410:
  %0 = call i64** @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE32reserveForParamAndGetAddressImplINS_23SmallVectorTemplateBaseIS2_Lb1EEEEEPKS2_PT_RS7_m(i64* %result, i64** %arg2, i64 %arg3), !insn.addr !3696
  %1 = ptrtoint i64** %0 to i64, !insn.addr !3696
  ret i64 %1, !insn.addr !3697
}

define i64 @_ZN4llvm14CastIsPossibleINS_8CallBaseEPNS_11InstructionEvE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e441:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_8CallBaseEKPNS_11InstructionEPKS2_E4doitERS4_(i64** %arg1), !insn.addr !3698
  ret i64 %0, !insn.addr !3699
}

define i64 @_ZN4llvm8CastInfoINS_8CallBaseEPNS_11InstructionEvE10castFailedEv() local_unnamed_addr {
dec_label_pc_e45f:
  ret i64 0, !insn.addr !3700
}

define i64 @_ZN4llvm8CastInfoINS_8CallBaseEPNS_11InstructionEvE6doCastERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e46e:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3701
  %1 = call i64 @_ZN4llvm16cast_convert_valINS_8CallBaseEPNS_11InstructionES3_E4doitEPKS2_(i64* %0), !insn.addr !3701
  ret i64 %1, !insn.addr !3702
}

define i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_e490:
  %0 = ptrtoint i64* %result to i64
  %1 = load i64, i64* inttoptr (i64 58531 to i64*), align 8, !insn.addr !3703
  %2 = add i64 %1, 16, !insn.addr !3704
  store i64 %2, i64* %result, align 8, !insn.addr !3705
  ret i64 %0, !insn.addr !3706
}

define i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_e4b2:
  %0 = ptrtoint i64* %result to i64
  %1 = load i64, i64* inttoptr (i64 58565 to i64*), align 8, !insn.addr !3707
  %2 = add i64 %1, 16, !insn.addr !3708
  store i64 %2, i64* %result, align 8, !insn.addr !3709
  ret i64 %0, !insn.addr !3710
}

define i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED0Ev(i64* %result) local_unnamed_addr {
dec_label_pc_e4d4:
  %0 = call i64 @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev(i64* %result), !insn.addr !3711
  %1 = call i64 @_ZdlPvm(i64* %result, i64 8), !insn.addr !3712
  ret i64 %1, !insn.addr !3713

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm6detail11PassConceptINS_6ModuleENS_15AnalysisManagerIS2_JEEEJEED1Ev, { 1, 0 }
}

define i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EECI1St15__uniq_ptr_implIS6_S8_EEPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_e504:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EPS6_(i64* %result, i64* %arg2), !insn.addr !3714
  ret i64 %0, !insn.addr !3715
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1IS8_vEEPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_e52e:
  %0 = call i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EECI1St15__uniq_ptr_implIS6_S8_EEPS6_(i64* %result, i64* %arg2), !insn.addr !3716
  ret i64 %0, !insn.addr !3717
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_e558:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %result), !insn.addr !3718
  %1 = inttoptr i64 %0 to i64*, !insn.addr !3719
  %2 = load i64, i64* %1, align 8, !insn.addr !3719
  %3 = icmp eq i64 %2, 0, !insn.addr !3720
  br i1 %3, label %dec_label_pc_e5ae, label %dec_label_pc_e585, !insn.addr !3721

dec_label_pc_e585:                                ; preds = %dec_label_pc_e558
  %4 = inttoptr i64 %0 to i64***, !insn.addr !3722
  %5 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE11get_deleterEv(i64* %result), !insn.addr !3723
  %6 = call i64* @_ZSt4moveIRPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEONSt16remove_referenceIT_E4typeEOSA_(i64*** %4), !insn.addr !3724
  %7 = load i64, i64* %6, align 8, !insn.addr !3725
  %8 = inttoptr i64 %5 to i64*, !insn.addr !3726
  %9 = inttoptr i64 %7 to i64*, !insn.addr !3726
  %10 = call i64 @_ZNKSt14default_deleteIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEclEPS6_(i64* %8, i64* %9), !insn.addr !3726
  br label %dec_label_pc_e5ae, !insn.addr !3726

dec_label_pc_e5ae:                                ; preds = %dec_label_pc_e585, %dec_label_pc_e558
  store i64 0, i64* %1, align 8, !insn.addr !3727
  ret i64 %0, !insn.addr !3728
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE9push_backEOSA_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_e5c0:
  %0 = bitcast i64* %arg2 to i64**, !insn.addr !3729
  %1 = call i64* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_(i64** %0), !insn.addr !3729
  %2 = ptrtoint i64* %1 to i64, !insn.addr !3729
  %3 = call i64* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12emplace_backIJSA_EEERSA_DpOT_(i64* %result, i64 %2), !insn.addr !3730
  %4 = ptrtoint i64* %3 to i64, !insn.addr !3730
  ret i64 %4, !insn.addr !3731
}

define i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e5f5:
  %0 = call i64 @_ZN4llvm13simplify_typeIPKNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3732
  %1 = inttoptr i64 %0 to i64*, !insn.addr !3733
  %2 = load i64, i64* %1, align 8, !insn.addr !3733
  ret i64 %2, !insn.addr !3734

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm13simplify_typeIPKNS_5ValueEE18getSimplifiedValueERS3_, { 1, 0 }
}

define i64 @_ZN4llvm13simplify_typeIKPNS_4TypeEE18getSimplifiedValueERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e616:
  %0 = call i64 @_ZN4llvm13simplify_typeIPNS_4TypeEE18getSimplifiedValueERS2_(i64** %arg1), !insn.addr !3735
  %1 = inttoptr i64 %0 to i64*, !insn.addr !3736
  %2 = load i64, i64* %1, align 8, !insn.addr !3736
  ret i64 %2, !insn.addr !3737

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm13simplify_typeIPNS_4TypeEE18getSimplifiedValueERS2_, { 1, 0 }
}

define i64 @_ZN4llvm6detail13PunnedPointerIPvEC1El(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_e638:
  %0 = call i64 @_ZN4llvm6detail13PunnedPointerIPvEaSEl(i64* %result, i32 %arg2), !insn.addr !3738
  ret i64 %0, !insn.addr !3739
}

define i64 @_ZNR4llvm14PointerIntPairIPvLj2EiNS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEENS_18PointerIntPairInfoIS1_Lj2ESA_EEE16setPointerAndIntES1_i(i64* %result, i64* %arg2, i32 %arg3) local_unnamed_addr {
dec_label_pc_e662:
  %0 = call i64 @_ZN4llvm18PointerIntPairInfoIPvLj2ENS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEEE13updatePointerElS1_(i32 0, i64* %arg2), !insn.addr !3740
  %1 = trunc i64 %0 to i32, !insn.addr !3741
  %2 = call i64 @_ZN4llvm18PointerIntPairInfoIPvLj2ENS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEEE9updateIntEll(i32 %1, i32 %arg3), !insn.addr !3741
  %3 = trunc i64 %2 to i32, !insn.addr !3742
  %4 = call i64 @_ZN4llvm6detail13PunnedPointerIPvEaSEl(i64* %result, i32 %3), !insn.addr !3742
  ret i64 %4, !insn.addr !3743

; uselistorder directives
  uselistorder i64 (i64*, i32)* @_ZN4llvm6detail13PunnedPointerIPvEaSEl, { 1, 0 }
  uselistorder i32 0, { 10, 11, 40, 26, 21, 22, 6, 23, 24, 12, 13, 25, 14, 38, 39, 20, 7, 5, 0, 27, 28, 15, 16, 29, 30, 8, 31, 32, 33, 34, 35, 17, 18, 36, 37, 19, 3, 4, 1, 2, 9 }
}

define i64 @_ZN4llvm13simplify_typeIKPNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e6b5:
  %0 = call i64 @_ZN4llvm13simplify_typeIPNS_5ValueEE18getSimplifiedValueERS2_(i64** %arg1), !insn.addr !3744
  %1 = inttoptr i64 %0 to i64*, !insn.addr !3745
  %2 = load i64, i64* %1, align 8, !insn.addr !3745
  ret i64 %2, !insn.addr !3746

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm13simplify_typeIPNS_5ValueEE18getSimplifiedValueERS2_, { 1, 0 }
}

define i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_e6d6:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3747
}

define i64 @_ZN4llvm13isa_impl_wrapINS_17DbgVariableRecordEKNS_9DbgRecordES3_E4doitERS3_(i64* %arg1) local_unnamed_addr {
dec_label_pc_e6e8:
  %0 = call i64 @_ZN4llvm11isa_impl_clINS_17DbgVariableRecordEKNS_9DbgRecordEE4doitERS3_(i64* %arg1), !insn.addr !3748
  ret i64 %0, !insn.addr !3749
}

define i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_e706:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !3750
  ret i64** %0, !insn.addr !3750
}

define i64 @_ZN4llvm10adl_detail10begin_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl5begincl7forwardIT_Efp_EEEOSB_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e718:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3751
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !3751
  %2 = bitcast i64** %1 to i64*, !insn.addr !3752
  %3 = call i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE5beginEv(i64* %2), !insn.addr !3752
  ret i64 %3, !insn.addr !3753
}

define i64 @_ZN4llvm10adl_detail8end_implIRNS_14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEEDTcl3endcl7forwardIT_Efp_EEEOSB_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e747:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3754
  %1 = call i64** @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE(i64* %0), !insn.addr !3754
  %2 = bitcast i64** %1 to i64*, !insn.addr !3755
  %3 = call i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE3endEv(i64* %2), !insn.addr !3755
  ret i64 %3, !insn.addr !3756

; uselistorder directives
  uselistorder i64** (i64*)* @_ZSt7forwardIRN4llvm14iterator_rangeINS0_14ilist_iteratorINS0_12ilist_detail12node_optionsINS0_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEEEEOT_RNSt16remove_referenceISA_E4typeE, { 3, 2, 1, 0 }
}

define i64 @_ZNK4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEE7getPrevEv(i64* %result) local_unnamed_addr {
dec_label_pc_e776:
  %0 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getPrevEv(i64* %result), !insn.addr !3757
  ret i64 %0, !insn.addr !3758
}

define i64 @_ZN4llvm14CastIsPossibleINS_5ValueEPKS1_vE10isPossibleERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e794:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_5ValueEKPKS1_S3_E4doitERS4_(i64** %arg1), !insn.addr !3759
  ret i64 %0, !insn.addr !3760
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8FunctionEKPNS_5ValueEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e7b2:
  %rax.0.reg2mem = alloca i64, !insn.addr !3761
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3762
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3763
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3764
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3765
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_8FunctionEPKNS_5ValueES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3765
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3766
  %5 = icmp eq i64 %0, %4, !insn.addr !3766
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3767
  br i1 %5, label %dec_label_pc_e801, label %dec_label_pc_e7fc, !insn.addr !3767

dec_label_pc_e7fc:                                ; preds = %dec_label_pc_e7b2
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3768
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3768
  br label %dec_label_pc_e801, !insn.addr !3768

dec_label_pc_e801:                                ; preds = %dec_label_pc_e7fc, %dec_label_pc_e7b2
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3769
}

define i64 @_ZN4llvm13isa_impl_wrapINS_11InstructionEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e803:
  %rax.0.reg2mem = alloca i64, !insn.addr !3770
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3771
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !3772
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3773
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3774
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_11InstructionEPKNS_5ValueES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3774
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3775
  %5 = icmp eq i64 %0, %4, !insn.addr !3775
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3776
  br i1 %5, label %dec_label_pc_e852, label %dec_label_pc_e84d, !insn.addr !3776

dec_label_pc_e84d:                                ; preds = %dec_label_pc_e803
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3777
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3777
  br label %dec_label_pc_e852, !insn.addr !3777

dec_label_pc_e852:                                ; preds = %dec_label_pc_e84d, %dec_label_pc_e803
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3778
}

define i64 @_ZN4llvm13isa_impl_wrapINS_10StructTypeEKPNS_4TypeEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e854:
  %rax.0.reg2mem = alloca i64, !insn.addr !3779
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3780
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_4TypeEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3781
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3782
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3783
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_10StructTypeEPKNS_4TypeES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3783
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3784
  %5 = icmp eq i64 %0, %4, !insn.addr !3784
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3785
  br i1 %5, label %dec_label_pc_e8a3, label %dec_label_pc_e89e, !insn.addr !3785

dec_label_pc_e89e:                                ; preds = %dec_label_pc_e854
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3786
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3786
  br label %dec_label_pc_e8a3, !insn.addr !3786

dec_label_pc_e8a3:                                ; preds = %dec_label_pc_e89e, %dec_label_pc_e854
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3787
}

define i64 @_ZN4llvm13isa_impl_wrapINS_9ArrayTypeEKPNS_4TypeEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e8a5:
  %rax.0.reg2mem = alloca i64, !insn.addr !3788
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3789
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_4TypeEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3790
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3791
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3792
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_9ArrayTypeEPKNS_4TypeES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3792
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3793
  %5 = icmp eq i64 %0, %4, !insn.addr !3793
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3794
  br i1 %5, label %dec_label_pc_e8f4, label %dec_label_pc_e8ef, !insn.addr !3794

dec_label_pc_e8ef:                                ; preds = %dec_label_pc_e8a5
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3795
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3795
  br label %dec_label_pc_e8f4, !insn.addr !3795

dec_label_pc_e8f4:                                ; preds = %dec_label_pc_e8ef, %dec_label_pc_e8a5
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3796
}

define i64 @_ZN4llvm17bitfields_details4ImplINS_8Bitfield7ElementIbLj0ELj1ELb1EEEtE7extractEt(i16 %arg1) local_unnamed_addr {
dec_label_pc_e8f6:
  %0 = trunc i16 %arg1 to i8
  %1 = urem i8 %0, 2, !insn.addr !3797
  %2 = call i64 @_ZN4llvm17bitfields_details10CompressorIhLj1ELb1EE6unpackEh(i8 %1), !insn.addr !3797
  ret i64 %2, !insn.addr !3798

; uselistorder directives
  uselistorder i8 2, { 1, 4, 0, 2, 3 }
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8LoadInstEKPNS_11InstructionEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e923:
  %rax.0.reg2mem = alloca i64, !insn.addr !3799
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3800
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_11InstructionEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3801
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3802
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3803
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_8LoadInstEPKNS_11InstructionES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3803
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3804
  %5 = icmp eq i64 %0, %4, !insn.addr !3804
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3805
  br i1 %5, label %dec_label_pc_e972, label %dec_label_pc_e96d, !insn.addr !3805

dec_label_pc_e96d:                                ; preds = %dec_label_pc_e923
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3806
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3806
  br label %dec_label_pc_e972, !insn.addr !3806

dec_label_pc_e972:                                ; preds = %dec_label_pc_e96d, %dec_label_pc_e923
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3807
}

define i64 @_ZN4llvm16cast_convert_valINS_8LoadInstEPNS_11InstructionES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_e974:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3808
}

define i64 @_ZN4llvm13isa_impl_wrapINS_9StoreInstEKPNS_11InstructionEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_e986:
  %rax.0.reg2mem = alloca i64, !insn.addr !3809
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3810
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_11InstructionEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3811
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3812
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3813
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_9StoreInstEPKNS_11InstructionES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3813
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3814
  %5 = icmp eq i64 %0, %4, !insn.addr !3814
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3815
  br i1 %5, label %dec_label_pc_e9d5, label %dec_label_pc_e9d0, !insn.addr !3815

dec_label_pc_e9d0:                                ; preds = %dec_label_pc_e986
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3816
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3816
  br label %dec_label_pc_e9d5, !insn.addr !3816

dec_label_pc_e9d5:                                ; preds = %dec_label_pc_e9d0, %dec_label_pc_e986
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3817
}

define i64 @_ZN4llvm16cast_convert_valINS_9StoreInstEPNS_11InstructionES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_e9d7:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3818
}

define i64 @_ZNKSt22_Optional_payload_baseIN4llvm13FastMathFlagsEE6_M_getEv(i64* %result) local_unnamed_addr {
dec_label_pc_e9ea:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !3819
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt4pairIjPNS_6MDNodeEELb1EEC1Em(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_e9fc:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvEC1Em(i64* %result, i64 %arg2), !insn.addr !3820
  ret i64 %0, !insn.addr !3821
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE7isSmallEv(i64* %result) local_unnamed_addr {
dec_label_pc_ea26:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE10getFirstElEv(i64* %result), !insn.addr !3822
  %2 = icmp eq i64 %1, %0, !insn.addr !3823
  %3 = zext i1 %2 to i64, !insn.addr !3824
  %4 = and i64 %1, -256, !insn.addr !3824
  %5 = or i64 %4, %3, !insn.addr !3824
  ret i64 %5, !insn.addr !3825

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64 @_ZN4llvm13simplify_typeIKPNS_11InstructionEE18getSimplifiedValueERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_ea56:
  %0 = call i64 @_ZN4llvm13simplify_typeIPNS_11InstructionEE18getSimplifiedValueERS2_(i64** %arg1), !insn.addr !3826
  %1 = inttoptr i64 %0 to i64*, !insn.addr !3827
  %2 = load i64, i64* %1, align 8, !insn.addr !3827
  ret i64 %2, !insn.addr !3828
}

define i64 @_ZN4llvm14CastIsPossibleINS_14FPMathOperatorEPKNS_11InstructionEvE10isPossibleERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_ea77:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_14FPMathOperatorEKPKNS_11InstructionES4_E4doitERS5_(i64** %arg1), !insn.addr !3829
  ret i64 %0, !insn.addr !3830
}

define i1** @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_ea95:
  %0 = bitcast i64* %arg1 to i1**, !insn.addr !3831
  ret i1** %0, !insn.addr !3831
}

define i64** @_ZNSt9_Any_data9_M_accessIPKSt9type_infoEERT_v(i64* %result) local_unnamed_addr {
dec_label_pc_eaa8:
  %0 = call i64 @_ZNSt9_Any_data9_M_accessEv(i64* %result), !insn.addr !3832
  %1 = inttoptr i64 %0 to i64**, !insn.addr !3833
  ret i64** %1, !insn.addr !3833

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNSt9_Any_data9_M_accessEv, { 4, 3, 2, 1, 0 }
}

define i64 @_ZN4llvm14CastIsPossibleINS_8FunctionEPKNS_5ValueEvE10isPossibleERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_eac6:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_8FunctionEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1), !insn.addr !3834
  ret i64 %0, !insn.addr !3835
}

define i64 @_ZN4llvm14CastIsPossibleINS_8CallInstEPKNS_5ValueEvE10isPossibleERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_eae4:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_8CallInstEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1), !insn.addr !3836
  ret i64 %0, !insn.addr !3837
}

define i64 @_ZN4llvm13isa_impl_wrapINS_13IntrinsicInstEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_eb02:
  %rax.0.reg2mem = alloca i64, !insn.addr !3838
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3839
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !3840
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3841
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3842
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_13IntrinsicInstEPKNS_5ValueES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3842
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3843
  %5 = icmp eq i64 %0, %4, !insn.addr !3843
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3844
  br i1 %5, label %dec_label_pc_eb51, label %dec_label_pc_eb4c, !insn.addr !3844

dec_label_pc_eb4c:                                ; preds = %dec_label_pc_eb02
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3845
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3845
  br label %dec_label_pc_eb51, !insn.addr !3845

dec_label_pc_eb51:                                ; preds = %dec_label_pc_eb4c, %dec_label_pc_eb02
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3846
}

define i64 @_ZN4llvm19SmallPtrSetIteratorIPvEC1EPKPKvS6_RKNS_14DebugEpochBaseE(i64* %result, i64** %arg2, i64** %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_eb54:
  %0 = call i64 @_ZN4llvm23SmallPtrSetIteratorImplC1EPKPKvS4_(i64* %result, i64** %arg2, i64** %arg3), !insn.addr !3847
  %1 = call i64 @_ZN4llvm14DebugEpochBase10HandleBaseC1EPKS0_(i64* %result, i64* %arg4), !insn.addr !3848
  ret i64 %1, !insn.addr !3849

; uselistorder directives
  uselistorder i64 (i64*, i64*)* @_ZN4llvm14DebugEpochBase10HandleBaseC1EPKS0_, { 1, 0 }
}

define i64* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_eb9d:
  ret i64* %arg1, !insn.addr !3850
}

define i64 @_ZNSt4pairIN4llvm19SmallPtrSetIteratorIPvEEbEC1IS3_RbLb1EEEOT_OT0_(i64* %result, i64* %arg2, i1** %arg3) local_unnamed_addr {
dec_label_pc_ebb0:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE(i64* %arg2), !insn.addr !3851
  %2 = ptrtoint i64* %1 to i64, !insn.addr !3851
  %3 = add i64 %2, 8, !insn.addr !3852
  %4 = inttoptr i64 %3 to i64*, !insn.addr !3852
  %5 = load i64, i64* %4, align 8, !insn.addr !3852
  %6 = load i64, i64* %1, align 8, !insn.addr !3853
  store i64 %6, i64* %result, align 8, !insn.addr !3854
  %7 = add i64 %0, 8, !insn.addr !3855
  %8 = inttoptr i64 %7 to i64*, !insn.addr !3855
  store i64 %5, i64* %8, align 8, !insn.addr !3855
  %9 = bitcast i1** %arg3 to i64*, !insn.addr !3856
  %10 = call i1** @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE(i64* %9), !insn.addr !3856
  %11 = bitcast i1** %10 to i8*, !insn.addr !3857
  %12 = load i8, i8* %11, align 1, !insn.addr !3857
  %13 = add i64 %0, 16, !insn.addr !3858
  %14 = inttoptr i64 %13 to i8*, !insn.addr !3858
  store i8 %12, i8* %14, align 1, !insn.addr !3858
  ret i64 %0, !insn.addr !3859

; uselistorder directives
  uselistorder i64 %0, { 1, 0, 2 }
  uselistorder i1** (i64*)* @_ZSt7forwardIRbEOT_RNSt16remove_referenceIS1_E4typeE, { 1, 0 }
  uselistorder i64* (i64*)* @_ZSt7forwardIN4llvm19SmallPtrSetIteratorIPvEEEOT_RNSt16remove_referenceIS4_E4typeE, { 1, 0 }
}

define i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getPrevEv(i64* %result) local_unnamed_addr {
dec_label_pc_ec00:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !3860
}

define i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_ec16:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !3861
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3861
  %3 = load i64, i64* %2, align 8, !insn.addr !3861
  ret i64 %3, !insn.addr !3862
}

define i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_8FunctionELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_ec2c:
  %0 = ptrtoint i64* %arg1 to i64
  %1 = icmp eq i64* %arg1, null, !insn.addr !3863
  %2 = add i64 %0, -56
  %storemerge = select i1 %1, i64 0, i64 %2
  ret i64 %storemerge, !insn.addr !3864
}

define i64 @_ZN4llvm17bitfields_details10CompressorIhLj1ELb1EE6unpackEh(i8 %arg1) local_unnamed_addr {
dec_label_pc_ec50:
  %0 = zext i8 %arg1 to i64, !insn.addr !3865
  ret i64 %0, !insn.addr !3866
}

define i1 @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_ec64:
  %rax.0.reg2mem = alloca i64, !insn.addr !3867
  %stack_var_-17 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3868
  %1 = call i64 @_ZNKSt4lessIPKvEclES1_S1_(i64* nonnull %stack_var_-17, i64* %arg2, i64* %arg3), !insn.addr !3869
  %2 = call i64 @__readfsqword(i64 40), !insn.addr !3870
  %3 = icmp eq i64 %0, %2, !insn.addr !3870
  store i64 %1, i64* %rax.0.reg2mem, !insn.addr !3871
  br i1 %3, label %dec_label_pc_ecb6, label %dec_label_pc_ecb1, !insn.addr !3871

dec_label_pc_ecb1:                                ; preds = %dec_label_pc_ec64
  %4 = call i64 @__stack_chk_fail(), !insn.addr !3872
  store i64 %4, i64* %rax.0.reg2mem, !insn.addr !3872
  br label %dec_label_pc_ecb6, !insn.addr !3872

dec_label_pc_ecb6:                                ; preds = %dec_label_pc_ecb1, %dec_label_pc_ec64
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  %5 = urem i64 %rax.0.reload, 2
  %6 = icmp ne i64 %5, 0, !insn.addr !3873
  ret i1 %6, !insn.addr !3873

; uselistorder directives
  uselistorder i64 2, { 3, 4, 5, 6, 7, 8, 9, 10, 2, 11, 12, 13, 14, 15, 16, 0, 20, 17, 18, 19, 1 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EEC1Em(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_ecb8:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvEC1Em(i64* %result, i64 %arg2), !insn.addr !3874
  ret i64 %0, !insn.addr !3875
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE7isSmallEv(i64* %result) local_unnamed_addr {
dec_label_pc_ece2:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE10getFirstElEv(i64* %result), !insn.addr !3876
  %2 = icmp eq i64 %1, %0, !insn.addr !3877
  %3 = zext i1 %2 to i64, !insn.addr !3878
  %4 = and i64 %1, -256, !insn.addr !3878
  %5 = or i64 %4, %3, !insn.addr !3878
  ret i64 %5, !insn.addr !3879

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
}

define i64* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE32reserveForParamAndGetAddressImplINS_23SmallVectorTemplateBaseISE_Lb0EEEEEPKSE_PT_RSJ_m(i64* %arg1, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_ed12:
  %storemerge1.reg2mem = alloca i64, !insn.addr !3880
  %0 = ptrtoint i64* %arg2 to i64
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %arg1), !insn.addr !3881
  %2 = add i64 %1, %arg3, !insn.addr !3882
  %3 = call i64 @_ZNK4llvm15SmallVectorBaseIjE8capacityEv(i64* %arg1), !insn.addr !3883
  %4 = icmp ult i64 %3, %2, !insn.addr !3884
  %5 = icmp eq i1 %4, false, !insn.addr !3885
  %6 = icmp eq i1 %5, false, !insn.addr !3886
  %7 = icmp eq i1 %6, false, !insn.addr !3887
  %8 = icmp eq i1 %7, false, !insn.addr !3888
  store i64 %0, i64* %storemerge1.reg2mem, !insn.addr !3889
  br i1 %8, label %dec_label_pc_ed6a, label %dec_label_pc_edef, !insn.addr !3889

dec_label_pc_ed6a:                                ; preds = %dec_label_pc_ed12
  %9 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE20isReferenceToStorageEPKv(i64* %arg1, i64* %arg2), !insn.addr !3890
  %10 = urem i64 %9, 256, !insn.addr !3891
  %11 = icmp eq i64 %10, 0, !insn.addr !3892
  %12 = icmp eq i1 %11, false, !insn.addr !3893
  %13 = icmp eq i1 %12, false, !insn.addr !3894
  br i1 %13, label %dec_label_pc_edb8.thread, label %dec_label_pc_edd1, !insn.addr !3895

dec_label_pc_edb8.thread:                         ; preds = %dec_label_pc_ed6a
  %14 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm(i64* %arg1, i64 %2), !insn.addr !3896
  store i64 %0, i64* %storemerge1.reg2mem
  br label %dec_label_pc_edef

dec_label_pc_edd1:                                ; preds = %dec_label_pc_ed6a
  %15 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %arg1), !insn.addr !3897
  %16 = sub i64 %0, %15, !insn.addr !3898
  %17 = and i64 %16, -32
  %18 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm(i64* %arg1, i64 %2), !insn.addr !3896
  %19 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %arg1), !insn.addr !3899
  %20 = add i64 %19, %17, !insn.addr !3900
  store i64 %20, i64* %storemerge1.reg2mem, !insn.addr !3901
  br label %dec_label_pc_edef, !insn.addr !3901

dec_label_pc_edef:                                ; preds = %dec_label_pc_edb8.thread, %dec_label_pc_ed12, %dec_label_pc_edd1
  %storemerge1.reload = load i64, i64* %storemerge1.reg2mem
  %21 = inttoptr i64 %storemerge1.reload to i64*, !insn.addr !3902
  ret i64* %21, !insn.addr !3902

; uselistorder directives
  uselistorder i64 %2, { 1, 0, 2 }
  uselistorder i64 %0, { 2, 0, 1 }
  uselistorder i64* %storemerge1.reg2mem, { 0, 3, 1, 2 }
  uselistorder i64 (i64*, i64)* @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm, { 1, 0 }
  uselistorder i64* %arg1, { 1, 2, 3, 0, 4, 5, 6 }
  uselistorder label %dec_label_pc_edef, { 2, 0, 1 }
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_edf2:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !3903
}

define i64 @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv(i64* %result) local_unnamed_addr {
dec_label_pc_ee08:
  %0 = call i64 @_ZNKSt14_Function_base8_M_emptyEv(i64* %result), !insn.addr !3904
  %1 = and i64 %0, 4294967295, !insn.addr !3905
  %2 = xor i64 %1, 1, !insn.addr !3905
  ret i64 %2, !insn.addr !3906

; uselistorder directives
  uselistorder i64 4294967295, { 3, 4, 5, 6, 1, 7, 8, 0, 9, 2, 10, 11 }
}

define i64 @_ZN4llvm13isa_impl_wrapINS_11GlobalAliasEKPNS_5ValueEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_ee29:
  %rax.0.reg2mem = alloca i64, !insn.addr !3907
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3908
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_5ValueEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3909
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3910
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3911
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_11GlobalAliasEPKNS_5ValueES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3911
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3912
  %5 = icmp eq i64 %0, %4, !insn.addr !3912
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3913
  br i1 %5, label %dec_label_pc_ee78, label %dec_label_pc_ee73, !insn.addr !3913

dec_label_pc_ee73:                                ; preds = %dec_label_pc_ee29
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3914
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3914
  br label %dec_label_pc_ee78, !insn.addr !3914

dec_label_pc_ee78:                                ; preds = %dec_label_pc_ee73, %dec_label_pc_ee29
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3915

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm13simplify_typeIKPNS_5ValueEE18getSimplifiedValueERS3_, { 0, 2, 1, 3 }
}

define i64 @_ZN4llvm16cast_convert_valINS_11GlobalAliasEPNS_5ValueES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_ee7a:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3916
}

define i64 @_ZN4llvm13isa_impl_wrapINS_11IntegerTypeEKPNS_4TypeEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_ee8c:
  %rax.0.reg2mem = alloca i64, !insn.addr !3917
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3918
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_4TypeEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3919
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3920
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3921
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_11IntegerTypeEPKNS_4TypeES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3921
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3922
  %5 = icmp eq i64 %0, %4, !insn.addr !3922
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3923
  br i1 %5, label %dec_label_pc_eedb, label %dec_label_pc_eed6, !insn.addr !3923

dec_label_pc_eed6:                                ; preds = %dec_label_pc_ee8c
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3924
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3924
  br label %dec_label_pc_eedb, !insn.addr !3924

dec_label_pc_eedb:                                ; preds = %dec_label_pc_eed6, %dec_label_pc_ee8c
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3925

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm13simplify_typeIKPNS_4TypeEE18getSimplifiedValueERS3_, { 0, 2, 1 }
}

define i64 @_ZN4llvm13simplify_typeIKPNS_8CallBaseEE18getSimplifiedValueERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_eedd:
  %0 = call i64 @_ZN4llvm13simplify_typeIPNS_8CallBaseEE18getSimplifiedValueERS2_(i64** %arg1), !insn.addr !3926
  %1 = inttoptr i64 %0 to i64*, !insn.addr !3927
  %2 = load i64, i64* %1, align 8, !insn.addr !3927
  ret i64 %2, !insn.addr !3928
}

define i64 @_ZN4llvm14CastIsPossibleINS_16DbgInfoIntrinsicEPKNS_8CallBaseEvE10isPossibleERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_eefe:
  %0 = call i64 @_ZN4llvm13isa_impl_wrapINS_16DbgInfoIntrinsicEKPKNS_8CallBaseES4_E4doitERS5_(i64** %arg1), !insn.addr !3929
  ret i64 %0, !insn.addr !3930
}

define i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_10BasicBlockELb0ELb0EvLb0EvEEEENT_7pointerEPNS_15ilist_node_implIS6_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_ef1c:
  %0 = ptrtoint i64* %arg1 to i64
  %1 = icmp eq i64* %arg1, null, !insn.addr !3931
  %2 = add i64 %0, -24
  %storemerge = select i1 %1, i64 0, i64 %2
  ret i64 %storemerge, !insn.addr !3932
}

define i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0ENS_10BasicBlockEEELb0EE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_ef40:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !3933
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3933
  %3 = load i64, i64* %2, align 8, !insn.addr !3933
  ret i64 %3, !insn.addr !3934
}

define i64 @_ZN4llvm12ilist_detail10NodeAccess11getValuePtrINS0_12node_optionsINS_11InstructionELb0ELb0EvLb1ENS_10BasicBlockEEEEENT_7pointerEPNS_15ilist_node_implIS7_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_ef56:
  %0 = ptrtoint i64* %arg1 to i64
  %1 = icmp eq i64* %arg1, null, !insn.addr !3935
  %2 = add i64 %0, -24
  %storemerge = select i1 %1, i64 0, i64 %2
  ret i64 %storemerge, !insn.addr !3936
}

define i64** @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE32reserveForParamAndGetAddressImplINS_23SmallVectorTemplateBaseIS2_Lb1EEEEEPKS2_PT_RS7_m(i64* %arg1, i64** %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_ef7a:
  %0 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %arg1), !insn.addr !3937
  %1 = add i64 %0, %arg3, !insn.addr !3938
  %2 = call i64 @_ZNK4llvm15SmallVectorBaseIjE8capacityEv(i64* %arg1), !insn.addr !3939
  %3 = icmp ult i64 %2, %1, !insn.addr !3940
  %4 = icmp eq i1 %3, false, !insn.addr !3941
  %5 = icmp eq i1 %4, false, !insn.addr !3942
  %6 = icmp eq i1 %5, false, !insn.addr !3943
  %7 = icmp eq i1 %6, false, !insn.addr !3944
  br i1 %7, label %dec_label_pc_efcf, label %dec_label_pc_f012, !insn.addr !3945

dec_label_pc_efcf:                                ; preds = %dec_label_pc_ef7a
  %8 = call i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE4growEm(i64* %arg1, i64 %1), !insn.addr !3946
  br label %dec_label_pc_f012, !insn.addr !3947

dec_label_pc_f012:                                ; preds = %dec_label_pc_ef7a, %dec_label_pc_efcf
  ret i64** %arg2, !insn.addr !3948

; uselistorder directives
  uselistorder label %dec_label_pc_f012, { 1, 0 }
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8CallBaseEKPNS_11InstructionEPKS2_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f014:
  %rax.0.reg2mem = alloca i64, !insn.addr !3949
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !3950
  %1 = call i64 @_ZN4llvm13simplify_typeIKPNS_11InstructionEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !3951
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !3952
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !3953
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_8CallBaseEPKNS_11InstructionES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !3953
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !3954
  %5 = icmp eq i64 %0, %4, !insn.addr !3954
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !3955
  br i1 %5, label %dec_label_pc_f063, label %dec_label_pc_f05e, !insn.addr !3955

dec_label_pc_f05e:                                ; preds = %dec_label_pc_f014
  %6 = call i64 @__stack_chk_fail(), !insn.addr !3956
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !3956
  br label %dec_label_pc_f063, !insn.addr !3956

dec_label_pc_f063:                                ; preds = %dec_label_pc_f05e, %dec_label_pc_f014
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !3957

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm13simplify_typeIKPNS_11InstructionEE18getSimplifiedValueERS3_, { 3, 2, 1, 0 }
}

define i64 @_ZN4llvm16cast_convert_valINS_8CallBaseEPNS_11InstructionES3_E4doitEPKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_f065:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !3958
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_f078:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = call i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1ILb1ELb1EEEv(i64* %result), !insn.addr !3959
  %2 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %result), !insn.addr !3960
  %3 = inttoptr i64 %2 to i64*, !insn.addr !3961
  store i64 %0, i64* %3, align 8, !insn.addr !3961
  ret i64 %2, !insn.addr !3962

; uselistorder directives
  uselistorder i64 %2, { 1, 0 }
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %result) local_unnamed_addr {
dec_label_pc_f0b4:
  %0 = call i64* @_ZSt3getILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %result), !insn.addr !3963
  %1 = ptrtoint i64* %0 to i64, !insn.addr !3963
  ret i64 %1, !insn.addr !3964
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE11get_deleterEv(i64* %result) local_unnamed_addr {
dec_label_pc_f0d2:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE10_M_deleterEv(i64* %result), !insn.addr !3965
  ret i64 %0, !insn.addr !3966
}

define i64* @_ZSt4moveIRPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEONSt16remove_referenceIT_E4typeEOSA_(i64*** %arg1) local_unnamed_addr {
dec_label_pc_f0f0:
  %0 = bitcast i64*** %arg1 to i64*, !insn.addr !3967
  ret i64* %0, !insn.addr !3967
}

define i64 @_ZNKSt14default_deleteIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEEclEPS6_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_f102:
  %0 = ptrtoint i64* %arg2 to i64
  ret i64 %0, !insn.addr !3968
}

define i64* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f131:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !3969
  ret i64* %0, !insn.addr !3969
}

define i64* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12emplace_backIJSA_EEERSA_DpOT_(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_f144:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !3970
  %2 = inttoptr i64 %1 to i64*, !insn.addr !3970
  %3 = load i64, i64* %2, align 8, !insn.addr !3970
  %4 = add i64 %0, 16, !insn.addr !3971
  %5 = inttoptr i64 %4 to i64*, !insn.addr !3971
  %6 = load i64, i64* %5, align 8, !insn.addr !3971
  %7 = icmp eq i64 %3, %6, !insn.addr !3972
  %8 = inttoptr i64 %arg2 to i64*
  %9 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %8)
  br i1 %7, label %dec_label_pc_f1f9, label %dec_label_pc_f172, !insn.addr !3973

dec_label_pc_f172:                                ; preds = %dec_label_pc_f144
  %10 = load i64, i64* %2, align 8, !insn.addr !3974
  %11 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %9), !insn.addr !3975
  %12 = inttoptr i64 %10 to i64*, !insn.addr !3976
  %13 = call i64 @_ZnwmPv(i64 8, i64* %12), !insn.addr !3976
  %14 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %11), !insn.addr !3977
  %15 = inttoptr i64 %13 to i64*, !insn.addr !3978
  %16 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %15, i64* %14), !insn.addr !3978
  %17 = load i64, i64* %2, align 8, !insn.addr !3979
  %18 = add i64 %17, 8, !insn.addr !3980
  store i64 %18, i64* %2, align 8, !insn.addr !3981
  br label %dec_label_pc_f229, !insn.addr !3982

dec_label_pc_f1f9:                                ; preds = %dec_label_pc_f144
  %19 = ptrtoint i64* %9 to i64, !insn.addr !3983
  %20 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv(i64* %result), !insn.addr !3984
  call void @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE17_M_realloc_insertIJSA_EEEvN9__gnu_cxx17__normal_iteratorIPSA_SC_EEDpOT_(i64* %result, i64 %20, i64 %19), !insn.addr !3985
  br label %dec_label_pc_f229, !insn.addr !3985

dec_label_pc_f229:                                ; preds = %dec_label_pc_f1f9, %dec_label_pc_f172
  %21 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4backEv(i64* %result), !insn.addr !3986
  %22 = inttoptr i64 %21 to i64*, !insn.addr !3987
  ret i64* %22, !insn.addr !3987

; uselistorder directives
  uselistorder i64* %9, { 1, 0 }
  uselistorder i64* %2, { 1, 0, 2, 3 }
  uselistorder i64* %result, { 2, 0, 1, 3 }
}

define i64** @_ZSt7forwardIRN4llvm11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS2_JEEEJEEEEOT_RNSt16remove_referenceIS7_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_f23b:
  %0 = bitcast i64* %arg1 to i64**, !insn.addr !3988
  ret i64** %0, !insn.addr !3988
}

define i64* @_ZSt7forwardIN4llvm8ArrayRefINS0_11PassBuilder15PipelineElementEEEEOT_RNSt16remove_referenceIS5_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_f24d:
  ret i64* %arg1, !insn.addr !3989
}

define i64 @_ZN4llvm6detail13PunnedPointerIPvEaSEl(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_f260:
  %0 = sext i32 %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !3990
  ret i64 %1, !insn.addr !3991
}

define i64 @_ZN4llvm18PointerIntPairInfoIPvLj2ENS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEEE13updatePointerElS1_(i32 %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_f281:
  %0 = call i64 @_ZN4llvm20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEE16getAsVoidPointerEPv(i64* %arg2), !insn.addr !3992
  %1 = urem i64 %0, 4, !insn.addr !3993
  %2 = icmp eq i64 %1, 0, !insn.addr !3994
  br i1 %2, label %dec_label_pc_f2d9, label %dec_label_pc_f2b1, !insn.addr !3995

dec_label_pc_f2b1:                                ; preds = %dec_label_pc_f281
  %3 = call i64 @__assert_fail(i64 ptrtoint ([74 x i8]* @global_var_7434 to i64), i64 ptrtoint ([47 x i8]* @global_var_7404 to i64), i64 202, i64 ptrtoint ([305 x i8]* @global_var_72cc to i64)), !insn.addr !3996
  br label %dec_label_pc_f2d9, !insn.addr !3996

dec_label_pc_f2d9:                                ; preds = %dec_label_pc_f2b1, %dec_label_pc_f281
  %4 = urem i32 %arg1, 4, !insn.addr !3997
  %5 = zext i32 %4 to i64, !insn.addr !3997
  %6 = or i64 %0, %5, !insn.addr !3998
  ret i64 %6, !insn.addr !3999

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64 4, { 0, 4, 3, 2, 1 }
}

define i64 @_ZN4llvm18PointerIntPairInfoIPvLj2ENS_20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEEEE9updateIntEll(i32 %arg1, i32 %arg2) local_unnamed_addr {
dec_label_pc_f2ec:
  %0 = icmp ult i32 %arg2, 4
  br i1 %0, label %dec_label_pc_f332, label %dec_label_pc_f30a, !insn.addr !4000

dec_label_pc_f30a:                                ; preds = %dec_label_pc_f2ec
  %1 = call i64 @__assert_fail(i64 ptrtoint ([55 x i8]* @global_var_75b4 to i64), i64 ptrtoint ([47 x i8]* @global_var_7404 to i64), i64 209, i64 ptrtoint ([301 x i8]* @global_var_7484 to i64)), !insn.addr !4001
  br label %dec_label_pc_f332, !insn.addr !4001

dec_label_pc_f332:                                ; preds = %dec_label_pc_f30a, %dec_label_pc_f2ec
  %2 = and i32 %arg1, -4
  %3 = or i32 %2, %arg2
  %4 = sext i32 %3 to i64, !insn.addr !4002
  ret i64 %4, !insn.addr !4003

; uselistorder directives
  uselistorder i32 4, { 5, 3, 6, 4, 0, 1, 2 }
}

define i64 @_ZN4llvm14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEppEv(i64* %result) local_unnamed_addr {
dec_label_pc_f346:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE7getNextEv(i64* %result), !insn.addr !4004
  store i64 %1, i64* %result, align 8, !insn.addr !4005
  ret i64 %0, !insn.addr !4006
}

define i64 @_ZN4llvm11isa_impl_clINS_17DbgVariableRecordEKNS_9DbgRecordEE4doitERS3_(i64* %arg1) local_unnamed_addr {
dec_label_pc_f372:
  %0 = call i64 @_ZN4llvm8isa_implINS_17DbgVariableRecordENS_9DbgRecordEvE4doitERKS2_(i64* %arg1), !insn.addr !4007
  ret i64 %0, !insn.addr !4008
}

define i64 @_ZN4llvm13isa_impl_wrapINS_5ValueEKPKS1_S3_E4doitERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f390:
  %rax.0.reg2mem = alloca i64, !insn.addr !4009
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4010
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !4011
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !4012
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !4013
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_5ValueEPKS1_S3_E4doitERKS3_(i64** nonnull %2), !insn.addr !4013
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !4014
  %5 = icmp eq i64 %0, %4, !insn.addr !4014
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !4015
  br i1 %5, label %dec_label_pc_f3df, label %dec_label_pc_f3da, !insn.addr !4015

dec_label_pc_f3da:                                ; preds = %dec_label_pc_f390
  %6 = call i64 @__stack_chk_fail(), !insn.addr !4016
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !4016
  br label %dec_label_pc_f3df, !insn.addr !4016

dec_label_pc_f3df:                                ; preds = %dec_label_pc_f3da, %dec_label_pc_f390
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4017
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8FunctionEPKNS_5ValueES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f3e1:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4018
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_8FunctionEPKNS_5ValueEE4doitES4_(i64* %0), !insn.addr !4018
  ret i64 %1, !insn.addr !4019
}

define i64 @_ZN4llvm13isa_impl_wrapINS_11InstructionEPKNS_5ValueES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f402:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4020
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_11InstructionEPKNS_5ValueEE4doitES4_(i64* %0), !insn.addr !4020
  ret i64 %1, !insn.addr !4021
}

define i64 @_ZN4llvm13isa_impl_wrapINS_10StructTypeEPKNS_4TypeES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f423:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4022
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_10StructTypeEPKNS_4TypeEE4doitES4_(i64* %0), !insn.addr !4022
  ret i64 %1, !insn.addr !4023
}

define i64 @_ZN4llvm13isa_impl_wrapINS_9ArrayTypeEPKNS_4TypeES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f444:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4024
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_9ArrayTypeEPKNS_4TypeEE4doitES4_(i64* %0), !insn.addr !4024
  ret i64 %1, !insn.addr !4025
}

define i64 @_ZN4llvm13simplify_typeIKPKNS_11InstructionEE18getSimplifiedValueERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f465:
  %0 = call i64 @_ZN4llvm13simplify_typeIPKNS_11InstructionEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !4026
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4027
  %2 = load i64, i64* %1, align 8, !insn.addr !4027
  ret i64 %2, !insn.addr !4028
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8LoadInstEPKNS_11InstructionES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f486:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4029
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_8LoadInstEPKNS_11InstructionEE4doitES4_(i64* %0), !insn.addr !4029
  ret i64 %1, !insn.addr !4030
}

define i64 @_ZN4llvm13isa_impl_wrapINS_9StoreInstEPKNS_11InstructionES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f4a7:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4031
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_9StoreInstEPKNS_11InstructionEE4doitES4_(i64* %0), !insn.addr !4031
  ret i64 %1, !insn.addr !4032
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvEC1Em(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_f4c8:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE10getFirstElEv(i64* %result), !insn.addr !4033
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4034
  %2 = call i64 @_ZN4llvm15SmallVectorBaseIjEC2EPvm(i64* %result, i64* %1, i64 %arg2), !insn.addr !4034
  ret i64 %2, !insn.addr !4035

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE10getFirstElEv, { 1, 0 }
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt4pairIjPNS_6MDNodeEEvE10getFirstElEv(i64* %result) local_unnamed_addr {
dec_label_pc_f50a:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !4036
  ret i64 %1, !insn.addr !4037
}

define i64 @_ZN4llvm13isa_impl_wrapINS_14FPMathOperatorEKPKNS_11InstructionES4_E4doitERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f520:
  %rax.0.reg2mem = alloca i64, !insn.addr !4038
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4039
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_11InstructionEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !4040
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !4041
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !4042
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_14FPMathOperatorEPKNS_11InstructionES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !4042
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !4043
  %5 = icmp eq i64 %0, %4, !insn.addr !4043
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !4044
  br i1 %5, label %dec_label_pc_f56f, label %dec_label_pc_f56a, !insn.addr !4044

dec_label_pc_f56a:                                ; preds = %dec_label_pc_f520
  %6 = call i64 @__stack_chk_fail(), !insn.addr !4045
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !4045
  br label %dec_label_pc_f56f, !insn.addr !4045

dec_label_pc_f56f:                                ; preds = %dec_label_pc_f56a, %dec_label_pc_f520
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4046
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8FunctionEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f571:
  %rax.0.reg2mem = alloca i64, !insn.addr !4047
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4048
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !4049
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !4050
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !4051
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_8FunctionEPKNS_5ValueES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !4051
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !4052
  %5 = icmp eq i64 %0, %4, !insn.addr !4052
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !4053
  br i1 %5, label %dec_label_pc_f5c0, label %dec_label_pc_f5bb, !insn.addr !4053

dec_label_pc_f5bb:                                ; preds = %dec_label_pc_f571
  %6 = call i64 @__stack_chk_fail(), !insn.addr !4054
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !4054
  br label %dec_label_pc_f5c0, !insn.addr !4054

dec_label_pc_f5c0:                                ; preds = %dec_label_pc_f5bb, %dec_label_pc_f571
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4055
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8CallInstEKPKNS_5ValueES4_E4doitERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f5c2:
  %rax.0.reg2mem = alloca i64, !insn.addr !4056
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4057
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !4058
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !4059
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !4060
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_8CallInstEPKNS_5ValueES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !4060
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !4061
  %5 = icmp eq i64 %0, %4, !insn.addr !4061
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !4062
  br i1 %5, label %dec_label_pc_f611, label %dec_label_pc_f60c, !insn.addr !4062

dec_label_pc_f60c:                                ; preds = %dec_label_pc_f5c2
  %6 = call i64 @__stack_chk_fail(), !insn.addr !4063
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !4063
  br label %dec_label_pc_f611, !insn.addr !4063

dec_label_pc_f611:                                ; preds = %dec_label_pc_f60c, %dec_label_pc_f5c2
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4064

; uselistorder directives
  uselistorder i64 (i64**)* @_ZN4llvm13simplify_typeIKPKNS_5ValueEE18getSimplifiedValueERS4_, { 5, 3, 7, 2, 0, 1, 4, 6 }
}

define i64 @_ZN4llvm13isa_impl_wrapINS_13IntrinsicInstEPKNS_5ValueES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f613:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4065
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_13IntrinsicInstEPKNS_5ValueEE4doitES4_(i64* %0), !insn.addr !4065
  ret i64 %1, !insn.addr !4066
}

define i64 @_ZNKSt4lessIPKvEclES1_S1_(i64* %result, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_f634:
  %0 = call i64 @_ZSt23__is_constant_evaluatedv(), !insn.addr !4067
  %1 = trunc i64 %0 to i8, !insn.addr !4068
  %2 = icmp eq i8 %1, 0, !insn.addr !4068
  %3 = icmp ult i64* %arg2, %arg3
  %4 = zext i1 %3 to i64
  %storemerge.v.v.v = select i1 %2, i64* %arg3, i64* %arg2
  %storemerge.v.v = ptrtoint i64* %storemerge.v.v.v to i64
  %storemerge.v = and i64 %storemerge.v.v, -256
  %storemerge = or i64 %storemerge.v, %4
  ret i64 %storemerge, !insn.addr !4069

; uselistorder directives
  uselistorder i64 ()* @_ZSt23__is_constant_evaluatedv, { 6, 4, 3, 2, 0, 1, 5 }
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvEC1Em(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_f672:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE10getFirstElEv(i64* %result), !insn.addr !4070
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4071
  %2 = call i64 @_ZN4llvm15SmallVectorBaseIjEC2EPvm(i64* %result, i64* %1, i64 %arg2), !insn.addr !4071
  ret i64 %2, !insn.addr !4072

; uselistorder directives
  uselistorder i64 (i64*, i64*, i64)* @_ZN4llvm15SmallVectorBaseIjEC2EPvm, { 1, 0 }
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE10getFirstElEv(i64* %result) local_unnamed_addr {
dec_label_pc_f6b4:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !4073
  ret i64 %1, !insn.addr !4074
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE20isReferenceToStorageEPKv(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_f6ca:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !4075
  %1 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !4076
  %2 = inttoptr i64 %1 to i64*, !insn.addr !4077
  %3 = inttoptr i64 %0 to i64*, !insn.addr !4077
  %4 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE18isReferenceToRangeEPKvSH_SH_(i64* %result, i64* %arg2, i64* %2, i64* %3), !insn.addr !4077
  ret i64 %4, !insn.addr !4078
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE4growEm(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_f716:
  %rax.0.reg2mem = alloca i64, !insn.addr !4079
  %stack_var_-32 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4080
  %1 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13mallocForGrowEmRm(i64* %result, i64 %arg2, i64* nonnull %stack_var_-32), !insn.addr !4081
  %2 = inttoptr i64 %1 to i64*, !insn.addr !4082
  %3 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE19moveElementsForGrowEPSE_(i64* %result, i64* %2), !insn.addr !4082
  %4 = load i64, i64* %stack_var_-32, align 8, !insn.addr !4083
  %5 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE21takeAllocationForGrowEPSE_m(i64* %result, i64* %2, i64 %4), !insn.addr !4084
  %6 = call i64 @__readfsqword(i64 40), !insn.addr !4085
  %7 = icmp eq i64 %0, %6, !insn.addr !4085
  store i64 0, i64* %rax.0.reg2mem, !insn.addr !4086
  br i1 %7, label %dec_label_pc_f793, label %dec_label_pc_f78e, !insn.addr !4086

dec_label_pc_f78e:                                ; preds = %dec_label_pc_f716
  %8 = call i64 @__stack_chk_fail(), !insn.addr !4087
  store i64 %8, i64* %rax.0.reg2mem, !insn.addr !4087
  br label %dec_label_pc_f793, !insn.addr !4087

dec_label_pc_f793:                                ; preds = %dec_label_pc_f78e, %dec_label_pc_f716
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4088

; uselistorder directives
  uselistorder i64* %stack_var_-32, { 1, 0 }
}

define i64 @_ZN4llvm13isa_impl_wrapINS_11GlobalAliasEPKNS_5ValueES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f795:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4089
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_11GlobalAliasEPKNS_5ValueEE4doitES4_(i64* %0), !insn.addr !4089
  ret i64 %1, !insn.addr !4090
}

define i64 @_ZN4llvm13isa_impl_wrapINS_11IntegerTypeEPKNS_4TypeES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f7b6:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4091
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_11IntegerTypeEPKNS_4TypeEE4doitES4_(i64* %0), !insn.addr !4091
  ret i64 %1, !insn.addr !4092
}

define i64 @_ZN4llvm13simplify_typeIPNS_8CallBaseEE18getSimplifiedValueERS2_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f7d7:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !4093
}

define i64 @_ZN4llvm13isa_impl_wrapINS_16DbgInfoIntrinsicEKPKNS_8CallBaseES4_E4doitERS5_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f7e9:
  %rax.0.reg2mem = alloca i64, !insn.addr !4094
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4095
  %1 = call i64 @_ZN4llvm13simplify_typeIKPKNS_8CallBaseEE18getSimplifiedValueERS4_(i64** %arg1), !insn.addr !4096
  store i64 %1, i64* %stack_var_-24, align 8, !insn.addr !4097
  %2 = bitcast i64* %stack_var_-24 to i64**, !insn.addr !4098
  %3 = call i64 @_ZN4llvm13isa_impl_wrapINS_16DbgInfoIntrinsicEPKNS_8CallBaseES4_E4doitERKS4_(i64** nonnull %2), !insn.addr !4098
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !4099
  %5 = icmp eq i64 %0, %4, !insn.addr !4099
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !4100
  br i1 %5, label %dec_label_pc_f838, label %dec_label_pc_f833, !insn.addr !4100

dec_label_pc_f833:                                ; preds = %dec_label_pc_f7e9
  %6 = call i64 @__stack_chk_fail(), !insn.addr !4101
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !4101
  br label %dec_label_pc_f838, !insn.addr !4101

dec_label_pc_f838:                                ; preds = %dec_label_pc_f833, %dec_label_pc_f7e9
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4102
}

define i32* @_ZSt3maxIiERKT_S2_S2_(i32* %arg1, i32* %arg2) local_unnamed_addr {
dec_label_pc_f83a:
  %0 = alloca i64
  %1 = load i64, i64* %0
  %2 = load i64, i64* %0
  %3 = trunc i64 %1 to i32
  %4 = trunc i64 %2 to i32
  %5 = icmp ult i32 %3, %4, !insn.addr !4103
  %storemerge.in = select i1 %5, i32* %arg2, i32* %arg1
  ret i32* %storemerge.in, !insn.addr !4104

; uselistorder directives
  uselistorder i64* %0, { 1, 0 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseIPNS_11InstructionELb1EE4growEm(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_f866:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE8grow_podEmm(i64* %result, i64 %arg2, i64 8), !insn.addr !4105
  ret i64 %0, !insn.addr !4106
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8CallBaseEPKNS_11InstructionES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_f895:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4107
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_8CallBaseEPKNS_11InstructionEE4doitES4_(i64* %0), !insn.addr !4107
  ret i64 %1, !insn.addr !4108
}

define i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1ILb1ELb1EEEv(i64* %result) local_unnamed_addr {
dec_label_pc_f8b6:
  %0 = call i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1Ev(i64* %result), !insn.addr !4109
  ret i64 %0, !insn.addr !4110
}

define i64* @_ZSt3getILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %arg1) local_unnamed_addr {
dec_label_pc_f8d5:
  %0 = call i64** @_ZSt12__get_helperILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEJSt14default_deleteIS6_EEERT0_RSt11_Tuple_implIXT_EJSA_DpT1_EE(i64* %arg1), !insn.addr !4111
  %1 = bitcast i64** %0 to i64*, !insn.addr !4112
  ret i64* %1, !insn.addr !4112
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE10_M_deleterEv(i64* %result) local_unnamed_addr {
dec_label_pc_f8f4:
  %0 = call i64* @_ZSt3getILm1EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %result), !insn.addr !4113
  %1 = ptrtoint i64* %0 to i64, !insn.addr !4113
  ret i64 %1, !insn.addr !4114
}

define i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_f912:
  ret i64* %arg1, !insn.addr !4115
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_f924:
  %rax.0.reg2mem = alloca i64, !insn.addr !4116
  %0 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !4117
  %2 = add i64 %0, 8, !insn.addr !4118
  %3 = inttoptr i64 %2 to i64**, !insn.addr !4119
  %4 = call i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* nonnull %stack_var_-24, i64** %3), !insn.addr !4119
  %5 = load i64, i64* %stack_var_-24, align 8, !insn.addr !4120
  %6 = call i64 @__readfsqword(i64 40), !insn.addr !4121
  %7 = icmp eq i64 %1, %6, !insn.addr !4121
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !4122
  br i1 %7, label %dec_label_pc_f972, label %dec_label_pc_f96d, !insn.addr !4122

dec_label_pc_f96d:                                ; preds = %dec_label_pc_f924
  %8 = call i64 @__stack_chk_fail(), !insn.addr !4123
  store i64 %8, i64* %rax.0.reg2mem, !insn.addr !4123
  br label %dec_label_pc_f972, !insn.addr !4123

dec_label_pc_f972:                                ; preds = %dec_label_pc_f96d, %dec_label_pc_f924
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4124

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
}

define void @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE17_M_realloc_insertIJSA_EEEvN9__gnu_cxx17__normal_iteratorIPSA_SC_EEDpOT_(i64* %result, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_f974:
  %0 = ptrtoint i64* %result to i64
  %stack_var_-136 = alloca i64, align 8
  %stack_var_-152 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-152, align 8, !insn.addr !4125
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !4126
  %2 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12_M_check_lenEmPKc(i64* %result, i64 1, i8* getelementptr inbounds ([26 x i8], [26 x i8]* @global_var_795c, i64 0, i64 0)), !insn.addr !4127
  %3 = add i64 %0, 8, !insn.addr !4128
  %4 = inttoptr i64 %3 to i64*, !insn.addr !4128
  %5 = load i64, i64* %4, align 8, !insn.addr !4128
  %6 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE5beginEv(i64* %result), !insn.addr !4129
  store i64 %6, i64* %stack_var_-136, align 8, !insn.addr !4130
  %7 = call i64 @_ZN9__gnu_cxxmiIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKSJ_SM_(i64* nonnull %stack_var_-152, i64* nonnull %stack_var_-136), !insn.addr !4131
  %8 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_M_allocateEm(i64* %result, i64 %2), !insn.addr !4132
  %9 = inttoptr i64 %arg3 to i64*, !insn.addr !4133
  %10 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %9), !insn.addr !4133
  %11 = mul i64 %7, 8, !insn.addr !4134
  %12 = add i64 %11, %8, !insn.addr !4135
  %13 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %10), !insn.addr !4136
  %14 = inttoptr i64 %12 to i64*, !insn.addr !4137
  %15 = call i64 @_ZnwmPv(i64 8, i64* %14), !insn.addr !4137
  %16 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %13), !insn.addr !4138
  %17 = inttoptr i64 %15 to i64*, !insn.addr !4139
  %18 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %17, i64* %16), !insn.addr !4139
  %19 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result), !insn.addr !4140
  %20 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* nonnull %stack_var_-152), !insn.addr !4141
  %21 = inttoptr i64 %20 to i64*, !insn.addr !4142
  %22 = load i64, i64* %21, align 8, !insn.addr !4142
  %23 = inttoptr i64 %22 to i64*, !insn.addr !4143
  %24 = inttoptr i64 %8 to i64*, !insn.addr !4143
  %25 = inttoptr i64 %19 to i64*, !insn.addr !4143
  %26 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_(i64* %result, i64* %23, i64* %24, i64* %25), !insn.addr !4143
  %27 = add i64 %26, 8, !insn.addr !4144
  %28 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result), !insn.addr !4145
  %29 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* nonnull %stack_var_-152), !insn.addr !4146
  %30 = inttoptr i64 %29 to i64*, !insn.addr !4147
  %31 = load i64, i64* %30, align 8, !insn.addr !4147
  %32 = inttoptr i64 %31 to i64*, !insn.addr !4148
  %33 = inttoptr i64 %5 to i64*, !insn.addr !4148
  %34 = inttoptr i64 %27 to i64*, !insn.addr !4148
  %35 = inttoptr i64 %28 to i64*, !insn.addr !4148
  %36 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_(i64* %32, i64* %33, i64* %34, i64* %35), !insn.addr !4148
  %37 = add i64 %0, 16, !insn.addr !4149
  %38 = inttoptr i64 %37 to i64*, !insn.addr !4149
  %39 = load i64, i64* %38, align 8, !insn.addr !4149
  %40 = sub i64 %39, %0, !insn.addr !4150
  %41 = ashr i64 %40, 3, !insn.addr !4151
  %42 = call i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE13_M_deallocateEPSA_m(i64* %result, i64* %result, i64 %41), !insn.addr !4152
  store i64 %8, i64* %result, align 8, !insn.addr !4153
  store i64 %36, i64* %4, align 8, !insn.addr !4154
  %43 = mul i64 %2, 8, !insn.addr !4155
  %44 = add i64 %8, %43, !insn.addr !4156
  store i64 %44, i64* %38, align 8, !insn.addr !4157
  %45 = call i64 @__readfsqword(i64 40), !insn.addr !4158
  %46 = icmp eq i64 %1, %45, !insn.addr !4158
  br i1 %46, label %dec_label_pc_fbb1, label %dec_label_pc_fbac, !insn.addr !4159

dec_label_pc_fbac:                                ; preds = %dec_label_pc_f974
  %47 = call i64 @__stack_chk_fail(), !insn.addr !4160
  br label %dec_label_pc_fbb1, !insn.addr !4160

dec_label_pc_fbb1:                                ; preds = %dec_label_pc_fbac, %dec_label_pc_f974
  ret void, !insn.addr !4161

; uselistorder directives
  uselistorder i64 %0, { 2, 0, 1 }
  uselistorder i64 (i64*, i64*, i64*, i64*)* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv, { 1, 0 }
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4backEv(i64* %result) local_unnamed_addr {
dec_label_pc_fbb8:
  %rax.0.reg2mem = alloca i64, !insn.addr !4162
  %stack_var_-24 = alloca i64, align 8
  %stack_var_-32 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4163
  %1 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv(i64* %result), !insn.addr !4164
  store i64 %1, i64* %stack_var_-32, align 8, !insn.addr !4165
  %2 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEmiEl(i64* nonnull %stack_var_-32, i32 1), !insn.addr !4166
  store i64 %2, i64* %stack_var_-24, align 8, !insn.addr !4167
  %3 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEdeEv(i64* nonnull %stack_var_-24), !insn.addr !4168
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !4169
  %5 = icmp eq i64 %0, %4, !insn.addr !4169
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !4170
  br i1 %5, label %dec_label_pc_fc1c, label %dec_label_pc_fc17, !insn.addr !4170

dec_label_pc_fc17:                                ; preds = %dec_label_pc_fbb8
  %6 = call i64 @__stack_chk_fail(), !insn.addr !4171
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !4171
  br label %dec_label_pc_fc1c, !insn.addr !4171

dec_label_pc_fc1c:                                ; preds = %dec_label_pc_fc17, %dec_label_pc_fbb8
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4172

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE3endEv, { 1, 0 }
}

define i64 @_ZN4llvm20pointer_union_detail22PointerUnionUIntTraitsIJPNS_15MetadataAsValueEPNS_8MetadataEPNS_14DebugValueUserEEE16getAsVoidPointerEPv(i64* %arg1) local_unnamed_addr {
dec_label_pc_fc1e:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !4173
}

define i64 @_ZN4llvm15ilist_node_implINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEEE7getNextEv(i64* %result) local_unnamed_addr {
dec_label_pc_fc30:
  %0 = call i64 @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getNextEv(i64* %result), !insn.addr !4174
  ret i64 %0, !insn.addr !4175

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm12ilist_detail18node_base_prevnextINS_15ilist_node_baseILb0EvEELb0EE7getNextEv, { 2, 0, 1 }
}

define i64 @_ZN4llvm8isa_implINS_17DbgVariableRecordENS_9DbgRecordEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fc4e:
  %0 = call i64 @_ZN4llvm17DbgVariableRecord7classofEPKNS_9DbgRecordE(i64* %arg1), !insn.addr !4176
  ret i64 %0, !insn.addr !4177
}

define i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_fc6c:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4178
}

define i64 @_ZNK4llvm14iterator_rangeINS_14ilist_iteratorINS_12ilist_detail12node_optionsINS_9DbgRecordELb0ELb0EvLb0EvEELb0ELb0EEEE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_fc82:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !4179
  %2 = inttoptr i64 %1 to i64*, !insn.addr !4179
  %3 = load i64, i64* %2, align 8, !insn.addr !4179
  ret i64 %3, !insn.addr !4180
}

define i64 @_ZN4llvm13isa_impl_wrapINS_5ValueEPKS1_S3_E4doitERKS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_fc98:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4181
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_5ValueEPKS1_E4doitES3_(i64* %0), !insn.addr !4181
  ret i64 %1, !insn.addr !4182
}

define i64 @_ZN4llvm11isa_impl_clINS_8FunctionEPKNS_5ValueEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fcb9:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4183
  %1 = icmp eq i1 %0, false, !insn.addr !4184
  br i1 %1, label %dec_label_pc_fcf8, label %dec_label_pc_fcd0, !insn.addr !4184

dec_label_pc_fcd0:                                ; preds = %dec_label_pc_fcb9
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([113 x i8]* @global_var_797c to i64)), !insn.addr !4185
  br label %dec_label_pc_fcf8, !insn.addr !4185

dec_label_pc_fcf8:                                ; preds = %dec_label_pc_fcd0, %dec_label_pc_fcb9
  %3 = call i64 @_ZN4llvm8isa_implINS_8FunctionENS_5ValueEvE4doitERKS2_(i64* %arg1), !insn.addr !4186
  ret i64 %3, !insn.addr !4187
}

define i64 @_ZN4llvm11isa_impl_clINS_11InstructionEPKNS_5ValueEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fd06:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4188
  %1 = icmp eq i1 %0, false, !insn.addr !4189
  br i1 %1, label %dec_label_pc_fd45, label %dec_label_pc_fd1d, !insn.addr !4189

dec_label_pc_fd1d:                                ; preds = %dec_label_pc_fd06
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([116 x i8]* @global_var_7a1c to i64)), !insn.addr !4190
  br label %dec_label_pc_fd45, !insn.addr !4190

dec_label_pc_fd45:                                ; preds = %dec_label_pc_fd1d, %dec_label_pc_fd06
  %3 = call i64 @_ZN4llvm8isa_implINS_11InstructionENS_5ValueEvE4doitERKS2_(i64* %arg1), !insn.addr !4191
  ret i64 %3, !insn.addr !4192
}

define i64 @_ZN4llvm11isa_impl_clINS_10StructTypeEPKNS_4TypeEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fd53:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4193
  %1 = icmp eq i1 %0, false, !insn.addr !4194
  br i1 %1, label %dec_label_pc_fd92, label %dec_label_pc_fd6a, !insn.addr !4194

dec_label_pc_fd6a:                                ; preds = %dec_label_pc_fd53
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([114 x i8]* @global_var_7a94 to i64)), !insn.addr !4195
  br label %dec_label_pc_fd92, !insn.addr !4195

dec_label_pc_fd92:                                ; preds = %dec_label_pc_fd6a, %dec_label_pc_fd53
  %3 = call i64 @_ZN4llvm8isa_implINS_10StructTypeENS_4TypeEvE4doitERKS2_(i64* %arg1), !insn.addr !4196
  ret i64 %3, !insn.addr !4197
}

define i64 @_ZN4llvm11isa_impl_clINS_9ArrayTypeEPKNS_4TypeEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fda0:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4198
  %1 = icmp eq i1 %0, false, !insn.addr !4199
  br i1 %1, label %dec_label_pc_fddf, label %dec_label_pc_fdb7, !insn.addr !4199

dec_label_pc_fdb7:                                ; preds = %dec_label_pc_fda0
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([113 x i8]* @global_var_7b0c to i64)), !insn.addr !4200
  br label %dec_label_pc_fddf, !insn.addr !4200

dec_label_pc_fddf:                                ; preds = %dec_label_pc_fdb7, %dec_label_pc_fda0
  %3 = call i64 @_ZN4llvm8isa_implINS_9ArrayTypeENS_4TypeEvE4doitERKS2_(i64* %arg1), !insn.addr !4201
  ret i64 %3, !insn.addr !4202
}

define i64 @_ZN4llvm11isa_impl_clINS_8LoadInstEPKNS_11InstructionEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fded:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4203
  %1 = icmp eq i1 %0, false, !insn.addr !4204
  br i1 %1, label %dec_label_pc_fe2c, label %dec_label_pc_fe04, !insn.addr !4204

dec_label_pc_fe04:                                ; preds = %dec_label_pc_fded
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([119 x i8]* @global_var_7b84 to i64)), !insn.addr !4205
  br label %dec_label_pc_fe2c, !insn.addr !4205

dec_label_pc_fe2c:                                ; preds = %dec_label_pc_fe04, %dec_label_pc_fded
  %3 = call i64 @_ZN4llvm8isa_implINS_8LoadInstENS_11InstructionEvE4doitERKS2_(i64* %arg1), !insn.addr !4206
  ret i64 %3, !insn.addr !4207
}

define i64 @_ZN4llvm11isa_impl_clINS_9StoreInstEPKNS_11InstructionEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fe3a:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4208
  %1 = icmp eq i1 %0, false, !insn.addr !4209
  br i1 %1, label %dec_label_pc_fe79, label %dec_label_pc_fe51, !insn.addr !4209

dec_label_pc_fe51:                                ; preds = %dec_label_pc_fe3a
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([120 x i8]* @global_var_7bfc to i64)), !insn.addr !4210
  br label %dec_label_pc_fe79, !insn.addr !4210

dec_label_pc_fe79:                                ; preds = %dec_label_pc_fe51, %dec_label_pc_fe3a
  %3 = call i64 @_ZN4llvm8isa_implINS_9StoreInstENS_11InstructionEvE4doitERKS2_(i64* %arg1), !insn.addr !4211
  ret i64 %3, !insn.addr !4212
}

define i64 @_ZN4llvm13isa_impl_wrapINS_14FPMathOperatorEPKNS_11InstructionES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_fe87:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4213
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_14FPMathOperatorEPKNS_11InstructionEE4doitES4_(i64* %0), !insn.addr !4213
  ret i64 %1, !insn.addr !4214
}

define i64 @_ZN4llvm13isa_impl_wrapINS_8CallInstEPKNS_5ValueES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_fea8:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4215
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_8CallInstEPKNS_5ValueEE4doitES4_(i64* %0), !insn.addr !4215
  ret i64 %1, !insn.addr !4216
}

define i64 @_ZN4llvm11isa_impl_clINS_13IntrinsicInstEPKNS_5ValueEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_fec9:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4217
  %1 = icmp eq i1 %0, false, !insn.addr !4218
  br i1 %1, label %dec_label_pc_ff08, label %dec_label_pc_fee0, !insn.addr !4218

dec_label_pc_fee0:                                ; preds = %dec_label_pc_fec9
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([118 x i8]* @global_var_7c74 to i64)), !insn.addr !4219
  br label %dec_label_pc_ff08, !insn.addr !4219

dec_label_pc_ff08:                                ; preds = %dec_label_pc_fee0, %dec_label_pc_fec9
  %3 = call i64 @_ZN4llvm8isa_implINS_13IntrinsicInstENS_5ValueEvE4doitERKS2_(i64* %arg1), !insn.addr !4220
  ret i64 %3, !insn.addr !4221
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE18isReferenceToRangeEPKvSH_SH_(i64* %result, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_ff16:
  %rax.0.reg2mem = alloca i64, !insn.addr !4222
  %stack_var_-17 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4223
  %1 = call i1 @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_(i64* nonnull %stack_var_-17, i64* %arg2, i64* %arg3), !insn.addr !4224
  %2 = call i1 @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_(i64* nonnull %stack_var_-17, i64* %arg2, i64* %arg4), !insn.addr !4225
  %storemerge = zext i1 %2 to i64
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !4226
  %4 = icmp eq i64 %0, %3, !insn.addr !4226
  store i64 %storemerge, i64* %rax.0.reg2mem, !insn.addr !4227
  br i1 %4, label %dec_label_pc_ff9a, label %dec_label_pc_ff95, !insn.addr !4227

dec_label_pc_ff95:                                ; preds = %dec_label_pc_ff16
  %5 = call i64 @__stack_chk_fail(), !insn.addr !4228
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !4228
  br label %dec_label_pc_ff9a, !insn.addr !4228

dec_label_pc_ff9a:                                ; preds = %dec_label_pc_ff95, %dec_label_pc_ff16
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4229

; uselistorder directives
  uselistorder i1 (i64*, i64*, i64*)* @_ZNKSt4lessIvEclIKvS2_EEbPT_PT0_, { 1, 0 }
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_ff9c:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4230
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result) local_unnamed_addr {
dec_label_pc_ffb2:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !4231
  %1 = call i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64* %result), !insn.addr !4232
  %2 = mul i64 %1, 32, !insn.addr !4233
  %3 = add i64 %2, %0, !insn.addr !4234
  ret i64 %3, !insn.addr !4235

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm15SmallVectorBaseIjE4sizeEv, { 8, 4, 7, 6, 3, 2, 5, 0, 1 }
  uselistorder i64 (i64*)* @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv, { 1, 0 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13mallocForGrowEmRm(i64* %result, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_ffec:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv(i64* %result), !insn.addr !4236
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4237
  %2 = call i64 @_ZN4llvm15SmallVectorBaseIjE13mallocForGrowEPvmmRm(i64* %result, i64* %1, i64 %arg2, i64 32, i64* %arg3), !insn.addr !4237
  ret i64 %2, !insn.addr !4238
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE19moveElementsForGrowEPSE_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_1003a:
  %0 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !4239
  %1 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !4240
  %2 = inttoptr i64 %1 to i64*, !insn.addr !4241
  %3 = inttoptr i64 %0 to i64*, !insn.addr !4241
  call void @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE18uninitialized_moveIPSE_SH_EEvT_SI_T0_(i64* %2, i64* %3, i64* %arg2), !insn.addr !4241
  %4 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv(i64* %result), !insn.addr !4242
  %5 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !4243
  %6 = inttoptr i64 %5 to i64*, !insn.addr !4244
  %7 = inttoptr i64 %4 to i64*, !insn.addr !4244
  %8 = call i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13destroy_rangeEPSE_SG_(i64* %6, i64* %7), !insn.addr !4244
  ret i64 %8, !insn.addr !4245

; uselistorder directives
  uselistorder i64 (i64*)* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE3endEv, { 2, 1, 0 }
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE21takeAllocationForGrowEPSE_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_100ac:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE7isSmallEv(i64* %result), !insn.addr !4246
  %1 = trunc i64 %0 to i8
  %2 = icmp eq i8 %1, 1, !insn.addr !4247
  br i1 %2, label %dec_label_pc_100eb, label %dec_label_pc_100d7, !insn.addr !4248

dec_label_pc_100d7:                               ; preds = %dec_label_pc_100ac
  %3 = call i64 @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv(i64* %result), !insn.addr !4249
  %4 = call i64 @free(i64 %3), !insn.addr !4250
  br label %dec_label_pc_100eb, !insn.addr !4250

dec_label_pc_100eb:                               ; preds = %dec_label_pc_100d7, %dec_label_pc_100ac
  %5 = call i64 @_ZN4llvm15SmallVectorBaseIjE20set_allocation_rangeEPvm(i64* %result, i64* %arg2, i64 %arg3), !insn.addr !4251
  ret i64 %5, !insn.addr !4252

; uselistorder directives
  uselistorder i64 (i64)* @free, { 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZN4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE5beginEv, { 5, 4, 3, 2, 1, 0 }
  uselistorder i8 1, { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 40, 41, 17, 18, 45, 0, 42, 43, 19, 20, 21, 22, 23, 24, 25, 26, 27, 44, 28, 29, 30, 47, 31, 32, 46, 33, 34, 35, 36, 37, 38, 39 }
}

define i64 @_ZN4llvm11isa_impl_clINS_11GlobalAliasEPKNS_5ValueEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10105:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4253
  %1 = icmp eq i1 %0, false, !insn.addr !4254
  br i1 %1, label %dec_label_pc_10144, label %dec_label_pc_1011c, !insn.addr !4254

dec_label_pc_1011c:                               ; preds = %dec_label_pc_10105
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([116 x i8]* @global_var_7cec to i64)), !insn.addr !4255
  br label %dec_label_pc_10144, !insn.addr !4255

dec_label_pc_10144:                               ; preds = %dec_label_pc_1011c, %dec_label_pc_10105
  %3 = call i64 @_ZN4llvm8isa_implINS_11GlobalAliasENS_5ValueEvE4doitERKS2_(i64* %arg1), !insn.addr !4256
  ret i64 %3, !insn.addr !4257
}

define i64 @_ZN4llvm11isa_impl_clINS_11IntegerTypeEPKNS_4TypeEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10152:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4258
  %1 = icmp eq i1 %0, false, !insn.addr !4259
  br i1 %1, label %dec_label_pc_10191, label %dec_label_pc_10169, !insn.addr !4259

dec_label_pc_10169:                               ; preds = %dec_label_pc_10152
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([115 x i8]* @global_var_7d64 to i64)), !insn.addr !4260
  br label %dec_label_pc_10191, !insn.addr !4260

dec_label_pc_10191:                               ; preds = %dec_label_pc_10169, %dec_label_pc_10152
  %3 = call i64 @_ZN4llvm8isa_implINS_11IntegerTypeENS_4TypeEvE4doitERKS2_(i64* %arg1), !insn.addr !4261
  ret i64 %3, !insn.addr !4262
}

define i64 @_ZN4llvm13simplify_typeIKPKNS_8CallBaseEE18getSimplifiedValueERS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_1019f:
  %0 = call i64 @_ZN4llvm13simplify_typeIPKNS_8CallBaseEE18getSimplifiedValueERS3_(i64** %arg1), !insn.addr !4263
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4264
  %2 = load i64, i64* %1, align 8, !insn.addr !4264
  ret i64 %2, !insn.addr !4265
}

define i64 @_ZN4llvm13isa_impl_wrapINS_16DbgInfoIntrinsicEPKNS_8CallBaseES4_E4doitERKS4_(i64** %arg1) local_unnamed_addr {
dec_label_pc_101c0:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4266
  %1 = call i64 @_ZN4llvm11isa_impl_clINS_16DbgInfoIntrinsicEPKNS_8CallBaseEE4doitES4_(i64* %0), !insn.addr !4266
  ret i64 %1, !insn.addr !4267
}

define i64 @_ZN4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE8grow_podEmm(i64* %result, i64 %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_101e2:
  %0 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE10getFirstElEv(i64* %result), !insn.addr !4268
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4269
  %2 = call i64 @_ZN4llvm15SmallVectorBaseIjE8grow_podEPvmm(i64* %result, i64* %1, i64 %arg2, i64 %arg3), !insn.addr !4269
  ret i64 %2, !insn.addr !4270

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK4llvm25SmallVectorTemplateCommonIPNS_11InstructionEvE10getFirstElEv, { 2, 1, 0 }
}

define i64 @_ZN4llvm11isa_impl_clINS_8CallBaseEPKNS_11InstructionEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_1022b:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4271
  %1 = icmp eq i1 %0, false, !insn.addr !4272
  br i1 %1, label %dec_label_pc_1026a, label %dec_label_pc_10242, !insn.addr !4272

dec_label_pc_10242:                               ; preds = %dec_label_pc_1022b
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([119 x i8]* @global_var_7f6c to i64)), !insn.addr !4273
  br label %dec_label_pc_1026a, !insn.addr !4273

dec_label_pc_1026a:                               ; preds = %dec_label_pc_10242, %dec_label_pc_1022b
  %3 = call i64 @_ZN4llvm8isa_implINS_8CallBaseENS_11InstructionEvE4doitERKS2_(i64* %arg1), !insn.addr !4274
  ret i64 %3, !insn.addr !4275
}

define i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_10278:
  %0 = call i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1Ev(i64* %result), !insn.addr !4276
  %1 = call i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EEC1Ev(i64* %result), !insn.addr !4277
  ret i64 %1, !insn.addr !4278
}

define i64** @_ZSt12__get_helperILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEEJSt14default_deleteIS6_EEERT0_RSt11_Tuple_implIXT_EJSA_DpT1_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_102a3:
  %0 = call i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEE7_M_headERSA_(i64* %arg1), !insn.addr !4279
  %1 = inttoptr i64 %0 to i64**, !insn.addr !4280
  ret i64** %1, !insn.addr !4280
}

define i64* @_ZSt3getILm1EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEERNSt13tuple_elementIXT_ESt5tupleIJDpT0_EEE4typeERSE_(i64* %arg1) local_unnamed_addr {
dec_label_pc_102c1:
  %0 = call i64* @_ZSt12__get_helperILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEJEERT0_RSt11_Tuple_implIXT_EJS9_DpT1_EE(i64* %arg1), !insn.addr !4281
  ret i64* %0, !insn.addr !4282
}

define i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_102e0:
  %0 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %result, i64* %arg2), !insn.addr !4283
  ret i64 %0, !insn.addr !4284
}

define i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_1030a:
  %0 = call i64 @_ZNSt15__uniq_ptr_dataIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_ELb1ELb1EEC1EOS9_(i64* %result, i64* %arg2), !insn.addr !4285
  ret i64 %0, !insn.addr !4286
}

define i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* %result, i64** %arg2) local_unnamed_addr {
dec_label_pc_10334:
  %0 = ptrtoint i64** %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  store i64 %0, i64* %result, align 8, !insn.addr !4287
  ret i64 %1, !insn.addr !4288
}

define i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE12_M_check_lenEmPKc(i64* %result, i64 %arg2, i8* %arg3) local_unnamed_addr {
dec_label_pc_10356:
  %rax.0.reg2mem = alloca i64, !insn.addr !4289
  %storemerge.reg2mem = alloca i64, !insn.addr !4289
  %stack_var_-48 = alloca i64, align 8
  %stack_var_-72 = alloca i64, align 8
  store i64 %arg2, i64* %stack_var_-72, align 8, !insn.addr !4290
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4291
  %1 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result), !insn.addr !4292
  %2 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !4293
  %3 = sub i64 %1, %2, !insn.addr !4294
  %4 = icmp ult i64 %3, %arg2, !insn.addr !4295
  %5 = icmp eq i1 %4, false, !insn.addr !4296
  br i1 %5, label %dec_label_pc_103b9, label %dec_label_pc_103ad, !insn.addr !4297

dec_label_pc_103ad:                               ; preds = %dec_label_pc_10356
  %6 = call i64 @_ZSt20__throw_length_errorPKc(i8* %arg3), !insn.addr !4298
  br label %dec_label_pc_103b9, !insn.addr !4298

dec_label_pc_103b9:                               ; preds = %dec_label_pc_103ad, %dec_label_pc_10356
  %7 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !4299
  %8 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !4300
  store i64 %8, i64* %stack_var_-48, align 8, !insn.addr !4301
  %9 = call i64* @_ZSt3maxImERKT_S2_S2_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-72), !insn.addr !4302
  %10 = load i64, i64* %9, align 8, !insn.addr !4303
  %11 = add i64 %10, %7, !insn.addr !4304
  %12 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result), !insn.addr !4305
  %13 = icmp ult i64 %11, %12, !insn.addr !4306
  br i1 %13, label %dec_label_pc_10419, label %dec_label_pc_10407, !insn.addr !4307

dec_label_pc_10407:                               ; preds = %dec_label_pc_103b9
  %14 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result), !insn.addr !4308
  %15 = icmp ult i64 %14, %11, !insn.addr !4309
  %16 = icmp eq i1 %15, false, !insn.addr !4310
  store i64 %11, i64* %storemerge.reg2mem, !insn.addr !4310
  br i1 %16, label %dec_label_pc_1042b, label %dec_label_pc_10419, !insn.addr !4310

dec_label_pc_10419:                               ; preds = %dec_label_pc_10407, %dec_label_pc_103b9
  %17 = call i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result), !insn.addr !4311
  store i64 %17, i64* %storemerge.reg2mem, !insn.addr !4312
  br label %dec_label_pc_1042b, !insn.addr !4312

dec_label_pc_1042b:                               ; preds = %dec_label_pc_10407, %dec_label_pc_10419
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  %18 = call i64 @__readfsqword(i64 40), !insn.addr !4313
  %19 = icmp eq i64 %0, %18, !insn.addr !4313
  store i64 %storemerge.reload, i64* %rax.0.reg2mem, !insn.addr !4314
  br i1 %19, label %dec_label_pc_1043f, label %dec_label_pc_1043a, !insn.addr !4314

dec_label_pc_1043a:                               ; preds = %dec_label_pc_1042b
  %20 = call i64 @__stack_chk_fail(), !insn.addr !4315
  store i64 %20, i64* %rax.0.reg2mem, !insn.addr !4315
  br label %dec_label_pc_1043f, !insn.addr !4315

dec_label_pc_1043f:                               ; preds = %dec_label_pc_1043a, %dec_label_pc_1042b
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4316

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder i64* (i64*, i64*)* @_ZSt3maxImERKT_S2_S2_, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv, { 3, 2, 1, 0 }
  uselistorder i64 (i64*)* @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv, { 2, 1, 0 }
  uselistorder label %dec_label_pc_1042b, { 1, 0 }
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE5beginEv(i64* %result) local_unnamed_addr {
dec_label_pc_10446:
  %rax.0.reg2mem = alloca i64, !insn.addr !4317
  %stack_var_-24 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4318
  %1 = bitcast i64* %result to i64**, !insn.addr !4319
  %2 = call i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* nonnull %stack_var_-24, i64** %1), !insn.addr !4319
  %3 = load i64, i64* %stack_var_-24, align 8, !insn.addr !4320
  %4 = call i64 @__readfsqword(i64 40), !insn.addr !4321
  %5 = icmp eq i64 %0, %4, !insn.addr !4321
  store i64 %3, i64* %rax.0.reg2mem, !insn.addr !4322
  br i1 %5, label %dec_label_pc_10490, label %dec_label_pc_1048b, !insn.addr !4322

dec_label_pc_1048b:                               ; preds = %dec_label_pc_10446
  %6 = call i64 @__stack_chk_fail(), !insn.addr !4323
  store i64 %6, i64* %rax.0.reg2mem, !insn.addr !4323
  br label %dec_label_pc_10490, !insn.addr !4323

dec_label_pc_10490:                               ; preds = %dec_label_pc_1048b, %dec_label_pc_10446
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4324

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
}

define i64 @_ZN9__gnu_cxxmiIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEENS_17__normal_iteratorIT_T0_E15difference_typeERKSJ_SM_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_10492:
  %0 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* %arg1), !insn.addr !4325
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4326
  %2 = load i64, i64* %1, align 8, !insn.addr !4326
  %3 = call i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* %arg2), !insn.addr !4327
  %4 = inttoptr i64 %3 to i64*, !insn.addr !4328
  %5 = load i64, i64* %4, align 8, !insn.addr !4328
  %6 = sub i64 %2, %5, !insn.addr !4329
  %7 = ashr i64 %6, 3, !insn.addr !4330
  ret i64 %7, !insn.addr !4331

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv, { 3, 2, 1, 0 }
}

define i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_M_allocateEm(i64* %result, i64 %arg2) local_unnamed_addr {
dec_label_pc_104d8:
  %storemerge.reg2mem = alloca i64, !insn.addr !4332
  %0 = icmp eq i64 %arg2, 0, !insn.addr !4333
  store i64 0, i64* %storemerge.reg2mem, !insn.addr !4334
  br i1 %0, label %dec_label_pc_10523, label %dec_label_pc_104f3, !insn.addr !4334

dec_label_pc_104f3:                               ; preds = %dec_label_pc_104d8
  %1 = call i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE8allocateEmPKv(i64* %result, i64 %arg2, i64* null), !insn.addr !4335
  store i64 %1, i64* %storemerge.reg2mem, !insn.addr !4336
  br label %dec_label_pc_10523, !insn.addr !4336

dec_label_pc_10523:                               ; preds = %dec_label_pc_104d8, %dec_label_pc_104f3
  %storemerge.reload = load i64, i64* %storemerge.reg2mem
  ret i64 %storemerge.reload, !insn.addr !4337

; uselistorder directives
  uselistorder i64* %storemerge.reg2mem, { 0, 2, 1 }
  uselistorder label %dec_label_pc_10523, { 1, 0 }
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_relocateEPSA_SD_SD_RSB_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_10525:
  %0 = call i64* @_ZSt12__relocate_aIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4), !insn.addr !4338
  %1 = ptrtoint i64* %0 to i64, !insn.addr !4338
  ret i64 %1, !insn.addr !4339
}

define i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEE4baseEv(i64* %result) local_unnamed_addr {
dec_label_pc_1055c:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4340
}

define i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result) local_unnamed_addr {
dec_label_pc_1056e:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4341
}

define i64 @_ZNSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE13_M_deallocateEPSA_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_10580:
  %rax.0.reg2mem = alloca i64, !insn.addr !4342
  %0 = icmp eq i64* %arg2, null, !insn.addr !4343
  br i1 %0, label %dec_label_pc_105cf, label %dec_label_pc_1059f, !insn.addr !4344

dec_label_pc_1059f:                               ; preds = %dec_label_pc_10580
  %1 = call i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE10deallocateEPSA_m(i64* %result, i64* nonnull %arg2, i64 %arg3), !insn.addr !4345
  store i64 %1, i64* %rax.0.reg2mem, !insn.addr !4346
  br label %dec_label_pc_105cf, !insn.addr !4346

dec_label_pc_105cf:                               ; preds = %dec_label_pc_1059f, %dec_label_pc_10580
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4347
}

define i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEmiEl(i64* %result, i32 %arg2) local_unnamed_addr {
dec_label_pc_105d2:
  %rax.0.reg2mem = alloca i64, !insn.addr !4348
  %0 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  %stack_var_-32 = alloca i64, align 8
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !4349
  %2 = sext i32 %arg2 to i64, !insn.addr !4350
  %3 = mul i64 %2, 8, !insn.addr !4351
  %4 = sub i64 %0, %3, !insn.addr !4352
  store i64 %4, i64* %stack_var_-32, align 8, !insn.addr !4353
  %5 = bitcast i64* %stack_var_-32 to i64**, !insn.addr !4354
  %6 = call i64 @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_(i64* nonnull %stack_var_-24, i64** nonnull %5), !insn.addr !4354
  %7 = load i64, i64* %stack_var_-24, align 8, !insn.addr !4355
  %8 = call i64 @__readfsqword(i64 40), !insn.addr !4356
  %9 = icmp eq i64 %1, %8, !insn.addr !4356
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !4357
  br i1 %9, label %dec_label_pc_10639, label %dec_label_pc_10634, !insn.addr !4357

dec_label_pc_10634:                               ; preds = %dec_label_pc_105d2
  %10 = call i64 @__stack_chk_fail(), !insn.addr !4358
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !4358
  br label %dec_label_pc_10639, !insn.addr !4358

dec_label_pc_10639:                               ; preds = %dec_label_pc_10634, %dec_label_pc_105d2
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4359

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
  uselistorder i64 (i64*, i64**)* @_ZN9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEC1ERKSC_, { 2, 1, 0 }
}

define i64 @_ZNK9__gnu_cxx17__normal_iteratorIPSt10unique_ptrIN4llvm6detail11PassConceptINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEESt14default_deleteIS8_EESt6vectorISB_SaISB_EEEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_1063c:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4360
}

define i64 @_ZN4llvm11isa_impl_clINS_5ValueEPKS1_E4doitES3_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10651:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4361
  %1 = icmp eq i1 %0, false, !insn.addr !4362
  br i1 %1, label %dec_label_pc_10690, label %dec_label_pc_10668, !insn.addr !4362

dec_label_pc_10668:                               ; preds = %dec_label_pc_10651
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([110 x i8]* @global_var_7fe4 to i64)), !insn.addr !4363
  br label %dec_label_pc_10690, !insn.addr !4363

dec_label_pc_10690:                               ; preds = %dec_label_pc_10668, %dec_label_pc_10651
  %3 = call i64 @_ZN4llvm8isa_implINS_5ValueES1_vE4doitERKS1_(i64* %arg1), !insn.addr !4364
  ret i64 %3, !insn.addr !4365
}

define i64 @_ZN4llvm8isa_implINS_10StructTypeENS_4TypeEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_1069e:
  %0 = call i64 @_ZN4llvm10StructType7classofEPKNS_4TypeE(i64* %arg1), !insn.addr !4366
  ret i64 %0, !insn.addr !4367
}

define i64 @_ZN4llvm8isa_implINS_9ArrayTypeENS_4TypeEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_106bc:
  %0 = call i64 @_ZN4llvm9ArrayType7classofEPKNS_4TypeE(i64* %arg1), !insn.addr !4368
  ret i64 %0, !insn.addr !4369
}

define i64 @_ZN4llvm8isa_implINS_8LoadInstENS_11InstructionEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_106da:
  %0 = call i64 @_ZN4llvm8LoadInst7classofEPKNS_11InstructionE(i64* %arg1), !insn.addr !4370
  ret i64 %0, !insn.addr !4371
}

define i64 @_ZN4llvm8isa_implINS_9StoreInstENS_11InstructionEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_106f8:
  %0 = call i64 @_ZN4llvm9StoreInst7classofEPKNS_11InstructionE(i64* %arg1), !insn.addr !4372
  ret i64 %0, !insn.addr !4373
}

define i64 @_ZN4llvm11isa_impl_clINS_14FPMathOperatorEPKNS_11InstructionEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10716:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4374
  %1 = icmp eq i1 %0, false, !insn.addr !4375
  br i1 %1, label %dec_label_pc_10755, label %dec_label_pc_1072d, !insn.addr !4375

dec_label_pc_1072d:                               ; preds = %dec_label_pc_10716
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([125 x i8]* @global_var_8054 to i64)), !insn.addr !4376
  br label %dec_label_pc_10755, !insn.addr !4376

dec_label_pc_10755:                               ; preds = %dec_label_pc_1072d, %dec_label_pc_10716
  %3 = call i64 @_ZN4llvm8isa_implINS_14FPMathOperatorENS_11InstructionEvE4doitERKS2_(i64* %arg1), !insn.addr !4377
  ret i64 %3, !insn.addr !4378
}

define i64 @_ZN4llvm11isa_impl_clINS_8CallInstEPKNS_5ValueEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10763:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4379
  %1 = icmp eq i1 %0, false, !insn.addr !4380
  br i1 %1, label %dec_label_pc_107a2, label %dec_label_pc_1077a, !insn.addr !4380

dec_label_pc_1077a:                               ; preds = %dec_label_pc_10763
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([113 x i8]* @global_var_80d4 to i64)), !insn.addr !4381
  br label %dec_label_pc_107a2, !insn.addr !4381

dec_label_pc_107a2:                               ; preds = %dec_label_pc_1077a, %dec_label_pc_10763
  %3 = call i64 @_ZN4llvm8isa_implINS_8CallInstENS_5ValueEvE4doitERKS2_(i64* %arg1), !insn.addr !4382
  ret i64 %3, !insn.addr !4383
}

define i64 @_ZN4llvm8isa_implINS_13IntrinsicInstENS_5ValueEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_107b0:
  %0 = call i64 @_ZN4llvm13IntrinsicInst7classofEPKNS_5ValueE(i64* %arg1), !insn.addr !4384
  ret i64 %0, !insn.addr !4385
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv(i64* %result) local_unnamed_addr {
dec_label_pc_107ce:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 16, !insn.addr !4386
  ret i64 %1, !insn.addr !4387
}

define void @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE18uninitialized_moveIPSE_SH_EEvT_SI_T0_(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_107e4:
  %0 = call i64* @_ZSt18uninitialized_moveIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEESF_ET0_T_SH_SG_(i64* %arg1, i64* %arg2, i64* %arg3), !insn.addr !4388
  ret void, !insn.addr !4389
}

define i64 @_ZN4llvm23SmallVectorTemplateBaseISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEELb0EE13destroy_rangeEPSE_SG_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_10816:
  %stack_var_-24.01.reg2mem = alloca i64, !insn.addr !4390
  %0 = ptrtoint i64* %arg1 to i64
  %1 = icmp eq i64* %arg2, %arg1, !insn.addr !4391
  %2 = icmp eq i1 %1, false, !insn.addr !4392
  br i1 %2, label %dec_label_pc_1082c.lr.ph, label %dec_label_pc_10847, !insn.addr !4392

dec_label_pc_1082c.lr.ph:                         ; preds = %dec_label_pc_10816
  %3 = ptrtoint i64* %arg2 to i64
  store i64 %3, i64* %stack_var_-24.01.reg2mem
  br label %dec_label_pc_1082c

dec_label_pc_1082c:                               ; preds = %dec_label_pc_1082c.lr.ph, %dec_label_pc_1082c
  %stack_var_-24.01.reload = load i64, i64* %stack_var_-24.01.reg2mem
  %4 = add i64 %stack_var_-24.01.reload, -32, !insn.addr !4393
  %5 = inttoptr i64 %4 to i64*, !insn.addr !4394
  %6 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev(i64* %5), !insn.addr !4394
  %7 = icmp eq i64 %4, %0, !insn.addr !4391
  %8 = icmp eq i1 %7, false, !insn.addr !4392
  store i64 %4, i64* %stack_var_-24.01.reg2mem, !insn.addr !4392
  br i1 %8, label %dec_label_pc_1082c, label %dec_label_pc_10847, !insn.addr !4392

dec_label_pc_10847:                               ; preds = %dec_label_pc_1082c, %dec_label_pc_10816
  ret i64 %0, !insn.addr !4395

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64* %stack_var_-24.01.reg2mem, { 1, 0, 2 }
  uselistorder i64 (i64*)* @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEED1Ev, { 1, 0 }
  uselistorder i64 -32, { 1, 0, 2, 3 }
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder label %dec_label_pc_1082c, { 1, 0 }
}

define i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE7isSmallEv(i64* %result) local_unnamed_addr {
dec_label_pc_1084c:
  %0 = ptrtoint i64* %result to i64
  %1 = call i64 @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv(i64* %result), !insn.addr !4396
  %2 = icmp eq i64 %1, %0, !insn.addr !4397
  %3 = zext i1 %2 to i64, !insn.addr !4398
  %4 = and i64 %1, -256, !insn.addr !4398
  %5 = or i64 %4, %3, !insn.addr !4398
  ret i64 %5, !insn.addr !4399

; uselistorder directives
  uselistorder i64 %1, { 1, 0 }
  uselistorder i64 -256, { 2, 0, 7, 8, 9, 10, 20, 21, 23, 27, 11, 12, 4, 13, 1, 15, 5, 6, 33, 17, 18, 22, 24, 25, 28, 29, 26, 16, 19, 31, 30, 3, 14, 32 }
  uselistorder i64 (i64*)* @_ZNK4llvm25SmallVectorTemplateCommonISt8functionIFbNS_9StringRefERNS_11PassManagerINS_6ModuleENS_15AnalysisManagerIS4_JEEEJEEENS_8ArrayRefINS_11PassBuilder15PipelineElementEEEEEvE10getFirstElEv, { 1, 0 }
}

define i64 @_ZN4llvm8isa_implINS_11IntegerTypeENS_4TypeEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_1087c:
  %0 = call i64 @_ZN4llvm11IntegerType7classofEPKNS_4TypeE(i64* %arg1), !insn.addr !4400
  ret i64 %0, !insn.addr !4401
}

define i64 @_ZN4llvm13simplify_typeIPKNS_8CallBaseEE18getSimplifiedValueERS3_(i64** %arg1) local_unnamed_addr {
dec_label_pc_1089a:
  %0 = ptrtoint i64** %arg1 to i64
  ret i64 %0, !insn.addr !4402
}

define i64 @_ZN4llvm11isa_impl_clINS_16DbgInfoIntrinsicEPKNS_8CallBaseEE4doitES4_(i64* %arg1) local_unnamed_addr {
dec_label_pc_108ac:
  %0 = icmp eq i64* %arg1, null, !insn.addr !4403
  %1 = icmp eq i1 %0, false, !insn.addr !4404
  br i1 %1, label %dec_label_pc_108eb, label %dec_label_pc_108c3, !insn.addr !4404

dec_label_pc_108c3:                               ; preds = %dec_label_pc_108ac
  %2 = call i64 @__assert_fail(i64 ptrtoint ([38 x i8]* @global_var_79f4 to i64), i64 ptrtoint ([44 x i8]* @global_var_50b4 to i64), i64 109, i64 ptrtoint ([124 x i8]* @global_var_814c to i64)), !insn.addr !4405
  br label %dec_label_pc_108eb, !insn.addr !4405

dec_label_pc_108eb:                               ; preds = %dec_label_pc_108c3, %dec_label_pc_108ac
  %3 = call i64 @_ZN4llvm8isa_implINS_16DbgInfoIntrinsicENS_8CallBaseEvE4doitERKS2_(i64* %arg1), !insn.addr !4406
  ret i64 %3, !insn.addr !4407

; uselistorder directives
  uselistorder i64 (i64, i64, i64, i64)* @__assert_fail, { 19, 25, 9, 54, 53, 8, 5, 23, 52, 51, 18, 17, 16, 22, 50, 49, 46, 45, 56, 15, 59, 14, 44, 7, 20, 24, 21, 58, 57, 55, 47, 43, 42, 41, 13, 12, 10, 39, 26, 40, 48, 11, 4, 1, 6, 3, 2, 0, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27 }
  uselistorder i64* null, { 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 1, 25, 26, 27, 28, 2, 29, 30, 31, 32, 0, 33 }
}

define i64 @_ZN4llvm8isa_implINS_8CallBaseENS_11InstructionEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_108f9:
  %0 = call i64 @_ZN4llvm8CallBase7classofEPKNS_11InstructionE(i64* %arg1), !insn.addr !4408
  ret i64 %0, !insn.addr !4409
}

define i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_10918:
  %0 = call i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EEC1Ev(i64* %result), !insn.addr !4410
  ret i64 %0, !insn.addr !4411
}

define i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_10938:
  %0 = ptrtoint i64* %result to i64
  store i64 0, i64* %result, align 8, !insn.addr !4412
  ret i64 %0, !insn.addr !4413
}

define i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEE7_M_headERSA_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10952:
  %0 = call i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EE7_M_headERS8_(i64* %arg1), !insn.addr !4414
  ret i64 %0, !insn.addr !4415
}

define i64* @_ZSt12__get_helperILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEJEERT0_RSt11_Tuple_implIXT_EJS9_DpT1_EE(i64* %arg1) local_unnamed_addr {
dec_label_pc_10970:
  %0 = call i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEE7_M_headERS9_(i64* %arg1), !insn.addr !4416
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4417
  ret i64* %1, !insn.addr !4417
}

define i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_1098e:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %2 = call i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1EOS9_(i64* %result, i64* %arg2), !insn.addr !4418
  store i64 %0, i64* %result, align 8, !insn.addr !4419
  ret i64 %1, !insn.addr !4420
}

define i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_109c6:
  %0 = call i64 @_ZNSt11_Tuple_implILm0EJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %arg2), !insn.addr !4421
  ret i64 %0, !insn.addr !4422
}

define i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_109f0:
  %0 = bitcast i64* %arg2 to i64**, !insn.addr !4423
  %1 = call i64* @_ZSt4moveIRSt5tupleIJPN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEEONSt16remove_referenceIT_E4typeEOSE_(i64** %0), !insn.addr !4423
  %2 = call i64 @_ZNSt5tupleIJPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEEC1EOSA_(i64* %result, i64* %1), !insn.addr !4424
  %3 = call i64 @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv(i64* %arg2), !insn.addr !4425
  %4 = inttoptr i64 %3 to i64*, !insn.addr !4426
  store i64 0, i64* %4, align 8, !insn.addr !4426
  ret i64 %3, !insn.addr !4427

; uselistorder directives
  uselistorder i64 %3, { 1, 0 }
  uselistorder i64 (i64*)* @_ZNSt15__uniq_ptr_implIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EE6_M_ptrEv, { 2, 1, 0 }
}

define i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE8max_sizeEv(i64* %result) local_unnamed_addr {
dec_label_pc_10a3a:
  %0 = call i64 @_ZNKSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result), !insn.addr !4428
  %1 = inttoptr i64 %0 to i64*, !insn.addr !4429
  %2 = call i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_max_sizeERKSB_(i64* %1), !insn.addr !4429
  ret i64 %2, !insn.addr !4430
}

define i64 @_ZNKSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE4sizeEv(i64* %result) local_unnamed_addr {
dec_label_pc_10a60:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 8, !insn.addr !4431
  %2 = inttoptr i64 %1 to i64*, !insn.addr !4431
  %3 = load i64, i64* %2, align 8, !insn.addr !4431
  %4 = sub i64 %3, %0, !insn.addr !4432
  %5 = ashr i64 %4, 3, !insn.addr !4433
  ret i64 %5, !insn.addr !4434

; uselistorder directives
  uselistorder i64 3, { 2, 3, 4, 5, 1, 0 }
}

define i64* @_ZSt12__relocate_aIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_10a87:
  %0 = call i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg3), !insn.addr !4435
  %1 = call i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg2), !insn.addr !4436
  %2 = call i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg1), !insn.addr !4437
  %3 = call i64* @_ZSt14__relocate_a_1IPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %2, i64* %1, i64* %0, i64* %arg4), !insn.addr !4438
  ret i64* %3, !insn.addr !4439

; uselistorder directives
  uselistorder i64* (i64*)* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_, { 2, 1, 0 }
}

define i64 @_ZN4llvm8isa_implINS_5ValueES1_vE4doitERKS1_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10aee:
  ret i64 1, !insn.addr !4440

; uselistorder directives
  uselistorder i64 1, { 42, 55, 50, 51, 52, 63, 56, 0, 62, 57, 43, 65, 68, 1, 2, 3, 4, 5, 58, 44, 45, 59, 53, 46, 47, 7, 6, 8, 9, 10, 48, 11, 12, 13, 64, 49, 67, 14, 69, 60, 61, 15, 54, 16, 17, 66, 40, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 41 }
}

define i64 @_ZN4llvm8isa_implINS_14FPMathOperatorENS_11InstructionEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10b01:
  %0 = call i64 @_ZN4llvm14FPMathOperator7classofEPKNS_5ValueE(i64* %arg1), !insn.addr !4441
  ret i64 %0, !insn.addr !4442
}

define i64 @_ZN4llvm8isa_implINS_8CallInstENS_5ValueEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10b1f:
  %0 = call i64 @_ZN4llvm8CallInst7classofEPKNS_5ValueE(i64* %arg1), !insn.addr !4443
  ret i64 %0, !insn.addr !4444
}

define i64* @_ZSt18uninitialized_moveIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEESF_ET0_T_SH_SG_(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_10b3d:
  %0 = call i64 @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_(i64* %arg2), !insn.addr !4445
  %1 = call i64 @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_(i64* %arg1), !insn.addr !4446
  %2 = call i64* @_ZSt18uninitialized_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %1, i64 %0, i64* %arg3), !insn.addr !4447
  ret i64* %2, !insn.addr !4448

; uselistorder directives
  uselistorder i64 (i64*)* @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_, { 1, 0 }
}

define i64 @_ZN4llvm8isa_implINS_16DbgInfoIntrinsicENS_8CallBaseEvE4doitERKS2_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10b8c:
  %0 = call i64 @_ZN4llvm16DbgInfoIntrinsic7classofEPKNS_5ValueE(i64* %arg1), !insn.addr !4449
  ret i64 %0, !insn.addr !4450
}

define i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EEC1Ev(i64* %result) local_unnamed_addr {
dec_label_pc_10baa:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !4451
}

define i64 @_ZNSt10_Head_baseILm0EPN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEELb0EE7_M_headERS8_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10bb9:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !4452
}

define i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEE7_M_headERS9_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10bcb:
  %0 = call i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EE7_M_headERS9_(i64* %arg1), !insn.addr !4453
  ret i64 %0, !insn.addr !4454
}

define i64* @_ZSt4moveIRSt5tupleIJPN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEEONSt16remove_referenceIT_E4typeEOSE_(i64** %arg1) local_unnamed_addr {
dec_label_pc_10be9:
  %0 = bitcast i64** %arg1 to i64*, !insn.addr !4455
  ret i64* %0, !insn.addr !4455
}

define i64 @_ZNSt11_Tuple_implILm1EJSt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEEEEC1EOS9_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_10bfc:
  %0 = alloca i64
  %1 = load i64, i64* %0
  ret i64 %1, !insn.addr !4456
}

define i64 @_ZNSt6vectorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE11_S_max_sizeERKSB_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10c0f:
  %rax.0.reg2mem = alloca i64, !insn.addr !4457
  %stack_var_-48 = alloca i64, align 8
  %stack_var_-56 = alloca i64, align 8
  %0 = call i64 @__readfsqword(i64 40), !insn.addr !4458
  store i64 1152921504606846975, i64* %stack_var_-56, align 8, !insn.addr !4459
  store i64 1152921504606846975, i64* %stack_var_-48, align 8, !insn.addr !4460
  %1 = call i64* @_ZSt3minImERKT_S2_S2_(i64* nonnull %stack_var_-56, i64* nonnull %stack_var_-48), !insn.addr !4461
  %2 = load i64, i64* %1, align 8, !insn.addr !4462
  %3 = call i64 @__readfsqword(i64 40), !insn.addr !4463
  %4 = icmp eq i64 %0, %3, !insn.addr !4463
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !4464
  br i1 %4, label %dec_label_pc_10c8e, label %dec_label_pc_10c89, !insn.addr !4464

dec_label_pc_10c89:                               ; preds = %dec_label_pc_10c0f
  %5 = call i64 @__stack_chk_fail(), !insn.addr !4465
  store i64 %5, i64* %rax.0.reg2mem, !insn.addr !4465
  br label %dec_label_pc_10c8e, !insn.addr !4465

dec_label_pc_10c8e:                               ; preds = %dec_label_pc_10c89, %dec_label_pc_10c0f
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4466

; uselistorder directives
  uselistorder i64* (i64*, i64*)* @_ZSt3minImERKT_S2_S2_, { 4, 3, 2, 1, 0 }
}

define i64 @_ZNKSt12_Vector_baseISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESaISA_EE19_M_get_Tp_allocatorEv(i64* %result) local_unnamed_addr {
dec_label_pc_10c90:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4467
}

define i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE8allocateEmPKv(i64* %result, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_10ca2:
  %0 = icmp ugt i64 %arg2, 1152921504606846975, !insn.addr !4468
  %1 = icmp eq i1 %0, false, !insn.addr !4469
  %2 = icmp eq i1 %1, false, !insn.addr !4470
  %3 = icmp eq i1 %2, false, !insn.addr !4471
  br i1 %3, label %dec_label_pc_10cfa, label %dec_label_pc_10ce0, !insn.addr !4472

dec_label_pc_10ce0:                               ; preds = %dec_label_pc_10ca2
  %4 = icmp ugt i64 %arg2, 2305843009213693951, !insn.addr !4473
  %5 = icmp eq i1 %4, false, !insn.addr !4474
  br i1 %5, label %dec_label_pc_10cf5, label %dec_label_pc_10cf0, !insn.addr !4474

dec_label_pc_10cf0:                               ; preds = %dec_label_pc_10ce0
  %6 = call i64 @_ZSt28__throw_bad_array_new_lengthv(), !insn.addr !4475
  br label %dec_label_pc_10cf5, !insn.addr !4475

dec_label_pc_10cf5:                               ; preds = %dec_label_pc_10cf0, %dec_label_pc_10ce0
  %7 = call i64 @_ZSt17__throw_bad_allocv(), !insn.addr !4476
  br label %dec_label_pc_10cfa, !insn.addr !4476

dec_label_pc_10cfa:                               ; preds = %dec_label_pc_10cf5, %dec_label_pc_10ca2
  %8 = mul i64 %arg2, 8, !insn.addr !4477
  %9 = call i64 @_Znwm(i64 %8), !insn.addr !4478
  ret i64 %9, !insn.addr !4479

; uselistorder directives
  uselistorder i64 (i64)* @_Znwm, { 1, 0 }
}

define i64* @_ZSt12__niter_baseIPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEET_SC_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10d0d:
  ret i64* %arg1, !insn.addr !4480
}

define i64* @_ZSt14__relocate_a_1IPSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESB_SaISA_EET0_T_SE_SD_RT1_(i64* %arg1, i64* %arg2, i64* %arg3, i64* %arg4) local_unnamed_addr {
dec_label_pc_10d1f:
  %storemerge.lcssa.reg2mem = alloca i64, !insn.addr !4481
  %stack_var_-48.01.reg2mem = alloca i64, !insn.addr !4481
  %storemerge2.reg2mem = alloca i64, !insn.addr !4481
  %0 = ptrtoint i64* %arg3 to i64
  %1 = icmp eq i64* %arg1, %arg2, !insn.addr !4482
  %2 = icmp eq i1 %1, false, !insn.addr !4483
  store i64 %0, i64* %storemerge.lcssa.reg2mem, !insn.addr !4483
  br i1 %2, label %dec_label_pc_10d46.lr.ph, label %dec_label_pc_10d8a, !insn.addr !4483

dec_label_pc_10d46.lr.ph:                         ; preds = %dec_label_pc_10d1f
  %3 = ptrtoint i64* %arg2 to i64
  %4 = ptrtoint i64* %arg1 to i64
  store i64 %0, i64* %storemerge2.reg2mem
  store i64 %4, i64* %stack_var_-48.01.reg2mem
  br label %dec_label_pc_10d46

dec_label_pc_10d46:                               ; preds = %dec_label_pc_10d46.lr.ph, %dec_label_pc_10d46
  %stack_var_-48.01.reload = load i64, i64* %stack_var_-48.01.reg2mem
  %storemerge2.reload = load i64, i64* %storemerge2.reg2mem
  %5 = inttoptr i64 %stack_var_-48.01.reload to i64*, !insn.addr !4484
  %6 = call i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %5), !insn.addr !4484
  %7 = inttoptr i64 %storemerge2.reload to i64*, !insn.addr !4485
  %8 = call i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %7), !insn.addr !4485
  call void @_ZSt19__relocate_object_aISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESA_SaISA_EEvPT_PT0_RT1_(i64* %8, i64* %6, i64* %arg4), !insn.addr !4486
  %9 = add i64 %stack_var_-48.01.reload, 8, !insn.addr !4487
  %10 = add i64 %storemerge2.reload, 8, !insn.addr !4488
  %11 = icmp eq i64 %9, %3, !insn.addr !4482
  %12 = icmp eq i1 %11, false, !insn.addr !4483
  store i64 %10, i64* %storemerge2.reg2mem, !insn.addr !4483
  store i64 %9, i64* %stack_var_-48.01.reg2mem, !insn.addr !4483
  store i64 %10, i64* %storemerge.lcssa.reg2mem, !insn.addr !4483
  br i1 %12, label %dec_label_pc_10d46, label %dec_label_pc_10d8a, !insn.addr !4483

dec_label_pc_10d8a:                               ; preds = %dec_label_pc_10d46, %dec_label_pc_10d1f
  %storemerge.lcssa.reload = load i64, i64* %storemerge.lcssa.reg2mem
  %13 = inttoptr i64 %storemerge.lcssa.reload to i64*, !insn.addr !4489
  ret i64* %13, !insn.addr !4489

; uselistorder directives
  uselistorder i64 %0, { 1, 0 }
  uselistorder i64* %storemerge2.reg2mem, { 1, 0, 2 }
  uselistorder i64* %stack_var_-48.01.reg2mem, { 1, 0, 2 }
  uselistorder i64* %arg2, { 1, 0 }
  uselistorder i64* %arg1, { 1, 0 }
  uselistorder label %dec_label_pc_10d46, { 1, 0 }
}

define i64 @_ZNSt15__new_allocatorISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEE10deallocateEPSA_m(i64* %result, i64* %arg2, i64 %arg3) local_unnamed_addr {
dec_label_pc_10d94:
  %0 = mul i64 %arg3, 8, !insn.addr !4490
  %1 = call i64 @_ZdlPvm(i64* %arg2, i64 %0), !insn.addr !4491
  ret i64 %1, !insn.addr !4492

; uselistorder directives
  uselistorder i64 (i64*, i64)* @_ZdlPvm, { 0, 3, 2, 1 }
}

define i64 @_ZSt18make_move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEESt13move_iteratorIT_ESH_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10dc9:
  %rax.0.reg2mem = alloca i64, !insn.addr !4493
  %0 = ptrtoint i64* %arg1 to i64
  %stack_var_-24 = alloca i64, align 8
  %stack_var_-32 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-32, align 8, !insn.addr !4494
  %1 = call i64 @__readfsqword(i64 40), !insn.addr !4495
  %2 = bitcast i64* %stack_var_-32 to i64***, !insn.addr !4496
  %3 = call i64* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_(i64*** nonnull %2), !insn.addr !4496
  %4 = load i64, i64* %3, align 8, !insn.addr !4497
  %5 = inttoptr i64 %4 to i64*, !insn.addr !4498
  %6 = call i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEC1ESF_(i64* nonnull %stack_var_-24, i64* %5), !insn.addr !4498
  %7 = load i64, i64* %stack_var_-24, align 8, !insn.addr !4499
  %8 = call i64 @__readfsqword(i64 40), !insn.addr !4500
  %9 = icmp eq i64 %1, %8, !insn.addr !4500
  store i64 %7, i64* %rax.0.reg2mem, !insn.addr !4501
  br i1 %9, label %dec_label_pc_10e1e, label %dec_label_pc_10e19, !insn.addr !4501

dec_label_pc_10e19:                               ; preds = %dec_label_pc_10dc9
  %10 = call i64 @__stack_chk_fail(), !insn.addr !4502
  store i64 %10, i64* %rax.0.reg2mem, !insn.addr !4502
  br label %dec_label_pc_10e1e, !insn.addr !4502

dec_label_pc_10e1e:                               ; preds = %dec_label_pc_10e19, %dec_label_pc_10dc9
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4503

; uselistorder directives
  uselistorder i64* %stack_var_-24, { 1, 0 }
  uselistorder i64 ()* @__stack_chk_fail, { 100, 95, 94, 93, 92, 98, 91, 90, 89, 37, 97, 44, 41, 29, 77, 76, 28, 20, 99, 40, 75, 74, 34, 33, 32, 43, 36, 86, 39, 42, 38, 27, 73, 45, 7, 19, 85, 84, 80, 83, 82, 67, 66, 72, 65, 64, 71, 6, 79, 81, 26, 25, 24, 23, 22, 69, 68, 30, 63, 70, 31, 17, 18, 62, 16, 15, 13, 14, 12, 104, 103, 102, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 4, 3, 88, 48, 47, 2, 1, 101, 96, 87, 78, 46, 35, 21, 11, 10, 9, 8, 5, 0 }
  uselistorder i64 40, { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 211, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 212, 152, 153, 154, 155, 156, 157, 158, 159, 210, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 213, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209 }
}

define i64* @_ZSt18uninitialized_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %arg1, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_10e20:
  %0 = call i64* @_ZNSt20__uninitialized_copyILb0EE13__uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS4_11PassManagerINS4_6ModuleENS4_15AnalysisManagerIS7_JEEEJEEENS4_8ArrayRefINS4_11PassBuilder15PipelineElementEEEEEESI_EET0_T_SL_SK_(i64 %arg1, i64 %arg2, i64* %arg3), !insn.addr !4504
  ret i64* %0, !insn.addr !4505
}

define i64 @_ZNSt10_Head_baseILm1ESt14default_deleteIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEEELb1EE7_M_headERS9_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10e59:
  %0 = ptrtoint i64* %arg1 to i64
  ret i64 %0, !insn.addr !4506
}

define i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %arg1) local_unnamed_addr {
dec_label_pc_10e6b:
  ret i64* %arg1, !insn.addr !4507
}

define void @_ZSt19__relocate_object_aISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EESA_SaISA_EEvPT_PT0_RT1_(i64* %arg1, i64* %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_10e7d:
  %0 = bitcast i64* %arg2 to i64**, !insn.addr !4508
  %1 = call i64* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_(i64** %0), !insn.addr !4508
  %2 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %1), !insn.addr !4509
  %3 = call i64 @_ZnwmPv(i64 8, i64* %arg1), !insn.addr !4510
  %4 = call i64* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE(i64* %2), !insn.addr !4511
  %5 = inttoptr i64 %3 to i64*, !insn.addr !4512
  %6 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_(i64* %5, i64* %4), !insn.addr !4512
  %7 = call i64* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_(i64* %arg2), !insn.addr !4513
  %8 = call i64 @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev(i64* %7), !insn.addr !4514
  ret void, !insn.addr !4515

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EED1Ev, { 1, 0 }
  uselistorder i64* (i64*)* @_ZSt11__addressofISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEPT_RSB_, { 2, 1, 0 }
  uselistorder i64 (i64*, i64*)* @_ZNSt10unique_ptrIN4llvm6detail11PassConceptINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEESt14default_deleteIS6_EEC1EOS9_, { 2, 1, 0 }
  uselistorder i64* (i64*)* @_ZSt7forwardISt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEOT_RNSt16remove_referenceISB_E4typeE, { 7, 6, 5, 4, 3, 1, 0, 2 }
  uselistorder i64* (i64**)* @_ZSt4moveIRSt10unique_ptrIN4llvm6detail11PassConceptINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEESt14default_deleteIS7_EEEONSt16remove_referenceIT_E4typeEOSD_, { 1, 0 }
}

define i64* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_(i64*** %arg1) local_unnamed_addr {
dec_label_pc_10f40:
  %0 = bitcast i64*** %arg1 to i64*, !insn.addr !4516
  ret i64* %0, !insn.addr !4516
}

define i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEC1ESF_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_10f52:
  %0 = ptrtoint i64* %arg2 to i64
  %1 = ptrtoint i64* %result to i64
  %stack_var_-24 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-24, align 8, !insn.addr !4517
  %2 = bitcast i64* %stack_var_-24 to i64***, !insn.addr !4518
  %3 = call i64* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_(i64*** nonnull %2), !insn.addr !4518
  %4 = load i64, i64* %3, align 8, !insn.addr !4519
  store i64 %4, i64* %result, align 8, !insn.addr !4520
  ret i64 %1, !insn.addr !4521

; uselistorder directives
  uselistorder i64* (i64***)* @_ZSt4moveIRPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEONSt16remove_referenceIT_E4typeEOSI_, { 1, 0 }
}

define i64* @_ZNSt20__uninitialized_copyILb0EE13__uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS4_11PassManagerINS4_6ModuleENS4_15AnalysisManagerIS7_JEEEJEEENS4_8ArrayRefINS4_11PassBuilder15PipelineElementEEEEEESI_EET0_T_SL_SK_(i64 %arg1, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_10f7f:
  %0 = call i64* @_ZSt16__do_uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %arg1, i64 %arg2, i64* %arg3), !insn.addr !4522
  ret i64* %0, !insn.addr !4523
}

define i64* @_ZSt16__do_uninit_copyISt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS2_11PassManagerINS2_6ModuleENS2_15AnalysisManagerIS5_JEEEJEEENS2_8ArrayRefINS2_11PassBuilder15PipelineElementEEEEEESG_ET0_T_SJ_SI_(i64 %arg1, i64 %arg2, i64* %arg3) local_unnamed_addr {
dec_label_pc_10fb0:
  %storemerge.lcssa.reg2mem = alloca i64, !insn.addr !4524
  %storemerge1.reg2mem = alloca i64, !insn.addr !4524
  %0 = ptrtoint i64* %arg3 to i64
  %stack_var_-56 = alloca i64, align 8
  %stack_var_-48 = alloca i64, align 8
  store i64 %arg1, i64* %stack_var_-48, align 8, !insn.addr !4525
  store i64 %arg2, i64* %stack_var_-56, align 8, !insn.addr !4526
  %1 = call i1 @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-56), !insn.addr !4527
  %2 = icmp eq i1 %1, false, !insn.addr !4528
  %3 = icmp eq i1 %2, false, !insn.addr !4529
  store i64 %0, i64* %storemerge1.reg2mem, !insn.addr !4529
  store i64 %0, i64* %storemerge.lcssa.reg2mem, !insn.addr !4529
  br i1 %3, label %dec_label_pc_10fd3, label %dec_label_pc_11021, !insn.addr !4529

dec_label_pc_10fd3:                               ; preds = %dec_label_pc_10fb0, %dec_label_pc_10fd3
  %storemerge1.reload = load i64, i64* %storemerge1.reg2mem
  %4 = call i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEdeEv(i64* nonnull %stack_var_-48), !insn.addr !4530
  %5 = inttoptr i64 %storemerge1.reload to i64*, !insn.addr !4531
  %6 = call i64* @_ZSt11__addressofISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEPT_RSF_(i64* %5), !insn.addr !4531
  call void @_ZSt10_ConstructISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEJSE_EEvPT_DpOT0_(i64* %6, i64 %4), !insn.addr !4532
  %7 = call i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEppEv(i64* nonnull %stack_var_-48), !insn.addr !4533
  %8 = add i64 %storemerge1.reload, 32, !insn.addr !4534
  %9 = call i1 @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* nonnull %stack_var_-48, i64* nonnull %stack_var_-56), !insn.addr !4527
  %10 = icmp eq i1 %9, false, !insn.addr !4528
  %11 = icmp eq i1 %10, false, !insn.addr !4529
  store i64 %8, i64* %storemerge1.reg2mem, !insn.addr !4529
  store i64 %8, i64* %storemerge.lcssa.reg2mem, !insn.addr !4529
  br i1 %11, label %dec_label_pc_10fd3, label %dec_label_pc_11021, !insn.addr !4529

dec_label_pc_11021:                               ; preds = %dec_label_pc_10fd3, %dec_label_pc_10fb0
  %storemerge.lcssa.reload = load i64, i64* %storemerge.lcssa.reg2mem
  %12 = inttoptr i64 %storemerge.lcssa.reload to i64*, !insn.addr !4535
  ret i64* %12, !insn.addr !4535

; uselistorder directives
  uselistorder i64 %storemerge1.reload, { 1, 0 }
  uselistorder i64* %stack_var_-48, { 1, 2, 3, 0, 4 }
  uselistorder i64* %stack_var_-56, { 1, 0, 2 }
  uselistorder i64* %storemerge1.reg2mem, { 2, 0, 1 }
  uselistorder i1 false, { 96, 30, 6, 7, 101, 8, 102, 31, 103, 32, 190, 97, 9, 183, 213, 119, 104, 33, 120, 214, 223, 186, 121, 122, 191, 192, 193, 187, 34, 123, 35, 124, 36, 98, 37, 99, 38, 100, 109, 39, 125, 126, 194, 215, 224, 129, 130, 131, 0, 271, 272, 110, 111, 2, 132, 133, 195, 94, 95, 196, 274, 227, 134, 1, 115, 225, 135, 40, 217, 41, 273, 42, 189, 43, 44, 184, 45, 188, 46, 105, 106, 107, 108, 47, 113, 114, 112, 10, 116, 48, 49, 50, 51, 52, 53, 54, 55, 218, 216, 11, 128, 136, 56, 137, 57, 58, 208, 59, 209, 210, 60, 211, 212, 61, 206, 200, 62, 201, 28, 202, 197, 63, 198, 64, 207, 65, 182, 66, 138, 67, 185, 127, 199, 205, 203, 204, 232, 228, 237, 219, 234, 235, 236, 68, 229, 233, 230, 231, 139, 69, 245, 239, 70, 240, 93, 71, 92, 238, 226, 270, 3, 140, 12, 141, 142, 143, 144, 145, 146, 72, 147, 73, 148, 74, 149, 75, 150, 76, 151, 152, 153, 13, 154, 155, 78, 157, 26, 77, 156, 14, 15, 158, 159, 4, 160, 79, 81, 162, 80, 161, 16, 17, 163, 164, 18, 165, 82, 83, 84, 85, 166, 167, 168, 169, 86, 170, 19, 171, 172, 173, 5, 118, 117, 20, 174, 23, 180, 179, 24, 175, 176, 177, 25, 178, 22, 21, 29, 181, 87, 88, 89, 90, 220, 221, 27, 222, 91, 241, 242, 243, 244, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269 }
  uselistorder i1 (i64*, i64*)* @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_, { 1, 0 }
  uselistorder label %dec_label_pc_10fd3, { 1, 0 }
}

define i1 @_ZStneIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_1102b:
  %0 = call i1 @_ZSteqIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* %arg1, i64* %arg2), !insn.addr !4536
  %1 = icmp ne i1 %0, true, !insn.addr !4537
  ret i1 %1, !insn.addr !4538

; uselistorder directives
  uselistorder i1 true, { 3, 0, 12, 1, 4, 5, 6, 10, 7, 11, 2, 8, 9 }
}

define i64 @_ZNSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEppEv(i64* %result) local_unnamed_addr {
dec_label_pc_11058:
  %0 = ptrtoint i64* %result to i64
  %1 = add i64 %0, 32, !insn.addr !4539
  store i64 %1, i64* %result, align 8, !insn.addr !4540
  ret i64 %0, !insn.addr !4541
}

define i64* @_ZSt11__addressofISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEPT_RSF_(i64* %arg1) local_unnamed_addr {
dec_label_pc_1107c:
  ret i64* %arg1, !insn.addr !4542
}

define i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEdeEv(i64* %result) local_unnamed_addr {
dec_label_pc_1108e:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4543
}

define void @_ZSt10_ConstructISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEJSE_EEvPT_DpOT0_(i64* %arg1, i64 %arg2) local_unnamed_addr {
dec_label_pc_110a3:
  %0 = call i64 @_ZnwmPv(i64 32, i64* %arg1), !insn.addr !4544
  %1 = inttoptr i64 %arg2 to i64*, !insn.addr !4545
  %2 = call i64* @_ZSt7forwardISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEOT_RNSt16remove_referenceISF_E4typeE(i64* %1), !insn.addr !4545
  %3 = inttoptr i64 %0 to i64*, !insn.addr !4546
  %4 = call i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1EOSD_(i64* %3, i64* %2), !insn.addr !4546
  ret void, !insn.addr !4547

; uselistorder directives
  uselistorder i64 (i64, i64*)* @_ZnwmPv, { 8, 5, 4, 3, 7, 2, 9, 6, 1, 0 }
  uselistorder i64 32, { 5, 9, 10, 6, 0, 1, 7, 11, 4, 2, 3, 37, 23, 24, 25, 26, 20, 28, 19, 27, 21, 22, 12, 13, 14, 29, 30, 35, 15, 16, 8, 36, 17, 18, 31, 32, 33, 34 }
}

define i1 @_ZSteqIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEbRKSt13move_iteratorIT_ESK_(i64* %arg1, i64* %arg2) local_unnamed_addr {
dec_label_pc_110ea:
  %0 = call i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv(i64* %arg1), !insn.addr !4548
  %1 = call i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv(i64* %arg2), !insn.addr !4549
  %2 = icmp eq i64 %0, %1, !insn.addr !4550
  ret i1 %2, !insn.addr !4551

; uselistorder directives
  uselistorder i64 (i64*)* @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv, { 1, 0 }
}

define i64* @_ZSt7forwardISt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEEOT_RNSt16remove_referenceISF_E4typeE(i64* %arg1) local_unnamed_addr {
dec_label_pc_11126:
  ret i64* %arg1, !insn.addr !4552
}

define i64 @_ZNSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEC1EOSD_(i64* %result, i64* %arg2) local_unnamed_addr {
dec_label_pc_11138:
  %0 = alloca i128
  %rax.0.reg2mem = alloca i64, !insn.addr !4553
  %rdi = alloca i64, align 8
  %1 = load i128, i128* %0
  %2 = ptrtoint i64* %arg2 to i64
  %3 = ptrtoint i64* %result to i64
  %4 = call i128 @__asm_pxor(i128 %1, i128 %1), !insn.addr !4554
  %5 = bitcast i64* %rdi to i128*
  %6 = load i128, i128* %5, align 8, !insn.addr !4555
  call void @__asm_movups(i128 %6, i128 %4), !insn.addr !4555
  %7 = add i64 %3, 16, !insn.addr !4556
  %8 = inttoptr i64 %7 to i64*, !insn.addr !4556
  %9 = load i64, i64* %8, align 8, !insn.addr !4556
  call void @__asm_movq(i64 %9, i128 %4), !insn.addr !4556
  %10 = call i64 @_ZNSt14_Function_baseC1Ev(i64* %result), !insn.addr !4557
  %11 = add i64 %2, 24, !insn.addr !4558
  %12 = inttoptr i64 %11 to i64*, !insn.addr !4558
  %13 = load i64, i64* %12, align 8, !insn.addr !4558
  %14 = add i64 %3, 24, !insn.addr !4559
  %15 = inttoptr i64 %14 to i64*, !insn.addr !4559
  store i64 %13, i64* %15, align 8, !insn.addr !4559
  %16 = call i64 @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv(i64* %arg2), !insn.addr !4560
  %17 = trunc i64 %16 to i8, !insn.addr !4561
  %18 = icmp eq i8 %17, 0, !insn.addr !4561
  store i64 %16, i64* %rax.0.reg2mem, !insn.addr !4562
  br i1 %18, label %dec_label_pc_111c6, label %dec_label_pc_11188, !insn.addr !4562

dec_label_pc_11188:                               ; preds = %dec_label_pc_11138
  %19 = add i64 %2, 8, !insn.addr !4563
  %20 = inttoptr i64 %19 to i64*, !insn.addr !4563
  %21 = load i64, i64* %20, align 8, !insn.addr !4563
  store i64 %2, i64* %result, align 8, !insn.addr !4564
  %22 = add i64 %3, 8, !insn.addr !4565
  %23 = inttoptr i64 %22 to i64*, !insn.addr !4565
  store i64 %21, i64* %23, align 8, !insn.addr !4565
  %24 = add i64 %2, 16, !insn.addr !4566
  %25 = inttoptr i64 %24 to i64*, !insn.addr !4566
  %26 = load i64, i64* %25, align 8, !insn.addr !4566
  store i64 %26, i64* %8, align 8, !insn.addr !4567
  store i64 0, i64* %25, align 8, !insn.addr !4568
  store i64 0, i64* %12, align 8, !insn.addr !4569
  store i64 %2, i64* %rax.0.reg2mem, !insn.addr !4569
  br label %dec_label_pc_111c6, !insn.addr !4569

dec_label_pc_111c6:                               ; preds = %dec_label_pc_11188, %dec_label_pc_11138
  %rax.0.reload = load i64, i64* %rax.0.reg2mem
  ret i64 %rax.0.reload, !insn.addr !4570

; uselistorder directives
  uselistorder i128 %4, { 1, 0 }
  uselistorder i64 0, { 210, 211, 220, 221, 0, 222, 99, 100, 1, 225, 96, 97, 213, 101, 98, 223, 224, 63, 64, 65, 214, 66, 67, 68, 248, 69, 70, 71, 102, 103, 2, 72, 104, 105, 106, 107, 215, 216, 217, 108, 109, 73, 110, 111, 74, 112, 113, 3, 114, 115, 116, 264, 4, 5, 6, 86, 7, 8, 9, 10, 247, 75, 76, 192, 256, 193, 204, 194, 205, 195, 257, 196, 261, 255, 11, 12, 206, 227, 13, 229, 230, 15, 252, 253, 14, 16, 254, 249, 250, 18, 17, 251, 259, 260, 258, 228, 226, 19, 117, 20, 197, 21, 22, 23, 24, 25, 26, 27, 231, 28, 29, 198, 30, 265, 268, 31, 32, 209, 212, 89, 218, 77, 33, 263, 34, 36, 35, 270, 78, 118, 119, 120, 121, 37, 38, 39, 122, 40, 41, 79, 80, 232, 42, 43, 44, 45, 46, 81, 235, 236, 233, 234, 123, 239, 90, 48, 237, 238, 49, 87, 47, 240, 242, 51, 241, 88, 50, 52, 53, 219, 54, 55, 56, 57, 58, 124, 125, 82, 83, 126, 127, 128, 129, 243, 244, 245, 199, 207, 246, 200, 60, 59, 130, 131, 132, 133, 134, 135, 61, 91, 262, 136, 137, 84, 85, 208, 201, 266, 267, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 269, 271, 186, 187, 272, 62, 188, 189, 190, 191, 92, 93, 94, 95, 202, 203 }
  uselistorder i8 0, { 10, 11, 12, 17, 18, 58, 19, 20, 21, 24, 25, 69, 59, 60, 70, 7, 53, 52, 51, 8, 15, 14, 22, 23, 49, 56, 57, 50, 122, 61, 62, 54, 55, 75, 76, 77, 78, 79, 80, 72, 87, 63, 64, 85, 86, 81, 83, 84, 82, 73, 74, 93, 71, 121, 118, 119, 120, 26, 27, 28, 29, 9, 1, 30, 90, 31, 32, 33, 91, 92, 34, 35, 36, 88, 13, 16, 6, 0, 2, 5, 37, 46, 45, 38, 39, 40, 41, 42, 43, 44, 4, 3, 47, 48, 65, 66, 67, 68, 89, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117 }
  uselistorder i64 (i64*)* @_ZNKSt8functionIFbN4llvm9StringRefERNS0_11PassManagerINS0_6ModuleENS0_15AnalysisManagerIS3_JEEEJEEENS0_8ArrayRefINS0_11PassBuilder15PipelineElementEEEEEcvbEv, { 1, 0 }
  uselistorder i64 24, { 2, 3, 4, 5, 7, 8, 9, 10, 11, 13, 15, 16, 17, 18, 14, 12, 19, 0, 20, 21, 22, 23, 6, 1 }
  uselistorder i64 (i64*)* @_ZNSt14_Function_baseC1Ev, { 2, 1, 0 }
  uselistorder i64 16, { 14, 15, 16, 23, 29, 30, 24, 26, 8, 25, 18, 19, 3, 32, 31, 0, 33, 1, 20, 35, 28, 27, 44, 34, 41, 42, 43, 47, 48, 49, 50, 45, 51, 46, 2, 17, 21, 4, 5, 36, 52, 53, 54, 9, 37, 38, 39, 55, 56, 10, 11, 12, 6, 57, 58, 59, 22, 7, 40, 13 }
  uselistorder void (i128, i128)* @__asm_movups, { 0, 1, 3, 4, 5, 6, 7, 2 }
  uselistorder i128 (i128, i128)* @__asm_pxor, { 0, 1, 3, 2 }
}

define i64 @_ZNKSt13move_iteratorIPSt8functionIFbN4llvm9StringRefERNS1_11PassManagerINS1_6ModuleENS1_15AnalysisManagerIS4_JEEEJEEENS1_8ArrayRefINS1_11PassBuilder15PipelineElementEEEEEE4baseEv(i64* %result) local_unnamed_addr {
dec_label_pc_111ca:
  %0 = ptrtoint i64* %result to i64
  ret i64 %0, !insn.addr !4571
}

define i64 @_ZNK4llvm12function_refIFNS_9StringRefES1_EEclES1_(i64* %this, i64* %result, i64 %arg3) local_unnamed_addr {
dec_label_pc_112ac:
  %0 = ptrtoint i64* %result to i64
  %stack_var_-56 = alloca i64, align 8
  store i64 %0, i64* %stack_var_-56, align 8, !insn.addr !4572
  %1 = call i64* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE(i64* nonnull %stack_var_-56), !insn.addr !4573
  %2 = ptrtoint i64* %1 to i64, !insn.addr !4573
  %3 = add i64 %2, 8, !insn.addr !4574
  %4 = inttoptr i64 %3 to i64*, !insn.addr !4574
  %5 = load i64, i64* %4, align 8, !insn.addr !4574
  ret i64 %5, !insn.addr !4575

; uselistorder directives
  uselistorder i64 8, { 23, 36, 37, 13, 0, 39, 40, 1, 41, 2, 29, 3, 42, 14, 4, 43, 44, 15, 45, 16, 46, 61, 62, 47, 48, 17, 53, 54, 55, 81, 63, 5, 64, 89, 56, 57, 38, 65, 82, 90, 91, 18, 49, 50, 51, 52, 6, 7, 59, 58, 8, 9, 12, 60, 83, 66, 85, 84, 10, 11, 87, 86, 94, 95, 96, 97, 98, 99, 92, 100, 93, 88, 24, 102, 104, 101, 103, 25, 26, 67, 68, 19, 27, 28, 69, 70, 105, 106, 107, 30, 71, 72, 20, 73, 74, 21, 108, 109, 31, 32, 33, 34, 76, 75, 77, 110, 111, 112, 78, 22, 35, 79, 80 }
  uselistorder i64* (i64*)* @_ZSt7forwardIN4llvm9StringRefEEOT_RNSt16remove_referenceIS2_E4typeE, { 3, 2, 1, 0 }
  uselistorder i32 1, { 298, 290, 29, 3, 300, 299, 31, 30, 301, 303, 302, 32, 35, 34, 33, 305, 304, 36, 28, 27, 37, 307, 306, 38, 39, 40, 308, 41, 310, 309, 43, 42, 311, 44, 278, 313, 312, 45, 315, 314, 316, 46, 26, 317, 47, 318, 48, 319, 49, 320, 50, 321, 51, 322, 52, 323, 53, 324, 54, 325, 55, 56, 326, 57, 327, 58, 328, 59, 329, 60, 330, 61, 331, 62, 332, 63, 333, 64, 334, 65, 289, 66, 2, 25, 67, 335, 68, 336, 69, 337, 70, 338, 71, 339, 72, 24, 73, 23, 340, 74, 341, 75, 292, 342, 76, 77, 22, 78, 343, 79, 80, 81, 344, 83, 82, 84, 85, 345, 86, 346, 87, 88, 348, 347, 349, 89, 350, 90, 21, 91, 92, 93, 94, 95, 96, 97, 98, 351, 99, 352, 100, 353, 101, 354, 102, 355, 103, 104, 279, 356, 105, 106, 357, 107, 108, 110, 109, 358, 359, 360, 20, 361, 112, 111, 362, 288, 1, 363, 113, 364, 365, 114, 366, 115, 367, 118, 117, 116, 121, 120, 119, 122, 280, 371, 370, 369, 368, 126, 125, 124, 123, 127, 375, 374, 373, 372, 130, 129, 128, 19, 376, 131, 377, 132, 379, 378, 134, 133, 18, 381, 380, 136, 135, 17, 137, 138, 382, 139, 383, 140, 293, 384, 385, 386, 141, 281, 142, 16, 387, 146, 145, 144, 143, 388, 389, 390, 391, 392, 393, 394, 395, 147, 148, 149, 150, 396, 151, 397, 152, 153, 154, 159, 158, 157, 156, 155, 160, 161, 291, 163, 162, 164, 165, 166, 167, 168, 15, 398, 169, 14, 399, 170, 401, 400, 171, 404, 403, 402, 172, 405, 173, 174, 409, 408, 407, 406, 175, 410, 176, 411, 177, 412, 178, 413, 179, 180, 13, 12, 181, 11, 182, 184, 183, 10, 295, 414, 185, 9, 415, 186, 418, 417, 416, 188, 187, 419, 296, 189, 282, 421, 420, 192, 191, 190, 423, 422, 195, 194, 193, 424, 275, 274, 426, 425, 196, 198, 197, 284, 283, 427, 297, 201, 200, 199, 428, 203, 202, 205, 204, 206, 429, 431, 430, 276, 432, 285, 212, 434, 433, 216, 215, 214, 213, 211, 210, 209, 208, 207, 435, 218, 217, 286, 223, 436, 225, 224, 222, 221, 220, 219, 438, 437, 227, 226, 228, 229, 8, 7, 440, 439, 442, 441, 444, 443, 287, 230, 0, 445, 231, 294, 233, 232, 235, 234, 239, 238, 237, 236, 241, 240, 446, 243, 242, 448, 447, 450, 449, 452, 451, 514, 454, 453, 244, 455, 246, 245, 6, 457, 456, 247, 260, 515, 467, 466, 465, 464, 463, 462, 461, 460, 459, 458, 265, 264, 263, 262, 261, 259, 258, 257, 256, 255, 254, 253, 252, 251, 250, 249, 248, 468, 266, 470, 469, 268, 267, 480, 479, 478, 477, 476, 475, 474, 473, 472, 471, 269, 504, 503, 502, 501, 500, 499, 498, 497, 496, 495, 494, 493, 492, 491, 490, 489, 488, 487, 486, 485, 484, 483, 482, 481, 271, 270, 5, 505, 272, 4, 507, 506, 509, 508, 277, 273, 513, 512, 511, 510 }
}

declare i64 @memcmp(i64, i64, i64) local_unnamed_addr

declare i64 @strlen(i64) local_unnamed_addr

declare i64 @memchr(i64, i64, i64, i64) local_unnamed_addr

declare i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4dataEv(i64*) local_unnamed_addr

declare i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE6lengthEv(i64*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev(i64*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EPKcmRKS3_(i64*, i8*, i64, i64*) local_unnamed_addr

declare i64 @__stack_chk_fail() local_unnamed_addr

declare i64 @__assert_fail(i64, i64, i64, i64) local_unnamed_addr

declare i64 @_ZN4llvm11raw_ostream5writeEPKcm(i64*, i8*, i64) local_unnamed_addr

declare i64 @memcpy(i64, i64, i64) local_unnamed_addr

declare i64 @_ZN4llvm11raw_ostreamlsEm(i64*, i64) local_unnamed_addr

declare i64 @_ZNK4llvm5Value17stripPointerCastsEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm16MetadataTracking5trackEPvRNS_8MetadataENS_12PointerUnionIJPNS_15MetadataAsValueEPS2_PNS_14DebugValueUserEEEE(i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZN4llvm16MetadataTracking7untrackEPvRNS_8MetadataE(i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm16MetadataTracking7retrackEPvRNS_8MetadataES1_(i64*, i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm4UsernwEmNS0_28IntrusiveOperandsAllocMarkerE(i64*, i64, i64) local_unnamed_addr

declare i64 @_ZNK4llvm10StructType24containsHomogeneousTypesEv(i64*) local_unnamed_addr

declare i64 @_ZNK4llvm11Instruction17getStableDebugLocEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm11Instruction11setMetadataEjPNS_6MDNodeE(i64*, i64*, i32, i64*) local_unnamed_addr

declare i64 @_ZNK4llvm13IRBuilderBase20SetInstDebugLocationEPNS_11InstructionE(i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm11Instruction16setFastMathFlagsENS_13FastMathFlagsE(i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZN4llvm8CastInst6CreateENS_11Instruction7CastOpsEPNS_5ValueEPNS_4TypeERKNS_5TwineENS_14InsertPositionE(i64*, i64, i64*, i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZN4llvm11Instruction20setHasNoUnsignedWrapEb(i64*, i1) local_unnamed_addr

declare i64 @_ZN4llvm11Instruction18setHasNoSignedWrapEb(i64*, i1) local_unnamed_addr

declare i64 @_ZN4llvm8ZExtInstC1EPNS_5ValueEPNS_4TypeERKNS_5TwineENS_14InsertPositionE(i64*, i64*, i64*, i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZN4llvm11Instruction9setNonNegEb(i64*, i1) local_unnamed_addr

declare i64 @_ZN4llvm19SmallPtrSetImplBase14insert_imp_bigEPKv(i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm25llvm_unreachable_internalEPKcS1_j(i8*, i8*, i32) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEED1Ev(i64*) local_unnamed_addr

declare i64 @_ZN4llvm12DenseMapInfoINS_9StringRefEvE12getHashValueES1_(i64*, i64) local_unnamed_addr

declare i64 @getenv(i64) local_unnamed_addr

declare i64 @_ZNK4llvm5Value7getNameEv(i64*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSEOS4_(i64*, i64*, i64*) local_unnamed_addr

declare i64 @_ZNK4llvm5Twine3strB5cxx11Ev(i64*, i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm15IRBuilderFolderD2Ev(i64*) local_unnamed_addr

declare i64 @_ZdlPvm(i64*, i64) local_unnamed_addr

declare i64 @_ZN4llvm24IRBuilderDefaultInserterD1Ev(i64*) local_unnamed_addr

declare i64 @_ZNK4llvm11GlobalValue13isDeclarationEv(i64*) local_unnamed_addr

declare i64 @_ZNK4llvm11Instruction8isAtomicEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm5Value18replaceAllUsesWithEPS0_(i64*, i64*) local_unnamed_addr

declare i64 @_ZNK4llvm11Instruction16mayWriteToMemoryEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm11Instruction15eraseFromParentEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm4errsEv() local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_local_dataEv(i64*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_Alloc_hiderC1EPcRKS3_(i64*, i8*, i64*) local_unnamed_addr

declare i64 @_ZSt19__throw_logic_errorPKc(i8*) local_unnamed_addr

declare i64 @_ZNK4llvm15SmallVectorBaseIjE4sizeEv(i64*) local_unnamed_addr

declare i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE4sizeEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjE8set_sizeEm(i64*, i64) local_unnamed_addr

declare i64 @_ZN4llvm18getAsSignedIntegerENS_9StringRefEjRx(i64*, i64, i32, i64*) local_unnamed_addr

declare i64 @_ZN4llvm17deallocate_bufferEPvmm(i64*, i64, i64) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEaSERKS4_(i64*, i64*) local_unnamed_addr

declare i64 @_ZNK4llvm5Value10getContextEv(i64*) local_unnamed_addr

declare i64 @_Znwm(i64) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE10_M_disposeEv(i64*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm(i64*, i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEPc(i64*, i8*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE11_M_capacityEm(i64*, i64) local_unnamed_addr

declare i64 @_ZNKSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE7_M_dataEv(i64*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_S_copy_charsEPcPKcS7_(i8*, i8*, i8*) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE13_M_set_lengthEm(i64*, i64) local_unnamed_addr

declare i64 @free(i64) local_unnamed_addr

declare i64 @_ZNK4llvm15SmallVectorBaseIjE8capacityEv(i64*) local_unnamed_addr

declare i64 @_ZN4llvm15allocate_bufferEmm(i64*, i64, i64) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1ERKS4_(i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjEC2EPvm(i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1EOS4_(i64*, i64*) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjE13mallocForGrowEPvmmRm(i64*, i64*, i64, i64, i64*) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjE20set_allocation_rangeEPvm(i64*, i64*, i64) local_unnamed_addr

declare i64 @_ZN4llvm15SmallVectorBaseIjE8grow_podEPvmm(i64*, i64*, i64, i64) local_unnamed_addr

declare i64 @_ZSt20__throw_length_errorPKc(i8*) local_unnamed_addr

declare i64 @_ZSt28__throw_bad_array_new_lengthv() local_unnamed_addr

declare i64 @_ZSt17__throw_bad_allocv() local_unnamed_addr

; Function Attrs: nounwind readnone speculatable
declare i32 @llvm.ctlz.i32(i32, i1) #0

declare i128 @__asm_pxor(i128, i128) local_unnamed_addr

declare void @__asm_movups(i128, i128) local_unnamed_addr

declare void @__asm_movq(i64, i128) local_unnamed_addr

declare i64 @__readfsqword(i64) local_unnamed_addr

attributes #0 = { nounwind readnone speculatable }

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
!21 = !{i64 478}
!22 = !{i64 485}
!23 = !{i64 497}
!24 = !{i64 504}
!25 = !{i64 517}
!26 = !{i64 563}
!27 = !{i64 572}
!28 = !{i64 606}
!29 = !{i64 615}
!30 = !{i64 630}
!31 = !{i64 643}
!32 = !{i64 654}
!33 = !{i64 663}
!34 = !{i64 665}
!35 = !{i64 675}
!36 = !{i64 688}
!37 = !{i64 734}
!38 = !{i64 743}
!39 = !{i64 777}
!40 = !{i64 786}
!41 = !{i64 801}
!42 = !{i64 814}
!43 = !{i64 825}
!44 = !{i64 834}
!45 = !{i64 836}
!46 = !{i64 846}
!47 = !{i64 847}
!48 = !{i64 859}
!49 = !{i64 888}
!50 = !{i64 893}
!51 = !{i64 907}
!52 = !{i64 916}
!53 = !{i64 925}
!54 = !{i64 927}
!55 = !{i64 933}
!56 = !{i64 964}
!57 = !{i64 970}
!58 = !{i64 989}
!59 = !{i64 994}
!60 = !{i64 997}
!61 = !{i64 1001}
!62 = !{i64 1002}
!63 = !{i64 1040}
!64 = !{i64 1075}
!65 = !{i64 1080}
!66 = !{i64 1114}
!67 = !{i64 1119}
!68 = !{i64 1121}
!69 = !{i64 1147}
!70 = !{i64 1152}
!71 = !{i64 1186}
!72 = !{i64 1191}
!73 = !{i64 1193}
!74 = !{i64 1219}
!75 = !{i64 1224}
!76 = !{i64 1258}
!77 = !{i64 1263}
!78 = !{i64 1265}
!79 = !{i64 1291}
!80 = !{i64 1296}
!81 = !{i64 1330}
!82 = !{i64 1335}
!83 = !{i64 1337}
!84 = !{i64 1363}
!85 = !{i64 1368}
!86 = !{i64 1402}
!87 = !{i64 1407}
!88 = !{i64 1409}
!89 = !{i64 1435}
!90 = !{i64 1440}
!91 = !{i64 1474}
!92 = !{i64 1479}
!93 = !{i64 1481}
!94 = !{i64 1507}
!95 = !{i64 1512}
!96 = !{i64 1546}
!97 = !{i64 1551}
!98 = !{i64 1553}
!99 = !{i64 1579}
!100 = !{i64 1584}
!101 = !{i64 1618}
!102 = !{i64 1623}
!103 = !{i64 1625}
!104 = !{i64 1651}
!105 = !{i64 1656}
!106 = !{i64 1690}
!107 = !{i64 1695}
!108 = !{i64 1697}
!109 = !{i64 1723}
!110 = !{i64 1728}
!111 = !{i64 1762}
!112 = !{i64 1767}
!113 = !{i64 1769}
!114 = !{i64 1795}
!115 = !{i64 1800}
!116 = !{i64 1834}
!117 = !{i64 1839}
!118 = !{i64 1841}
!119 = !{i64 1867}
!120 = !{i64 1872}
!121 = !{i64 1906}
!122 = !{i64 1911}
!123 = !{i64 1913}
!124 = !{i64 1939}
!125 = !{i64 1944}
!126 = !{i64 1978}
!127 = !{i64 1983}
!128 = !{i64 1985}
!129 = !{i64 2011}
!130 = !{i64 2016}
!131 = !{i64 2050}
!132 = !{i64 2055}
!133 = !{i64 2057}
!134 = !{i64 2083}
!135 = !{i64 2088}
!136 = !{i64 2122}
!137 = !{i64 2127}
!138 = !{i64 2129}
!139 = !{i64 2155}
!140 = !{i64 2160}
!141 = !{i64 2194}
!142 = !{i64 2199}
!143 = !{i64 2201}
!144 = !{i64 2227}
!145 = !{i64 2232}
!146 = !{i64 2266}
!147 = !{i64 2271}
!148 = !{i64 2273}
!149 = !{i64 2296}
!150 = !{i64 2301}
!151 = !{i64 2329}
!152 = !{i64 2334}
!153 = !{i64 2336}
!154 = !{i64 2359}
!155 = !{i64 2364}
!156 = !{i64 2392}
!157 = !{i64 2397}
!158 = !{i64 2399}
!159 = !{i64 2422}
!160 = !{i64 2427}
!161 = !{i64 2455}
!162 = !{i64 2460}
!163 = !{i64 2462}
!164 = !{i64 2485}
!165 = !{i64 2490}
!166 = !{i64 2518}
!167 = !{i64 2523}
!168 = !{i64 2525}
!169 = !{i64 2548}
!170 = !{i64 2553}
!171 = !{i64 2581}
!172 = !{i64 2586}
!173 = !{i64 2588}
!174 = !{i64 2607}
!175 = !{i64 2612}
!176 = !{i64 2640}
!177 = !{i64 2645}
!178 = !{i64 2647}
!179 = !{i64 2666}
!180 = !{i64 2671}
!181 = !{i64 2699}
!182 = !{i64 2704}
!183 = !{i64 2724}
!184 = !{i64 2733}
!185 = !{i64 2735}
!186 = !{i64 2741}
!187 = !{i64 2761}
!188 = !{i64 2768}
!189 = !{i64 2789}
!190 = !{i64 2796}
!191 = !{i64 2817}
!192 = !{i64 2826}
!193 = !{i64 2833}
!194 = !{i64 2842}
!195 = !{i64 2852}
!196 = !{i64 2853}
!197 = !{i64 2882}
!198 = !{i64 2897}
!199 = !{i64 2905}
!200 = !{i64 2917}
!201 = !{i64 2922}
!202 = !{i64 2932}
!203 = !{i64 2944}
!204 = !{i64 2952}
!205 = !{i64 2964}
!206 = !{i64 2969}
!207 = !{i64 2984}
!208 = !{i64 2989}
!209 = !{i64 3023}
!210 = !{i64 3035}
!211 = !{i64 3043}
!212 = !{i64 3055}
!213 = !{i64 3060}
!214 = !{i64 3085}
!215 = !{i64 3090}
!216 = !{i64 3124}
!217 = !{i64 3132}
!218 = !{i64 3134}
!219 = !{i64 3146}
!220 = !{i64 3151}
!221 = !{i64 3163}
!222 = !{i64 3182}
!223 = !{i64 3194}
!224 = !{i64 3202}
!225 = !{i64 3214}
!226 = !{i64 3219}
!227 = !{i64 3255}
!228 = !{i64 3260}
!229 = !{i64 3274}
!230 = !{i64 3295}
!231 = !{i64 3300}
!232 = !{i64 3302}
!233 = !{i64 3326}
!234 = !{i64 3331}
!235 = !{i64 3333}
!236 = !{i64 3378}
!237 = !{i64 3400}
!238 = !{i64 3423}
!239 = !{i64 3435}
!240 = !{i64 3471}
!241 = !{i64 3503}
!242 = !{i64 3535}
!243 = !{i64 3557}
!244 = !{i64 3576}
!245 = !{i64 3588}
!246 = !{i64 3610}
!247 = !{i64 3622}
!248 = !{i64 3361}
!249 = !{i64 3366}
!250 = !{i64 3631}
!251 = !{i64 3640}
!252 = !{i64 3642}
!253 = !{i64 3655}
!254 = !{i64 3656}
!255 = !{i64 3687}
!256 = !{i64 3709}
!257 = !{i64 3722}
!258 = !{i64 3729}
!259 = !{i64 3747}
!260 = !{i64 3752}
!261 = !{i64 3754}
!262 = !{i64 3766}
!263 = !{i64 3771}
!264 = !{i64 3773}
!265 = !{i64 3879}
!266 = !{i64 3884}
!267 = !{i64 3886}
!268 = !{i64 3802}
!269 = !{i64 3807}
!270 = !{i64 3836}
!271 = !{i64 3862}
!272 = !{i64 3867}
!273 = !{i64 3898}
!274 = !{i64 3903}
!275 = !{i64 3905}
!276 = !{i64 4011}
!277 = !{i64 4030}
!278 = !{i64 4039}
!279 = !{i64 4046}
!280 = !{i64 4051}
!281 = !{i64 4044}
!282 = !{i64 3934}
!283 = !{i64 3939}
!284 = !{i64 3968}
!285 = !{i64 3994}
!286 = !{i64 3999}
!287 = !{i64 4070}
!288 = !{i64 4075}
!289 = !{i64 4085}
!290 = !{i64 4090}
!291 = !{i64 4096}
!292 = !{i64 4099}
!293 = !{i64 4113}
!294 = !{i64 4116}
!295 = !{i64 4163}
!296 = !{i64 4195}
!297 = !{i64 4200}
!298 = !{i64 4247}
!299 = !{i64 4285}
!300 = !{i64 4290}
!301 = !{i64 4295}
!302 = !{i64 4304}
!303 = !{i64 4306}
!304 = !{i64 4316}
!305 = !{i64 4317}
!306 = !{i64 4333}
!307 = !{i64 4352}
!308 = !{i64 4363}
!309 = !{i64 4368}
!310 = !{i64 4388}
!311 = !{i64 4397}
!312 = !{i64 4399}
!313 = !{i64 4405}
!314 = !{i64 4406}
!315 = !{i64 4431}
!316 = !{i64 4456}
!317 = !{i64 4461}
!318 = !{i64 4463}
!319 = !{i64 4475}
!320 = !{i64 4480}
!321 = !{i64 4498}
!322 = !{i64 4537}
!323 = !{i64 4566}
!324 = !{i64 4571}
!325 = !{i64 4588}
!326 = !{i64 4593}
!327 = !{i64 5790}
!328 = !{i64 5795}
!329 = !{i64 5797}
!330 = !{i64 5770}
!331 = !{i64 4615}
!332 = !{i64 4642}
!333 = !{i64 4671}
!334 = !{i64 4676}
!335 = !{i64 4700}
!336 = !{i64 4705}
!337 = !{i64 5727}
!338 = !{i64 5732}
!339 = !{i64 5734}
!340 = !{i64 4734}
!341 = !{i64 4756}
!342 = !{i64 4768}
!343 = !{i64 4776}
!344 = !{i64 4792}
!345 = !{i64 4797}
!346 = !{i64 4799}
!347 = !{i64 4811}
!348 = !{i64 4816}
!349 = !{i64 4832}
!350 = !{i64 4834}
!351 = !{i64 4846}
!352 = !{i64 4851}
!353 = !{i64 4866}
!354 = !{i64 4887}
!355 = !{i64 4902}
!356 = !{i64 4910}
!357 = !{i64 4912}
!358 = !{i64 4928}
!359 = !{i64 4949}
!360 = !{i64 4954}
!361 = !{i64 4978}
!362 = !{i64 4983}
!363 = !{i64 5017}
!364 = !{i64 5022}
!365 = !{i64 5024}
!366 = !{i64 5030}
!367 = !{i64 5062}
!368 = !{i64 5067}
!369 = !{i64 5109}
!370 = !{i64 5124}
!371 = !{i64 5142}
!372 = !{i64 5147}
!373 = !{i64 5167}
!374 = !{i64 5179}
!375 = !{i64 5187}
!376 = !{i64 5209}
!377 = !{i64 5234}
!378 = !{i64 5246}
!379 = !{i64 5253}
!380 = !{i64 5266}
!381 = !{i64 5271}
!382 = !{i64 5287}
!383 = !{i64 5292}
!384 = !{i64 5307}
!385 = !{i64 5319}
!386 = !{i64 5327}
!387 = !{i64 5343}
!388 = !{i64 5348}
!389 = !{i64 5350}
!390 = !{i64 5362}
!391 = !{i64 5367}
!392 = !{i64 5383}
!393 = !{i64 5385}
!394 = !{i64 5397}
!395 = !{i64 5402}
!396 = !{i64 5417}
!397 = !{i64 5438}
!398 = !{i64 5453}
!399 = !{i64 5461}
!400 = !{i64 5463}
!401 = !{i64 5475}
!402 = !{i64 5480}
!403 = !{i64 5492}
!404 = !{i64 5513}
!405 = !{i64 5531}
!406 = !{i64 5549}
!407 = !{i64 5557}
!408 = !{i64 5562}
!409 = !{i64 5565}
!410 = !{i64 5569}
!411 = !{i64 5580}
!412 = !{i64 5585}
!413 = !{i64 5597}
!414 = !{i64 5609}
!415 = !{i64 5617}
!416 = !{i64 5629}
!417 = !{i64 5634}
!418 = !{i64 5636}
!419 = !{i64 5648}
!420 = !{i64 5653}
!421 = !{i64 5665}
!422 = !{i64 5670}
!423 = !{i64 5672}
!424 = !{i64 5684}
!425 = !{i64 5689}
!426 = !{i64 5702}
!427 = !{i64 5750}
!428 = !{i64 5765}
!429 = !{i64 5827}
!430 = !{i64 5849}
!431 = !{i64 5910}
!432 = !{i64 5917}
!433 = !{i64 5870}
!434 = !{i64 5890}
!435 = !{i64 5895}
!436 = !{i64 5919}
!437 = !{i64 5924}
!438 = !{i64 5928}
!439 = !{i64 5926}
!440 = !{i64 5957}
!441 = !{i64 5978}
!442 = !{i64 5996}
!443 = !{i64 6028}
!444 = !{i64 6049}
!445 = !{i64 6068}
!446 = !{i64 6089}
!447 = !{i64 6094}
!448 = !{i64 6111}
!449 = !{i64 6122}
!450 = !{i64 6131}
!451 = !{i64 6133}
!452 = !{i64 6149}
!453 = !{i64 6150}
!454 = !{i64 6178}
!455 = !{i64 6212}
!456 = !{i64 6217}
!457 = !{i64 6228}
!458 = !{i64 6233}
!459 = !{i64 6307}
!460 = !{i64 6312}
!461 = !{i64 6314}
!462 = !{i64 6246}
!463 = !{i64 6262}
!464 = !{i64 6267}
!465 = !{i64 6273}
!466 = !{i64 6275}
!467 = !{i64 6278}
!468 = !{i64 6288}
!469 = !{i64 6320}
!470 = !{i64 6329}
!471 = !{i64 6334}
!472 = !{i64 6343}
!473 = !{i64 6352}
!474 = !{i64 6361}
!475 = !{i64 6363}
!476 = !{i64 6373}
!477 = !{i64 6374}
!478 = !{i64 6415}
!479 = !{i64 6447}
!480 = !{i64 6452}
!481 = !{i64 6474}
!482 = !{i64 6479}
!483 = !{i64 6481}
!484 = !{i64 6497}
!485 = !{i64 6507}
!486 = !{i64 6518}
!487 = !{i64 6527}
!488 = !{i64 6529}
!489 = !{i64 6535}
!490 = !{i64 6536}
!491 = !{i64 6552}
!492 = !{i64 6581}
!493 = !{i64 6600}
!494 = !{i64 6612}
!495 = !{i64 6622}
!496 = !{i64 6631}
!497 = !{i64 6633}
!498 = !{i64 6639}
!499 = !{i64 6668}
!500 = !{i64 6674}
!501 = !{i64 6691}
!502 = !{i64 6708}
!503 = !{i64 6723}
!504 = !{i64 6738}
!505 = !{i64 6747}
!506 = !{i64 6768}
!507 = !{i64 6790}
!508 = !{i64 6806}
!509 = !{i64 6830}
!510 = !{i64 6833}
!511 = !{i64 6853}
!512 = !{i64 6856}
!513 = !{i64 6928}
!514 = !{i64 6942}
!515 = !{i64 6951}
!516 = !{i64 6953}
!517 = !{i64 6963}
!518 = !{i64 6980}
!519 = !{i64 7002}
!520 = !{i64 7020}
!521 = !{i64 7030}
!522 = !{i64 7039}
!523 = !{i64 7041}
!524 = !{i64 7051}
!525 = !{i64 7071}
!526 = !{i64 7080}
!527 = !{i64 7125}
!528 = !{i64 7139}
!529 = !{i64 7156}
!530 = !{i64 7178}
!531 = !{i64 7196}
!532 = !{i64 7206}
!533 = !{i64 7215}
!534 = !{i64 7217}
!535 = !{i64 7227}
!536 = !{i64 7252}
!537 = !{i64 7264}
!538 = !{i64 7350}
!539 = !{i64 7368}
!540 = !{i64 7389}
!541 = !{i64 7398}
!542 = !{i64 7404}
!543 = !{i64 7425}
!544 = !{i64 7432}
!545 = !{i64 7453}
!546 = !{i64 7460}
!547 = !{i64 7481}
!548 = !{i64 7488}
!549 = !{i64 7509}
!550 = !{i64 7516}
!551 = !{i64 7537}
!552 = !{i64 7544}
!553 = !{i64 7565}
!554 = !{i64 7572}
!555 = !{i64 7593}
!556 = !{i64 7605}
!557 = !{i64 7612}
!558 = !{i64 7642}
!559 = !{i64 7653}
!560 = !{i64 7664}
!561 = !{i64 7693}
!562 = !{i64 7700}
!563 = !{i64 7721}
!564 = !{i64 7730}
!565 = !{i64 7733}
!566 = !{i64 7751}
!567 = !{i64 7776}
!568 = !{i64 7783}
!569 = !{i64 7814}
!570 = !{i64 7823}
!571 = !{i64 7831}
!572 = !{i64 7841}
!573 = !{i64 7850}
!574 = !{i64 7858}
!575 = !{i64 7867}
!576 = !{i64 7868}
!577 = !{i64 7881}
!578 = !{i64 7903}
!579 = !{i64 7915}
!580 = !{i64 7920}
!581 = !{i64 7922}
!582 = !{i64 7931}
!583 = !{i64 7936}
!584 = !{i64 7938}
!585 = !{i64 7967}
!586 = !{i64 7972}
!587 = !{i64 7986}
!588 = !{i64 7991}
!589 = !{i64 7993}
!590 = !{i64 8002}
!591 = !{i64 8007}
!592 = !{i64 8010}
!593 = !{i64 8052}
!594 = !{i64 8064}
!595 = !{i64 8080}
!596 = !{i64 8130}
!597 = !{i64 8134}
!598 = !{i64 8035}
!599 = !{i64 8040}
!600 = !{i64 8098}
!601 = !{i64 8116}
!602 = !{i64 8121}
!603 = !{i64 8148}
!604 = !{i64 8165}
!605 = !{i64 8177}
!606 = !{i64 8182}
!607 = !{i64 8189}
!608 = !{i64 8198}
!609 = !{i64 8200}
!610 = !{i64 8210}
!611 = !{i64 8231}
!612 = !{i64 8237}
!613 = !{i64 8257}
!614 = !{i64 8263}
!615 = !{i64 8264}
!616 = !{i64 8294}
!617 = !{i64 8303}
!618 = !{i64 8308}
!619 = !{i64 8310}
!620 = !{i64 8315}
!621 = !{i64 8317}
!622 = !{i64 8326}
!623 = !{i64 8331}
!624 = !{i64 8340}
!625 = !{i64 8369}
!626 = !{i64 8374}
!627 = !{i64 8383}
!628 = !{i64 8388}
!629 = !{i64 8390}
!630 = !{i64 8412}
!631 = !{i64 8427}
!632 = !{i64 8458}
!633 = !{i64 8468}
!634 = !{i64 8469}
!635 = !{i64 8493}
!636 = !{i64 8496}
!637 = !{i64 8505}
!638 = !{i64 8510}
!639 = !{i64 8512}
!640 = !{i64 8549}
!641 = !{i64 8561}
!642 = !{i64 8564}
!643 = !{i64 8573}
!644 = !{i64 8578}
!645 = !{i64 8580}
!646 = !{i64 8617}
!647 = !{i64 8629}
!648 = !{i64 8644}
!649 = !{i64 8649}
!650 = !{i64 8652}
!651 = !{i64 8689}
!652 = !{i64 8708}
!653 = !{i64 8711}
!654 = !{i64 8719}
!655 = !{i64 8720}
!656 = !{i64 8739}
!657 = !{i64 8744}
!658 = !{i64 8746}
!659 = !{i64 8783}
!660 = !{i64 8799}
!661 = !{i64 8803}
!662 = !{i64 8806}
!663 = !{i64 8843}
!664 = !{i64 8848}
!665 = !{i64 8853}
!666 = !{i64 8878}
!667 = !{i64 8880}
!668 = !{i64 8896}
!669 = !{i64 8929}
!670 = !{i64 8934}
!671 = !{i64 8936}
!672 = !{i64 8938}
!673 = !{i64 8946}
!674 = !{i64 8966}
!675 = !{i64 8971}
!676 = !{i64 8979}
!677 = !{i64 8988}
!678 = !{i64 8990}
!679 = !{i64 8996}
!680 = !{i64 8998}
!681 = !{i64 9017}
!682 = !{i64 9041}
!683 = !{i64 9056}
!684 = !{i64 9064}
!685 = !{i64 9079}
!686 = !{i64 9094}
!687 = !{i64 9106}
!688 = !{i64 9116}
!689 = !{i64 9125}
!690 = !{i64 9127}
!691 = !{i64 9140}
!692 = !{i64 9142}
!693 = !{i64 9162}
!694 = !{i64 9166}
!695 = !{i64 9169}
!696 = !{i64 9181}
!697 = !{i64 9190}
!698 = !{i64 9205}
!699 = !{i64 9210}
!700 = !{i64 9212}
!701 = !{i64 9221}
!702 = !{i64 9239}
!703 = !{i64 9255}
!704 = !{i64 9270}
!705 = !{i64 9276}
!706 = !{i64 9316}
!707 = !{i64 9323}
!708 = !{i64 9348}
!709 = !{i64 9360}
!710 = !{i64 9430}
!711 = !{i64 9448}
!712 = !{i64 9462}
!713 = !{i64 9479}
!714 = !{i64 9501}
!715 = !{i64 9524}
!716 = !{i64 9535}
!717 = !{i64 9544}
!718 = !{i64 9546}
!719 = !{i64 9556}
!720 = !{i64 9570}
!721 = !{i64 9584}
!722 = !{i64 9607}
!723 = !{i64 9651}
!724 = !{i64 9664}
!725 = !{i64 9675}
!726 = !{i64 9686}
!727 = !{i64 9697}
!728 = !{i64 9714}
!729 = !{i64 9736}
!730 = !{i64 9759}
!731 = !{i64 9770}
!732 = !{i64 9779}
!733 = !{i64 9781}
!734 = !{i64 9791}
!735 = !{i64 9805}
!736 = !{i64 9822}
!737 = !{i64 9834}
!738 = !{i64 9837}
!739 = !{i64 9841}
!740 = !{i64 9844}
!741 = !{i64 9848}
!742 = !{i64 9852}
!743 = !{i64 9856}
!744 = !{i64 9860}
!745 = !{i64 9871}
!746 = !{i64 9883}
!747 = !{i64 9886}
!748 = !{i64 9890}
!749 = !{i64 9894}
!750 = !{i64 9898}
!751 = !{i64 9902}
!752 = !{i64 9906}
!753 = !{i64 9910}
!754 = !{i64 9916}
!755 = !{i64 9928}
!756 = !{i64 9940}
!757 = !{i64 9942}
!758 = !{i64 9958}
!759 = !{i64 9962}
!760 = !{i64 9964}
!761 = !{i64 9973}
!762 = !{i64 9978}
!763 = !{i64 9984}
!764 = !{i64 9990}
!765 = !{i64 10004}
!766 = !{i64 10036}
!767 = !{i64 10043}
!768 = !{i64 10074}
!769 = !{i64 10081}
!770 = !{i64 10110}
!771 = !{i64 10121}
!772 = !{i64 10132}
!773 = !{i64 10134}
!774 = !{i64 10161}
!775 = !{i64 10166}
!776 = !{i64 10181}
!777 = !{i64 10186}
!778 = !{i64 10188}
!779 = !{i64 10197}
!780 = !{i64 10202}
!781 = !{i64 10208}
!782 = !{i64 10219}
!783 = !{i64 10228}
!784 = !{i64 10230}
!785 = !{i64 10248}
!786 = !{i64 10273}
!787 = !{i64 10278}
!788 = !{i64 10283}
!789 = !{i64 10285}
!790 = !{i64 10301}
!791 = !{i64 10313}
!792 = !{i64 10328}
!793 = !{i64 10350}
!794 = !{i64 10519}
!795 = !{i64 10526}
!796 = !{i64 10377}
!797 = !{i64 10398}
!798 = !{i64 10406}
!799 = !{i64 10408}
!800 = !{i64 10420}
!801 = !{i64 10438}
!802 = !{i64 10446}
!803 = !{i64 10448}
!804 = !{i64 10476}
!805 = !{i64 10491}
!806 = !{i64 10499}
!807 = !{i64 10504}
!808 = !{i64 10539}
!809 = !{i64 10554}
!810 = !{i64 10559}
!811 = !{i64 10566}
!812 = !{i64 10575}
!813 = !{i64 10577}
!814 = !{i64 10583}
!815 = !{i64 10603}
!816 = !{i64 10609}
!817 = !{i64 10629}
!818 = !{i64 10635}
!819 = !{i64 10655}
!820 = !{i64 10661}
!821 = !{i64 10681}
!822 = !{i64 10688}
!823 = !{i64 10701}
!824 = !{i64 10723}
!825 = !{i64 10732}
!826 = !{i64 10741}
!827 = !{i64 10743}
!828 = !{i64 10753}
!829 = !{i64 10773}
!830 = !{i64 10779}
!831 = !{i64 10800}
!832 = !{i64 10815}
!833 = !{i64 10820}
!834 = !{i64 10838}
!835 = !{i64 10842}
!836 = !{i64 10850}
!837 = !{i64 10865}
!838 = !{i64 10893}
!839 = !{i64 10900}
!840 = !{i64 10929}
!841 = !{i64 10936}
!842 = !{i64 10950}
!843 = !{i64 10955}
!844 = !{i64 10968}
!845 = !{i64 10973}
!846 = !{i64 10975}
!847 = !{i64 10984}
!848 = !{i64 11017}
!849 = !{i64 11023}
!850 = !{i64 11024}
!851 = !{i64 11050}
!852 = !{i64 11075}
!853 = !{i64 11094}
!854 = !{i64 11099}
!855 = !{i64 11102}
!856 = !{i64 11106}
!857 = !{i64 11125}
!858 = !{i64 11140}
!859 = !{i64 11148}
!860 = !{i64 11151}
!861 = !{i64 11163}
!862 = !{i64 11182}
!863 = !{i64 11193}
!864 = !{i64 11207}
!865 = !{i64 11228}
!866 = !{i64 11233}
!867 = !{i64 11236}
!868 = !{i64 11239}
!869 = !{i64 11242}
!870 = !{i64 11244}
!871 = !{i64 11259}
!872 = !{i64 11277}
!873 = !{i64 11282}
!874 = !{i64 11285}
!875 = !{i64 11288}
!876 = !{i64 11291}
!877 = !{i64 11293}
!878 = !{i64 11305}
!879 = !{i64 11311}
!880 = !{i64 11320}
!881 = !{i64 11335}
!882 = !{i64 11347}
!883 = !{i64 11356}
!884 = !{i64 11358}
!885 = !{i64 11368}
!886 = !{i64 11370}
!887 = !{i64 11400}
!888 = !{i64 11415}
!889 = !{i64 11420}
!890 = !{i64 11422}
!891 = !{i64 11431}
!892 = !{i64 11436}
!893 = !{i64 11440}
!894 = !{i64 11449}
!895 = !{i64 11454}
!896 = !{i64 11460}
!897 = !{i64 11494}
!898 = !{i64 11507}
!899 = !{i64 11535}
!900 = !{i64 11544}
!901 = !{i64 11552}
!902 = !{i64 11561}
!903 = !{i64 11563}
!904 = !{i64 11569}
!905 = !{i64 11584}
!906 = !{i64 11586}
!907 = !{i64 11619}
!908 = !{i64 11644}
!909 = !{i64 11666}
!910 = !{i64 11671}
!911 = !{i64 11677}
!912 = !{i64 11684}
!913 = !{i64 11693}
!914 = !{i64 11705}
!915 = !{i64 11731}
!916 = !{i64 11743}
!917 = !{i64 11768}
!918 = !{i64 11776}
!919 = !{i64 11778}
!920 = !{i64 11797}
!921 = !{i64 11805}
!922 = !{i64 11807}
!923 = !{i64 11844}
!924 = !{i64 11859}
!925 = !{i64 11870}
!926 = !{i64 11873}
!927 = !{i64 11891}
!928 = !{i64 11913}
!929 = !{i64 11927}
!930 = !{i64 11947}
!931 = !{i64 11968}
!932 = !{i64 11973}
!933 = !{i64 11976}
!934 = !{i64 11979}
!935 = !{i64 11982}
!936 = !{i64 11984}
!937 = !{i64 12000}
!938 = !{i64 12008}
!939 = !{i64 12023}
!940 = !{i64 12044}
!941 = !{i64 12049}
!942 = !{i64 12052}
!943 = !{i64 12055}
!944 = !{i64 12058}
!945 = !{i64 12060}
!946 = !{i64 12062}
!947 = !{i64 12095}
!948 = !{i64 12103}
!949 = !{i64 12115}
!950 = !{i64 12133}
!951 = !{i64 12138}
!952 = !{i64 12142}
!953 = !{i64 12150}
!954 = !{i64 12188}
!955 = !{i64 12197}
!956 = !{i64 12212}
!957 = !{i64 12230}
!958 = !{i64 12245}
!959 = !{i64 12250}
!960 = !{i64 12256}
!961 = !{i64 12265}
!962 = !{i64 12267}
!963 = !{i64 12277}
!964 = !{i64 12290}
!965 = !{i64 12301}
!966 = !{i64 12311}
!967 = !{i64 12351}
!968 = !{i64 12367}
!969 = !{i64 12382}
!970 = !{i64 12393}
!971 = !{i64 12405}
!972 = !{i64 12418}
!973 = !{i64 12423}
!974 = !{i64 12430}
!975 = !{i64 12441}
!976 = !{i64 12455}
!977 = !{i64 12469}
!978 = !{i64 12489}
!979 = !{i64 12505}
!980 = !{i64 12515}
!981 = !{i64 12522}
!982 = !{i64 12537}
!983 = !{i64 12551}
!984 = !{i64 12575}
!985 = !{i64 12593}
!986 = !{i64 12600}
!987 = !{i64 12641}
!988 = !{i64 12656}
!989 = !{i64 12671}
!990 = !{i64 12686}
!991 = !{i64 12703}
!992 = !{i64 12718}
!993 = !{i64 12746}
!994 = !{i64 12764}
!995 = !{i64 12776}
!996 = !{i64 12779}
!997 = !{i64 12788}
!998 = !{i64 12803}
!999 = !{i64 12808}
!1000 = !{i64 12811}
!1001 = !{i64 12830}
!1002 = !{i64 12845}
!1003 = !{i64 12880}
!1004 = !{i64 12893}
!1005 = !{i64 12904}
!1006 = !{i64 12911}
!1007 = !{i64 12928}
!1008 = !{i64 12940}
!1009 = !{i64 12943}
!1010 = !{i64 12947}
!1011 = !{i64 12950}
!1012 = !{i64 12954}
!1013 = !{i64 12958}
!1014 = !{i64 12969}
!1015 = !{i64 12981}
!1016 = !{i64 12984}
!1017 = !{i64 12988}
!1018 = !{i64 12992}
!1019 = !{i64 12996}
!1020 = !{i64 13000}
!1021 = !{i64 13006}
!1022 = !{i64 13024}
!1023 = !{i64 13036}
!1024 = !{i64 13039}
!1025 = !{i64 13043}
!1026 = !{i64 13046}
!1027 = !{i64 13050}
!1028 = !{i64 13054}
!1029 = !{i64 13060}
!1030 = !{i64 13092}
!1031 = !{i64 13099}
!1032 = !{i64 13116}
!1033 = !{i64 13127}
!1034 = !{i64 13134}
!1035 = !{i64 13164}
!1036 = !{i64 13175}
!1037 = !{i64 13184}
!1038 = !{i64 13194}
!1039 = !{i64 13196}
!1040 = !{i64 13211}
!1041 = !{i64 13215}
!1042 = !{i64 13227}
!1043 = !{i64 13237}
!1044 = !{i64 13241}
!1045 = !{i64 13247}
!1046 = !{i64 13255}
!1047 = !{i64 13261}
!1048 = !{i64 13262}
!1049 = !{i64 13284}
!1050 = !{i64 13294}
!1051 = !{i64 13296}
!1052 = !{i64 13323}
!1053 = !{i64 13341}
!1054 = !{i64 13353}
!1055 = !{i64 13368}
!1056 = !{i64 13374}
!1057 = !{i64 13406}
!1058 = !{i64 13415}
!1059 = !{i64 13423}
!1060 = !{i64 13433}
!1061 = !{i64 13442}
!1062 = !{i64 13450}
!1063 = !{i64 13456}
!1064 = !{i64 13458}
!1065 = !{i64 13471}
!1066 = !{i64 13498}
!1067 = !{i64 13515}
!1068 = !{i64 13527}
!1069 = !{i64 13541}
!1070 = !{i64 13546}
!1071 = !{i64 13549}
!1072 = !{i64 13551}
!1073 = !{i64 13553}
!1074 = !{i64 13590}
!1075 = !{i64 13602}
!1076 = !{i64 13614}
!1077 = !{i64 13630}
!1078 = !{i64 13693}
!1079 = !{i64 13697}
!1080 = !{i64 13648}
!1081 = !{i64 13661}
!1082 = !{i64 13679}
!1083 = !{i64 13684}
!1084 = !{i64 13706}
!1085 = !{i64 13715}
!1086 = !{i64 13724}
!1087 = !{i64 13726}
!1088 = !{i64 13736}
!1089 = !{i64 13749}
!1090 = !{i64 13771}
!1091 = !{i64 13780}
!1092 = !{i64 13789}
!1093 = !{i64 13791}
!1094 = !{i64 13801}
!1095 = !{i64 13814}
!1096 = !{i64 13819}
!1097 = !{i64 13832}
!1098 = !{i64 13836}
!1099 = !{i64 13850}
!1100 = !{i64 13854}
!1101 = !{i64 13868}
!1102 = !{i64 13872}
!1103 = !{i64 13874}
!1104 = !{i64 13886}
!1105 = !{i64 13905}
!1106 = !{i64 13915}
!1107 = !{i64 13928}
!1108 = !{i64 13940}
!1109 = !{i64 13944}
!1110 = !{i64 13951}
!1111 = !{i64 13956}
!1112 = !{i64 13966}
!1113 = !{i64 13970}
!1114 = !{i64 13973}
!1115 = !{i64 13991}
!1116 = !{i64 13994}
!1117 = !{i64 13999}
!1118 = !{i64 14001}
!1119 = !{i64 14008}
!1120 = !{i64 14011}
!1121 = !{i64 14014}
!1122 = !{i64 14023}
!1123 = !{i64 14028}
!1124 = !{i64 14030}
!1125 = !{i64 14049}
!1126 = !{i64 14074}
!1127 = !{i64 14091}
!1128 = !{i64 14100}
!1129 = !{i64 14109}
!1130 = !{i64 14111}
!1131 = !{i64 14117}
!1132 = !{i64 14134}
!1133 = !{i64 14154}
!1134 = !{i64 14159}
!1135 = !{i64 14178}
!1136 = !{i64 14183}
!1137 = !{i64 14197}
!1138 = !{i64 14217}
!1139 = !{i64 14223}
!1140 = !{i64 14224}
!1141 = !{i64 14268}
!1142 = !{i64 14281}
!1143 = !{i64 14292}
!1144 = !{i64 14303}
!1145 = !{i64 14308}
!1146 = !{i64 14310}
!1147 = !{i64 14347}
!1148 = !{i64 14352}
!1149 = !{i64 14356}
!1150 = !{i64 14358}
!1151 = !{i64 14363}
!1152 = !{i64 14365}
!1153 = !{i64 14374}
!1154 = !{i64 14379}
!1155 = !{i64 14388}
!1156 = !{i64 14393}
!1157 = !{i64 14397}
!1158 = !{i64 14398}
!1159 = !{i64 14418}
!1160 = !{i64 14425}
!1161 = !{i64 14447}
!1162 = !{i64 14459}
!1163 = !{i64 14464}
!1164 = !{i64 14477}
!1165 = !{i64 14482}
!1166 = !{i64 14488}
!1167 = !{i64 14504}
!1168 = !{i64 14506}
!1169 = !{i64 14512}
!1170 = !{i64 14515}
!1171 = !{i64 14520}
!1172 = !{i64 14532}
!1173 = !{i64 14558}
!1174 = !{i64 14570}
!1175 = !{i64 14578}
!1176 = !{i64 14587}
!1177 = !{i64 14595}
!1178 = !{i64 14600}
!1179 = !{i64 14605}
!1180 = !{i64 14608}
!1181 = !{i64 14610}
!1182 = !{i64 14616}
!1183 = !{i64 14619}
!1184 = !{i64 14622}
!1185 = !{i64 14624}
!1186 = !{i64 14638}
!1187 = !{i64 14664}
!1188 = !{i64 14669}
!1189 = !{i64 14676}
!1190 = !{i64 14679}
!1191 = !{i64 14716}
!1192 = !{i64 14728}
!1193 = !{i64 14740}
!1194 = !{i64 14745}
!1195 = !{i64 14755}
!1196 = !{i64 14773}
!1197 = !{i64 14781}
!1198 = !{i64 14783}
!1199 = !{i64 14792}
!1200 = !{i64 14797}
!1201 = !{i64 14811}
!1202 = !{i64 14823}
!1203 = !{i64 14832}
!1204 = !{i64 14834}
!1205 = !{i64 14844}
!1206 = !{i64 14858}
!1207 = !{i64 14872}
!1208 = !{i64 14896}
!1209 = !{i64 14909}
!1210 = !{i64 14921}
!1211 = !{i64 14928}
!1212 = !{i64 14948}
!1213 = !{i64 14964}
!1214 = !{i64 14970}
!1215 = !{i64 15007}
!1216 = !{i64 15022}
!1217 = !{i64 15037}
!1218 = !{i64 15052}
!1219 = !{i64 15069}
!1220 = !{i64 15084}
!1221 = !{i64 15105}
!1222 = !{i64 15111}
!1223 = !{i64 15135}
!1224 = !{i64 15138}
!1225 = !{i64 15143}
!1226 = !{i64 15173}
!1227 = !{i64 15185}
!1228 = !{i64 15188}
!1229 = !{i64 15197}
!1230 = !{i64 15212}
!1231 = !{i64 15217}
!1232 = !{i64 15220}
!1233 = !{i64 15229}
!1234 = !{i64 15247}
!1235 = !{i64 15252}
!1236 = !{i64 15261}
!1237 = !{i64 15266}
!1238 = !{i64 15277}
!1239 = !{i64 15290}
!1240 = !{i64 15301}
!1241 = !{i64 15310}
!1242 = !{i64 15313}
!1243 = !{i64 15318}
!1244 = !{i64 15351}
!1245 = !{i64 15365}
!1246 = !{i64 15370}
!1247 = !{i64 15372}
!1248 = !{i64 15342}
!1249 = !{i64 15389}
!1250 = !{i64 15400}
!1251 = !{i64 15408}
!1252 = !{i64 15410}
!1253 = !{i64 15435}
!1254 = !{i64 15459}
!1255 = !{i64 15463}
!1256 = !{i64 15466}
!1257 = !{i64 15470}
!1258 = !{i64 15474}
!1259 = !{i64 15483}
!1260 = !{i64 15512}
!1261 = !{i64 15523}
!1262 = !{i64 15534}
!1263 = !{i64 15556}
!1264 = !{i64 15560}
!1265 = !{i64 15564}
!1266 = !{i64 15567}
!1267 = !{i64 15571}
!1268 = !{i64 15575}
!1269 = !{i64 15584}
!1270 = !{i64 15616}
!1271 = !{i64 15625}
!1272 = !{i64 15633}
!1273 = !{i64 15643}
!1274 = !{i64 15652}
!1275 = !{i64 15660}
!1276 = !{i64 15666}
!1277 = !{i64 15696}
!1278 = !{i64 15707}
!1279 = !{i64 15718}
!1280 = !{i64 15720}
!1281 = !{i64 15738}
!1282 = !{i64 15770}
!1283 = !{i64 15774}
!1284 = !{i64 15777}
!1285 = !{i64 15814}
!1286 = !{i64 15829}
!1287 = !{i64 15838}
!1288 = !{i64 15841}
!1289 = !{i64 15889}
!1290 = !{i64 15893}
!1291 = !{i64 15896}
!1292 = !{i64 15858}
!1293 = !{i64 15869}
!1294 = !{i64 15908}
!1295 = !{i64 15915}
!1296 = !{i64 15936}
!1297 = !{i64 15941}
!1298 = !{i64 15943}
!1299 = !{i64 15955}
!1300 = !{i64 15962}
!1301 = !{i64 15980}
!1302 = !{i64 15985}
!1303 = !{i64 15987}
!1304 = !{i64 16016}
!1305 = !{i64 16031}
!1306 = !{i64 16040}
!1307 = !{i64 16049}
!1308 = !{i64 16051}
!1309 = !{i64 16057}
!1310 = !{i64 16058}
!1311 = !{i64 16076}
!1312 = !{i64 16108}
!1313 = !{i64 16112}
!1314 = !{i64 16115}
!1315 = !{i64 16152}
!1316 = !{i64 16167}
!1317 = !{i64 16176}
!1318 = !{i64 16179}
!1319 = !{i64 16227}
!1320 = !{i64 16231}
!1321 = !{i64 16234}
!1322 = !{i64 16196}
!1323 = !{i64 16207}
!1324 = !{i64 16249}
!1325 = !{i64 16270}
!1326 = !{i64 16275}
!1327 = !{i64 16277}
!1328 = !{i64 16292}
!1329 = !{i64 16310}
!1330 = !{i64 16315}
!1331 = !{i64 16317}
!1332 = !{i64 16346}
!1333 = !{i64 16361}
!1334 = !{i64 16370}
!1335 = !{i64 16379}
!1336 = !{i64 16381}
!1337 = !{i64 16387}
!1338 = !{i64 16415}
!1339 = !{i64 16422}
!1340 = !{i64 16443}
!1341 = !{i64 16448}
!1342 = !{i64 16460}
!1343 = !{i64 16467}
!1344 = !{i64 16487}
!1345 = !{i64 16492}
!1346 = !{i64 16504}
!1347 = !{i64 16511}
!1348 = !{i64 16531}
!1349 = !{i64 16537}
!1350 = !{i64 16551}
!1351 = !{i64 16565}
!1352 = !{i64 16602}
!1353 = !{i64 16617}
!1354 = !{i64 16632}
!1355 = !{i64 16647}
!1356 = !{i64 16655}
!1357 = !{i64 16658}
!1358 = !{i64 16662}
!1359 = !{i64 16665}
!1360 = !{i64 16684}
!1361 = !{i64 16699}
!1362 = !{i64 16723}
!1363 = !{i64 16741}
!1364 = !{i64 16748}
!1365 = !{i64 16768}
!1366 = !{i64 16775}
!1367 = !{i64 16795}
!1368 = !{i64 16805}
!1369 = !{i64 16819}
!1370 = !{i64 16850}
!1371 = !{i64 16857}
!1372 = !{i64 16886}
!1373 = !{i64 16897}
!1374 = !{i64 16908}
!1375 = !{i64 16910}
!1376 = !{i64 16925}
!1377 = !{i64 16944}
!1378 = !{i64 16964}
!1379 = !{i64 16967}
!1380 = !{i64 16972}
!1381 = !{i64 16977}
!1382 = !{i64 16980}
!1383 = !{i64 17001}
!1384 = !{i64 17006}
!1385 = !{i64 17017}
!1386 = !{i64 17029}
!1387 = !{i64 17032}
!1388 = !{i64 17069}
!1389 = !{i64 17088}
!1390 = !{i64 17093}
!1391 = !{i64 17095}
!1392 = !{i64 17114}
!1393 = !{i64 17125}
!1394 = !{i64 17142}
!1395 = !{i64 17188}
!1396 = !{i64 17197}
!1397 = !{i64 17206}
!1398 = !{i64 17208}
!1399 = !{i64 17214}
!1400 = !{i64 17228}
!1401 = !{i64 17252}
!1402 = !{i64 17265}
!1403 = !{i64 17277}
!1404 = !{i64 17284}
!1405 = !{i64 17305}
!1406 = !{i64 17311}
!1407 = !{i64 17340}
!1408 = !{i64 17351}
!1409 = !{i64 17360}
!1410 = !{i64 17370}
!1411 = !{i64 17402}
!1412 = !{i64 17411}
!1413 = !{i64 17419}
!1414 = !{i64 17429}
!1415 = !{i64 17438}
!1416 = !{i64 17446}
!1417 = !{i64 17455}
!1418 = !{i64 17456}
!1419 = !{i64 17489}
!1420 = !{i64 17514}
!1421 = !{i64 17529}
!1422 = !{i64 17541}
!1423 = !{i64 17973}
!1424 = !{i64 17980}
!1425 = !{i64 17589}
!1426 = !{i64 17610}
!1427 = !{i64 17618}
!1428 = !{i64 17620}
!1429 = !{i64 17632}
!1430 = !{i64 17650}
!1431 = !{i64 17658}
!1432 = !{i64 17660}
!1433 = !{i64 17692}
!1434 = !{i64 17720}
!1435 = !{i64 17795}
!1436 = !{i64 17803}
!1437 = !{i64 17811}
!1438 = !{i64 17821}
!1439 = !{i64 17832}
!1440 = !{i64 17837}
!1441 = !{i64 17847}
!1442 = !{i64 17860}
!1443 = !{i64 17878}
!1444 = !{i64 17886}
!1445 = !{i64 17891}
!1446 = !{i64 17895}
!1447 = !{i64 17898}
!1448 = !{i64 17901}
!1449 = !{i64 17915}
!1450 = !{i64 17930}
!1451 = !{i64 17945}
!1452 = !{i64 17953}
!1453 = !{i64 17958}
!1454 = !{i64 17993}
!1455 = !{i64 18008}
!1456 = !{i64 18017}
!1457 = !{i64 18026}
!1458 = !{i64 18028}
!1459 = !{i64 18038}
!1460 = !{i64 18063}
!1461 = !{i64 18070}
!1462 = !{i64 18084}
!1463 = !{i64 18098}
!1464 = !{i64 18127}
!1465 = !{i64 18137}
!1466 = !{i64 18144}
!1467 = !{i64 18169}
!1468 = !{i64 18186}
!1469 = !{i64 18192}
!1470 = !{i64 18222}
!1471 = !{i64 18241}
!1472 = !{i64 18260}
!1473 = !{i64 18269}
!1474 = !{i64 18278}
!1475 = !{i64 18280}
!1476 = !{i64 18290}
!1477 = !{i64 18324}
!1478 = !{i64 18346}
!1479 = !{i64 18353}
!1480 = !{i64 18370}
!1481 = !{i64 18376}
!1482 = !{i64 18394}
!1483 = !{i64 18400}
!1484 = !{i64 18402}
!1485 = !{i64 18418}
!1486 = !{i64 18426}
!1487 = !{i64 18441}
!1488 = !{i64 18472}
!1489 = !{i64 18503}
!1490 = !{i64 18513}
!1491 = !{i64 18522}
!1492 = !{i64 18524}
!1493 = !{i64 18530}
!1494 = !{i64 18531}
!1495 = !{i64 18539}
!1496 = !{i64 18561}
!1497 = !{i64 18590}
!1498 = !{i64 18595}
!1499 = !{i64 18613}
!1500 = !{i64 18618}
!1501 = !{i64 18630}
!1502 = !{i64 18639}
!1503 = !{i64 18641}
!1504 = !{i64 18647}
!1505 = !{i64 18658}
!1506 = !{i64 18673}
!1507 = !{i64 18706}
!1508 = !{i64 18708}
!1509 = !{i64 18712}
!1510 = !{i64 18713}
!1511 = !{i64 18737}
!1512 = !{i64 18742}
!1513 = !{i64 18754}
!1514 = !{i64 18759}
!1515 = !{i64 18761}
!1516 = !{i64 18781}
!1517 = !{i64 18792}
!1518 = !{i64 18801}
!1519 = !{i64 18806}
!1520 = !{i64 18808}
!1521 = !{i64 18845}
!1522 = !{i64 18850}
!1523 = !{i64 18852}
!1524 = !{i64 18861}
!1525 = !{i64 18870}
!1526 = !{i64 18874}
!1527 = !{i64 18901}
!1528 = !{i64 18906}
!1529 = !{i64 18908}
!1530 = !{i64 18909}
!1531 = !{i64 18925}
!1532 = !{i64 18930}
!1533 = !{i64 18932}
!1534 = !{i64 18941}
!1535 = !{i64 18946}
!1536 = !{i64 18948}
!1537 = !{i64 18955}
!1538 = !{i64 18960}
!1539 = !{i64 18962}
!1540 = !{i64 18963}
!1541 = !{i64 18987}
!1542 = !{i64 18992}
!1543 = !{i64 19001}
!1544 = !{i64 19006}
!1545 = !{i64 19008}
!1546 = !{i64 19028}
!1547 = !{i64 19033}
!1548 = !{i64 19042}
!1549 = !{i64 19049}
!1550 = !{i64 19053}
!1551 = !{i64 19058}
!1552 = !{i64 19063}
!1553 = !{i64 19065}
!1554 = !{i64 19087}
!1555 = !{i64 19114}
!1556 = !{i64 19134}
!1557 = !{i64 19154}
!1558 = !{i64 19174}
!1559 = !{i64 34401}
!1560 = !{i64 34419}
!1561 = !{i64 34440}
!1562 = !{i64 34444}
!1563 = !{i64 34481}
!1564 = !{i64 34498}
!1565 = !{i64 34502}
!1566 = !{i64 34505}
!1567 = !{i64 34509}
!1568 = !{i64 34540}
!1569 = !{i64 34543}
!1570 = !{i64 34556}
!1571 = !{i64 34575}
!1572 = !{i64 34580}
!1573 = !{i64 34590}
!1574 = !{i64 34592}
!1575 = !{i64 34595}
!1576 = !{i64 34612}
!1577 = !{i64 34615}
!1578 = !{i64 34623}
!1579 = !{i64 34627}
!1580 = !{i64 34635}
!1581 = !{i64 34639}
!1582 = !{i64 34647}
!1583 = !{i64 34651}
!1584 = !{i64 34659}
!1585 = !{i64 34663}
!1586 = !{i64 34671}
!1587 = !{i64 34675}
!1588 = !{i64 34683}
!1589 = !{i64 34688}
!1590 = !{i64 34706}
!1591 = !{i64 34707}
!1592 = !{i64 34731}
!1593 = !{i64 34736}
!1594 = !{i64 34749}
!1595 = !{i64 34753}
!1596 = !{i64 34763}
!1597 = !{i64 34768}
!1598 = !{i64 34770}
!1599 = !{i64 34772}
!1600 = !{i64 34796}
!1601 = !{i64 34800}
!1602 = !{i64 34803}
!1603 = !{i64 34808}
!1604 = !{i64 34817}
!1605 = !{i64 34822}
!1606 = !{i64 34833}
!1607 = !{i64 34839}
!1608 = !{i64 34868}
!1609 = !{i64 34879}
!1610 = !{i64 34885}
!1611 = !{i64 34913}
!1612 = !{i64 34922}
!1613 = !{i64 34932}
!1614 = !{i64 34941}
!1615 = !{i64 34947}
!1616 = !{i64 34968}
!1617 = !{i64 34993}
!1618 = !{i64 34998}
!1619 = !{i64 35001}
!1620 = !{i64 35005}
!1621 = !{i64 35022}
!1622 = !{i64 35027}
!1623 = !{i64 35049}
!1624 = !{i64 35071}
!1625 = !{i64 35076}
!1626 = !{i64 35082}
!1627 = !{i64 35084}
!1628 = !{i64 35093}
!1629 = !{i64 35098}
!1630 = !{i64 35117}
!1631 = !{i64 35132}
!1632 = !{i64 35157}
!1633 = !{i64 35169}
!1634 = !{i64 35174}
!1635 = !{i64 35179}
!1636 = !{i64 35188}
!1637 = !{i64 35190}
!1638 = !{i64 35204}
!1639 = !{i64 35206}
!1640 = !{i64 35223}
!1641 = !{i64 35245}
!1642 = !{i64 35260}
!1643 = !{i64 35281}
!1644 = !{i64 35286}
!1645 = !{i64 35298}
!1646 = !{i64 35307}
!1647 = !{i64 35309}
!1648 = !{i64 35319}
!1649 = !{i64 35320}
!1650 = !{i64 35351}
!1651 = !{i64 35366}
!1652 = !{i64 35381}
!1653 = !{i64 35386}
!1654 = !{i64 35389}
!1655 = !{i64 35398}
!1656 = !{i64 35413}
!1657 = !{i64 35428}
!1658 = !{i64 35442}
!1659 = !{i64 35447}
!1660 = !{i64 35449}
!1661 = !{i64 35458}
!1662 = !{i64 35471}
!1663 = !{i64 35472}
!1664 = !{i64 35497}
!1665 = !{i64 35519}
!1666 = !{i64 35524}
!1667 = !{i64 35549}
!1668 = !{i64 35558}
!1669 = !{i64 35567}
!1670 = !{i64 35569}
!1671 = !{i64 35575}
!1672 = !{i64 35576}
!1673 = !{i64 35593}
!1674 = !{i64 35597}
!1675 = !{i64 35601}
!1676 = !{i64 35623}
!1677 = !{i64 35628}
!1678 = !{i64 35646}
!1679 = !{i64 35651}
!1680 = !{i64 35654}
!1681 = !{i64 35665}
!1682 = !{i64 35673}
!1683 = !{i64 35677}
!1684 = !{i64 35680}
!1685 = !{i64 35698}
!1686 = !{i64 35703}
!1687 = !{i64 35713}
!1688 = !{i64 35718}
!1689 = !{i64 35722}
!1690 = !{i64 35739}
!1691 = !{i64 35744}
!1692 = !{i64 35756}
!1693 = !{i64 35765}
!1694 = !{i64 35767}
!1695 = !{i64 35777}
!1696 = !{i64 35778}
!1697 = !{i64 35805}
!1698 = !{i64 35810}
!1699 = !{i64 35814}
!1700 = !{i64 35817}
!1701 = !{i64 35819}
!1702 = !{i64 35832}
!1703 = !{i64 35841}
!1704 = !{i64 35846}
!1705 = !{i64 35863}
!1706 = !{i64 35868}
!1707 = !{i64 35870}
!1708 = !{i64 35899}
!1709 = !{i64 35904}
!1710 = !{i64 35908}
!1711 = !{i64 35945}
!1712 = !{i64 35957}
!1713 = !{i64 35962}
!1714 = !{i64 35981}
!1715 = !{i64 35987}
!1716 = !{i64 35988}
!1717 = !{i64 36016}
!1718 = !{i64 36042}
!1719 = !{i64 36050}
!1720 = !{i64 36052}
!1721 = !{i64 36068}
!1722 = !{i64 36093}
!1723 = !{i64 36102}
!1724 = !{i64 36105}
!1725 = !{i64 36109}
!1726 = !{i64 36115}
!1727 = !{i64 36116}
!1728 = !{i64 36133}
!1729 = !{i64 36137}
!1730 = !{i64 36141}
!1731 = !{i64 36163}
!1732 = !{i64 36168}
!1733 = !{i64 36186}
!1734 = !{i64 36191}
!1735 = !{i64 36194}
!1736 = !{i64 36205}
!1737 = !{i64 36210}
!1738 = !{i64 36232}
!1739 = !{i64 36237}
!1740 = !{i64 36240}
!1741 = !{i64 36248}
!1742 = !{i64 36255}
!1743 = !{i64 36265}
!1744 = !{i64 36270}
!1745 = !{i64 36274}
!1746 = !{i64 36291}
!1747 = !{i64 36296}
!1748 = !{i64 36308}
!1749 = !{i64 36317}
!1750 = !{i64 36319}
!1751 = !{i64 36329}
!1752 = !{i64 36330}
!1753 = !{i64 36360}
!1754 = !{i64 36368}
!1755 = !{i64 36383}
!1756 = !{i64 36398}
!1757 = !{i64 36403}
!1758 = !{i64 36406}
!1759 = !{i64 36409}
!1760 = !{i64 36411}
!1761 = !{i64 36427}
!1762 = !{i64 36432}
!1763 = !{i64 36434}
!1764 = !{i64 36450}
!1765 = !{i64 36465}
!1766 = !{i64 36480}
!1767 = !{i64 36494}
!1768 = !{i64 36499}
!1769 = !{i64 36501}
!1770 = !{i64 36512}
!1771 = !{i64 36514}
!1772 = !{i64 36542}
!1773 = !{i64 36557}
!1774 = !{i64 36570}
!1775 = !{i64 36578}
!1776 = !{i64 36582}
!1777 = !{i64 36588}
!1778 = !{i64 36592}
!1779 = !{i64 36601}
!1780 = !{i64 36623}
!1781 = !{i64 36628}
!1782 = !{i64 36630}
!1783 = !{i64 36635}
!1784 = !{i64 36644}
!1785 = !{i64 36656}
!1786 = !{i64 36670}
!1787 = !{i64 36679}
!1788 = !{i64 36687}
!1789 = !{i64 36694}
!1790 = !{i64 36703}
!1791 = !{i64 36704}
!1792 = !{i64 36724}
!1793 = !{i64 36753}
!1794 = !{i64 36758}
!1795 = !{i64 36776}
!1796 = !{i64 36785}
!1797 = !{i64 36794}
!1798 = !{i64 36796}
!1799 = !{i64 36802}
!1800 = !{i64 36823}
!1801 = !{i64 36836}
!1802 = !{i64 36842}
!1803 = !{i64 36864}
!1804 = !{i64 36886}
!1805 = !{i64 36904}
!1806 = !{i64 36909}
!1807 = !{i64 36929}
!1808 = !{i64 36933}
!1809 = !{i64 36957}
!1810 = !{i64 36963}
!1811 = !{i64 36980}
!1812 = !{i64 36985}
!1813 = !{i64 37009}
!1814 = !{i64 37014}
!1815 = !{i64 37017}
!1816 = !{i64 37021}
!1817 = !{i64 37045}
!1818 = !{i64 37050}
!1819 = !{i64 37053}
!1820 = !{i64 37057}
!1821 = !{i64 37081}
!1822 = !{i64 37086}
!1823 = !{i64 37089}
!1824 = !{i64 37093}
!1825 = !{i64 37094}
!1826 = !{i64 37112}
!1827 = !{i64 37123}
!1828 = !{i64 37130}
!1829 = !{i64 37141}
!1830 = !{i64 37146}
!1831 = !{i64 37148}
!1832 = !{i64 37185}
!1833 = !{i64 37192}
!1834 = !{i64 37194}
!1835 = !{i64 37245}
!1836 = !{i64 37260}
!1837 = !{i64 37263}
!1838 = !{i64 37279}
!1839 = !{i64 37283}
!1840 = !{i64 37295}
!1841 = !{i64 37306}
!1842 = !{i64 37316}
!1843 = !{i64 37321}
!1844 = !{i64 37323}
!1845 = !{i64 37360}
!1846 = !{i64 37367}
!1847 = !{i64 37391}
!1848 = !{i64 37396}
!1849 = !{i64 37398}
!1850 = !{i64 37402}
!1851 = !{i64 37427}
!1852 = !{i64 37432}
!1853 = !{i64 37434}
!1854 = !{i64 37438}
!1855 = !{i64 37463}
!1856 = !{i64 37468}
!1857 = !{i64 37470}
!1858 = !{i64 37479}
!1859 = !{i64 37484}
!1860 = !{i64 37501}
!1861 = !{i64 37502}
!1862 = !{i64 37525}
!1863 = !{i64 37530}
!1864 = !{i64 37532}
!1865 = !{i64 37541}
!1866 = !{i64 37549}
!1867 = !{i64 37551}
!1868 = !{i64 37560}
!1869 = !{i64 37566}
!1870 = !{i64 37568}
!1871 = !{i64 37591}
!1872 = !{i64 37596}
!1873 = !{i64 37598}
!1874 = !{i64 37607}
!1875 = !{i64 37612}
!1876 = !{i64 37614}
!1877 = !{i64 37623}
!1878 = !{i64 37629}
!1879 = !{i64 37630}
!1880 = !{i64 37653}
!1881 = !{i64 37658}
!1882 = !{i64 37660}
!1883 = !{i64 37669}
!1884 = !{i64 37674}
!1885 = !{i64 37676}
!1886 = !{i64 37711}
!1887 = !{i64 37716}
!1888 = !{i64 37721}
!1889 = !{i64 37723}
!1890 = !{i64 37742}
!1891 = !{i64 37747}
!1892 = !{i64 37749}
!1893 = !{i64 37758}
!1894 = !{i64 37763}
!1895 = !{i64 37765}
!1896 = !{i64 37800}
!1897 = !{i64 37805}
!1898 = !{i64 37807}
!1899 = !{i64 37819}
!1900 = !{i64 37827}
!1901 = !{i64 37829}
!1902 = !{i64 37861}
!1903 = !{i64 37866}
!1904 = !{i64 37868}
!1905 = !{i64 37874}
!1906 = !{i64 37881}
!1907 = !{i64 37889}
!1908 = !{i64 37891}
!1909 = !{i64 37922}
!1910 = !{i64 37940}
!1911 = !{i64 37945}
!1912 = !{i64 37962}
!1913 = !{i64 37967}
!1914 = !{i64 37968}
!1915 = !{i64 37992}
!1916 = !{i64 38000}
!1917 = !{i64 38008}
!1918 = !{i64 38011}
!1919 = !{i64 38013}
!1920 = !{i64 38019}
!1921 = !{i64 38023}
!1922 = !{i64 38034}
!1923 = !{i64 38051}
!1924 = !{i64 38056}
!1925 = !{i64 38058}
!1926 = !{i64 38095}
!1927 = !{i64 38102}
!1928 = !{i64 38104}
!1929 = !{i64 38128}
!1930 = !{i64 38136}
!1931 = !{i64 38147}
!1932 = !{i64 38156}
!1933 = !{i64 38166}
!1934 = !{i64 38175}
!1935 = !{i64 38186}
!1936 = !{i64 38191}
!1937 = !{i64 38193}
!1938 = !{i64 38230}
!1939 = !{i64 38237}
!1940 = !{i64 38238}
!1941 = !{i64 38266}
!1942 = !{i64 38274}
!1943 = !{i64 38285}
!1944 = !{i64 38294}
!1945 = !{i64 38304}
!1946 = !{i64 38313}
!1947 = !{i64 38325}
!1948 = !{i64 38336}
!1949 = !{i64 38341}
!1950 = !{i64 38343}
!1951 = !{i64 38380}
!1952 = !{i64 38387}
!1953 = !{i64 38388}
!1954 = !{i64 38413}
!1955 = !{i64 38435}
!1956 = !{i64 38440}
!1957 = !{i64 38442}
!1958 = !{i64 38451}
!1959 = !{i64 38456}
!1960 = !{i64 38458}
!1961 = !{i64 38505}
!1962 = !{i64 38510}
!1963 = !{i64 38512}
!1964 = !{i64 38488}
!1965 = !{i64 38493}
!1966 = !{i64 38525}
!1967 = !{i64 38529}
!1968 = !{i64 38532}
!1969 = !{i64 38536}
!1970 = !{i64 38540}
!1971 = !{i64 38544}
!1972 = !{i64 38548}
!1973 = !{i64 38552}
!1974 = !{i64 38556}
!1975 = !{i64 38560}
!1976 = !{i64 38572}
!1977 = !{i64 38577}
!1978 = !{i64 38579}
!1979 = !{i64 38592}
!1980 = !{i64 38596}
!1981 = !{i64 38599}
!1982 = !{i64 38603}
!1983 = !{i64 38607}
!1984 = !{i64 38611}
!1985 = !{i64 38615}
!1986 = !{i64 38619}
!1987 = !{i64 38623}
!1988 = !{i64 38627}
!1989 = !{i64 38663}
!1990 = !{i64 38668}
!1991 = !{i64 38670}
!1992 = !{i64 38676}
!1993 = !{i64 38698}
!1994 = !{i64 38703}
!1995 = !{i64 38713}
!1996 = !{i64 38718}
!1997 = !{i64 38720}
!1998 = !{i64 38726}
!1999 = !{i64 38748}
!2000 = !{i64 38753}
!2001 = !{i64 38800}
!2002 = !{i64 38805}
!2003 = !{i64 38813}
!2004 = !{i64 38822}
!2005 = !{i64 38824}
!2006 = !{i64 38838}
!2007 = !{i64 38863}
!2008 = !{i64 38896}
!2009 = !{i64 38906}
!2010 = !{i64 38915}
!2011 = !{i64 38917}
!2012 = !{i64 38927}
!2013 = !{i64 38970}
!2014 = !{i64 38980}
!2015 = !{i64 38998}
!2016 = !{i64 39001}
!2017 = !{i64 39005}
!2018 = !{i64 39022}
!2019 = !{i64 39026}
!2020 = !{i64 39030}
!2021 = !{i64 39032}
!2022 = !{i64 39055}
!2023 = !{i64 39063}
!2024 = !{i64 39065}
!2025 = !{i64 39067}
!2026 = !{i64 39071}
!2027 = !{i64 39074}
!2028 = !{i64 39083}
!2029 = !{i64 39089}
!2030 = !{i64 39113}
!2031 = !{i64 39118}
!2032 = !{i64 39120}
!2033 = !{i64 39129}
!2034 = !{i64 39134}
!2035 = !{i64 39137}
!2036 = !{i64 39146}
!2037 = !{i64 39151}
!2038 = !{i64 39169}
!2039 = !{i64 39193}
!2040 = !{i64 39201}
!2041 = !{i64 39207}
!2042 = !{i64 39231}
!2043 = !{i64 39236}
!2044 = !{i64 39239}
!2045 = !{i64 39243}
!2046 = !{i64 39267}
!2047 = !{i64 39272}
!2048 = !{i64 39275}
!2049 = !{i64 39279}
!2050 = !{i64 39303}
!2051 = !{i64 39308}
!2052 = !{i64 39311}
!2053 = !{i64 39320}
!2054 = !{i64 39325}
!2055 = !{i64 39343}
!2056 = !{i64 39344}
!2057 = !{i64 39367}
!2058 = !{i64 39372}
!2059 = !{i64 39374}
!2060 = !{i64 39388}
!2061 = !{i64 39393}
!2062 = !{i64 39400}
!2063 = !{i64 39425}
!2064 = !{i64 39428}
!2065 = !{i64 39431}
!2066 = !{i64 39468}
!2067 = !{i64 39477}
!2068 = !{i64 39481}
!2069 = !{i64 39484}
!2070 = !{i64 39488}
!2071 = !{i64 39491}
!2072 = !{i64 39495}
!2073 = !{i64 39519}
!2074 = !{i64 39525}
!2075 = !{i64 39549}
!2076 = !{i64 39554}
!2077 = !{i64 39557}
!2078 = !{i64 39561}
!2079 = !{i64 39585}
!2080 = !{i64 39590}
!2081 = !{i64 39593}
!2082 = !{i64 39595}
!2083 = !{i64 39599}
!2084 = !{i64 39616}
!2085 = !{i64 39621}
!2086 = !{i64 39638}
!2087 = !{i64 39646}
!2088 = !{i64 39649}
!2089 = !{i64 39651}
!2090 = !{i64 39655}
!2091 = !{i64 39659}
!2092 = !{i64 39660}
!2093 = !{i64 39677}
!2094 = !{i64 39699}
!2095 = !{i64 39714}
!2096 = !{i64 39735}
!2097 = !{i64 39740}
!2098 = !{i64 39752}
!2099 = !{i64 39761}
!2100 = !{i64 39763}
!2101 = !{i64 39773}
!2102 = !{i64 39797}
!2103 = !{i64 39802}
!2104 = !{i64 39805}
!2105 = !{i64 39809}
!2106 = !{i64 39826}
!2107 = !{i64 39831}
!2108 = !{i64 39855}
!2109 = !{i64 39860}
!2110 = !{i64 39863}
!2111 = !{i64 39867}
!2112 = !{i64 39884}
!2113 = !{i64 39892}
!2114 = !{i64 39928}
!2115 = !{i64 39935}
!2116 = !{i64 39970}
!2117 = !{i64 39977}
!2118 = !{i64 39978}
!2119 = !{i64 39994}
!2120 = !{i64 40021}
!2121 = !{i64 40033}
!2122 = !{i64 40047}
!2123 = !{i64 40056}
!2124 = !{i64 40065}
!2125 = !{i64 40067}
!2126 = !{i64 40073}
!2127 = !{i64 40107}
!2128 = !{i64 40114}
!2129 = !{i64 40156}
!2130 = !{i64 40162}
!2131 = !{i64 40195}
!2132 = !{i64 40205}
!2133 = !{i64 40212}
!2134 = !{i64 40238}
!2135 = !{i64 40242}
!2136 = !{i64 40257}
!2137 = !{i64 40273}
!2138 = !{i64 40290}
!2139 = !{i64 40295}
!2140 = !{i64 40300}
!2141 = !{i64 40325}
!2142 = !{i64 40332}
!2143 = !{i64 40334}
!2144 = !{i64 40357}
!2145 = !{i64 40360}
!2146 = !{i64 40369}
!2147 = !{i64 40376}
!2148 = !{i64 40378}
!2149 = !{i64 40401}
!2150 = !{i64 40404}
!2151 = !{i64 40413}
!2152 = !{i64 40420}
!2153 = !{i64 40422}
!2154 = !{i64 40456}
!2155 = !{i64 40459}
!2156 = !{i64 40496}
!2157 = !{i64 40508}
!2158 = !{i64 40511}
!2159 = !{i64 40527}
!2160 = !{i64 40536}
!2161 = !{i64 40545}
!2162 = !{i64 40562}
!2163 = !{i64 40571}
!2164 = !{i64 40595}
!2165 = !{i64 40602}
!2166 = !{i64 40627}
!2167 = !{i64 40634}
!2168 = !{i64 40659}
!2169 = !{i64 40666}
!2170 = !{i64 40691}
!2171 = !{i64 40698}
!2172 = !{i64 40734}
!2173 = !{i64 40741}
!2174 = !{i64 40758}
!2175 = !{i64 40769}
!2176 = !{i64 40777}
!2177 = !{i64 40783}
!2178 = !{i64 40808}
!2179 = !{i64 40815}
!2180 = !{i64 40830}
!2181 = !{i64 40837}
!2182 = !{i64 40861}
!2183 = !{i64 40866}
!2184 = !{i64 40870}
!2185 = !{i64 40906}
!2186 = !{i64 40916}
!2187 = !{i64 40941}
!2188 = !{i64 40947}
!2189 = !{i64 40964}
!2190 = !{i64 40969}
!2191 = !{i64 40993}
!2192 = !{i64 40998}
!2193 = !{i64 41000}
!2194 = !{i64 41004}
!2195 = !{i64 41006}
!2196 = !{i64 41022}
!2197 = !{i64 41041}
!2198 = !{i64 41048}
!2199 = !{i64 41053}
!2200 = !{i64 41073}
!2201 = !{i64 41078}
!2202 = !{i64 41090}
!2203 = !{i64 41099}
!2204 = !{i64 41101}
!2205 = !{i64 41107}
!2206 = !{i64 41128}
!2207 = !{i64 41135}
!2208 = !{i64 41141}
!2209 = !{i64 41158}
!2210 = !{i64 41162}
!2211 = !{i64 41180}
!2212 = !{i64 41187}
!2213 = !{i64 41189}
!2214 = !{i64 41193}
!2215 = !{i64 41214}
!2216 = !{i64 41221}
!2217 = !{i64 41227}
!2218 = !{i64 41248}
!2219 = !{i64 41255}
!2220 = !{i64 41261}
!2221 = !{i64 41282}
!2222 = !{i64 41289}
!2223 = !{i64 41295}
!2224 = !{i64 41313}
!2225 = !{i64 41337}
!2226 = !{i64 41343}
!2227 = !{i64 41356}
!2228 = !{i64 41367}
!2229 = !{i64 41372}
!2230 = !{i64 41374}
!2231 = !{i64 41411}
!2232 = !{i64 41423}
!2233 = !{i64 41429}
!2234 = !{i64 41442}
!2235 = !{i64 41453}
!2236 = !{i64 41465}
!2237 = !{i64 41553}
!2238 = !{i64 41577}
!2239 = !{i64 41583}
!2240 = !{i64 41618}
!2241 = !{i64 41624}
!2242 = !{i64 41637}
!2243 = !{i64 41648}
!2244 = !{i64 41653}
!2245 = !{i64 41655}
!2246 = !{i64 41692}
!2247 = !{i64 41704}
!2248 = !{i64 41710}
!2249 = !{i64 41738}
!2250 = !{i64 41743}
!2251 = !{i64 41746}
!2252 = !{i64 41783}
!2253 = !{i64 41795}
!2254 = !{i64 41800}
!2255 = !{i64 41803}
!2256 = !{i64 41807}
!2257 = !{i64 41813}
!2258 = !{i64 41821}
!2259 = !{i64 41827}
!2260 = !{i64 41851}
!2261 = !{i64 41856}
!2262 = !{i64 41859}
!2263 = !{i64 41868}
!2264 = !{i64 41873}
!2265 = !{i64 41876}
!2266 = !{i64 41885}
!2267 = !{i64 41890}
!2268 = !{i64 41908}
!2269 = !{i64 41933}
!2270 = !{i64 41941}
!2271 = !{i64 41947}
!2272 = !{i64 41960}
!2273 = !{i64 41971}
!2274 = !{i64 41983}
!2275 = !{i64 42012}
!2276 = !{i64 42036}
!2277 = !{i64 42042}
!2278 = !{i64 42055}
!2279 = !{i64 42066}
!2280 = !{i64 42071}
!2281 = !{i64 42073}
!2282 = !{i64 42110}
!2283 = !{i64 42122}
!2284 = !{i64 42128}
!2285 = !{i64 42141}
!2286 = !{i64 42152}
!2287 = !{i64 42157}
!2288 = !{i64 42159}
!2289 = !{i64 42196}
!2290 = !{i64 42208}
!2291 = !{i64 42214}
!2292 = !{i64 42227}
!2293 = !{i64 42238}
!2294 = !{i64 42243}
!2295 = !{i64 42245}
!2296 = !{i64 42282}
!2297 = !{i64 42294}
!2298 = !{i64 42300}
!2299 = !{i64 42301}
!2300 = !{i64 42317}
!2301 = !{i64 42339}
!2302 = !{i64 42348}
!2303 = !{i64 42353}
!2304 = !{i64 42362}
!2305 = !{i64 42370}
!2306 = !{i64 42372}
!2307 = !{i64 42381}
!2308 = !{i64 42389}
!2309 = !{i64 42407}
!2310 = !{i64 42423}
!2311 = !{i64 42428}
!2312 = !{i64 42443}
!2313 = !{i64 42448}
!2314 = !{i64 42455}
!2315 = !{i64 42464}
!2316 = !{i64 42473}
!2317 = !{i64 42478}
!2318 = !{i64 42487}
!2319 = !{i64 42503}
!2320 = !{i64 42512}
!2321 = !{i64 42517}
!2322 = !{i64 42520}
!2323 = !{i64 42522}
!2324 = !{i64 42531}
!2325 = !{i64 42536}
!2326 = !{i64 42541}
!2327 = !{i64 42550}
!2328 = !{i64 42552}
!2329 = !{i64 42558}
!2330 = !{i64 42582}
!2331 = !{i64 42587}
!2332 = !{i64 42589}
!2333 = !{i64 42598}
!2334 = !{i64 42603}
!2335 = !{i64 42620}
!2336 = !{i64 42621}
!2337 = !{i64 42644}
!2338 = !{i64 42653}
!2339 = !{i64 42658}
!2340 = !{i64 42667}
!2341 = !{i64 42672}
!2342 = !{i64 42679}
!2343 = !{i64 42682}
!2344 = !{i64 42684}
!2345 = !{i64 42705}
!2346 = !{i64 42718}
!2347 = !{i64 42721}
!2348 = !{i64 42724}
!2349 = !{i64 42727}
!2350 = !{i64 42729}
!2351 = !{i64 42741}
!2352 = !{i64 42744}
!2353 = !{i64 42747}
!2354 = !{i64 42750}
!2355 = !{i64 42752}
!2356 = !{i64 42770}
!2357 = !{i64 42778}
!2358 = !{i64 42783}
!2359 = !{i64 42791}
!2360 = !{i64 42815}
!2361 = !{i64 42821}
!2362 = !{i64 42850}
!2363 = !{i64 42856}
!2364 = !{i64 42880}
!2365 = !{i64 42885}
!2366 = !{i64 42888}
!2367 = !{i64 42892}
!2368 = !{i64 42917}
!2369 = !{i64 42923}
!2370 = !{i64 42952}
!2371 = !{i64 42958}
!2372 = !{i64 42988}
!2373 = !{i64 42994}
!2374 = !{i64 43018}
!2375 = !{i64 43023}
!2376 = !{i64 43026}
!2377 = !{i64 43030}
!2378 = !{i64 43058}
!2379 = !{i64 43063}
!2380 = !{i64 43066}
!2381 = !{i64 43103}
!2382 = !{i64 43115}
!2383 = !{i64 43120}
!2384 = !{i64 43123}
!2385 = !{i64 43127}
!2386 = !{i64 43133}
!2387 = !{i64 43141}
!2388 = !{i64 43147}
!2389 = !{i64 43164}
!2390 = !{i64 43175}
!2391 = !{i64 43185}
!2392 = !{i64 43209}
!2393 = !{i64 43214}
!2394 = !{i64 43217}
!2395 = !{i64 43221}
!2396 = !{i64 43222}
!2397 = !{i64 43234}
!2398 = !{i64 43245}
!2399 = !{i64 43250}
!2400 = !{i64 43252}
!2401 = !{i64 43254}
!2402 = !{i64 43261}
!2403 = !{i64 43269}
!2404 = !{i64 43274}
!2405 = !{i64 43276}
!2406 = !{i64 43285}
!2407 = !{i64 43291}
!2408 = !{i64 43304}
!2409 = !{i64 43315}
!2410 = !{i64 43320}
!2411 = !{i64 43322}
!2412 = !{i64 43359}
!2413 = !{i64 43371}
!2414 = !{i64 43377}
!2415 = !{i64 43390}
!2416 = !{i64 43401}
!2417 = !{i64 43406}
!2418 = !{i64 43408}
!2419 = !{i64 43445}
!2420 = !{i64 43457}
!2421 = !{i64 43463}
!2422 = !{i64 43476}
!2423 = !{i64 43483}
!2424 = !{i64 43491}
!2425 = !{i64 43496}
!2426 = !{i64 43514}
!2427 = !{i64 43531}
!2428 = !{i64 43537}
!2429 = !{i64 43577}
!2430 = !{i64 43586}
!2431 = !{i64 43593}
!2432 = !{i64 43602}
!2433 = !{i64 43609}
!2434 = !{i64 43622}
!2435 = !{i64 43634}
!2436 = !{i64 43646}
!2437 = !{i64 43658}
!2438 = !{i64 43666}
!2439 = !{i64 43673}
!2440 = !{i64 43682}
!2441 = !{i64 43690}
!2442 = !{i64 43698}
!2443 = !{i64 43714}
!2444 = !{i64 43718}
!2445 = !{i64 43732}
!2446 = !{i64 43739}
!2447 = !{i64 43740}
!2448 = !{i64 43756}
!2449 = !{i64 43775}
!2450 = !{i64 43783}
!2451 = !{i64 43806}
!2452 = !{i64 43815}
!2453 = !{i64 43819}
!2454 = !{i64 43827}
!2455 = !{i64 43836}
!2456 = !{i64 43845}
!2457 = !{i64 43847}
!2458 = !{i64 43853}
!2459 = !{i64 43854}
!2460 = !{i64 43874}
!2461 = !{i64 43893}
!2462 = !{i64 43900}
!2463 = !{i64 43909}
!2464 = !{i64 43924}
!2465 = !{i64 43929}
!2466 = !{i64 43945}
!2467 = !{i64 43949}
!2468 = !{i64 43953}
!2469 = !{i64 43961}
!2470 = !{i64 43968}
!2471 = !{i64 43973}
!2472 = !{i64 43999}
!2473 = !{i64 44004}
!2474 = !{i64 44006}
!2475 = !{i64 44043}
!2476 = !{i64 44055}
!2477 = !{i64 44073}
!2478 = !{i64 44086}
!2479 = !{i64 44092}
!2480 = !{i64 44104}
!2481 = !{i64 44114}
!2482 = !{i64 44123}
!2483 = !{i64 44125}
!2484 = !{i64 44131}
!2485 = !{i64 44159}
!2486 = !{i64 44171}
!2487 = !{i64 44181}
!2488 = !{i64 44188}
!2489 = !{i64 44190}
!2490 = !{i64 44225}
!2491 = !{i64 44241}
!2492 = !{i64 44297}
!2493 = !{i64 44301}
!2494 = !{i64 44264}
!2495 = !{i64 44272}
!2496 = !{i64 44283}
!2497 = !{i64 44288}
!2498 = !{i64 44317}
!2499 = !{i64 44324}
!2500 = !{i64 44349}
!2501 = !{i64 44356}
!2502 = !{i64 44358}
!2503 = !{i64 44385}
!2504 = !{i64 44390}
!2505 = !{i64 44396}
!2506 = !{i64 44400}
!2507 = !{i64 44404}
!2508 = !{i64 44409}
!2509 = !{i64 44427}
!2510 = !{i64 44444}
!2511 = !{i64 44454}
!2512 = !{i64 44456}
!2513 = !{i64 44498}
!2514 = !{i64 44520}
!2515 = !{i64 44525}
!2516 = !{i64 44532}
!2517 = !{i64 44534}
!2518 = !{i64 44567}
!2519 = !{i64 44594}
!2520 = !{i64 44599}
!2521 = !{i64 44622}
!2522 = !{i64 44644}
!2523 = !{i64 44649}
!2524 = !{i64 44683}
!2525 = !{i64 44692}
!2526 = !{i64 44696}
!2527 = !{i64 44710}
!2528 = !{i64 44715}
!2529 = !{i64 44719}
!2530 = !{i64 44733}
!2531 = !{i64 44756}
!2532 = !{i64 44761}
!2533 = !{i64 44766}
!2534 = !{i64 44775}
!2535 = !{i64 44777}
!2536 = !{i64 44783}
!2537 = !{i64 44784}
!2538 = !{i64 44825}
!2539 = !{i64 44847}
!2540 = !{i64 44852}
!2541 = !{i64 44859}
!2542 = !{i64 44861}
!2543 = !{i64 44867}
!2544 = !{i64 44894}
!2545 = !{i64 44921}
!2546 = !{i64 44926}
!2547 = !{i64 44942}
!2548 = !{i64 44962}
!2549 = !{i64 44984}
!2550 = !{i64 44989}
!2551 = !{i64 45021}
!2552 = !{i64 45040}
!2553 = !{i64 45049}
!2554 = !{i64 45056}
!2555 = !{i64 45070}
!2556 = !{i64 45083}
!2557 = !{i64 45092}
!2558 = !{i64 45094}
!2559 = !{i64 45104}
!2560 = !{i64 45106}
!2561 = !{i64 45134}
!2562 = !{i64 45149}
!2563 = !{i64 45164}
!2564 = !{i64 45209}
!2565 = !{i64 45222}
!2566 = !{i64 45231}
!2567 = !{i64 45233}
!2568 = !{i64 45239}
!2569 = !{i64 45240}
!2570 = !{i64 45268}
!2571 = !{i64 45283}
!2572 = !{i64 45298}
!2573 = !{i64 45343}
!2574 = !{i64 45356}
!2575 = !{i64 45365}
!2576 = !{i64 45367}
!2577 = !{i64 45373}
!2578 = !{i64 45374}
!2579 = !{i64 45409}
!2580 = !{i64 45431}
!2581 = !{i64 45436}
!2582 = !{i64 45443}
!2583 = !{i64 45445}
!2584 = !{i64 45478}
!2585 = !{i64 45503}
!2586 = !{i64 45508}
!2587 = !{i64 45531}
!2588 = !{i64 45553}
!2589 = !{i64 45558}
!2590 = !{i64 45590}
!2591 = !{i64 45595}
!2592 = !{i64 45606}
!2593 = !{i64 45611}
!2594 = !{i64 45613}
!2595 = !{i64 45673}
!2596 = !{i64 45619}
!2597 = !{i64 45622}
!2598 = !{i64 45628}
!2599 = !{i64 45633}
!2600 = !{i64 45635}
!2601 = !{i64 45650}
!2602 = !{i64 45655}
!2603 = !{i64 45678}
!2604 = !{i64 45683}
!2605 = !{i64 45692}
!2606 = !{i64 45694}
!2607 = !{i64 45700}
!2608 = !{i64 45780}
!2609 = !{i64 45811}
!2610 = !{i64 45821}
!2611 = !{i64 45828}
!2612 = !{i64 45839}
!2613 = !{i64 45850}
!2614 = !{i64 45859}
!2615 = !{i64 45864}
!2616 = !{i64 45866}
!2617 = !{i64 45903}
!2618 = !{i64 45910}
!2619 = !{i64 45927}
!2620 = !{i64 45944}
!2621 = !{i64 45969}
!2622 = !{i64 45974}
!2623 = !{i64 46027}
!2624 = !{i64 46028}
!2625 = !{i64 46048}
!2626 = !{i64 46070}
!2627 = !{i64 46075}
!2628 = !{i64 46077}
!2629 = !{i64 46090}
!2630 = !{i64 46105}
!2631 = !{i64 46108}
!2632 = !{i64 46110}
!2633 = !{i64 46114}
!2634 = !{i64 46223}
!2635 = !{i64 46227}
!2636 = !{i64 46127}
!2637 = !{i64 46138}
!2638 = !{i64 46142}
!2639 = !{i64 46144}
!2640 = !{i64 46162}
!2641 = !{i64 46167}
!2642 = !{i64 46189}
!2643 = !{i64 46194}
!2644 = !{i64 46202}
!2645 = !{i64 46211}
!2646 = !{i64 46215}
!2647 = !{i64 46233}
!2648 = !{i64 46240}
!2649 = !{i64 46243}
!2650 = !{i64 46245}
!2651 = !{i64 46269}
!2652 = !{i64 46276}
!2653 = !{i64 46279}
!2654 = !{i64 46281}
!2655 = !{i64 46285}
!2656 = !{i64 46288}
!2657 = !{i64 46298}
!2658 = !{i64 46303}
!2659 = !{i64 46318}
!2660 = !{i64 46321}
!2661 = !{i64 46324}
!2662 = !{i64 46326}
!2663 = !{i64 46330}
!2664 = !{i64 46333}
!2665 = !{i64 46351}
!2666 = !{i64 46356}
!2667 = !{i64 46378}
!2668 = !{i64 46383}
!2669 = !{i64 46391}
!2670 = !{i64 46407}
!2671 = !{i64 46412}
!2672 = !{i64 46417}
!2673 = !{i64 46426}
!2674 = !{i64 46428}
!2675 = !{i64 46434}
!2676 = !{i64 46452}
!2677 = !{i64 46457}
!2678 = !{i64 46458}
!2679 = !{i64 46490}
!2680 = !{i64 46501}
!2681 = !{i64 46505}
!2682 = !{i64 46510}
!2683 = !{i64 46512}
!2684 = !{i64 46521}
!2685 = !{i64 46526}
!2686 = !{i64 46535}
!2687 = !{i64 46541}
!2688 = !{i64 46542}
!2689 = !{i64 46570}
!2690 = !{i64 46574}
!2691 = !{i64 46577}
!2692 = !{i64 46614}
!2693 = !{i64 46626}
!2694 = !{i64 46634}
!2695 = !{i64 46648}
!2696 = !{i64 46652}
!2697 = !{i64 46655}
!2698 = !{i64 46667}
!2699 = !{i64 46672}
!2700 = !{i64 46675}
!2701 = !{i64 46687}
!2702 = !{i64 46692}
!2703 = !{i64 46695}
!2704 = !{i64 46720}
!2705 = !{i64 46722}
!2706 = !{i64 46750}
!2707 = !{i64 46754}
!2708 = !{i64 46757}
!2709 = !{i64 46794}
!2710 = !{i64 46806}
!2711 = !{i64 46814}
!2712 = !{i64 46828}
!2713 = !{i64 46832}
!2714 = !{i64 46835}
!2715 = !{i64 46844}
!2716 = !{i64 46848}
!2717 = !{i64 46851}
!2718 = !{i64 46856}
!2719 = !{i64 46859}
!2720 = !{i64 46872}
!2721 = !{i64 46875}
!2722 = !{i64 46880}
!2723 = !{i64 46883}
!2724 = !{i64 46908}
!2725 = !{i64 46921}
!2726 = !{i64 46932}
!2727 = !{i64 46937}
!2728 = !{i64 46939}
!2729 = !{i64 46976}
!2730 = !{i64 46988}
!2731 = !{i64 46994}
!2732 = !{i64 47019}
!2733 = !{i64 47027}
!2734 = !{i64 47035}
!2735 = !{i64 47041}
!2736 = !{i64 47042}
!2737 = !{i64 47065}
!2738 = !{i64 47073}
!2739 = !{i64 47082}
!2740 = !{i64 47087}
!2741 = !{i64 47096}
!2742 = !{i64 47101}
!2743 = !{i64 47103}
!2744 = !{i64 47112}
!2745 = !{i64 47118}
!2746 = !{i64 47131}
!2747 = !{i64 47142}
!2748 = !{i64 47147}
!2749 = !{i64 47149}
!2750 = !{i64 47186}
!2751 = !{i64 47198}
!2752 = !{i64 47204}
!2753 = !{i64 47205}
!2754 = !{i64 47217}
!2755 = !{i64 47228}
!2756 = !{i64 47233}
!2757 = !{i64 47235}
!2758 = !{i64 47237}
!2759 = !{i64 47244}
!2760 = !{i64 47252}
!2761 = !{i64 47257}
!2762 = !{i64 47259}
!2763 = !{i64 47268}
!2764 = !{i64 47274}
!2765 = !{i64 47287}
!2766 = !{i64 47298}
!2767 = !{i64 47303}
!2768 = !{i64 47305}
!2769 = !{i64 47342}
!2770 = !{i64 47354}
!2771 = !{i64 47360}
!2772 = !{i64 47392}
!2773 = !{i64 47416}
!2774 = !{i64 47421}
!2775 = !{i64 47423}
!2776 = !{i64 47429}
!2777 = !{i64 47430}
!2778 = !{i64 47442}
!2779 = !{i64 47453}
!2780 = !{i64 47458}
!2781 = !{i64 47460}
!2782 = !{i64 47462}
!2783 = !{i64 47469}
!2784 = !{i64 47477}
!2785 = !{i64 47482}
!2786 = !{i64 47484}
!2787 = !{i64 47493}
!2788 = !{i64 47499}
!2789 = !{i64 47523}
!2790 = !{i64 47532}
!2791 = !{i64 47539}
!2792 = !{i64 47546}
!2793 = !{i64 47567}
!2794 = !{i64 47571}
!2795 = !{i64 47574}
!2796 = !{i64 47578}
!2797 = !{i64 47582}
!2798 = !{i64 47586}
!2799 = !{i64 47597}
!2800 = !{i64 47607}
!2801 = !{i64 47624}
!2802 = !{i64 47646}
!2803 = !{i64 47659}
!2804 = !{i64 47672}
!2805 = !{i64 47682}
!2806 = !{i64 47691}
!2807 = !{i64 47693}
!2808 = !{i64 47703}
!2809 = !{i64 47704}
!2810 = !{i64 47720}
!2811 = !{i64 47754}
!2812 = !{i64 47743}
!2813 = !{i64 47750}
!2814 = !{i64 47762}
!2815 = !{i64 47775}
!2816 = !{i64 47783}
!2817 = !{i64 47785}
!2818 = !{i64 47745}
!2819 = !{i64 47795}
!2820 = !{i64 47804}
!2821 = !{i64 47806}
!2822 = !{i64 47812}
!2823 = !{i64 47843}
!2824 = !{i64 47845}
!2825 = !{i64 47849}
!2826 = !{i64 47870}
!2827 = !{i64 47877}
!2828 = !{i64 47883}
!2829 = !{i64 47904}
!2830 = !{i64 47911}
!2831 = !{i64 47917}
!2832 = !{i64 47934}
!2833 = !{i64 47939}
!2834 = !{i64 47964}
!2835 = !{i64 47981}
!2836 = !{i64 47988}
!2837 = !{i64 48001}
!2838 = !{i64 48012}
!2839 = !{i64 48024}
!2840 = !{i64 48053}
!2841 = !{i64 48077}
!2842 = !{i64 48083}
!2843 = !{i64 48096}
!2844 = !{i64 48107}
!2845 = !{i64 48112}
!2846 = !{i64 48114}
!2847 = !{i64 48151}
!2848 = !{i64 48163}
!2849 = !{i64 48169}
!2850 = !{i64 48190}
!2851 = !{i64 48197}
!2852 = !{i64 48209}
!2853 = !{i64 48216}
!2854 = !{i64 48234}
!2855 = !{i64 48241}
!2856 = !{i64 48249}
!2857 = !{i64 48259}
!2858 = !{i64 48266}
!2859 = !{i64 48291}
!2860 = !{i64 48308}
!2861 = !{i64 48314}
!2862 = !{i64 48336}
!2863 = !{i64 48345}
!2864 = !{i64 48354}
!2865 = !{i64 48363}
!2866 = !{i64 48375}
!2867 = !{i64 48382}
!2868 = !{i64 48395}
!2869 = !{i64 48406}
!2870 = !{i64 48411}
!2871 = !{i64 48413}
!2872 = !{i64 48450}
!2873 = !{i64 48462}
!2874 = !{i64 48468}
!2875 = !{i64 48493}
!2876 = !{i64 48500}
!2877 = !{i64 48502}
!2878 = !{i64 48588}
!2879 = !{i64 48592}
!2880 = !{i64 48544}
!2881 = !{i64 48557}
!2882 = !{i64 48562}
!2883 = !{i64 48564}
!2884 = !{i64 48579}
!2885 = !{i64 48600}
!2886 = !{i64 48630}
!2887 = !{i64 48641}
!2888 = !{i64 48647}
!2889 = !{i64 48678}
!2890 = !{i64 48681}
!2891 = !{i64 48694}
!2892 = !{i64 48695}
!2893 = !{i64 48706}
!2894 = !{i64 48710}
!2895 = !{i64 48715}
!2896 = !{i64 48718}
!2897 = !{i64 48721}
!2898 = !{i64 48723}
!2899 = !{i64 48732}
!2900 = !{i64 48738}
!2901 = !{i64 48750}
!2902 = !{i64 48754}
!2903 = !{i32 0, i32 33}
!2904 = !{i64 48772}
!2905 = !{i64 48774}
!2906 = !{i64 48796}
!2907 = !{i64 48814}
!2908 = !{i64 48818}
!2909 = !{i64 48827}
!2910 = !{i64 48839}
!2911 = !{i64 48847}
!2912 = !{i64 48865}
!2913 = !{i64 48874}
!2914 = !{i64 48879}
!2915 = !{i64 48885}
!2916 = !{i64 48893}
!2917 = !{i64 48896}
!2918 = !{i64 48905}
!2919 = !{i64 48930}
!2920 = !{i64 48986}
!2921 = !{i64 49004}
!2922 = !{i64 49010}
!2923 = !{i64 49048}
!2924 = !{i64 49069}
!2925 = !{i64 49074}
!2926 = !{i64 49079}
!2927 = !{i64 49091}
!2928 = !{i64 49103}
!2929 = !{i64 49108}
!2930 = !{i64 49112}
!2931 = !{i64 49137}
!2932 = !{i64 49148}
!2933 = !{i64 49172}
!2934 = !{i64 49178}
!2935 = !{i64 49180}
!2936 = !{i64 49212}
!2937 = !{i64 49219}
!2938 = !{i64 49223}
!2939 = !{i64 49234}
!2940 = !{i64 49242}
!2941 = !{i64 49246}
!2942 = !{i64 49283}
!2943 = !{i64 49290}
!2944 = !{i64 49317}
!2945 = !{i64 49323}
!2946 = !{i64 49358}
!2947 = !{i64 49365}
!2948 = !{i64 49366}
!2949 = !{i64 49387}
!2950 = !{i64 49413}
!2951 = !{i64 49436}
!2952 = !{i64 49441}
!2953 = !{i64 49451}
!2954 = !{i64 49461}
!2955 = !{i64 49470}
!2956 = !{i64 49472}
!2957 = !{i64 49482}
!2958 = !{i64 49518}
!2959 = !{i64 49525}
!2960 = !{i64 49543}
!2961 = !{i64 49571}
!2962 = !{i64 49589}
!2963 = !{i64 49599}
!2964 = !{i64 49600}
!2965 = !{i64 49626}
!2966 = !{i64 49634}
!2967 = !{i64 49636}
!2968 = !{i64 49673}
!2969 = !{i64 49688}
!2970 = !{i64 49694}
!2971 = !{i64 49718}
!2972 = !{i64 49724}
!2973 = !{i64 49755}
!2974 = !{i64 49758}
!2975 = !{i64 49762}
!2976 = !{i64 49778}
!2977 = !{i64 49789}
!2978 = !{i64 49794}
!2979 = !{i64 49796}
!2980 = !{i64 49812}
!2981 = !{i64 49841}
!2982 = !{i64 49853}
!2983 = !{i64 49862}
!2984 = !{i64 49869}
!2985 = !{i64 49878}
!2986 = !{i64 49880}
!2987 = !{i64 49886}
!2988 = !{i64 49888}
!2989 = !{i64 49904}
!2990 = !{i64 49933}
!2991 = !{i64 49938}
!2992 = !{i64 49950}
!2993 = !{i64 49959}
!2994 = !{i64 49961}
!2995 = !{i64 49967}
!2996 = !{i64 49968}
!2997 = !{i64 49984}
!2998 = !{i64 50013}
!2999 = !{i64 50018}
!3000 = !{i64 50030}
!3001 = !{i64 50039}
!3002 = !{i64 50041}
!3003 = !{i64 50047}
!3004 = !{i64 50048}
!3005 = !{i64 50064}
!3006 = !{i64 50093}
!3007 = !{i64 50105}
!3008 = !{i64 50110}
!3009 = !{i64 50117}
!3010 = !{i64 50126}
!3011 = !{i64 50128}
!3012 = !{i64 50134}
!3013 = !{i64 50136}
!3014 = !{i64 50152}
!3015 = !{i64 50181}
!3016 = !{i64 50186}
!3017 = !{i64 50194}
!3018 = !{i64 50203}
!3019 = !{i64 50205}
!3020 = !{i64 50211}
!3021 = !{i64 50235}
!3022 = !{i64 50241}
!3023 = !{i64 50265}
!3024 = !{i64 50273}
!3025 = !{i64 50279}
!3026 = !{i64 50294}
!3027 = !{i64 50318}
!3028 = !{i64 50324}
!3029 = !{i64 50351}
!3030 = !{i64 50357}
!3031 = !{i64 50384}
!3032 = !{i64 50390}
!3033 = !{i64 50407}
!3034 = !{i64 50412}
!3035 = !{i64 50431}
!3036 = !{i64 50455}
!3037 = !{i64 50463}
!3038 = !{i64 50469}
!3039 = !{i64 50493}
!3040 = !{i64 50499}
!3041 = !{i64 50514}
!3042 = !{i64 50515}
!3043 = !{i64 50538}
!3044 = !{i64 50546}
!3045 = !{i64 50548}
!3046 = !{i64 50550}
!3047 = !{i64 50555}
!3048 = !{i64 50564}
!3049 = !{i64 50569}
!3050 = !{i64 50571}
!3051 = !{i64 50589}
!3052 = !{i64 50616}
!3053 = !{i64 50622}
!3054 = !{i64 50649}
!3055 = !{i64 50655}
!3056 = !{i64 50679}
!3057 = !{i64 50687}
!3058 = !{i64 50693}
!3059 = !{i64 50694}
!3060 = !{i64 50717}
!3061 = !{i64 50725}
!3062 = !{i64 50727}
!3063 = !{i64 50729}
!3064 = !{i64 50734}
!3065 = !{i64 50743}
!3066 = !{i64 50748}
!3067 = !{i64 50750}
!3068 = !{i64 50751}
!3069 = !{i64 50774}
!3070 = !{i64 50782}
!3071 = !{i64 50784}
!3072 = !{i64 50786}
!3073 = !{i64 50791}
!3074 = !{i64 50800}
!3075 = !{i64 50805}
!3076 = !{i64 50807}
!3077 = !{i64 50808}
!3078 = !{i64 50831}
!3079 = !{i64 50839}
!3080 = !{i64 50841}
!3081 = !{i64 50878}
!3082 = !{i64 50891}
!3083 = !{i64 50892}
!3084 = !{i64 50915}
!3085 = !{i64 50923}
!3086 = !{i64 50925}
!3087 = !{i64 50927}
!3088 = !{i64 50932}
!3089 = !{i64 50941}
!3090 = !{i64 50946}
!3091 = !{i64 50948}
!3092 = !{i64 50973}
!3093 = !{i64 50978}
!3094 = !{i64 50983}
!3095 = !{i64 50989}
!3096 = !{i64 51006}
!3097 = !{i64 51011}
!3098 = !{i64 51030}
!3099 = !{i64 51054}
!3100 = !{i64 51062}
!3101 = !{i64 51068}
!3102 = !{i64 51069}
!3103 = !{i64 51092}
!3104 = !{i64 51100}
!3105 = !{i64 51102}
!3106 = !{i64 51104}
!3107 = !{i64 51109}
!3108 = !{i64 51118}
!3109 = !{i64 51123}
!3110 = !{i64 51125}
!3111 = !{i64 51126}
!3112 = !{i64 51149}
!3113 = !{i64 51157}
!3114 = !{i64 51159}
!3115 = !{i64 51161}
!3116 = !{i64 51166}
!3117 = !{i64 51175}
!3118 = !{i64 51180}
!3119 = !{i64 51182}
!3120 = !{i64 51200}
!3121 = !{i64 51207}
!3122 = !{i64 51219}
!3123 = !{i64 51229}
!3124 = !{i64 51253}
!3125 = !{i64 51262}
!3126 = !{i64 51268}
!3127 = !{i64 51293}
!3128 = !{i64 51300}
!3129 = !{i64 51325}
!3130 = !{i64 51332}
!3131 = !{i64 51357}
!3132 = !{i64 51364}
!3133 = !{i64 51366}
!3134 = !{i64 51393}
!3135 = !{i64 51398}
!3136 = !{i64 51400}
!3137 = !{i64 51409}
!3138 = !{i64 51414}
!3139 = !{i64 51416}
!3140 = !{i64 51425}
!3141 = !{i64 51430}
!3142 = !{i64 51433}
!3143 = !{i64 51454}
!3144 = !{i64 51480}
!3145 = !{i64 51495}
!3146 = !{i64 51500}
!3147 = !{i64 51504}
!3148 = !{i64 51512}
!3149 = !{i64 51542}
!3150 = !{i64 51549}
!3151 = !{i64 51574}
!3152 = !{i64 51589}
!3153 = !{i64 51600}
!3154 = !{i64 51612}
!3155 = !{i64 51623}
!3156 = !{i64 51717}
!3157 = !{i64 51727}
!3158 = !{i64 51748}
!3159 = !{i64 51755}
!3160 = !{i64 51761}
!3161 = !{i64 51792}
!3162 = !{i64 51795}
!3163 = !{i64 51799}
!3164 = !{i64 51820}
!3165 = !{i64 51846}
!3166 = !{i64 51861}
!3167 = !{i64 51866}
!3168 = !{i64 51870}
!3169 = !{i64 51878}
!3170 = !{i64 51902}
!3171 = !{i64 51908}
!3172 = !{i64 52003}
!3173 = !{i64 52013}
!3174 = !{i64 52042}
!3175 = !{i64 52044}
!3176 = !{i64 52057}
!3177 = !{i64 52058}
!3178 = !{i64 52079}
!3179 = !{i64 52101}
!3180 = !{i64 52116}
!3181 = !{i64 52137}
!3182 = !{i64 52142}
!3183 = !{i64 52154}
!3184 = !{i64 52163}
!3185 = !{i64 52165}
!3186 = !{i64 52175}
!3187 = !{i64 52203}
!3188 = !{i64 52208}
!3189 = !{i64 52215}
!3190 = !{i64 52222}
!3191 = !{i64 52229}
!3192 = !{i64 52234}
!3193 = !{i64 52241}
!3194 = !{i64 52246}
!3195 = !{i64 52247}
!3196 = !{i64 52268}
!3197 = !{i64 52290}
!3198 = !{i64 52305}
!3199 = !{i64 52326}
!3200 = !{i64 52331}
!3201 = !{i64 52343}
!3202 = !{i64 52352}
!3203 = !{i64 52354}
!3204 = !{i64 52364}
!3205 = !{i64 52379}
!3206 = !{i64 52403}
!3207 = !{i64 52409}
!3208 = !{i64 52436}
!3209 = !{i64 52442}
!3210 = !{i64 52466}
!3211 = !{i64 52472}
!3212 = !{i64 52499}
!3213 = !{i64 52505}
!3214 = !{i64 52529}
!3215 = !{i64 52535}
!3216 = !{i64 52562}
!3217 = !{i64 52568}
!3218 = !{i64 52610}
!3219 = !{i64 52617}
!3220 = !{i64 52642}
!3221 = !{i64 52657}
!3222 = !{i64 52664}
!3223 = !{i64 52706}
!3224 = !{i64 52713}
!3225 = !{i64 52738}
!3226 = !{i64 52753}
!3227 = !{i64 52760}
!3228 = !{i64 52787}
!3229 = !{i64 52813}
!3230 = !{i64 52824}
!3231 = !{i64 52829}
!3232 = !{i64 52833}
!3233 = !{i64 52851}
!3234 = !{i64 52856}
!3235 = !{i64 52886}
!3236 = !{i64 52896}
!3237 = !{i64 52905}
!3238 = !{i64 52907}
!3239 = !{i64 52921}
!3240 = !{i64 52952}
!3241 = !{i64 52955}
!3242 = !{i64 52959}
!3243 = !{i64 52986}
!3244 = !{i64 52995}
!3245 = !{i64 53003}
!3246 = !{i64 53004}
!3247 = !{i64 53030}
!3248 = !{i64 53038}
!3249 = !{i64 53040}
!3250 = !{i64 53077}
!3251 = !{i64 53092}
!3252 = !{i64 53098}
!3253 = !{i64 53100}
!3254 = !{i64 53116}
!3255 = !{i64 53145}
!3256 = !{i64 53157}
!3257 = !{i64 53162}
!3258 = !{i64 53169}
!3259 = !{i64 53178}
!3260 = !{i64 53180}
!3261 = !{i64 53186}
!3262 = !{i64 53188}
!3263 = !{i64 53204}
!3264 = !{i64 53233}
!3265 = !{i64 53238}
!3266 = !{i64 53246}
!3267 = !{i64 53255}
!3268 = !{i64 53257}
!3269 = !{i64 53263}
!3270 = !{i64 53264}
!3271 = !{i64 53294}
!3272 = !{i64 53309}
!3273 = !{i64 53314}
!3274 = !{i64 53317}
!3275 = !{i64 53326}
!3276 = !{i64 53341}
!3277 = !{i64 53356}
!3278 = !{i64 53370}
!3279 = !{i64 53375}
!3280 = !{i64 53377}
!3281 = !{i64 53386}
!3282 = !{i64 53399}
!3283 = !{i64 53440}
!3284 = !{i64 53456}
!3285 = !{i64 53469}
!3286 = !{i64 53487}
!3287 = !{i64 53503}
!3288 = !{i64 53508}
!3289 = !{i64 53518}
!3290 = !{i64 53529}
!3291 = !{i64 53544}
!3292 = !{i64 53545}
!3293 = !{i64 53568}
!3294 = !{i64 53576}
!3295 = !{i64 53578}
!3296 = !{i64 53580}
!3297 = !{i64 53585}
!3298 = !{i64 53594}
!3299 = !{i64 53599}
!3300 = !{i64 53601}
!3301 = !{i64 53602}
!3302 = !{i64 53625}
!3303 = !{i64 53654}
!3304 = !{i64 53664}
!3305 = !{i64 53669}
!3306 = !{i64 53687}
!3307 = !{i64 53696}
!3308 = !{i64 53704}
!3309 = !{i64 53707}
!3310 = !{i64 53716}
!3311 = !{i64 53725}
!3312 = !{i64 53727}
!3313 = !{i64 53733}
!3314 = !{i64 53734}
!3315 = !{i64 53757}
!3316 = !{i64 53765}
!3317 = !{i64 53767}
!3318 = !{i64 53769}
!3319 = !{i64 53774}
!3320 = !{i64 53783}
!3321 = !{i64 53788}
!3322 = !{i64 53790}
!3323 = !{i64 53814}
!3324 = !{i64 53820}
!3325 = !{i64 53850}
!3326 = !{i64 53857}
!3327 = !{i64 53882}
!3328 = !{i64 53897}
!3329 = !{i64 53908}
!3330 = !{i64 53920}
!3331 = !{i64 53931}
!3332 = !{i64 53962}
!3333 = !{i64 53965}
!3334 = !{i64 53969}
!3335 = !{i64 53996}
!3336 = !{i64 54005}
!3337 = !{i64 54013}
!3338 = !{i64 54014}
!3339 = !{i64 54040}
!3340 = !{i64 54048}
!3341 = !{i64 54050}
!3342 = !{i64 54087}
!3343 = !{i64 54102}
!3344 = !{i64 54108}
!3345 = !{i64 54136}
!3346 = !{i64 54145}
!3347 = !{i64 54152}
!3348 = !{i64 54160}
!3349 = !{i64 54169}
!3350 = !{i64 54170}
!3351 = !{i64 54196}
!3352 = !{i64 54204}
!3353 = !{i64 54206}
!3354 = !{i64 54243}
!3355 = !{i64 54258}
!3356 = !{i64 54264}
!3357 = !{i64 54278}
!3358 = !{i64 54285}
!3359 = !{i64 54293}
!3360 = !{i64 54298}
!3361 = !{i64 54323}
!3362 = !{i64 54328}
!3363 = !{i64 54335}
!3364 = !{i64 54343}
!3365 = !{i64 54348}
!3366 = !{i64 54404}
!3367 = !{i64 54415}
!3368 = !{i64 54429}
!3369 = !{i64 54459}
!3370 = !{i64 54481}
!3371 = !{i64 54499}
!3372 = !{i64 54518}
!3373 = !{i64 54534}
!3374 = !{i64 54553}
!3375 = !{i64 54576}
!3376 = !{i64 54592}
!3377 = !{i64 54601}
!3378 = !{i64 54604}
!3379 = !{i64 54618}
!3380 = !{i64 54623}
!3381 = !{i64 54633}
!3382 = !{i64 54644}
!3383 = !{i64 54645}
!3384 = !{i64 54668}
!3385 = !{i64 54676}
!3386 = !{i64 54678}
!3387 = !{i64 54680}
!3388 = !{i64 54685}
!3389 = !{i64 54694}
!3390 = !{i64 54699}
!3391 = !{i64 54701}
!3392 = !{i64 54722}
!3393 = !{i64 54748}
!3394 = !{i64 54763}
!3395 = !{i64 54768}
!3396 = !{i64 54772}
!3397 = !{i64 54780}
!3398 = !{i64 54796}
!3399 = !{i64 54822}
!3400 = !{i64 54827}
!3401 = !{i64 54828}
!3402 = !{i64 54851}
!3403 = !{i64 54854}
!3404 = !{i64 54866}
!3405 = !{i64 54873}
!3406 = !{i64 54874}
!3407 = !{i64 54898}
!3408 = !{i64 54917}
!3409 = !{i64 54930}
!3410 = !{i64 54950}
!3411 = !{i64 54955}
!3412 = !{i64 54967}
!3413 = !{i64 54969}
!3414 = !{i64 54988}
!3415 = !{i64 55006}
!3416 = !{i64 55011}
!3417 = !{i64 55025}
!3418 = !{i64 55030}
!3419 = !{i64 55055}
!3420 = !{i64 55067}
!3421 = !{i64 55089}
!3422 = !{i64 55094}
!3423 = !{i64 55102}
!3424 = !{i64 55116}
!3425 = !{i64 55128}
!3426 = !{i64 55137}
!3427 = !{i64 55146}
!3428 = !{i64 55148}
!3429 = !{i64 55154}
!3430 = !{i64 55172}
!3431 = !{i64 55190}
!3432 = !{i64 55191}
!3433 = !{i64 55207}
!3434 = !{i64 55229}
!3435 = !{i64 55234}
!3436 = !{i64 55245}
!3437 = !{i64 55254}
!3438 = !{i64 55263}
!3439 = !{i64 55265}
!3440 = !{i64 55271}
!3441 = !{i64 55289}
!3442 = !{i64 55307}
!3443 = !{i64 55343}
!3444 = !{i64 55365}
!3445 = !{i64 55372}
!3446 = !{i64 55398}
!3447 = !{i64 55403}
!3448 = !{i64 55421}
!3449 = !{i64 55440}
!3450 = !{i64 55464}
!3451 = !{i64 55470}
!3452 = !{i64 55494}
!3453 = !{i64 55500}
!3454 = !{i64 55524}
!3455 = !{i64 55532}
!3456 = !{i64 55538}
!3457 = !{i64 55562}
!3458 = !{i64 55570}
!3459 = !{i64 55576}
!3460 = !{i64 55594}
!3461 = !{i64 55620}
!3462 = !{i64 55627}
!3463 = !{i64 55635}
!3464 = !{i64 55641}
!3465 = !{i64 55666}
!3466 = !{i64 55671}
!3467 = !{i64 55700}
!3468 = !{i64 55705}
!3469 = !{i64 55708}
!3470 = !{i64 55716}
!3471 = !{i64 55734}
!3472 = !{i64 55754}
!3473 = !{i64 55757}
!3474 = !{i64 55761}
!3475 = !{i64 55762}
!3476 = !{i64 55778}
!3477 = !{i64 55800}
!3478 = !{i64 55805}
!3479 = !{i64 55816}
!3480 = !{i64 55825}
!3481 = !{i64 55834}
!3482 = !{i64 55836}
!3483 = !{i64 55842}
!3484 = !{i64 55860}
!3485 = !{i64 55878}
!3486 = !{i64 55896}
!3487 = !{i64 55916}
!3488 = !{i64 55919}
!3489 = !{i64 55923}
!3490 = !{i64 55947}
!3491 = !{i64 55952}
!3492 = !{i64 55957}
!3493 = !{i64 55981}
!3494 = !{i64 55987}
!3495 = !{i64 56005}
!3496 = !{i64 56023}
!3497 = !{i64 56041}
!3498 = !{i64 56061}
!3499 = !{i64 56064}
!3500 = !{i64 56068}
!3501 = !{i64 56092}
!3502 = !{i64 56098}
!3503 = !{i64 56113}
!3504 = !{i64 56137}
!3505 = !{i64 56143}
!3506 = !{i64 56158}
!3507 = !{i64 56176}
!3508 = !{i64 56180}
!3509 = !{i64 56183}
!3510 = !{i64 56187}
!3511 = !{i64 56211}
!3512 = !{i64 56217}
!3513 = !{i64 56232}
!3514 = !{i64 56257}
!3515 = !{i64 56262}
!3516 = !{i64 56264}
!3517 = !{i64 56268}
!3518 = !{i64 56286}
!3519 = !{i64 56304}
!3520 = !{i64 56324}
!3521 = !{i64 56327}
!3522 = !{i64 56331}
!3523 = !{i64 56355}
!3524 = !{i64 56361}
!3525 = !{i64 56376}
!3526 = !{i64 56403}
!3527 = !{i64 56409}
!3528 = !{i64 56433}
!3529 = !{i64 56439}
!3530 = !{i64 56454}
!3531 = !{i64 56481}
!3532 = !{i64 56487}
!3533 = !{i64 56502}
!3534 = !{i64 56520}
!3535 = !{i64 56538}
!3536 = !{i64 56543}
!3537 = !{i64 56545}
!3538 = !{i64 56554}
!3539 = !{i64 56587}
!3540 = !{i64 56593}
!3541 = !{i64 56617}
!3542 = !{i64 56626}
!3543 = !{i64 56633}
!3544 = !{i64 56634}
!3545 = !{i64 56657}
!3546 = !{i64 56662}
!3547 = !{i64 56665}
!3548 = !{i64 56667}
!3549 = !{i64 56676}
!3550 = !{i64 56684}
!3551 = !{i64 56691}
!3552 = !{i64 56710}
!3553 = !{i64 56732}
!3554 = !{i64 56733}
!3555 = !{i64 56749}
!3556 = !{i64 56771}
!3557 = !{i64 56776}
!3558 = !{i64 56787}
!3559 = !{i64 56796}
!3560 = !{i64 56805}
!3561 = !{i64 56807}
!3562 = !{i64 56813}
!3563 = !{i64 56831}
!3564 = !{i64 56863}
!3565 = !{i64 56868}
!3566 = !{i64 56875}
!3567 = !{i64 56885}
!3568 = !{i64 56890}
!3569 = !{i64 56897}
!3570 = !{i64 56902}
!3571 = !{i64 56920}
!3572 = !{i64 56953}
!3573 = !{i64 56958}
!3574 = !{i64 56965}
!3575 = !{i64 56975}
!3576 = !{i64 56980}
!3577 = !{i64 56987}
!3578 = !{i64 56992}
!3579 = !{i64 56993}
!3580 = !{i64 57009}
!3581 = !{i64 57031}
!3582 = !{i64 57036}
!3583 = !{i64 57047}
!3584 = !{i64 57056}
!3585 = !{i64 57065}
!3586 = !{i64 57067}
!3587 = !{i64 57073}
!3588 = !{i64 57091}
!3589 = !{i64 57092}
!3590 = !{i64 57108}
!3591 = !{i64 57130}
!3592 = !{i64 57135}
!3593 = !{i64 57146}
!3594 = !{i64 57155}
!3595 = !{i64 57164}
!3596 = !{i64 57166}
!3597 = !{i64 57172}
!3598 = !{i64 57190}
!3599 = !{i64 57191}
!3600 = !{i64 57207}
!3601 = !{i64 57229}
!3602 = !{i64 57234}
!3603 = !{i64 57245}
!3604 = !{i64 57254}
!3605 = !{i64 57263}
!3606 = !{i64 57265}
!3607 = !{i64 57271}
!3608 = !{i64 57289}
!3609 = !{i64 57313}
!3610 = !{i64 57319}
!3611 = !{i64 57320}
!3612 = !{i64 57341}
!3613 = !{i64 57356}
!3614 = !{i64 57361}
!3615 = !{i64 57363}
!3616 = !{i64 57379}
!3617 = !{i64 57384}
!3618 = !{i64 57388}
!3619 = !{i64 57424}
!3620 = !{i64 57437}
!3621 = !{i64 57446}
!3622 = !{i64 57475}
!3623 = !{i64 57484}
!3624 = !{i64 57492}
!3625 = !{i64 57501}
!3626 = !{i64 57503}
!3627 = !{i64 57513}
!3628 = !{i64 57546}
!3629 = !{i64 57561}
!3630 = !{i64 57582}
!3631 = !{i64 57596}
!3632 = !{i64 57621}
!3633 = !{i64 57627}
!3634 = !{i64 57651}
!3635 = !{i64 57657}
!3636 = !{i64 57682}
!3637 = !{i64 57687}
!3638 = !{i64 57711}
!3639 = !{i64 57720}
!3640 = !{i64 57727}
!3641 = !{i64 57728}
!3642 = !{i64 57751}
!3643 = !{i64 57756}
!3644 = !{i64 57759}
!3645 = !{i64 57761}
!3646 = !{i64 57770}
!3647 = !{i64 57778}
!3648 = !{i64 57785}
!3649 = !{i64 57804}
!3650 = !{i64 57848}
!3651 = !{i64 57854}
!3652 = !{i64 57880}
!3653 = !{i64 57895}
!3654 = !{i64 57900}
!3655 = !{i64 57904}
!3656 = !{i64 57912}
!3657 = !{i64 57914}
!3658 = !{i64 57938}
!3659 = !{i64 57942}
!3660 = !{i64 57945}
!3661 = !{i64 57957}
!3662 = !{i64 57966}
!3663 = !{i64 57981}
!3664 = !{i64 57986}
!3665 = !{i64 57988}
!3666 = !{i64 58024}
!3667 = !{i64 58032}
!3668 = !{i64 58040}
!3669 = !{i64 58048}
!3670 = !{i64 58054}
!3671 = !{i64 58078}
!3672 = !{i64 58084}
!3673 = !{i64 58111}
!3674 = !{i64 58117}
!3675 = !{i64 58141}
!3676 = !{i64 58147}
!3677 = !{i64 58162}
!3678 = !{i64 58163}
!3679 = !{i64 58179}
!3680 = !{i64 58201}
!3681 = !{i64 58206}
!3682 = !{i64 58217}
!3683 = !{i64 58226}
!3684 = !{i64 58235}
!3685 = !{i64 58237}
!3686 = !{i64 58243}
!3687 = !{i64 58267}
!3688 = !{i64 58273}
!3689 = !{i64 58297}
!3690 = !{i64 58303}
!3691 = !{i64 58327}
!3692 = !{i64 58333}
!3693 = !{i64 58352}
!3694 = !{i64 58376}
!3695 = !{i64 58382}
!3696 = !{i64 58426}
!3697 = !{i64 58432}
!3698 = !{i64 58456}
!3699 = !{i64 58462}
!3700 = !{i64 58477}
!3701 = !{i64 58504}
!3702 = !{i64 58510}
!3703 = !{i64 58524}
!3704 = !{i64 58531}
!3705 = !{i64 58539}
!3706 = !{i64 58544}
!3707 = !{i64 58558}
!3708 = !{i64 58565}
!3709 = !{i64 58573}
!3710 = !{i64 58578}
!3711 = !{i64 58603}
!3712 = !{i64 58620}
!3713 = !{i64 58626}
!3714 = !{i64 58662}
!3715 = !{i64 58669}
!3716 = !{i64 58704}
!3717 = !{i64 58711}
!3718 = !{i64 58736}
!3719 = !{i64 58749}
!3720 = !{i64 58752}
!3721 = !{i64 58755}
!3722 = !{i64 58741}
!3723 = !{i64 58764}
!3724 = !{i64 58779}
!3725 = !{i64 58784}
!3726 = !{i64 58793}
!3727 = !{i64 58802}
!3728 = !{i64 58815}
!3729 = !{i64 58843}
!3730 = !{i64 58861}
!3731 = !{i64 58868}
!3732 = !{i64 58892}
!3733 = !{i64 58897}
!3734 = !{i64 58901}
!3735 = !{i64 58925}
!3736 = !{i64 58930}
!3737 = !{i64 58934}
!3738 = !{i64 58970}
!3739 = !{i64 58977}
!3740 = !{i64 59020}
!3741 = !{i64 59031}
!3742 = !{i64 59049}
!3743 = !{i64 59060}
!3744 = !{i64 59084}
!3745 = !{i64 59089}
!3746 = !{i64 59093}
!3747 = !{i64 59111}
!3748 = !{i64 59135}
!3749 = !{i64 59141}
!3750 = !{i64 59159}
!3751 = !{i64 59183}
!3752 = !{i64 59199}
!3753 = !{i64 59206}
!3754 = !{i64 59230}
!3755 = !{i64 59246}
!3756 = !{i64 59253}
!3757 = !{i64 59277}
!3758 = !{i64 59283}
!3759 = !{i64 59307}
!3760 = !{i64 59313}
!3761 = !{i64 59314}
!3762 = !{i64 59330}
!3763 = !{i64 59352}
!3764 = !{i64 59357}
!3765 = !{i64 59368}
!3766 = !{i64 59377}
!3767 = !{i64 59386}
!3768 = !{i64 59388}
!3769 = !{i64 59394}
!3770 = !{i64 59395}
!3771 = !{i64 59411}
!3772 = !{i64 59433}
!3773 = !{i64 59438}
!3774 = !{i64 59449}
!3775 = !{i64 59458}
!3776 = !{i64 59467}
!3777 = !{i64 59469}
!3778 = !{i64 59475}
!3779 = !{i64 59476}
!3780 = !{i64 59492}
!3781 = !{i64 59514}
!3782 = !{i64 59519}
!3783 = !{i64 59530}
!3784 = !{i64 59539}
!3785 = !{i64 59548}
!3786 = !{i64 59550}
!3787 = !{i64 59556}
!3788 = !{i64 59557}
!3789 = !{i64 59573}
!3790 = !{i64 59595}
!3791 = !{i64 59600}
!3792 = !{i64 59611}
!3793 = !{i64 59620}
!3794 = !{i64 59629}
!3795 = !{i64 59631}
!3796 = !{i64 59637}
!3797 = !{i64 59676}
!3798 = !{i64 59682}
!3799 = !{i64 59683}
!3800 = !{i64 59699}
!3801 = !{i64 59721}
!3802 = !{i64 59726}
!3803 = !{i64 59737}
!3804 = !{i64 59746}
!3805 = !{i64 59755}
!3806 = !{i64 59757}
!3807 = !{i64 59763}
!3808 = !{i64 59781}
!3809 = !{i64 59782}
!3810 = !{i64 59798}
!3811 = !{i64 59820}
!3812 = !{i64 59825}
!3813 = !{i64 59836}
!3814 = !{i64 59845}
!3815 = !{i64 59854}
!3816 = !{i64 59856}
!3817 = !{i64 59862}
!3818 = !{i64 59880}
!3819 = !{i64 59899}
!3820 = !{i64 59934}
!3821 = !{i64 59941}
!3822 = !{i64 59973}
!3823 = !{i64 59978}
!3824 = !{i64 59981}
!3825 = !{i64 59989}
!3826 = !{i64 60013}
!3827 = !{i64 60018}
!3828 = !{i64 60022}
!3829 = !{i64 60046}
!3830 = !{i64 60052}
!3831 = !{i64 60070}
!3832 = !{i64 60095}
!3833 = !{i64 60101}
!3834 = !{i64 60125}
!3835 = !{i64 60131}
!3836 = !{i64 60155}
!3837 = !{i64 60161}
!3838 = !{i64 60162}
!3839 = !{i64 60178}
!3840 = !{i64 60200}
!3841 = !{i64 60205}
!3842 = !{i64 60216}
!3843 = !{i64 60225}
!3844 = !{i64 60234}
!3845 = !{i64 60236}
!3846 = !{i64 60242}
!3847 = !{i64 60290}
!3848 = !{i64 60309}
!3849 = !{i64 60316}
!3850 = !{i64 60334}
!3851 = !{i64 60367}
!3852 = !{i64 60376}
!3853 = !{i64 60380}
!3854 = !{i64 60383}
!3855 = !{i64 60386}
!3856 = !{i64 60397}
!3857 = !{i64 60402}
!3858 = !{i64 60409}
!3859 = !{i64 60414}
!3860 = !{i64 60436}
!3861 = !{i64 60454}
!3862 = !{i64 60459}
!3863 = !{i64 60472}
!3864 = !{i64 60495}
!3865 = !{i64 60509}
!3866 = !{i64 60514}
!3867 = !{i64 60516}
!3868 = !{i64 60540}
!3869 = !{i64 60573}
!3870 = !{i64 60582}
!3871 = !{i64 60591}
!3872 = !{i64 60593}
!3873 = !{i64 60599}
!3874 = !{i64 60634}
!3875 = !{i64 60641}
!3876 = !{i64 60673}
!3877 = !{i64 60678}
!3878 = !{i64 60681}
!3879 = !{i64 60689}
!3880 = !{i64 60690}
!3881 = !{i64 60721}
!3882 = !{i64 60730}
!3883 = !{i64 60744}
!3884 = !{i64 60749}
!3885 = !{i64 60753}
!3886 = !{i64 60759}
!3887 = !{i64 60762}
!3888 = !{i64 60765}
!3889 = !{i64 60767}
!3890 = !{i64 60804}
!3891 = !{i64 60809}
!3892 = !{i64 60812}
!3893 = !{i64 60815}
!3894 = !{i64 60818}
!3895 = !{i64 60820}
!3896 = !{i64 60870}
!3897 = !{i64 60833}
!3898 = !{i64 60842}
!3899 = !{i64 60888}
!3900 = !{i64 60901}
!3901 = !{i64 60904}
!3902 = !{i64 60912}
!3903 = !{i64 60934}
!3904 = !{i64 60959}
!3905 = !{i64 60964}
!3906 = !{i64 60968}
!3907 = !{i64 60969}
!3908 = !{i64 60985}
!3909 = !{i64 61007}
!3910 = !{i64 61012}
!3911 = !{i64 61023}
!3912 = !{i64 61032}
!3913 = !{i64 61041}
!3914 = !{i64 61043}
!3915 = !{i64 61049}
!3916 = !{i64 61067}
!3917 = !{i64 61068}
!3918 = !{i64 61084}
!3919 = !{i64 61106}
!3920 = !{i64 61111}
!3921 = !{i64 61122}
!3922 = !{i64 61131}
!3923 = !{i64 61140}
!3924 = !{i64 61142}
!3925 = !{i64 61148}
!3926 = !{i64 61172}
!3927 = !{i64 61177}
!3928 = !{i64 61181}
!3929 = !{i64 61205}
!3930 = !{i64 61211}
!3931 = !{i64 61224}
!3932 = !{i64 61247}
!3933 = !{i64 61264}
!3934 = !{i64 61269}
!3935 = !{i64 61282}
!3936 = !{i64 61305}
!3937 = !{i64 61337}
!3938 = !{i64 61346}
!3939 = !{i64 61360}
!3940 = !{i64 61365}
!3941 = !{i64 61369}
!3942 = !{i64 61375}
!3943 = !{i64 61378}
!3944 = !{i64 61381}
!3945 = !{i64 61383}
!3946 = !{i64 61417}
!3947 = !{i64 61457}
!3948 = !{i64 61459}
!3949 = !{i64 61460}
!3950 = !{i64 61476}
!3951 = !{i64 61498}
!3952 = !{i64 61503}
!3953 = !{i64 61514}
!3954 = !{i64 61523}
!3955 = !{i64 61532}
!3956 = !{i64 61534}
!3957 = !{i64 61540}
!3958 = !{i64 61558}
!3959 = !{i64 61588}
!3960 = !{i64 61604}
!3961 = !{i64 61609}
!3962 = !{i64 61618}
!3963 = !{i64 61643}
!3964 = !{i64 61649}
!3965 = !{i64 61673}
!3966 = !{i64 61679}
!3967 = !{i64 61697}
!3968 = !{i64 61744}
!3969 = !{i64 61762}
!3970 = !{i64 61789}
!3971 = !{i64 61797}
!3972 = !{i64 61801}
!3973 = !{i64 61804}
!3974 = !{i64 61826}
!3975 = !{i64 61853}
!3976 = !{i64 61890}
!3977 = !{i64 61905}
!3978 = !{i64 61916}
!3979 = !{i64 61927}
!3980 = !{i64 61931}
!3981 = !{i64 61939}
!3982 = !{i64 61943}
!3983 = !{i64 61952}
!3984 = !{i64 61967}
!3985 = !{i64 61988}
!3986 = !{i64 62000}
!3987 = !{i64 62010}
!3988 = !{i64 62028}
!3989 = !{i64 62046}
!3990 = !{i64 62072}
!3991 = !{i64 62080}
!3992 = !{i64 62108}
!3993 = !{i64 62121}
!3994 = !{i64 62124}
!3995 = !{i64 62127}
!3996 = !{i64 62164}
!3997 = !{i64 62173}
!3998 = !{i64 62183}
!3999 = !{i64 62187}
!4000 = !{i64 62216}
!4001 = !{i64 62253}
!4002 = !{i64 62273}
!4003 = !{i64 62277}
!4004 = !{i64 62304}
!4005 = !{i64 62313}
!4006 = !{i64 62321}
!4007 = !{i64 62345}
!4008 = !{i64 62351}
!4009 = !{i64 62352}
!4010 = !{i64 62368}
!4011 = !{i64 62390}
!4012 = !{i64 62395}
!4013 = !{i64 62406}
!4014 = !{i64 62415}
!4015 = !{i64 62424}
!4016 = !{i64 62426}
!4017 = !{i64 62432}
!4018 = !{i64 62459}
!4019 = !{i64 62465}
!4020 = !{i64 62492}
!4021 = !{i64 62498}
!4022 = !{i64 62525}
!4023 = !{i64 62531}
!4024 = !{i64 62558}
!4025 = !{i64 62564}
!4026 = !{i64 62588}
!4027 = !{i64 62593}
!4028 = !{i64 62597}
!4029 = !{i64 62624}
!4030 = !{i64 62630}
!4031 = !{i64 62657}
!4032 = !{i64 62663}
!4033 = !{i64 62696}
!4034 = !{i64 62717}
!4035 = !{i64 62728}
!4036 = !{i64 62746}
!4037 = !{i64 62751}
!4038 = !{i64 62752}
!4039 = !{i64 62768}
!4040 = !{i64 62790}
!4041 = !{i64 62795}
!4042 = !{i64 62806}
!4043 = !{i64 62815}
!4044 = !{i64 62824}
!4045 = !{i64 62826}
!4046 = !{i64 62832}
!4047 = !{i64 62833}
!4048 = !{i64 62849}
!4049 = !{i64 62871}
!4050 = !{i64 62876}
!4051 = !{i64 62887}
!4052 = !{i64 62896}
!4053 = !{i64 62905}
!4054 = !{i64 62907}
!4055 = !{i64 62913}
!4056 = !{i64 62914}
!4057 = !{i64 62930}
!4058 = !{i64 62952}
!4059 = !{i64 62957}
!4060 = !{i64 62968}
!4061 = !{i64 62977}
!4062 = !{i64 62986}
!4063 = !{i64 62988}
!4064 = !{i64 62994}
!4065 = !{i64 63021}
!4066 = !{i64 63027}
!4067 = !{i64 63052}
!4068 = !{i64 63057}
!4069 = !{i64 63089}
!4070 = !{i64 63122}
!4071 = !{i64 63143}
!4072 = !{i64 63154}
!4073 = !{i64 63172}
!4074 = !{i64 63177}
!4075 = !{i64 63206}
!4076 = !{i64 63221}
!4077 = !{i64 63243}
!4078 = !{i64 63253}
!4079 = !{i64 63254}
!4080 = !{i64 63274}
!4081 = !{i64 63307}
!4082 = !{i64 63330}
!4083 = !{i64 63335}
!4084 = !{i64 63353}
!4085 = !{i64 63363}
!4086 = !{i64 63372}
!4087 = !{i64 63374}
!4088 = !{i64 63380}
!4089 = !{i64 63407}
!4090 = !{i64 63413}
!4091 = !{i64 63440}
!4092 = !{i64 63446}
!4093 = !{i64 63464}
!4094 = !{i64 63465}
!4095 = !{i64 63481}
!4096 = !{i64 63503}
!4097 = !{i64 63508}
!4098 = !{i64 63519}
!4099 = !{i64 63528}
!4100 = !{i64 63537}
!4101 = !{i64 63539}
!4102 = !{i64 63545}
!4103 = !{i64 63576}
!4104 = !{i64 63589}
!4105 = !{i64 63629}
!4106 = !{i64 63636}
!4107 = !{i64 63663}
!4108 = !{i64 63669}
!4109 = !{i64 63693}
!4110 = !{i64 63700}
!4111 = !{i64 63724}
!4112 = !{i64 63730}
!4113 = !{i64 63755}
!4114 = !{i64 63761}
!4115 = !{i64 63779}
!4116 = !{i64 63780}
!4117 = !{i64 63796}
!4118 = !{i64 63815}
!4119 = !{i64 63829}
!4120 = !{i64 63834}
!4121 = !{i64 63842}
!4122 = !{i64 63851}
!4123 = !{i64 63853}
!4124 = !{i64 63859}
!4125 = !{i64 63883}
!4126 = !{i64 63897}
!4127 = !{i64 63934}
!4128 = !{i64 63964}
!4129 = !{i64 63982}
!4130 = !{i64 63987}
!4131 = !{i64 64008}
!4132 = !{i64 64034}
!4133 = !{i64 64061}
!4134 = !{i64 64070}
!4135 = !{i64 64082}
!4136 = !{i64 64111}
!4137 = !{i64 64148}
!4138 = !{i64 64163}
!4139 = !{i64 64174}
!4140 = !{i64 64199}
!4141 = !{i64 64217}
!4142 = !{i64 64222}
!4143 = !{i64 64239}
!4144 = !{i64 64248}
!4145 = !{i64 64263}
!4146 = !{i64 64281}
!4147 = !{i64 64286}
!4148 = !{i64 64303}
!4149 = !{i64 64326}
!4150 = !{i64 64330}
!4151 = !{i64 64334}
!4152 = !{i64 64348}
!4153 = !{i64 64364}
!4154 = !{i64 64378}
!4155 = !{i64 64386}
!4156 = !{i64 64398}
!4157 = !{i64 64408}
!4158 = !{i64 64417}
!4159 = !{i64 64426}
!4160 = !{i64 64428}
!4161 = !{i64 64438}
!4162 = !{i64 64440}
!4163 = !{i64 64456}
!4164 = !{i64 64478}
!4165 = !{i64 64483}
!4166 = !{i64 64499}
!4167 = !{i64 64504}
!4168 = !{i64 64515}
!4169 = !{i64 64524}
!4170 = !{i64 64533}
!4171 = !{i64 64535}
!4172 = !{i64 64541}
!4173 = !{i64 64559}
!4174 = !{i64 64583}
!4175 = !{i64 64589}
!4176 = !{i64 64613}
!4177 = !{i64 64619}
!4178 = !{i64 64640}
!4179 = !{i64 64658}
!4180 = !{i64 64663}
!4181 = !{i64 64690}
!4182 = !{i64 64696}
!4183 = !{i64 64713}
!4184 = !{i64 64718}
!4185 = !{i64 64755}
!4186 = !{i64 64767}
!4187 = !{i64 64773}
!4188 = !{i64 64790}
!4189 = !{i64 64795}
!4190 = !{i64 64832}
!4191 = !{i64 64844}
!4192 = !{i64 64850}
!4193 = !{i64 64867}
!4194 = !{i64 64872}
!4195 = !{i64 64909}
!4196 = !{i64 64921}
!4197 = !{i64 64927}
!4198 = !{i64 64944}
!4199 = !{i64 64949}
!4200 = !{i64 64986}
!4201 = !{i64 64998}
!4202 = !{i64 65004}
!4203 = !{i64 65021}
!4204 = !{i64 65026}
!4205 = !{i64 65063}
!4206 = !{i64 65075}
!4207 = !{i64 65081}
!4208 = !{i64 65098}
!4209 = !{i64 65103}
!4210 = !{i64 65140}
!4211 = !{i64 65152}
!4212 = !{i64 65158}
!4213 = !{i64 65185}
!4214 = !{i64 65191}
!4215 = !{i64 65218}
!4216 = !{i64 65224}
!4217 = !{i64 65241}
!4218 = !{i64 65246}
!4219 = !{i64 65283}
!4220 = !{i64 65295}
!4221 = !{i64 65301}
!4222 = !{i64 65302}
!4223 = !{i64 65330}
!4224 = !{i64 65363}
!4225 = !{i64 65393}
!4226 = !{i64 65418}
!4227 = !{i64 65427}
!4228 = !{i64 65429}
!4229 = !{i64 65435}
!4230 = !{i64 65456}
!4231 = !{i64 65482}
!4232 = !{i64 65497}
!4233 = !{i64 65502}
!4234 = !{i64 65506}
!4235 = !{i64 65514}
!4236 = !{i64 65552}
!4237 = !{i64 65582}
!4238 = !{i64 65592}
!4239 = !{i64 65622}
!4240 = !{i64 65637}
!4241 = !{i64 65658}
!4242 = !{i64 65670}
!4243 = !{i64 65685}
!4244 = !{i64 65696}
!4245 = !{i64 65707}
!4246 = !{i64 65739}
!4247 = !{i64 65747}
!4248 = !{i64 65749}
!4249 = !{i64 65758}
!4250 = !{i64 65766}
!4251 = !{i64 65789}
!4252 = !{i64 65796}
!4253 = !{i64 65813}
!4254 = !{i64 65818}
!4255 = !{i64 65855}
!4256 = !{i64 65867}
!4257 = !{i64 65873}
!4258 = !{i64 65890}
!4259 = !{i64 65895}
!4260 = !{i64 65932}
!4261 = !{i64 65944}
!4262 = !{i64 65950}
!4263 = !{i64 65974}
!4264 = !{i64 65979}
!4265 = !{i64 65983}
!4266 = !{i64 66010}
!4267 = !{i64 66016}
!4268 = !{i64 66054}
!4269 = !{i64 66079}
!4270 = !{i64 66090}
!4271 = !{i64 66107}
!4272 = !{i64 66112}
!4273 = !{i64 66149}
!4274 = !{i64 66161}
!4275 = !{i64 66167}
!4276 = !{i64 66191}
!4277 = !{i64 66203}
!4278 = !{i64 66210}
!4279 = !{i64 66234}
!4280 = !{i64 66240}
!4281 = !{i64 66264}
!4282 = !{i64 66270}
!4283 = !{i64 66306}
!4284 = !{i64 66313}
!4285 = !{i64 66348}
!4286 = !{i64 66355}
!4287 = !{i64 66383}
!4288 = !{i64 66388}
!4289 = !{i64 66390}
!4290 = !{i64 66407}
!4291 = !{i64 66415}
!4292 = !{i64 66437}
!4293 = !{i64 66452}
!4294 = !{i64 66457}
!4295 = !{i64 66467}
!4296 = !{i64 66473}
!4297 = !{i64 66475}
!4298 = !{i64 66484}
!4299 = !{i64 66496}
!4300 = !{i64 66511}
!4301 = !{i64 66516}
!4302 = !{i64 66534}
!4303 = !{i64 66539}
!4304 = !{i64 66542}
!4305 = !{i64 66556}
!4306 = !{i64 66561}
!4307 = !{i64 66565}
!4308 = !{i64 66574}
!4309 = !{i64 66579}
!4310 = !{i64 66583}
!4311 = !{i64 66592}
!4312 = !{i64 66597}
!4313 = !{i64 66607}
!4314 = !{i64 66616}
!4315 = !{i64 66618}
!4316 = !{i64 66628}
!4317 = !{i64 66630}
!4318 = !{i64 66646}
!4319 = !{i64 66675}
!4320 = !{i64 66680}
!4321 = !{i64 66688}
!4322 = !{i64 66697}
!4323 = !{i64 66699}
!4324 = !{i64 66705}
!4325 = !{i64 66734}
!4326 = !{i64 66739}
!4327 = !{i64 66749}
!4328 = !{i64 66754}
!4329 = !{i64 66760}
!4330 = !{i64 66766}
!4331 = !{i64 66775}
!4332 = !{i64 66776}
!4333 = !{i64 66796}
!4334 = !{i64 66801}
!4335 = !{i64 66838}
!4336 = !{i64 66844}
!4337 = !{i64 66852}
!4338 = !{i64 66900}
!4339 = !{i64 66906}
!4340 = !{i64 66925}
!4341 = !{i64 66943}
!4342 = !{i64 66944}
!4343 = !{i64 66968}
!4344 = !{i64 66973}
!4345 = !{i64 67017}
!4346 = !{i64 67022}
!4347 = !{i64 67025}
!4348 = !{i64 67026}
!4349 = !{i64 67046}
!4350 = !{i64 67068}
!4351 = !{i64 67072}
!4352 = !{i64 67079}
!4353 = !{i64 67082}
!4354 = !{i64 67100}
!4355 = !{i64 67105}
!4356 = !{i64 67113}
!4357 = !{i64 67122}
!4358 = !{i64 67124}
!4359 = !{i64 67130}
!4360 = !{i64 67152}
!4361 = !{i64 67169}
!4362 = !{i64 67174}
!4363 = !{i64 67211}
!4364 = !{i64 67223}
!4365 = !{i64 67229}
!4366 = !{i64 67253}
!4367 = !{i64 67259}
!4368 = !{i64 67283}
!4369 = !{i64 67289}
!4370 = !{i64 67313}
!4371 = !{i64 67319}
!4372 = !{i64 67343}
!4373 = !{i64 67349}
!4374 = !{i64 67366}
!4375 = !{i64 67371}
!4376 = !{i64 67408}
!4377 = !{i64 67420}
!4378 = !{i64 67426}
!4379 = !{i64 67443}
!4380 = !{i64 67448}
!4381 = !{i64 67485}
!4382 = !{i64 67497}
!4383 = !{i64 67503}
!4384 = !{i64 67527}
!4385 = !{i64 67533}
!4386 = !{i64 67550}
!4387 = !{i64 67555}
!4388 = !{i64 67598}
!4389 = !{i64 67605}
!4390 = !{i64 67606}
!4391 = !{i64 67649}
!4392 = !{i64 67653}
!4393 = !{i64 67628}
!4394 = !{i64 67640}
!4395 = !{i64 67658}
!4396 = !{i64 67691}
!4397 = !{i64 67696}
!4398 = !{i64 67699}
!4399 = !{i64 67707}
!4400 = !{i64 67731}
!4401 = !{i64 67737}
!4402 = !{i64 67755}
!4403 = !{i64 67772}
!4404 = !{i64 67777}
!4405 = !{i64 67814}
!4406 = !{i64 67826}
!4407 = !{i64 67832}
!4408 = !{i64 67856}
!4409 = !{i64 67862}
!4410 = !{i64 67887}
!4411 = !{i64 67894}
!4412 = !{i64 67912}
!4413 = !{i64 67921}
!4414 = !{i64 67945}
!4415 = !{i64 67951}
!4416 = !{i64 67975}
!4417 = !{i64 67981}
!4418 = !{i64 68016}
!4419 = !{i64 68032}
!4420 = !{i64 68037}
!4421 = !{i64 68072}
!4422 = !{i64 68079}
!4423 = !{i64 68112}
!4424 = !{i64 68123}
!4425 = !{i64 68135}
!4426 = !{i64 68140}
!4427 = !{i64 68153}
!4428 = !{i64 68177}
!4429 = !{i64 68185}
!4430 = !{i64 68191}
!4431 = !{i64 68208}
!4432 = !{i64 68219}
!4433 = !{i64 68225}
!4434 = !{i64 68230}
!4435 = !{i64 68269}
!4436 = !{i64 68284}
!4437 = !{i64 68299}
!4438 = !{i64 68320}
!4439 = !{i64 68333}
!4440 = !{i64 68352}
!4441 = !{i64 68376}
!4442 = !{i64 68382}
!4443 = !{i64 68406}
!4444 = !{i64 68412}
!4445 = !{i64 68445}
!4446 = !{i64 68460}
!4447 = !{i64 68481}
!4448 = !{i64 68491}
!4449 = !{i64 68515}
!4450 = !{i64 68521}
!4451 = !{i64 68536}
!4452 = !{i64 68554}
!4453 = !{i64 68578}
!4454 = !{i64 68584}
!4455 = !{i64 68602}
!4456 = !{i64 68622}
!4457 = !{i64 68623}
!4458 = !{i64 68639}
!4459 = !{i64 68664}
!4460 = !{i64 68704}
!4461 = !{i64 68722}
!4462 = !{i64 68727}
!4463 = !{i64 68734}
!4464 = !{i64 68743}
!4465 = !{i64 68745}
!4466 = !{i64 68751}
!4467 = !{i64 68769}
!4468 = !{i64 68812}
!4469 = !{i64 68822}
!4470 = !{i64 68825}
!4471 = !{i64 68828}
!4472 = !{i64 68830}
!4473 = !{i64 68842}
!4474 = !{i64 68846}
!4475 = !{i64 68848}
!4476 = !{i64 68853}
!4477 = !{i64 68862}
!4478 = !{i64 68869}
!4479 = !{i64 68876}
!4480 = !{i64 68894}
!4481 = !{i64 68895}
!4482 = !{i64 68996}
!4483 = !{i64 69000}
!4484 = !{i64 68941}
!4485 = !{i64 68956}
!4486 = !{i64 68977}
!4487 = !{i64 68982}
!4488 = !{i64 68987}
!4489 = !{i64 69011}
!4490 = !{i64 69040}
!4491 = !{i64 69058}
!4492 = !{i64 69064}
!4493 = !{i64 69065}
!4494 = !{i64 69077}
!4495 = !{i64 69081}
!4496 = !{i64 69103}
!4497 = !{i64 69108}
!4498 = !{i64 69121}
!4499 = !{i64 69126}
!4500 = !{i64 69134}
!4501 = !{i64 69143}
!4502 = !{i64 69145}
!4503 = !{i64 69151}
!4504 = !{i64 69202}
!4505 = !{i64 69208}
!4506 = !{i64 69226}
!4507 = !{i64 69244}
!4508 = !{i64 69277}
!4509 = !{i64 69309}
!4510 = !{i64 69346}
!4511 = !{i64 69361}
!4512 = !{i64 69372}
!4513 = !{i64 69386}
!4514 = !{i64 69426}
!4515 = !{i64 69439}
!4516 = !{i64 69457}
!4517 = !{i64 69474}
!4518 = !{i64 69485}
!4519 = !{i64 69490}
!4520 = !{i64 69497}
!4521 = !{i64 69502}
!4522 = !{i64 69545}
!4523 = !{i64 69551}
!4524 = !{i64 69552}
!4525 = !{i64 69565}
!4526 = !{i64 69569}
!4527 = !{i64 69656}
!4528 = !{i64 69661}
!4529 = !{i64 69663}
!4530 = !{i64 69594}
!4531 = !{i64 69609}
!4532 = !{i64 69620}
!4533 = !{i64 69632}
!4534 = !{i64 69637}
!4535 = !{i64 69674}
!4536 = !{i64 69709}
!4537 = !{i64 69714}
!4538 = !{i64 69718}
!4539 = !{i64 69739}
!4540 = !{i64 69747}
!4541 = !{i64 69755}
!4542 = !{i64 69773}
!4543 = !{i64 69794}
!4544 = !{i64 69828}
!4545 = !{i64 69843}
!4546 = !{i64 69854}
!4547 = !{i64 69865}
!4548 = !{i64 69894}
!4549 = !{i64 69909}
!4550 = !{i64 69914}
!4551 = !{i64 69925}
!4552 = !{i64 69943}
!4553 = !{i64 69944}
!4554 = !{i64 69968}
!4555 = !{i64 69972}
!4556 = !{i64 69975}
!4557 = !{i64 69987}
!4558 = !{i64 69996}
!4559 = !{i64 70004}
!4560 = !{i64 70015}
!4561 = !{i64 70020}
!4562 = !{i64 70022}
!4563 = !{i64 70032}
!4564 = !{i64 70039}
!4565 = !{i64 70042}
!4566 = !{i64 70050}
!4567 = !{i64 70058}
!4568 = !{i64 70066}
!4569 = !{i64 70078}
!4570 = !{i64 70088}
!4571 = !{i64 70110}
!4572 = !{i64 70345}
!4573 = !{i64 70367}
!4574 = !{i64 70383}
!4575 = !{i64 70403}
