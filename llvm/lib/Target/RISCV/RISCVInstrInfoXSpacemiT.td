//===-- RISCVInstrInfoXSpacemiT.td -------------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the vendor extensions defined by SpacemiT.
// SpacemiT IME (Integrated Matrix Engine) Extension.
//
// Optimized for VLEN=256 configurations where:
//  - Integer Accumulators (Int32) require 2 registers (VRM2).
//  - Floating Point Accumulators (FP16) require 1 register (VR).
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Operand definitions.
//===----------------------------------------------------------------------===//

// We use this for SEW and Policy operands in Pseudo instructions.
def ixlenimm : Operand<XLenVT>;

class SMTVDotOpcode<bits<7> val> {
  bits<7> Value = val;
}

class SMTVEncoding2<bits<2> val> {
  bits<2> Value = val;
}

class SMTVEncoding3<bits<3> val> {
  bits<3> Value = val;
}

//===----------------------------------------------------------------------===//
// Major Opcode Definitions (Spec Page 19)
//
// OPMMA:       111000 + 1 (M-Bit) = 1110001 -> Integer Dot Product
// OPMMA_SLIDE: 111001 + 1 (M-Bit) = 1110011 -> Integer Sliding Window
// OPFMMA:      111010 + 1 (M-Bit) = 1110101 -> Floating Point Dot Product
//===----------------------------------------------------------------------===//
def OPMMA       : SMTVDotOpcode<0b1110001>;
def OPMMA_SLIDE : SMTVDotOpcode<0b1110011>;
def OPFMMA      : SMTVDotOpcode<0b1110101>;

//===----------------------------------------------------------------------===//
// Vector Dot-Product Sign Encoding
// Defines the signed/unsigned mixing modes for vector dot-product operations.
// Maps to bits [13:12] of the instruction.
// Encoding format: [1:0] bits
//   00: UU (Unsigned x Unsigned)
//   01: US (Unsigned x Signed)
//   10: SU (Signed x Unsigned)
//   11: SS (Signed x Signed)
//===----------------------------------------------------------------------===//
def SMT_Int_UU        : SMTVEncoding2<0b00>;
def SMT_Int_US        : SMTVEncoding2<0b01>;
def SMT_Int_SU        : SMTVEncoding2<0b10>;
def SMT_Int_SS        : SMTVEncoding2<0b11>;

//===----------------------------------------------------------------------===//
// Vector Dot-Product Sliding Window Modes (Integer)
// Maps to bits [15:14] of the instruction (func2).
// Encoding format: [1:0] bits
//   00: Slide1 (1-element sliding stride)
//   01: Slide2 (2-element sliding stride)
//   10: Slide3 (3-element sliding stride)
//   11: Reserved
//
// Used in sliding-window dot-product operations:
//   vd = vs1 • vs2.slide{1|2|3}  // • = dot product
//===----------------------------------------------------------------------===//
def SMT_Slide1 : SMTVEncoding2<0b00>;
def SMT_Slide2 : SMTVEncoding2<0b01>;
def SMT_Slide3 : SMTVEncoding2<0b10>;

//===----------------------------------------------------------------------===//
// Floating Point Modes
// Maps to bits [14:12] of the instruction (func3).
//   000: Standard Dot Product (vfmadot)
//   001: Slide 1 (vfmadot1)
//   010: Slide 2 (vfmadot2)
//   011: Slide 3 (vfmadot3)
//   ...: Other reserved modes
//===----------------------------------------------------------------------===//
def SMT_FP_Std    : SMTVEncoding3<0b000>;
def SMT_FP_Slide1 : SMTVEncoding3<0b001>;
def SMT_FP_Slide2 : SMTVEncoding3<0b010>;
def SMT_FP_Slide3 : SMTVEncoding3<0b011>;

