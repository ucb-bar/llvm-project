; backend_test.ll
; This manually defines a function that calls your intrinsic.
; We use fixed vectors (vscale x n) which LLVM understands.

define <vscale x 4 x i32> @test_spacemit_intrinsic(
    <vscale x 4 x i32> %acc, 
    <vscale x 8 x i8> %lhs, 
    <vscale x 8 x i8> %rhs, 
    i64 %vl) {

  ; Call the intrinsic. Note the .i64 suffix we fought for earlier!
  %res = call <vscale x 4 x i32> @llvm.riscv.smt.vmadot.nxv4i32.nxv8i8.nxv8i8.i64(
    <vscale x 4 x i32> %acc, 
    <vscale x 8 x i8> %lhs, 
    <vscale x 8 x i8> %rhs, 
    i64 %vl
  )

  ret <vscale x 4 x i32> %res
}

; Declare the intrinsic signature
declare <vscale x 4 x i32> @llvm.riscv.smt.vmadot.nxv4i32.nxv8i8.nxv8i8.i64(
    <vscale x 4 x i32>, 
    <vscale x 8 x i8>, 
    <vscale x 8 x i8>, 
    i64
)