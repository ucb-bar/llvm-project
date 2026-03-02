; RUN: llc -mtriple=riscv32 -mattr=+v,+xsmtvdot -verify-machineinstrs < %s | FileCheck %s

; NOTE: Triple is riscv32 (32-bit) to match the i32 VL argument in your definition.
; The intrinsic name does NOT have .i32 or .i64 at the end because the VL arg is not overloaded.

define <vscale x 4 x i32> @test_vmadot_ss(<vscale x 4 x i32> %acc, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b, i32 %vl) {
; CHECK-LABEL: test_vmadot_ss:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetvli zero, a3, e8, m1, ta, ma
; CHECK-NEXT:    smt.vmadot v8, v9, v10
; CHECK-NEXT:    ret
  %res = call <vscale x 4 x i32> @llvm.riscv.smt.vmadot.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32> %acc, <vscale x 8 x i8> %a, <vscale x 8 x i8> %b, i32 %vl)
  ret <vscale x 4 x i32> %res
}

declare <vscale x 4 x i32> @llvm.riscv.smt.vmadot.nxv4i32.nxv8i8.nxv8i8(<vscale x 4 x i32>, <vscale x 8 x i8>, <vscale x 8 x i8>, i32)