//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {

  // 1. Integer Real Instruction Format (vmadot)
  //    - NO '$vl' in 'ins'. The hardware implicitly uses VL.
  //    - GUARD RAIL: Output uses VRM2 (Group of 2, Even Aligned).
  //      This prevents illegal instruction crashes on hardware that expects 
  //      even-aligned accumulator pairs.
  class RVInstSMT_Int<SMTVEncoding2 sign, string opcodestr>
      : RVInst<(outs VRM2:$vd), (ins VRM2:$vd_in, VR:$vs1, VR:$vs2), opcodestr,
               "$vd, $vs1, $vs2", [], InstFormatR> {
    bits<5> vd;
    bits<5> vs1;
    bits<5> vs2;

    let Constraints = "$vd = $vd_in";
    let Uses = [VL, VTYPE];

    // Encoding: Funct7 + vs2 + vs1 + ...
    let Inst{31-25} = OPMMA.Value;
    let Inst{24-20} = vs2;
    let Inst{19-15} = vs1;
    let Inst{15-14} = 0b00;       // No Slide
    let Inst{13-12} = sign.Value; // Sign Mode
    let Inst{11-7}  = vd;
    let Inst{6-0}   = 0b0101011;  // OPC_CUSTOM_1
  }

  // 2. Integer Sliding Instruction Format (vmadot1/2/3)
  //    - GUARD RAIL: Input 'vs1' uses VRM2 because sliding loads from 
  //      a register pair (VS1 and VS1+1).
  class RVInstSMT_IntSlide<SMTVEncoding2 funct2, SMTVEncoding2 sign, string opcodestr>
      : RVInst<(outs VRM2:$vd), (ins VRM2:$vd_in, VRM2:$vs1, VR:$vs2), opcodestr,
               "$vd, $vs1, $vs2", [], InstFormatR> {
    bits<5> vd;
    bits<5> vs1;
    bits<5> vs2;

    let Constraints = "$vd = $vd_in";
    let Uses = [VL, VTYPE];

    let Inst{31-25} = OPMMA_SLIDE.Value;
    let Inst{24-20} = vs2;
    let Inst{19-16} = vs1{4-1}; // 4 bits for even reg index
    let Inst{15-14} = funct2.Value; // Slide Amount
    let Inst{13-12} = sign.Value;   // Sign Mode
    let Inst{11-7}  = vd;
    let Inst{6-0}   = 0b0101011;
  }

  // 3. Floating Point Instruction Format (vfmadot)
  //    - GUARD RAIL: Output uses VR (Single Register).
  //      For VLEN=256, FP16 4x4 matrix fits in 256 bits (1 Reg).
  //      Using VRM2 here would be incorrect and waste registers.
  class RVInstSMT_FP<SMTVEncoding3 mode, string opcodestr>
      : RVInst<(outs VR:$vd), (ins VR:$vd_in, VR:$vs1, VR:$vs2), opcodestr,
               "$vd, $vs1, $vs2", [], InstFormatR> {
    bits<5> vd;
    bits<5> vs1;
    bits<5> vs2;

    let Constraints = "$vd = $vd_in";
    let Uses = [VL, VTYPE];

    let Inst{31-25} = OPFMMA.Value;
    let Inst{24-20} = vs2;
    let Inst{19-15} = vs1;
    let Inst{14-12} = mode.Value; // Mode/Slide (Func3)
    let Inst{11-7}  = vd;
    let Inst{6-0}   = 0b0101011;
  }
}

//===----------------------------------------------------------------------===//
// Instructions & Patterns
//===----------------------------------------------------------------------===//

