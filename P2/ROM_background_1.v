//Background listrado
module rom_background_1 (
    input  wire [9:0] x,        // 0–639
    input  wire [8:0] y,        // 0–479
    output wire  [7:0] data_out
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
    storage[20]=8'h01; storage[21]=8'h01; storage[22]=8'h01; storage[23]=8'h01; storage[24]=8'h01;
    storage[25]=8'h01; storage[26]=8'h01; storage[27]=8'h01; storage[28]=8'h01; storage[29]=8'h01;
    storage[30]=8'h01; storage[31]=8'h01; storage[32]=8'h01; storage[33]=8'h01; storage[34]=8'h01;
    storage[35]=8'h01; storage[36]=8'h01; storage[37]=8'h01; storage[38]=8'h01; storage[39]=8'h01;

    // 0x028
    storage[40]=8'h02; storage[41]=8'h02; storage[42]=8'h02; storage[43]=8'h02; storage[44]=8'h02;
    storage[45]=8'h02; storage[46]=8'h02; storage[47]=8'h02; storage[48]=8'h02; storage[49]=8'h02;
    storage[50]=8'h02; storage[51]=8'h02; storage[52]=8'h02; storage[53]=8'h02; storage[54]=8'h02;
    storage[55]=8'h02; storage[56]=8'h02; storage[57]=8'h02; storage[58]=8'h02; storage[59]=8'h02;

    // 0x03C
    storage[60]=8'h00; storage[61]=8'h00; storage[62]=8'h00; storage[63]=8'h00; storage[64]=8'h00;
    storage[65]=8'h00; storage[66]=8'h00; storage[67]=8'h00; storage[68]=8'h00; storage[69]=8'h00;
    storage[70]=8'h00; storage[71]=8'h00; storage[72]=8'h00; storage[73]=8'h00; storage[74]=8'h00;
    storage[75]=8'h00; storage[76]=8'h00; storage[77]=8'h00; storage[78]=8'h00; storage[79]=8'h00;

    // 0x050
    storage[80]=8'h01; storage[81]=8'h01; storage[82]=8'h01; storage[83]=8'h01; storage[84]=8'h01;
    storage[85]=8'h01; storage[86]=8'h01; storage[87]=8'h01; storage[88]=8'h01; storage[89]=8'h01;
    storage[90]=8'h01; storage[91]=8'h01; storage[92]=8'h01; storage[93]=8'h01; storage[94]=8'h01;
    storage[95]=8'h01; storage[96]=8'h01; storage[97]=8'h01; storage[98]=8'h01; storage[99]=8'h01;

    // 0x064
    storage[100]=8'h02; storage[101]=8'h02; storage[102]=8'h02; storage[103]=8'h02; storage[104]=8'h02;
    storage[105]=8'h02; storage[106]=8'h02; storage[107]=8'h02; storage[108]=8'h02; storage[109]=8'h02;
    storage[110]=8'h02; storage[111]=8'h02; storage[112]=8'h02; storage[113]=8'h02; storage[114]=8'h02;
    storage[115]=8'h02; storage[116]=8'h02; storage[117]=8'h02; storage[118]=8'h02; storage[119]=8'h02;

    // 0x078
    storage[120]=8'h00; storage[121]=8'h00; storage[122]=8'h00; storage[123]=8'h00; storage[124]=8'h00;
    storage[125]=8'h00; storage[126]=8'h00; storage[127]=8'h00; storage[128]=8'h00; storage[129]=8'h00;
    storage[130]=8'h00; storage[131]=8'h00; storage[132]=8'h00; storage[133]=8'h00; storage[134]=8'h00;
    storage[135]=8'h00; storage[136]=8'h00; storage[137]=8'h00; storage[138]=8'h00; storage[139]=8'h00;

    // 0x08C
    storage[140]=8'h01; storage[141]=8'h01; storage[142]=8'h01; storage[143]=8'h01; storage[144]=8'h01;
    storage[145]=8'h01; storage[146]=8'h01; storage[147]=8'h01; storage[148]=8'h01; storage[149]=8'h01;
    storage[150]=8'h01; storage[151]=8'h01; storage[152]=8'h01; storage[153]=8'h01; storage[154]=8'h01;
    storage[155]=8'h01; storage[156]=8'h01; storage[157]=8'h01; storage[158]=8'h01; storage[159]=8'h01;

    // 0x0A0
    storage[160]=8'h02; storage[161]=8'h02; storage[162]=8'h02; storage[163]=8'h02; storage[164]=8'h02;
    storage[165]=8'h02; storage[166]=8'h02; storage[167]=8'h02; storage[168]=8'h02; storage[169]=8'h02;
    storage[170]=8'h02; storage[171]=8'h02; storage[172]=8'h02; storage[173]=8'h02; storage[174]=8'h02;
    storage[175]=8'h02; storage[176]=8'h02; storage[177]=8'h02; storage[178]=8'h02; storage[179]=8'h02;

    // 0x0B4
    storage[180]=8'h00; storage[181]=8'h00; storage[182]=8'h00; storage[183]=8'h00; storage[184]=8'h00;
    storage[185]=8'h00; storage[186]=8'h00; storage[187]=8'h00; storage[188]=8'h00; storage[189]=8'h00;
    storage[190]=8'h00; storage[191]=8'h00; storage[192]=8'h00; storage[193]=8'h00; storage[194]=8'h00;
    storage[195]=8'h00; storage[196]=8'h00; storage[197]=8'h00; storage[198]=8'h00; storage[199]=8'h00;

    // 0x0C8
    storage[200]=8'h01; storage[201]=8'h01; storage[202]=8'h01; storage[203]=8'h01; storage[204]=8'h01;
    storage[205]=8'h01; storage[206]=8'h01; storage[207]=8'h01; storage[208]=8'h01; storage[209]=8'h01;
    storage[210]=8'h01; storage[211]=8'h01; storage[212]=8'h01; storage[213]=8'h01; storage[214]=8'h01;
    storage[215]=8'h01; storage[216]=8'h01; storage[217]=8'h01; storage[218]=8'h01; storage[219]=8'h01;

    // 0x0DC
    storage[220]=8'h02; storage[221]=8'h02; storage[222]=8'h02; storage[223]=8'h02; storage[224]=8'h02;
    storage[225]=8'h02; storage[226]=8'h02; storage[227]=8'h02; storage[228]=8'h02; storage[229]=8'h02;
    storage[230]=8'h02; storage[231]=8'h02; storage[232]=8'h02; storage[233]=8'h02; storage[234]=8'h02;
    storage[235]=8'h02; storage[236]=8'h02; storage[237]=8'h02; storage[238]=8'h02; storage[239]=8'h02;

    // 0x0F0
    storage[240]=8'h00; storage[241]=8'h00; storage[242]=8'h00; storage[243]=8'h00; storage[244]=8'h00;
    storage[245]=8'h00; storage[246]=8'h00; storage[247]=8'h00; storage[248]=8'h00; storage[249]=8'h00;
    storage[250]=8'h00; storage[251]=8'h00; storage[252]=8'h00; storage[253]=8'h00; storage[254]=8'h00;
    storage[255]=8'h00; storage[256]=8'h00; storage[257]=8'h00; storage[258]=8'h00; storage[259]=8'h00;

    // 0x104
    storage[260]=8'h01; storage[261]=8'h01; storage[262]=8'h01; storage[263]=8'h01; storage[264]=8'h01;
    storage[265]=8'h01; storage[266]=8'h01; storage[267]=8'h01; storage[268]=8'h01; storage[269]=8'h01;
    storage[270]=8'h01; storage[271]=8'h01; storage[272]=8'h01; storage[273]=8'h01; storage[274]=8'h01;
    storage[275]=8'h01; storage[276]=8'h01; storage[277]=8'h01; storage[278]=8'h01; storage[279]=8'h01;

    // 0x118
    storage[280]=8'h02; storage[281]=8'h02; storage[282]=8'h02; storage[283]=8'h02; storage[284]=8'h02;
    storage[285]=8'h02; storage[286]=8'h02; storage[287]=8'h02; storage[288]=8'h02; storage[289]=8'h02;
    storage[290]=8'h02; storage[291]=8'h02; storage[292]=8'h02; storage[293]=8'h02; storage[294]=8'h02;
    storage[295]=8'h02; storage[296]=8'h02; storage[297]=8'h02; storage[298]=8'h02; storage[299]=8'h02;
end
    
   assign data_out = storage[addr];
    
endmodule
