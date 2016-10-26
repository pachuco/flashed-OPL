//
// Copyright (C) 2013-2016 Alexey Khokholov (Nuke.YKT)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
//
//  Nuked OPL3 emulator.
//  Thanks:
//      MAME Development Team(Jarek Burczynski, Tatsuyuki Satoh):
//          Feedback and Rhythm part calculation information.
//      forums.submarine.org.uk(carbon14, opl3):
//          Tremolo and phase generator calculation information.
//      OPLx decapsulated(Matthew Gambrell, Olli Niemitalo):
//          OPL2 ROMs.
//
// version: 1.7.4
//

package nukedOPL
{
    import flash.utils.ByteArray;

public class OPL3emu
{
    private var chip:opl3_chip;

    private var OPL3_SAMPRATE:int = 49716;
    private var RSM_FRAC:int = 10;
    private var
        envelope_gen_num_off:int = 0,
        envelope_gen_num_attack:int = 1,
        envelope_gen_num_decay:int = 2,
        envelope_gen_num_sustain:int = 3,
        envelope_gen_num_release:int = 4;

    // Channel types
    private var
        ch_2op:int = 0,
        ch_4op:int = 1,
        ch_4op2:int = 2,
        ch_drum:int = 3;

    // Envelope key types
    private var
        egk_norm:int = 0x01,
        egk_drum:int = 0x02;
    
    //
    // logsin table
    //
    private var logsinrom:Vector.<uint> = Vector.<uint>([
        0x859, 0x6c3, 0x607, 0x58b, 0x52e, 0x4e4, 0x4a6, 0x471,
        0x443, 0x41a, 0x3f5, 0x3d3, 0x3b5, 0x398, 0x37e, 0x365,
        0x34e, 0x339, 0x324, 0x311, 0x2ff, 0x2ed, 0x2dc, 0x2cd,
        0x2bd, 0x2af, 0x2a0, 0x293, 0x286, 0x279, 0x26d, 0x261,
        0x256, 0x24b, 0x240, 0x236, 0x22c, 0x222, 0x218, 0x20f,
        0x206, 0x1fd, 0x1f5, 0x1ec, 0x1e4, 0x1dc, 0x1d4, 0x1cd,
        0x1c5, 0x1be, 0x1b7, 0x1b0, 0x1a9, 0x1a2, 0x19b, 0x195,
        0x18f, 0x188, 0x182, 0x17c, 0x177, 0x171, 0x16b, 0x166,
        0x160, 0x15b, 0x155, 0x150, 0x14b, 0x146, 0x141, 0x13c,
        0x137, 0x133, 0x12e, 0x129, 0x125, 0x121, 0x11c, 0x118,
        0x114, 0x10f, 0x10b, 0x107, 0x103, 0x0ff, 0x0fb, 0x0f8,
        0x0f4, 0x0f0, 0x0ec, 0x0e9, 0x0e5, 0x0e2, 0x0de, 0x0db,
        0x0d7, 0x0d4, 0x0d1, 0x0cd, 0x0ca, 0x0c7, 0x0c4, 0x0c1,
        0x0be, 0x0bb, 0x0b8, 0x0b5, 0x0b2, 0x0af, 0x0ac, 0x0a9,
        0x0a7, 0x0a4, 0x0a1, 0x09f, 0x09c, 0x099, 0x097, 0x094,
        0x092, 0x08f, 0x08d, 0x08a, 0x088, 0x086, 0x083, 0x081,
        0x07f, 0x07d, 0x07a, 0x078, 0x076, 0x074, 0x072, 0x070,
        0x06e, 0x06c, 0x06a, 0x068, 0x066, 0x064, 0x062, 0x060,
        0x05e, 0x05c, 0x05b, 0x059, 0x057, 0x055, 0x053, 0x052,
        0x050, 0x04e, 0x04d, 0x04b, 0x04a, 0x048, 0x046, 0x045,
        0x043, 0x042, 0x040, 0x03f, 0x03e, 0x03c, 0x03b, 0x039,
        0x038, 0x037, 0x035, 0x034, 0x033, 0x031, 0x030, 0x02f,
        0x02e, 0x02d, 0x02b, 0x02a, 0x029, 0x028, 0x027, 0x026,
        0x025, 0x024, 0x023, 0x022, 0x021, 0x020, 0x01f, 0x01e,
        0x01d, 0x01c, 0x01b, 0x01a, 0x019, 0x018, 0x017, 0x017,
        0x016, 0x015, 0x014, 0x014, 0x013, 0x012, 0x011, 0x011,
        0x010, 0x00f, 0x00f, 0x00e, 0x00d, 0x00d, 0x00c, 0x00c,
        0x00b, 0x00a, 0x00a, 0x009, 0x009, 0x008, 0x008, 0x007,
        0x007, 0x007, 0x006, 0x006, 0x005, 0x005, 0x005, 0x004,
        0x004, 0x004, 0x003, 0x003, 0x003, 0x002, 0x002, 0x002,
        0x002, 0x001, 0x001, 0x001, 0x001, 0x001, 0x001, 0x001,
        0x000, 0x000, 0x000, 0x000, 0x000, 0x000, 0x000, 0x000
    ]);
    
    //
    // exp table
    //
    private var exprom:Vector.<uint> = Vector.<uint>([
        0x000, 0x003, 0x006, 0x008, 0x00b, 0x00e, 0x011, 0x014,
        0x016, 0x019, 0x01c, 0x01f, 0x022, 0x025, 0x028, 0x02a,
        0x02d, 0x030, 0x033, 0x036, 0x039, 0x03c, 0x03f, 0x042,
        0x045, 0x048, 0x04b, 0x04e, 0x051, 0x054, 0x057, 0x05a,
        0x05d, 0x060, 0x063, 0x066, 0x069, 0x06c, 0x06f, 0x072,
        0x075, 0x078, 0x07b, 0x07e, 0x082, 0x085, 0x088, 0x08b,
        0x08e, 0x091, 0x094, 0x098, 0x09b, 0x09e, 0x0a1, 0x0a4,
        0x0a8, 0x0ab, 0x0ae, 0x0b1, 0x0b5, 0x0b8, 0x0bb, 0x0be,
        0x0c2, 0x0c5, 0x0c8, 0x0cc, 0x0cf, 0x0d2, 0x0d6, 0x0d9,
        0x0dc, 0x0e0, 0x0e3, 0x0e7, 0x0ea, 0x0ed, 0x0f1, 0x0f4,
        0x0f8, 0x0fb, 0x0ff, 0x102, 0x106, 0x109, 0x10c, 0x110,
        0x114, 0x117, 0x11b, 0x11e, 0x122, 0x125, 0x129, 0x12c,
        0x130, 0x134, 0x137, 0x13b, 0x13e, 0x142, 0x146, 0x149,
        0x14d, 0x151, 0x154, 0x158, 0x15c, 0x160, 0x163, 0x167,
        0x16b, 0x16f, 0x172, 0x176, 0x17a, 0x17e, 0x181, 0x185,
        0x189, 0x18d, 0x191, 0x195, 0x199, 0x19c, 0x1a0, 0x1a4,
        0x1a8, 0x1ac, 0x1b0, 0x1b4, 0x1b8, 0x1bc, 0x1c0, 0x1c4,
        0x1c8, 0x1cc, 0x1d0, 0x1d4, 0x1d8, 0x1dc, 0x1e0, 0x1e4,
        0x1e8, 0x1ec, 0x1f0, 0x1f5, 0x1f9, 0x1fd, 0x201, 0x205,
        0x209, 0x20e, 0x212, 0x216, 0x21a, 0x21e, 0x223, 0x227,
        0x22b, 0x230, 0x234, 0x238, 0x23c, 0x241, 0x245, 0x249,
        0x24e, 0x252, 0x257, 0x25b, 0x25f, 0x264, 0x268, 0x26d,
        0x271, 0x276, 0x27a, 0x27f, 0x283, 0x288, 0x28c, 0x291,
        0x295, 0x29a, 0x29e, 0x2a3, 0x2a8, 0x2ac, 0x2b1, 0x2b5,
        0x2ba, 0x2bf, 0x2c4, 0x2c8, 0x2cd, 0x2d2, 0x2d6, 0x2db,
        0x2e0, 0x2e5, 0x2e9, 0x2ee, 0x2f3, 0x2f8, 0x2fd, 0x302,
        0x306, 0x30b, 0x310, 0x315, 0x31a, 0x31f, 0x324, 0x329,
        0x32e, 0x333, 0x338, 0x33d, 0x342, 0x347, 0x34c, 0x351,
        0x356, 0x35b, 0x360, 0x365, 0x36a, 0x370, 0x375, 0x37a,
        0x37f, 0x384, 0x38a, 0x38f, 0x394, 0x399, 0x39f, 0x3a4,
        0x3a9, 0x3ae, 0x3b4, 0x3b9, 0x3bf, 0x3c4, 0x3c9, 0x3cf,
        0x3d4, 0x3da, 0x3df, 0x3e4, 0x3ea, 0x3ef, 0x3f5, 0x3fa
    ]);
    
    //
    // freq mult table multiplied by 2
    //
    // 1/2, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 12, 12, 15, 15
    //
    private var mt:Vector.<uint> = Vector.<uint>([
        1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 20, 24, 24, 30, 30
    ]);
    
    //
    // ksl table
    //
    private var kslrom:Vector.<uint> = Vector.<uint>([
        0, 32, 40, 45, 48, 51, 53, 55, 56, 58, 59, 60, 61, 62, 63, 64
    ]);
    
    private var kslshift:Vector.<uint> = Vector.<uint>([
        8, 1, 2, 0
    ]);
    
    //static const Bit8u eg_incstep[3][4][8]
    //OLD: eg_incstep[a][b][c];
    //NEW: eg_incstep[a*32 + b*8 + c];
    private var eg_incstep:Vector.<uint> = Vector.<uint>([
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        
        0, 1, 0, 1, 0, 1, 0, 1,
        0, 1, 0, 1, 1, 1, 0, 1,
        0, 1, 1, 1, 0, 1, 1, 1,
        0, 1, 1, 1, 1, 1, 1, 1,
        
        1, 1, 1, 1, 1, 1, 1, 1,
        2, 2, 1, 1, 1, 1, 1, 1,
        2, 2, 1, 1, 2, 2, 1, 1,
        2, 2, 2, 2, 2, 2, 1, 1
    ]);
    
    private var eg_incdesc:Vector.<uint> = Vector.<uint>([
        0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2
    ]);
    
    private var eg_incsh:Vector.<int> = Vector.<int>([
        0, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0, -1, -2
    ]);
    
    //
    // address decoding
    //
    private var ad_slot:Vector.<int> = Vector.<int>([
        0, 1, 2, 3, 4, 5, -1, -1, 6, 7, 8, 9, 10, 11, -1, -1,
        12, 13, 14, 15, 16, 17, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1
    ]);

    private var ch_slot:Vector.<uint> = Vector.<uint>([
        0, 1, 2, 6, 7, 8, 12, 13, 14, 18, 19, 20, 24, 25, 26, 30, 31, 32
    ]);
    
    public function OPL3emu(samplerate:uint)
    {
        chip = new opl3_chip();
        Reset(samplerate);
    }
    
    
    
    
    private function OPL3_EnvelopeCalcExp(level:uint):int
    {
        if (level > 0x1fff)
        {
            level = 0x1fff;
        }
        return ((exprom[(level & 0xff) ^ 0xff] | 0x400) << 1) >> (level >> 8);
    }
    
    public function envelope_gen(slot:opl3_slot):void
    {
        switch(slot.eg_gen)
        {
            case envelope_gen_num_off:
                slot.eg_rout = 0x1ff;
            break;
            case envelope_gen_num_attack:
                if (slot.eg_rout == 0x00)
                {
                    slot.eg_gen = envelope_gen_num_decay;
                    OPL3_EnvelopeUpdateRate(slot);
                    return;
                }
                slot.eg_rout += ((~slot.eg_rout) * slot.eg_inc) >> 3; //~
                if (slot.eg_rout < 0x00)
                {
                    slot.eg_rout = 0x00;
                }
            break;
            case envelope_gen_num_decay:
                if (slot.eg_rout >= slot.reg_sl << 4)
                {
                    slot.eg_gen = envelope_gen_num_sustain;
                    OPL3_EnvelopeUpdateRate(slot);
                    return;
                }
                slot.eg_rout += slot.eg_inc;
            break;
            case envelope_gen_num_sustain:
                if (slot.reg_type) break;
                //fall through
            case envelope_gen_num_release:
                if (slot.eg_rout >= 0x1ff)
                {
                    slot.eg_gen = envelope_gen_num_off;
                    slot.eg_rout = 0x1ff;
                    OPL3_EnvelopeUpdateRate(slot);
                    return;
                }
                slot.eg_rout += slot.eg_inc;
            break;
        }
    }
    
    private function OPL3_EnvelopeCalcRate(slot:opl3_slot, reg_rate:uint):uint
    {
        var rate:uint;
        if (reg_rate == 0x00)
        {
            return 0x00;
        }
        rate = (reg_rate << 2)
             + (slot.reg_ksr ? slot.channel.ksv : (slot.channel.ksv >> 2));
        if (rate > 0x3c)
        {
            rate = 0x3c;
        }
        return rate;
    }

    private function OPL3_EnvelopeUpdateKSL(slot:opl3_slot):void
    {
        var ksl:int = (kslrom[slot.channel.f_num >> 6] << 2)
                   - ((0x08 - slot.channel.block) << 5);
        if (ksl < 0)
        {
            ksl = 0;
        }
        slot.eg_ksl = ksl & 0xFF; //int16 -> uint8
    }

    private function OPL3_EnvelopeUpdateRate(slot:opl3_slot):void
    {
        switch (slot.eg_gen)
        {
        case envelope_gen_num_off:
        case envelope_gen_num_attack:
            slot.eg_rate = OPL3_EnvelopeCalcRate(slot, slot.reg_ar);
            break;
        case envelope_gen_num_decay:
            slot.eg_rate = OPL3_EnvelopeCalcRate(slot, slot.reg_dr);
            break;
        case envelope_gen_num_sustain:
        case envelope_gen_num_release:
            slot.eg_rate = OPL3_EnvelopeCalcRate(slot, slot.reg_rr);
            break;
        }
    }
    
    private function OPL3_EnvelopeCalc(slot:opl3_slot):void
    {
        var rate_h:uint, rate_l:uint;
        var inc:uint = 0;
        var a:uint, b:uint, c:uint
        rate_h = slot.eg_rate >> 2;
        rate_l = slot.eg_rate & 3;
        if (eg_incsh[rate_h] > 0)
        {
            if ((chip.timer & ((1 << eg_incsh[rate_h]) - 1)) == 0)
            {
                a = eg_incdesc[rate_h];
                b = rate_l;
                c = ((chip.timer) >> eg_incsh[rate_h]) & 0x07;
                inc = eg_incstep[a*32 + b*8 + c];
            }
        }
        else
        {
            a = eg_incdesc[rate_h];
            b = rate_l;
            c = chip.timer & 0x07;
            inc = eg_incstep[a*32 + b*8 + c] << (-eg_incsh[rate_h]);
        }
        slot.eg_inc = inc;
        slot.eg_out = slot.eg_rout + (slot.reg_tl << 2)
                     + (slot.eg_ksl >> kslshift[slot.reg_ksl]) + slot.trem[0];
        envelope_gen(slot);
    }
    
    private function OPL3_EnvelopeKeyOn(slot:opl3_slot, type:uint):void
    {
        if (!slot.key)
        {
            slot.eg_gen = envelope_gen_num_attack;
            OPL3_EnvelopeUpdateRate(slot);
            if ((slot.eg_rate >> 2) == 0x0f)
            {
                slot.eg_gen = envelope_gen_num_decay;
                OPL3_EnvelopeUpdateRate(slot);
                slot.eg_rout = 0x00;
            }
            slot.pg_phase = 0x00;
        }
        slot.key |= type;
    }

    private function OPL3_EnvelopeKeyOff(slot:opl3_slot, type:uint):void
    {
        if (slot.key)
        {
            slot.key &= (~type);
            if (!slot.key)
            {
                slot.eg_gen = envelope_gen_num_release;
                OPL3_EnvelopeUpdateRate(slot);
            }
        }
    }
        
    //
    // Phase Generator
    //

    private function OPL3_PhaseGenerate(slot:opl3_slot):void
    {
        var f_num:uint;
        var basefreq:uint;

        f_num = slot.channel.f_num;
        if (slot.reg_vib)
        {
            var range:int;
            var vibpos:int;

            range = (f_num >> 7) & 7;
            vibpos = chip.vibpos;

            if (!(vibpos & 3))
            {
                range = 0;
            }
            else if (vibpos & 1)
            {
                range >>= 1;
            }
            range >>= chip.vibshift;

            if (vibpos & 4)
            {
                range = -range;
            }
            f_num += range;
        }
        basefreq = (f_num << slot.channel.block) >> 1;
        slot.pg_phase += (basefreq * mt[slot.reg_mult]) >> 1;
    }

    //
    // Noise Generator
    //

    private function OPL3_NoiseGenerate():void
    {
        if (chip.noise & 0x01)
        {
            chip.noise ^= 0x800302;
        }
        chip.noise >>= 1;
    }
    
    private function OPL3_SlotWrite20(slot:opl3_slot, data:uint):void
    {
        if ((data >> 7) & 0x01)
        {
            slot.trem = chip.tremolo;
        }
        else
        {
            slot.trem = chip.zeromod;
        }
        slot.reg_vib = (data >> 6) & 0x01;
        slot.reg_type = (data >> 5) & 0x01;
        slot.reg_ksr = (data >> 4) & 0x01;
        slot.reg_mult = data & 0x0f;
        OPL3_EnvelopeUpdateRate(slot);
    }
        
    private function OPL3_SlotWrite40(slot:opl3_slot, data:uint):void
    {
        slot.reg_ksl = (data >> 6) & 0x03;
        slot.reg_tl = data & 0x3f;
        OPL3_EnvelopeUpdateKSL(slot);
    }

    private function OPL3_SlotWrite60(slot:opl3_slot, data:uint):void
    {
        slot.reg_ar = (data >> 4) & 0x0f;
        slot.reg_dr = data & 0x0f;
        OPL3_EnvelopeUpdateRate(slot);
    }

    private function OPL3_SlotWrite80(slot:opl3_slot, data:uint):void
    {
        slot.reg_sl = (data >> 4) & 0x0f;
        if (slot.reg_sl == 0x0f)
        {
            slot.reg_sl = 0x1f;
        }
        slot.reg_rr = data & 0x0f;
        OPL3_EnvelopeUpdateRate(slot);
    }

    private function OPL3_SlotWriteE0(slot:opl3_slot, data:uint):void
    {
        slot.reg_wf = data & 0x07;
        if (chip.newm == 0x00)
        {
            slot.reg_wf &= 0x03;
        }
    }
    
    public function OPL3_SlotGeneratePhase(slot:opl3_slot, phase:uint):void
    {
        var out:uint = 0;
        var neg:uint = 0;
        
        var envelope:uint = slot.eg_out;
        
        switch(slot.reg_wf) {
            case 0:
                phase &= 0x3ff;
                if (phase & 0x200)
                {
                    neg = ~0; //~0
                }
                if (phase & 0x100)
                {
                    out = logsinrom[(phase & 0xff) ^ 0xff];
                }
                else
                {
                    out = logsinrom[phase & 0xff];
                }
                slot.out[0] = OPL3_EnvelopeCalcExp(out + (envelope << 3)) ^ neg;
            break;
            case 1:
                phase &= 0x3ff;
                if (phase & 0x200)
                {
                    out = 0x1000;
                }
                else if (phase & 0x100)
                {
                    out = logsinrom[(phase & 0xff) ^ 0xff];
                }
                else
                {
                    out = logsinrom[phase & 0xff];
                }
                slot.out[0] = OPL3_EnvelopeCalcExp(out + (envelope << 3));
            break;
            case 2:
                phase &= 0x3ff;
                if (phase & 0x100)
                {
                    out = logsinrom[(phase & 0xff) ^ 0xff];
                }
                else
                {
                    out = logsinrom[phase & 0xff];
                }
                slot.out[0] = OPL3_EnvelopeCalcExp(out + (envelope << 3));
            break;
            case 3:
                phase &= 0x3ff;
                if (phase & 0x100)
                {
                    out = 0x1000;
                }
                else
                {
                    out = logsinrom[phase & 0xff];
                }
                slot.out[0] = OPL3_EnvelopeCalcExp(out + (envelope << 3));
            break;
            case 4:
                phase &= 0x3ff;
                if ((phase & 0x300) == 0x100)
                {
                    neg = ~0; //~0
                }
                if (phase & 0x200)
                {
                    out = 0x1000;
                }
                else if (phase & 0x80)
                {
                    out = logsinrom[((phase ^ 0xff) << 1) & 0xff];
                }
                else
                {
                    out = logsinrom[(phase << 1) & 0xff];
                }
                slot.out[0] = OPL3_EnvelopeCalcExp(out + (envelope << 3)) ^ neg;
            break;
            case 5:
                phase &= 0x3ff;
                if (phase & 0x200)
                {
                    out = 0x1000;
                }
                else if (phase & 0x80)
                {
                    out = logsinrom[((phase ^ 0xff) << 1) & 0xff];
                }
                else
                {
                    out = logsinrom[(phase << 1) & 0xff];
                }
                slot.out[0] = OPL3_EnvelopeCalcExp(out + (envelope << 3));
            break;
            case 6:
                phase &= 0x3ff;
                if (phase & 0x200)
                {
                    neg = ~0; //~0
                }
                slot.out[0] = OPL3_EnvelopeCalcExp(envelope << 3) ^ neg;
            break;
            case 7:
                phase &= 0x3ff;
                if (phase & 0x200)
                {
                    neg = ~0; //~0
                    phase = (phase & 0x1ff) ^ 0x1ff;
                }
                out = phase << 3;
                slot.out[0] = OPL3_EnvelopeCalcExp(out + (envelope << 3)) ^ neg;
            break;
            slot.out[0] = slot.out[0];
        }
    }
    
    private function OPL3_SlotGenerate(slot:opl3_slot):void
    {
        OPL3_SlotGeneratePhase(slot, (slot.pg_phase >> 9) + slot.mod[0]);
    }

    private function OPL3_SlotGenerateZM(slot:opl3_slot):void
    {
        OPL3_SlotGeneratePhase(slot, (slot.pg_phase >> 9));
    }
    
    private function OPL3_SlotCalcFB(slot:opl3_slot):void
    {
        if (slot.channel.fb != 0x00)
        {
            slot.fbmod[0] = (slot.prout + slot.out[0]) >> (0x09 - slot.channel.fb);
        }
        else
        {
            slot.fbmod[0] = 0;
        }
        slot.prout = slot.out[0];
    }
    
    //
    // Channel
    //

    private function OPL3_ChannelUpdateRhythm(data:uint):void
    {
        var channel6:opl3_channel;
        var channel7:opl3_channel;
        var channel8:opl3_channel;
        var chnum:uint;

        chip.rhy = data & 0x3f;
        if (chip.rhy & 0x20)
        {
            channel6 = chip.channel[6];
            channel7 = chip.channel[7];
            channel8 = chip.channel[8];
            channel6.out0 = channel6.slots1.out;
            channel6.out1 = channel6.slots1.out;
            channel6.out2 = chip.zeromod;
            channel6.out3 = chip.zeromod;
            channel7.out0 = channel7.slots0.out;
            channel7.out1 = channel7.slots0.out;
            channel7.out2 = channel7.slots1.out;
            channel7.out3 = channel7.slots1.out;
            channel8.out0 = channel8.slots0.out;
            channel8.out1 = channel8.slots0.out;
            channel8.out2 = channel8.slots1.out;
            channel8.out3 = channel8.slots1.out;
            for (chnum = 6; chnum < 9; chnum++)
            {
                chip.channel[chnum].chtype = ch_drum;
            }
            OPL3_ChannelSetupAlg(channel6);
            //hh
            if (chip.rhy & 0x01)
            {
                OPL3_EnvelopeKeyOn(channel7.slots0, egk_drum);
            }
            else
            {
                OPL3_EnvelopeKeyOff(channel7.slots0, egk_drum);
            }
            //tc
            if (chip.rhy & 0x02)
            {
                OPL3_EnvelopeKeyOn(channel8.slots1, egk_drum);
            }
            else
            {
                OPL3_EnvelopeKeyOff(channel8.slots1, egk_drum);
            }
            //tom
            if (chip.rhy & 0x04)
            {
                OPL3_EnvelopeKeyOn(channel8.slots0, egk_drum);
            }
            else
            {
                OPL3_EnvelopeKeyOff(channel8.slots0, egk_drum);
            }
            //sd
            if (chip.rhy & 0x08)
            {
                OPL3_EnvelopeKeyOn(channel7.slots1, egk_drum);
            }
            else
            {
                OPL3_EnvelopeKeyOff(channel7.slots1, egk_drum);
            }
            //bd
            if (chip.rhy & 0x10)
            {
                OPL3_EnvelopeKeyOn(channel6.slots0, egk_drum);
                OPL3_EnvelopeKeyOn(channel6.slots1, egk_drum);
            }
            else
            {
                OPL3_EnvelopeKeyOff(channel6.slots0, egk_drum);
                OPL3_EnvelopeKeyOff(channel6.slots1, egk_drum);
            }
        }
        else
        {
            for (chnum = 6; chnum < 9; chnum++)
            {
                chip.channel[chnum].chtype = ch_2op;
                OPL3_ChannelSetupAlg(chip.channel[chnum]);
                OPL3_EnvelopeKeyOff(chip.channel[chnum].slots0, egk_drum);
                OPL3_EnvelopeKeyOff(chip.channel[chnum].slots1, egk_drum);
            }
        }
    }
    
    private function OPL3_ChannelWriteA0(channel:opl3_channel, data:uint):void
    {
        if (chip.newm && channel.chtype == ch_4op2)
        {
            return;
        }
        channel.f_num = (channel.f_num & 0x300) | data;
        channel.ksv = (channel.block << 1)
                     | ((channel.f_num >> (0x09 - chip.nts)) & 0x01);
        OPL3_EnvelopeUpdateKSL(channel.slots0);
        OPL3_EnvelopeUpdateKSL(channel.slots1);
        OPL3_EnvelopeUpdateRate(channel.slots0);
        OPL3_EnvelopeUpdateRate(channel.slots1);
        if (chip.newm && channel.chtype == ch_4op)
        {
            channel.pair.f_num = channel.f_num;
            channel.pair.ksv = channel.ksv;
            OPL3_EnvelopeUpdateKSL(channel.pair.slots0);
            OPL3_EnvelopeUpdateKSL(channel.pair.slots1);
            OPL3_EnvelopeUpdateRate(channel.pair.slots0);
            OPL3_EnvelopeUpdateRate(channel.pair.slots1);
        }
    }

    private function OPL3_ChannelWriteB0(channel:opl3_channel, data:uint):void
    {
        if (chip.newm && channel.chtype == ch_4op2)
        {
            return;
        }
        channel.f_num = (channel.f_num & 0xff) | ((data & 0x03) << 8);
        channel.block = (data >> 2) & 0x07;
        channel.ksv = (channel.block << 1)
                     | ((channel.f_num >> (0x09 - chip.nts)) & 0x01);
        OPL3_EnvelopeUpdateKSL(channel.slots0);
        OPL3_EnvelopeUpdateKSL(channel.slots1);
        OPL3_EnvelopeUpdateRate(channel.slots0);
        OPL3_EnvelopeUpdateRate(channel.slots1);
        if (chip.newm && channel.chtype == ch_4op)
        {
            channel.pair.f_num = channel.f_num;
            channel.pair.block = channel.block;
            channel.pair.ksv = channel.ksv;
            OPL3_EnvelopeUpdateKSL(channel.pair.slots0);
            OPL3_EnvelopeUpdateKSL(channel.pair.slots1);
            OPL3_EnvelopeUpdateRate(channel.pair.slots0);
            OPL3_EnvelopeUpdateRate(channel.pair.slots1);
        }
    }
    
    private function OPL3_ChannelSetupAlg(channel:opl3_channel):void
    {
        if (channel.chtype == ch_drum)
        {
            switch (channel.alg & 0x01)
            {
            case 0x00:
                channel.slots0.mod = channel.slots0.fbmod;
                channel.slots1.mod = channel.slots0.out;
                break;
            case 0x01:
                channel.slots0.mod = channel.slots0.fbmod;
                channel.slots1.mod = chip.zeromod;
                break;
            }
            return;
        }
        if (channel.alg & 0x08)
        {
            return;
        }
        if (channel.alg & 0x04)
        {
            channel.pair.out0 = chip.zeromod;
            channel.pair.out1 = chip.zeromod;
            channel.pair.out2 = chip.zeromod;
            channel.pair.out3 = chip.zeromod;
            switch (channel.alg & 0x03)
            {
            case 0x00:
                channel.pair.slots0.mod = channel.pair.slots0.fbmod;
                channel.pair.slots1.mod = channel.pair.slots0.out;
                channel.slots0.mod = channel.pair.slots1.out;
                channel.slots1.mod = channel.slots0.out;
                channel.out0 = channel.slots1.out;
                channel.out1 = chip.zeromod;
                channel.out2 = chip.zeromod;
                channel.out3 = chip.zeromod;
                break;
            case 0x01:
                channel.pair.slots0.mod = channel.pair.slots0.fbmod;
                channel.pair.slots1.mod = channel.pair.slots0.out;
                channel.slots0.mod = chip.zeromod;
                channel.slots1.mod = channel.slots0.out;
                channel.out0 = channel.pair.slots1.out;
                channel.out1 = channel.slots1.out;
                channel.out2 = chip.zeromod;
                channel.out3 = chip.zeromod;
                break;
            case 0x02:
                channel.pair.slots0.mod = channel.pair.slots0.fbmod;
                channel.pair.slots1.mod = chip.zeromod;
                channel.slots0.mod = channel.pair.slots1.out;
                channel.slots1.mod = channel.slots0.out;
                channel.out0 = channel.pair.slots0.out;
                channel.out1 = channel.slots1.out;
                channel.out2 = chip.zeromod;
                channel.out3 = chip.zeromod;
                break;
            case 0x03:
                channel.pair.slots0.mod = channel.pair.slots0.fbmod;
                channel.pair.slots1.mod = chip.zeromod;
                channel.slots0.mod = channel.pair.slots1.out;
                channel.slots1.mod = chip.zeromod;
                channel.out0 = channel.pair.slots0.out;
                channel.out1 = channel.slots0.out;
                channel.out2 = channel.slots1.out;
                channel.out3 = chip.zeromod;
                break;
            }
        }
        else
        {
            switch (channel.alg & 0x01)
            {
            case 0x00:
                channel.slots0.mod = channel.slots0.fbmod;
                channel.slots1.mod = channel.slots0.out;
                channel.out0 = channel.slots1.out;
                channel.out1 = chip.zeromod;
                channel.out2 = chip.zeromod;
                channel.out3 = chip.zeromod;
                break;
            case 0x01:
                channel.slots0.mod = channel.slots0.fbmod;
                channel.slots1.mod = chip.zeromod;
                channel.out0 = channel.slots0.out;
                channel.out1 = channel.slots1.out;
                channel.out2 = chip.zeromod;
                channel.out3 = chip.zeromod;
                break;
            }
        }
    }

    private function OPL3_ChannelWriteC0(channel:opl3_channel, data:uint):void
    {
        channel.fb = (data & 0x0e) >> 1;
        channel.con = data & 0x01;
        channel.alg = channel.con;
        if (chip.newm)
        {
            if (channel.chtype == ch_4op)
            {
                channel.pair.alg = 0x04 | (channel.con << 1) | (channel.pair.con);
                channel.alg = 0x08;
                OPL3_ChannelSetupAlg(channel.pair);
            }
            else if (channel.chtype == ch_4op2)
            {
                channel.alg = 0x04 | (channel.pair.con << 1) | (channel.con);
                channel.pair.alg = 0x08;
                OPL3_ChannelSetupAlg(channel);
            }
            else
            {
                OPL3_ChannelSetupAlg(channel);
            }
        }
        else
        {
            OPL3_ChannelSetupAlg(channel);
        }
        if (chip.newm)
        {
            channel.cha = ((data >> 4) & 0x01) ? ~0 : 0; //~0
            channel.chb = ((data >> 5) & 0x01) ? ~0 : 0; //~0
        }
        else
        {
            channel.cha = channel.chb = ~0; //~0
        }
    }
    
    private function OPL3_ChannelKeyOn(channel:opl3_channel):void
    {
        if (chip.newm)
        {
            if (channel.chtype == ch_4op)
            {
                OPL3_EnvelopeKeyOn(channel.slots0, egk_norm);
                OPL3_EnvelopeKeyOn(channel.slots1, egk_norm);
                OPL3_EnvelopeKeyOn(channel.pair.slots0, egk_norm);
                OPL3_EnvelopeKeyOn(channel.pair.slots1, egk_norm);
            }
            else if (channel.chtype == ch_2op || channel.chtype == ch_drum)
            {
                OPL3_EnvelopeKeyOn(channel.slots0, egk_norm);
                OPL3_EnvelopeKeyOn(channel.slots1, egk_norm);
            }
        }
        else
        {
            OPL3_EnvelopeKeyOn(channel.slots0, egk_norm);
            OPL3_EnvelopeKeyOn(channel.slots1, egk_norm);
        }
    }
    
    private function OPL3_ChannelKeyOff(channel:opl3_channel):void
    {
        if (chip.newm)
        {
            if (channel.chtype == ch_4op)
            {
                OPL3_EnvelopeKeyOff(channel.slots0, egk_norm);
                OPL3_EnvelopeKeyOff(channel.slots1, egk_norm);
                OPL3_EnvelopeKeyOff(channel.pair.slots0, egk_norm);
                OPL3_EnvelopeKeyOff(channel.pair.slots1, egk_norm);
            }
            else if (channel.chtype == ch_2op || channel.chtype == ch_drum)
            {
                OPL3_EnvelopeKeyOff(channel.slots0, egk_norm);
                OPL3_EnvelopeKeyOff(channel.slots1, egk_norm);
            }
        }
        else
        {
            OPL3_EnvelopeKeyOff(channel.slots0, egk_norm);
            OPL3_EnvelopeKeyOff(channel.slots1, egk_norm);
        }
    }
    
    private function OPL3_ChannelSet4Op(data:uint):void
    {
        var bit:uint;
        var chnum:uint;
        for (bit = 0; bit < 6; bit++)
        {
            chnum = bit;
            if (bit >= 3)
            {
                chnum += 9 - 3;
            }
            if ((data >> bit) & 0x01)
            {
                chip.channel[chnum].chtype = ch_4op;
                chip.channel[chnum + 3].chtype = ch_4op2;
            }
            else
            {
                chip.channel[chnum].chtype = ch_2op;
                chip.channel[chnum + 3].chtype = ch_2op;
            }
        }
    }
    
    //TODO: obsolete
    private function OPL3_ClipSample(sample:int):int
    {
        if (sample > 32767)
        {
            sample = 32767;
        }
        else if (sample < -32768)
        {
            sample = -32768;
        }
        return sample;
    }
    
    private function OPL3_GenerateRhythm1():void
    {
        var channel6:opl3_channel;
        var channel7:opl3_channel;
        var channel8:opl3_channel;
        var phase14:uint;
        var phase17:uint;
        var phase:uint;
        var phasebit:uint;

        channel6 = chip.channel[6];
        channel7 = chip.channel[7];
        channel8 = chip.channel[8];
        OPL3_SlotGenerate(channel6.slots0);
        phase14 = (channel7.slots0.pg_phase >> 9) & 0x3ff;
        phase17 = (channel8.slots1.pg_phase >> 9) & 0x3ff;
        phase = 0x00;
        //hh tc phase bit
        phasebit = ((phase14 & 0x08) | (((phase14 >> 5) ^ phase14) & 0x04)
                 | (((phase17 >> 2) ^ phase17) & 0x08)) ? 0x01 : 0x00;
        //hh
        phase = (phasebit << 9)
              | (0x34 << ((phasebit ^ (chip.noise & 0x01)) << 1));
        OPL3_SlotGeneratePhase(channel7.slots0, phase);
        //tt
        OPL3_SlotGenerateZM(channel8.slots0);
    }
    
    private function OPL3_GenerateRhythm2():void
    {
        var channel6:opl3_channel;
        var channel7:opl3_channel;
        var channel8:opl3_channel;
        var phase14:uint;
        var phase17:uint;
        var phase:uint;
        var phasebit:uint;

        channel6 = chip.channel[6];
        channel7 = chip.channel[7];
        channel8 = chip.channel[8];
        OPL3_SlotGenerate(channel6.slots1);
        phase14 = (channel7.slots0.pg_phase >> 9) & 0x3ff;
        phase17 = (channel8.slots1.pg_phase >> 9) & 0x3ff;
        phase = 0x00;
        //hh tc phase bit
        phasebit = ((phase14 & 0x08) | (((phase14 >> 5) ^ phase14) & 0x04)
                 | (((phase17 >> 2) ^ phase17) & 0x08)) ? 0x01 : 0x00;
        //sd
        phase = (0x100 << ((phase14 >> 8) & 0x01)) ^ ((chip.noise & 0x01) << 8);
        OPL3_SlotGeneratePhase(channel7.slots1, phase);
        //tc
        phase = 0x100 | (phasebit << 9);
        OPL3_SlotGeneratePhase(channel8.slots1, phase);
    }

    //TODO: obsolete
    private function uint16ToInt32(x:uint):int
    {
        if (x & 0x8000)
        {
            x |= 0xFFFF0000;
        }
        return x;
    }
    
    private function OPL3_Generate():void
    {
        var ii:uint;
        var jj:uint;
        var accm:int;

        chip.samples1 = OPL3_ClipSample(chip.mixbuff1);

        for (ii = 0; ii < 12; ii++)
        {
            OPL3_SlotCalcFB(chip.slot[ii]);
            OPL3_PhaseGenerate(chip.slot[ii]);
            OPL3_EnvelopeCalc(chip.slot[ii]);
            OPL3_SlotGenerate(chip.slot[ii]);
        }

        for (ii = 12; ii < 15; ii++)
        {
            OPL3_SlotCalcFB(chip.slot[ii]);
            OPL3_PhaseGenerate(chip.slot[ii]);
            OPL3_EnvelopeCalc(chip.slot[ii]);
        }

        if (chip.rhy & 0x20)
        {
            OPL3_GenerateRhythm1();
        }
        else
        {
            OPL3_SlotGenerate(chip.slot[12]);
            OPL3_SlotGenerate(chip.slot[13]);
            OPL3_SlotGenerate(chip.slot[14]);
        }

        chip.mixbuff0 = 0;
        for (ii = 0; ii < 18; ii++)
        {
            accm = 0;
            accm += chip.channel[ii].out0[0];
            accm += chip.channel[ii].out1[0];
            accm += chip.channel[ii].out2[0];
            accm += chip.channel[ii].out3[0];
            chip.mixbuff0 += accm & chip.channel[ii].cha; //uint16 -> int16
        }

        for (ii = 15; ii < 18; ii++)
        {
            OPL3_SlotCalcFB(chip.slot[ii]);
            OPL3_PhaseGenerate(chip.slot[ii]);
            OPL3_EnvelopeCalc(chip.slot[ii]);
        }

        if (chip.rhy & 0x20)
        {
            OPL3_GenerateRhythm2();
        }
        else
        {
            OPL3_SlotGenerate(chip.slot[15]);
            OPL3_SlotGenerate(chip.slot[16]);
            OPL3_SlotGenerate(chip.slot[17]);
        }

        chip.samples0 = OPL3_ClipSample(chip.mixbuff0);

        for (ii = 18; ii < 33; ii++)
        {
            OPL3_SlotCalcFB(chip.slot[ii]);
            OPL3_PhaseGenerate(chip.slot[ii]);
            OPL3_EnvelopeCalc(chip.slot[ii]);
            OPL3_SlotGenerate(chip.slot[ii]);
        }

        chip.mixbuff1 = 0;
        for (ii = 0; ii < 18; ii++)
        {
            accm = 0;
            accm += chip.channel[ii].out0[0];
            accm += chip.channel[ii].out1[0];
            accm += chip.channel[ii].out2[0];
            accm += chip.channel[ii].out3[0];
            chip.mixbuff1 += accm & chip.channel[ii].chb; //uint16 -> int16
        }

        for (ii = 33; ii < 36; ii++)
        {
            OPL3_SlotCalcFB(chip.slot[ii]);
            OPL3_PhaseGenerate(chip.slot[ii]);
            OPL3_EnvelopeCalc(chip.slot[ii]);
            OPL3_SlotGenerate(chip.slot[ii]);
        }

        OPL3_NoiseGenerate();

        if ((chip.timer & 0x3f) == 0x3f)
        {
            chip.tremolopos = (chip.tremolopos + 1) % 210;
        }
        if (chip.tremolopos < 105)
        {
            chip.tremolo[0] = chip.tremolopos >> chip.tremoloshift;
        }
        else
        {
            chip.tremolo[0] = (210 - chip.tremolopos) >> chip.tremoloshift;
        }

        if ((chip.timer & 0x3ff) == 0x3ff)
        {
            chip.vibpos = (chip.vibpos + 1) & 7;
        }

        chip.timer++;

        /*
        while (chip->writebuf[chip->writebuf_cur].time <= chip->writebuf_samplecnt)
        {
            if (!(chip->writebuf[chip->writebuf_cur].reg & 0x200))
            {
                break;
            }
            chip->writebuf[chip->writebuf_cur].reg &= 0x1ff;
            OPL3_WriteReg(chip, chip->writebuf[chip->writebuf_cur].reg,
                          chip->writebuf[chip->writebuf_cur].data);
            chip->writebuf_cur = (chip->writebuf_cur + 1) % OPL_WRITEBUF_SIZE;
        }
        chip->writebuf_samplecnt++;
        */
    }
    
    public function Reset(samplerate:uint):void
    {
        var slotnum:uint;
        var channum:uint;

        chip.MEMSET_0();
        for (slotnum = 0; slotnum < 36; slotnum++)
        {
            chip.slot[slotnum].mod = chip.zeromod;
            chip.slot[slotnum].eg_rout = 0x1ff;
            chip.slot[slotnum].eg_out = 0x1ff;
            chip.slot[slotnum].eg_gen = envelope_gen_num_off;
            chip.slot[slotnum].trem = chip.zeromod;
        }
        for (channum = 0; channum < 18; channum++)
        {
            chip.channel[channum].slots0 = chip.slot[ch_slot[channum]];
            chip.channel[channum].slots1 = chip.slot[ch_slot[channum] + 3];
            chip.slot[ch_slot[channum]].channel = chip.channel[channum];
            chip.slot[ch_slot[channum] + 3].channel = chip.channel[channum];
            if ((channum % 9) < 3)
            {
                chip.channel[channum].pair = chip.channel[channum + 3];
            }
            else if ((channum % 9) < 6)
            {
                chip.channel[channum].pair = chip.channel[channum - 3];
            }
            chip.channel[channum].out0 = chip.zeromod;
            chip.channel[channum].out1 = chip.zeromod;
            chip.channel[channum].out2 = chip.zeromod;
            chip.channel[channum].out3 = chip.zeromod;
            chip.channel[channum].chtype = ch_2op;
            chip.channel[channum].cha = ~0;
            chip.channel[channum].chb = ~0;
            OPL3_ChannelSetupAlg(chip.channel[channum]);
        }
        chip.noise = 0x306600;
        chip.rateratio = (samplerate << RSM_FRAC) / OPL3_SAMPRATE;
        chip.tremoloshift = 4;
        chip.vibshift = 1;
    }
    
    public function WriteReg(reg:uint, v:uint):void
    {
        var high:uint = (reg >> 8) & 0x01;
        var regm:uint = reg & 0xff;
        switch (regm & 0xf0)
        {
        case 0x00:
            if (high)
            {
                switch (regm & 0x0f)
                {
                case 0x04:
                    OPL3_ChannelSet4Op( v);
                    break;
                case 0x05:
                    chip.newm = v & 0x01;
                    break;
                }
            }
            else
            {
                switch (regm & 0x0f)
                {
                case 0x08:
                    chip.nts = (v >> 6) & 0x01;
                    break;
                }
            }
            break;
        case 0x20:
        case 0x30:
            if (ad_slot[regm & 0x1f] >= 0)
            {
                OPL3_SlotWrite20(chip.slot[18 * high + ad_slot[regm & 0x1f]], v);
            }
            break;
        case 0x40:
        case 0x50:
            if (ad_slot[regm & 0x1f] >= 0)
            {
                OPL3_SlotWrite40(chip.slot[18 * high + ad_slot[regm & 0x1f]], v);
            }
            break;
        case 0x60:
        case 0x70:
            if (ad_slot[regm & 0x1f] >= 0)
            {
                OPL3_SlotWrite60(chip.slot[18 * high + ad_slot[regm & 0x1f]], v);
            }
            break;
        case 0x80:
        case 0x90:
            if (ad_slot[regm & 0x1f] >= 0)
            {
                OPL3_SlotWrite80(chip.slot[18 * high + ad_slot[regm & 0x1f]], v);
            }
            break;
        case 0xe0:
        case 0xf0:
            if (ad_slot[regm & 0x1f] >= 0)
            {
                OPL3_SlotWriteE0(chip.slot[18 * high + ad_slot[regm & 0x1f]], v);
            }
            break;
        case 0xa0:
            if ((regm & 0x0f) < 9)
            {
                OPL3_ChannelWriteA0(chip.channel[9 * high + (regm & 0x0f)], v);
            }
            break;
        case 0xb0:
            if (regm == 0xbd && !high)
            {
                chip.tremoloshift = (((v >> 7) ^ 1) << 1) + 2;
                chip.vibshift = ((v >> 6) & 0x01) ^ 1;
                OPL3_ChannelUpdateRhythm(v);
            }
            else if ((regm & 0x0f) < 9)
            {
                OPL3_ChannelWriteB0(chip.channel[9 * high + (regm & 0x0f)], v);
                if (v & 0x20)
                {
                    OPL3_ChannelKeyOn(chip.channel[9 * high + (regm & 0x0f)]);
                }
                else
                {
                    OPL3_ChannelKeyOff(chip.channel[9 * high + (regm & 0x0f)]);
                }
            }
            break;
        case 0xc0:
            if ((regm & 0x0f) < 9)
            {
                OPL3_ChannelWriteC0(chip.channel[9 * high + (regm & 0x0f)], v);
            }
            break;
        }
    }

/*
void OPL3_WriteRegBuffered(opl3_chip *chip, Bit16u reg, Bit8u v)
{
    Bit64u time1, time2;

    if (chip->writebuf[chip->writebuf_last].reg & 0x200)
    {
        OPL3_WriteReg(chip, chip->writebuf[chip->writebuf_last].reg & 0x1ff,
                      chip->writebuf[chip->writebuf_last].data);

        chip->writebuf_cur = (chip->writebuf_last + 1) % OPL_WRITEBUF_SIZE;
        chip->writebuf_samplecnt = chip->writebuf[chip->writebuf_last].time;
    }

    chip->writebuf[chip->writebuf_last].reg = reg | 0x200;
    chip->writebuf[chip->writebuf_last].data = v;
    time1 = chip->writebuf_lasttime + OPL_WRITEBUF_DELAY;
    time2 = chip->writebuf_samplecnt;

    if (time1 < time2)
    {
        time1 = time2;
    }

    chip->writebuf[chip->writebuf_last].time = time1;
    chip->writebuf_lasttime = time1;
    chip->writebuf_last = (chip->writebuf_last + 1) % OPL_WRITEBUF_SIZE;
}
*/
    
    public function GenerateStream(sndptr:ByteArray, numsamples:uint):void
    {
        var i:uint;
        var s0:int;
        var s1:int;

        for(i = 0; i < numsamples; i++)
        {
            //------------
            while (chip.samplecnt >= chip.rateratio)
            {
                chip.oldsamples0 = chip.samples0;
                chip.oldsamples1 = chip.samples1;
                OPL3_Generate();
                chip.samplecnt -= chip.rateratio;
            }
            s0 = ((chip.oldsamples0 * (chip.rateratio - chip.samplecnt)
                             + chip.samples0 * chip.samplecnt) / chip.rateratio);
            s1 = ((chip.oldsamples1 * (chip.rateratio - chip.samplecnt)
                             + chip.samples1 * chip.samplecnt) / chip.rateratio);
            sndptr.writeFloat(s0/0x7FFF);
            sndptr.writeFloat(s1/0x7FFF);
            
            chip.samplecnt += 1 << RSM_FRAC;
            //------------
            //sndptr += 2;
        }
    }
    
    
    
}


}

