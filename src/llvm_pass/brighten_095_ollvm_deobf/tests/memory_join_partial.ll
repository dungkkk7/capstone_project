; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); p=d['proofs']; assert d['metrics']['dispatchers_recovered']==0; assert d['metrics']['dispatchers_unresolved']==1; assert sum(x['kind']=='cff_transition' and x['result']=='proved' for x in p)==6; assert sum(x['kind']=='cff_transition' and x['proof_engine']=='memory_join_default_entry_clone' for x in p)==1; e=[x for x in p if x['kind']=='cff_transition' and x['proof_engine']=='memory_join_exact_dispatcher_clone']; assert len(e)==1 and e[0]['origin']=='case30' and e[0]['proof_query_hash'] and e[0]['dependencies']==['exact_header_plumbing_clone','exhaustive_original_switch_cases','exact_default_entry_clone']; assert not [x for x in p if x['kind']=='cff_transition' and x['origin']=='case70']; assert any(x['origin']=='case70' and x['result']=='barrier' and x['residual_reason']=='unknown_memory_write_or_alias_barrier' for x in p); assert 'proved_direct_transitions=6' in next(x['residual_reason'] for x in p if x['kind']=='cff_candidate')"

@frame_storage_backing.partial = internal global [64 x i8] zeroinitializer
@observable_dispatch_store = internal global i32 0
@detour_effect = internal global i32 0
@default_effect = internal global i32 0
@transition_bias = internal constant i32 26

declare i32 @llvm.fshl.i32(i32, i32, i32)

define i32 @summarize_next(i32 %value) memory(read) {
  %bias = load i32, ptr @transition_bias, align 4
  %next = add i32 %value, %bias
  ret i32 %next
}

define void @unknown_clobber() noinline {
  store i32 70, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  ret void
}

define i32 @partial_memory_join(i32 %dynamic, i1 %cond, i1 %take.default) {
; CHECK-LABEL: @partial_memory_join
entry:
; CHECK: entry:
  store i32 10, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
; CHECK: %encoded.deobf.edge = mul i32 10, 3
; CHECK: store i32 %encoded.deobf.edge, ptr @observable_dispatch_store
; CHECK: br label %case10
  br label %dispatch

dispatch:
; CHECK: dispatch:
; CHECK: switch i32
  %state = phi i32 [ 10, %entry ], [ %reloaded, %join ]
  %encoded = mul i32 %state, 3
  store i32 %encoded, ptr @observable_dispatch_store, align 4
  switch i32 %encoded, label %default [
    i32 30, label %case10
    i32 60, label %case20
    i32 90, label %case30
    i32 120, label %case40
    i32 150, label %case50
    i32 210, label %case70
  ]

case10:
; CHECK: case10:
; CHECK: %current = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4)
; CHECK: %via.entry.state = xor i32 %current, 30
; CHECK: store i32 %via.entry.state, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4)
; CHECK: br i1 %cond, label %case10.deobf.dispatch.edge, label %detour10
  %current = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  %via.entry.state = xor i32 %current, 30
  store i32 %via.entry.state, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  br i1 %cond, label %join, label %detour10

detour10:
; CHECK: detour10:
; CHECK: store i32 1, ptr @detour_effect
; CHECK-NEXT: [[DETOUR_ENCODED:%.*]] = mul i32 %via.entry.state, 3
; CHECK-NEXT: store i32 [[DETOUR_ENCODED]], ptr @observable_dispatch_store
; CHECK: br label %case20
  store i32 1, ptr @detour_effect, align 4
  br label %join

case20:
; CHECK: case20:
; CHECK: store i32 12, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 8)
; CHECK: %aux = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 8)
; CHECK: %rotated = call i32 @llvm.fshl.i32(i32 %aux, i32 %aux, i32 1)
; CHECK: %summarized = call i32 @summarize_next(i32 %rotated)
; CHECK: %next = select i1 %cond, i32 %summarized, i32 40
; CHECK: store i32 %next, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4)
; CHECK: [[CASE20_ENCODED:%.*]] = mul i32 %next, 3
; CHECK-NEXT: store i32 [[CASE20_ENCODED]], ptr @observable_dispatch_store
; CHECK: br i1 %cond, label %case50, label %case40
  store i32 12, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 8), align 4
  br label %compute20

compute20:
  %aux = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 8), align 4
  %rotated = call i32 @llvm.fshl.i32(i32 %aux, i32 %aux, i32 1)
  %summarized = call i32 @summarize_next(i32 %rotated)
  %next = select i1 %cond, i32 %summarized, i32 40
  store i32 %next, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  br label %join

case50:
; CHECK: case50:
; CHECK: %with.default = select i1 %take.default, i32 60, i32 30
; CHECK: br i1 %take.default, label %default.deobf.from.case50, label %case30
  %with.default = select i1 %take.default, i32 60, i32 30
  store i32 %with.default, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  br label %join

case30:
; This state is deliberately non-constant.  It must continue through the
; residual dispatcher instead of being guessed or broadened.
; CHECK: case30:
; CHECK: [[DYNAMIC_ENCODED:%.*]] = mul i32 %dynamic, 3
; CHECK-NEXT: store i32 [[DYNAMIC_ENCODED]], ptr @observable_dispatch_store
; CHECK: switch i32 [[DYNAMIC_ENCODED]], label %default.deobf.from.case30
  store i32 %dynamic, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  br label %join

case70:
; CHECK: case70:
; CHECK: store i32 80, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4)
; CHECK-NEXT: call void @unknown_clobber()
; CHECK-NEXT: br label %join
  store i32 80, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  call void @unknown_clobber()
  br label %join

case40:
; CHECK: case10.deobf.dispatch.edge:
; CHECK: [[SPLIT_ENCODED:%.*]] = mul i32 %via.entry.state, 3
; CHECK-NEXT: store i32 [[SPLIT_ENCODED]], ptr @observable_dispatch_store
; CHECK: br label %case20
  ret i32 7

join:
  %reloaded = load i32, ptr getelementptr (i8, ptr @frame_storage_backing.partial, i64 4), align 4
  br label %dispatch

default:
; CHECK: default.deobf.from.case50:
; CHECK: [[SEEN50:%.*]] = load i32, ptr @observable_dispatch_store
; CHECK: store i32 [[SEEN50]], ptr @default_effect
; CHECK: br label %default.exit
  %seen = load i32, ptr @observable_dispatch_store, align 4
  store i32 %seen, ptr @default_effect, align 4
  br label %default.exit

default.exit:
  ret i32 99
}

define i32 @main() {
  %a = call i32 @partial_memory_join(i32 40, i1 true, i1 true)
  %b = call i32 @partial_memory_join(i32 40, i1 false, i1 false)
  %c = call i32 @partial_memory_join(i32 40, i1 true, i1 false)
  %a.ok = icmp eq i32 %a, 99
  %b.ok = icmp eq i32 %b, 7
  %c.ok = icmp eq i32 %c, 7
  %ab.ok = and i1 %a.ok, %b.ok
  %ok = and i1 %ab.ok, %c.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
