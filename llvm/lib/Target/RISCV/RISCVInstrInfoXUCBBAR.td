//===-- RISCVInstrInfoXOPU.td ----------------------------------*- tablegen -*-===//
//
// Saturn OPU vendor extension.
//
// Encoded using opcode 0x57 (standard vector major opcode), but with custom
// funct7/funct3 encoding as seen in bme.h:
//
//   OPMVINBCAST: .insn r 0x57, 0x6, 0x59, md, x0, vs2
//   VMV_VR:      .insn r 0x57, 0x6, 0x5d, vd, rs1, ms2
//   VMV_RV:      .insn r 0x57, 0x6, 0x55, md, rs1, vs2
//   VOPACC:      .insn r 0x57, 0x2, 0x51, md, vs1, vs2   (rs1 field is VS1)
//
// We provide:
//  - MPR register file (matrix accumulator regs) M0..M31 (5-bit encoding)
//  - Real instructions with correct bit encodings
//  - Pseudos carrying (vl,sew,policy) like SpacemiT style
//  - Intrinsic patterns mapping IR intrinsics -> pseudos
//
// NOTE: This file only covers int8 path (no fp8/fp16 yet).
//
//===----------------------------------------------------------------------===//

//------------------------------------------------------------------------------
// Register definitions: Matrix accumulator registers (MPR).
// These are NOT GPRs; they are a separate reg file that just reuses 5-bit
// encoding positions in the instruction.
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// XOPU local opcode helper.
// Do NOT use RISCVOpcode<...> here; in this tree that class is not the right
// helper for this usage.
//------------------------------------------------------------------------------
class XOPUOpcode<bits<7> val> {
  bits<7> Value = val;
}

// Standard OP-V major opcode (0x57).
def OPC_XOPU : XOPUOpcode<0b1010111>;

//------------------------------------------------------------------------------
// XOPU accumulator register file.
// Keep it vendor-local here, like other vendor extensions.
// Do NOT add this to RISCVRegisterInfo.td.
//
// Important:
// - Use OPM* internal names to avoid clashing with the existing mask regs M0..M7.
// - Reuse RISCVReg so HWEncoding stays 5-bit and compatible with generic RISC-V.
// - Keep the carrier fixed-width. Do NOT use nxv1i64 here.
//------------------------------------------------------------------------------
let Namespace = "RISCV" in {
  def OPM0  : RISCVReg<0,  "m0">;
  def OPM1  : RISCVReg<1,  "m1">;
  def OPM2  : RISCVReg<2,  "m2">;
  def OPM3  : RISCVReg<3,  "m3">;
  def OPM4  : RISCVReg<4,  "m4">;
  def OPM5  : RISCVReg<5,  "m5">;
  def OPM6  : RISCVReg<6,  "m6">;
  def OPM7  : RISCVReg<7,  "m7">;
  def OPM8  : RISCVReg<8,  "m8">;
  def OPM9  : RISCVReg<9,  "m9">;
  def OPM10 : RISCVReg<10, "m10">;
  def OPM11 : RISCVReg<11, "m11">;
  def OPM12 : RISCVReg<12, "m12">;
  def OPM13 : RISCVReg<13, "m13">;
  def OPM14 : RISCVReg<14, "m14">;
  def OPM15 : RISCVReg<15, "m15">;
  def OPM16 : RISCVReg<16, "m16">;
  def OPM17 : RISCVReg<17, "m17">;
  def OPM18 : RISCVReg<18, "m18">;
  def OPM19 : RISCVReg<19, "m19">;
  def OPM20 : RISCVReg<20, "m20">;
  def OPM21 : RISCVReg<21, "m21">;
  def OPM22 : RISCVReg<22, "m22">;
  def OPM23 : RISCVReg<23, "m23">;
  def OPM24 : RISCVReg<24, "m24">;
  def OPM25 : RISCVReg<25, "m25">;
  def OPM26 : RISCVReg<26, "m26">;
  def OPM27 : RISCVReg<27, "m27">;
  def OPM28 : RISCVReg<28, "m28">;
  def OPM29 : RISCVReg<29, "m29">;
  def OPM30 : RISCVReg<30, "m30">;
  def OPM31 : RISCVReg<31, "m31">;

  // Fixed-width opaque carrier for the accumulator handle.
  // This avoids tblgen/register-bank crashes from scalable types.
  def MPR : RegisterClass<"RISCV", [i64], 64, (add OPM0)> {
      let DecoderMethod = "DecodeSimpleRegisterClass<RISCV::OPM0, 1>";
    }
}