//---------------------------------------------------------------------------------------
class opl3_chip 
{
    //struct opl3_chip
    //-------------------------------------------
    /*struct _opl3_chip {
        opl3_channel channel[18];
        opl3_slot slot[36];
        Bit16u timer;
        Bit8u newm;
        Bit8u nts;
        Bit8u rhy;
        Bit8u vibpos;
        Bit8u vibshift;
        Bit8u tremolo;
        Bit8u tremolopos;
        Bit8u tremoloshift;
        Bit32u noise;
        Bit16s zeromod;
        Bit32s mixbuff[2];
        //OPL3L
        Bit32s rateratio;
        Bit32s samplecnt;
        Bit16s oldsamples[2];
        Bit16s samples[2];

        Bit64u writebuf_samplecnt;
        Bit32u writebuf_cur;
        Bit32u writebuf_last;
        Bit64u writebuf_lasttime;
        opl3_writebuf writebuf[OPL_WRITEBUF_SIZE];
    };*/
    
    public var
        channel:Vector.<opl3_channel>,
        slot:Vector.<opl3_slot>,
        timer:uint,
        newm:uint,
        nts:uint,
        rhy:uint,
        vibpos:uint,
        vibshift:uint,
        tremolo:Vector.<int>,
        tremolopos:uint,
        tremoloshift:uint,
        noise:uint,
        zeromod:Vector.<int>,
        mixbuff0:int,
        mixbuff1:int,
        //OPL3L
        rateratio:int,
        samplecnt:int,
        oldsamples0:int,
        oldsamples1:int,
        samples0:int,
        samples1:int;
        
