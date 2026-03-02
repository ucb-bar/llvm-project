//===----------------------------------------------------------------------===//
// IntrinsicsRISCVXSpacemiT.td
//===----------------------------------------------------------------------===//

let TargetPrefix = "riscv" in {

  // Arguments: (Accumulator, Input A, Input B, VL)
  // - Accumulator: llvm_anyvector_ty (matches constraints like nxv4i32 or nxv4f16)
  // - Input A:     llvm_anyvector_ty (matches constraints like nxv8i8 or nxv16i8)
  // - Input B:     llvm_anyvector_ty (matches constraints like nxv8i8 or nxv16i8)
  // - VL:          llvm_anyint_ty    (Explicit vector length)
  
  // Integer Dot Product
  def int_riscv_smt_vmadot : Intrinsic<[llvm_anyvector_ty],
                                       [LLVMMatchType<0>, llvm_anyvector_ty, llvm_anyvector_ty, llvm_anyint_ty],
                                       [IntrNoMem]>;

  def int_riscv_smt_vmadotu : Intrinsic<[llvm_anyvector_ty],
                                        [LLVMMatchType<0>, llvm_anyvector_ty, llvm_anyvector_ty, llvm_anyint_ty],
                                        [IntrNoMem]>;

  def int_riscv_smt_vmadotsu : Intrinsic<[llvm_anyvector_ty],
                                         [LLVMMatchType<0>, llvm_anyvector_ty, llvm_anyvector_ty, llvm_anyint_ty],
                                         [IntrNoMem]>;

  def int_riscv_smt_vmadotus : Intrinsic<[llvm_anyvector_ty],
                                         [LLVMMatchType<0>, llvm_anyvector_ty, llvm_anyvector_ty, llvm_anyint_ty],
                                         [IntrNoMem]>;

  // Floating Point Dot Product
  // Uses same structure: Result/Acc are overloaded (idx 0), Inputs are overloaded (idx 1, 2)
  def int_riscv_smt_vfmadot : Intrinsic<[llvm_anyvector_ty],
                                        [LLVMMatchType<0>, llvm_anyvector_ty, llvm_anyvector_ty, llvm_anyint_ty],
                                        [IntrNoMem]>;
}