// If you already have ixlenimm elsewhere, do NOT re-define it.
// In many trees, it’s already available.
// def ixlenimm : Operand<XLenVT>;

//------------------------------------------------------------------------------
// Instruction formats
//------------------------------------------------------------------------------

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {

  // opmvinbcast: md <- broadcast(vs2), rs1 field forced to x0.
  class RVInstXOPU_MDst_VS2<bits<3> funct3, bits<7> funct7, string opcodestr>
    : RVInst<(outs MPR:$md), (ins VRM4:$vs2), opcodestr,
            "$md, $vs2", [], InstFormatR> {
    bits<5> md;
    bits<5> vs2;

    let Uses = [VL, VTYPE];

    let Inst{31-25} = funct7;
    let Inst{24-20} = vs2;
    let Inst{19-15} = 0b00000;
    let Inst{14-12} = funct3;
    let Inst{11-7}  = md;
    let Inst{6-0}   = OPC_XOPU.Value;
  }

  // vmv.vr: vd <- extract_row(ms2, rs1)
  class RVInstXOPU_VD_MSrc<bits<3> funct3, bits<7> funct7, string opcodestr>
    : RVInst<(outs VRM4:$vd), (ins GPR:$rs1, MPR:$ms2), opcodestr,
            "$vd, $rs1, $ms2", [], InstFormatR> {
    bits<5> vd;
    bits<5> rs1;
    bits<5> ms2;

    let Uses = [VL, VTYPE];

    let Inst{31-25} = funct7;
    let Inst{24-20} = ms2;
    let Inst{19-15} = rs1;
    let Inst{14-12} = funct3;
    let Inst{11-7}  = vd;
    let Inst{6-0}   = OPC_XOPU.Value;
  }

  // vmv.rv: md[row] <- vs2  (tied update)
  class RVInstXOPU_MDst_Tied_VS2<bits<3> funct3, bits<7> funct7, string opcodestr>
    : RVInst<(outs MPR:$md), (ins MPR:$md_in, GPR:$rs1, VRM4:$vs2), opcodestr,
            "$md, $rs1, $vs2", [], InstFormatR> {
    bits<5> md;
    bits<5> rs1;
    bits<5> vs2;

    let Constraints = "$md = $md_in";
    let Uses = [VL, VTYPE];

    let Inst{31-25} = funct7;
    let Inst{24-20} = vs2;
    let Inst{19-15} = rs1;
    let Inst{14-12} = funct3;
    let Inst{11-7}  = md;
    let Inst{6-0}   = OPC_XOPU.Value;
  }

  // vopacc: md += outer(vs1, vs2)  (tied update)
  // rs1 field is repurposed to carry VS1.
  class RVInstXOPU_VOPACC<bits<3> funct3, bits<7> funct7, string opcodestr>
    : RVInst<(outs MPR:$md), (ins MPR:$md_in, VR:$vs1, VR:$vs2), opcodestr,
            "$md, $vs1, $vs2", [], InstFormatR> {
    bits<5> md;
    bits<5> vs1;
    bits<5> vs2;

    let Constraints = "$md = $md_in";
    let Uses = [VL, VTYPE];

    let Inst{31-25} = funct7;
    let Inst{24-20} = vs2;
    let Inst{19-15} = vs1;
    let Inst{14-12} = funct3;
    let Inst{11-7}  = md;
    let Inst{6-0}   = OPC_XOPU.Value;
  }
}

//------------------------------------------------------------------------------
// Real instructions and pseudos + patterns
//------------------------------------------------------------------------------

