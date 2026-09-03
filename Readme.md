<div align="center">

# ASM SMM RAM Lockdown Driver
### Low-Level Ring -2 Firmware Security & SMRAM Protection in Pure Assembly

[![Assembly](https://img.shields.io/badge/Language-x86__64%20ASM-purple?style=flat&logo=assembly&logoColor=white)](https://en.wikipedia.org/wiki/Assembly_language)
[![Platform](https://img.shields.io/badge/Platform-UEFI%20%2F%20SMM-0078D6?style=flat&logo=windows&logoColor=white)](https://en.wikipedia.org/wiki/System_Management_Mode)
[![Privilege](https://img.shields.io/badge/Privilege-Ring%20-2-critical?style=flat)]()

</div>

---

## Overview

A bare-metal, pure Assembly implementation designed to execute during the **DXE (Driver Execution Environment)** phase of UEFI/BIOS initialization. This low-level routine directly interacts with CPU control registers and chipset configuration spaces to lock down **SMRAM (System Management RAM)**, preventing malicious pre-OS tampering or unauthorized memory mapping before the operating system even boots.

---

## Technical Architecture & Mechanism

Operating at **Ring -2**, SMM is the highest privilege mode in modern x86/x64 architecture. If an attacker breaches SMRAM before it gets locked, they achieve permanent hardware persistence. 

This pure ASM driver secures the system through the following actions:
1. **SMI Disabling:** Temporarily disables System Management Interrupts via control port manipulation to ensure atomic configuration safely.
2. **Chipset Register Locking:** Targets MCHBAR (Memory Controller Hub Base Address) registers (such as `SMRAMC`) to enforce read-only and lock states on the SMRAM address boundary.
3. **Cache Line Flushing & Serialization:** Leverages native instructions (`wbinvd`, `cld`) to flush memory cache hierarchies and force immediate hardware register synchronization.

---

## Assembly Implementation Concept

```assembly
; ==============================================================================
; SMM RAM Lockdown Core Routine (Pure x86_64 Assembly)
; Target: DXE Phase Pre-OS Initialization
; ==============================================================================

.code

PUBLIC LockSmramHardware

LockSmramHardware PROC
    ; Clear direction flag for string/memory operations
    cld                     

    ; Disable interrupts to ensure atomic register updates
    cli                     

    ; Load Memory Controller Hub Base Register (MCHBAR) or Chipset Config Space
    ; (Example conceptual port/register interaction for Intel chipset architecture)
    mov dx, 0CF8h           ; PCI Configuration Address Port
    mov eax, 8000F804h      ; Target Bus 0, Device 0, Function 0, Register offset
    out dx, eax

    mov dx, 0CFCh           ; PCI Configuration Data Port
    in eax, dx              ; Read current SMRAM control register state (SMRAMC)

    ; Set the Lock bit (D_LCK) and Enable SMRAM bit (G_SMRAME)
    or eax, 00000018h       ; Apply lockdown flags

    ; Write back modified configuration to lock memory boundaries
    out dx, eax             

    ; Flush CPU caches to enforce memory coherency across core complexes
    wbinvd                  

    ; Restore interrupt flag
    sti                     
    ret
LockSmramHardware ENDP

END
