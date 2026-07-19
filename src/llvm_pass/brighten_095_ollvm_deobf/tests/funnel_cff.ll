; RUN: lli-21 %s
; RUN: opt-21 -load-pass-plugin %plugin -ollvm-deobf-report=%t.json -passes=brighten-ollvm-deobf-pass,simplifycfg,adce,verify -S %s -o %t.ll
; RUN: FileCheck-21 %s < %t.ll
; RUN: lli-21 %t.ll
; RUN: python3 -c "import json; d=json.load(open('%t.json')); assert d['metrics']['dispatchers_recovered']==1; assert d['metrics']['dispatchers_unresolved']==0"

@frame_storage_backing.funnel = internal global [256 x i8] zeroinitializer

define i32 @funnel(i1 %cond) {
; CHECK-LABEL: @funnel
; CHECK-NOT: switch
entry:
  %direct = getelementptr i8, ptr @frame_storage_backing.funnel, i64 20
  store i32 10, ptr %direct, align 4
  %anchor = getelementptr i8, ptr @frame_storage_backing.funnel, i64 100
  %anchor.int = ptrtoint ptr %anchor to i64
  %plus = add i64 %anchor.int, -80
  %idx = sub i64 %plus, %anchor.int
  %equivalent = getelementptr i8, ptr %anchor, i64 %idx
  %initial = load i32, ptr %equivalent, align 4
  br label %outer

sink:
  %next = phi i32 [ %choice, %case10 ], [ 20, %header ]
  store i32 %next, ptr getelementptr (i8, ptr @frame_storage_backing.funnel, i64 20), align 4
  br label %outer

outer:
  %state = phi i32 [ %initial, %entry ], [ %next, %sink ]
  store i32 %state, ptr getelementptr (i8, ptr @frame_storage_backing.funnel, i64 24), align 4
  br label %header

header:
  switch i32 %state, label %header [
    i32 10, label %case10
    i32 20, label %case20
    i32 30, label %case30
    i32 40, label %sink
  ]

case10:
  %choice = select i1 %cond, i32 20, i32 30
  br label %sink
case20:
  ret i32 2
case30:
  ret i32 3
}

define i32 @main() {
  %a = call i32 @funnel(i1 true)
  %b = call i32 @funnel(i1 false)
  %a.ok = icmp eq i32 %a, 2
  %b.ok = icmp eq i32 %b, 3
  %ok = and i1 %a.ok, %b.ok
  %status = select i1 %ok, i32 0, i32 1
  ret i32 %status
}