    public function MEMSET_0():void
    {
        var i:int;
        
        for(i=0; i<18; i++) channel[i].MEMSET_0();
        for(i=0; i<36; i++) slot[i].MEMSET_0();
        timer = 0;
        newm = 0;
        nts = 0;
        rhy = 0;
        vibpos = 0;
        vibshift = 0;
        tremolo[0] = 0;
        tremolopos = 0;
        tremoloshift = 0;
        noise = 0;
        zeromod[0] = 0;
        mixbuff0 = 0;
        mixbuff1 = 0;
        //OPL3L
        rateratio = 0;
        samplecnt = 0;
        oldsamples0 = 0;
        oldsamples1 = 0;
        samples0 = 0;
        samples1 = 0;
    }
    
    public function opl3_chip()
    {
        var i:int;
        
        channel = new Vector.<opl3_channel>(18, true);  for(i=0; i<18; i++) channel[i] = new opl3_channel();
        slot = new Vector.<opl3_slot>(36, true);        for(i=0; i<36; i++) slot[i] = new opl3_slot();
        tremolo = new Vector.<int>(1, true);
        zeromod = new Vector.<int>(1, true);
    }
}


class opl3_slot
{
    //struct opl3_slot
    //-------------------------------------------
    /*struct _opl3_slot {
        opl3_channel *channel;
        opl3_chip *chip;
        Bit16s out;
        Bit16s fbmod;
        Bit16s *mod;
        Bit16s prout;
        Bit16s eg_rout;
        Bit16s eg_out;
        Bit8u eg_inc;
        Bit8u eg_gen;
        Bit8u eg_rate;
        Bit8u eg_ksl;
        Bit8u *trem;
        Bit8u reg_vib;
        Bit8u reg_type;
        Bit8u reg_ksr;
        Bit8u reg_mult;
        Bit8u reg_ksl;
        Bit8u reg_tl;
        Bit8u reg_ar;
        Bit8u reg_dr;
        Bit8u reg_sl;
        Bit8u reg_rr;
        Bit8u reg_wf;
        Bit8u key;
        Bit32u pg_phase;
        Bit32u timer;
    };*/
    