// If ixlenimm already exists elsewhere in your tree, do not redefine it here.
// def ixlenimm : Operand<XLenVT>;
// If ixlenimm already exists elsewhere in your tree, do not redefine it here.
// def ixlenimm : Operand<XLenVT>;

let Predicates = [HasVendorXOPU] in {

    let DecoderNamespace = "XOPU" in {
      def OPU_OPMVINBCAST : RVInstXOPU_MDst_VS2<0b110, 0b1011001, "opu.opmvinbcast">;
      def OPU_VMV_VR      : RVInstXOPU_VD_MSrc<0b110, 0b1011101, "opu.vmv.vr">;
      def OPU_VMV_RV      : RVInstXOPU_MDst_Tied_VS2<0b110, 0b1010101, "opu.vmv.rv">;
      def OPU_VOPACC      : RVInstXOPU_VOPACC<0b010, 0b1010001, "opu.vopacc">;
    }

      let isPseudo = 1, isCodeGenOnly = 1, hasSideEffects = 1 in {

      // OPM0 <- broadcast(vs2)
      def OPU_OPMVINBCAST_Pseudo :
        Pseudo<(outs),
              (ins VRM4:$vs2, AVL:$vl, ixlenimm:$sew, ixlenimm:$policy), []>,
        PseudoInstExpansion<(OPU_OPMVINBCAST OPM0, VRM4:$vs2)> {
          let Defs = [OPM0];
          let Uses = [VL, VTYPE];
        }

      // vd <- extract_row(OPM0, rs1)
      def OPU_VMV_VR_Pseudo :
        Pseudo<(outs VRM4:$vd),
              (ins GPR:$rs1, AVL:$vl, ixlenimm:$sew, ixlenimm:$policy), []>,
        PseudoInstExpansion<(OPU_VMV_VR VRM4:$vd, GPR:$rs1, OPM0)> {
          let Uses = [OPM0, VL, VTYPE];
        }

      // OPM0[row] <- vs2
      def OPU_VMV_RV_Pseudo :
        Pseudo<(outs),
              (ins GPR:$rs1, VRM4:$vs2,
                    AVL:$vl, ixlenimm:$sew, ixlenimm:$policy), []>,
        PseudoInstExpansion<(OPU_VMV_RV OPM0, OPM0, GPR:$rs1, VRM4:$vs2)> {
          let Defs = [OPM0];
          let Uses = [OPM0, VL, VTYPE];
        }

      // OPM0 += outer(vs1, vs2)
      def OPU_VOPACC_Pseudo :
        Pseudo<(outs),
              (ins VR:$vs1, VR:$vs2,
                    AVL:$vl, ixlenimm:$sew, ixlenimm:$policy), []>,
        PseudoInstExpansion<(OPU_VOPACC OPM0, OPM0, VR:$vs1, VR:$vs2)> {
          let Defs = [OPM0];
          let Uses = [OPM0, VL, VTYPE];
        }
    }

    // Intrinsic patterns with implicit OPM0 state.

    def : Pat<(int_riscv_opu_bcast nxv8i32:$v, (XLenVT GPR:$vl)),
              (OPU_OPMVINBCAST_Pseudo $v, $vl, 5, 1)>;

    def : Pat<(int_riscv_opu_vmv_rv (XLenVT GPR:$row),
                                      nxv8i32:$v,
                                      (XLenVT GPR:$vl)),
              (OPU_VMV_RV_Pseudo $row, $v, $vl, 5, 1)>;

    def : Pat<(nxv8i32 (int_riscv_opu_vmv_vr (XLenVT GPR:$row),
                                              (XLenVT GPR:$vl))),
              (OPU_VMV_VR_Pseudo $row, $vl, 5, 1)>;

    def : Pat<(int_riscv_opu_vopacc nxv8i8:$lhs,
                                      nxv8i8:$rhs,
                                      (XLenVT GPR:$vl)),
              (OPU_VOPACC_Pseudo $lhs, $rhs, $vl, 3, 1)>;
}