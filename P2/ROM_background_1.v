//Background listrado
module rom_background_1 (
    input  wire [9:0] x,        // 0–639
<<<<<<< HEAD
    input  wire [9:0] y,        // 0–479
    output wire [7:0] data_out
=======
    input  wire [8:0] y,        // 0–479
    output wire  [7:0] data_out
>>>>>>> 0371d272a976c5d63e1ca4fcae20c2802a636e20
);

reg [7:0] storage [0:299];

// Tile coordinates
wire [4:0] tile_x;
wire [4:0] tile_y;

// Final address (0–299)
wire [8:0] addr;

// Divide by 32 using shift
assign tile_x = x >> 5;  // x / 32
assign tile_y = y >> 5;  // y / 32

// Map 2D → 1D
assign addr = tile_y * 20 + tile_x;

initial begin
    // 0x000
    storage[0]=8'h00;  storage[1]=8'h00;  storage[2]=8'h00;  storage[3]=8'h00;  storage[4]=8'h00;
    storage[5]=8'h00;  storage[6]=8'h00;  storage[7]=8'h00;  storage[8]=8'h00;  storage[9]=8'h00;
    storage[10]=8'h00; storage[11]=8'h00; storage[12]=8'h00; storage[13]=8'h00; storage[14]=8'h00;
    storage[15]=8'h00; storage[16]=8'h00; storage[17]=8'h00; storage[18]=8'h00; storage[19]=8'h00;

    // 0x014
    storage[20]=8'h0F; storage[21]=8'h0F; storage[22]=8'h0F; storage[23]=8'h0F; storage[24]=8'h0F;
    storage[25]=8'h0F; storage[26]=8'h0F; storage[27]=8'h0F; storage[28]=8'h0F; storage[29]=8'h0F;
    storage[30]=8'h0F; storage[31]=8'h0F; storage[32]=8'h0F; storage[33]=8'h0F; storage[34]=8'h0F;
    storage[35]=8'h0F; storage[36]=8'h0F; storage[37]=8'h0F; storage[38]=8'h0F; storage[39]=8'h0F;

    // 0x028
    storage[40]=8'hFF; storage[41]=8'hFF; storage[42]=8'hFF; storage[43]=8'hFF; storage[44]=8'hFF;
    storage[45]=8'hFF; storage[46]=8'hFF; storage[47]=8'hFF; storage[48]=8'hFF; storage[49]=8'hFF;
    storage[50]=8'hFF; storage[51]=8'hFF; storage[52]=8'hFF; storage[53]=8'hFF; storage[54]=8'hFF;
    storage[55]=8'hFF; storage[56]=8'hFF; storage[57]=8'hFF; storage[58]=8'hFF; storage[59]=8'hFF;

    // 0x03C
    storage[60]=8'h00; storage[61]=8'h00; storage[62]=8'h00; storage[63]=8'h00; storage[64]=8'h00;
    storage[65]=8'h00; storage[66]=8'h00; storage[67]=8'h00; storage[68]=8'h00; storage[69]=8'h00;
    storage[70]=8'h00; storage[71]=8'h00; storage[72]=8'h00; storage[73]=8'h00; storage[74]=8'h00;
    storage[75]=8'h00; storage[76]=8'h00; storage[77]=8'h00; storage[78]=8'h00; storage[79]=8'h00;

    // 0x050
    storage[80]=8'h0F; storage[81]=8'h0F; storage[82]=8'h0F; storage[83]=8'h0F; storage[84]=8'h0F;
    storage[85]=8'h0F; storage[86]=8'h0F; storage[87]=8'h0F; storage[88]=8'h0F; storage[89]=8'h0F;
    storage[90]=8'h0F; storage[91]=8'h0F; storage[92]=8'h0F; storage[93]=8'h0F; storage[94]=8'h0F;
    storage[95]=8'h0F; storage[96]=8'h0F; storage[97]=8'h0F; storage[98]=8'h0F; storage[99]=8'h0F;

    // 0x064
    storage[100]=8'hFF; storage[101]=8'hFF; storage[102]=8'hFF; storage[103]=8'hFF; storage[104]=8'hFF;
    storage[105]=8'hFF; storage[106]=8'hFF; storage[107]=8'hFF; storage[108]=8'hFF; storage[109]=8'hFF;
    storage[110]=8'hFF; storage[111]=8'hFF; storage[112]=8'hFF; storage[113]=8'hFF; storage[114]=8'hFF;
    storage[115]=8'hFF; storage[116]=8'hFF; storage[117]=8'hFF; storage[118]=8'hFF; storage[119]=8'hFF;

    // 0x078
    storage[120]=8'h00; storage[121]=8'h00; storage[122]=8'h00; storage[123]=8'h00; storage[124]=8'h00;
    storage[125]=8'h00; storage[126]=8'h00; storage[127]=8'h00; storage[128]=8'h00; storage[129]=8'h00;
    storage[130]=8'h00; storage[131]=8'h00; storage[132]=8'h00; storage[133]=8'h00; storage[134]=8'h00;
    storage[135]=8'h00; storage[136]=8'h00; storage[137]=8'h00; storage[138]=8'h00; storage[139]=8'h00;

    // 0x08C
    storage[140]=8'h0F; storage[141]=8'h0F; storage[142]=8'h0F; storage[143]=8'h0F; storage[144]=8'h0F;
    storage[145]=8'h0F; storage[146]=8'h0F; storage[147]=8'h0F; storage[148]=8'h0F; storage[149]=8'h0F;
    storage[150]=8'h0F; storage[151]=8'h0F; storage[152]=8'h0F; storage[153]=8'h0F; storage[154]=8'h0F;
    storage[155]=8'h0F; storage[156]=8'h0F; storage[157]=8'h0F; storage[158]=8'h0F; storage[159]=8'h0F;

    // 0x0A0
    storage[160]=8'hFF; storage[161]=8'hFF; storage[162]=8'hFF; storage[163]=8'hFF; storage[164]=8'hFF;
    storage[165]=8'hFF; storage[166]=8'hFF; storage[167]=8'hFF; storage[168]=8'hFF; storage[169]=8'hFF;
    storage[170]=8'hFF; storage[171]=8'hFF; storage[172]=8'hFF; storage[173]=8'hFF; storage[174]=8'hFF;
    storage[175]=8'hFF; storage[176]=8'hFF; storage[177]=8'hFF; storage[178]=8'hFF; storage[179]=8'hFF;

    // 0x0B4
    storage[180]=8'h00; storage[181]=8'h00; storage[182]=8'h00; storage[183]=8'h00; storage[184]=8'h00;
    storage[185]=8'h00; storage[186]=8'h00; storage[187]=8'h00; storage[188]=8'h00; storage[189]=8'h00;
    storage[190]=8'h00; storage[191]=8'h00; storage[192]=8'h00; storage[193]=8'h00; storage[194]=8'h00;
    storage[195]=8'h00; storage[196]=8'h00; storage[197]=8'h00; storage[198]=8'h00; storage[199]=8'h00;

    // 0x0C8
    storage[200]=8'h0F; storage[201]=8'h0F; storage[202]=8'h0F; storage[203]=8'h0F; storage[204]=8'h0F;
    storage[205]=8'h0F; storage[206]=8'h0F; storage[207]=8'h0F; storage[208]=8'h0F; storage[209]=8'h0F;
    storage[210]=8'h0F; storage[211]=8'h0F; storage[212]=8'h0F; storage[213]=8'h0F; storage[214]=8'h0F;
    storage[215]=8'h0F; storage[216]=8'h0F; storage[217]=8'h0F; storage[218]=8'h0F; storage[219]=8'h0F;

    // 0x0DC
    storage[220]=8'hFF; storage[221]=8'hFF; storage[222]=8'hFF; storage[223]=8'hFF; storage[224]=8'hFF;
    storage[225]=8'hFF; storage[226]=8'hFF; storage[227]=8'hFF; storage[228]=8'hFF; storage[229]=8'hFF;
    storage[230]=8'hFF; storage[231]=8'hFF; storage[232]=8'hFF; storage[233]=8'hFF; storage[234]=8'hFF;
    storage[235]=8'hFF; storage[236]=8'hFF; storage[237]=8'hFF; storage[238]=8'hFF; storage[239]=8'hFF;

    // 0x0F0
    storage[240]=8'h00; storage[241]=8'h00; storage[242]=8'h00; storage[243]=8'h00; storage[244]=8'h00;
    storage[245]=8'h00; storage[246]=8'h00; storage[247]=8'h00; storage[248]=8'h00; storage[249]=8'h00;
    storage[250]=8'h00; storage[251]=8'h00; storage[252]=8'h00; storage[253]=8'h00; storage[254]=8'h00;
    storage[255]=8'h00; storage[256]=8'h00; storage[257]=8'h00; storage[258]=8'h00; storage[259]=8'h00;

    // 0x104
    storage[260]=8'h0F; storage[261]=8'h0F; storage[262]=8'h0F; storage[263]=8'h0F; storage[264]=8'h0F;
    storage[265]=8'h0F; storage[266]=8'h0F; storage[267]=8'h0F; storage[268]=8'h0F; storage[269]=8'h0F;
    storage[270]=8'h0F; storage[271]=8'h0F; storage[272]=8'h0F; storage[273]=8'h0F; storage[274]=8'h0F;
    storage[275]=8'h0F; storage[276]=8'h0F; storage[277]=8'h0F; storage[278]=8'h0F; storage[279]=8'h0F;

    // 0x118
    storage[280]=8'hFF; storage[281]=8'hFF; storage[282]=8'hFF; storage[283]=8'hFF; storage[284]=8'hFF;
    storage[285]=8'hFF; storage[286]=8'hFF; storage[287]=8'hFF; storage[288]=8'hFF; storage[289]=8'hFF;
    storage[290]=8'hFF; storage[291]=8'hFF; storage[292]=8'hFF; storage[293]=8'hFF; storage[294]=8'hFF;
    storage[295]=8'hFF; storage[296]=8'hFF; storage[297]=8'hFF; storage[298]=8'hFF; storage[299]=8'hFF;
end
<<<<<<< HEAD


assign data_out = storage[addr];

endmodule
=======
    
   assign data_out = storage[addr];
    
endmodule
>>>>>>> 0371d272a976c5d63e1ca4fcae20c2802a636e20