    public var
        channel:opl3_channel,
        out:Vector.<int>,
        fbmod:Vector.<int>,
        mod:Vector.<int>,
        prout:int,
        eg_rout:int,
        eg_out:int,
        eg_inc:uint,
        eg_gen:uint,
        eg_rate:uint,
        eg_ksl:uint,
        trem:Vector.<int>,
        reg_vib:uint,
        reg_type:uint,
        reg_ksr:uint,
        reg_mult:uint,
        reg_ksl:uint,
        reg_tl:uint,
        reg_ar:uint,
        reg_dr:uint,
        reg_sl:uint,
        reg_rr:uint,
        reg_wf:uint,
        key:uint,
        pg_phase:uint,
        timer:uint;
    
    public function MEMSET_0():void
    {
        channel = null;
        out[0] = 0;
        fbmod[0] = 0;
        mod = null;
        prout = 0;
        eg_rout = 0;
        eg_out = 0;
        eg_inc = 0;
        eg_gen = 0;
        eg_rate = 0;
        eg_ksl = 0;
        trem = null;
        reg_vib = 0;
        reg_type = 0;
        reg_ksr = 0;
        reg_mult = 0;
        reg_ksl = 0;
        reg_tl = 0;
        reg_ar = 0;
        reg_dr = 0;
        reg_sl = 0;
        reg_rr = 0;
        reg_wf = 0;
        key = 0;
        pg_phase = 0;
        timer = 0;
    }
    
