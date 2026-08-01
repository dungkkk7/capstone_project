; A freeze around a dispatcher PHI is an identity when every entry and latch
; value is already defined. The exact deflattening proof may look through it.
define i32 @defined_frozen_dispatcher(i1 noundef %choose) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 17, %entry ], [ %next, %latch ]
  %defined.state = freeze i32 %state
  switch i32 %defined.state, label %trap [
    i32 17, label %first
    i32 91, label %second
    i32 203, label %done
  ]

first:
  %choice = select i1 %choose, i32 91, i32 203
  br label %latch

second:
  br label %latch

latch:
  %next = phi i32 [ %choice, %first ], [ 203, %second ]
  br label %dispatch

done:
  ret i32 42

trap:
  ret i32 -1
}

; CHECK-LABEL: define i32 @defined_frozen_dispatcher(
; CHECK-NOT: switch i32
; CHECK: ret i32 42

; freeze(poison) is observable nondeterminism, not an identity. A decoded
; two-state select may still bypass the dispatcher when its condition is
; frozen first: choosing one of those two states is a valid refinement of the
; arbitrary i32 chosen by the original freeze, and unlike br poison it does
; not introduce undefined behavior.
@poison_path_sink = global i32 0

define i32 @poison_frozen_dispatcher(i1 %maybe_poison) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 17, %entry ], [ %next, %latch ]
  %defined.state = freeze i32 %state
  switch i32 %defined.state, label %trap [
    i32 17, label %first
    i32 91, label %second
    i32 203, label %done
  ]

first:
  br label %choice.prepare

second:
  store volatile i32 1, ptr @poison_path_sink
  br label %latch

latch:
  %next = phi i32 [ %choice, %choice.prepare ], [ 203, %second ]
  br label %dispatch

choice.prepare:
  %choice = select i1 %maybe_poison, i32 91, i32 203
  br label %latch

done:
  ret i32 42

trap:
  ret i32 -1
}

; CHECK-LABEL: define i32 @poison_frozen_dispatcher(
; CHECK-NOT: switch i32
; CHECK: %deobf.frozen.condition = freeze i1 %maybe_poison
; CHECK-NEXT: br i1 %deobf.frozen.condition

; A split dispatcher may compute payload in a child switch block. Even when a
; frozen edge has a defined constant state, bypassing that child would make the
; payload cease to dominate its case. Direct root cases can still be rewired.
@payload_sink = global i32 0
@payload_source = global i32 7

define i32 @frozen_split_dispatcher_payload(i32 noundef %initial,
                                            i32 noundef %x) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ %initial, %entry ], [ %next, %latch ]
  %defined.state = freeze i32 %state
  switch i32 %defined.state, label %child.dispatch [
    i32 11, label %first
    i32 33, label %done
  ]

child.dispatch:
  %payload = load volatile i32, ptr @payload_source
  switch i32 %defined.state, label %trap [
    i32 22, label %second
  ]

first:
  br label %latch

second:
  %used.payload = add i32 %payload, %x
  store volatile i32 %used.payload, ptr @payload_sink
  br label %latch

latch:
  %next = phi i32 [ 22, %first ], [ 33, %second ]
  br label %dispatch

done:
  ret i32 42

trap:
  ret i32 -1
}

; CHECK-LABEL: define i32 @frozen_split_dispatcher_payload(
; CHECK: switch i32 %state, label %child.dispatch
; CHECK: i32 11, label %latch
; CHECK: i32 33, label %common.ret
; CHECK: child.dispatch:
; CHECK: %payload = load volatile i32, ptr @payload_source
; CHECK: %cond = icmp eq i32 %state, 22
; CHECK: second:
; CHECK: %used.payload = add i32 %payload, %x
; CHECK: %next = phi i32 [ 33, %second ], [ 22, %dispatch ]

; A decoded select may send one arm through a payload-bearing child dispatcher
; and the other directly to a root case.  Clone the child payload only onto the
; arm which bypasses it, then repair its use in the selected application case.
define i32 @frozen_split_select_payload(i1 %choose, i32 noundef %x) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 11, %entry ], [ %next, %latch ]
  %defined.state = freeze i32 %state
  switch i32 %defined.state, label %child.dispatch [
    i32 11, label %first
    i32 33, label %done
    i32 100, label %trap.100
  ]

child.dispatch:
  %payload = load volatile i32, ptr @payload_source
  switch i32 %defined.state, label %trap [
    i32 22, label %second
  ]

