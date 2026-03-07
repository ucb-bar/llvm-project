//===----------------------------------------------------------------------===//
// IntrinsicsRISCVXUCBBAR.td
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// OPU intrinsics and custom instructions.
//===----------------------------------------------------------------------===//
//
// These intrinsics model the OPU matrix-accumulator operations.
//
// IMPORTANT:
// - The accumulator is NOT modeled as an SSA i64 handle anymore.
// - Instead, it is implicit backend state (fixed physical OPM0).
// - Therefore bcast / vmv.rv / vopacc return void.
// - vmv.vr only returns the extracted row vector.
//
//===----------------------------------------------------------------------===//

let TargetPrefix = "riscv" in {

  // Initialize implicit OPM0 from a row vector.
  def int_riscv_opu_bcast :
      Intrinsic<[],
                [llvm_anyvector_ty, llvm_anyint_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  // Insert one row into implicit OPM0.
  def int_riscv_opu_vmv_rv :
      Intrinsic<[],
                [llvm_anyint_ty, llvm_anyvector_ty, llvm_anyint_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  // Extract one row from implicit OPM0.
  def int_riscv_opu_vmv_vr :
      Intrinsic<[llvm_anyvector_ty],
                [llvm_anyint_ty, llvm_anyint_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  // Accumulate lhs x rhs into implicit OPM0.
  def int_riscv_opu_vopacc :
      Intrinsic<[],
                [llvm_anyvector_ty, llvm_anyvector_ty, llvm_anyint_ty],
                [IntrHasSideEffects, IntrWillReturn]>;
}