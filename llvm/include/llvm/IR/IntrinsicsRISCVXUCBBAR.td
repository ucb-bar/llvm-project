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

  // Gemmini-MX RoCC intrinsics.
  //
  // Merlin currently lowers Gemmini operations through a fixed RV64 host
  // interface, materializing rs1/rs2 payloads as i64 values before export to
  // LLVM IR. Keep these intrinsics non-overloaded so the LLVM backend surface
  // matches that lowering directly.
  def int_riscv_flush :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_config :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_mvin :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_mvin2 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_mvin3 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_mvout :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_preload :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_compute_preloaded :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_compute_accumulated :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_ws_config_bounds :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_ws_config_addrs_ab :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_ws_config_addrs_dc :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_ws_config_strides_ab :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_ws_config_strides_dc :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_ws :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  // mxGemmini extensions: spad-source LOOP_WS preconfig (funct=24) and
  // CONFIG_SCALE_MEM (funct=26 = mxquant_config_mvout).
  def int_riscv_loop_ws_config_spad_ab :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_mxquant_config :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_mvout_spad :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_conv_ws_config1 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_conv_ws_config2 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_conv_ws_config3 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_conv_ws_config4 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_conv_ws_config5 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_conv_ws_config6 :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;

  def int_riscv_loop_conv_ws :
      Intrinsic<[], [llvm_i64_ty, llvm_i64_ty],
                [IntrHasSideEffects, IntrWillReturn]>;
}
