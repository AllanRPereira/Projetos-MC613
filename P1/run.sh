#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Uso: $0 <nome_do_arquivo>"
    exit 1
fi

nome=$1
fontes=("Máquina Verilog"/*.v)
iverilog -o "$nome" "${fontes[@]}" "TestBenches/${nome}_tb.v"