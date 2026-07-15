@data_1000 = global i64 0, align 8

declare ptr @__remill_fetch_and_add_64(ptr, i64, ptr)
declare ptr @__remill_compare_exchange_memory_64(ptr, i64, ptr, i64)
declare ptr @__remill_barrier_load_load(ptr)
declare ptr @__remill_barrier_store_store(ptr)
declare ptr @__remill_barrier_store_load(ptr)
declare i64 @__remill_read_memory_64(ptr, i64)
declare ptr @__remill_write_memory_64(ptr, i64, i64)
declare ptr @__remill_read_memory_ptr(ptr, i64)

; CHECK-LABEL: define ptr @__remill_fetch_and_add_64
; CHECK: atomicrmw add ptr {{.*}}, i64 {{.*}} seq_cst
; CHECK-LABEL: define ptr @__remill_compare_exchange_memory_64
; CHECK: cmpxchg ptr {{.*}}, i64 {{.*}}, i64 {{.*}} seq_cst seq_cst
; CHECK-LABEL: define ptr @__remill_barrier_load_load
; CHECK: fence acquire
; CHECK-LABEL: define ptr @__remill_barrier_store_store
; CHECK: fence release
; CHECK-LABEL: define ptr @__remill_barrier_store_load
; CHECK: fence seq_cst
; CHECK-LABEL: define i64 @__remill_read_memory_64
; CHECK: call ptr @__translate_guest_pointer(i64 {{.*}}, i1 false)
; CHECK: load i64, ptr {{.*}}, align 1
; CHECK-LABEL: define ptr @__remill_write_memory_64
; CHECK: store i64 {{.*}}, ptr {{.*}}, align 1
; CHECK-LABEL: define ptr @__remill_read_memory_ptr
; CHECK: load ptr, ptr {{.*}}, align 1