first:
  %choice = select i1 %choose, i32 22, i32 33
  br label %latch

second:
  %used.payload = add i32 %payload, %x
  store volatile i32 %used.payload, ptr @payload_sink
  br label %latch

latch:
  %next = phi i32 [ %choice, %first ], [ 33, %second ]
  br label %dispatch

done:
  ret i32 42

trap:
  ret i32 -1

trap.100:
  ret i32 -100
}

; CHECK-LABEL: define i32 @frozen_split_select_payload(
; CHECK-NOT: switch i32
; CHECK: [[FROZEN:%.*]] = freeze i1 %choose
; CHECK: br i1 [[FROZEN]], label %[[TRUE:[^,]+]], label %done
; CHECK: [[TRUE]]:
; CHECK: load volatile i32, ptr @payload_source
; CHECK: store volatile i32
; CHECK: br label %done
; CHECK: done:
; CHECK: ret i32 42

; A state owned by a child switch may deliberately re-enter the latch.  That
; edge executes the child payload, installs another state at the latch, then
; executes the dispatcher path again.  Compose the exact extra iteration,
; including both volatile payload loads, before removing the dispatcher.
define i32 @frozen_child_latch_state(i32 noundef %x) {
entry:
  br label %dispatch

dispatch:
  %state = phi i32 [ 11, %entry ], [ %next, %latch ]
  %defined.state = freeze i32 %state
  switch i32 %defined.state, label %child.dispatch [
    i32 11, label %first
    i32 33, label %done
    i32 100, label %trap.100
  ]

child.dispatch:
  %payload = load volatile i32, ptr @payload_source
  switch i32 %defined.state, label %trap [
    i32 22, label %second
    i32 44, label %latch
  ]

first:
  br label %latch

second:
  %used.payload = add i32 %payload, %x
  store volatile i32 %used.payload, ptr @payload_sink
  br label %latch

latch:
  %next = phi i32 [ 44, %first ], [ 22, %child.dispatch ],
                          [ 33, %second ]
  br label %dispatch

done:
  ret i32 42

trap:
  ret i32 -1

trap.100:
  ret i32 -100
}

; CHECK-LABEL: define i32 @frozen_child_latch_state(
; CHECK-NOT: switch i32
; CHECK: load volatile i32, ptr @payload_source
; CHECK: load volatile i32, ptr @payload_source
; CHECK: store volatile i32
; CHECK: ret i32 42

; A child dispatcher payload may also be a loop-carried definition.  Every
; rewritten transition must execute a fresh clone for the new visit while uses
; on later latch edges select the clone which actually reached that case.
define i32 @frozen_split_loop_carried_payload(i32 noundef %x) {
entry:
  br label %dispatch

latch:
  %next.state = phi i32 [ 2, %first ], [ 3, %second ], [ 4, %third ]
  %next.carry = phi i32 [ %payload, %first ], [ %payload, %second ],
                          [ %payload, %third ]
  br label %dispatch

dispatch:
  %state = phi i32 [ 1, %entry ], [ %next.state, %latch ]
  %carry = phi i32 [ %x, %entry ], [ %next.carry, %latch ]
  %defined.state = freeze i32 %state
  switch i32 %defined.state, label %child.dispatch [
    i32 4, label %done
    i32 100, label %trap.100
    i32 101, label %trap.101
  ]

child.dispatch:
  %payload = add i32 %carry, 1
  switch i32 %defined.state, label %trap [
    i32 1, label %first
    i32 2, label %second
    i32 3, label %third
  ]

first:
  br label %latch

second:
  br label %latch

third:
  br label %latch

done:
  ret i32 %carry

trap:
  ret i32 -1

trap.100:
  ret i32 -100

trap.101:
  ret i32 -101
}

; CHECK-LABEL: define i32 @frozen_split_loop_carried_payload(
; CHECK-NOT: poison
; CHECK-NOT: switch i32
; CHECK: ret i32

define i32 @main() {
entry:
  %result = call i32 @frozen_split_loop_carried_payload(i32 39)
  %internal = call i32 @frozen_child_latch_state(i32 5)
  %loop.ok = icmp eq i32 %result, 42
  %internal.ok = icmp eq i32 %internal, 42
  %ok = and i1 %loop.ok, %internal.ok
  %failed = xor i1 %ok, true
  %status = zext i1 %failed to i32
  ret i32 %status
}