let Predicates = [HasVendorXSMTVDot] in {

  // 1. Integer Multiclass
  multiclass SMT_Int_Dot<SMTVEncoding2 sign, string opcodestr, Intrinsic intr> {
    
    let DecoderNamespace = "XSMT" in
    def NAME : RVInstSMT_Int<sign, opcodestr>;

    let isPseudo = 1, isCodeGenOnly = 1 in
    def NAME # "_Pseudo" : 
      Pseudo<(outs VRM2:$vd), 
             // We keep the operands here so the Pattern Matcher can bind them
             (ins VRM2:$vd_in, VR:$vs1, VR:$vs2, AVL:$vl, ixlenimm:$sew, ixlenimm:$policy), []>,
      PseudoInstExpansion<(!cast<Instruction>(NAME) VRM2:$vd, VRM2:$vd_in, VR:$vs1, VR:$vs2)> {
        let Constraints = "$vd = $vd_in";
        let Uses = [VL, VTYPE]; // Hardware still uses VL implicitly
      }

    // Pattern (Integer): matches nxv4i32 (VRM2) and nxv8i8 (VR)
    def : Pat<(nxv4i32 (intr nxv4i32:$acc, nxv8i8:$a, nxv8i8:$b, (XLenVT GPR:$vl))),
              (!cast<Instruction>(NAME # "_Pseudo") $acc, $a, $b, $vl, 3, 1)>;
  }

  // 2. Floating Point Multiclass
  multiclass SMT_FP_Dot<SMTVEncoding3 mode, string opcodestr, Intrinsic intr> {
    
    let DecoderNamespace = "XSMT" in
    def NAME : RVInstSMT_FP<mode, opcodestr>;

    // REMOVED: HasVLOp, HasSEWOp, HasVecPolicyOp. 
    let isPseudo = 1, isCodeGenOnly = 1 in
    def NAME # "_Pseudo" : 
      Pseudo<(outs VR:$vd), 
             (ins VR:$vd_in, VR:$vs1, VR:$vs2, AVL:$vl, ixlenimm:$sew, ixlenimm:$policy), []>,
      PseudoInstExpansion<(!cast<Instruction>(NAME) VR:$vd, VR:$vd_in, VR:$vs1, VR:$vs2)> {
        let Constraints = "$vd = $vd_in";
        let Uses = [VL, VTYPE];
      }

    // Pattern (Float): matches nxv4f16 (VR) and nxv8i8 (VR)
    def : Pat<(nxv4f16 (intr nxv4f16:$acc, nxv8i8:$a, nxv8i8:$b, (XLenVT GPR:$vl))),
              (!cast<Instruction>(NAME # "_Pseudo") $acc, $a, $b, $vl, 3, 1)>;
  }

  // =========================================================
  // Instantiations
  // =========================================================

  defm SMT_VMADOT   : SMT_Int_Dot<SMT_Int_SS, "smt.vmadot",   int_riscv_smt_vmadot>;
  defm SMT_VMADOTU  : SMT_Int_Dot<SMT_Int_UU, "smt.vmadotu",  int_riscv_smt_vmadotu>;
  defm SMT_VMADOTSU : SMT_Int_Dot<SMT_Int_SU, "smt.vmadotsu", int_riscv_smt_vmadotsu>;
  defm SMT_VMADOTUS : SMT_Int_Dot<SMT_Int_US, "smt.vmadotus", int_riscv_smt_vmadotus>;

  defm SMT_VFMADOT  : SMT_FP_Dot<SMT_FP_Std,  "smt.vfmadot",  int_riscv_smt_vfmadot>;

  // --- Sliding Window Instructions (Assembler Support) ---
  // These are defined as Real Instructions. 
  // If intrinsics are needed later, they can be wrapped in a multiclass.
  
  let DecoderNamespace = "XSMT" in {
    // Slide 1
    def SMT_VMADOT1   : RVInstSMT_IntSlide<SMT_Slide1, SMT_Int_SS, "smt.vmadot1">;
    def SMT_VMADOT1U  : RVInstSMT_IntSlide<SMT_Slide1, SMT_Int_UU, "smt.vmadot1u">;
    def SMT_VMADOT1SU : RVInstSMT_IntSlide<SMT_Slide1, SMT_Int_SU, "smt.vmadot1su">;
    def SMT_VMADOT1US : RVInstSMT_IntSlide<SMT_Slide1, SMT_Int_US, "smt.vmadot1us">;

    // Slide 2
    def SMT_VMADOT2   : RVInstSMT_IntSlide<SMT_Slide2, SMT_Int_SS, "smt.vmadot2">;
    def SMT_VMADOT2U  : RVInstSMT_IntSlide<SMT_Slide2, SMT_Int_UU, "smt.vmadot2u">;
    def SMT_VMADOT2SU : RVInstSMT_IntSlide<SMT_Slide2, SMT_Int_SU, "smt.vmadot2su">;
    def SMT_VMADOT2US : RVInstSMT_IntSlide<SMT_Slide2, SMT_Int_US, "smt.vmadot2us">;

    // Slide 3
    def SMT_VMADOT3   : RVInstSMT_IntSlide<SMT_Slide3, SMT_Int_SS, "smt.vmadot3">;
    def SMT_VMADOT3U  : RVInstSMT_IntSlide<SMT_Slide3, SMT_Int_UU, "smt.vmadot3u">;
    def SMT_VMADOT3SU : RVInstSMT_IntSlide<SMT_Slide3, SMT_Int_SU, "smt.vmadot3su">;
    def SMT_VMADOT3US : RVInstSMT_IntSlide<SMT_Slide3, SMT_Int_US, "smt.vmadot3us">;
  }

} // Predicates