    public function opl3_slot()
    {
        out = new Vector.<int>(1, true);
        fbmod = new Vector.<int>(1, true);
    }
}


class opl3_channel
{
    //struct OPL3_channel
    //-------------------------------------------
    /*struct _opl3_channel {
        opl3_slot *slots[2];
        opl3_channel *pair;
        opl3_chip *chip;
        Bit16s *out[4];
        Bit8u chtype;
        Bit16u f_num;
        Bit8u block;
        Bit8u fb;
        Bit8u con;
        Bit8u alg;
        Bit8u ksv;
        Bit16u cha, chb;
    };*/
    public var
        slots0:opl3_slot,
        slots1:opl3_slot,
        pair:opl3_channel,
        out0:Vector.<int>,
        out1:Vector.<int>,
        out2:Vector.<int>,
        out3:Vector.<int>,
        chtype:uint,
        f_num:uint,
        block:uint,
        fb:uint,
        con:uint,
        alg:uint,
        ksv:uint,
        cha:uint, chb:uint;
        
    public function MEMSET_0():void
    {
        slots0 = null;
        slots1 = null;
        pair = null;
        out0 = null;
        out1 = null;
        out2 = null;
        out3 = null;
        chtype = 0;
        f_num = 0;
        block = 0;
        fb = 0;
        con = 0;
        alg = 0;
        ksv = 0;
        cha = 0;
        chb = 0;
    }
    
    public function opl3_channel()
    {
    }
}